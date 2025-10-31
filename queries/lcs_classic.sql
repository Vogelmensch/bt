-- This query implements the 'longest common subsequence'-algorithm
-- It finds the longest subsequence common to two strings
-- Subsequences are not required to occupy consecutive positions within the original sequences
-- ❶ Create a table `letters` that holds the cross product of all letters in the two substrings
-- ❷ Initial Case: The LCS between any sequence and an empty sequence is always empty
-- ❸ Iterate through every possible combination of letters in the two input strings; distinguish between two cases
-- ❹ Carry the entire working table until the entire table has been filled
-- ❺ Case 1: Letters are equal; add letter to the solutions
-- ❻ Case 2: Letters are unequal; select the best solution to continue with
-- Working Table: Holds the solutions for (growing) substrings of the input strings
-- Union Table: Every iteration's solution gets dumped here

-- See https://en.wikipedia.org/wiki/Longest_common_subsequence#Solution_for_two_sequences

CREATE OR REPLACE MACRO s1() AS {string1};
CREATE OR REPLACE MACRO s2() AS {string2};

-- ❶ Create a table `letters` that holds the cross product of all letters in the two substrings
CREATE OR REPLACE TABLE letters(xsym, xidx, ysym, yidx) AS (
    SELECT s1()[m], m, s2()[n], n
    FROM 
        range(length(s1())+1) AS r(m),
        range(length(s2())+1) AS r(n)
);

WITH RECURSIVE 
 -- largest possible y-value
max_row (y) AS (
    SELECT max(yidx)
    FROM letters
),
lcs (
    xsym, xidx,     -- one letter and its index from the first strings
    ysym, yidx,     -- one letter and its index from the second strings
    strings, len    -- current solutions and their length
) AS (
    -- ❷ Initial Case: The LCS between any sequence and an empty sequence is always empty
    SELECT 
        xsym, xidx,
        ysym, yidx,
        [''], 0
    FROM letters
    WHERE xidx = 0 or yidx = 0

    UNION ALL

    -- ❸ Iterate through every possible combination of letters in the two input strings; distinguish between two cases
    (
    -- ❹ Carry the entire working table until the entire table has been filled

    -- `current_row` is the highest "full" row's yidx plus one
    WITH current_row(y) AS ( 
        SELECT max(yidx) + 1
        FROM lcs
        WHERE xidx = length(s1())
    ) 
    FROM lcs
    WHERE 
        -- when the current row number is larger than the maximal row number, then terminate
        (SELECT y FROM current_row) <= (SELECT y FROM max_row) 

    UNION

    -- ❺ Case 1: Letters are equal; add letter to the solutions
    SELECT
        nxt.xsym, nxt.xidx,
        nxt.ysym, nxt.yidx,
        list_transform(diag.strings, lambda s: nxt.xsym || s),  -- add letter to every solution
        diag.len + 1                                            -- the solution's length is increased by one
    FROM 
        letters AS nxt
        JOIN lcs AS diag ON nxt.xidx = diag.xidx+1 and 
                                      nxt.yidx = diag.yidx+1 
        LEFT OUTER JOIN lcs AS this ON nxt.xidx = this.xidx and
                                                 nxt.yidx = this.yidx
    WHERE 
        this.strings IS NULL and        -- this field is empty
        nxt.xsym = nxt.ysym             -- letters are equal

    UNION

    -- ❻ Case 2: Letters are unequal; select the best solution to continue with
    SELECT
        nxt.xsym, nxt.xidx,
        nxt.ysym, nxt.yidx,
        -- select the solution with the longest strings.
        -- if the lengths are equal, concatenate both.
        CASE 
            WHEN l.len > u.len THEN l.strings 
            ELSE CASE 
                WHEN l.len < u.len THEN u.strings 
                ELSE list_distinct(l.strings || u.strings) 
            END 
        END,
        greatest(l.len, u.len)
    FROM 
        letters AS nxt 
        JOIN lcs AS l ON nxt.xidx = l.xidx+1 and nxt.yidx = l.yidx 
        JOIN lcs AS u ON nxt.xidx = u.xidx and nxt.yidx = u.yidx+1 
        LEFT OUTER JOIN lcs AS this ON nxt.xidx = this.xidx and nxt.yidx = this.yidx    
    WHERE 
        this.strings IS NULL and    -- this field is empty
        nxt.xsym != nxt.ysym        -- letters are unequal
    )
)
SELECT list_transform(strings, lambda s: reverse(s)) AS 'Longest Common Subsequence'
FROM lcs
WHERE xidx = length(s1()) and yidx = length(s2());