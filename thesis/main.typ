#import "simple.typ": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#show: codly-init.with()
#codly(
  languages: (
    sql: (name: "SQL", icon: text(size: 7pt, [🦆]),)
  )
)
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

= Abstract

#include "chapters/abstract.typ"

#page()[
  #outline(indent: auto, depth: 4)
]

#show: mainmatter

#set figure(placement: auto)

#include "chapters/introduction.typ"
#include "chapters/basics.typ"
#include "chapters/algorithms.typ"
#include "chapters/measuring.typ"
#include "chapters/conclusions.typ"


#show: backmatter 
#pagebreak(to: "even")
#bibliography("references.bib")

#pagebreak()
#include "chapters/ai_versions.typ"