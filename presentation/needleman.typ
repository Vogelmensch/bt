#import "@preview/touying:0.7.1": *

#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *

// dimension for dynamic programming tables
#let dim = 16pt

#let orange = rgb("#ffB51b")

#let t(len, left, up, diag, color) = table.cell(
    grid(
        rows: (dim, dim),
        columns: (dim, dim),
        gutter: 6pt,
        if diag [↖] else [#text(color)[↖]],
        if up [↑] else [#text(color)[↑]],
        if left [←] else [#text(color)[←]], 
        [#len]
    ),
    fill: color,
)

#let e = t("", false, false, false, white)

#let lcs_table(table, code) = grid(
  columns: 2,
  column-gutter: 30pt,
  {
    set text(size: 20pt)
    table
  },
  code
)

== DNA

#grid(
    columns: (30%, 70%),
    gutter: 5cm,
    [
        #only("2-", "Every species is identifiable by its DNA.")

        #only("3-", [
        DNA is made up of four molecules:
        - Cytosine (*C*)
        - Guanine (*G*)
        - Adenine (*A*)
        - Thymine (*T*)
        ])
    ],
    image("/assets/image.png", width: 70%)

)


== DNA Conversion

#{
    show raw: set text(size: 30pt)
    align(center,
        grid(
            columns: 3,
            rows: 1,
            column-gutter: 5cm,
            row-gutter: 1cm,
            align: center + horizon,
            [`GTA`], 
            [`GTA`], 
            alternatives([`GTA`], [`GTA`], [`GTA`], [`GTA`], [`GTA`], [`GTA`], [`GT-A`], ),

            alternatives([`↓`], [`↓`], [`↓`], [`↓`], [`GTC`]),
            alternatives([`↓`], [`↓`], [`↓`], [`↓`], [`↓`], [`G-A`]),
            alternatives([`↓`], [`↓`], [`↓`], [`↓`], [`↓`], [`↓`], [`GTGA`]),

            uncover("2-4", [`GTC`]), 
            uncover("3-5", [`GA`]), 
            uncover("4-6", [`GTGA`]),

            uncover("2-", "substitution"), 
            uncover("3-", "deletion"), 
            uncover("4-", "insertion")
        )
    )
}

== Scoring Function

$
  "score"(a, b) = cases(
    +1 &"if" a = b &"match",
    -1 &"if" a != b &"mismatch",
    -1 &"if" a = "\"-\"" "or" b = "\"-\"" &"indel"
  )
$

#pause
#{
    show raw: set text(size: 25pt)
    align(center + horizon,
        grid(
                columns: 4,
                gutter:20pt,

                [```
                GAGA
                AATG
                -+-- = -2
                ```],

                [```
                GAGA-
                -AATG
                -+--- = -3
                ```],

                [```
                GA-GA
                -AATG
                -+--- = -3
                ```],

                [```
                GA-GA
                AATG-
                -+-+- = -1
                ```],
            )
    )
}

== Needleman: Layout

#codly-enable()
#grid(
    columns: 2,
    gutter: 25pt,

    ```sql
    WITH RECURSIVE needleman (
        xidx, yidx,
        val,
        from_left, from_up, from_diag
    ) AS (
        (<base case>)

        UNION ALL

        (<recursive step>)
    )
    <outer query>
    ```,

    ```sql
    WITH RECURSIVE needleman (
        xidx, yidx,
        val,
        from_left, from_up, from_diag
    ) USING KEY (xidx, yidx) AS (
        (<base case>)

        UNION

        (<recursive step>)
    )
    <outer query>
    ```
    )

== Needleman: Dynamic Programming Table

#align(left, lcs_table(
    align(center,
    table(
        rows: 6,
        columns: 6,
        stroke: 0.5pt,
        [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
        table.hline(stroke: 1pt),
        [*$epsilon$*], e, e, e, e, e,
        [*A*], e, e, e, e, e,
        [*A*], e, e, e, e, e,
        [*T*], e, e, e, e, e,
        [*G*], e, e, e, e, e,
    )),
    []
),)

