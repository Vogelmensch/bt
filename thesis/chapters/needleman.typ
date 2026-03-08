= Needleman-Wunsch

Say you are given two distinct strings of DNA originating from two different species, and you want to find out in which way those two species are related to each other. Maybe they share a common ancestor, or one species originated from the other. Maybe they are far apart on the evolutionary tree, despite sharing similar features. To answer this and similar questions, we want to find out how one DNA string can be transformed into the other, using as few operations as possible. In bioinformatics, this problem is known as the _sequence alignment problem_. In 1969, Saul B. Needleman and Christian D. Wunsch proposed a dynamic programming algorithm to solve this problem, which is now known as the _Needleman-Wunsch algorithm_ @needleman.


== How DNA changes

A DNA sequence is a sequence of nucleotides. A nucleotide is a type of organic molecule of which four distinct flavors exist within DNA. Here, we will simply encode those types with the letters C, G, A and T. 

@changing_dna shows the three operations that can be used to convert one DNA sequence into another. First, a nucleotide within the sequence can change its flavor. We call this substitution. Secondly, a nucleotide can be removed. We call this deletion. Lastly, a new nucleotide can be inserted. 

#figure(
    caption: [Example DNA sequence being changed to a different one by substitution (left), deletion (middle) and insertion (right).],
    grid(
        columns: 3,
        rows: 3,
        gutter: 15pt,
        [`GTA`], [`GTA`], [`GTA`],
        [`↓`], [`↓`], [`↓`],
        [`GTC`], [`GA`], [`GTGA`]
    )
) <changing_dna>

There are infinitely many ways to combine those three operations to turn one given DNA sequence into the other. We are interested in the combination that needs the minimal amount of operations. 
To compare two given sequences, we write them one above the other. Oviously, we cannot change or remove letters from one of the sequences. However, we can insert a special symbol called the "indel", denoted with the sign "`-`". The indel marks the insertion or deletion of a character. @aligning_dna continues the previous example and aligns each sequence pair in this way.

#figure(
    caption: [Aligning the sequences from @changing_dna. The left alignment shows the substitution of `A` to `C`. The middle alignment shows the deletion of `T`, while the right alignment shows the insertion of `G`.],
    grid(
        columns: 3,
        rows: 1,
        gutter: 15pt,
        [```
        GTA 
        GTC
        ```], 
        [```
        GTA
        G-A
        ```], 
        [```
        GT-A
        GTGA
        ```]
    )
) <aligning_dna>


To rate an alignment, we assign scores to each of its pairs of letters, based on a scoring function. There are many different scoring functions; we choose the following: let $(x, y)$ be a pair of letters. Then:

$
  "score"(x, y) = cases(
    +1 &"if" x = y &"match",
    -1 &"if" x != y &"mismatch",
    -1 &"if" x = "\"-\"" "or" y = "\"-\"" &"indel"
  )
$


To illustrate this with another example, let us consider the sequences `s1 = GAGA` and `s2 = AATG`. @alignment_example shows four different way to align `s1` and `s2`, and it shows the application of the scoring function for each of them. The highest score is being reached by the rightmost example, which also turns out to be the overall best alignment, i.e., the one resulting in the highest score.

#figure(
    caption: [Four different ways of aligning the sequences `GAGA` and `AATG`, and their respective scores. For each pair of letters, `+` denotes a score of $+1$ and `-` denotes a score of $-1$.],
    grid(
        columns: 4,
        gutter: 15pt,
        [```
        GAGA
        AATG
        -+-- = -2
        ```],
        [```
        GAGA-
        -AATG
        -+--- = -3
        ```],
        [```
        GA-GA
        -AATG
        -+--- = -3
        ```],
        [```
        GA-GA
        AATG-
        -+-+- = -1
        ```],
    )
) <alignment_example>

== Finding the best alignment

#bibliography("../references.bib")