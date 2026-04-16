#import "@preview/touying:0.7.1": *
#import themes.simple: *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#let fletcher-diagram = touying-reducer.with(reduce: fletcher.diagram, cover: fletcher.hide)

#let tablestroke = 0.5pt

#let cte_table(pos, table_name, ..content) = node(
  pos,
  shape: rect,
  stroke: none,
  grid(
    rows: 2,
    row-gutter: 10pt,
    table(
      columns: 5,
      stroke: (x: .5pt, y: none),
      table.hline(stroke: .5pt),
      table.header(
        [*id*], [*dist*], [*f*], [*prev*], [*vis?*]
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

== Tables

#align(center + horizon, 

    fletcher-diagram(
        debug: 0,
        spacing: (0pt, 20pt),

        // Working Table
        alternatives(
            cte_table((-1, 0), "working table", ),
            cte_table((-1, 0), "working table", [0], [0], [0], [-], [false],),
            cte_table((-1, 0), "working table", [0], [0], [0], [-], [false],),
            cte_table((-1, 0), "working table", [0], [0], [0], [-], [false],),
            cte_table((-1, 0), "working table", [0], [0], [0], [-], [false],),
            cte_table((-1, 0), "working table",
            [0], [0], [0], [-], [true],
            [1], [1], [1], [0], [false],
            [2], [4], [4], [0], [false],
            [0], [0], [0], [-], [false]
            )
        ),

        // Intermediate Table
        alternatives(
            cte_table((0,0), "intermediate table", ),
            cte_table((0,0), "intermediate table", ),
            cte_table((0,0), "intermediate table", [0], [0], [0], [-], [true]),
            cte_table((0,0), "intermediate table", [0], [0], [0], [-], [true],
            [1], [1], [1], [0], [false],
            [2], [4], [4], [0], [false]
            ),
            cte_table((0,0), "intermediate table", [0], [0], [0], [-], [true],
            [1], [1], [1], [0], [false],
            [2], [4], [4], [0], [false],
            [0], [0], [0], [-], [false]
            ),
        ),

        // Union Table
        alternatives(
            cte_table((1, 0), "union table", [0], [0], [0], [-], [false]),
            cte_table((1, 0), "union table", [0], [0], [0], [-], [false]),
            cte_table((1, 0), "union table", [0], [0], [0], [-], [false]),
            cte_table((1, 0), "union table", [0], [0], [0], [-], [false]),
            cte_table((1, 0), "union table", [0], [0], [0], [-], [false]),
            cte_table((1, 0), "union table", [0], [0], [0], [-], [false],
            [0], [0], [0], [-], [true],
            [1], [1], [1], [0], [false],
            [2], [4], [4], [0], [false],
            [0], [0], [0], [-], [false]
            ),
        ),

        // QUERIES
        uncover(1, 
            rec_step([*Base Case*], 
            ```sql
            SELECT start_node(), 0, 
                h(start_node()), NULL, false
            ```)
        ),

        uncover(3, 
            rec_step([*Recursive step (1/3)*], 
            ```sql
            SELECT node_id, dist, f, prev, true
            FROM astar
            WHERE node_id = min_node_id
            ```)
        ),

        uncover(4,
            rec_step([*Recursive step (2/3)*],
            ```sql
            <select neighbors>
            ```  
            )
        ),

        uncover(5,
            rec_step([*Recursive step (3/3)*],
            ```sql
            <carry working table>
            ```  
            )
        ),

        // EDGES
        uncover(1,
            edge((0, -1), "r", (1, 0), "->", arrowtext("appends"))),

        uncover(2,
            edge((1, 0), "u,l,l", (-1, 0), "->", arrowtext("overwrites"), label-side: right)),

        uncover("3-5",
            edge((-1, 0), "u", (0, -1), "->", arrowtext("read by"), label-side: left, label-pos: 60%),
        ),
        uncover("3-5",
            edge((0, -1), (0, 0), "->", arrowtext("overwrites"))
        ),
        uncover(6,
            edge((0, 0), "u,r", (1, 0), shift: 2pt, "->", arrowtext("appends"))
        ),
        uncover(6,
            edge((0, 0), "u,l", (-1, 0), shift: -2pt, "->", arrowtext("overwrites"))
        )
    )
)

