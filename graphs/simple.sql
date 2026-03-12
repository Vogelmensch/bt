CREATE OR REPLACE TABLE nodes (
    id INTEGER PRIMARY KEY
);

CREATE OR REPLACE TABLE edges (
    node_from INTEGER REFERENCES nodes(id),
    node_to INTEGER REFERENCES nodes(id),
    weight INTEGER NOT NULL
);

INSERT INTO nodes VALUES (0), (1), (2), (3), (4), (5), (6);

INSERT INTO edges VALUES 
    (0, 1, 1),
    (0, 2, 4),
    (1, 3, 1),
    (2, 3, 1),
    (2, 6, 10),
    (3, 4, 1),
    (3, 5, 3),
    (4, 5, 1),
    (5, 6, 1);

CREATE OR REPLACE TABLE simple AS (
    SELECT node_from, node_to, weight, 0 AS h
    FROM edges 

    UNION

    SELECT node_to, node_from, weight, 0 AS h
    FROM edges
);