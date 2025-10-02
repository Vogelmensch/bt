WITH RECURSIVE dijkstra (
    node_id,
    dist,
    prev
) USING KEY (node_id) AS (
    -- initial case
    (
        SELECT 
            id,
            CAST('inf' AS DOUBLE),
            NULL
        FROM nodes
        WHERE id != 0

        UNION

        SELECT 0, 0, NULL
    )
    -- the initial case is now already part of the union table.
    -- thus, the first node is already stored as a result!
    -- we can thus remove it in the next step already.
    -- => the intermediate table can be used as dijkstra's 'Q'

    UNION 

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
            IF(n.dist < d.dist, n.prev, d.prev)  -- same here
        FROM 
            dijkstra AS d LEFT OUTER JOIN 
            neighbors AS n 
            ON d.node_id = n.node_id
        WHERE 
            -- remove selected node
            d.node_id != (SELECT id FROM min_node_id)
    )
)

FROM dijkstra
ORDER BY node_id;