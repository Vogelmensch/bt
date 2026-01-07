-- Find some path of given length from start_node in graph
CREATE OR REPLACE MACRO max_length() AS {max_length};
CREATE OR REPLACE MACRO start_node() AS {start_node};

WITH RECURSIVE find(n, node) USING KEY (n) AS (
    -- initial case
    SELECT 0, start_node()

    UNION 

    SELECT 
        f.n+1,
        g.node_to
    FROM
        find AS f JOIN 
        {graph} AS g ON f.node = g.node_from
    WHERE f.n < max_length() AND NOT EXISTS (FROM recurring.find AS r WHERE r.node = g.node_to)
)

-- Directly use this as argument for the --goals option in astar.py
SELECT string_agg(node, ' ' ORDER BY n) AS 'Path'
FROM find;