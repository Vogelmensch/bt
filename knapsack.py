import argparse
import subprocess
from measure.measure import Timer, Memory

def perform_query(args, graph):
    scripts = []

    if args.using_key:
        scripts.append('queries/knapsack/using-key.sql')
    if args.classic:
        scripts.append('queries/knapsack/classic.sql')

    if len(scripts) == 0:
        scripts.append('queries/knapsack/using-key.sql')

    for script in scripts:
        script_name = script.split('/')[-1]
        if not args.suppress_solution:
            print(script_name) # Print script name
            print('-' * len(script_name))

        with open(script) as f:
            query = f.read()

        query = query.format(max_weight=args.max_weight, items=graph)

        # Use duckdb's interal time measurement utility
        if args.time:
            cmd = '.timer on'
        else:
            cmd = ''

        if args.memory:
            memory.start()

        res = subprocess.run(['duckdb', args.db, '-list', '-cmd', cmd], input=query, text=True, capture_output=True)
        
        if args.memory:
            memory.stop()
        
        if res.stderr != '':
            print('An error occured during query execution:')
            print(res.stderr)
            return

        out = res.stdout.replace('\n', '|').split('|')

        if args.time:
            max_value = out[2]
            timestr = out[3]
        else:
            max_value = out[1]
    
        if not args.suppress_solution:
            print(f'Max Value: {max_value}')
        
        if args.time and not args.suppress_solution:
            print(timestr)

        if args.memory and not args.suppress_solution:
            memory.print()

        # data to store to csv
        if args.file != 'DONT STORE':
            data = [script_name, args.graph, max_value]
            if args.time:
                timelist = timestr.split()
                timer.foreign_measurement(timelist[4:9:2]) # get time data out of timelist
                timer.write_csv(data)
            if args.memory:
                memory.write_csv(data)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Perform Knapsack query.'
    )
    parser.add_argument('db', type=str, help='path to .db-file holding the graph(s)')
    parser.add_argument('graph', type=str, help='name of the graph to perform the query on')
    parser.add_argument('max_weight', type=int, help='total max weight')

    parser.add_argument('-g', '--graphs', type=str, nargs='*', help='additional graphs to evaluate')

    parser.add_argument('-u', '--using_key', action='store_true', help='USING KEY')
    parser.add_argument('-c','--classic', action='store_true', help='use classic CTE')

    measure = parser.add_mutually_exclusive_group()
    measure.add_argument('-t', '--time', action='store_true', help='measure process time for query execution')
    measure.add_argument('-m', '--memory', action='store_true', help='measure memory allocated during query execution')

    parser.add_argument('-x', '--suppress_solution', action='store_true', help='suppress print of solution')
    parser.add_argument('-f', '--file', type=str, nargs='?', const='NOT PROVIDED', default='DONT STORE', help='measure time and store into FILE')

    args = parser.parse_args()

    header = ['script','graph','max_value']

    if args.time:
        timer = Timer('knapsack', args.file, header[:])
    if args.memory:
        memory = Memory('knapsack', args.file, header[:])

    graphs = [args.graph] + (args.graphs if args.graphs else [])

    for i, graph in enumerate(graphs):
        if args.suppress_solution:
            print(f'\rPerforming query {i+1}/{len(graphs)}', end='')
        perform_query(args, graph)