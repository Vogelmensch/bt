#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

#let tablestroke = 0.5pt
#let t(s) = text(
  size: 8pt,
  s
)

#let (l, m, r, fr) = (
  (-1,0),
  (0,0),
  (1,0),
  (1,1)
)

#let cte_table(pos, table_name, ..content) = node(
  pos,
  shape: rect,
  stroke: tablestroke,
  grid(
    rows: 2,
    row-gutter: 10pt,
    table(
      columns: 3,
      rows:1,
      stroke: (y: none),
      table.hline(),
      table.header(
        [*iteration*], [*n*], [*x*]
      ),
      table.hline(),
      ..content,
      table.hline()
    ),
    [#table_name]
  )
)


#let rec_step(i, name: "recursive step") = node(
  m,
  shape: rect,
  stroke: tablestroke,
  grid(
    rows: 3,
    row-gutter: 5pt,
    [\<#name\>],
    [⚙],
    [iteration: #i]
  )
)

#diagram(
  cte_table(l, "Working Table", [-], [-], [-]),
  rec_step(0, name: "base case"),  
  edge(t("writes to"), "->"),
  edge(m, fr, t("writes to"), "->", bend:-35deg),
  cte_table(r, "Intermediate Table", [0],[1],[2]),
  cte_table(fr, "Union Table", [0], [1], [2])
)

#diagram(
  cte_table(l, "Working Table", [0], [1], [2]),
  rec_step("-", name: "between iterations"),  
  cte_table(r, "Intermediate Table", [0],[1],[2]),
  edge(r, l, t("writes to"), "->", bend:-35deg),
  cte_table(fr, "Union Table", [0], [1], [2])
)

#diagram(
  cte_table(l, "Working Table", [0], [1], [2]),
  edge(t("read by"), "->"),
  rec_step(1),  
  edge(t("writes to"), "->"),
  edge(m, fr, t("writes to"), "->", bend:-35deg),
  cte_table(r, "Intermediate Table", [1],[2],[4]),
  cte_table(fr, "Union Table", 
    [0], [1], [2],
    [1], [2], [4]
  )
)

#diagram(
  cte_table(l, "Working Table", [1], [2], [4]),
  rec_step("-", name: "between iterations"),  
  cte_table(r, "Intermediate Table", [1],[2],[4]),
  edge(r, l, t("writes to"), "->", bend:-35deg),
  cte_table(fr, "Union Table", 
    [0], [1], [2],
    [1], [2], [4]
  )
)

#diagram(
  cte_table(l, "Working Table", [1], [2], [4]),
  edge(t("read by"), "->"),
  rec_step(2),  
  edge(t("writes to"), "->"),
  edge(m, fr, t("writes to"), "->", bend:-35deg),
  cte_table(r, "Intermediate Table", [2],[3],[8]),
  cte_table(fr, "Union Table", 
    [0], [1], [2],
    [1], [2], [4],
    [2], [3], [8]
  )
)
