#import "@preview/touying:0.7.1": *
#import themes.simple: *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#let fletcher-diagram = touying-reducer.with(reduce: fletcher.diagram, cover: fletcher.hide)

#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *

#let tablestroke = 0.5pt

#let cte_table(pos, table_name, ..content) = node(
  pos,
  shape: rect,
  stroke: none,
  grid(
    rows: 2,
    row-gutter: 10pt,
    table(
      columns: 2,
      stroke: (x: .5pt, y: none),
      table.hline(stroke: .5pt),
      table.header(
        [*n*], [*x*]
      ),
      table.hline(stroke: .5pt),
      ..content,
      table.hline(stroke: .5pt)
    ),
    text(
      table_name,
      size: 20pt,
      ),
  )
)

#let rec_step(label, content) = node(
  (0, -1),
  shape: rect,
  stroke: tablestroke,
  grid(
    rows: 2,
    row-gutter: 10pt,
    label,
    content
  )
)

#let arrowtext(content) = text(content, size: 15pt)

== Classic recursive CTEs

#codly-enable()
#grid(
  columns: (50%, 50%),
  ```sql
  WITH RECURSIVE pow2(n, x) AS (
      -- Base Case
      SELECT 1, 2

      UNION ALL 

      -- Recursive Step
      SELECT n+1, x*2
      FROM pow2
      WHERE n < 10
  )
  FROM pow2;
  ```,
  align(center,
    no-codly(
    ```
    ┌───────┬───────┐
    │   n   │   x   │
    │ int32 │ int32 │
    ├───────┼───────┤
    │     1 │     2 │
    │     2 │     4 │
    │     3 │     8 │
    │     4 │    16 │
    │     5 │    32 │
    │     6 │    64 │
    │     7 │   128 │
    │     8 │   256 │
    │     9 │   512 │
    │    10 │  1024 │
    ├───────┴───────┤
    │    10 rows    │
    └───────────────┘
    ```
    )
  )
)

== Classic: Base Case

#codly-disable()


#align(center+horizon)[
  #fletcher-diagram(
    spacing: (0pt, 25pt),

    alternatives(
      cte_table((-1, 0), "working table", [], []),
      cte_table((-1, 0), "working table", [1], [2])
    ),
    cte_table((0,0), "intermediate table", [], []),
    cte_table((1, 0), "union table", [1], [2]),

    uncover((1), rec_step([*Base Case*], 
      ```sql
      SELECT 1, 2
      ```)
    ),

    uncover((1), edge((0, -1), "r", (1, 0), shift: 2pt, "->", arrowtext("appends"))),
    uncover((2), edge((1, 0), "u,l,l", (-1, 0), shift: 2pt, "->", arrowtext("appends"))),
  )
]

== Classic: Recursive Step

#codly-disable()

#align(center + horizon)[
  #fletcher-diagram(
      debug: 0,
      spacing: (0pt, 25pt),

      alternatives(
        cte_table((-1, 0), "working table", [1], [2]),
        cte_table((-1, 0), "working table", [2], [4]),
        cte_table((-1, 0), "working table", [2], [4]),
        cte_table((-1, 0), "working table", [3], [8]),
        cte_table((-1, 0), "working table", [3], [8]),
        cte_table((-1, 0), "working table", [4], [16]),
      ),
      alternatives(
        cte_table((0,0), "intermediate table", [2], [4]),
        cte_table((0,0), "intermediate table", [2], [4]),
        cte_table((0,0), "intermediate table", [3], [8]),
        cte_table((0,0), "intermediate table", [3], [8]),
        cte_table((0,0), "intermediate table", [4], [16]),
        cte_table((0,0), "intermediate table", [4], [16]),
      ),
      alternatives(
        cte_table((1, 0), "union table", [1], [2]),
        cte_table((1, 0), "union table", [1], [2], [2], [4]),
        cte_table((1, 0), "union table", [1], [2], [2], [4]),
        cte_table((1, 0), "union table", [1], [2], [2], [4], [3], [8]),
        cte_table((1, 0), "union table", [1], [2], [2], [4], [3], [8]),
        cte_table((1, 0), "union table", [1], [2], [2], [4], [3], [8], [4], [16]),

      ),

      uncover((1,3,5), rec_step([*Recursive Step*], 
      ```sql
      SELECT n+1, x*2
      FROM pow2
      WHERE n < 10
      ```)),

      uncover((1,3,5), edge((-1, 0), "u", (0, -1), "->", arrowtext("read by"), label-side: left, label-pos: 60%)),
      uncover((1,3,5), edge((0, -1), (0, 0), "->", arrowtext("overwrites"))),

      uncover((2,4,6), edge((0, 0), "u,r", (1, 0), shift: 2pt, "->", arrowtext("appends"))),
      uncover((2,4,6),
      edge((0, 0), "u,l", (-1, 0), shift: -2pt, "->", arrowtext("overwrites"))),
  )
]

