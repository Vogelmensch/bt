#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#import "definitions.typ": orange

#set heading(numbering: "1.1")
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

= The A\* search algorithm 

The A\* search algorithm solves the shortest path problem for weighted graphs. On graphs with non-negative edge weights, it is guaranteed to terminate and it is complete. A\* can be seen as an expansion of Dijkstra's algorithm, ...

== Dijkstra's algorithm and a heuristic function <astar_basics>

Dijkstra's algorithm solves the shortest path problem for a graph with non-negative edge weights. Given a starting node, the algorithm returns the shortest path and its distance for every node in the graph. Of course, one can also limit the algorithm to halt once a given goal node has been found. This is the approach we want to follow.

We are encoding the graph as one table. An example is shown in @graph_example. We will use this graph for a running example to explain Dijkstra's algorithm.

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

We will explain the algorithm in detail in the following chapters. In a nutshell, in order to find the shortest path to the goal node, we keep a record of all paths we have already taken from the start node to any other node in the graph. Then, in every iteration, we have to decide which node to visit next, out of all nodes we have not visited yet. In Dijkstra's algorithm, from all candidate nodes, we simply visit the node with the shortest overall path. We will now explain how the A\* search algorithm expands this idea with a simple addition.

In Dijkstra's algorithm, the only information we have about the goal node is its `node_id`. In many use cases, however, information is available about the direction in which the goal is located. 
A vivid example is that of route planning. When travelling, say, via train, we can depict the railway network as a graph, with stations being the nodes, railroads being the edges and travel times or distances being the edge weights. We then want to find the fastest route from our current location, the start node, to our destination, the goal node. 
Dijkstra's algorithm approaches this problem by searching in _every_ direction until it finds the destination. While it always finds the best solution, the runtime is obviously not optimal, as we constantly calculate shortest paths for stations which we know to be in the wrong direction.

This problem can be addressed by using a _heuristic function_. In our example of train travel, a heuristic $h$ for a node $n$ (a station) could simply be the air-line distance between this station and the goal node, the destination,

$ 
  h(n) = "dist"(n, "goal_node"). 
$

There are many possibilities to define a heuristic function. In order to return an optimal solution, and to have an optimal runtime, the heuristic function has to meet two criteria.
1. It has to be _admissable_, i.e. it must never overestimate the cost of reaching the goal node, and
2. It has to be consistent, i.e. for every node $n$ and for every neighbor $p$ of $n$, the following formula for the heuristic function $h$ must apply: $ h(n) <= w(n, p) + h(p), $ where $w(n, p)$ is the weight of the edge between nodes $n$ and $p$. 

The A\* search algorithm uses the heuristic function when deciding which node to visit next in each iteration. Instead of visiting the node with the shortest overall path, we visit the node $n$ with the smallest value $f$,
$ f(n) = "dist"(n) + h(n). $

For our train journey, when considering to visit a station located in the opposite direction of our goal, the $h$-value, and thus the $f$-value for this node would be larger than one for a station located in the direction of our destination. 

Because including a heuristic function would make following the running example unnecessarily confusing, we decided not to include one for it; we set all values $h = 0$, as shown in @graph_example. The explanation below still covers the full A\* search algorithm though. For our measurements in (TODO: Link to chapter), we used a heuristic function which be explain in TODO.

== Query Layout

For both variants, we first define two macros for the ids of start- and goal-node respectively, shown in @dijkstra_macros. 

#figure(
  caption: [Macros for Dijkstra, with values being set to match our running example.],
  ```sql
  CREATE MACRO start_node() AS 0;
  CREATE MACRO goal_node() AS 6;
  ```
) <dijkstra_macros>



