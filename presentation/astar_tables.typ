#import "@preview/touying:0.7.1": *
#import themes.simple: *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#let fletcher-diagram = touying-reducer.with(reduce: fletcher.diagram, cover: fletcher.hide)
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *

#show raw: set text(size: 12pt)
#show table: set text(size: 13pt)

#let tablestroke = 1pt

#let marking_color = red + 1.2pt

#let dijk(marked: none, ..cont) = table(
      columns: 5,
      stroke: (x: tablestroke, y: none),
      align: center,
      table.hline(stroke: tablestroke),
      table.header(
        [*id*], [*dist*], [*f*],  [*prev*], [*vis?*]
      ),
      table.hline(stroke: tablestroke),
      ..cont,
      table.hline(stroke: tablestroke),

      ..if marked != none {
        (
        table.hline(y: marked+1, stroke: marking_color),
        table.hline(y: marked, stroke: marking_color),
        table.vline(x: 0, start: marked, end: marked+1, stroke: marking_color),
        table.vline(x: 5, start: marked, end: marked+1, stroke: marking_color)
        )
      } 
)

#let example_graph(marked) = {
        set text(size: 11pt)

        diagram(
        node-shape: circle,
        node-stroke: 0.5pt,
        {
        let (A, B, C, D, E, F, G) = (
            (0,0),
            (1,0),
            (0,1),
            (1,1),
            (2,2),
            (1,2),
            (0,2))
        
        node(A, $0$, stroke: if marked == 0 {red+1.2pt} else {black})
        node(B, $1$, stroke: if marked == 1 {red+1.2pt} else {black})
        node(C, $2$)
        node(D, $3$)
        node(E, $4$)
        node(F, $5$)
        node(G, $6$)
        edge(A, B, $1$)
        edge(A, C, $4$)
        edge(B, D, $1$)
        edge(C, D, $1$)
        edge(D, E, $1$)
        edge(D, F, $3$)
        edge(E, F, $1$)
        edge(F, G, $1$)
        edge(C, G, $10$)
    })
}

