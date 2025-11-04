-- This query implements The A* Search Algorithm, or just 'A*' for short
-- It finds the shortest path between a start- and a goal-node in a graph
-- The graph can be directed or undirected
-- The graph can be weighted, but all weights must be non-negative
-- ❶ A* uses a problem-specific heuristic function to estimate the distance to the goal node
-- ❷ Initial Case: The start node has a distance of zero, no parent and has not been visited yet.
-- ❸ Filter out old nodes if last iteration returned new values (this step is not needed in USING KEY version)
-- ❹ Select the node with minimal f-value; choose one at random if multiple exist
-- If this node is the goal node, then stop the recursion
-- ❺ Set 'visited' to TRUE for the unvisited node with smallest distance
-- ❻ If the distance from the smallest node to their neighbor(s) is smaller then previously, then update the neighbor(s)
-- ❼ Carry all values from previous iteration
-- Working Table: Holds all the nodes that have been seen (but not necessarily visited)
-- Union Table: Holds every value that has ever been calculated for every node

CREATE OR REPLACE MACRO start_node() AS {start_node};
CREATE OR REPLACE MACRO goal_node() AS {goal_node};

-- ❶ A* uses a problem-specific heuristic function to estimate the distance to the goal node
CREATE OR REPLACE MACRO h(x) AS {heuristic};

WITH RECURSIVE dijkstra (
    node_id,
    dist,       -- shortest distance to this node
    f,          -- f = dist + h, where h is the heuristic function (estimated distance to the goal)
    prev,       -- previous node; backtrack to find the shortest path
    visited     -- type: boolean; has the node already been visited?
) AS (
    -- ❷ Initial Case: The start node has a distance of zero, no parent and has not been visited yet.
    SELECT 
        start_node(), 
        0,
        h(start_node()),
        NULL, 
        false

    UNION ALL

    (
        -- ❸ Filter out old nodes if last iteration returned new values (this step is not needed in USING KEY version)
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
            FROM dijkstra
            GROUP BY node_id
        ),
        -- ❹ Select the node with minimal f-value; choose one at random if multiple exist
        -- If this node is the goal node, then stop the recursion
        min_node (id) AS (
            SELECT node_id
            FROM filtered_dijkstra
            WHERE 
                NOT visited AND 
                f = (SELECT min(f) FROM filtered_dijkstra WHERE NOT visited)
            LIMIT 1
        )

        -- ❺ Set 'visited' to TRUE for the unvisited node with smallest distance
        SELECT 
            node_id, 
            dist, 
            f,
            prev, 
            true
        FROM filtered_dijkstra
        WHERE 
            node_id = (SELECT id FROM min_node) AND 
            node_id != goal_node()

        UNION

        -- ❻ If the distance from the smallest node to their neighbor(s) is smaller then previously, then update the neighbor(s)
        SELECT
            nbs.node_to,                            -- id of neighbor
            sml.dist + nbs.weight,                  -- new distance
            sml.dist + nbs.weight + h(nbs.node_to), -- f-value: distance + estimated distance to the goal
            sml.node_id,                            -- new prev
            false                                   -- still unvisited
        FROM
            filtered_dijkstra AS sml JOIN                                           -- smallest node
            {graph}           AS nbs ON sml.node_id = nbs.node_from LEFT OUTER JOIN -- neighbors of smallest node
            filtered_dijkstra AS old ON nbs.node_to = old.node_id                   -- old dist and prev of neighbors
        WHERE 
            NOT sml.visited AND                                                     -- not visited yet -> part of the front
            sml.node_id = (SELECT id FROM min_node) AND                             -- sml is the smallest node in the front
            sml.dist + nbs.weight < coalesce(old.dist, CAST('inf' AS FLOAT)) AND    -- modify only neighbors with smaller distances
            sml.node_id != goal_node()                                              -- stop when path to goal node has been found

        UNION 

        -- ❼ Carry all values from previous iteration
        SELECT *
        FROM filtered_dijkstra
        WHERE (SELECT id FROM min_node) != goal_node()
    )
), 
solution (
    node_id,
    dist,
    prev,
) AS (
    SELECT 
        node_id,
        min(dist),
        argmin(prev, dist)
    FROM dijkstra
    GROUP BY node_id
),
-- Pretty-Printing
path_as_string (
    new_node,
    path_string,
) AS (
    SELECT 
        goal_node(), 
        (SELECT '' || goal_node()),

    UNION ALL

    SELECT 
        d.prev,
        d.prev || ' -> ' || p.path_string,

    FROM path_as_string AS p JOIN solution AS d ON p.new_node = d.node_id
)

SELECT 
    path_string AS 'Path',
    (SELECT dist FROM solution WHERE node_id = goal_node()) AS 'Distance'
FROM 
    path_as_string
WHERE new_node = start_node();
