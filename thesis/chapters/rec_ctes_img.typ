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
      rows:1,
      stroke: (y: none),
      table.hline(),
      table.header(
        [*n*], [*x*]
      ),
      table.hline(),
      ..content,
      table.hline()
    ),
    [#table_name]
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

#let diag_spacing = 2em

= WITH RECURSIVE

#figure(
  caption: [Pseudocode of classic CTE],
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
  ]
)

== Base case

#table(
  rows: 2,
  columns: (65%, 40%),
  align: (x, y) => if x == 0 {center} else {left},

  diagram(
    debug: 0,
    spacing: diag_spacing,

    cte_table((-1, 0), "working table", [-], [-]),
    cte_table((0,0), "intermediate table", [-], [-]),
    cte_table((1, 0), "union table", [1], [2]),
    rec_step([*Base Case*], 
    ```sql
    SELECT 1, 2
    ```),

    edge((0, -1), (1, 0), bend: 35deg, "->", [writes to])
  ),
  [Blabla],

  diagram(
    debug: 0,
    spacing: diag_spacing,

    cte_table((-1, 0), "working table", [1], [2]),
    cte_table((0,0), "intermediate table", [-], [-]),
    cte_table((1, 0), "union table", [1], [2]),

    edge((1, 0), (-1, 0), bend: 35deg, "->", [writes to])
  ),
  [Blabliblub]
)

== Recursive step
#table(
  rows: 2,
  columns: (65%, 40%),
  align: (x, y) => if x == 0 {center} else {left},

  diagram(
    debug: 0,
    spacing: diag_spacing,

    cte_table((-1, 0), "working table", [1], [2]),
    cte_table((0,0), "intermediate table", [2], [4]),
    cte_table((1, 0), "union table", [1], [2]),
    rec_step([*Recursive Step*], 
    ```sql
    SELECT n+1, x*2
    FROM pow2
    WHERE n < 10
    ```),

    edge((-1, 0), (0, -1), bend: 45deg, "->", [read by]),
    edge((0, -1), (0, 0), "->", [writes to])
  ),
  [Here, things are actually happening. They are ening quite fast to be frank.],

  diagram(
    debug: 0,
    spacing: diag_spacing,

    cte_table((-1, 0), "working table", [2], [4]),
    cte_table((0,0), "intermediate table", [2], [4]),
    cte_table((1, 0), "union table", [1], [2], [2], [4]),

    edge((0, 0), (1, 0), "->", [appends]),
    edge((0, 0), (-1, 0), "->", [writes to])
  ),
  [Things are also happening right here. It's tremendous.]
)

#table(
  rows: 2,
  columns: (65%, 40%),
  align: (x, y) => if x == 0 {center} else {left},

  diagram(
    debug: 0,
    spacing: diag_spacing,

    cte_table((-1, 0), "working table", [2], [4]),
    cte_table((0,0), "intermediate table", [3], [8]),
    cte_table((1, 0), "union table", [1], [2], [2], [4]),
    rec_step([*Recursive Step*], 
    ```sql
    SELECT n+1, x*2
    FROM pow2
    WHERE n < 10
    ```),

    edge((-1, 0), (0, -1), bend: 45deg, "->", [read by]),
    edge((0, -1), (0, 0), "->", [writes to])
  ),
  [Here, things are actually happening. They are ening quite fast to be frank.],

  diagram(
    debug: 0,
    spacing: diag_spacing,

    cte_table((-1, 0), "working table", [3], [8]),
    cte_table((0,0), "intermediate table", [3], [8]),
    cte_table((1, 0), "union table", [1], [2], [2], [4], [3], [8]),

    edge((0, 0), (1, 0), "->", [appends]),
    edge((0, 0), (-1, 0), "->", [writes to])
  ),
  [Things are also happening right here. It's tremendous.]
)





= USING-KEY

#figure(
  caption: [Pseudocode of USING KEY],
  [
    ```

    ```
  ]
)

== Base case
#table(
  rows: 2,
  columns: (65%, 40%),
  align: (x, y) => if x == 0 {center} else {left},

  diagram(
    debug: 0,
    spacing: diag_spacing,

    cte_table((-1, 0), "working table", [-], [-]),
    cte_table((0,0), "intermediate table", [-], [-]),
    cte_table((1, 0), "recurring table", [1], [2]),
    rec_step([*Base Case*], 
    ```sql
    SELECT 1, 2
    ```),

    edge((0, -1), (1, 0), bend: 35deg, "->", [writes to])
  ),
  [Blabla],

  diagram(
    debug: 0,
    spacing: diag_spacing,

    cte_table((-1, 0), "working table", [1], [2]),
    cte_table((0,0), "intermediate table", [-], [-]),
    cte_table((1, 0), "recurring table", [1], [2]),

    edge((1, 0), (-1, 0), bend: 35deg, "->", [writes to])
  ),
  [Blabliblub]
)