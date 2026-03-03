import argparse
import subprocess
from measure.measure import Timer
import duckdb
import json
from general_query import GeneralQuery as master

def perform_query(args, item_table):
    scripts = master.scripts(args, 'knapsack')

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

        res = master.run_subprocess(cmd, query, args)

        if res == 'timeout':
            constant_data = [script_name, item_table, args.max_weight]
            timer.store_timeout(args, constant_data)
            continue

        if not res:
            continue
        
        # out: dictionary holding result values
        # timestr: string showing execution times measured by DuckDB
        out, timestr = master.get_out_dict(args, res)

        # get wanted values out of 'out'
        max_value = out['max_value']
        items_count = out['items_count']
        table_size = out['table_size']

        gnu_data = res['stderr'].strip().split(',')

        if not args.suppress_solution:
            print(f'Max Value: {max_value}')
            print(f'{items_count} items in table')
            print(f'{table_size} items in final table')
        
        if args.time and not args.suppress_solution:
            print(timestr)

        if args.memory and not args.suppress_solution:
            master.print_memory(gnu_data)

        # data to store to csv
        if args.file != 'DONT STORE':
            data = [script_name, item_table, args.max_weight, items_count, max_value, table_size]
            if args.time:
                timelist = timestr.split()
                data += timelist[4:9:2]
            if args.memory:
                data += gnu_data
            timer.write_csv(data)

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

    master.add_standard_args(parser)

    parser.add_argument('-g', '--item_tables', type=str, nargs='*', help='additional item_tables to evaluate')
    parser.add_argument('-r', '--random', type=int, nargs='*', help='create random item-table of given size')

    args = parser.parse_args()

    master.check_combos(args)

    header = ['script','item_table','max_weight','items_count','max_value','table_size']

    timer = Timer('knapsack', args.file, header[:])

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