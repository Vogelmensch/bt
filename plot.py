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
        self.map_query = '''
            SELECT 
                f.long AS from_long, f.lat AS from_lat,
                t.long AS to_long, t.lat AS to_lat
            FROM 
                h_dists AS d JOIN 
                coords AS f ON d.node_from = f.node_id JOIN 
                coords as t ON d.node_to = t.node_id
            WHERE d.h < {radius}
        '''
        self.get_coordinate_from_id_query = '''
            SELECT long, lat
            FROM coords
            WHERE node_id = {node}
        '''
        plt.figure()

    def show(self):
        plt.show()

    def store(self, name, dpi="figure"):
        plt.savefig(name, dpi=dpi)

    def default(self, algorithm, x_value, y_value, file, scripts, xlabel=None, ylabel=None, errorbars=False, histogram=None, logy=False, ms=5):
        if not args.x_value:
            x_value = self.default_x_values[algorithm]

        query = self.default_query if not errorbars else self.errorbar_query

        for script_idx, script in enumerate(scripts):
            d = duckdb.sql(query.format(x_value=x_value, y_value=y_value, file=file, script=script)).fetchnumpy()

            colors = {'classic.sql': 'tab:blue', 'using-key.sql': 'tab:orange'}
            color = colors.get(script, None)

            if errorbars:
                plt.errorbar(d['x'], d['y'], yerr=d['dy'], fmt='o', label=script, color=color)
            elif histogram:
                plt.hist(d['y'], bins=histogram, label=script, color=color, log=logy, histtype='step')
            else:
                plt.plot(d['x'], d['y'], '.', label=script, color=color, ms = ms)

            if args.fit:
                try:
                    deg = args.fit[script_idx]
                    if deg == 0:
                        continue
                except IndexError:
                    print(f'Fitting failed for {script}: No degree was provided.\n')
                    continue

                fit = np.polyfit(d['x'], d['y'], deg) # returns coefficients of polynomial
                p = np.poly1d(fit) # can be applied to x-values
                xs = np.linspace(min(d['x']), max(d['x']))

                suffixes = {1: 'st', 2: 'nd', 3: 'rd'}
                degree_suffix = suffixes.get(deg, 'th')

                print(f'Fitted data for {script} to {deg}{degree_suffix} degree:')
                print(p)
                print()
 
                fit_colors = {'classic.sql': 'tab:red', 'using-key.sql': 'tab:green'}
                fit_color = fit_colors.get(script, None)

                plt.plot(xs, p(xs), label=f'{deg}{degree_suffix} degree fit', color=fit_color, zorder=-1)

        if logy:
            plt.yscale('log')
        plt.xlabel(xlabel if xlabel else y_value if histogram else x_value)
        plt.ylabel(ylabel if ylabel else 'count' if histogram else y_value)
        plt.grid()
        plt.legend(loc='upper left')

    # --- Astar-specific functions ---
    def edge_weights(self):
        w = np.loadtxt('all_weights.csv', skiprows=1)
        plt.hist(w, bins=500)
        plt.xlabel('edge weight [m]')
        plt.ylabel('number of edges')
        plt.title('Distribution of edge weights in New York')

    def map(self, coords_file):
        coords = np.loadtxt(coords_file, skiprows=1, delimiter=',')
        lat = coords[:,1]
        long = coords[:,0]
        plt.plot(long, lat, '.')

        plt.xlabel('Longitude')
        plt.ylabel('Latitude')

    # plot map from center with provided radius
    def roadmap(self, db, center, radius, goals):
        # use heuristic query to get distances of nodes to center
        with open('queries/astar/create_heuristic_graph.sql') as f:
            heuristic_query = f.read()
        heuristic_query = heuristic_query.format(goal_node=center, graph='h_dists')

        query = heuristic_query + self.map_query

        with duckdb.connect(db) as con:
            coords = con.sql(query.format(radius=radius)).fetchnumpy()
            for i in range(len(coords['from_long'])):
                x = [coords['from_long'][i], coords['to_long'][i]]
                y = [coords['from_lat'][i], coords['to_lat'][i]]
                plt.plot(x, y, color='Black', linewidth=0.5)
        
            # Plot start node
            center_coords = con.sql(self.get_coordinate_from_id_query.format(node=center)).fetchnumpy()
            x, y = center_coords['long'], center_coords['lat']
            plt.plot(x, y, 'o', color='Red')

            # Plot goal nodes
            for goal in goals:
                goal_coords = con.sql(self.get_coordinate_from_id_query.format(node=goal)).fetchnumpy()
                x, y = goal_coords['long'], goal_coords['lat']
                plt.plot(x, y, '.', color='magenta')

        plt.xlabel('Longitude')
        plt.ylabel('Latitude')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    parser.add_argument('query', type=str)
    parser.add_argument('y_value', type=str)
    parser.add_argument('file', type=str)

    parser.add_argument('--script', '--scripts', type=str, nargs='*', default=['using-key.sql', 'classic.sql'], help='scripts to consider')

    parser.add_argument('-x', '--x_value', type=str)

    parser.add_argument('--title', type=str)
    parser.add_argument('--xlabel', type=str)
    parser.add_argument('--ylabel', type=str)
    parser.add_argument('--marker_size', '--ms', type=float)

    parser.add_argument('--err', '--errorbars', action='store_true', help='plot with errorbars')
    parser.add_argument('--logy', action='store_true')
    parser.add_argument('--fit', type=int, nargs='*', help='fit data to polynomial of given degree; provide multiple values for multiple measurements within one plot (0 -> no fit)')

    parser.add_argument('-s', '--store', '--save', '--write', type=str, nargs='?', const='NOT PROVIDED', default='DONT STORE', help='store into file STORE')
    parser.add_argument('--dpi', type=float, help='set resolution of stored image in dpi')

    parser.add_argument('--hist', type=int, help='Print y_value as histogram with HIST many bins')
    parser.add_argument('--edge', action='store_true')
    parser.add_argument('--map', type=str, nargs='*', help='coords-files')
    parser.add_argument('--roadmap', nargs='+', help='Provide DB-FILE, CENTER, RADIUS, GOALS [OPTIONAL])')

    args = parser.parse_args()

    plot = Plot()

    if args.edge:
        plot.edge_weights()
    elif args.map:
        for map in args.map:
            plot.map(map)
    elif args.roadmap:
        if len(args.roadmap) < 3:
            raise Exception('Wrong number of arguments for --roadmap.')
        plot.roadmap(args.roadmap[0], int(args.roadmap[1]), int(args.roadmap[2]), args.roadmap[3:-1])
    else:
        plot.default(args.query, args.x_value, args.y_value, args.file, args.script, args.xlabel, args.ylabel, args.err, args.hist, args.logy, args.marker_size)

    if args.title:
        plt.title(args.title)
    if args.store == 'DONT STORE':
        plot.show()
    else:
        if args.store == 'NOT PROVIDED':
            measurement_filename = args.file.split('/')[-1].split('.')[0]
            filename = f'measure/plots/{measurement_filename}.svg'
        else:
            filename = args.store
        plot.store(filename, dpi=args.dpi)