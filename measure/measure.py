import csv
import time
import tracemalloc

class Measurer:
    def _generate_filename(self):
        now = time.localtime()
        return f'measure/{self.query_name}_{time.strftime('%m%d_%H%M%S', now)}.csv'

    # The header is only dependent on the query; supclasses of Measurer should automatically append their respective parameters
    # `header` appears to be a global variable of some sort??
    def __init__(self, query_name, filepath, header=None):
        self.query_name = query_name
        self.header = header
        
        if filepath == 'NOT PROVIDED':
            self.filepath = self._generate_filename()
        else:
            self.filepath = filepath

        if header and filepath != 'DONT STORE':
            with open(self.filepath, 'w', newline='') as csvfile:
                writer = csv.writer(csvfile, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
                writer.writerow(header)

    # Write data formatted as list. Append list to add data in child classes.
    def write_csv(self, data):
        if self.filepath == 'DONT STORE':
            return

        with open(self.filepath, 'a', newline='') as csvfile:
            writer = csv.writer(csvfile, delimiter=',', quotechar='"')
            writer.writerow(data)


class Timer(Measurer):
    def __init__(self, query_name, filepath, header=None):
        if header:
            header += ['t_real', 't_user', 't_sys', 'gnu_t_real', 'gnu_t_user', 'gnu_t_sys', 'gnu_rss_max', 'gnu_rss_avg']
        super().__init__(query_name, filepath, header)
        self.time_start = 0
        self.time_stop = 0

    def add_duckdb_time(self, timestr):
        timelist = timestr.split()

    def start(self):
        self.time_start = time.process_time()

    def stop(self):
        self.time_stop = time.process_time()

    # Store data that exists even without completed measurement
    def store_timeout(self, args, constant_data):
        if args.file == 'DONT STORE':
            return
        n_dynamic_data = len(self.header) - len(constant_data)
        data = constant_data + n_dynamic_data * [None]
        self.write_csv(data)

    def print_elapsed(self):
        time_elapsed = self.time_stop - self.time_start
        
        # convert to convenient unit
        if time_elapsed < 1:
            time_elapsed *= 1000
            unit = 'ms'
        else:
            unit = 's'

        print('CPU time: {0:.2f} {1}'.format(time_elapsed, unit))
        print()

    