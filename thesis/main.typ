#import "simple.typ": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

#set raw(syntaxes: "custom_sql.sublime-syntax")

#show: doc => template(
  affiliation: "Eberhard Karls Universität Tübingen",
  institute: [
    Mathematisch-Naturwissenschaftliche Fakultät

    Wilhelm-Schickard-Institut für Informatik

    Lehrstuhl für Datenbanksysteme
  ],
  title: [Actually USING KEY: Exploring Practical Applications of DuckDB’s New Recursive CTE Semantics],
  authors: ("David Knöpp",),
  examiners: ("Prof. Dr. Torsten Grust",),
  supervisors: ("Björn Bamberg",),
  type: "Bachelor of Science Informatik",
  start-date: "01.12.2025",
  end-date: "01.04.2026",
  doc,)

#show: frontmatter

= Declaration of Authorship

Hiermit versichere ich, dass ich die vorliegende Thesis selbständig
und nur mit den angegebenen Hilfsmitteln angefertigt habe und dass alle
Stellen, die dem Wortlaut oder dem Sinne nach anderen Werken entnommen
sind, durch Angaben von Quellen als Entlehnung kenntlich gemacht worden
sind. Diese Thesis wurde in gleicher oder ähnlicher Form in keinem
anderen Studiengang als Prüfungsleistung vorgelegt.

#v(5em)

#grid(
  columns: (0.8fr, 0.8fr),
  align: (center, center),
  gutter: 1em,
  column-gutter: 5em,
  line(length: 100%, stroke: (paint: luma(80%), cap: "round")),
  line(length: 100%, stroke: (paint: luma(80%), cap: "round")),
  [Ort, Datum],
  [Unterschrift]
)

#pagebreak()

= Abstract

#include "chapters/abstract.typ"

#page()[
  #outline(indent: auto, depth: 4)
]

#show: mainmatter

#include "chapters/introduction.typ"
#include "chapters/basics.typ"
#include "chapters/algorithms.typ"
#include "chapters/measuring.typ"
#include "chapters/conclusions.typ"


#show: backmatter 
#pagebreak(to: "even")
#bibliography("references.bib")
