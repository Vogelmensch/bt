-- Solve 0-1 knapsack problem 
-- input: 
-- 1. table `items` with the following schema

-- CREATE OR REPLACE TABLE items (
--     id INTEGER PRIMARY KEY,
--     value INTEGER,
--     weight INTEGER
-- );

-- INSERT INTO items VALUES 
--     (1, 5, 4),
--     (2, 4, 3),
--     (3, 3, 2),
--     (4, 2, 1);

-- 2. max_weight (INTEGER)

CREATE OR REPLACE MACRO total_max_weight() AS {max_weight};

-- max_weight is a local value
-- all items up to item_id are included
WITH RECURSIVE best_value(max_weight, item_id, value) AS (
    -- First row: for i = 0 (no items taken), the total value is zero across all weights.
    SELECT 
        w.x,
        0,
        0
    FROM generate_series(total_max_weight()) AS w(x)

    UNION ALL 

    -- We can calculate the entire row in one go!
    SELECT 
        up.max_weight,
        up.item_id + 1,
        CASE WHEN i.weight > up.max_weight 
        THEN up.value
        ELSE list_max([up.value, shifted.value + i.value])
        END
    FROM 
        best_value AS up JOIN
        {items}      AS i       ON i.id = up.item_id + 1 LEFT OUTER JOIN
        best_value AS shifted ON shifted.max_weight = up.max_weight - i.weight
)
SELECT 
    (SELECT max(value) FROM best_value) AS max_value,
    (SELECT count(*) FROM {items}) AS items_count,
    (SELECT count(*) FROM best_value) AS table_size;