# Measurements

A protocol of inputs for the different algorithms and my observations.

## Great for presentation

### A*

Works out of the box, but no performance difference is observable:
```bash
python astar.py example.db simple 0 6
```

Requires an additional graph, but performance difference is observable:
```python
TODO :)
```

### LCS

```bash
python lcs.py 'Houston, we have a problem' 'Oberpfaffenhofen, wir haben ein Problem'
```

### Bishop

```bash
python bishop.py -s 4 -r 400 
```
