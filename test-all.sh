#!/bin/bash
echo Testing A\*...
python tests/astar.py
python tests/astar.py -c
echo
echo Testing Bishop...
python tests/bishop.py
python tests/bishop.py -c
echo
echo Testing LCS...
python tests/lcs.py
python tests/lcs.py -c
