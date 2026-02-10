import subprocess
import subprocess 
import argparse
from measure.measure import Timer, Memory
from general_query import GeneralQuery as master

# supply args from argparse
def perform_query(args):
    if args.use_heuristic:
        with open('queries/astar/create_heuristic_graph.sql') as f:
            heuristic_query = f.read()
        graph = 'h_' + args.graph
        heuristic_query.format(goal_node=args.goal, graph=graph)
    else:
        heuristic_query = ''
        graph = args.graph
    
    scripts = []

    if args.using_key:
        scripts.append('queries/astar/using-key.sql')
    if args.classic:
        scripts.append('queries/astar/classic.sql')

    if len(scripts) == 0:
        scripts.append('queries/astar/using-key.sql')

    for script in scripts:
        script_name = script.split('/')[-1]
        if not args.suppress_solution:
            print(script_name) # Print script name
            print('-' * len(script_name))

        with open(script) as f:
            query = f.read()

        query = heuristic_query + query

        # Add arguments with formatted python string
        query = query.format(graph=graph, start_node=args.start, goal_node=args.goal)

        # Use duckdb's interal time measurement utility
        if args.time:
            cmd = '.timer on'
        else:
            cmd = ''

        if args.memory:
            memory.start()

        res = master.run_subprocess(cmd, query, args)

        if args.memory:
            memory.stop()

        if res == 'timeout':
            constant_data = [script_name, args.graph, args.start, args.goal]
            if args.time:
                master.store_timeout(args, constant_data, timer)
            if args.memory:
                master.store_timeout(args, constant_data, memory)
            continue
        
        if not res:
            continue
    
        out = res.stdout.replace('\n', '|').split('|')

        if (len(res.stdout) > 0):
            if args.time:
                idx = 7
            else:
                idx = 4
            path = out[idx]
            total_weight = out[idx+1]
            expanded_count = out[idx+2]
            table_size = out[idx+3] 
            timestr = out[idx+4] if args.time else None
        else:
            path, total_weight, timestr = None, None, None

        nodes_count = len(path.split('->'))
            
        if not args.suppress_solution:
            if (len(res.stdout) == 0):
                print('Nothing found.')
            else:
                print(f'Path: {path} ({nodes_count} node{'' if nodes_count == 1 else 's'})')
                print(f'Total Weight: {total_weight}')
                print(f'{expanded_count} nodes expanded')
                print(f'{table_size} items in final table')

        if args.time and not args.suppress_solution:
            print(timestr)

        if args.memory and not args.suppress_solution:
            memory.print()

        # data to store to csv
        if args.file != 'DONT STORE':
            data = [script_name, args.graph, args.start, args.goal, path, nodes_count, total_weight, expanded_count, table_size]
            if args.time:
                timelist = timestr.split()
                timer.foreign_measurement(timelist[4:9:2]) # get time data out of timelist
                timer.write_csv(data)
            if args.memory:
                memory.write_csv(data)

        if not args.suppress_solution:
            print()
            print()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Perform A* query.', 
        epilog='''
        The graph needs to have the following schema: node_from: INT | node_to: INT | weight: INT

        To perform multiple queries and store them all into one csv-file, provide -e / --extend. 
        The provided strings extend the graph name.
        ''')

    parser.add_argument('db', type=str, help='path to .db-file holding the graph(s)')
    parser.add_argument('graph', type=str, help='name of the graph to perform the query on')
    parser.add_argument('start', type=int, help='id of the start node')
    parser.add_argument('goal', type=int, help='id of the goal node')

    master.add_standard_args(parser)

    parser.add_argument('--use_heuristic', action='store_true', help='use heuristic for coordinate-based queries')

    parser.add_argument('-e', '--extend', type=str, action='extend', nargs='*', help='extend graph name with provided strings and perform MULTIPLE queries')
    parser.add_argument('-g', '--goals', type=int, nargs='+', help='Override provided goal with a list goals to perform MULTIPLE queries')

    args = parser.parse_args()

    master.check_combos(args)

    # expanded_count does count every single node only once. That means, if a node gets visited again, it does not count again.
    # table_size counts the number of total visits. That means, if a node gets visited again, it counts again.
    # for measuring performance, total_visiting_count seems to be the better metric.
    header = ['script','graph','start_node','goal_node','path','nodes_count','total_weight','expanded_count','table_size']

    if args.time:
        timer = Timer('astar', args.file, header[:])
    if args.memory:
        memory = Memory('astar', args.file, header[:])

    if args.goals:
        goals = args.goals
    else:
        goals = [args.goal]

    if args.extend:
        extensions = args.extend
    else:
        extensions = ['']

    if args.repeat:
        repeats = args.repeat
    else:
        repeats = 1

    # Number of total repeats to show progress 
    total_repeats = repeats * len(goals) * len(extensions)
    current_repeat = 1

    for _ in range(repeats):
        # loop over graphs
        graph = args.graph
        for extension in extensions:
            args.graph = graph + extension
            # loop over goals
            for goal in goals:
                args.goal = goal
                if args.suppress_solution:
                    print(f'\rPerforming query {current_repeat}/{total_repeats}', end='')
                current_repeat += 1
                perform_query(args)
