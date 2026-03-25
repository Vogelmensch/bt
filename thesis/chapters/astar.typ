#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#import "definitions.typ": orange

#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#show: codly-init.with()
#codly(
  languages: (
    sql: (name: "SQL", icon: "🦆", )
  )
)
#codly-enable()

#set heading(numbering: "1.1")
#set math.equation(numbering: "(1.1)")
#set table.vline(stroke: .5pt)
#set table.hline(stroke: .5pt)

#let example_graph() = diagram(
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

== A\* search algorithm <astar>

The A\* search algorithm solves the shortest path problem for weighted graphs. It can be seen as an expansion of Dijkstra's algorithm, wich is guaranteed to finds the optimal solution in minimal time on graphs with non-negative edge weights. A\* expands Dijkstra by adding a heuristic function to the cost function. If this heuristic function meets certain criteria (explained in @astar_basics), A\* always returns an optimal solution under optimal runtime.

=== Dijkstra's algorithm and a heuristic function <astar_basics>

Dijkstra's algorithm solves the shortest path problem for a graph with non-negative edge weights. Given a starting node, the algorithm returns the shortest path and its distance for every node in the graph. Of course, one can also limit the algorithm to halt once a given goal node has been found. This is the approach we want to follow.

We are encoding the graph as one table. An example is shown in @graph_example. We use this graph for a running example to explain Dijkstra's algorithm first before expanding it to A\*.

#figure(
  caption: [Example graph (left) and the first rows of its table representation (right)],
  grid(
    rows: 1,
    columns: 2,
    gutter: 10pt,
    example_graph(),
    table(
      rows: 8,
      columns: 4,
      stroke: none,
      table.header(
        [*node_from*],
        table.vline(stroke: .5pt),
        [*node_to*],
        table.vline(stroke: .5pt),
        [*weight*],
        table.vline(stroke: .5pt),
        [*h*]
      ),
        table.hline(stroke: .5pt),
      $0$, $1$, $1$, $0$,
      $1$, $0$, $1$, $0$,
      $0$, $2$, $4$, $0$,
      $2$, $0$, $4$, $0$,
      $1$, $3$, $1$, $0$,
      $3$, $1$, $1$, $0$,
      "...", "...", "...", "..."
    )
  ),
) <graph_example>

We explain the algorithm in detail in the following sections. In a nutshell, in order to find the shortest path to the goal node, we keep a record of all paths we have already taken from the start node to any other node in the graph. Then, in every iteration, we have to decide which node to visit next, out of all nodes we have not visited yet. In Dijkstra's algorithm, from all candidate nodes, we simply visit the node with the shortest overall path. We now explain how the A\* search algorithm expands this idea with a simple addition.

In Dijkstra's algorithm, the only information we have about the goal node is its `node_id`. In many use cases, however, information is available about the direction in which the goal is located. 
A vivid example is that of route planning. When travelling, say, via train, we can depict the railway network as a graph, with stations as nodes, railroads as edges and travel times or distances as edge weights. We then want to find the fastest route from our current location, the start node, to our destination, the goal node. 
Dijkstra's algorithm approaches this problem by searching in _every_ direction until it finds the destination. While it always finds the best solution, the runtime is not optimal, as we constantly calculate shortest paths for stations which we know to be in the wrong direction.

This problem can be addressed by using a _heuristic function_. In our example of train travel, a heuristic $h$ for a node $n$ (a station) could simply be the air-line distance between this station and the goal node, the destination,

$ 
  h(n) = "dist"(n, "goal_node"). 
$

There are many possibilities to define a heuristic function. In order to return an optimal solution, and to have an optimal runtime, the heuristic function has to meet two criteria.
1. It has to be _admissable_, i.e. it must never overestimate the cost of reaching the goal node, and
2. It has to be consistent, i.e. for every node $n$ and for every neighbor $p$ of $n$, the following formula for the heuristic function $h$ must apply: $ h(n) <= w(n, p) + h(p), $ where $w(n, p)$ is the weight of the edge between nodes $n$ and $p$. 

