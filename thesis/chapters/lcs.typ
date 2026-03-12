#import "definitions.typ": orange
#let lcs = "LCS"

#set math.equation(numbering: "(1)")
#set heading(numbering: "1.1")

= Longest Common Subsequence

A subsequence $s_"sub"$ of a string $s$ is a string that can be derived from $s$ by deleting some or no letters without changing the order of the remaining letters @survey_of_lcs. A subsequence common to two strings $s_1$ and $s_2$ is a subsequence that both strings have in common. For example, if 
$ s_1 = "\"Never gonna give you up\"," $
and 
$ s_2 = "\"Never gonna let you down\"," $
some subsequences common to both $s_1$ and $s_2$ would be "Never", "Never gonna", "gonna you", but also "N  p", "eea" "r na u", etc. 

Our goal is to find the _longest_ common subsequence (LCS) of two strings. In our example, the LCS is "Never gonna e you " (notice the whitespace at the end). 
Note that the longest common subsequence is not equal to the longest common _substring_. The difference is that adjacent letters within a substring must always also be adjacent in the original string. Thus, every substring of a string $s$ is also a subsequence of $s$, but not the other way around.


== Filling the dynamic programming table

We solve LCS by implementing the "traditional technique" first proposed by Wagner and Fischer @string_to_string @survey_of_lcs. This approach breaks the problem down by finding the longest common subsequence for all combinations of prefixes of the input strings. The goal of this chapter is to find a recurrence relation from which we can derive the queries. To do this,
we observe two properties of the longest common subsequence which examine the last letters of the input strings.

Let $Sigma$ be an alphabet and $Sigma^*$ the set of all words over $Sigma$, with arbitrary letters $a, b in Sigma, a != b$, and two strings $s_1, s_2 in Sigma^*$. Also, let $+$ be the concatenation operator.
The first property states that 
$ lcs(s_1 + a, s_2 + a) = lcs(s_1, s_2) + a. $ <prop1>
In words, if two strings end with the same letter, then the LCS of those strings also ends with that letter. As an example, when solving $lcs("FAR", "BAR")$, we can clearly see that the solution must also end with the letter $"R"$.

