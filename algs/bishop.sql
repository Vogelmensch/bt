CREATE OR REPLACE MACRO width() AS 17;
CREATE OR REPLACE MACRO height() AS 9;

CREATE OR REPLACE MACRO bitlist() AS ['00', '11', '11', '11', '00', '01', '01', '10', '00', '00', '11', '10', '01', '00', '00', '11'];

WITH RECURSIVE bishop (
    x, 
    y, 
    sym_id, -- id for symbol in picture
    bitlist -- list of binary pairs, e.g. (10, 11, 01, 00, 10, ...)
) USING KEY (x, y) AS (
    SELECT 
        (width()/2) :: INTEGER,
        (height()/2) :: INTEGER,
        2,
        bitlist(),
        
    UNION

    (
    WITH new(x,y,bitlist) AS (
        SELECT
            CASE 
                WHEN bitlist[1][2] == '0' 
                THEN greatest(0, x-1)      -- don't move past borders
                ELSE least(width()-1, x+1)
            END AS x,
            CASE 
                WHEN bitlist[1][1] == '0' 
                THEN greatest(0, y-1)
                ELSE least(height()-1, y+1)
            END AS y,
            array_pop_front(bitlist)
        FROM bishop
    )
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
    WHERE length(new.bitlist) > 0
   )
)
SELECT x, y, sym_id
FROM bishop;