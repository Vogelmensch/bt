In general, in could be interesting to plot the variance as well, to see how uncertain execution times become.

```
D select length_string1, script, sqrt(var_samp(t_real)) from 'large_measurements/lcs_27_01_2026.csv' group by length_string1, script order by length_string1;
┌────────────────┬───────────────┬────────────────────────┐
│ length_string1 │    script     │ sqrt(var_samp(t_real)) │
│     int64      │    varchar    │         double         │
├────────────────┼───────────────┼────────────────────────┤
│             20 │ using-key.sql │  0.0029533408577782252 │
│             20 │ classic.sql   │   0.004168666186896922 │
│             40 │ classic.sql   │    0.01079145752693099 │
│             40 │ using-key.sql │   0.004022160834399561 │
│             60 │ classic.sql   │   0.019125317717041408 │
│             60 │ using-key.sql │   0.005738757124441962 │
│             80 │ classic.sql   │    0.03786173676828772 │
│             80 │ using-key.sql │    0.01081203033662042 │
│            100 │ using-key.sql │   0.009512564790259739 │
│            100 │ classic.sql   │   0.059093992926523405 │
│            120 │ classic.sql   │     0.8670078879559158 │
│            120 │ using-key.sql │   0.036377801533963604 │
│            140 │ using-key.sql │   0.041274689580904224 │
│            140 │ classic.sql   │      1.308677963102883 │
│            160 │ using-key.sql │    0.04299819117642561 │
│            160 │ classic.sql   │      2.114870776194139 │
│            180 │ classic.sql   │     12.806223695271504 │
│            180 │ using-key.sql │     0.3564940548047204 │
│            200 │ classic.sql   │       20.5657815605059 │
│            200 │ using-key.sql │     1.3517518715438208 │
├────────────────┴───────────────┴────────────────────────┤
│ 20 rows                                       3 columns │
└─────────────────────────────────────────────────────────┘
```
