#let redbox(content) = box(
    stroke: 1pt + red,
    inset: 2mm,
    content
)

#let orange = rgb("#ffB51b")

#let dim = 5pt

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
    fill: color
)

#let e = t("", false, false, false, white)