The second property states that 
$ lcs(s_1 + a, s_2 + b) = max lr([lcs(s_1 + a, s_2), lcs(s_1, s_2 + b)], size: #200%), $ <prop2>
where $max(s_1, s_2)$ returns the longest string of its arguments.
In words, the second property states that, if two strings end with different letters, then the solution obviously cannot contain both letters. One of the letters, either $a$ or $b$, must be discarded; we choose to discard the one that leads to a longer subsequence when comparing the remaining strings. As an example, the last letters of the strings $s_1 = "BEAR"$ and $s_2 = "HERE"$ are not equal, $"R" != "E"$. One of those letters must be discarded in order for the search to be continued without it, 

$
  lcs("BEAR", "HERE") = max lr([lcs("BEAR", "HER"), lcs("BEA", "HERE")], size: #200%).
$

We now combine @prop1 and @prop2 to form the recurrence relation. For this, we generalize our definitions: It is now unknown whether $a = b$ or $a != b$. Also, let $epsilon$ be the empty word. Then:

$ lcs(s_1 + a, s_2 + b) = cases(
    epsilon &"if" a = epsilon "or" b = epsilon,
    lcs(s_1, s_2) + a &"if" a = b,
    max lr([lcs(s_1 + a, s_2), lcs(s_1, s_2 + b)], size: #200%) &"if" a != b
) $ <lcs_rec_relation>

@lcs_rec_relation will help us understand the queries.
We visualize the solution process by iteratively filling out the table shown in @lcs_table_empty. As a running example, we solve the example introduced above, $lcs("BEAR", "HERE")$.

#figure(
    caption: [Empty dynamic programming table],
    table(
        rows: 6,
        columns: 6,
        stroke: 0.5pt,
        [], table.vline(stroke: 1pt), [*$epsilon$*], [*B*], [*E*], [*A*], [*R*],
        table.hline(stroke: 1pt),
        [*$epsilon$*], [], [], [], [], [],
        [*H*], [], [], [], [], [],
        [*E*], [], [], [], [], [],
        [*R*], [], [], [], [], [],
        [*E*], [], [], [], [], [],
    ),
)<lcs_table_empty>


== Query layout

First, we define macros `s1()` and `s2()` to hold our two input strings. We then define the table `letters` which holds all combinations of letters from the two input strings. Every row of `letters` thus defines the coordinates for one cell of @lcs_table_empty. See @letters_definition for the code and an excerpt.

#figure(
    caption: [Definition of table `letters` in SQL (left) and an excerpt of the table (right)],
    grid(
        gutter: 15pt,
        columns: 2,
        align: horizon,
        [
            ```sql
            CREATE MACRO s1() AS 'BEAR';
            CREATE MACRO s2() AS 'HERE';

            CREATE TABLE letters(xsym, xidx, 
                                 ysym, yidx) AS (
                SELECT s1()[m], m, 
                       s2()[n], n
                FROM 
                    range(length(s1())+1) AS r(m),
                    range(length(s2())+1) AS r(n)
            );
            ```
        ],
        table(
            columns: 4,
            table.header([`xsym`], [`xidx`], [`ysym`], [`yidx`]),
            [$epsilon$], [0], [$epsilon$], [0],
            [B], [1], [$epsilon$], [0],
            [E], [2], [$epsilon$], [0],
            [A], [3], [$epsilon$], [0],
            [R], [4], [$epsilon$], [0],
            [$epsilon$], [0], [H], [1],
            [B], [1], [H], [1],
            [...], [...], [...], [...],
        )        
    )
) <letters_definition>

@lcs_layout shows the layout of the queries for both variants of recursive CTEs. The first columns of `lcs` are equivalent to the columns of `letters`: they define the coordinates and their respective letter-combination for the dynamic programming table.


The recurrence relation gets strings as inputs and returns strings as results. While strings help us understand the relation in a mathematical sense, it would be unwise to use strings during the iterative process in the query. Strings can become quite large data structures and the operation of string concatenation is more complex than, say, incrementing an integer or changing a boolean value. Thus, to ensure better performance, we only store the lengths that result from the recurrence relation and follow a backtracking strategy on the result table afterwards.

For this, we fill the dynamic programming table with the following data: For every symbol `xsym` at `xidx` of `s1()` and every symbol `ysym` at `yidx` of `s2()`, we calculate the length `len` of the lcs, and provide the direction we need to follow when backtracking afterwards, `from_left`, `from_up`, or `from_diag`.

TODO: about key used

#figure(
    caption: [Base case of LCS for classic (left) and using-key (right)],
    grid(
        columns: 2,
        gutter: 15pt,
        [
            ```sql
            WITH RECURSIVE lcs (
                xsym, xidx,                     
                ysym, yidx,                    
                len,                         
                from_left, from_up, from_diag   
            ) AS (
                <base case>

                UNION ALL

                (<recursive step>)
            )
            <outer query>
            ```
        ],
        [
            ```sql
            WITH RECURSIVE lcs (
                xsym, xidx,                    
                ysym, yidx,                   
                len,                 
                from_left, from_up, from_diag  
            ) USING KEY (xidx, yidx) AS (
                <base case>
                
                UNION

                (<recursive step>)
            )
            <outer query>
            ```
        ]
    )
) <lcs_layout>



== Base case

@lcs_base_case shows the base case, which corresponds to the first case in @lcs_rec_relation. For the empty letters at the beginning of the strings, `len = 0`. When backtracking later, this will be an enpoint: `from_left = from_up = from_diag = false`. 

#figure(
    caption: [Base case of LCS (left) and the dynamic programming table after its execution (right).],
    grid(
        columns: 2,
        gutter: 20pt,
        align: horizon,
        ```sql
        SELECT 
            xsym, xidx,
            ysym, yidx,
            0,
            false, false, false
        FROM letters
        WHERE xidx = 0 or yidx = 0
        ```,
        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*B*], [*E*], [*A*], [*R*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], [0], [0], [0], [0], [0],
            [*H*], [0], [], [], [], [],
            [*E*], [0], [], [], [], [],
            [*R*], [0], [], [], [], [],
            [*E*], [0], [], [], [], [],
        ),
    )
)<lcs_base_case>


== Recursive step: using-key

Similar to A\*, the recursive step of classic contains the recursive step of using-key, which is why we start with the latter.

The recursive step corresponds to the other two cases in @lcs_rec_relation. In the query, we simply separate the cases with a `UNION`. In the code at @lcs_recursive_using_key, we marked the cases using comments. You can follow an example in @lcs_example.

Case ❶: Letters are equal, corresponding to the second case of the recurrence relation. We select the `letters` we want to compare, and two times from the recurring table `recurring.lcs`; once to get the diagonal element `diag`, and once to get the element we are currently filling out, `this`. Notice that we are using a `LEFT OUTER JOIN` to join `this`, as we want `this` to be empty.

