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
    epsilon &"if" a = epsilon "or" b = epsilon,
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

TODO: explain that we don't fill the dynamic programming table with strings, but with integers and "arrows". This is the part that explains the schema.

The base case simply implements the first case of the recurrence relation: It fills the dynamic programming table with zero

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

                <recursive step>
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

                <recursive step>
            )
            <outer query>
            ```
        ]
    )
) <lcs_base_case>


#bibliography("../references.bib")
