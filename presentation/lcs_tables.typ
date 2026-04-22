#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *

// dimension for dynamic programming tables
#let dim = 16pt

#let orange = rgb("#ffB51b")

#let t(len, left, up, diag, color) = table.cell(
    grid(
        rows: (dim, dim),
        columns: (dim, dim),
        gutter: 6pt,
        if diag [↖] else [#text(color)[↖]],
        if up [↑] else [#text(color)[↑]],
        if left [←] else [#text(color)[←]], 
        [#len]
    ),
    fill: color,
)

#let e = t("", false, false, false, white)

== LCS: Base Case

#let lcs_table(table, code) = grid(
  columns: 2,
  column-gutter: 30pt,
  {
    set text(size: 20pt)
    table
  },
  code
)

#lcs_table(
  table(
    rows: 6,
    columns: 6,
    stroke: 0.5pt,
    [], table.vline(stroke: 1pt), [*$epsilon$*], [*B*], [*E*], [*A*], [*R*],
    table.hline(stroke: 1pt),
    [*$epsilon$*], [0], [0], [0], [0], [0],
    [*H*], [0], e, e, e, e,
    [*E*], [0], e, e, e, e,
    [*R*], [0], e, e, e, e,
    [*E*], [0], e, e, e, e,
  ),
  ```sql
  SELECT 
      xsym, xidx,
      ysym, yidx,
      0,
      false, false, false
  FROM letters
  WHERE xidx = 0 or yidx = 0
  ```,
)


== LCS: Letters are not equal


#lcs_table(
  table(
      rows: 6,
      columns: 6,
      stroke: 0.5pt,
      [], table.vline(stroke: 1pt), [*$epsilon$*], [*B*], [*E*], [*A*], [*R*],
      table.hline(stroke: 1pt),
      [*$epsilon$*], [0], [0], [0], [0], [0],
      [*H*], [0], t(0, true, true, false, lime), e, e, e,
      [*E*], [0], e, e, e, e,
      [*R*], [0], e, e, e, e,
      [*E*], [0], e, e, e, e,
  ),
  ```sql
  SELECT
      ltrs.xsym, ltrs.xidx,
      ltrs.ysym, ltrs.yidx,
      greatest(l.len, u.len),
      l.len >= u.len, u.len >= l.len, false
  FROM 
      letters AS ltrs 
      JOIN recurring.lcs            AS l ON <left>
      JOIN recurring.lcs            AS u ON <above>
      LEFT OUTER JOIN recurring.lcs AS this ON <this>
  WHERE 
      this.len IS NULL AND    
      ltrs.xsym != ltrs.ysym 
  ```
)

== LCS: Letters are equal


#lcs_table(
  table(
      rows: 6,
      columns: 6,
      stroke: 0.5pt,
      [], table.vline(stroke: 1pt), [*$epsilon$*], [*B*], [*E*], [*A*], [*R*],
      table.hline(stroke: 1pt),
      [*$epsilon$*], [0], [0], [0], [0], [0],
      [*H*], [0], t(0, true, true, false, white), e, e, e,
      [*E*], [0], e, t(1, false, false, true, lime), e, e,
      [*R*], [0], e, e, e, e,
      [*E*], [0], e, e, e, e,
  ),
  ```sql
  SELECT
      ltrs.xsym, ltrs.xidx,
      ltrs.ysym, ltrs.yidx,
      diag.len + 1,
      false, false, true
  FROM 
      letters                       AS ltrs 
      JOIN recurring.lcs            AS diag ON <diag> 
      LEFT OUTER JOIN recurring.lcs AS this ON <this>
  WHERE 
      this.len IS NULL AND    
      ltrs.xsym = ltrs.ysym  
  ```
)

== LCS: Letters are equal

#lcs_table(
  table(
      rows: 6,
      columns: 6,
      stroke: 0.5pt,
      [], table.vline(stroke: 1pt), [*$epsilon$*], [*B*], [*E*], [*A*], [*R*],
      table.hline(stroke: 1pt),
      [*$epsilon$*], [0], [0], [0], [0], [0],
      [*H*], [0], t(0, true, true, false, white), t(0, true, true, false, lime), e, e,
      [*E*], [0], t(0, true, true, false, lime), t(1, false, false, true, lime), e, e,
      [*R*], [0], e, e, e, e,
      [*E*], [0], e, e, e, e,
  ),
  []
)

== LCS: Letters are equal