The A\* search algorithm uses the heuristic function when deciding which node to visit next in each iteration. Instead of visiting the node with the shortest overall path $"path_length(n)"$, we visit the node $n$ with the smallest value $f$,
$ f(n) = "path_length"(n) + h(n). $

For our train journey, when considering to visit a station located in the opposite direction of our goal, the $h$-value, and thus the $f$-value for this node would likely be larger than one for a station located in the direction of our destination. 

For us, because including a heuristic function would make following our running example unnecessarily confusing, we decided not to include one for it; we set all values $h = 0$, as shown in @graph_example. The explanation below still covers the full A\* search algorithm though. For our measurements in @measuring, we used a heuristic function which we explain in @heuristic.

=== Query Layout <astar_layout>

We define macros `start_node()` and `goal_node()` for the ids of start- and goal-node respectively

#figure(
  caption: [Layout of A\* for classic (left) and using-key (right).],
  placement: auto,
  grid(
    columns: 2,
    column-gutter: 20pt,
    [
      ```SQL
      WITH RECURSIVE astar (
        node_id,
        dist,
        f,
        prev,
        visited
      ) AS (
        <base case>

        UNION ALL

        (<recursive step>)
      )
      <outer query>
      ```
    ],
    [
      ```SQL
      WITH RECURSIVE astar (
        node_id,
        dist,
        f,
        prev,
        visited
      ) USING KEY (node_id) AS (
        <base case>

        UNION 

        (<recursive step>)
      )
      <outer query>
      ```
    ]
  )
) <astar_init>

The general layouts of the queries are shown in @astar_init. Both variants use the same column names. Every row in `astar` represents a node in the graph, which consists of 
- `node_id` as a unique identifier for the node, taken from the graph, 
- `dist`, the shortest currently known distance from the start node to this node, 
- `f`, which adds the heuristic value for this node to `dist` as explained in @astar_basics,
- `prev`, the `node_id` for the node that leads back to `start_node()` on the fastest currently known path, and
- `visited`, a boolean flag stating whether the node has already been visited. 

During runtime, the values `dist`, `f` and `prev` and constantly being updated as A\* keeps finding shorter paths through the graph. Only when a node is `visited` we know its values to be optimal. Thus, for the using-key version of the query, we use `node_id` as key, in order to access and update values for previously selected nodes.


=== Base Case

@astar_base_case shows the base case. The only known node is `start_node()`, with a distance from `start_node()` of `dist = 0`, the f-value is the heuristic function's value for this node, `f = h(start_node())`, no previous node could lead to itself, `prev = NULL`, and the visited flag set to `visited = false`.

#figure(
  caption: [Base case for A\*.],
  ```sql
  SELECT 
      start_node(), 
      0,
      h(start_node()),
      NULL, 
      false
  ```
) <astar_base_case>

=== Recursive Step: using-key <rec_step_using_key_chapter>

We see in @rec_step_classic_chapter that the classic variant of A\* can be written as an extension of using-key, which is why we start with the latter. @astar_recursive shows the recursive step of the query. It is itself a CTE that can be separated into three logical parts. Notice that, in every part, we select from the recurring table.
To follow along, @astar_example illustrates each step for our running example in the first four iterations. 

`(1)` We select one node with minimal f-value from the recurring table and bind its id to `min_node(id)`. Because every node can be `visited` only once in the entire process, it must not have been `visited` before, as stated in the `WHERE` clause.

`(2)` We now mark `min_node` as `visited` for future iterations. If `min_node` turns out to be the `goal_node()`, we end the iteration, as defined by the condtion `node_id != goal_node()` in this and the next step.

`(3)` The goal of this step is to take all neighbors of `min_node` and update their values for `dist`, `f` and `prev`, if it turns out that the path over `min_node` is shorter than the respective shortest path found so far. We explain this step in the following paragraphs.

First, notice that @astar_recursive:30, @astar_recursive:34 and @astar_recursive:35 are identical to ❷, the only difference being that we bind `min_node` to the name `sml` (standing for "smallest") here. @astar_recursive:31 binds the `graph` to the name `nbs` ("neighbors"), on the condition `sml.node_id = nbs.node_from`. With this, we can select the `node_id`s of all neighbors of `min_node` by selecting `nbs.node_to`. We immediately use this in @astar_recursive:32, where we bind the recurring table to the name `old`, on the conidtion `nbs.node_to = old.node_id`. With this, we have access to the values of `min_nodes`' neighbors, by selecting from `old`. Notice the `LEFT OUTER JOIN` we used to join `old`, which returns `NULL`-values for neighbors which are not part of the recurring table yet.

