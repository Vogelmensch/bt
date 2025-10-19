CREATE OR REPLACE MACRO start_node() AS 0;
CREATE OR REPLACE MACRO goal_node() AS 4242;

WITH RECURSIVE dijkstra (
    node_id,
    dist,
    prev
) AS (
    -- initial case
    (
        SELECT DISTINCT
            node_from,
            CAST('inf' AS DOUBLE),
            NULL
        FROM graph
        WHERE node_from != 0

        UNION

        SELECT start_node(), 0, NULL
    )
    -- the initial case is now already part of the union table.
    -- thus, the first node is already stored as a result!
    -- we can thus remove it in the next step already.
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
                node_from AS prev
            FROM graph AS g
            WHERE node_from = (SELECT id FROM min_node_id)
        )

        SELECT
            d.node_id,
            IF(n.dist < d.dist, n.dist, d.dist), -- d.dist is also selected if n.dist = NULL 
            IF(n.dist < d.dist, n.prev, d.prev)
        FROM 
            dijkstra AS d LEFT OUTER JOIN 
            neighbors AS n 
            ON d.node_id = n.node_id
        WHERE 
            d.node_id != (SELECT id FROM min_node_id) AND -- remove selected node
            EXISTS (FROM dijkstra WHERE node_id = goal_node())
    )
)

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
ORDER BY d.node_id;