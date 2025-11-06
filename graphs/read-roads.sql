CREATE OR REPLACE TABLE left_graph (
    node_from INTEGER,
    node_to INTEGER,
);

COPY left_graph FROM 'roads.csv';

CREATE OR REPLACE TABLE graph(
    node_from,
    node_to,
    weight
) AS 
FROM left_graph JOIN (SELECT 1) ON true;