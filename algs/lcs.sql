-- see https://en.wikipedia.org/wiki/Longest_common_subsequence#Worked_example

CREATE OR REPLACE MACRO s1() AS 'das ist ein schöner text.';
CREATE OR REPLACE MACRO s2() AS 'dies ist ein toller text.';

CREATE OR REPLACE TABLE letters(xsym, xidx, ysym, yidx) AS (
    SELECT s1()[m], m, s2()[n], n
    FROM 
        range(length(s1())+1) AS r(m),
        range(length(s2())+1) AS r(n)
);

WITH RECURSIVE lcs (
    xsym, xidx, 
    ysym, yidx, 
    len, dir
    ) USING KEY (xidx, yidx) AS (

    -- initial case
    SELECT 
        xsym, xidx,
        ysym, yidx,
        0, 'NONE'
    FROM letters
    WHERE xidx = 0 or yidx = 0
    
    UNION

    (
    -- in every iteration, fill out every letter that has a left and upper predecessor
    
    -- Case 1: Letters are equal
    SELECT
        nxt.xsym, nxt.xidx,
        nxt.ysym, nxt.yidx,
        diag.len+1, 'd'
    FROM 
        letters AS nxt JOIN
        recurring.lcs AS diag ON nxt.xidx = diag.xidx+1 and 
                                 nxt.yidx = diag.yidx+1
    WHERE 
        NOT EXISTS (SELECT len FROM recurring.lcs AS r WHERE r.xidx = nxt.xidx and r.yidx = nxt.yidx) and
        diag.len IS NOT NULL and
        nxt.xsym = nxt.ysym

    UNION

    -- Case 2: Letters are unequal
    SELECT
        nxt.xsym, nxt.xidx,
        nxt.ysym, nxt.yidx,
        -- TODO: add support for both directions
        greatest(l.len, u.len), IF(l.len < u.len, 'u', 'l') -- 'l' can also mean 'both directions'
    FROM 
        letters AS nxt JOIN 
        recurring.lcs AS l ON nxt.xidx = l.xidx+1 and nxt.yidx = l.yidx JOIN
        recurring.lcs AS u ON nxt.xidx = u.xidx and nxt.yidx = u.yidx+1     
    WHERE 
        NOT EXISTS (SELECT len FROM recurring.lcs AS r WHERE r.xidx = nxt.xidx and r.yidx = nxt.yidx) and
        l.len IS NOT NULL and
        u.len IS NOT NULL and
        nxt.xsym != nxt.ysym
    )
),
backtrack (word, xidx, yidx) USING KEY (xidx, yidx) AS (
    SELECT '', length(s1()), length(s2())

    UNION 

    SELECT 
        IF(dir = 'd', lcs.xsym || b.word, b.word),
        IF(dir = 'u', b.xidx, b.xidx-1),
        IF(dir = 'l', b.yidx, b.yidx-1)
    FROM 
        lcs  
        JOIN backtrack AS b ON lcs.xidx = b.xidx and lcs.yidx = b.yidx
)
SELECT word AS 'Longest Common Subsequence'
FROM backtrack
ORDER BY length(word) DESC
LIMIT 1;