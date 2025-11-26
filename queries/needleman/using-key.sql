-- This query implements the 'needleman-wunsch'-algorithm
-- It aligns two strings (most commonly DNA sequences) based on a scoring system
-- The scoring system is being defined at the top of this query as macros
-- ❶ Create a table `letters` that holds the cross product of all letters in the two substrings
-- ❷ Initial Case: Aligning any letter with an empty sequence shifts the sequence, i.e. includes an indel
-- ❸ Calculate the score for each of the three possible alignments for the next combination of letters
-- ❹ Highlight the path(s) corresponding to the highest score
-- ❺ Build the resulting strings in backtracking process, using the highlighted paths
-- Recurring Table: Holds score and paths for previous sub-solutions

-- https://en.wikipedia.org/wiki/Needleman-Wunsch_algorithm

-- Input Strings
CREATE OR REPLACE MACRO s1() AS {string1};
CREATE OR REPLACE MACRO s2() AS {string2};

-- Scoring System
CREATE OR REPLACE MACRO match_score() AS 1;
CREATE OR REPLACE MACRO mismatch_score() AS -1;
CREATE OR REPLACE MACRO indel_score() AS -1;

-- ❶ Create a table `letters` that holds the cross product of all letters in the two substrings
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
    -- ❷ Initial Case: Aligning any letter with an empty sequence shifts the sequence, i.e. includes an indel
    (
        SELECT 
            xidx, yidx,
            xidx * indel_score(),
            false, false, false
        FROM letters
        WHERE yidx = 0

        UNION   

        SELECT 
            xidx, yidx,
            yidx * indel_score(),
            false, false, false
        FROM letters
        WHERE xidx = 0
    )

    UNION

    -- ❸ Calculate the score for each of the three possible alignments for the next combination of letters
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

        -- ❹ Highlight the path(s) corresponding to the highest score
        SELECT 
            xidx, yidx,
            max,
            lft = max, up = max, diag = max
        FROM scores
    )
),
-- ❺ Build the resulting strings in backtracking process, using the highlighted paths
backtrack(
    xidx, yidx, 
    string1,
    string2
) AS (
    SELECT 
        length(s1()), length(s2()),
        '', 
        ''

    UNION ALL 

    (
        -- expand string1 and insert 'indel' into string2
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

        -- insert 'indel' into string1 and expand string2
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

        -- expand both strings
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

        -- notice that all paths can be taken simultaneously if scores are equal
    )
)
SELECT list(string1), list(string2) 
FROM (
    SELECT DISTINCT string1, string2
    FROM backtrack
    WHERE xidx = 0 OR yidx = 0
);