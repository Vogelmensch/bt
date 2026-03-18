#let t(len, left, up, diag, color) = table.cell(
    grid(
        rows: 2,
        columns: 2,
        gutter: 3pt,
        if diag [↖] else [#text(color)[↖]],
        if up [↑] else [#text(color)[↑]],
        if left [←] else [#text(color)[←]], 
        [#len]
    ),
    fill: color
)

#let e = t("", false, false, false, white)

#figure(
    caption: [Dynamic programming table in various iterations. The arrows represent the boolean flags `from_left`, `from_up` and `from_diag`. The numbers represent the `len`-value. Marked in green are the elements that are being added in the respective iteration. In the last table, the final path is marked in orange.],
    grid(
        rows: 4,
        columns: 2,
        gutter: 20pt,

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

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*B*], [*E*], [*A*], [*R*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, white), table.cell([0], fill: orange), [0], [0], [0],
            [*H*], table.cell([0], fill: orange), t(0, true, true, false, orange), t(0, true, true, false, white), t(0, true, true, false, white), t(0, true, true, false, white),
            [*E*], [0], t(0, true, true, false, white), t(1, false, false, true, orange), t(1, true, false, false, orange), t(1, true, false, false, white),
            [*R*], [0], t(0, true, true, false, white), t(1, false, true, false, white), t(1, true, true, false, white), t(2, false, false, true, orange),
            [*E*], [0], t(0, true, true, false, white), t(1, false, false, true, white), t(1, true, true, false, white), t(2, false, true, false, orange),
        ),
    )
)


#figure(
    caption: [bla],
    grid(
        columns: 2,
        gutter: 20pt,

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, white), t(-1, true, false, false, white), t(-2, true, false, false, white), t(-3, true, false, false, white), t(-4, true, false, false, white),
            [*A*], t(-1, false, true, false, white), t(-1, false, false, true, lime), e, e, e,
            [*A*], t(-2, false, true, false, white), e, e, e, e,
            [*T*], t(-3, false, true, false, white), e, e, e, e,
            [*G*], t(-4, false, true, false, white), e, e, e, e,
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, white), t(-1, true, false, false, white), t(-2, true, false, false, white), t(-3, true, false, false, white), t(-4, true, false, false, white),
            [*A*], t(-1, false, true, false, white), t(-1, false, false, true, white), t(0, false, false, true, lime), e, e,
            [*A*], t(-2, false, true, false, white), t(-2, false, true, true, lime), e, e, e,
            [*T*], t(-3, false, true, false, white), e, e, e, e,
            [*G*], t(-4, false, true, false, white), e, e, e, e,
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, white), t(-1, true, false, false, white), t(-2, true, false, false, white), t(-3, true, false, false, white), t(-4, true, false, false, white),
            [*A*], t(-1, false, true, false, white), t(-1, false, false, true, white), t(0, false, false, true, white), t(-1, true, false, false, lime), e,
            [*A*], t(-2, false, true, false, white), t(-2, false, true, true, white), t(0, false, false, true, lime), e, e,
            [*T*], t(-3, false, true, false, white), t(-3, false, true, true, lime), e, e, e,
            [*G*], t(-4, false, true, false, white), e, e, e, e,
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, white), t(-1, true, false, false, white), t(-2, true, false, false, white), t(-3, true, false, false, white), t(-4, true, false, false, white),
            [*A*], t(-1, false, true, false, white), t(-1, false, false, true, white), t(0, false, false, true, white), t(-1, true, false, false, white), t(-2, true, false, true, lime),
            [*A*], t(-2, false, true, false, white), t(-2, false, true, true, white), t(0, false, false, true, white), t(-1, true, false, true, lime), e,
            [*T*], t(-3, false, true, false, white), t(-3, false, true, true, white), t(-1, false, true, false, lime), e, e,
            [*G*], t(-4, false, true, false, white), t(-2, false, false, true, lime), e, e, e,
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, white), t(-1, true, false, false, white), t(-2, true, false, false, white), t(-3, true, false, false, white), t(-4, true, false, false, white),
            [*A*], t(-1, false, true, false, white), t(-1, false, false, true, white), t(0, false, false, true, white), t(-1, true, false, false, white), t(-2, true, false, true, white),
            [*A*], t(-2, false, true, false, white), t(-2, false, true, true, white), t(0, false, false, true, white), t(-1, true, false, true, white), t(0, false, false, true, lime),
            [*T*], t(-3, false, true, false, white), t(-3, false, true, true, white), t(-1, false, true, false, white), t(-1, false, false, true, lime), e,
            [*G*], t(-4, false, true, false, white), t(-2, false, false, true, white), t(-2, false, true, false, lime), e, e,
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, white), t(-1, true, false, false, white), t(-2, true, false, false, white), t(-3, true, false, false, white), t(-4, true, false, false, white),
            [*A*], t(-1, false, true, false, white), t(-1, false, false, true, white), t(0, false, false, true, white), t(-1, true, false, false, white), t(-2, true, false, true, white),
            [*A*], t(-2, false, true, false, white), t(-2, false, true, true, white), t(0, false, false, true, white), t(-1, true, false, true, white), t(0, false, false, true, white),
            [*T*], t(-3, false, true, false, white), t(-3, false, true, true, white), t(-1, false, true, false, white), t(-1, false, false, true, white), t(-1, false, true, false, lime),
            [*G*], t(-4, false, true, false, white), t(-2, false, false, true, white), t(-2, false, true, false, white), t(0, false, false, true, lime), e,
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, white), t(-1, true, false, false, white), t(-2, true, false, false, white), t(-3, true, false, false, white), t(-4, true, false, false, white),
            [*A*], t(-1, false, true, false, white), t(-1, false, false, true, white), t(0, false, false, true, white), t(-1, true, false, false, white), t(-2, true, false, true, white),
            [*A*], t(-2, false, true, false, white), t(-2, false, true, true, white), t(0, false, false, true, white), t(-1, true, false, true, white), t(0, false, false, true, white),
            [*T*], t(-3, false, true, false, white), t(-3, false, true, true, white), t(-1, false, true, false, white), t(-1, false, false, true, white), t(-1, false, true, false, white),
            [*G*], t(-4, false, true, false, white), t(-2, false, false, true, white), t(-2, false, true, false, white), t(0, false, false, true, white), t(-1, true, false, false, lime),
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, orange), t(-1, true, false, false, white), t(-2, true, false, false, white), t(-3, true, false, false, white), t(-4, true, false, false, white),
            [*A*], t(-1, false, true, false, white), t(-1, false, false, true, orange), t(0, false, false, true, white), t(-1, true, false, false, white), t(-2, true, false, true, white),
            [*A*], t(-2, false, true, false, white), t(-2, false, true, true, white), t(0, false, false, true, orange), t(-1, true, false, true, white), t(0, false, false, true, white),
            [*T*], t(-3, false, true, false, white), t(-3, false, true, true, white), t(-1, false, true, false, orange), t(-1, false, false, true, white), t(-1, false, true, false, white),
            [*G*], t(-4, false, true, false, white), t(-2, false, false, true, white), t(-2, false, true, false, white), t(0, false, false, true, orange), t(-1, true, false, false, orange),
        ),
    )
) 