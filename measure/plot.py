import numpy as np
import matplotlib.pyplot as plt
import duckdb
import argparse

class Plot:
    # start new figure
    def __init__(self):
        plt.figure()

    def show(self):
        plt.grid()
        plt.legend()
        plt.show()

    def astar(self, file):
        self.default('length', file)

    def lcs(self, file):
        self.default('length_string1', file)

    def default(self, x_value, file):
        query = '''
            SELECT 
                {x_value} AS l,
                mean(time) AS t, 
                var_samp(time) AS dt
            FROM \'{file}\'
            WHERE script=\'{script}\' 
            GROUP BY {x_value}
        '''
        u = duckdb.sql(query.format(x_value=x_value, file=file, script='using-key.sql')).fetchnumpy()
        c = duckdb.sql(query.format(x_value=x_value, file=file, script='classic.sql')).fetchnumpy()

        plt.plot(u['l'], u['t'], 'o', label='USING KEY')
        plt.plot(c['l'], c['t'], 'o', label='Classic')
        plt.xlabel(x_value)
        plt.ylabel('time')

    

if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    parser.add_argument('query', type=str)
    parser.add_argument('file', type=str)

    args = parser.parse_args()


    plot = Plot()

    match args.query:
        case 'astar':
            plot.astar(args.file)
        case 'lcs':
            plot.lcs(args.file)
        case _:
            parser.exit(1, 'Unknown query')

    plot.show()