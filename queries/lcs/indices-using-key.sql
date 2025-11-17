CREATE OR REPLACE MACRO s1() AS {string1};
CREATE OR REPLACE MACRO s2() AS {string2};

CREATE OR REPLACE TABLE letters(xsym, xidx, ysym, yidx) AS (
    SELECT s1()[m], m, s2()[n], n
    FROM 
        range(length(s1())+1) AS r(m),
        range(length(s2())+1) AS r(n)
);

WITH RECURSIVE lcs (
    xidx, yidx,
    len,
    from_left, from_up, from_diag
) USING KEY (xidx, yidx) AS (
    SELECT 
        0, 0,
        0,
        false, false, false

    UNION 

    (
        WITH nxt(xidx, yidx) AS (
            SELECT
                (xidx + 1) % (length(s1()) + 1),
                CASE WHEN xidx < length(s1())
                    THEN yidx
                    ELSE yidx + 1
                    END
            FROM lcs
        )

        -- Case 0: epsilon
        SELECT 
            nxt.xidx, nxt.yidx,
            0,
            false, false, false
        FROM 
            nxt JOIN
            letters AS l ON nxt.xidx = l.xidx AND nxt.yidx = l.yidx 
        WHERE l.xsym = '' OR l.ysym = ''

        UNION

        -- Case 1: Letters are equal
        SELECT
            nxt.xidx, nxt.yidx,
            diag.len + 1,
            false, false, true
        FROM 
            nxt JOIN
            letters AS l ON nxt.xidx = l.xidx AND nxt.yidx = l.yidx JOIN
            recurring.lcs AS diag ON diag.xidx = nxt.xidx - 1 AND diag.yidx = nxt.yidx - 1
        WHERE l.xsym = l.ysym

        UNION

        -- Case 2: Letters are unequal
        -- TODO: calculation of greatest maybe in CTE?
        SELECT 
            nxt.xidx, nxt.yidx,
            greatest(lft.len, up.len),
            lft.len = greatest(lft.len, up.len), up.len = greatest(lft.len, up.len), false
        FROM 
            nxt JOIN
            letters AS l ON nxt.xidx = l.xidx AND nxt.yidx = l.yidx JOIN
            recurring.lcs AS lft ON lft.xidx = nxt.xidx - 1 AND lft.yidx = nxt.yidx JOIN
            recurring.lcs AS up ON up.xidx = nxt.xidx AND up.yidx = nxt.yidx - 1
        WHERE l.xsym != l.ysym
    )
),
backtrack(
    xidx, yidx,
    word
) AS (
    SELECT 
        length(s1()), length(s2()),
        ''

    UNION ALL

    (
        SELECT 
            xidx-1, yidx-1,
            xsym || word    -- expand word
        FROM 
            backtrack NATURAL JOIN lcs 
                      NATURAL JOIN letters
        WHERE from_diag

        UNION 

        SELECT 
            xidx-1, yidx,
            word
        FROM backtrack NATURAL JOIN lcs
        WHERE from_left

        UNION

        SELECT
            xidx, yidx-1,
            word
        FROM backtrack NATURAL JOIN lcs
        WHERE from_up
    )
)
SELECT list(word) 
FROM (
    SELECT DISTINCT word
    FROM backtrack
    WHERE xidx = 0 OR yidx = 0
)