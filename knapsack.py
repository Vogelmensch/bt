import argparse
import subprocess
from measure.measure import Timer, Memory
import duckdb
import json

def perform_query(args, item_table):
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

        query = query.format(max_weight=args.max_weight, items=item_table)

        # Use duckdb's interal time measurement utility
        if args.time:
            cmd = '.timer on'
        else:
            cmd = ''

        if args.memory:
            memory.start()

        res = subprocess.run(['duckdb', args.db, '-json', '-cmd', cmd], input=query, text=True, capture_output=True)

        if args.memory:
            memory.stop()
        
        if res.stderr != '':
            print('An error occured during query execution:')
            print(res.stderr)
            return

        results = res.stdout.split('\n')
        if args.time:
            json_string = results[1][1:-1]
            timestr = results[2]
        else:
            json_string = results[0][1:-1]

        out = json.loads(json_string)

        max_value = out['max_value']
        items_count = out['items_count']
        table_size = out['table_size']

        if not args.suppress_solution:
            print(f'Max Value: {max_value}')
            print(f'{items_count} items in table')
            print(f'{table_size} items in final table')
        
        if args.time and not args.suppress_solution:
            print(timestr)

        if args.memory and not args.suppress_solution:
            memory.print()

        # data to store to csv
        if args.file != 'DONT STORE':
            data = [script_name, item_table, items_count, max_value, table_size]
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
        description='Perform Knapsack query.'
    )
    parser.add_argument('db', type=str, help='path to .db-file holding the item_table(s)')
    parser.add_argument('item_table', type=str, help='name of the item_table to perform the query on')
    parser.add_argument('max_weight', type=int, help='total max weight')

    parser.add_argument('-g', '--item_tables', type=str, nargs='*', help='additional item_tables to evaluate')
    parser.add_argument('-r', '--random', type=int, nargs='*', help='create random item-table of given size')

    parser.add_argument('-u', '--using_key', action='store_true', help='USING KEY')
    parser.add_argument('-c','--classic', action='store_true', help='use classic CTE')

    measure = parser.add_mutually_exclusive_group()
    measure.add_argument('-t', '--time', action='store_true', help='measure process time for query execution')
    measure.add_argument('-m', '--memory', action='store_true', help='measure memory allocated during query execution')

    parser.add_argument('-x', '--suppress_solution', action='store_true', help='suppress print of solution')
    parser.add_argument('-f', '--file', type=str, nargs='?', const='NOT PROVIDED', default='DONT STORE', help='measure time and store into FILE')

    args = parser.parse_args()

    header = ['script','item_table','items_count','max_value','table_size']

    if args.time:
        timer = Timer('knapsack', args.file, header[:])
    if args.memory:
        memory = Memory('knapsack', args.file, header[:])

    random_tables = []
    if args.random:
        with open('queries/knapsack/random-items.sql') as f:
            query_from_file = f.read()
        with duckdb.connect(args.db) as con:
            for idx, sample_size in enumerate(args.random):
                table_name = f'generated_{idx}'
                random_tables.append(table_name)
                query = query_from_file.format(table_name=table_name, sample_size=sample_size)
                con.sql(query)

    if not args.random:
        item_tables = [args.item_table] + (args.item_tables if args.item_tables else [])
    else:
        item_tables = random_tables

    for i, item_table in enumerate(item_tables):
        if args.suppress_solution:
            print(f'\rPerforming query {i+1}/{len(item_tables)}', end='')
        perform_query(args, item_table)