== Needleman: Base Case

#lcs_table(
    table(
        rows: 6,
        columns: 6,
        stroke: 0.5pt,
        [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
        table.hline(stroke: 1pt),
        [*$epsilon$*], t(0, false, false, false, white), alternatives(e, t(1, true, false, false, white)), alternatives(e, t(2, true, false, false, white)), alternatives(e, t(3, true, false, false, white)), alternatives(e, t(4, true, false, false, white)),
        [*A*], alternatives(e, e, t(1, false, true, false, white)), e, e, e, e,
        [*A*], alternatives(e, e, t(2, false, true, false, white)), e, e, e, e,
        [*T*], alternatives(e, e, t(3, false, true, false, white)), e, e, e, e,
        [*G*], alternatives(e, e, t(4, false, true, false, white)), e, e, e, e,
    ),
    alternatives(
    [
    ```sql
    -- (1) a = b = ε
    SELECT 
        xidx, yidx,
        0,
        false, false, false
    FROM letters
    WHERE xidx = 0 and yidx = 0
    ```],
    [
    ```sql
    UNION 

    -- (2) a = ε, b ≠ ε
    SELECT 
        xidx, yidx,
        yidx * indel_score(),
        false, true, false
    FROM letters
    WHERE xidx = 0 and yidx > 0
    ```
    ],
    [
    ```sql
    UNION

    -- (3) a ≠ ε, b = ε
    SELECT 
        xidx, yidx,
        xidx * indel_score(),
        true, false, false
    FROM letters
    WHERE xidx > 0 and yidx = 0
    ```
    ]
    )
)


== Needleman: Recursive Step

