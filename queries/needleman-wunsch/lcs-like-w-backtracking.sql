-- Unfertiges File

-- Notiz: Unterschied zwischen Needleman-Wunsch und LCS
-- In Needleman-Wunsch muss man immer auf alle drei Richtungen zugreifen, unabhängig von den 
-- Buchstaben. Bei LCS Entscheidet der Vergleich zwischen den Buchstaben, ob man
-- diagonal oder "gerade" auswählt.
-- Bei LCS kann man den Letter-Vergleich daher im WHERE-Clause machen, was bei needleman nicht
-- geht, weil die Berechnung der scores ja erst ausgeführt werden muss, und dann
-- die Scores verglichen werden.

-- Input Strings
CREATE OR REPLACE MACRO s1() AS {string1};
CREATE OR REPLACE MACRO s2() AS {string2};

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
    -- Initial Case
    (
        SELECT 
            xidx, yidx,
            -xidx,
            false, false, false
        FROM letters
        WHERE yidx = 0

        UNION   

        SELECT 
            xidx, yidx,
            -yidx,
            false, false, false
        FROM letters
        WHERE xidx = 0
    )

    UNION

    (
        WITH scores_intermediate (
            xidx, yidx, 
            lft, up, diag
        ) AS (
            SELECT 
                ltrs.xidx, ltrs.yidx,
                lft.score + indel_score(),
                up.score + indel_score(),
                CASE 
                    WHEN ltrs.xsym = ltrs.ysym         
                    THEN diag.score + match_score()
                    ELSE diag.score + mismatch_score()
                END
            FROM 
                letters AS ltrs
                JOIN recurring.needleman_wunsch AS diag ON diag.xidx = ltrs.xidx-1 AND diag.yidx = ltrs.yidx-1
                JOIN recurring.needleman_wunsch AS lft ON lft.xidx = ltrs.xidx-1 AND lft.yidx = ltrs.yidx 
                JOIN recurring.needleman_wunsch AS up ON up.xidx = ltrs.xidx AND up.yidx = ltrs.yidx-1
                LEFT OUTER JOIN recurring.needleman_wunsch AS this ON this.xidx = ltrs.xidx AND this.yidx = ltrs.yidx
            WHERE 
                this.score IS NULL 
        ),
        scores (
            xidx, yidx, 
            lft, up, diag, max
        ) AS (
            SELECT 
                xidx, yidx,
                lft, up, diag, greatest(lft, up, diag)
            FROM scores_intermediate
        )

        SELECT 
            xidx, yidx,
            max,
            lft = max, up = max, diag = max
        FROM scores
    )
),
backtrack(
    xidx, yidx, 
    string1,
    string2
) AS (
    -- Initial Case
    SELECT 
        length(s1()), length(s2()),
        '', 
        ''

    UNION ALL 

    (
        SELECT 
            nw.xidx-1, nw.yidx,
            l.xsym || b.string1,
            '-' || b.string2
        FROM 
            backtrack AS b JOIN 
            needleman_wunsch AS nw ON b.xidx = nw.xidx AND b.yidx = nw.yidx JOIN 
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
            needleman_wunsch AS nw ON b.xidx = nw.xidx AND b.yidx = nw.yidx JOIN 
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
            needleman_wunsch AS nw ON b.xidx = nw.xidx AND b.yidx = nw.yidx JOIN 
            letters AS l ON nw.xidx = l.xidx AND nw.yidx = l.yidx 
        WHERE
            nw.from_diag
    )
)
SELECT list(string1), list(string2) 
FROM (
    SELECT DISTINCT string1, string2
    FROM backtrack
    WHERE xidx = 0 OR yidx = 0
);