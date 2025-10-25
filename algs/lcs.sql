-- see https://en.wikipedia.org/wiki/Longest_common_subsequence#Worked_example

CREATE OR REPLACE MACRO s1() AS 'Never gonna give you up';
CREATE OR REPLACE MACRO s2() AS 'Never gonna let you down';

CREATE OR REPLACE TABLE letters(xsym, xidx, ysym, yidx) AS (
    SELECT s1()[m], m, s2()[n], n
    FROM 
        range(length(s1())+1) AS r(m),
        range(length(s2())+1) AS r(n)
);

WITH RECURSIVE lcs (
    xsym, xidx, 
    ysym, yidx, 
    strings, len
    ) USING KEY (xidx, yidx) AS (

    -- initial case
    SELECT 
        xsym, xidx,
        ysym, yidx,
        [''], 0
    FROM letters
    WHERE xidx = 0 or yidx = 0
    
    UNION

    (
    -- in every iteration, fill out every letter that has a left and upper OR diagonal predecessor
    
    -- Case 1: Letters are equal
    SELECT
        nxt.xsym, nxt.xidx,
        nxt.ysym, nxt.yidx,
        list_transform(diag.strings, lambda s: nxt.xsym || s), 
        diag.len + 1 -- concat letter for every element in list
    FROM 
        letters AS nxt
        JOIN recurring.lcs AS diag ON nxt.xidx = diag.xidx+1 and 
                                      nxt.yidx = diag.yidx+1 
        LEFT OUTER JOIN recurring.lcs AS this ON nxt.xidx = this.xidx and
                                                 nxt.yidx = this.yidx
    WHERE 
        this.strings IS NULL and
        diag.strings IS NOT NULL and -- diagonal neighbor is not empty
        nxt.xsym = nxt.ysym -- letters are equal

    UNION

    -- Case 2: Letters are unequal
    SELECT
        nxt.xsym, nxt.xidx,
        nxt.ysym, nxt.yidx,       
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
        this.strings IS NULL and
        l.strings IS NOT NULL and
        u.strings IS NOT NULL and
        nxt.xsym != nxt.ysym
    )
)
SELECT list_transform(strings, lambda s: reverse(s)) AS 'Longest Common Subsequence'
FROM lcs
WHERE xidx = length(s1()) and yidx = length(s2());