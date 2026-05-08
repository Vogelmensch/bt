== Findings

TODO: compare all algorithms

== Summary

- Classic recursive CTEs forget previous results.
- `USING KEY` remembers by keeping a keyed dictionary.

If previous results are needed,
- `USING KEY` is easier to implement #emoji.keyboard
- `USING KEY` speeds up query execution #emoji.lightning
- `USING KEY` saves memory #emoji.package

However, if only the immediately preceding results are needed, classic CTEs perform better due to less overhead.