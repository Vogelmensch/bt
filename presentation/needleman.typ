#import "@preview/touying:0.7.1": *

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

#{
    show raw: set text(size: 25pt)
    align(center + horizon,
        grid(
                columns: 4,
                gutter:20pt,

                pause,
                [```
                GAGA
                AATG
                -+-- = -2
                ```],

                pause,
                [```
                GAGA-
                -AATG
                -+--- = -3
                ```],

                pause,
                [```
                GA-GA
                -AATG
                -+--- = -3
                ```],

                pause,
                [```
                GA-GA
                AATG-
                -+-+- = -1
                ```],
            )
    )
}

== Tables :)

#lcs_table(
    table(
        rows: 6,
        columns: 6,
        stroke: 0.5pt,
        [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
        table.hline(stroke: 1pt),
        [*$epsilon$*], t(0, false, false, false, white), t(-1, true, false, false, white), t(-2, true, false, false, white), t(-3, true, false, false, white), t(-4, true, false, false, white),
        [*A*], t(-1, false, true, false, white), e, e, e, e,
        [*A*], t(-2, false, true, false, white), e, e, e, e,
        [*T*], t(-3, false, true, false, white), e, e, e, e,
        [*G*], t(-4, false, true, false, white), e, e, e, e,
    ),
    [lel]
)

== Tables :DDD

#lcs_table(
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
    [pimmel hihi :D]
)