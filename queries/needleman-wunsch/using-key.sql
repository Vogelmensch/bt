-- Input Strings
CREATE OR REPLACE MACRO s1() AS 'GCATGCG';
CREATE OR REPLACE MACRO s2() AS 'GATTACA';

-- Scoring System
CREATE OR REPLACE MACRO match_score() AS 1;
CREATE OR REPLACE MACRO mismatch_score() AS -1;
CREATE OR REPLACE MACRO indel_score() AS -1;

CREATE OR REPLACE TABLE letters(xsym, xidx, ysym, yidx) AS (
    SELECT s1()[m], m, s2()[n], n
    FROM 
        range(length(s1())+1) AS r(m),
        range(length(s2())+1) AS r(n)
);

WITH RECURSIVE needleman_wunsch (
    xidx, yidx,
    score,
    from_lft, from_up, from_diag
) USING KEY (xidx, yidx) AS (
    -- initial case: negative scores at the corner

    -- TODO: The initial case produces many coordinates. In the first recursive iteration, the coordinates taken from the initial case are not unique.
    SELECT 
        0, 0,
        0,
        false, false, false

    UNION 

    (
        WITH coords(x, y) AS (
            SELECT
                (nw.xidx + 1) % (length(s1()) + 1),
                CASE 
                    WHEN nw.xidx < length(s1())
                    THEN nw.yidx
                    ELSE yidx+1
                END
            FROM needleman_wunsch AS nw
        ),
        scores_intermediate(lft, up, diag) AS (
            SELECT 
                lft.score + indel_score(),
                up.score + indel_score(),
                CASE 
                    WHEN l.xsym = l.ysym 
                    THEN diag.score + match_score()
                    ELSE diag.score + mismatch_score()
                END
            FROM 
                coords AS c JOIN
                letters AS l ON c.x = l.xidx AND c.y = l.yidx LEFT OUTER JOIN
                recurring.needleman_wunsch AS lft  ON lft.xidx = c.x-1 AND lft.yidx = c.y LEFT OUTER JOIN
                recurring.needleman_wunsch AS up   ON up.xidx = c.x AND up.yidx = c.y-1 LEFT OUTER JOIN
                recurring.needleman_wunsch AS diag ON diag.xidx = c.x-1 AND diag.yidx = c.y-1
        ),
        scores(lft, up, diag, max) AS (
            SELECT 
                lft,
                up,
                diag,
                greatest(lft, up, diag)
            FROM scores_intermediate
        )
        SELECT
            c.x, c.y,
            s.max,
            s.lft = s.max, s.up = s.max, s.diag = s.max
        FROM 
            coords AS c, 
            scores AS s
    )
),
backtrack(
    x, y, 
    string1,
    string2) AS (
    -- Initial Case
    (
        SELECT 
            nw.xidx-1, nw.yidx,
            l.xsym,
            '-'
        FROM 
            needleman_wunsch AS nw JOIN 
            letters AS l ON nw.xidx = l.xidx AND nw.yidx = l.yidx
        WHERE
            nw.xidx = length(s1()) AND 
            nw.yidx = length(s2()) AND
            nw.from_lft
        
        UNION

        SELECT 
            nw.xidx, nw.yidx-1,
            '-',
            l.ysym
        FROM 
            needleman_wunsch AS nw JOIN 
            letters AS l ON nw.xidx = l.xidx AND nw.yidx = l.yidx
        WHERE
            nw.xidx = length(s1()) AND 
            nw.yidx = length(s2()) AND
            nw.from_up
        
        UNION

        SELECT 
            nw.xidx-1, nw.yidx-1,
            l.xsym,
            l.ysym
        FROM 
            needleman_wunsch AS nw JOIN 
            letters AS l ON nw.xidx = l.xidx AND nw.yidx = l.yidx
        WHERE
            nw.xidx = length(s1()) AND 
            nw.yidx = length(s2()) AND
            nw.from_diag
    )

    UNION ALL 

    (
        SELECT 
            nw.xidx-1, nw.yidx,
            l.xsym || b.string1,
            '-' || b.string2
        FROM 
            backtrack AS b JOIN 
            needleman_wunsch AS nw ON b.x = nw.xidx AND b.y = nw.yidx JOIN 
            letters AS l ON nw.xidx = l.xidx AND nw.yidx = l.yidx 
        WHERE
            nw.from_lft
        
        UNION

        SELECT 
            nw.xidx, nw.yidx-1,
            '-' || b.string1,
            l.ysym || b.string2
        FROM 
            backtrack AS b JOIN 
            needleman_wunsch AS nw ON b.x = nw.xidx AND b.y = nw.yidx JOIN 
            letters AS l ON nw.xidx = l.xidx AND nw.yidx = l.yidx 
        WHERE
            nw.from_up
        
        UNION

        SELECT 
            nw.xidx-1, nw.yidx-1,
            l.xsym || b.string1,
            l.ysym || b.string2
        FROM 
            backtrack AS b JOIN 
            needleman_wunsch AS nw ON b.x = nw.xidx AND b.y = nw.yidx JOIN 
            letters AS l ON nw.xidx = l.xidx AND nw.yidx = l.yidx 
        WHERE
            nw.from_diag
    )
)

SELECT string1, string2
FROM backtrack
WHERE x = 0 AND y = 0;