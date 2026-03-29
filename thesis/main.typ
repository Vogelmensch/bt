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

#pagebreak()
#include "chapters/ai_versions.typ"