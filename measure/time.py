import time
import duckdb

class Timer:
    time_start = 0
    time_stop = 0
    # Connection to database
    con = None
    table_name = None

    # store current state in .db-file
    def store_time(self, script_name, first_arg):
        if not self.con or not self.table_name:
            raise Error('Data storage failed. Did you create the storage file?')
        
        time_elapsed = self.time_stop - self.time_start
        time_elapsed *= 1000

        self.con.sql(
            f'INSERT INTO {self.table_name} VALUES (\'{script_name}\', {first_arg}, {int(time_elapsed)})'
        )

    # prepare storage of results in .db-file
    def connect(self, db_name, first_arg='first_arg', first_arg_type='INTEGER', table_name=None):
        # connect if not connected yet
        if not self.con:
            self.con = duckdb.connect(db_name)

        # create table
        if not table_name:
            now = time.localtime()
            table_name = f'measurement_{time.strftime('%m%d_%H%M%S', now)}'
            self.table_name = table_name
        self.con.sql(
            f'CREATE TABLE {table_name} (script_name TEXT, {first_arg} {first_arg_type}, time INTEGER)'
        )

    def close_connection(self):
        if self.con:
            self.con.close()
        else:
            print('Failed to close connection to database: No database connected.')

    def start(self):
        self.time_start = time.process_time()

    def stop(self):
        self.time_stop = time.process_time()

    def print_elapsed(self):
        time_elapsed = self.time_stop - self.time_start
        
        # convert to convenient unit
        if time_elapsed < 1:
            time_elapsed *= 1000
            unit = 'ms'
        else:
            unit = 's'

        print('CPU time: {0:.2f} {1}'.format(time_elapsed, unit))