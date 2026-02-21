import argparse
import subprocess as sp
import json
from measure.measure import Measurer, Timer, Memory

# Code that every query-evaluating python-file needs!
class GeneralQuery:
    # CLI-arguments every query implements
    def add_standard_args(parser: argparse.ArgumentParser):
        parser.add_argument('-u', '--using_key', action='store_true', help='USING KEY')
        parser.add_argument('-c','--classic', action='store_true', help='use classic CTE')
        parser.add_argument('-t', '--time', action='store_true', help='measure process time for query execution')
        parser.add_argument('-m', '--memory', action='store_true', help='measure memory allocated during query execution')
        parser.add_argument('-x', '--suppress_solution', action='store_true', help='suppress print of solution')
        parser.add_argument('-f', '--file', type=str, nargs='?', const='NOT PROVIDED', default='DONT STORE', help='store measured data into FILE')
        parser.add_argument('--repeat', '--repeats', type=int, help='repeat the entire query')
        parser.add_argument('--timeout', type=int, help='timeout for each query in seconds')
        parser.add_argument('--script', '--scripts', type=str, nargs='*', help='manually provide script to read from')

    # Check weird combinations of provided arguments
    def check_combos(args: argparse.Namespace):
        if args.time and args.memory:
            print('CAUTION: When measuring time and memory simultaneously, the measurements could influence each other.')

        if args.file != 'DONT STORE' and not args.time and not args.memory:
            print('CAUTION: You provided a file with --file but no measurement with --time or --memory.')

    def run_subprocess(cmd: str, query: str, args: argparse.Namespace, result_format='-json') -> sp.CompletedProcess:
        # some queries don't need those, so we need to check for their existence
        try:
            db = args.db
        except AttributeError:
            db = ''
        try:
            timeout = args.timeout
        except AttributeError:
            timeout = None

        try:
            res = sp.run(['duckdb', db, result_format, '-cmd', 'INSTALL spatial;', '-cmd', 'LOAD spatial;', '-cmd', cmd], input=query, text=True, capture_output=True, timeout=timeout)
        except sp.TimeoutExpired:
            if not args.suppress_solution:
                print('query timed out.\n')
            
            return 'timeout'
        
        if res.stderr != '':
            print('An error occured during query execution:')
            print(res.stderr)
            return

        return res

    # Store data that exists even without completed measurement
    # Store timeout-time in seconds for t_real and NULL for the rest
    def store_timeout(args, constant_data, measurer: Measurer):
        if args.file == 'DONT STORE':
            return
        n_dynamic_data = len(measurer.header) - len(constant_data)
        if args.time:
            data = constant_data + (n_dynamic_data-3) * [None]
            timelist = [args.timeout] + 2 * [None]
            measurer.foreign_measurement(timelist)
            measurer.write_csv(data)
        if args.memory:
            data = constant_data + (n_dynamic_data-2) * [None]
            measurer.write_csv(data)

    # get dictionary of the query's output values
    # also get timestr
    def get_out_dict(args, res):
        results = res.stdout.split('\n')
        if args.time:
            # timestr is always the second-to-last item (last item is always empty),
            # and json_string is always the item before that
            json_string = results[-3][1:-1]
            timestr = results[-2]
        else:
            # here, json_string is second-to-last item 
            json_string = results[-2][1:-1]
            timestr = ''

        out = json.loads(json_string)

        return out, timestr

    def scripts(args, query_name):
        scripts = []

        if args.using_key:
            scripts.append(f'queries/{query_name}/using-key.sql')
        if args.classic:
            scripts.append(f'queries/{query_name}/classic.sql')
        if args.script:
            scripts += args.script

        if len(scripts) == 0:
            scripts.append(f'queries/{query_name}/using-key.sql')

        return scripts