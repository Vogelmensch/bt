import numpy as np
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
            'knapsack': 'items_count',
            'bishop': 'fingerprint_length'
        }
        self.default_query = '''
            SELECT 
                {x_value} AS x,
                {y_value} AS y
            FROM \'{file}\'
            WHERE script=\'{script}\' 
            '''
        self.errorbar_query = '''
            SELECT 
                {x_value} AS x,
                mean({y_value}) AS y,
                sqrt(var_pop({y_value})) AS dy
            FROM \'{file}\'
            WHERE script=\'{script}\' 
            GROUP BY {x_value}
        '''
        plt.figure()

    def show(self):
        plt.show()

    def store(self, name):
        plt.savefig(name)

    def default(self, algorithm, x_value, y_value, file, scripts, xlabel=None, ylabel=None, errorbars=False, logy=False):
        if not args.x_value:
            x_value = self.default_x_values[algorithm]

        query = self.default_query if not errorbars else self.errorbar_query

        for script in scripts:
            d = duckdb.sql(query.format(x_value=x_value, y_value=y_value, file=file, script=script)).fetchnumpy()

            if errorbars:
                plt.errorbar(d['x'], d['y'], yerr=d['dy'], fmt='o', label=script)
            else:
                plt.plot(d['x'], d['y'], '.', label=script)

        if logy:
            plt.yscale('log')
        plt.xlabel(xlabel if xlabel else x_value)
        plt.ylabel(ylabel if ylabel else y_value)
        plt.grid()
        plt.legend()

    def edge_weights(self):
        w = np.loadtxt('all_weights.csv', skiprows=1)
        plt.hist(w, bins=500)
        plt.xlabel('edge weight [m]')
        plt.ylabel('number of edges')
        plt.title('Distribution of edge weights in New York')

    def map(self, coords_file, path_file='path.txt'):
        coords = np.loadtxt(coords_file, skiprows=1, delimiter=',')
        lat = coords[:,0]
        long = coords[:,1]
        plt.plot(long, lat, '.')

        if path_file:
            path_coords = np.loadtxt(path_file, skiprows=1, delimiter=' -> ')
            lat = path_coords[:,0]
            long = path_coords[:,1]
            plt.plot(long, lat, '.')

    

if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    parser.add_argument('query', type=str)
    parser.add_argument('y_value', type=str)
    parser.add_argument('file', type=str)

    parser.add_argument('--script', '--scripts', type=str, nargs='*', default=['using-key.sql', 'classic.sql'], help='scripts to consider')

    parser.add_argument('-x', '--x_value', type=str)

    parser.add_argument('--xlabel', type=str)
    parser.add_argument('--ylabel', type=str)

    parser.add_argument('--err', '--errorbars', action='store_true', help='plot with errorbars')
    parser.add_argument('--logy', action='store_true')

    parser.add_argument('-s', '--store', '--save', '--write', type=str, nargs='?', const='NOT PROVIDED', default='DONT STORE', help='store into file STORE')

    parser.add_argument('--edge', action='store_true')
    parser.add_argument('--map', type=str, help='coords-file')

    args = parser.parse_args()

    plot = Plot()

    if args.edge:
        plot.edge_weights()
    elif args.map:
        plot.map(args.map)
    else:
        plot.default(args.query, args.x_value, args.y_value, args.file, args.script, args.xlabel, args.ylabel, args.err, args.logy)

    if args.store == 'DONT STORE':
        plot.show()
    else:
        if args.store == 'NOT PROVIDED':
            measurement_filename = args.file.split('/')[-1].split('.')[0]
            filename = f'measure/plots/{measurement_filename}.svg'
        else:
            filename = args.store
        plot.store(filename)