#let cte_table(pos, table_name, marked: none, ..content) = node(
  pos,
  shape: rect,
  stroke: none,
  grid(
    rows: 2,
    row-gutter: 10pt,
    dijk(marked: marked, ..content),
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


== A\*: USING KEY

#codly-disable()

#align(center + horizon, 
        fletcher-diagram(
        debug: 0,
        spacing: (0pt, 20pt),

        // Working Table
        alternatives(
            cte_table((-1, 0), "working table", ),
            cte_table((-1, 0), "working table", [0], [0], [0], [-], [`false`],),
            cte_table((-1, 0), "working table", [0], [0], [0], [-], [`false`]),
            cte_table((-1, 0), "working table", [0], [0], [0], [-], [`false`]),
            cte_table((-1, 0), "working table",
            [0], [0], [0], [-], [`true`],
            [1], [1], [1], [0], [`false`],
            [2], [4], [4], [0], [`false`]
            ),
            cte_table((-1, 0), "working table",
            [0], [0], [0], [-], [`true`],
            [1], [1], [1], [0], [`false`],
            [2], [4], [4], [0], [`false`]
            ),
            cte_table((-1, 0), "working table",
            [0], [0], [0], [-], [`true`],
            [1], [1], [1], [0], [`false`],
            [2], [4], [4], [0], [`false`]
            ),
            cte_table((-1, 0), "working table",
            [1], [1], [1], [0], [true],
            [3], [2], [2], [1], [false]
            ),
        ),

        // Intermediate Table
        alternatives(
            cte_table((0,0), "intermediate table", ),
            cte_table((0,0), "intermediate table", ),
            cte_table((0,0), "intermediate table", 
            [0], [0], [0], [-], [`true`]),
            cte_table((0,0), "intermediate table", 
            [0], [0], [0], [-], [`true`],
            [1], [1], [1], [0], [`false`],
            [2], [4], [4], [0], [`false`]
            ),
            cte_table((0,0), "intermediate table", 
            [0], [0], [0], [-], [`true`],
            [1], [1], [1], [0], [`false`],
            [2], [4], [4], [0], [`false`]
            ),
            cte_table((0,0), "intermediate table",
            [1], [1], [1], [0], [true]),
            cte_table((0,0), "intermediate table",
            [1], [1], [1], [0], [true],
            [3], [2], [2], [1], [false]
            ),
        ),

        // Recurring Table
        alternatives(
            cte_table((1, 0), "recurring table", [0], [0], [0], [-], [`false`]),
            cte_table((1, 0), "recurring table", [0], [0], [0], [-], [`false`]),
            cte_table((1, 0), "recurring table", [0], [0], [0], [-], [`false`], marked: 1),
            cte_table((1, 0), "recurring table", [0], [0], [0], [-], [`false`]),
            cte_table((1, 0), "recurring table", [0], [0], [0], [-], [`true`],
            [1], [1], [1], [0], [`false`],
            [2], [4], [4], [0], [`false`]
            ),
            cte_table((1, 0), "recurring table", [0], [0], [0], [-], [`true`],
            [1], [1], [1], [0], [`false`],
            [2], [4], [4], [0], [`false`],
            marked: 2
            ),
            cte_table((1, 0), "recurring table", [0], [0], [0], [-], [`true`],
            [1], [1], [1], [0], [`false`],
            [2], [4], [4], [0], [`false`]
            ),
            cte_table((1, 0), "recurring table", [0], [0], [0], [-], [`true`],
            [1], [1], [1], [0], [`true`],
            [2], [4], [4], [0], [`false`],
            [3], [2], [2], [1], [false]
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

        uncover("3,6", 
            rec_step([*Recursive step (1/2)*], 
            ```sql
            SELECT node_id, dist, f, prev, true
            FROM recurring.astar
            WHERE node_id = min_node_id
            ```)
        ),

        uncover("4,7",
            rec_step([*Recursive step (2/2)*],
            ```sql
            <select neighbors>
            ```  
            )
        ),

        // EDGES
        uncover(1,
            edge((0, -1), "r", (1, 0), "->", arrowtext("appends"))),

        uncover(2,
            edge((1, 0), "u,l,l", (-1, 0), "->", arrowtext("overwrites"), label-side: right)),

        uncover("3-4,6-7",
            edge((-1, 0), "u", (0, -1), "->", arrowtext("read by"), label-side: left, label-pos: 60%, stroke: .4pt),
        ),
        uncover("3-4,6-7",
            edge((1, 0), "u", (0, -1), "->", arrowtext("read by"), label-side: right, label-pos: 60%),
        ),
        uncover("3-4,6-7",
            edge((0, -1), (0, 0), "->", arrowtext("overwrites"))
        ),
        uncover("5,8",
            edge((0, 0), "u,r", (1, 0), shift: 2pt, "->", arrowtext("updates and inserts"))
        ),
        uncover("5,8",
            edge((0, 0), "u,l", (-1, 0), shift: -2pt, "->", arrowtext("overwrites"))
        )
    )
)


== A\*: Classic

#codly-disable()

#align(center + horizon, 
        fletcher-diagram(
        debug: 0,
        spacing: (0pt, 20pt),

        // Working Table
        alternatives(
            cte_table((-1, 0), "working table", ),
            cte_table((-1, 0), "working table", [0], [0], [0], [-], [`false`],),
            cte_table((-1, 0), "working table", [0], [0], [0], [-], [`false`], marked: 1),
            cte_table((-1, 0), "working table", [0], [0], [0], [-], [`false`],
            marked: 1),
            cte_table((-1, 0), "working table", [0], [0], [0], [-], [`false`],),
            cte_table((-1, 0), "working table",
            [0], [0], [0], [-], [`true`],
            [1], [1], [1], [0], [`false`],
            [2], [4], [4], [0], [`false`],
            [0], [0], [0], [-], [`false`]
            ),
            cte_table((-1, 0), "working table",
            [0], [0], [0], [-], [`true`],
            [1], [1], [1], [0], [`false`],
            [2], [4], [4], [0], [`false`],
            [0], [0], [0], [-], [`false`],
            ),

        ),

        // Intermediate Table
        alternatives(
            cte_table((0,0), "intermediate table", ),
            cte_table((0,0), "intermediate table", ),
            cte_table((0,0), "intermediate table", [0], [0], [0], [-], [`true`]),
            cte_table((0,0), "intermediate table", [0], [0], [0], [-], [`true`],
            [1], [1], [1], [0], [`false`],
            [2], [4], [4], [0], [`false`]
            ),
            cte_table((0,0), "intermediate table", [0], [0], [0], [-], [`true`],
            [1], [1], [1], [0], [`false`],
            [2], [4], [4], [0], [`false`],
            [0], [0], [0], [-], [`false`]
            ),
            cte_table((0,0), "intermediate table", [0], [0], [0], [-], [`true`],
            [1], [1], [1], [0], [`false`],
            [2], [4], [4], [0], [`false`],
            [0], [0], [0], [-], [`false`]
            ),
            cte_table((0,0), "intermediate table", 
            [-], [-], [-], [-], [-], )
        ),

        // Union Table
        alternatives(
            cte_table((1, 0), "union table", [0], [0], [0], [-], [`false`]),
            cte_table((1, 0), "union table", [0], [0], [0], [-], [`false`]),
            cte_table((1, 0), "union table", [0], [0], [0], [-], [`false`]),
            cte_table((1, 0), "union table", [0], [0], [0], [-], [`false`]),
            cte_table((1, 0), "union table", [0], [0], [0], [-], [`false`]),
            cte_table((1, 0), "union table", [0], [0], [0], [-], [`false`],
            [0], [0], [0], [-], [`true`],
            [1], [1], [1], [0], [`false`],
            [2], [4], [4], [0], [`false`],
            [0], [0], [0], [-], [`false`]
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

        uncover("3,7", 
            rec_step([*Recursive step (1/3)*], 
            ```sql
            SELECT node_id, dist, f, prev, true
            FROM astar
            WHERE node_id = min_node_id
            ```)
        ),

        uncover("4",
            rec_step([*Recursive step (2/3)*],
            ```sql
            <select neighbors>
            ```  
            )
        ),

        uncover("5",
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

        uncover("3-5,7",
            edge((-1, 0), "u", (0, -1), "->", arrowtext("read by"), label-side: left, label-pos: 60%),
        ),
        uncover("3-5,7",
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

== A\*: Filter the Working Table

#align(center + horizon,

    fletcher-diagram(
        rec_step([],
            ```sql
            WITH filtered_astar (...) AS (
                SELECT 
                    node_id,
                    min(dist), argmin(f, dist), 
                    argmin(prev, dist), bool_or(visited)
                FROM astar 
                GROUP BY node_id
            )
            ```
        ),
        uncover(2, 
            cte_table((-.5, -.2), "astar", 
                [0], [0], [0], [-], [`true`],
                [1], [1], [1], [0], [`false`],
                [2], [4], [4], [0], [`false`],
                [0], [0], [0], [-], [`false`]
            )    
        ),
        uncover(2, 
            cte_table((.5, -.2), "filtered_astar", 
                [0], [0], [0], [-], [`true`],
                [1], [1], [1], [0], [`false`],
                [2], [4], [4], [0], [`false`],
            )    
        ),
        uncover(2,
            edge((-.5, -.2), (-.5, -1), "->",)
        ),
        uncover(2,
            edge((.5, -.2), (.5, -1), "<-")
        )
    ),
)

== A\*: Classic

#align(center + horizon, 
    fletcher-diagram(
        debug: 0,
        spacing: (0pt, 20pt),

        // Working Table
        alternatives(
            cte_table((-1, 0), "filtered_astar", 
                [0], [0], [0], [-], [`true`],
                [1], [1], [1], [0], [`false`],
                [2], [4], [4], [0], [`false`],
                marked: 2
            ),
            cte_table((-1, 0), "filtered_astar", 
                [0], [0], [0], [-], [`true`],
                [1], [1], [1], [0], [`false`],
                [2], [4], [4], [0], [`false`],
                marked: 2
            ),
            cte_table((-1, 0), "filtered_astar", 
                [0], [0], [0], [-], [`true`],
                [1], [1], [1], [0], [`false`],
                [2], [4], [4], [0], [`false`],
            ),
            cte_table((-1, 0), "filtered_astar", 
                [1], [1], [1], [0], [`true`],
                [3], [2], [2], [1], [`false`],
                [0], [0], [0], [-], [`true`],
                [1], [1], [1], [0], [`false`],
                [2], [4], [4], [0], [`false`],
            ),
        ),

        // Intermediate Table
        alternatives(
            cte_table((0,0), "intermediate table", 
                [1], [1], [1], [0], [`true`],
            ),
            cte_table((0,0), "intermediate table", 
                [1], [1], [1], [0], [`true`],
                [3], [2], [2], [1], [`false`]
            ),
            cte_table((0,0), "intermediate table", 
                [1], [1], [1], [0], [`true`],
                [3], [2], [2], [1], [`false`],
                [0], [0], [0], [-], [`true`],
                [1], [1], [1], [0], [`false`],
                [2], [4], [4], [0], [`false`],
            ),
        ),

        // Union Table
        uncover("1-3",
            cte_table((1, 0), "union table", [0], [0], [0], [-], [`false`],
                [0], [0], [0], [-], [`true`],
                [1], [1], [1], [0], [`false`],
                [2], [4], [4], [0], [`false`],
                [0], [0], [0], [-], [`false`]
            ),
        ),

        only(4,
            cte_table((1, 0), "union table", [0], [0], [0], [-], [`false`],
                [0], [0], [0], [-], [`true`],
                [1], [1], [1], [0], [`false`],
                [2], [4], [4], [0], [`false`],
                [0], [0], [0], [-], [`false`],
                [1], [1], [1], [0], [`true`],
                [3], [2], [2], [1], [`false`],
                [0], [0], [0], [-], [`true`],
                [1], [1], [1], [0], [`false`],
                [2], [4], [4], [0], [`false`],
            ),
        ),
        

        // QUERIES
        uncover("1", 
            rec_step([*Recursive step (1/3)*], 
            ```sql
            SELECT node_id, dist, f, prev, true
            FROM astar
            WHERE node_id = min_node_id
            ```)
        ),

        uncover("2",
            rec_step([*Recursive step (2/3)*],
            ```sql
            <select neighbors>
            ```  
            )
        ),

        uncover("3",
            rec_step([*Recursive step (3/3)*],
            ```sql
            <carry working table>
            ```  
            )
        ),

        // EDGES
        uncover("1-3",
            edge((-1, 0), "u", (0, -1), "->", arrowtext("read by"), label-side: left, label-pos: 60%),
        ),
        uncover("1-3",
            edge((0, -1), (0, 0), "->", arrowtext("overwrites"))
        ),
        uncover(4,
            edge((0, 0), "u,r", (1, 0), shift: 2pt, "->", arrowtext("appends"))
        ),
        uncover(4,
            edge((0, 0), "u,l", (-1, 0), shift: -2pt, "->", arrowtext("overwrites"))
        )
    )
)

== A\*: Classic (Query)

#codly-enable()
#grid(
    columns: 2,
    gutter: .5cm,
    ```sql
-- (1) Group equal nodes
WITH filtered_astar (
    node_id,
    dist, f,
    prev,
    visited
) AS (
    SELECT 
        node_id,
        min(dist), argmin(f, dist),
        argmin(prev, dist),
        bool_or(visited)
    FROM astar
    GROUP BY node_id
),
  ```,
  {
  codly(offset: 15)
  ```sql
<using-key recursive step>

UNION 

-- (2) Carry table
SELECT *
FROM filtered_astar
WHERE (SELECT id FROM min_node) != goal_node()
  ```
  }
)
