#import "@preview/touying:0.7.1": *
#import themes.simple: *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#let fletcher-diagram = touying-reducer.with(reduce: fletcher.diagram, cover: fletcher.hide)

#show: simple-theme.with(aspect-ratio: "16-9")

#show raw: set text(size: 14pt)


= Actually USING KEY: Exploring Practical Applications of DuckDB’s New Recursive CTE Semantics

#include "theory.typ"

#include "astar.typ"
#include "astar_tables.typ"
#include "astar_measure.typ"

#include "lcs.typ"
#include "lcs_tables.typ"
#include "lcs_measure.typ"

#include "needleman.typ"