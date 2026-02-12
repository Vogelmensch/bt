import matplotlib.pyplot as plt
import duckdb
import argparse

class Plot:
    # start new figure
    def __init__(self):
        self.default_x_values = {
            'astar': 'expanded_count',
            'lcs': 'length_string1',
            'needleman': 'length_string1',
            'knapsack': 'items_count'
        }
        plt.figure()

    def show(self):
        plt.show()

    def store(self, name):
        plt.savefig(name)

    def default(self, algorithm, x_value, y_value, file):
        if not args.x_value:
            x_value = self.default_x_values[algorithm]

        query = '''
            SELECT 
                {x_value} AS x,
                {y_value} AS y
            FROM \'{file}\'
            WHERE script=\'{script}\' 
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

    plot = Plot()

    plot.default(args.query, args.x_value, args.y_value, args.file)

    if args.store == 'DONT STORE':
        plot.show()
    else:
        if args.store == 'NOT PROVIDED':
            measurement_filename = args.file.split('/')[-1].split('.')[0]
            filename = f'measure/plots/{measurement_filename}.svg'
        else:
            filename = args.store
        plot.store(filename)