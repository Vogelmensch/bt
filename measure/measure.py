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
            header += ['t_real', 't_user', 't_sys']
        super().__init__(query_name, filepath, header)
        self.time_start = 0
        self.time_stop = 0

    def foreign_measurement(self, time_data):
        self.foreign_time = time_data

    # Add current time to measurement
    def write_csv(self, data):
        if self.foreign_time:
            super().write_csv(data + self.foreign_time)
        else:
            raise Exception('This feature is deprecated. Use DuckDB\'s internal time measurement from now on.')

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
        print()

class Memory(Measurer):
    def __init__(self, query_name, filepath, header=None):
        if header:
            header += ['memory_size', 'memory_peak']
        super().__init__(query_name, filepath, header)
        tracemalloc.start()

    def write_csv(self, data):
        super().write_csv(data + [self.size, self.peak])

    def start(self):
        tracemalloc.reset_peak()

    def stop(self):
        self.size, self.peak = tracemalloc.get_traced_memory()

    def print(self):
        size = self._append_unit(self.size)
        peak = self._append_unit(self.peak)

        print(f'Size: {size}')
        print(f'Peak: {peak}')
        print()

    def _append_unit(self, n):
        units = ['B', 'KB', 'MB', 'GB']
        idx = 0

        while n > 1000:
            idx += 1
            n /= 1000
        
        n = round(n, 2)
        
        return f'{n} {units[idx]}'