#lcs_table(
  table(
      rows: 6,
      columns: 6,
      stroke: 0.5pt,
      [], table.vline(stroke: 1pt), [*$epsilon$*], [*B*], [*E*], [*A*], [*R*],
      table.hline(stroke: 1pt),
      [*$epsilon$*], [0], [0], [0], [0], [0],
      [*H*], [0], t(0, true, true, false, white), t(0, true, true, false, white), t(0, true, true, false, lime), e,
      [*E*], [0], t(0, true, true, false, white), t(1, false, false, true, white), e, e,
      [*R*], [0], t(0, true, true, false, lime), e, e, e,
      [*E*], [0], e, e, e, e,
  ),
  []
)

== LCS: Letters are equal

#lcs_table(
  table(
      rows: 6,
      columns: 6,
      stroke: 0.5pt,
      [], table.vline(stroke: 1pt), [*$epsilon$*], [*B*], [*E*], [*A*], [*R*],
      table.hline(stroke: 1pt),
      [*$epsilon$*], [0], [0], [0], [0], [0],
      [*H*], [0], t(0, true, true, false, white), t(0, true, true, false, white), t(0, true, true, false, white), t(0, true, true, false, lime),
      [*E*], [0], t(0, true, true, false, white), t(1, false, false, true, white), t(1, true, false, false, lime), e,
      [*R*], [0], t(0, true, true, false, white), t(1, false, true, false, lime), e, e,
      [*E*], [0], t(0, true, true, false, lime), t(1, false, false, true, lime), e, e,
  ),
  []
)

== LCS: Letters are equal

#lcs_table(
  table(
    rows: 6,
    columns: 6,
    stroke: 0.5pt,
    [], table.vline(stroke: 1pt), [*$epsilon$*], [*B*], [*E*], [*A*], [*R*],
    table.hline(stroke: 1pt),
    [*$epsilon$*], [0], [0], [0], [0], [0],
    [*H*], [0], t(0, true, true, false, white), t(0, true, true, false, white), t(0, true, true, false, white), t(0, true, true, false, white),
    [*E*], [0], t(0, true, true, false, white), t(1, false, false, true, white), t(1, true, false, false, white), t(1, true, false, false, lime),
    [*R*], [0], t(0, true, true, false, white), t(1, false, true, false, white), t(1, true, true, false, lime), t(2, false, false, true, lime),
    [*E*], [0], t(0, true, true, false, white), t(1, false, false, true, white), e, e,
  ),
  []
)

== LCS: Letters are equal

#lcs_table(
  table(
    rows: 6,
    columns: 6,
    stroke: 0.5pt,
    [], table.vline(stroke: 1pt), [*$epsilon$*], [*B*], [*E*], [*A*], [*R*],
    table.hline(stroke: 1pt),
    [*$epsilon$*], [0], [0], [0], [0], [0],
    [*H*], [0], t(0, true, true, false, white), t(0, true, true, false, white), t(0, true, true, false, white), t(0, true, true, false, white),
    [*E*], [0], t(0, true, true, false, white), t(1, false, false, true, white), t(1, true, false, false, white), t(1, true, false, false, white),
    [*R*], [0], t(0, true, true, false, white), t(1, false, true, false, white), t(1, true, true, false, white), t(2, false, false, true, white),
    [*E*], [0], t(0, true, true, false, white), t(1, false, false, true, white), t(1, true, true, false, lime), e,
  ),
  []
)

== LCS: Letters are equal

#lcs_table(
  table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*B*], [*E*], [*A*], [*R*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], [0], [0], [0], [0], [0],
            [*H*], [0], t(0, true, true, false, white), t(0, true, true, false, white), t(0, true, true, false, white), t(0, true, true, false, white),
            [*E*], [0], t(0, true, true, false, white), t(1, false, false, true, white), t(1, true, false, false, white), t(1, true, false, false, white),
            [*R*], [0], t(0, true, true, false, white), t(1, false, true, false, white), t(1, true, true, false, white), t(2, false, false, true, white),
            [*E*], [0], t(0, true, true, false, white), t(1, false, false, true, white), t(1, true, true, false, white), t(2, false, true, false, lime),
        ),
  []
)

== LCS: Letters are equal

#lcs_table(
  table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*B*], [*E*], [*A*], [*R*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], [0], table.cell([0], fill: orange), [0], [0], [0],
            [*H*], table.cell([0], fill: orange), t(0, true, true, false, orange), t(0, true, true, false, white), t(0, true, true, false, white), t(0, true, true, false, white),
            [*E*], [0], t(0, true, true, false, white), t(1, false, false, true, orange), t(1, true, false, false, orange), t(1, true, false, false, white),
            [*R*], [0], t(0, true, true, false, white), t(1, false, true, false, white), t(1, true, true, false, white), t(2, false, false, true, orange),
            [*E*], [0], t(0, true, true, false, white), t(1, false, false, true, white), t(1, true, true, false, white), t(2, false, true, false, orange),
        ),
  []
)