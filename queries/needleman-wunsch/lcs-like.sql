-- Unfertiges File

-- Notiz: Unterschied zwischen Needleman-Wunsch und LCS
-- In Needleman-Wunsch muss man immer auf alle drei Richtungen zugreifen, unabhängig von den 
-- Buchstaben. Bei LCS Entscheidet der Vergleich zwischen den Buchstaben, ob man
-- diagonal oder "gerade" auswählt.
-- Bei LCS kann man den Letter-Vergleich daher im WHERE-Clause machen, was bei needleman nicht
-- geht, weil die Berechnung der scores ja erst ausgeführt werden muss, und dann
-- die Scores verglichen werden.

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
    strings1, strings2
) USING KEY (xidx, yidx) AS (
    -- Initial Case
    (
        SELECT 
            xidx, yidx,
            -xidx,
            [''], ['']
        FROM letters
        WHERE yidx = 0

        UNION   

        SELECT 
            xidx, yidx,
            -yidx,
            [''], ['']
        FROM letters
        WHERE xidx = 0
    )

    UNION

    WITH scores (
        xidx, yidx, 
        diag, lft, right,
        strings1_diag, strings1_lft, strings1_right,
        strings2_diag, strings2_lft, strings2_right
    ) AS (
        SELECT 
            this.xidx, this.yidx,
            CASE 
                WHEN ltrs.xsym = ltrs.ysym         
                THEN diag.score + match_score()
                ELSE diag.score + mismatch_score()
            END,
            lft.score + indel_score(),
            right.score + indel_score(),
            diag.strings1, lft.strings1, right.strings1,
            diag.strings2, lft.strings2, right.strings2
        FROM 
            letters AS ltrs
            JOIN recurring.needleman_wunsch AS diag ON diag.xidx = ltrs.xidx-1 AND diag.yidx = ltrs.yidx-1
            JOIN recurring.needleman_wunsch AS lft ON lft.xidx = ltrs.xidx-1 AND lft.yidx = ltrs.yidx 
            JOIN recurring.needleman_wunsch AS right ON right.xidx = ltrs.xidx AND right.yidx = ltrs.yidx-1
            LEFT OUTER JOIN recurring.needleman_wunsch AS this ON this.xidx = ltrs.xidx AND this.yidx = ltrs.yidx
        WHERE 
            this.score IS NULL
    )
    SELECT 
        xidx, yidx,
        greatest(diag, lft, right),

    FROM score
)