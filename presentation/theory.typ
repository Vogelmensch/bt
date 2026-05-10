#import "@preview/touying:0.7.1": *
#import themes.simple: *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#let fletcher-diagram = touying-reducer.with(reduce: fletcher.diagram, cover: fletcher.hide)

#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *

#let tablestroke = 0.5pt

#let cte_table(pos, table_name, ..content, using_key: false) = node(
  pos,
  shape: rect,
  stroke: none,
  grid(
    rows: 2,
    row-gutter: 10pt,
    table(
      columns: if not using_key {2} else {3},
      stroke: (x: .5pt, y: none),
      table.hline(stroke: .5pt),
      if not using_key {
        table.header(
          [*n*], [*x*]
      ) } else {
        table.header(
          [*i*], [*n*], [*x*]
        )
      },
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
      cte_table((-1, 0), "working table", [-], [-]),
      cte_table((-1, 0), "working table", [1], [2])
    ),
    cte_table((0,0), "intermediate table", [-], [-]),
    cte_table((1, 0), "union table", [1], [2]),

    uncover((1), rec_step([*Base Case*], 
      ```sql
      SELECT 1, 2
      ```)
    ),

    uncover((1), edge((0, -1), "r", (1, 0), shift: 2pt, "->", arrowtext("appends"))),
    uncover((2), edge((1, 0), "u,l,l", (-1, 0), shift: 2pt, "->", arrowtext("overwrites"))),
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

== Issues of classic recursive CTEs

- Union table collects results of every iteration
  - large growth
  - we cannot access union table at runtime
  - syntactic restrictions

- workarounds exist
  - queries are complicated
  - inefficient execution

$=>$ new semantics for recursive CTEs are needed


== `USING KEY`

#codly-enable()
#grid(
  gutter: 15pt,
  columns: (50%, 50%),
  ```sql
  WITH RECURSIVE 
    pow2(i, n, x) USING KEY (i) AS (
      -- Base Case
      SELECT 0, 1, 2

      UNION

      -- Recursive Step
      SELECT 0, n+1, x*2
      FROM pow2
      WHERE n < 10
  )
  FROM pow2;
  ```,
  align(center,
    [
      #no-codly(
      ```
    ┌───────┬───────┬───────┐
    │   i   │   n   │   x   │
    │ int32 │ int32 │ int32 │
    ├───────┼───────┼───────┤
    │   0   │  10   │ 1024  │
    └───────┴───────┴───────┘
      ```
      )
      #pause
      #grid(
        align: left,
        columns: 2,
        column-gutter: 15pt,
        row-gutter: 30pt,
        [classic:], [append only],
        [`USING KEY`:], [
          keyed dictionary
          - update row if key is equal
          - insert otherwise
        ]
      )
    ]
  ),
)

== `USING KEY`: Base Case

#codly-disable()

#align(center+horizon)[
  #fletcher-diagram(
    spacing: (0pt, 25pt),

    alternatives(
      cte_table(using_key: true, (-1, 0), "working table", [-], [-], [-]),
      cte_table(using_key: true, (-1, 0), "working table", [0], [1], [2])
    ),
    cte_table(using_key: true, (0,0), "intermediate table", [-], [-], [-]),
    cte_table(using_key: true, (1, 0), "recurring table", [0], [1], [2]),

    uncover((1), rec_step([*Base Case*], 
      ```sql
      SELECT 0, 1, 2
      ```)
    ),

    uncover((1), edge((0, -1), "r", (1, 0), shift: 2pt, "->", arrowtext("inserts"))),
    uncover((2), edge((1, 0), "u,l,l", (-1, 0), shift: 2pt, "->", arrowtext("overwrites"))),
  )
]


== `USING KEY`: Recursive Step

#codly-disable()

#align(center + horizon)[
  #fletcher-diagram(
      debug: 0,
      spacing: (0pt, 25pt),

      alternatives(
        cte_table(using_key: true, (-1, 0), "working table", [0], [1], [2]), 
        cte_table(using_key: true, (-1, 0), "working table", [0], [2], [4]), 
        cte_table(using_key: true, (-1, 0), "working table", [0], [2], [4]), 
        cte_table(using_key: true, (-1, 0), "working table", [0], [3], [8]), 
        cte_table(using_key: true, (-1, 0), "working table", [0], [3], [8]), 
        cte_table(using_key: true, (-1, 0), "working table", [0], [4], [16]), 
      ),
      alternatives(
        cte_table(using_key: true, (0,0), "intermediate table", [0], [2], [4]),
        cte_table(using_key: true, (0,0), "intermediate table", [0], [2], [4]),
        cte_table(using_key: true, (0,0), "intermediate table", [0], [3], [8]),
        cte_table(using_key: true, (0,0), "intermediate table", [0], [3], [8]),
        cte_table(using_key: true, (0,0), "intermediate table", [0], [4], [16]),
        cte_table(using_key: true, (0,0), "intermediate table", [0], [4], [16]),
        
      ),
      alternatives(
        cte_table(using_key: true,(1, 0), "recurring table", [0], [1], [2]),
         cte_table(using_key: true,(1, 0), "recurring table", [0], [2], [4]),
         cte_table(using_key: true,(1, 0), "recurring table", [0], [2], [4]),
         cte_table(using_key: true,(1, 0), "recurring table", [0], [3], [8]),
         cte_table(using_key: true,(1, 0), "recurring table", [0], [3], [8]),
         cte_table(using_key: true,(1, 0), "recurring table", [0], [4], [16]),
      ),

      uncover((1,3,5), rec_step([*Recursive Step*], 
      ```sql
      SELECT 0, n+1, x*2
      FROM pow2
      WHERE n < 10
      ```)),

      uncover((1,3,5), edge((-1, 0), "u", (0, -1), "->", arrowtext("read by"), label-side: left, label-pos: 60%)),
      uncover((1,3,5), edge((0, -1), (0, 0), "->", arrowtext("overwrites"))),
      uncover((1,3,5), edge((1, 0), "u", (0, -1), "-->", arrowtext("read by"), label-side: right, label-pos: 60%)),

      uncover((2,4,6), edge((0, 0), "u,r", (1, 0), shift: 2pt, "->", arrowtext("updates / inserts"))),
      uncover((2,4,6),
      edge((0, 0), "u,l", (-1, 0), shift: -2pt, "->", arrowtext("overwrites"))),
  )
]

== Advantages of `USING KEY`

- Recurring table replaces outdated results
  - Size limitation
  - we can access recurring table at runtime
  - no syntactic restrictions 

- Queries become easer to read
- Performance improves