#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

#let tablestroke = 0.5pt
#let t(s) = text(
  size: 8pt,
  s
)

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
      size: 9pt,
      ),
  )
)

#let using_key_table(pos, table_name, ..content) = node(
  pos,
  shape: rect,
  stroke: none,
  grid(
    rows: 2,
    row-gutter: 10pt,
    table(
      columns: 3,
      stroke: (y: none),
      table.hline(),
      table.header(
        [*i*], [*n*], [*x*]
      ),
      table.hline(),
      ..content,
      table.hline()
    ),
    text(
      table_name,
      size: 9pt,
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

#let arrowtext(content) = text(content, size: 9pt)

#let spacing = (0pt, 0pt)
#let align = (x, y) => if y == 0 {center + bottom} else {left}
#let codegutter = 40pt

= WITH RECURSIVE

#figure(
  caption: [Pseudocode of classic CTE],
  grid(
    columns: 2,
    gutter: codegutter,
    [
      ```
      WITH RECURSIVE T(c1, ..., cn) AS (
        base_case()

        UNION ALL 

        recursive_step(T)
      )
      TABLE T;
      ```
    ],
    [
    ```
    union ← base_case()
    working ← union

    LOOP
      intermediate ← recursive_step(working)
      IF intermediate = ∅
        THEN BREAK
      union ← union ∪ intermediate
      working ← intermediate
    RETURN union
    ```
    ],
  )
)

== Base case

The base case runs once at query start.

#let classic_base = table(
  rows: 2,
  columns: (50%, 50%),
  align: align,
  stroke: .5pt,

  diagram(
    debug: 0,
    spacing: spacing,

    cte_table((-1, 0), "working table", [-], [-]),
    cte_table((0,0), "intermediate table", [-], [-]),
    cte_table((1, 0), "union table", [1], [2]),
    rec_step([*Base Case*], 
    ```sql
    SELECT 1, 2
    ```),

    edge((0, -1), "r", (1, 0), "->", arrowtext("appends"))
  ),

  diagram(
    debug: 0,
    spacing: (0pt, 20pt),

    cte_table((-1, 0), "working table", [1], [2]),
    cte_table((0,0), "intermediate table", [-], [-]),
    cte_table((1, 0), "union table", [1], [2]),

    edge((1, 0), "u,l,l", (-1, 0), "->", arrowtext("overwrites"), label-side: right)
  ),

  [`(1)` The base case defines the first values written to the union table.],
  [`(2)` The union table is copied to the working table.]
)

== Recursive step

The recursive step is repeated until the intermediate table is empty after step 3.

#let classic_step = table(
  rows: 2,
  columns: (50%, 50%),
  align: align,
  stroke: .5pt,

  diagram(
    debug: 0,
    spacing: (0pt, 25pt),

    cte_table((-1, 0), "working table", [1], [2]),
    cte_table((0,0), "intermediate table", [2], [4]),
    cte_table((1, 0), "union table", [1], [2]),
    rec_step([*Recursive Step*], 
    ```sql
    SELECT n+1, x*2
    FROM pow2
    WHERE n < 10
    ```),

    edge((-1, 0), "u", (0, -1), "->", arrowtext("read by"), label-side: left, label-pos: 60%),
    edge((0, -1), (0, 0), "->", arrowtext("overwrites"))
  ),

  diagram(
    debug: 0,
    spacing: (0pt, 25pt),

    cte_table((-1, 0), "working table", [2], [4]),
    cte_table((0,0), "intermediate table", [2], [4]),
    cte_table((1, 0), "union table", [1], [2], [2], [4]),

    edge((0, 0), "u,r", (1, 0), shift: 2pt, "->", arrowtext("appends")),
    edge((0, 0), "u,l", (-1, 0), shift: -2pt, "->", arrowtext("overwrites"))
  ),
  [`(3)` The recursive step is being evaluated, reading values from the working table (here: `pow2`), and writing results to the intermediate table. 
  ],
  [`(4)` If the intermediate table is empty, terminate. Else, all values within it are written to the working table and appended to the union table. ]
)

#table(
  rows: 2,
  columns: (50%, 50%),
  align: align,

  diagram(
    debug: 0,
    spacing: (0pt, 25pt),

    cte_table((-1, 0), "working table", [2], [4]),
    cte_table((0,0), "intermediate table", [3], [8]),
    cte_table((1, 0), "union table", [1], [2], [2], [4]),
    rec_step([*Recursive Step*], 
    ```sql
    SELECT n+1, x*2
    FROM pow2
    WHERE n < 10
    ```),

    edge((-1, 0), "u", (0, -1), "->", arrowtext("read by"), label-side: left, label-pos: 60%),
    edge((0, -1), (0, 0), "->", arrowtext("overwrites"))
  ),

  diagram(
    debug: 0,
    spacing: (0pt, 25pt),

    cte_table((-1, 0), "working table", [3], [8]),
    cte_table((0,0), "intermediate table", [3], [8]),
    cte_table((1, 0), "union table", [1], [2], [2], [4], [3], [8]),

    edge((0, 0), "u,r", (1, 0), shift: 2pt, "->", arrowtext("appends")),
    edge((0, 0), "u,l", (-1, 0), shift: -2pt, "->", arrowtext("overwrites"))
  ),
  [3. The recursive step is being evaluated, reading values from the working table (here: `pow2`), and writing results to the intermediate table. 
  ],
  [4. If the intermediate table is empty, terminate. Else, all values within it are written to the working table and appended to the union table. ]
)


