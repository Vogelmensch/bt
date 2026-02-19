-- This query implements the 'longest common subsequence'-algorithm
-- It finds the longest subsequence common to two strings
-- Subsequences are not required to occupy consecutive positions within the original sequences
-- ❶ Create a table `letters` that holds the cross product of all letters in the two substrings
-- ❷ Initial Case: The LCS between any sequence and an empty sequence is always empty
-- ❸ Iterate through every possible combination of letters in the two input strings; distinguish between two cases
-- ❹ Carry the entire working table until the entire table has been filled
-- ❺ Case 1: Letters are equal; highlight diagonal path
-- ❻ Case 2: Letters are unequal; highlight best path (left or up)
-- ❼ Build the resulting strings in backtracking process, using the highlighted paths
-- Working Table: Holds solutions; manual carry necessary
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

WITH RECURSIVE lcs (
    xsym, xidx,                     -- one letter and its index from the first strings
    ysym, yidx,                     -- one letter and its index from the second strings
    len,                            -- current solution's length
    from_left, from_up, from_diag   -- path the solution came from; needed for backtracking later
) AS (
    -- ❷ Initial Case: The LCS between any sequence and an empty sequence is always empty
    SELECT 
        xsym, xidx,
        ysym, yidx,
        0,
        false, false, false
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
        -- when the current row number is larger than the maximal row number, terminate
        (SELECT y FROM current_row) <= (SELECT max(yidx) FROM letters) 

    UNION

    -- ❺ Case 1: Letters are equal; highlight diagonal path
    SELECT
        ltrs.xsym, ltrs.xidx,
        ltrs.ysym, ltrs.yidx,
        diag.len + 1,            -- the solution's length is increased by one
        false, false, true
    FROM 
        letters AS ltrs
        JOIN lcs AS diag ON ltrs.xidx = diag.xidx+1 and 
                            ltrs.yidx = diag.yidx+1 
        LEFT OUTER JOIN lcs AS this ON ltrs.xidx = this.xidx and
                                       ltrs.yidx = this.yidx
    WHERE 
        this.len IS NULL and        -- this field is empty
        ltrs.xsym = ltrs.ysym and   -- letters are equal
        (SELECT y FROM current_row) <= (SELECT max(yidx) FROM letters)  -- termination condition

    UNION

    -- ❻ Case 2: Letters are unequal; highlight best path (left or up)
    SELECT
        ltrs.xsym, ltrs.xidx,
        ltrs.ysym, ltrs.yidx,
        greatest(l.len, u.len),
        l.len >= u.len, u.len >= l.len, false
    FROM 
        letters AS ltrs 
        JOIN lcs AS l ON ltrs.xidx = l.xidx+1 and ltrs.yidx = l.yidx 
        JOIN lcs AS u ON ltrs.xidx = u.xidx and ltrs.yidx = u.yidx+1 
        LEFT OUTER JOIN lcs AS this ON ltrs.xidx = this.xidx and ltrs.yidx = this.yidx    
    WHERE 
        this.len IS NULL and        -- this field is empty
        ltrs.xsym != ltrs.ysym and  -- letters are unequal
        (SELECT y FROM current_row) <= (SELECT max(yidx) FROM letters)  -- termination condition
    )
),
-- ❻ Build the resulting strings in backtracking process, using the highlighted paths
backtrack(
    xidx, yidx,
    word
) AS (
    SELECT 
        length(s1()), length(s2()),
        ''

    UNION ALL

    -- which path has been highlighted?
    (
        -- diagonal => expand word
        SELECT 
            xidx-1, yidx-1,
            xsym || word
        FROM 
            backtrack NATURAL JOIN lcs 
                      NATURAL JOIN letters
        WHERE from_diag

        UNION 

        -- left => continue left
        SELECT 
            xidx-1, yidx,
            word
        FROM backtrack NATURAL JOIN lcs
        WHERE from_left

        UNION

        -- up => continue up
        SELECT
            xidx, yidx-1,
            word
        FROM backtrack NATURAL JOIN lcs
        WHERE from_up

        -- notice that 'left' and 'up' can both be selected simultaneously
    )
)
SELECT 
    (SELECT list(word) 
    FROM (
        SELECT DISTINCT word
        FROM backtrack
        WHERE xidx = 0 OR yidx = 0
    )) AS solutions,
    (SELECT count(*) FROM lcs) AS table_size