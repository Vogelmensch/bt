#import "simple.typ": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

#show: doc => template(
  affiliation: "Eberhard Karls Universität Tübingen",
  institute: [
    Mathematisch-Naturwissenschaftliche Fakultät

    Wilhelm-Schickard-Institut für Informatik

    Lehrstuhl für Datenbanksysteme
  ],
  title: [Ode to Lorem Ipsum],
  authors: ("Lorem Ipsum",),
  examiners: ("Prof. Dr. Lorem Ipsum", "Prof. Dr. Dolor Sit"),
  supervisors: ("Amet Consectetur", "Adipiscing Elit"),
  type: "Bachelor of Science Informatik",
  start-date: "01.05.2018",
  end-date: "19.06.2024",
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

This is an abstract.

#page()[
  #outline(indent: auto, depth: 4)
]

#show: mainmatter

#show: backmatter

#pagebreak(to: "even")

#bibliography("references.bib")
