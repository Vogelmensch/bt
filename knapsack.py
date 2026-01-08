import argparse
import subprocess

def perform_query(args):
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

        query = query.format(max_weight=args.max_weight, items=args.graph)

        # Use duckdb's interal time measurement utility
        if args.time:
            cmd = '.timer on'
        else:
            cmd = ''

        res = subprocess.run(['duckdb', args.db, '-cmd', cmd], input=query, text=True, capture_output=True)

        print(res.stdout)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Perform Knapsack query.'
    )
    parser.add_argument('db', type=str, help='path to .db-file holding the graph(s)')
    parser.add_argument('graph', type=str, help='name of the graph to perform the query on')
    parser.add_argument('max_weight', type=int, help='total max weight')

    parser.add_argument('-u', '--using_key', action='store_true', help='USING KEY')
    parser.add_argument('-c','--classic', action='store_true', help='use classic CTE')

    measure = parser.add_mutually_exclusive_group()
    measure.add_argument('-t', '--time', action='store_true', help='measure process time for query execution')
    measure.add_argument('-m', '--memory', action='store_true', help='measure memory allocated during query execution')

    parser.add_argument('-x', '--suppress_solution', action='store_true', help='suppress print of solution')

    args = parser.parse_args()

    perform_query(args)