-- Create a graph that looks like this:
-- 0    -   1   -   ...   -   width-1
-- |        |                   |
-- width-...
-- | 
-- ...

CREATE OR REPLACE TABLE graph AS (
    WITH RECURSIVE width AS (
        SELECT 15 AS width
    ),
    manhattan_rights (
        node_from,
        node_to,
        width
    ) AS (
        -- start: top left edges
        SELECT 0, 1, (SELECT width FROM width)

        UNION ALL

        -- recursive step: 
        -- go one node to the right.
        -- select the edges from that node 
        -- which lead to the right
        -- if we're at the right corner (width-1)
        -- there is no neighbor. 
        SELECT 
            m.node_from + 1,
            IF((m.node_from+1) % m.width < m.width-1, m.node_from+2, NULL),
            width
        FROM manhattan_rights AS m
        WHERE m.node_from+1 < m.width^2
    ),
    manhattan_downs (
        node_from,
        node_to,
        width
    ) AS (
        -- start: top left edge
        SELECT 0, (SELECT width FROM width), (SELECT width FROM width)
        
        UNION ALL

        -- recursive step: 
        -- go one node to the right.
        -- select the edges from that node 
        -- which lead down
        -- if we're at the lower corner (width^2-width)
        -- there is no neighbor.      
        SELECT
            node_from + 1,
            IF((m.node_from+1) < m.width^2 - m.width, m.node_from+1+width, NULL),
            m.width
        FROM manhattan_downs AS m
        WHERE m.node_from+1 < width^2
        
    ), directed_graph AS (
        SELECT node_from, node_to
        FROM manhattan_rights
        UNION 
        SELECT node_from, node_to
        FROM manhattan_downs
    )

    SELECT node_from, node_to, 1 AS weight
    FROM directed_graph
    WHERE node_to IS NOT NULL

    UNION

    SELECT node_to, node_from, 1 AS weight
    FROM directed_graph
    WHERE node_to IS NOT NULL
);