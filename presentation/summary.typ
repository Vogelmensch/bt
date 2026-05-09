#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *

== Findings (Queries)

#grid(
    columns: 2,
    align: left,
    inset: 1cm,
    [A\*], grid.vline(), [Bishop],
    grid.hline(),
    [
      classic: overhead by manual carry and filtering
    ], [
      `USING KEY`: overhead by accessing recurring table (unnecessary)
    ],
    [
      `USING KEY` is more concise
    ],
    [
      classic is more concise
    ]
)

== Findings (Runtime)


#grid(
    columns: 2,
    align: center,
    row-gutter: 5pt,
    [LCS], [Bishop],
    image("../thesis/chapters/images/lcs_10_to_200_time_no_err.svg"),
    image("../thesis/chapters/images/bishop_0315_all_time.svg")
)

== Findings (Memory)

#grid(
    columns: 2,
    align: center,
    row-gutter: 5pt,
    [A\*], [Bishop],
    image("../thesis/chapters/images/astar_nyc_memory.svg"),
    image("../thesis/chapters/images/bishop_0315_all_memory.svg")
)

== Summary

- Classic recursive CTEs forget previous results.
- `USING KEY` remembers by keeping a keyed dictionary.

If previous results are needed,
- `USING KEY` is easier to implement #emoji.keyboard
- `USING KEY` speeds up query execution #emoji.lightning
- `USING KEY` saves memory #emoji.package

However, if only the immediately preceding results are needed, classic CTEs perform better due to less overhead.