#figure(
  caption: [Layout of Dijkstra's algorithm for both CTE types in comparison.],
  grid(
    columns: 2,
    column-gutter: 20pt,
    [
      ```SQL
      WITH RECURSIVE dijkstra (
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
      WITH RECURSIVE dijkstra (
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
) <dijkstra_init>

The general layout of the queries is shown in @dijkstra_init. Both variants use the same column names. Every row in `dijkstra` represents a node in the graph, which consists of 
- `node_id` as a unique identifier for the node, taken from the graph, 
- `dist`, the shortest currently known distance from the start node to this node, 
- `f`, which adds the heuristic value for this node to `dist` as explained in @astar_basics,
- `prev`, the `node_id` for the node that leads back to `start_node()` on the fastest currently known path, and
- `visited`, a boolean flag stating whether the node has already been visited. 

During runtime, the values `dist`, `f` and `prev` and constantly being updated as A\* keeps finding shorter paths through the graph. Only when a node is `visited` to we know that those values are optimal. Thus, for the using-key version of the query, we use `node_id` as key, in order to access previously written, and update values for previously selected nodes.


== Base Case

In the base case, the only node known to us is `start_node()`, with a distance from `start_node()` of $"dist"=0$, no previous node, $"prev" = "NULL"$, and the visited flag set to $"visited" = "false"$.

#figure(
  caption: [],
  ```sql
  SELECT 
      start_node(), 
      0,
      h(start_node()),
      NULL, 
      false
  ```
)

== Recursive Step: using-key

The recursive step is the important part of the query. We shall see later that the classic version can be written as an extension of using-key, which is why we start with the latter. @dijkstra_recursive shows the relevant code. It is a CTE that can be separated into three logical parts. Notice that, in every part, we select from the recurring table.

❶st, we select one single node from the recurring table and bind its id to `min_node(id)`. This node has to meet two criteria, as can be seen in the `WHERE` clause: First, it must not be visited. Second, its f-value must be minimal. 
In the first iteration, the only node in the recurring table is the start node. 

❷nd step: We want so visit each node at most once. For this reason, we introduced the `visited` variable at the query start. The `node_id` of the node we are currently visiting has been bound to `min_node(id)` in ❶. Thus, we should udpate its `visited` value to `true`.
Keep in mind that we are currently working with using-key. Because we set the `key` to `node_id` at the start, when updating the values for the currently visited node, the values get updated in the dictionary. 

❸rd step: The goal of this step is to take all neighbors of `min_node` and update their `dist`-values, if it turns out that the path over `min_node` is shorter. 

First, notice that the first line of the `FROM`-clause and the first two lines of the `WHERE`-clause are identical to ❷, the only difference being that we bind `mind_node` to the name `sml` (standing for "smallest") here. The second line in the `FROM`-clause binds the graph to the name `nbs` ("neighbors"), on the condition `sml.node_id = nbs.node_from`. With this, we can select the `node_id`s of all neighbors of `min_node` by selecting `nbs.node_to`. We immediately use this in the third line of the `FROM`-clause, where we bind the recurring table to the name `old`, on the conidtion `nbs.node_to = old.node_id`. With this, we have access to the values of `smallest`'s neighbors, by selecting `old`. Notice that we used a `LEFT OUTER JOIN` to join `old`, which returns `NULL`-values for neighbors which are not part of the dictionary yet.

With this preparation, we are able to understand the third line of the `WHERE`-clause. This line is the heart of Dijkstra's algorithm. It defines the final condition on which values are being selected. Rewriting the `coalesce`-function in a mathematical way, it looks like this:

$ 
  "coalesce"(a, b) = cases(
    a "if" a != "NULL",
    b "else"
  )
$

`old.dist` can be `NULL`, as explained in the previous paragraph. In this case, the condition is `true` by default. Otherwise we evaluate the condition, `sml.dist + nbs.weight < old.dist`. Only nodes for which this condition is `true`, i.e. nodes for which the path over `min_node` is smaller than their current shortest path, will be selected in this step.

Finally, we examine the `SELECT`-clause. With the conditions mentioned above, we have just found a set of neighbors which either have never been selected before, or for which we found a shorter path. We now set or update those neighbor's entries in the dictionary, respectively.
- `nbs.node_to` is the neighbor's `node_id`, as explained above.
- as `sml.dist + nbs.weight` is the shortest path currently known to reach this neighbor, we set both `dist` and `f` to this value.
- as we found this smallest path by going over `min_node`, we set its id, `sml.node_id`, to be previous node `prev` in the path to reach the neighbor.
- the neighbor has still not been visited yet. 

#figure(
  
  caption: [Recursive step of Dijkstra's algorithm for using-key],
  [
    ```sql
    -- ❶ Find node_id of the node with minimal f-value
    WITH min_node(id) AS (
        SELECT node_id
        FROM recurring.astar
        WHERE 
            NOT visited AND 
            f = (SELECT min(f) FROM recurring.astar WHERE NOT visited)
        LIMIT 1
    )

    -- ❷ Set visited = true for the minimal node
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

    -- ❸ Update or insert neighbors of the minimal node
    SELECT
        nbs.node_to,                            
        sml.dist + nbs.weight,                  
        sml.dist + nbs.weight + nbs.h, 
        sml.node_id,                            
        false                                   
    FROM
        recurring.astar AS sml JOIN                                              
        {graph}         AS nbs ON sml.node_id = nbs.node_from LEFT OUTER JOIN
        recurring.astar AS old ON nbs.node_to = old.node_id                      
    WHERE 
        sml.node_id = (SELECT id FROM min_node) AND                             
        sml.node_id != goal_node() AND 
        sml.dist + nbs.weight < coalesce(old.dist, CAST('inf' AS FLOAT))
    ```
  ]
) <dijkstra_recursive>


== Recursive Step: classic

The classic version of A\* can be viewed as an extension of the using-key version. We follow the same approach, however, because we can only access values which have been calculated in the previous iteration, we have to carry all values manually. This vastly increases the size of the union table.

@dijkstra_classic shows the relevant code. The dict-based recursive step from @dijkstra_recursive can be inserted at the marked spot if replacing every occurence of `recurring.table` with `filtered_dijkstra`. Additionally, two code blocks are required.

❶st, as multiple occurences of the same key can appear in the union table, we need to specify which one should be selected. This is what the CTE `filtered_dijkstra` does. To decide which values to select and which to discard, we can use the nature of Dijkstra's algorithm:
1. A new entry for a given node is only being generated if a smaller distance to this node has been found. Thus, we should select `min(dist)` and `argmin(f, dist)`, `argmin(prev, dist)`, respectively.
2. If a node has been marked as `visited`, it will never be selected again. Thus, if one instance of the node has its `visited`-value set to `true`, we should select `true` overall - which can simply be implemented by `bool_or(visited)`.

❷ndly, after all other values have been selected, we need to carry to rest of the table in order to not lose any information. For this, we simply select the entire `filtered_dijkstra`-table. The `WHERE`-clause implements the break condition.

#figure(
  caption: [Recursive step of Dijkstra's algorithm for classic, based on the dict-based version.],
  
  ```sql
  -- ❶ Group equal nodes
  WITH filtered_dijkstra (
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

  -- <dict-based recursive step>

  UNION 

  -- ❷ Carry table
  SELECT *
  FROM filtered_dijkstra
  WHERE (SELECT id FROM min_node) != goal_node()
  ```
) <dijkstra_classic>


TODO: Maybe move the full query to the appendix or something. Or just say which lines to change.

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
  caption: [],
  table(
    columns: 4,
    table.header([*Iteration*], table.vline(stroke: 1pt), [*visit node with smallest f-value*], [*update `visited` for smallest*],[*update or insert neighbors of smallest*]),
    table.hline(stroke: 1pt),
    stroke: none,
    align: (x, y) => if x == 0 or y == 0 {horizon} else {top},

    [1], 
    dijk(
      marked: 1,
      table.hline(),
      table.cell([0], fill: white),table.cell([0], fill: white),table.cell([0], fill: white),table.cell([None], fill: white),table.cell([false], fill: white),
    ),
    dijk(
      table.cell([0], fill: white),table.cell([0], fill: white),table.cell([0], fill: white),table.cell([None], fill: white),table.cell([true], fill: orange),
    ),
    dijk(
      table.cell([0], fill: white),table.cell([0], fill: white),table.cell([0], fill: white),table.cell([None], fill: white),table.cell([true], fill: white),
      table.cell([1], fill: lime), table.cell([1], fill: lime),table.cell([1], fill: lime),table.cell([0], fill: lime),table.cell([false], fill: lime),
      table.cell([2], fill: lime), table.cell([4], fill: lime),table.cell([4], fill: lime),table.cell([0], fill: lime),table.cell([false], fill: lime),
    ),

    [2],
    dijk(
      marked: 2,
      [0], [0], [0], [None], [true],
      table.cell([1], fill: white), table.cell([1], fill: white),table.cell([1], fill: white),table.cell([0], fill: white),table.cell([false], fill: white),
      [2], [4], [4], [0], [false],
    ),
    dijk(
      [0], [0], [0], [None], [true],
      table.cell([1], fill: white), table.cell([1], fill: white),table.cell([1], fill: white),table.cell([0], fill: white),table.cell([true], fill: orange),
      [2], [4], [4], [0], [false],
    ),
    dijk(
      [0], [0], [0], [None], [true],
      table.cell([1], fill: white), table.cell([1], fill: white),table.cell([1], fill: white),table.cell([0], fill: white),table.cell([true], fill: white),
      [2], [4], [4], [0], [false],
      table.cell([3], fill:lime),table.cell([2], fill:lime),table.cell([2], fill:lime),table.cell([1], fill:lime),table.cell([false], fill:lime),
    ),

    [3],
    dijk(
      marked: 4,
      [0], [0], [0], [None], [true],
      table.cell([1], fill: white), table.cell([1], fill: white),table.cell([1], fill: white),table.cell([0], fill: white),table.cell([true], fill: white),
      [2], [4], [4], [0], [false],
      table.cell([3], fill:white),table.cell([2], fill:white),table.cell([2], fill:white),table.cell([1], fill:white),table.cell([false], fill:white)
    ),
    dijk(
      [0], [0], [0], [None], [true],
      table.cell([1], fill: white), table.cell([1], fill: white),table.cell([1], fill: white),table.cell([0], fill: white),table.cell([true], fill: white),
      [2], [4], [4], [0], [false],
      table.cell([3], fill:white),table.cell([2], fill:white),table.cell([2], fill:white),table.cell([1], fill:white),table.cell([true], fill:orange),
    ),
    dijk(
      [0], [0], [0], [None], [true],
      table.cell([1], fill: white), table.cell([1], fill: white),table.cell([1], fill: white),table.cell([0], fill: white),table.cell([true], fill: white),
      [2], table.cell([3], fill:orange), table.cell([3], fill:orange), table.cell([3], fill:orange), [false],
      table.cell([3], fill:white),table.cell([2], fill:white),table.cell([2], fill:white),table.cell([1], fill:white),table.cell([true], fill:white),
      table.cell([4], fill:lime),table.cell([3], fill:lime),table.cell([3], fill:lime),table.cell([3], fill:lime),table.cell([false], fill:lime),
      table.cell([5], fill:lime),table.cell([5], fill:lime),table.cell([5], fill:lime),table.cell([3], fill:lime),table.cell([false], fill:lime),
    ),

    [4],
    dijk(
      marked: 5,
      [0], [0], [0], [None], [true],
      table.cell([1], fill: white), table.cell([1], fill: white),table.cell([1], fill: white),table.cell([0], fill: white),table.cell([true], fill: white),
      [2], table.cell([3], fill:white), table.cell([3], fill:white), [3], [false],
      table.cell([3], fill:white),table.cell([2], fill:white),table.cell([2], fill:white),table.cell([1], fill:white),table.cell([true], fill:white),
      table.cell([4], fill:white),table.cell([3], fill:white),table.cell([3], fill:white),table.cell([3], fill:white),table.cell([false], fill:white),
      table.cell([5], fill:white),table.cell([5], fill:white),table.cell([5], fill:white),table.cell([3], fill:white),table.cell([false], fill:white),
    ),
    dijk(
      [0], [0], [0], [None], [true],
      table.cell([1], fill: white), table.cell([1], fill: white),table.cell([1], fill: white),table.cell([0], fill: white),table.cell([true], fill: white),
      [2], table.cell([3], fill:white), table.cell([3], fill:white), [3], [false],
      table.cell([3], fill:white),table.cell([2], fill:white),table.cell([2], fill:white),table.cell([1], fill:white),table.cell([true], fill:white),
      table.cell([4], fill:white),table.cell([3], fill:white),table.cell([3], fill:white),table.cell([3], fill:white),table.cell([true], fill:orange),
      table.cell([5], fill:white),table.cell([5], fill:white),table.cell([5], fill:white),table.cell([3], fill:white),table.cell([false], fill:white),
    ),
    dijk(
      [0], [0], [0], [None], [true],
      table.cell([1], fill: white), table.cell([1], fill: white),table.cell([1], fill: white),table.cell([0], fill: white),table.cell([true], fill: white),
      [2], table.cell([3], fill:white), table.cell([3], fill:white), [3], [false],
      table.cell([3], fill:white),table.cell([2], fill:white),table.cell([2], fill:white),table.cell([1], fill:white),table.cell([true], fill:white),
      table.cell([4], fill:white),table.cell([3], fill:white),table.cell([3], fill:white),table.cell([3], fill:white),table.cell([true], fill:white),
      table.cell([5], fill:white),table.cell([4], fill:orange),table.cell([4], fill:orange),table.cell([4], fill:orange),table.cell([false], fill:white),
    ),
  )
)


== Heuristic function for air distance

TODO: zeige die query, die h-values erstellt