In order for `this` to be selectable in the current iteration, two condition, defined in the `WHERE` clause, must be fulfilled: first, `this` must not have been selected in any previous iteration, `this.len IS NULL`; secondly, the letters must be equal, `ltrs.xsym = ltrs.ysym`. 

If those conditions are met, the clause `SELECT`s the following values: First, we take the symbols and ids of the letters, `ltrs.xsym, ltrs.xidx, ltrs.ysym, ltrs.yidx`. Because of the matching symbols, the lcs's length increases by one, `diag.len + 1`. Finally, we need to mark the path for backtracking later, `false, false, true`, corresponding to the diagonal path.

Case ❷: Letters are unequal, corresponding to the third case in @lcs_rec_relation. The `FROM` clause is similar to the previous case, the difference being that we inspect the left and upper elements of the recurring table, `l` and `u`, instead of the diagonal one. In the `WHERE` clause, we define that the letters must be unequal. Finally, in the `SELECT` clause, we also select the symbols and indices of the considered letters. From the two elements `l` and `u`, we only want to select the one of greater length, and mark the corresponding path; in the case of equality, we select both.

Both case ❶ and case ❷ automatically terminate as soon as no empty table element is left, i.e. when `this.len IS NULL` returns `false` for all elements.

#figure(
    caption: [Recursive step of lcs for using-key],
    [
        ```sql
        -- Case ❶: Letters are equal
        SELECT
            ltrs.xsym, ltrs.xidx,
            ltrs.ysym, ltrs.yidx,
            diag.len + 1,
            false, false, true
        FROM 
                            letters       AS ltrs 
            JOIN            recurring.lcs AS diag ON ltrs.xidx = diag.xidx+1 and 
                                                     ltrs.yidx = diag.yidx+1 
            LEFT OUTER JOIN recurring.lcs AS this ON ltrs.xidx = this.xidx and
                                                     ltrs.yidx = this.yidx
        WHERE 
            this.len IS NULL and    
            ltrs.xsym = ltrs.ysym   

        UNION

        -- Case ❷: Letters are unequal
        SELECT
            ltrs.xsym, ltrs.xidx,
            ltrs.ysym, ltrs.yidx,
            greatest(l.len, u.len),
            l.len >= u.len, u.len >= l.len, false
        FROM 
                            letters       AS ltrs 
                       JOIN recurring.lcs AS l    ON ltrs.xidx = l.xidx+1 and 
                                                     ltrs.yidx = l.yidx 
                       JOIN recurring.lcs AS u    ON ltrs.xidx = u.xidx and 
                                                     ltrs.yidx = u.yidx+1
            LEFT OUTER JOIN recurring.lcs AS this ON ltrs.xidx = this.xidx and 
                                                     ltrs.yidx = this.yidx    
        WHERE 
            this.len IS NULL and    
            ltrs.xsym != ltrs.ysym 
        ```
    ]
) <lcs_recursive_using_key>


