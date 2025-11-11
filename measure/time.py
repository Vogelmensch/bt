import time

class Timer:
    time_start = 0
    time_stop = 0

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

        print()
        print('CPU time: {} {}'.format(time_elapsed, unit))