= USING-KEY

#figure(
  caption: [Pseudocode of USING KEY],
  grid(
    columns: 2,
    gutter: codegutter,
    [
      ```
      WITH RECURSIVE T(k1, ..., km, 
                       c1, ..., cn)
      USING KEY (k1, ..., km) AS (
        base_case()

        UNION 

        recursive_step(T, RECURRING T)
      )
      TABLE T;
      ```
    ],
    [
    ```
    recurring ← upsert(∅, base_case())
    working ← recurring

    LOOP
      intermediate ← recursive_step(working, recurring)
      IF intermediate = ∅
        THEN BREAK
      recurring ← upsert(recurring, intermediate)
      working ← intermediate
    RETURN recurring
    ```
    ]
  )
)

== The `upsert` operation

This operation is at the heart of the entire mechanism. As the name suggests, it stands for updating or inserting values in a table. 

TODO


== Base Case

The base case runs once at query start.

#let using_key-base = table(
  rows: 2,
  columns: (50%, 50%),
  align: align,

  diagram(
    debug: 0,
    spacing: spacing,

    using_key_table((-1, 0), "working table", [-], [-], [-]),
    using_key_table((0,0), "intermediate table", [-], [-], [-]),
    using_key_table((1, 0), "recurring table", [0], [1], [2]),
    rec_step([*Base Case*], 
    ```sql
    SELECT 0, 1, 2
    ```),

    edge((0, -1), "r", (1, 0), "->", arrowtext("upserts")),
  ),

  diagram(
    debug: 0,
    spacing: (0pt, 20pt),

    using_key_table((-1, 0), "working table", [0], [1], [2]),
    using_key_table((0,0), "intermediate table", [-], [-], [-]),
    using_key_table((1, 0), "recurring table", [0], [1], [2]),

    edge((1, 0), "u,l,l", (-1, 0), "->", arrowtext("overwrites"), label-side: right),
  ),

  [1. The base case defines the first values inserted to the recurring table.],
  [2. The recurring table is being copied to the working table.]
)

== Recursive step

#let using_key-step = table(
  rows: 2,
  columns: (50%, 50%),
  align: align,

  diagram(
    debug: 0,
    spacing: (0pt, 25pt),

    using_key_table((-1, 0), "working table", [0], [1], [2]),
    using_key_table((0,0), "intermediate table", [0], [2], [4]),
    using_key_table((1, 0), "recurring table", [0], [1], [2]),
    rec_step([*Recursive Step*], 
    ```sql
    SELECT 0, n+1, x*2
    FROM pow2
    WHERE n < 10
    ```),

    edge((-1, 0), "u", (0, -1), "->", arrowtext("read by"), label-side: left, label-pos: 60%),
    edge((0, -1), (0, 0), "->", arrowtext("overwrites")),
    edge((1, 0), "u", (0, -1), "->", arrowtext("read  by"), label-side: right, label-pos: 60%)
  ),

  diagram(
    debug: 0,
    spacing: (0pt, 25pt),

    using_key_table((-1, 0), "working table", [0], [2], [4]),
    using_key_table((0,0), "intermediate table", [0], [2], [4]),
    using_key_table((1, 0), "recurring table", [0], [2], [4]),

    edge((0, 0), "u,r", (1, 0), shift: 2pt, "->", arrowtext("upserts")),
    edge((0, 0), "u,l", (-1, 0), shift: -2pt, "->", arrowtext("overwrites"))
  ),
  [3. The recursive step is being evaluated, reading values from the working table (here: `pow2`) and the recurring table (here: `recurring.pow2`), and writing results to the intermediate table. In this example, the recurring table is not being read.
  ],
  [4. If the intermediate table is empty, terminate. Else, all values within it are written to the working table and upserted to the union table. ]
)

#table(
  rows: 2,
  columns: (50%, 50%),
  align: align,

  diagram(
    debug: 0,
    spacing: (0pt, 25pt),

    using_key_table((-1, 0), "working table", [0], [2], [4]),
    using_key_table((0,0), "intermediate table", [0], [3], [8]),
    using_key_table((1, 0), "recurring table", [0], [2], [4]),
    rec_step([*Recursive Step*], 
    ```sql
    SELECT 0, n+1, x*2
    FROM pow2
    WHERE n < 10
    ```),

    edge((-1, 0), "u", (0, -1), "->", arrowtext("read by"), label-side: left, label-pos: 60%),
    edge((0, -1), (0, 0), "->", arrowtext("overwrites")),
    edge((1, 0), "u", (0, -1), "->", arrowtext("read  by"), label-side: right, label-pos: 60%)
  ),

  diagram(
    debug: 0,
    spacing: (0pt, 25pt),

    using_key_table((-1, 0), "working table", [0], [3], [8]),
    using_key_table((0,0), "intermediate table", [0], [3], [8]),
    using_key_table((1, 0), "recurring table", [0], [3], [8]),

    edge((0, 0), "u,r", (1, 0), shift: 2pt, "->", arrowtext("upserts")),
    edge((0, 0), "u,l", (-1, 0), shift: -2pt, "->", arrowtext("overwrites"))
  ),
  [...],
  [...]
)