#import "../definitions.typ" as def
#let lcs = "LCS"

= Longest Common Subsequence

A subsequence of a string $s$ is a string $s_"sub"$ that can be derived from $s$ by deleting some or no characters without changing the order of the remaining characters [from #link("https://en.wikipedia.org/wiki/Subsequence")[Wikipedia]]. A subsequence common to two strings $s_1$ and $s_2$ is a subsequence that both strings have. For example, if 
$ s_1 = "\"Never gonna give you up\"," $
and 
$ s_2 = "\"Never gonna let you down\"," $
some subsequences common to both $s_1$ and $s_2$ would be "Never", "Never gonna", "gonna you", but also "N  p", "eea" "r na u", etc. 

Now, what we are looking for is the _longest_ common subsequence (LCS), which, in this case, is "Never gonna e you " (notice the whitespace at the end). 
Note that the longest common subsequence is not equal to the longest common _substring_. The difference is ...


== Filling the dynamic programming table

We solve LCS by implementing the "traditional technique" first proposed by Wagner and Fischer, using both `USING KEY` and `WITH RECURSIVE` @string_to_string @survey_of_lcs. This approach breaks the problem down by finding the longest common subsequence for all combinations of prefixes of the input strings. 

#def.redbox([TODO: If there is time, we will try to find an algorithm that works better in `WITH RECURSIVE`, and compare that to the results from this chapter.])


We observe two properties of the longest common subsequence which we will use when deriving the recurrence relation. These properties look at the last letters of the input strings.

For this, let $Sigma$ be an alphabet and $Sigma^*$ the set of all words over $Sigma$, with arbitrary letters $a, b in Sigma, a != b$, and two strings $s_1, s_2 in Sigma^*$. Also, let $+$ be the concatenation operator.

The first property states that 
$ lcs(s_1 + a, s_2 + a) = lcs(s_1, s_2) + a. $ 
In words, if two strings end with the same letter, then the LCS of those strings also ends with that letter. As an example, when solving $lcs("FAR", "BAR")$, we can clearly see that the solution must also have the letter R at its end.

The second property states that 
$ lcs(s_1 + a, s_2 + b) = max lr([lcs(s_1 + a, s_2), lcs(s_1, s_2 + b)], size: #200%), $
where $max(s_1, s_2)$ returns the longest string of its arguments.
In words, the second property states that, if two strings end with different letters, then the solution ... TODO. As an example, when solving $lcs("BEAR", "HERE")$, we can see that ... TODO

We can combine the two properties to form the recurrence relation. We use the above definitions for the syntax, with the generalization that it is unknown whether $a$ and $b$ are equal or not. Also, let $epsilon$ be the empty word. Then:

$ lcs(s_1 + a, s_2 + b) = cases(
    epsilon &"if" s_1 + a = epsilon "or" s_2 + b = epsilon,
    lcs(s_1, s_2) + a &"if" a = b,
    max lr([lcs(s_1 + a, s_2), lcs(s_1, s_2 + b)], size: #200%) &"if" a != b
) $ 

We visualize the solution process by iteratively filling out the table shown in @lcs_table_empty. As a running example, we solve $lcs("BEAR", "HERE")$, which we already used above.

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


== Query start

We start by defining the table `letters` which holds all combinations of letters from the two input strings. Every row of `letters` thus defines the coordinates for one cell of @lcs_table_empty. See @letters_definition for the code and an excerpt.

#figure(
    caption: [Definition of table `letters` in SQL (left) and an excerpt of the table (right)],
    grid(
        gutter: 15pt,
        columns: 2,
        [
            ```sql
            CREATE MACRO s1() AS 'BEAR';
            CREATE MACRO s2() AS 'HERE';

            CREATE TABLE letters(xsym, xidx, ysym, yidx) AS (
                SELECT s1()[m], m, s2()[n], n
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

Now we can define the CTEs base case, see @lcs_base_case. With the exception of the `USING KEY` statement, the code is equal for both query types. 

The recurrence relation gets strings as inputs and returns strings as results. While strings help us understand the relation in a mathematical sense, it would be unwise to use strings during the iterative process in the query. Strings can become quite large data structures and the operation of string concatenation is more complex than, say, incrementing an integer or changing a boolean value. Thus, to ensure better performance, we change the recurrence relation and follow a backtracking strategy on the result table afterwards.

For this, we fill the dynamic programming table with the following data: For every symbol `xsym` at `xidx` of `s1()` and every symbol `ysym` at `yidx` of `s2()`, we calculate the length `len` of the lcs, and provide the direction we need to follow when backtracking afterwards, `from_left`, `from_up`, `from_diag`.

The base case corresponds to the first case of the recurrence relation. For the empty characters at the beginning of the strings, `len = 0` and `from_left = from_up = from_diag = false`. 

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
                SELECT 
                    xsym, xidx,
                    ysym, yidx,
                    0,
                    false, false, false
                FROM letters
                WHERE xidx = 0 or yidx = 0

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
                SELECT 
                    xsym, xidx,
                    ysym, yidx,
                    0,
                    false, false, false
                FROM letters
                WHERE xidx = 0 or yidx = 0
                
                UNION

                (<recursive step>)
            )
            <outer query>
            ```
        ]
    )
) <lcs_base_case>

#figure(
    caption: [Dynamic programming table after the base case],
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
)<lcs_table_start>


== Recursive step: using-key



Similar to A\*, the recursive step of classic contains the recursive step of using-key, which is why we start with the latter.

The recursive step corresponds to the other two cases of the recurrence relation. In the query, we simply separate the cases with a `UNION`. In the code at @lcs_recursive_using_key, we marked the cases using comments.

Case ❶: Letters are equal, corresponding to the second case in the recurrence relation. We select `FROM` our table `letters` to get the letters we want to compare and two times from the recurring table `recurring.lcs`; once to get the diagonal element `diag`, and once to get the element we are currently filling out, `this`. Notice that we are using a `LEFT OUTER JOIN` to join `this`, as we want `this` to be empty.

In order for `this` to be selectable in the current iteration, two condition, defined in the `WHERE` clause, must be fulfilled: first, `this` must not have been selected in any previous iteration, `this.len IS NULL`; secondly, the letters must be equal, `ltrs.xsym = ltrs.ysym`. 

If those conditions are met, the clause `SELECT`s the following values: First, we take the symbols and ids of the letters, `ltrs.xsym, ltrs.xidx,ltrs.ysym, ltrs.yidx`. Because of the matching symbols, the lcs's length increases by one, `diag.len + 1`. Finally, we need to mark the path for backtracking later, `false, false, true`, corresponding to the diagonal path.

Case ❷: Letters are unequal, corresponding to the third case in the recurrence relation. The `FROM` clause is similar to the previous case, the difference being that we inspect the left and upper elements of the recurring table, `l` and `u`, instead of the diagonal one. In the `WHERE` clause, we define that the letters must be unequal. Finally, in the `SELECT` clause, we also select the symbols and indices of the considered letters. From the both elements `l` and `u`, we only want to select the greater length, and mark the corresponding path.

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
            letters       AS ltrs JOIN
            recurring.lcs AS diag ON ltrs.xidx = diag.xidx+1 and 
                                     ltrs.yidx = diag.yidx+1 LEFT OUTER JOIN
            recurring.lcs AS this ON ltrs.xidx = this.xidx and
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
            letters       AS ltrs JOIN
            recurring.lcs AS l ON ltrs.xidx = l.xidx+1 and 
                                  ltrs.yidx = l.yidx JOIN
            recurring.lcs AS u ON ltrs.xidx = u.xidx and 
                                  ltrs.yidx = u.yidx+1 LEFT OUTER JOIN
            recurring.lcs AS this ON ltrs.xidx = this.xidx and 
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
    caption: [Dynamic programming table in various iterations],
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
            [*$epsilon$*], [0], [0], [0], [0], [0],
            [*H*], [0], t(0, true, true, false, white), t(0, true, true, false, white), t(0, true, true, false, white), t(0, true, true, false, white),
            [*E*], [0], t(0, true, true, false, white), t(1, false, false, true, white), t(1, true, false, false, white), t(1, true, false, false, white),
            [*R*], [0], t(0, true, true, false, white), t(1, false, true, false, white), t(1, true, true, false, white), t(2, false, false, true, white),
            [*E*], [0], t(0, true, true, false, white), t(1, false, false, true, white), t(1, true, true, false, white), t(2, false, true, false, white),
        ),
    )
)<lcs_table_steps>

#bibliography("../references.bib")
