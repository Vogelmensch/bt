-- This query implements the `Drunken Bishop`-Algorithm
-- It creates a grid of numbers, representing an agent's path
-- The agent moves based on a list of binary tuples, and according to predefined rules
-- The binary tuples are calculated from a hash-value; this is handled by an external script
-- The same script converts this query's result into an ASCII-image

-- ❶ Start in the center of the grid, with the entire bitlist
-- ❷ Calculate the next coordinates from the first element in bitlist. Pop this element from bitlist.
-- ❸ Repeat until the bitlist is empty
-- ❹ Count the number of rows including each cell to get the sym_id
-- Working Table: Stores current coordinates of agent and current bitlist
-- Union Table: Stores the entire walk history

CREATE OR REPLACE MACRO width() AS {width};
CREATE OR REPLACE MACRO height() AS {height};

WITH RECURSIVE bishop (
    idx,
    x,          -- x and y coordinates defining the grid
    y, 
    is_end      -- last cell gets a special character
) AS (
    -- ❶ Start in the center of the grid, with the entire bitlist
    SELECT 
        0,
        (width()/2) :: INTEGER,
        (height()/2) :: INTEGER,
        false
        
    UNION ALL

    -- ❷ Calculate the next coordinates from the first element in bitlist. Pop this element from bitlist.
    SELECT
        bishop.idx+1,
        CASE 
            WHEN bits.x = 0
            THEN greatest(0, bishop.x-1)       -- don't move past borders
            ELSE least(width()-1, bishop.x+1)
        END,
        CASE 
            WHEN bits.y = 0
            THEN greatest(0, bishop.y-1)       -- don't move past borders
            ELSE least(height()-1, bishop.y+1)
        END,
        bishop.idx = (SELECT max(idx) FROM bits)             -- last element only
    FROM bishop JOIN bits ON bishop.idx = bits.idx
)
-- ❹ Count the number of rows including each cell to get the sym_id
SELECT x, y, count(*), bool_or(is_end)
FROM bishop
GROUP BY x, y;