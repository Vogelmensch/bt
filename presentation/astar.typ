#import "@preview/touying:0.7.1": *
#import themes.simple: *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#let fletcher-diagram = touying-reducer.with(reduce: fletcher.diagram, cover: fletcher.hide)


#let marking_color = red + 1.2pt

#let dijk(marked: none, ..cont) = table(
      columns: 5,
      stroke: none,
      align: center,
      table.header(
        [*id*],  [*dist*],  [*f*],  [*prev*], [*vis?*]
      ),
      table.hline(),
      ..cont,

      ..if marked != none {
        (
        table.hline(y: marked+1, stroke: marking_color),
        table.hline(y: marked, stroke: marking_color),
        table.vline(x: 0, start: marked, end: marked+1, stroke: marking_color),
        table.vline(x: 5, start: marked, end: marked+1, stroke: marking_color)
        )
      } 
)

#let example_graph(marked) = diagram(
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
    
      node(A, $0$)
      node(B, $1$)
      node(C, $2$)
      node(D, $3$, stroke: if marked {red+1.2pt} else {black})
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

== A\*


#grid(
    columns: 2,
    gutter: 1cm,
    
    grid(
        gutter: 1cm,
        [
            ```sql
            WITH min_node(id) AS (
                SELECT argmin(node_id, f)
                FROM recurring.astar
                WHERE NOT visited
            )
            ```
        ],
        dijk(
            [0], [0], [0], [`NULL`], [`true`],
            [1], [1], [1], [0], [`true`],
            [2], [4], [4], [0], [`false`],
            [3], [2], [2], [1], [`false`],

        )
    ),
    example_graph(false)
)

== A\*


#grid(
    columns: 2,
    gutter: 1cm,
    
    grid(
        gutter: 1cm,
        [
            ```sql
            WITH min_node(id) AS (
                SELECT argmin(node_id, f)
                FROM recurring.astar
                WHERE NOT visited
            )
            ```
        ],
        dijk(
            marked: 4,
            [0], [0], [0], [`NULL`], [`true`],
            [1], [1], [1], [0], [`true`],
            [2], [4], [4], [0], [`false`],
            [3], [2], [2], [1], [`false`],

        )
    ),
    example_graph(true)
)

== A\*


#grid(
    columns: 2,
    gutter: 1cm,
    
    [
        ```sql
        SELECT 
            node_id, 
            dist, 
            f,
            prev, 
            true
        FROM recurring.astar
        WHERE 
            node_id = (SELECT id FROM min_node) AND 
            node_id != goal_node()
        ```
    ],
    dijk(
        marked: 4,
        [0], [0], [0], [`NULL`], [`true`],
        [1], [1], [1], [0], [`true`],
        [2], [4], [4], [0], [`false`],
        [3], [2], [2], [1], [`false`],
    )
)

== A\*


#grid(
    columns: 2,
    gutter: 1cm,
    
    [
        ```sql
        SELECT 
            node_id, 
            dist, 
            f,
            prev, 
            true
        FROM recurring.astar
        WHERE 
            node_id = (SELECT id FROM min_node) AND 
            node_id != goal_node()
        ```
    ],
    dijk(
        marked: 4,
        [0], [0], [0], [`NULL`], [`true`],
        [1], [1], [1], [0], [`true`],
        [2], [4], [4], [0], [`false`],
        [3], [2], [2], [1], [`true`],
    )
)



== A\*

#uncover(
4,
```sql
    SELECT
        nbs.node_to,                   -- node_id                            
        sml.dist + nbs.weight,         -- dist                  
        sml.dist + nbs.weight + nbs.h, -- f
        sml.node_id,                   -- prev                            
        false                          -- visited                       
```  
)    
```sql
    FROM
        recurring.astar                 AS sml
```
#uncover(
    "2-",
```sql
        JOIN graph                      AS nbs ON sml.node_id = nbs.node_from 
```
)
#uncover(
"3-",
```sql
        LEFT OUTER JOIN recurring.astar AS old ON nbs.node_to = old.node_id
```)
```sql
    WHERE 
        sml.node_id = (SELECT id FROM min_node) AND                             
        sml.node_id != goal_node()              AND 
```
#uncover(
    "3-",
```sql
        sml.dist + nbs.weight < coalesce(old.dist, 'inf' :: FLOAT)
```)



