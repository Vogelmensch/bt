#import "@preview/touying:0.7.1": *

== Longest Common Subsequence

A subsequence of a string $s$ is a string that can be derived from $s$ by 
- deleting some (or no) letters from $s$
- without changing the order of the remaining letters.

== Longest Common Subsequence

Never gonna give you up

Never gonna let you down

== Longest Common Subsequence

Never gonna #uncover(2, "give you up")

Never gonna #uncover(2, "let you down")

== Longest Common Subsequence

Never gonna #uncover(2, "give") you #uncover(2, "up")

Never gonna #uncover(2, "let") you #uncover(2, "down")


== LCS: Recurrence Relation

#let lcs = "lcs"

$ lcs(s_1 + a, s_2 + b) = cases(
    epsilon &"if" a = epsilon "or" b = epsilon,
    lcs(s_1, s_2) + a &"if" a = b,
    max lr([lcs(s_1 + a, s_2), lcs(s_1, s_2 + b)], size: #200%) &"if" a != b
) $

#{
    show raw: set text(size: 20pt)

    align(
    center,
    grid(
        columns: 3,
        column-gutter: 2cm,
        row-gutter: 1cm,
        align: center,
        [], [Case 1: Equal Letters], [Case 2: Unequal Letters],
        $s_1$, `FAR`, `BEAR`,
        $s_2$, `BAR`, `HERE`,
        $lcs(s_1, s_2)$, ` AR`, `ER`
    )
    )
}

== LCS: Layout

#grid(
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