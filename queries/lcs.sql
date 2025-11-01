-- This query implements the 'longest common subsequence'-algorithm
-- It finds the longest subsequence common to two strings
-- Subsequences are not required to occupy consecutive positions within the original sequences
-- ❶ Create a table `letters` that holds the cross product of all letters in the two substrings
-- ❷ Initial Case: The LCS between any sequence and an empty sequence is always empty
-- ❸ Iterate through every possible combination of letters in the two input strings; distinguish between two cases
-- ❹ Case 1: Letters are equal; add the letter to the solutions
-- ❺ Case 2: Letters are unequal; select the best solution to continue with
-- Recurring Table: Holds the solutions for (growing) substrings of the input strings

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
    xsym, xidx,     -- one letter and its index from the first strings
    ysym, yidx,     -- one letter and its index from the second strings
    strings, len    -- current solutions and their length
    ) USING KEY (xidx, yidx) AS (
    -- ❷ Initial Case: The LCS between any sequence and an empty sequence is always empty
    SELECT 
        xsym, xidx,
        ysym, yidx,
        [''], 0
    FROM letters
    WHERE xidx = 0 or yidx = 0
    
    UNION

    -- ❸ Iterate through every possible combination of letters in the two input strings; distinguish between two cases
    (
    -- ❹ Case 1: Letters are equal; add letter to the solutions
    SELECT
        nxt.xsym, nxt.xidx,
        nxt.ysym, nxt.yidx,
        list_transform(diag.strings, lambda s: nxt.xsym || s),  -- add letter to every solution
        diag.len + 1                                            -- the solution's length is increased by one
    FROM 
        letters AS nxt
        JOIN recurring.lcs AS diag ON nxt.xidx = diag.xidx+1 and 
                                      nxt.yidx = diag.yidx+1 
        LEFT OUTER JOIN recurring.lcs AS this ON nxt.xidx = this.xidx and
                                                 nxt.yidx = this.yidx
    WHERE 
        this.strings IS NULL and        -- this field is empty
        nxt.xsym = nxt.ysym             -- letters are equal

    UNION

    -- ❺ Case 2: Letters are unequal; select the best solution to continue with
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
        JOIN recurring.lcs AS l ON nxt.xidx = l.xidx+1 and nxt.yidx = l.yidx 
        JOIN recurring.lcs AS u ON nxt.xidx = u.xidx and nxt.yidx = u.yidx+1 
        LEFT OUTER JOIN recurring.lcs AS this ON nxt.xidx = this.xidx and nxt.yidx = this.yidx    
    WHERE 
        this.strings IS NULL and    -- this field is empty
        nxt.xsym != nxt.ysym        -- letters are unequal
    )
)
SELECT list_transform(strings, lambda s: reverse(s)) AS 'Longest Common Subsequence'
FROM lcs
WHERE xidx = length(s1()) and yidx = length(s2());