import argparse
import subprocess
from measure.measure import Timer, Memory
import duckdb
import json

# query_name: name as found in filesystem
# the following paramters encode the names of the columns in the csv-file
# constants: list of constants
# metrics: list of the querie's return-values
class QueryTester():
    def __init__(self, query_name, description, constants, metrics):
        self.query_name = query_name
        self.constants = constants
        self.metrics = metrics

        # initiate parser
        parser = argparse.ArgumentParser(description=description)
        
        # define CLI-arguments
        self._define_standard_arguments(parser)
        self.args = self.define_specific_arguments(parser)

        # make preparations
        self._prepare()

    def run(self):
        for script_name in self.queries:
            if self.args.suppress_solution:
                print(f'\rPerforming query {i+1}/{len(item_tables)}', end='') # print progress
            else:
                print(script_name) 
                print('-' * len(script_name))
            query = self.queries[script_name]
            self._perform_query(query)
    
    def define_specific_arguments(self, parser):
        # return args
        raise NotImplementedError('Override this method!')

    def format_query(self, query):
        # return formatted query
        raise NotImplementedError('Override this method!')

    def _define_standard_arguments(self, parser):
        parser.add_argument('-u', '--using_key', action='store_true', help='USING KEY')
        parser.add_argument('-c','--classic', action='store_true', help='use classic CTE')

        measure = parser.add_mutually_exclusive_group()
        measure.add_argument('-t', '--time', action='store_true', help='measure process time for query execution')
        measure.add_argument('-m', '--memory', action='store_true', help='measure memory allocated during query execution')

        parser.add_argument('-x', '--suppress_solution', action='store_true', help='suppress print of solution')
        parser.add_argument('-f', '--file', type=str, nargs='?', const='NOT PROVIDED', default='DONT STORE', help='measure time and store into FILE')

    def _prepare(self):
        scripts = []
        self.queries = {}

        if self.args.using_key:
            scripts.append(f'queries/{self.query_name}/using-key.sql')
        if self.args.classic:
            scripts.append(f'queries/{self.query_name}/classic.sql')

        if len(scripts) == 0:
            scripts.append(f'queries/{self.query_name}/using-key.sql')

        for script in scripts:
            script_name = script.split('/')[-1]

            with open(script) as f:
                query = f.read()

            query = self.format_query(query)
            self.queries[script_name] = query 

        header = self.constants + self.metrics

        if self.args.time:
            timer = Timer(self.query_name, self.args.file, header[:])
        if self.args.memory:
            memory = Memory(self.query_name, self.args.file, header[:])
    
    def _perform_query(self, query):
        # Use duckdb's interal time measurement utility
        if self.args.time:
            cmd = '.timer on'
        else:
            cmd = ''

        if self.args.memory:
            memory.start()

        res = subprocess.run(['duckdb', self.args.db, '-json', '-cmd', cmd], input=query, text=True, capture_output=True)

        if self.args.memory:
            memory.stop()
        
        if res.stderr != '':
            print('An error occured during query execution:')
            print(res.stderr)
            return

        results = res.stdout.split('\n')
        print(results)
        return

        if self.args.time:
            json_string = results[1][1:-1]
            timestr = results[2]
        else:
            json_string = results[0][1:-1]

        out = json.loads(json_string)

        if not self.args.suppress_solution:
            for metric in metrics:
                print(f'{metric}: {out[metric]}')
        
        if self.args.time and not self.args.suppress_solution:
            print(timestr)

        if self.args.memory and not self.args.suppress_solution:
            memory.print()

        # data to store to csv
        if self.args.file != 'DONT STORE':
            data = constants
            for metric in metrics:
                data.append(out[metric])
            if self.args.time:
                timelist = timestr.split()
                timer.foreign_measurement(timelist[4:9:2]) # get time data out of timelist
                timer.write_csv(data)
            if self.args.memory:
                memory.write_csv(data)

        if not self.args.suppress_solution:
            print()
            print()
