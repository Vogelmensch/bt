import argparse
import random
import duckdb

DEFAULT_DB_NAME = 'graphs.db'
DEFAULT_GRAPH_NAME = 'pygraph'
PROGRESS_INDICATOR = 1  

def insert_query(graph_name, edge):
    query = 'INSERT INTO {graph_name} VALUES '
    return f

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Generate random Graph')
    parser.add_argument('nodes', type=int, help='Number of nodes')
    parser.add_argument('edges', type=int, help='Number of edges')

    parser.add_argument('-w', '--max_weight', type=int, help='Max weight. Defaults to 1.')
    parser.add_argument('-c', '--connect', type=str, help='Name of .db-file to connect to. Defaults to \'graphs.db\'')
    parser.add_argument('-n', '--name', type=str, help='Name of graph')

    parser.add_argument('-d', '--directed', action='store_true', help='Make graph directed')

    parser.add_argument('-p', '--print_progress', action='store_true', help='Print progress of generation')

    args = parser.parse_args()

    max_weight = args.max_weight if args.max_weight else 1

    if args.connect:
        db_name = args.connect
    else:
        db_name = DEFAULT_DB_NAME

    if args.name:
        graph_name = args.name
    else:
        graph_name = DEFAULT_GRAPH_NAME

    with duckdb.connect(db_name) as con:
        # Choose a different name if graph already exists
        created = False
        add_number = 0
        while not created:
            temp_name = graph_name + (str(add_number) if add_number > 0 else '')
            try:
                con.sql(
                    'CREATE TABLE {} (node_from int, node_to int, weight int)'
                    .format(temp_name))
                graph_name = temp_name
                created = True
            except duckdb.CatalogException:
                add_number += 1

        print(f'Created table {graph_name}.')
        
        progress = 0
        dp = 1 / args.edges
        edges = [] # Type: list(tuple(int, int))

        for i in range(args.edges):
            progress = i / args.edges
            print(f'\rGenerating edges {int(progress * 100)} %', end='')
            
            node_from, node_to = 0, 0
            while node_from == node_to:
                node_from = random.randint(0, args.nodes)
                node_to = random.randint(0, args.nodes)
            
            weight = random.randint(1, max_weight)

            # twice for undirected graphs
            for _ in range(2):
                edge = (node_from, node_to, weight)
                edges.append(edge)

                if args.directed:
                    break

                node_from, node_to = node_to, node_from

        print()
        print('Generating query...')
        query = f'INSERT INTO {graph_name} VALUES '
        query = query + str(edges)[1:-1] + ';' # the str-representation can simply be used

        print('Performing query (this may take a while)...')
        con.sql(query)