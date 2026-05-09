#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#show: codly-init.with()
#codly(
  zebra-fill: luma(220),
)

#import "@preview/touying:0.7.1": *
#import themes.simple: *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#let fletcher-diagram = touying-reducer.with(reduce: fletcher.diagram, cover: fletcher.hide)

#show: simple-theme.with(aspect-ratio: "16-9")

// define words that should not obey RAW resizing
#show raw: it => {
  if not (
    "USING KEY",
    "filtered_astar",
    "FAR",
    "BAR",
    " AR",
    "BEAR",
    "HERE",
    "ER"
  ).contains(it.text) {
    set text(size: 12pt)
    it
  } else {
    it
  }
}
#set raw(syntaxes: "../thesis/custom_sql.sublime-syntax")
#set text(font: "Open Sans")

= Actually `USING KEY`: Exploring Practical Applications of DuckDB’s New Recursive CTE Semantics

#codly-disable()
#include "intro.typ"
#include "theory.typ"

#codly-enable()
#include "astar.typ"
#include "astar_tables.typ"
#include "astar_measure.typ"

#codly-enable()
#include "lcs.typ"
#include "lcs_tables.typ"
#include "lcs_measure.typ"

#include "needleman_measure.typ"

#include "bishop.typ"

#include "summary.typ"