With this preparation, we are able to understand @astar_recursive:36. This line is the heart of Dijkstra's algorithm. It defines the final condition on which values are being selected. @coalesce shows the `coalesce`-function in mathematical notation: It selects a value only if it is not `NULL`, and provides an alternative otherwise.

$ 
  "coalesce"(a, b) = cases(
    a "if" a != "NULL",
    b "else"
  )
$ <coalesce>

`old.dist` is  `NULL` if `old` has not been selected before. In this case, the condition is `true` by default, as $x < infinity, forall x in RR$. Otherwise we evaluate the condition, `sml.dist + nbs.weight < old.dist`. Only nodes for which this condition is `true`, i.e. nodes for which the path over `min_node` is shorter than their currently known shortest path, are selected in this step.

Finally, we examine the `SELECT`-clause. With the conditions mentioned above, we have just found a set of neighbors which either have never been selected before, or for which we found a shorter path by going over `min_node`. We now update or insert those neighbor's entries in the recurring table:
- `nbs.node_to` is the neighbor's `node_id`, as explained above.
- as `sml.dist + nbs.weight` is the shortest path currently known to reach this neighbor, we set `dist` to this value.
- we add the heuristic to `dist` to get the `f`-value, `sml.dist + nbs.weight + nbs.h`.
- as we found this smallest path by going over `min_node`, we set `sml.node_id`, to be the previous node `prev` in the path to reach this neighbor.
- the neighbor has still not been `visited` yet. 

#figure(
  caption: [Recursive step of A\* for using-key],
  placement: auto,
  [
    ```sql
    -- (1) Find node_id of the node with minimal f-value
    WITH min_node(id) AS (
        SELECT argmin(node_id, f)
        FROM recurring.astar
        WHERE NOT visited
    )

    -- (2) Set visited = true for the minimal node
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

    UNION

    -- (3) Update or insert neighbors of the minimal node
    SELECT
        nbs.node_to,                            
        sml.dist + nbs.weight,                  
        sml.dist + nbs.weight + nbs.h, 
        sml.node_id,                            
        false                                   
    FROM
        recurring.astar                 AS sml
        JOIN graph                      AS nbs ON sml.node_id = nbs.node_from 
        LEFT OUTER JOIN recurring.astar AS old ON nbs.node_to = old.node_id
    WHERE 
        sml.node_id = (SELECT id FROM min_node) AND                             
        sml.node_id != goal_node() AND 
        sml.dist + nbs.weight < coalesce(old.dist, 'inf' :: FLOAT)
    ```
  ]
) <astar_recursive>

#let marking_color = red + 0.8pt

#let dijk(marked: none, ..cont) = table(
      columns: 5,
      stroke: none,
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

