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
            'knapsack': 'items_count'
        }
        plt.figure()

    def show(self):
        plt.show()

    def store(self, name):
        plt.savefig(name)

    def default(self, algorithm, x_value, y_value, file, xlabel=None, ylabel=None):
        # if algorithm == 'lcs':
        #     return self.lcs(x_value, y_value, file, xlabel, ylabel)

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


        # diff_query = '''
        #     SELECT 
        #         u.{x_value} AS x,
        #         c.{y_value} - u.{y_value} AS diff
        #     FROM \'{file}\' AS u JOIN
        #          \'{file}\' AS c ON u.{x_value} = c.{x_value}
        #     WHERE u.script = \'using-key.sql\' AND
        #           c.script = \'classic.sql\'
        #     GROUP BY u.{x_value}
        # '''
        # q = diff_query.format(x_value=x_value, y_value=y_value, file=file)
        # print(q)
        # d = duckdb.sql(q).fetchnumpy()

        plt.plot(u['x'], u['y'], '.', label='USING KEY')
        plt.plot(c['x'], c['y'], '.', label='Classic')
        # plt.plot(d['x'], d['diff'], label='Difference')
        plt.xlabel(xlabel if xlabel else x_value)
        plt.ylabel(ylabel if ylabel else y_value)
        plt.grid()
        plt.legend()

    def lcs(self, x_value, y_value, file, xlabel=None, ylabel=None):
        if not args.x_value:
            x_value = self.default_x_values['lcs']

        query = '''
            SELECT 
                {x_value} AS x,
                mean({y_value}) AS y,
                sqrt(var_pop({y_value})) AS dy
            FROM \'{file}\'
            WHERE script=\'{script}\' 
            GROUP BY {x_value}
        '''

        u = duckdb.sql(query.format(x_value=x_value, y_value=y_value, file=file, script='using-key.sql')).fetchnumpy()
        c = duckdb.sql(query.format(x_value=x_value, y_value=y_value, file=file, script='classic.sql')).fetchnumpy()

        plt.errorbar(u['x'], u['y'], yerr=u['dy'], fmt='o', label='USING KEY')
        plt.errorbar(c['x'], c['y'], yerr=c['dy'], fmt='o', label='Classic')
        plt.xlabel(xlabel if xlabel else x_value)
        plt.ylabel(ylabel if ylabel else y_value)
        plt.grid()
        plt.legend(loc='upper left')

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

    parser.add_argument('-x', '--x_value', type=str)

    parser.add_argument('--xlabel', type=str)
    parser.add_argument('--ylabel', type=str)

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
        plot.default(args.query, args.x_value, args.y_value, args.file, args.xlabel, args.ylabel)

    if args.store == 'DONT STORE':
        plot.show()
    else:
        if args.store == 'NOT PROVIDED':
            measurement_filename = args.file.split('/')[-1].split('.')[0]
            filename = f'measure/plots/{measurement_filename}.svg'
        else:
            filename = args.store
        plot.store(filename)