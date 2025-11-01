-- This query implements The A* Search Algorithm, or just 'A*' for short
-- It finds the shortest path between a start- and a goal-node in a graph
-- The graph can be directed or undirected
-- The graph can be weighted, but all weights must be non-negative
-- ❶ A* uses a problem-specific heuristic function to estimate the distance to the goal node
-- ❷ Initial Case: The start node has a distance of zero, no parent and has not been visited yet.
-- ❸ Set 'visited' to TRUE for the unvisited node with smallest distance
-- ❹ If the distance from the smallest node to their neighbor(s) is smaller then previously, then update the neighbor(s)
-- Recurring Table: Holds all the nodes that have been seen (but not necessarily visited)

CREATE OR REPLACE MACRO start_node() AS {start_node};
CREATE OR REPLACE MACRO goal_node() AS {goal_node};

-- ❶ A* uses a problem-specific heuristic function to estimate the distance to the goal node
CREATE OR REPLACE MACRO h(x) AS {heuristic};

WITH RECURSIVE
dijkstra (
    node_id,
    dist,       -- shortest distance to this node
    f,          -- f = dist + h, where h is the heuristic function (estimated distance to the goal)
    prev,       -- previous node; backtrack to find the shortest path
    visited     -- type: boolean; has the node already been visited?
) USING KEY (node_id) AS (
    -- ❷ Initial Case: The start node has a distance of zero, no parent and has not been visited yet.
    SELECT 
        start_node(), 
        0,
        h(start_node()),
        NULL, 
        false

    UNION

    (
    -- ❸ Set 'visited' to TRUE for the unvisited node with smallest distance
    SELECT 
        node_id, 
        dist, 
        f,
        prev, 
        true
    FROM recurring.dijkstra
    WHERE 
        NOT visited AND
        f = (SELECT min(f) FROM recurring.dijkstra WHERE NOT visited)

    UNION

    -- ❹ If the distance from the smallest node to their neighbor(s) is smaller then previously, then update the neighbor(s)
    SELECT
        nbs.node_to,                            -- id of neighbor
        sml.dist + nbs.weight,                  -- new distance
        sml.dist + nbs.weight + h(nbs.node_to), -- f-value: distance + estimated distance to the goal
        sml.node_id,                            -- new prev
        false                                   -- still unvisited
    FROM
        recurring.dijkstra AS sml JOIN                                              -- smallest node
        {graph}            AS nbs ON sml.node_id = nbs.node_from LEFT OUTER JOIN    -- neighbors of smallest node
        recurring.dijkstra AS old ON nbs.node_to = old.node_id                      -- old dist and prev of neighbors
    WHERE 
        NOT sml.visited AND                                                     -- not visited yet -> part of the front
        sml.f = (SELECT min(f) FROM recurring.dijkstra WHERE NOT visited) AND   -- sml is the smallest node in the front
        sml.dist + nbs.weight < coalesce(old.dist, CAST('inf' AS FLOAT)) AND    -- modify only neighbors with smaller distances
        sml.node_id != goal_node()                                              -- stop when path to goal node has been found
    )
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

    FROM path_as_string AS p JOIN dijkstra AS d ON p.new_node = d.node_id
)

SELECT 
    path_string AS 'Path',
    (SELECT dist FROM dijkstra WHERE node_id = goal_node()) AS 'Distance'
FROM 
    path_as_string
WHERE new_node = start_node();