#figure(
  caption: [Running example of A\* for using-key. Rows outlined in red mark currently visited nodes; orange values are being updated, while green values are being inserted.],
  placement: bottom,
  table(
    columns: 4,
    table.header([*Iteration*], table.vline(stroke: 1pt), [*❶: visit node with smallest f-value*], [*❷: update `visited` for `smallest`*],[*❸: update or insert neighbors of `smallest`*]),
    table.hline(stroke: 1pt),
    stroke: none,
    align: (x, y) => if y == 0 {horizon} else {top},

    [1], 
    dijk(
      marked: 1,
      table.hline(),
      table.cell([0], fill: white),table.cell([0], fill: white),table.cell([0], fill: white),table.cell([`NULL`], fill: white),table.cell([false], fill: white),
    ),
    dijk(
      table.cell([0], fill: white),table.cell([0], fill: white),table.cell([0], fill: white),table.cell([`NULL`], fill: white),table.cell([true], fill: orange),
    ),
    dijk(
      table.cell([0], fill: white),table.cell([0], fill: white),table.cell([0], fill: white),table.cell([`NULL`], fill: white),table.cell([true], fill: white),
      table.cell([1], fill: lime), table.cell([1], fill: lime),table.cell([1], fill: lime),table.cell([0], fill: lime),table.cell([false], fill: lime),
      table.cell([2], fill: lime), table.cell([4], fill: lime),table.cell([4], fill: lime),table.cell([0], fill: lime),table.cell([false], fill: lime),
    ),

    [2],
    dijk(
      marked: 2,
      [0], [0], [0], [`NULL`], [true],
      table.cell([1], fill: white), table.cell([1], fill: white),table.cell([1], fill: white),table.cell([0], fill: white),table.cell([false], fill: white),
      [2], [4], [4], [0], [false],
    ),
    dijk(
      [0], [0], [0], [`NULL`], [true],
      table.cell([1], fill: white), table.cell([1], fill: white),table.cell([1], fill: white),table.cell([0], fill: white),table.cell([true], fill: orange),
      [2], [4], [4], [0], [false],
    ),
    dijk(
      [0], [0], [0], [`NULL`], [true],
      table.cell([1], fill: white), table.cell([1], fill: white),table.cell([1], fill: white),table.cell([0], fill: white),table.cell([true], fill: white),
      [2], [4], [4], [0], [false],
      table.cell([3], fill:lime),table.cell([2], fill:lime),table.cell([2], fill:lime),table.cell([1], fill:lime),table.cell([false], fill:lime),
    ),

    [3],
    dijk(
      marked: 4,
      [0], [0], [0], [`NULL`], [true],
      table.cell([1], fill: white), table.cell([1], fill: white),table.cell([1], fill: white),table.cell([0], fill: white),table.cell([true], fill: white),
      [2], [4], [4], [0], [false],
      table.cell([3], fill:white),table.cell([2], fill:white),table.cell([2], fill:white),table.cell([1], fill:white),table.cell([false], fill:white)
    ),
    dijk(
      [0], [0], [0], [`NULL`], [true],
      table.cell([1], fill: white), table.cell([1], fill: white),table.cell([1], fill: white),table.cell([0], fill: white),table.cell([true], fill: white),
      [2], [4], [4], [0], [false],
      table.cell([3], fill:white),table.cell([2], fill:white),table.cell([2], fill:white),table.cell([1], fill:white),table.cell([true], fill:orange),
    ),
    dijk(
      [0], [0], [0], [`NULL`], [true],
      table.cell([1], fill: white), table.cell([1], fill: white),table.cell([1], fill: white),table.cell([0], fill: white),table.cell([true], fill: white),
      [2], table.cell([3], fill:orange), table.cell([3], fill:orange), table.cell([3], fill:orange), [false],
      table.cell([3], fill:white),table.cell([2], fill:white),table.cell([2], fill:white),table.cell([1], fill:white),table.cell([true], fill:white),
      table.cell([4], fill:lime),table.cell([3], fill:lime),table.cell([3], fill:lime),table.cell([3], fill:lime),table.cell([false], fill:lime),
      table.cell([5], fill:lime),table.cell([5], fill:lime),table.cell([5], fill:lime),table.cell([3], fill:lime),table.cell([false], fill:lime),
    ),

    [4],
    dijk(
      marked: 5,
      [0], [0], [0], [`NULL`], [true],
      table.cell([1], fill: white), table.cell([1], fill: white),table.cell([1], fill: white),table.cell([0], fill: white),table.cell([true], fill: white),
      [2], table.cell([3], fill:white), table.cell([3], fill:white), [3], [false],
      table.cell([3], fill:white),table.cell([2], fill:white),table.cell([2], fill:white),table.cell([1], fill:white),table.cell([true], fill:white),
      table.cell([4], fill:white),table.cell([3], fill:white),table.cell([3], fill:white),table.cell([3], fill:white),table.cell([false], fill:white),
      table.cell([5], fill:white),table.cell([5], fill:white),table.cell([5], fill:white),table.cell([3], fill:white),table.cell([false], fill:white),
    ),
    dijk(
      [0], [0], [0], [`NULL`], [true],
      table.cell([1], fill: white), table.cell([1], fill: white),table.cell([1], fill: white),table.cell([0], fill: white),table.cell([true], fill: white),
      [2], table.cell([3], fill:white), table.cell([3], fill:white), [3], [false],
      table.cell([3], fill:white),table.cell([2], fill:white),table.cell([2], fill:white),table.cell([1], fill:white),table.cell([true], fill:white),
      table.cell([4], fill:white),table.cell([3], fill:white),table.cell([3], fill:white),table.cell([3], fill:white),table.cell([true], fill:orange),
      table.cell([5], fill:white),table.cell([5], fill:white),table.cell([5], fill:white),table.cell([3], fill:white),table.cell([false], fill:white),
    ),
    dijk(
      [0], [0], [0], [`NULL`], [true],
      table.cell([1], fill: white), table.cell([1], fill: white),table.cell([1], fill: white),table.cell([0], fill: white),table.cell([true], fill: white),
      [2], table.cell([3], fill:white), table.cell([3], fill:white), [3], [false],
      table.cell([3], fill:white),table.cell([2], fill:white),table.cell([2], fill:white),table.cell([1], fill:white),table.cell([true], fill:white),
      table.cell([4], fill:white),table.cell([3], fill:white),table.cell([3], fill:white),table.cell([3], fill:white),table.cell([true], fill:white),
      table.cell([5], fill:white),table.cell([4], fill:orange),table.cell([4], fill:orange),table.cell([4], fill:orange),table.cell([false], fill:white),
    ),
  )
) <astar_example>


