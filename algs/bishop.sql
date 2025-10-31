-- This query implements the `Drunken Bishop`-Algorithm
-- It creates a grid of numbers, representing an agent's path
-- The agent moves based on a list of binary tuples, and according to predefined rules
-- The binary tuples are calculated from a hash-value; this is handled by an external script
-- The same script converts this query's result into an ASCII-image

-- ❶ Start in the center of the grid, with the entire bitlist
-- ❷ Calculate the next coordinates from the first element in bitlist. Pop this element from bitlist.
-- ❸ Select the new values and increate sym_id by one
-- ❹ Repeat until the bitlist is empty
-- Recurring table: Stores sym_id for all coordinates
-- Working Table: Stores current coordinates of agent and current bitlist

CREATE OR REPLACE MACRO width() AS {width};
CREATE OR REPLACE MACRO height() AS {height};

CREATE OR REPLACE MACRO bitlist() AS {bitlist};

WITH RECURSIVE bishop (
    x,      -- x and y coordinates defining the grid
    y, 
    sym_id, -- id for symbol in picture
    bitlist -- list of binary tuples, e.g. (10, 11, 01, 00, 10, ...)
) USING KEY (x, y) AS (
    -- ❶ Start in the center of the grid, with the entire bitlist
    SELECT 
        (width()/2) :: INTEGER,
        (height()/2) :: INTEGER,
        1,
        bitlist(),
        
    UNION

    (
    -- ❷ Calculate the next coordinates from the first element in bitlist. Pop this element from bitlist.
    WITH new(x,y,bitlist) AS (
        SELECT
            CASE 
                WHEN bitlist[1][2] == '0' 
                THEN greatest(0, x-1)       -- don't move past borders
                ELSE least(width()-1, x+1)
            END AS x,
            CASE 
                WHEN bitlist[1][1] == '0' 
                THEN greatest(0, y-1)       -- don't move past borders
                ELSE least(height()-1, y+1)
            END AS y,
            array_pop_front(bitlist)
        FROM bishop
    )
    -- ❸ Select the new values and increate sym_id by one
    SELECT 
        new.x,
        new.y,
        -- if field has not been visited before, result is NULL
        coalesce(field_to.sym_id + 1, 1),
        new.bitlist
    FROM 
        new 
        LEFT OUTER JOIN recurring.bishop AS field_to
        ON field_to.x = new.x AND field_to.y = new.y
    -- ❹ Repeat until the bitlist is empty
    WHERE length((SELECT bitlist FROM bishop)) > 0
   )
)
SELECT x, y, sym_id
FROM bishop;