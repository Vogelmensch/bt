import argparse
import subprocess as sp
import os
from signal import SIGTERM
import json
from measure.measure import Measurer, Timer
from sys import exit

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

        GeneralQuery.check_duckdb_version()

    def check_duckdb_version():
        cproc = sp.run(['duckdb', '--version'], capture_output=True, text=True)
        out, err = cproc.stdout, cproc.stderr

        if err:
            print('Checking duckdb version returned error:')
            print(err)
            exit(1)
        
        if 'v1.4.4' not in out:
            print(f'DuckDB v1.4.4 required. Found {out}')
            print('The program might not work correctly with this version.')
            answer = input('Continue anyway? y/[n]')
            if answer != 'y':
                print('exiting...')
                exit(1)



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

        # manually create process in order to cleanly kill it later
        proc = sp.Popen(['/usr/bin/time', '-f', '%M', 'duckdb', db, result_format, '-cmd', 'INSTALL spatial;', '-cmd', 'LOAD spatial;', '-cmd', cmd], text=True, stdin=sp.PIPE, stdout=sp.PIPE, stderr=sp.PIPE, start_new_session=True)
        try:
            stdout, stderr = proc.communicate(input=query, timeout=timeout)
        except sp.TimeoutExpired:
            if not args.suppress_solution:
                print('query timed out.')
            # The timeout killed /usr/bin/time, but not duckdb, as the latter is a child process of the former
            # => kill it manually
            os.killpg(os.getpgid(proc.pid), SIGTERM)
            proc.wait()
            return 'timeout'

        if proc.returncode != 0:
            print('An error occured during query execution:')
            print(stderr)
            return

        return {'stdout': stdout, 'stderr': stderr}


    # get dictionary of the query's output values
    # also get timestr
    def get_out_dict(args, res):
        results = res['stdout'].split('\n')
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

    def print_memory(gnu_data):
        mem_max = int(gnu_data[-1])

        print(f'Max RSS: {GeneralQuery._format_memory(mem_max)}')

    def _format_memory(n):
        units = ['KB', 'MB', 'GB']
        idx = 0

        while n > 1024:
            idx += 1
            n /= 1024
        
        n = round(n, 2)
        
        return f'{n} {units[idx]}'