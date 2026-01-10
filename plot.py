import numpy as np
import matplotlib.pyplot as plt
import duckdb
import argparse

class Plot:
    # start new figure
    def __init__(self):
        plt.figure()

    def show(self):
        plt.show()

    def store(self, name):
        plt.savefig(name)

    def astar(self, y_value, file, x_value):
        if not x_value:
            x_vale = 'expanded_count'
        self.default(x_value, y_value, file)

    def lcs(self, y_value, file, x_value):
        if not x_value:
            x_value = 'length_string1'
        self.default(x_value, y_value, file)

    def needleman(self, y_value, file, x_value='length_string1'):
        self.default(x_value, y_value, file)

    def knapsack(self, y_value, file, x_value='max_value'):
        self.default(x_value, y_value, file)

    def default(self, x_value, y_value, file):
        query = '''
            SELECT 
                {x_value} AS x,
                mean({y_value}) AS y, 
                var_samp({y_value}) AS dy
            FROM \'{file}\'
            WHERE script=\'{script}\' 
            GROUP BY {x_value}
        '''
        u = duckdb.sql(query.format(x_value=x_value, y_value=y_value, file=file, script='using-key.sql')).fetchnumpy()
        c = duckdb.sql(query.format(x_value=x_value, y_value=y_value, file=file, script='classic.sql')).fetchnumpy()

        plt.plot(u['x'], u['y'], '.', label='USING KEY')
        plt.plot(c['x'], c['y'], '.', label='Classic')
        plt.plot()
        plt.xlabel(x_value)
        plt.ylabel(y_value)
        plt.grid()
        plt.legend()

    

if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    parser.add_argument('query', type=str)
    parser.add_argument('y_value', type=str)
    parser.add_argument('file', type=str)

    parser.add_argument('-x', '--x_value', type=str)

    parser.add_argument('-s', '--store', '--save', '--write', type=str, nargs='?', const='NOT PROVIDED', default='DONT STORE', help='store into file STORE')

    args = parser.parse_args()

    # possible_y_values = ['t_real','t_user','t_sys','memory_size','memory_peak']
    # if args.y_value not in possible_y_values:
    #     parser.exit(1, f'Unknown y-value. Possible values are: {possible_y_values}')

    plot = Plot()

    match args.query:
        case 'astar':
            plot.astar(args.y_value, args.file, x_value=args.x_value)
        case 'lcs':
            plot.lcs(args.y_value, args.file, x_value=args.x_value)
        case 'needleman' | 'needle':
            plot.needleman(args.y_value, args.file)
        case 'knapsack':
            plot.knapsack(args.y_value, args.file)
        case _:
            parser.exit(1, 'Unknown query')

    if args.store == 'DONT STORE':
        plot.show()
    else:
        if args.store == 'NOT PROVIDED':
            measurement_filename = args.file.split('/')[-1].split('.')[0]
            filename = f'measure/plots/{measurement_filename}.svg'
        else:
            filename = args.store
        plot.store(filename)