=== Recursive Step: classic <rec_step_classic_chapter>

The classic variant of A\* can be viewed as an extension of the using-key variant. We follow the same approach; however, because we can only access values which have been calculated in the previous iteration, we have to carry all values manually. This vastly increases the size of the union table.

@astar_classic shows the recursive step of the classic query. The using-key variant can be inserted at the marked spot by replacing every occurence of `recurring.table` within @astar_recursive with `filtered_astar`. Additionally, two more code blocks are required.

`(1)`: As multiple occurences of the same key can appear in the union table, we need to specify which one should be selected. This is what the CTE `filtered_astar` does. To decide which values to select and which to discard, we can use the nature of Dijkstra's algorithm:
1. A new entry for a given node is only being generated if a smaller distance to this node has been found. Thus, we should select `min(dist)` and `argmin(f, dist)`, `argmin(prev, dist)`, respectively.
2. If a node has been marked as `visited`, it will never be selected again. Thus, if one instance of the node has its `visited`-value set to `true`, we should select `true` overall - which can simply be implemented by `bool_or(visited)`.

`(2)`: After all other values have been selected, we need to carry to rest of the table in order to not lose any information. For this, we simply select the entire `filtered_astar`-table. The `WHERE`-clause implements the break condition.

#figure(
  caption: [Comparison of table sizes for our example graph.],
  placement: auto,
  table(
    rows: 3,
    columns: 8,
    stroke: none,

    [Iteration], table.vline(), ..range(0, 7).map(str),
    table.hline(),
    [Items in recurring table], [1], [3], [4], [6], [7], [7], [7],
    table.hline(),
    [Items in union table], [1], [5], [10], [18], [26], [34], [43],
  )
) <astar_table_size_comparison>

#figure(
  caption: [Recursive step of A\* for classic, based on the using-key variant.],
  placement: auto,
  
  ```sql
  -- (1) Group equal nodes
  WITH filtered_astar (
      node_id,
      dist,
      f,
      prev,
      visited
  ) AS (
      SELECT 
          node_id,
          min(dist),
          argmin(f, dist),
          argmin(prev, dist),
          bool_or(visited)
      FROM astar
      GROUP BY node_id
  ),

  <using-key recursive step>

  UNION 

  -- (2) Carry table
  SELECT *
  FROM filtered_astar
  WHERE (SELECT id FROM min_node) != goal_node()
  ```
) <astar_classic>

In @astar_example, the state of the recurring table after each iteration is shown in the last column. We can see it growing slowly. Showing all iterations for both CTE variants in this way would be too much. Instead in @astar_table_size_comparison, we list the size of the union- and recurring table at each iteration for comparison. Notice how the union table grows much faster.



