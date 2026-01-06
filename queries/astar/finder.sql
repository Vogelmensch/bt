-- Find one path of given length from start_node in graph

CREATE OR REPLACE MACRO len() AS 15;
CREATE OR REPLACE MACRO start_node() AS 1;

WITH RECURSIVE find(n, node) USING KEY (n) AS (
    -- initial case
    SELECT 0, start_node()

    UNION 

    SELECT 
        f.n+1,
        g.node_to
    FROM
        find AS f JOIN 
        time_graph AS g ON f.node = g.node_from
    WHERE f.n < len() AND NOT EXISTS (FROM recurring.find AS r WHERE r.node = g.node_to)
)
FROM find;