#lcs_table(
    alternatives(
        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, white), t(1, true, false, false, white), t(2, true, false, false, white), t(3, true, false, false, white), t(4, true, false, false, white),
            [*A*], t(1, false, true, false, white), t(1, false, false, true, lime), e, e, e,
            [*A*], t(2, false, true, false, white), e, e, e, e,
            [*T*], t(3, false, true, false, white), e, e, e, e,
            [*G*], t(4, false, true, false, white), e, e, e, e,
        ),
        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, white), t(1, true, false, false, white), t(2, true, false, false, white), t(3, true, false, false, white), t(4, true, false, false, white),
            [*A*], t(1, false, true, false, white), t(1, false, false, true, white), t(0, false, false, true, lime), e, e,
            [*A*], t(2, false, true, false, white), t(2, false, true, true, lime), e, e, e,
            [*T*], t(3, false, true, false, white), e, e, e, e,
            [*G*], t(4, false, true, false, white), e, e, e, e,
        ),
        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, white), t(1, true, false, false, white), t(2, true, false, false, white), t(3, true, false, false, white), t(4, true, false, false, white),
            [*A*], t(1, false, true, false, white), t(1, false, false, true, white), t(0, false, false, true, white), t(1, true, false, false, lime), e,
            [*A*], t(2, false, true, false, white), t(2, false, true, true, white), t(0, false, false, true, lime), e, e,
            [*T*], t(3, false, true, false, white), t(3, false, true, true, lime), e, e, e,
            [*G*], t(4, false, true, false, white), e, e, e, e,
        ),
        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, white), t(1, true, false, false, white), t(2, true, false, false, white), t(3, true, false, false, white), t(4, true, false, false, white),
            [*A*], t(1, false, true, false, white), t(1, false, false, true, white), t(0, false, false, true, white), t(1, true, false, false, white), t(2, true, false, true, lime),
            [*A*], t(2, false, true, false, white), t(2, false, true, true, white), t(0, false, false, true, white), t(1, true, false, true, lime), e,
            [*T*], t(3, false, true, false, white), t(3, false, true, true, white), t(1, false, true, false, lime), e, e,
            [*G*], t(4, false, true, false, white), t(2, false, false, true, lime), e, e, e,
        ),
        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, white), t(1, true, false, false, white), t(2, true, false, false, white), t(3, true, false, false, white), t(4, true, false, false, white),
            [*A*], t(1, false, true, false, white), t(1, false, false, true, white), t(0, false, false, true, white), t(1, true, false, false, white), t(2, true, false, true, white),
            [*A*], t(2, false, true, false, white), t(2, false, true, true, white), t(0, false, false, true, white), t(1, true, false, true, white), t(0, false, false, true, lime),
            [*T*], t(3, false, true, false, white), t(3, false, true, true, white), t(1, false, true, false, white), t(1, false, false, true, lime), e,
            [*G*], t(4, false, true, false, white), t(2, false, false, true, white), t(2, false, true, false, lime), e, e,
        ),
        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, white), t(1, true, false, false, white), t(2, true, false, false, white), t(3, true, false, false, white), t(4, true, false, false, white),
            [*A*], t(1, false, true, false, white), t(1, false, false, true, white), t(0, false, false, true, white), t(1, true, false, false, white), t(2, true, false, true, white),
            [*A*], t(2, false, true, false, white), t(2, false, true, true, white), t(0, false, false, true, white), t(1, true, false, true, white), t(0, false, false, true, white),
            [*T*], t(3, false, true, false, white), t(3, false, true, true, white), t(1, false, true, false, white), t(1, false, false, true, white), t(1, false, true, false, lime),
            [*G*], t(4, false, true, false, white), t(2, false, false, true, white), t(2, false, true, false, white), t(0, false, false, true, lime), e,
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, white), t(1, true, false, false, white), t(2, true, false, false, white), t(3, true, false, false, white), t(4, true, false, false, white),
            [*A*], t(1, false, true, false, white), t(1, false, false, true, white), t(0, false, false, true, white), t(1, true, false, false, white), t(2, true, false, true, white),
            [*A*], t(2, false, true, false, white), t(2, false, true, true, white), t(0, false, false, true, white), t(1, true, false, true, white), t(0, false, false, true, white),
            [*T*], t(3, false, true, false, white), t(3, false, true, true, white), t(1, false, true, false, white), t(1, false, false, true, white), t(1, false, true, false, white),
            [*G*], t(4, false, true, false, white), t(2, false, false, true, white), t(2, false, true, false, white), t(0, false, false, true, white), t(1, true, false, false, lime),
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, orange), t(1, true, false, false, white), t(2, true, false, false, white), t(3, true, false, false, white), t(4, true, false, false, white),
            [*A*], t(1, false, true, false, white), t(1, false, false, true, orange), t(0, false, false, true, white), t(1, true, false, false, white), t(2, true, false, true, white),
            [*A*], t(2, false, true, false, white), t(2, false, true, true, white), t(0, false, false, true, orange), t(1, true, false, true, white), t(0, false, false, true, white),
            [*T*], t(3, false, true, false, white), t(3, false, true, true, white), t(1, false, true, false, orange), t(1, false, false, true, white), t(1, false, true, false, white),
            [*G*], t(4, false, true, false, white), t(2, false, false, true, white), t(2, false, true, false, white), t(0, false, false, true, orange), t(1, true, false, false, orange),
        ),
    ),
    {
    only("1-7",
        [
            ```sql
            SELECT 
                ltrs.xidx, ltrs.yidx, 
                lft.val + indel_score(),
                up.val + indel_score(),
                CASE WHEN ltrs.xsym = ltrs.ysym         
                    THEN diag.val + match_score()
                    ELSE diag.val + mismatch_score() END
            FROM 
                letters AS ltrs
                JOIN recurring.needleman AS diag ON <diag>
                JOIN recurring.needleman AS lft  ON <left>
                JOIN recurring.needleman AS up   ON <up>
                LEFT OUTER JOIN recurring.needleman AS this ON <this>
            WHERE this.val IS NULL 
            ```
        ]
    )
    only("8", 
        [
            ```
            GA-GA
            AATG-
            ```
        ]
    )
    }
)

== Needleman as classic CTE

```sql
<using-key recursive step>

UNION 

FROM needleman
WHERE (SELECT count(*) FROM needleman) < (SELECT count(*) FROM letters)
```