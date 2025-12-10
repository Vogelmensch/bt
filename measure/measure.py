import csv
import time

class Timer:
    def _generate_filename(self):
        now = time.localtime()
        return f'measure/{self.query_name}_{time.strftime('%m%d_%H%M%S', now)}.csv'

    def __init__(self, query_name, filepath, header=None):
        self.query_name = query_name
        
        if filepath == 'NOT PROVIDED':
            self.filepath = self._generate_filename()
        else:
            self.filepath = filepath

        if header:
            with open(self.filepath, 'w', newline='') as csvfile:
                writer = csv.writer(csvfile, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
                writer.writerow(header)

        self.time_start = 0
        self.time_stop = 0

    # Write data formatted as list and the current time
    def write_csv(self, data):
        time_elapsed = self.time_stop - self.time_start

        with open(self.filepath, 'a', newline='') as csvfile:
            writer = csv.writer(csvfile, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
            writer.writerow(data + [time_elapsed])

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