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

CREATE OR REPLACE MACRO bitlist() AS {bitlist};

WITH RECURSIVE bishop (
    x,      -- x and y coordinates defining the grid
    y, 
    bitlist -- list of binary tuples, e.g. (10, 11, 01, 00, 10, ...)
) AS (
    -- ❶ Start in the center of the grid, with the entire bitlist
    SELECT 
        (width()/2) :: INTEGER,
        (height()/2) :: INTEGER,
        bitlist(),
        
    UNION ALL

    -- ❷ Calculate the next coordinates from the first element in bitlist. Pop this element from bitlist.
    SELECT
        CASE 
            WHEN bitlist[1][2] == '0' 
            THEN greatest(0, x-1)       -- don't move past borders
            ELSE least(width()-1, x+1)
        END,
        CASE 
            WHEN bitlist[1][1] == '0' 
            THEN greatest(0, y-1)       -- don't move past borders
            ELSE least(height()-1, y+1)
        END,
        array_pop_front(bitlist)
    FROM bishop
    -- ❸ Repeat until the bitlist is empty
    WHERE length(bitlist) > 0
)
-- ❹ Count the number of rows including each cell to get the sym_id
SELECT x, y, count(*)
FROM bishop
GROUP BY x, y;