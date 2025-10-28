-- This query implements The A* Search Algorithm, or just 'A*' for short
-- It finds the shortest path between a start- and a goal-node in a graph
-- The graph can be directed or undirected
-- The graph can be weighted, but all weights must be non-negative
-- ❶ A* uses a problem-specific heuristic function to estimate the distance to the goal node
-- ❷ Initial Case: Add every node to the working table with initial values; 
--                  select different values for start node 


CREATE OR REPLACE MACRO start_node() AS 0;
CREATE OR REPLACE MACRO goal_node() AS 6969;

-- ❶ A* uses a problem-specific heuristic function to estimate the distance to the goal node
CREATE OR REPLACE MACRO width() AS 100;
CREATE OR REPLACE MACRO h(x) AS cast(
    sqrt(((x % width()) - (goal_node() % width()))^2 + 
         ((x / width()) - (goal_node() / width()))^2) 
    as int);

WITH RECURSIVE dijkstra (
    node_id,
    dist,   -- shortest distance to this node
    f,      -- f = dist + h, where h is the heuristic function (estimated distance to the goal)
    prev    -- previous node; backtrack to find the shortest path
) AS (
    -- ❷ Initial Case: Add every node to the working table with initial values; 
    --                  select different values for start node 
    (
        SELECT DISTINCT
            node_from,
            CAST('inf' AS DOUBLE),
            CAST('inf' AS DOUBLE),
            NULL
        FROM graph
        WHERE node_from != 0

        UNION

        SELECT start_node(), 0, h(start_node()), NULL
    )
    -- => the intermediate table can be used as dijkstra's 'Q'

    UNION ALL

    (
        -- recursion
        WITH 
        -- select one node with minimal dist
        min_node_id AS (
            SELECT node_id AS id
            FROM dijkstra 
            WHERE dist = (SELECT min(dist) FROM dijkstra)
            LIMIT 1
        ),
        -- get neighbors of minimal node
        neighbors AS (
            SELECT 
                g.node_to AS node_id, 
                (SELECT min(dist) FROM dijkstra) + g.weight AS dist,
                (SELECT min(dist) FROM dijkstra) + g.weight + h(g.node_to) AS f,
                node_from AS prev
            FROM graph AS g
            WHERE node_from = (SELECT id FROM min_node_id)
        )

        SELECT
            d.node_id,
            IF(n.dist < d.dist, n.dist, d.dist), -- d.dist is also selected if n.dist = NULL 
            IF(n.dist < d.dist, n.f, d.f),
            IF(n.dist < d.dist, n.prev, d.prev)
        FROM 
            dijkstra AS d LEFT OUTER JOIN 
            neighbors AS n 
            ON d.node_id = n.node_id
        WHERE 
            d.node_id != (SELECT id FROM min_node_id) AND -- remove selected node
            EXISTS (FROM dijkstra WHERE node_id = goal_node())
    )
), 
solution(node_id, dist, prev) AS (
    SELECT DISTINCT d.node_id, d.dist, d.prev
    FROM 
        dijkstra d JOIN 
        (
            SELECT 
                node_id, 
                min(dist) AS dist,
            FROM dijkstra
            GROUP BY node_id
        ) res 
        ON d.node_id = res.node_id AND d.dist = res.dist
    WHERE prev IS NOT NULL
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
