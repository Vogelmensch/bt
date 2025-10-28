-- This query implements The A* Search Algorithm, or just 'A*' for short
-- It finds the shortest path between a start- and a goal-node in a graph
-- The graph can be directed or undirected
-- The graph can be weighted, but all weights must be non-negative
-- ❶ A* uses a problem-specific heuristic function to estimate the distance to the goal node
-- ❷ Initial Case: Add every node to the working table with initial values; 
--                  select different values for start node 


CREATE OR REPLACE MACRO start_node() AS 0;
CREATE OR REPLACE MACRO goal_node() AS 4242;

-- ❶ A* uses a problem-specific heuristic function to estimate the distance to the goal node
CREATE OR REPLACE MACRO width() AS 100;
CREATE OR REPLACE MACRO h(x) AS cast(
    sqrt(((x % width()) - (goal_node() % width()))^2 + 
         ((x / width()) - (goal_node() / width()))^2) 
    as int);

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
        -- ❸ Set 'visited' to TRUE for the unvisited node with smallest distance
        SELECT 
            node_id, 
            dist, 
            f,
            prev, 
            true
        FROM dijkstra
        WHERE 
            NOT visited AND
            f = (SELECT min(f) FROM dijkstra WHERE NOT visited)

        UNION

        -- Smaller ones
        SELECT
            nbs.node_to,                            -- id of neighbor
            sml.dist + nbs.weight,                  -- new distance
            sml.dist + nbs.weight + h(nbs.node_to), -- f-value: distance + estimated distance to the goal
            sml.node_id,                            -- new prev
            false                                   -- still unvisited
        FROM 
            dijkstra AS sml JOIN
            graph    AS nbs ON sml.node_id = nbs.node_from LEFT OUTER JOIN 
            dijkstra AS old ON nbs.node_to = old.node_id
        WHERE 
            NOT sml.visited AND
            sml.f = (SELECT min(f) FROM dijkstra WHERE NOT visited) AND
            sml.dist + nbs.weight < coalesce(old.dist, CAST('inf' AS FLOAT)) AND    -- modify only neighbors with smaller distances
            sml.node_id != goal_node()

        UNION

        -- Carry values that do not get updated
        SELECT old.*
        FROM 
            dijkstra AS sml JOIN
            graph    AS nbs ON sml.node_id = nbs.node_from RIGHT OUTER JOIN 
            dijkstra AS old ON nbs.node_to = old.node_id
        WHERE 
            old.node_id != sml.node_id AND 
            NOT sml.visited AND
            sml.f = (SELECT min(f) FROM dijkstra WHERE NOT visited) AND
            coalesce(sml.dist + nbs.weight, CAST('inf' AS FLOAT)) >= old.dist AND  
            sml.node_id != goal_node()
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
