#import "@preview/splash:0.4.0": xcolor

#let monofont = ("New Computer Modern Mono", "Apple Color Emoji")

#let frontmatter(doc) = {
  set page(numbering: "i")
  doc
}

#let mainmatter(doc) = {
  set heading(numbering: "1.1.1.")
  set page(numbering: "1")

  show heading.where(level: 1): it => {
    pagebreak(weak: true, to: "even")
    stack(dir: ttb, spacing: 1em,
      align(right)[#text(size: 54pt, fill: luma(75%))[#counter(heading).display()]],
      it.body,
      line(length: 100%, stroke: (paint: luma(80%), cap: "round")),
      v(1em)
    )
  }

  show heading.where(level: 2): it => [
    #block(
      sticky: true,
      [#text(fill: xcolor.orange)[#counter(heading).display()] #it.body]
    )
  ]

  show heading.where(level: 3): it => [
    #block(
      sticky: true,
      [#text(fill: xcolor.orange)[#counter(heading).display()] #it.body]
    )
  ]

  doc
}

#let backmatter(doc) = {
  set heading(numbering: none)

  show heading.where(level: 1): it => [
    #it.body
  ]

  doc
}

#let template(
  affiliation: none,
  institute: none,
  title: none,
  authors: none,
  start-date: none,
  end-date: none,
  date: datetime.today(),
  examiners: none,
  supervisors: none,
  type: none,
  doc,
) = {
  set document(title: title, author: authors.join(", ", last: " and "), date: date)

  set par(justify: true)

  show raw: set text(
    font: monofont,
    weight: "regular"
  )

  show heading: it => {
    it
    v(1em)
  }

  show link: set text(fill: xcolor.olive-green)
  show cite: set text(fill: luma(25%))

  show outline.entry.where(
    level: 1
  ): it => {
    v(12pt, weak: true)
    strong(it)
  }

  page()[
    #align(center)[
      #text(size: 18pt, weight: "bold", fill: xcolor.maroon)[#affiliation]

      #text(weight: "light", fill: luma(40%))[#institute]

      #v(2em)
      #line(length:100%, stroke: (paint: luma(80%), cap: "round"))
      #v(1em)
      #text(size:14pt)[#type]
      #v(2em)
      #text(size:14pt, weight: "bold", upper(title), fill: xcolor.maroon)
      #v(1em)
      #line(length:100%, stroke: (paint: luma(80%), cap: "round"))
      #v(5em)

      // authors
      #upper(authors.join(", ", last: " and "))

      // date
      #end-date

      #v(14em)

      *Gutachter*

      #smallcaps(examiners.join(", ", last: " and "))

      #v(8em)

      *Betreuer*

      #smallcaps(supervisors.join(", ", last: " and "))
    ]

    #pagebreak()

    #align(bottom)[
      #stack(
        dir:ttb,
        spacing: 0.5em,
        [#text(weight: "bold")[#authors.join(", ", last: " and "):]],
        emph(title),
        [#type],
        [#affiliation],
        if start-date != none and end-date != none [#start-date -- #end-date]
      )
    ]
  ]

  set page(footer:
    context {
      let page-numbering = page.numbering
      let page = counter(page)
      let chapter = query(heading.where(level: 1).before(here())).last().body
      let section = query(heading.where(level: 2).before(here()))
      let vertical-line = line(length: 2em, angle: 90deg, stroke: (paint: xcolor.orange, cap: "round"))
      if calc.odd(page.get().first()) [
        #stack(
          dir:ltr,
          spacing: 0.5em,
          page.display(page-numbering),
          vertical-line,
          chapter
        )
      ] else [
        #align(right)[
          #stack(
            dir:ltr,
            spacing: 0.5em,
            if section.len() > 0 [
              #section.last().body
            ] else [
              #chapter
            ]
            ,
            vertical-line,
            page.display(page-numbering)
          )
        ]
      ]
    }
  )



  doc
}
