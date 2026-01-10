-- create table of all pairing of values and weights from 1 to 1000
CREATE TABLE IF NOT EXISTS pairings_to_1000 AS (SELECT s.x AS value, t.x AS weight FROM generate_series(1000) AS s(x), generate_series(1000) AS t(x));

-- to generate ids
CREATE OR REPLACE SEQUENCE id_sequence START 1;

-- create table with automatically increasing ids
CREATE OR REPLACE TABLE temp (id INTEGER PRIMARY KEY DEFAULT nextval('id_sequence'), value INTEGER, weight INTEGER);

-- insert random pairs from pairings_to_1000 into the new table
INSERT INTO temp(value, weight) (FROM pairings_to_1000 USING SAMPLE {sample_size});

CREATE OR REPLACE TABLE {table_name} AS (FROM temp);

DROP TABLE temp;