#let t(len, left, up, diag, color) = table.cell(
    grid(
        rows: 2,
        columns: 2,
        gutter: 3pt,
        if diag [↖] else [#text(color)[↖]],
        if up [↑] else [#text(color)[↑]],
        if left [←] else [#text(color)[←]], 
        [#len]
    ),
    fill: color
)

#let e = t("", false, false, false, white)

#figure(
    caption: [Dynamic programming table in various iterations. The arrows represent the boolean flags `from_left`, `from_up` and `from_diag`. The numbers represent the `len`-value. Marked in green are the elements that are being added in the respective iteration. In the last table, the final path is marked in orange.],
    grid(
        rows: 4,
        columns: 2,
        gutter: 20pt,
        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*B*], [*E*], [*A*], [*R*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], [0], [0], [0], [0], [0],
            [*H*], [0], t(0, true, true, false, lime), e, e, e,
            [*E*], [0], e, e, e, e,
            [*R*], [0], e, e, e, e,
            [*E*], [0], e, e, e, e,
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*B*], [*E*], [*A*], [*R*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], [0], [0], [0], [0], [0],
            [*H*], [0], t(0, true, true, false, white), t(0, true, true, false, lime), e, e,
            [*E*], [0], t(0, true, true, false, lime), t(1, false, false, true, lime), e, e,
            [*R*], [0], e, e, e, e,
            [*E*], [0], e, e, e, e,
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*B*], [*E*], [*A*], [*R*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], [0], [0], [0], [0], [0],
            [*H*], [0], t(0, true, true, false, white), t(0, true, true, false, white), t(0, true, true, false, lime), e,
            [*E*], [0], t(0, true, true, false, white), t(1, false, false, true, white), e, e,
            [*R*], [0], t(0, true, true, false, lime), e, e, e,
            [*E*], [0], e, e, e, e,
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*B*], [*E*], [*A*], [*R*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], [0], [0], [0], [0], [0],
            [*H*], [0], t(0, true, true, false, white), t(0, true, true, false, white), t(0, true, true, false, white), t(0, true, true, false, lime),
            [*E*], [0], t(0, true, true, false, white), t(1, false, false, true, white), t(1, true, false, false, lime), e,
            [*R*], [0], t(0, true, true, false, white), t(1, false, true, false, lime), e, e,
            [*E*], [0], t(0, true, true, false, lime), t(1, false, false, true, lime), e, e,
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*B*], [*E*], [*A*], [*R*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], [0], [0], [0], [0], [0],
            [*H*], [0], t(0, true, true, false, white), t(0, true, true, false, white), t(0, true, true, false, white), t(0, true, true, false, white),
            [*E*], [0], t(0, true, true, false, white), t(1, false, false, true, white), t(1, true, false, false, white), t(1, true, false, false, lime),
            [*R*], [0], t(0, true, true, false, white), t(1, false, true, false, white), t(1, true, true, false, lime), t(2, false, false, true, lime),
            [*E*], [0], t(0, true, true, false, white), t(1, false, false, true, white), e, e,
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*B*], [*E*], [*A*], [*R*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], [0], [0], [0], [0], [0],
            [*H*], [0], t(0, true, true, false, white), t(0, true, true, false, white), t(0, true, true, false, white), t(0, true, true, false, white),
            [*E*], [0], t(0, true, true, false, white), t(1, false, false, true, white), t(1, true, false, false, white), t(1, true, false, false, white),
            [*R*], [0], t(0, true, true, false, white), t(1, false, true, false, white), t(1, true, true, false, white), t(2, false, false, true, white),
            [*E*], [0], t(0, true, true, false, white), t(1, false, false, true, white), t(1, true, true, false, lime), e,
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*B*], [*E*], [*A*], [*R*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], [0], [0], [0], [0], [0],
            [*H*], [0], t(0, true, true, false, white), t(0, true, true, false, white), t(0, true, true, false, white), t(0, true, true, false, white),
            [*E*], [0], t(0, true, true, false, white), t(1, false, false, true, white), t(1, true, false, false, white), t(1, true, false, false, white),
            [*R*], [0], t(0, true, true, false, white), t(1, false, true, false, white), t(1, true, true, false, white), t(2, false, false, true, white),
            [*E*], [0], t(0, true, true, false, white), t(1, false, false, true, white), t(1, true, true, false, white), t(2, false, true, false, lime),
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*B*], [*E*], [*A*], [*R*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], [0], table.cell([0], fill: orange), [0], [0], [0],
            [*H*], table.cell([0], fill: orange), t(0, true, true, false, orange), t(0, true, true, false, white), t(0, true, true, false, white), t(0, true, true, false, white),
            [*E*], [0], t(0, true, true, false, white), t(1, false, false, true, orange), t(1, true, false, false, orange), t(1, true, false, false, white),
            [*R*], [0], t(0, true, true, false, white), t(1, false, true, false, white), t(1, true, true, false, white), t(2, false, false, true, orange),
            [*E*], [0], t(0, true, true, false, white), t(1, false, false, true, white), t(1, true, true, false, white), t(2, false, true, false, orange),
        ),
    )
)<lcs_example>

== Recursive step: classic

As mentioned above, classic lcs contains the using-key variant. However, in classic, we cannot access the recurring table, which we repeatedly do within using-key. We thus need to manually carry all calculated values by selecting the entire table `lcs` and unionizing it with the results of each recursive step. To guarantee termination, in the `WHERE` clause, we check whether the number of elements in the working table exceed the number of elements in `letters`, which is the natural limit.

To access those carried values, we simply replace all occurences of `recurring.lcs` in @lcs_recursive_using_key with `lcs`. The difference between the two variants then boils down to a few additional lines shown in @lcs_recursive_classic.

#figure(
    caption: [Recursive step of lcs for classic],
    [
        ```sql
        <using-key recursive step>

        UNION

        FROM lcs
        WHERE (SELECT count(*) FROM lcs) < (SELECT count(*) FROM letters)
        ```
    ]
) <lcs_recursive_classic>





#bibliography("../references.bib")
