import argparse
import random
import duckdb

DEFAULT_DB_NAME = 'graphs.db'
DEFAULT_GRAPH_NAME = 'pygraph'
PROGRESS_INDICATOR = 1  

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Generate random Graph')
    parser.add_argument('nodes', type=int, help='Number of nodes')
    parser.add_argument('con_prob', type=float, help='Probability that two nodes are connected. con_prob = 1 creates a fully connected graph.')

    parser.add_argument('-w', '--max_weight', type=int, help='Max weight. Defaults to 1.')
    parser.add_argument('-c', '--connect', type=str, help='Name of .db-file to connect to. Defaults to \'graphs.db\'')
    parser.add_argument('-n', '--name', type=str, help='Name of graph')

    parser.add_argument('-d', '--directed', action='store_true', help='Make graph directed')

    parser.add_argument('-p', '--print_progress', action='store_true', help='Print progress of generation')

    args = parser.parse_args()

    if args.directed:
        raise NotImplementedError

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
        
        progress = 0
        for node1 in range(args.nodes):
            for node2 in range(args.nodes):
                if args.print_progress:
                    current_progress = int(node1/args.nodes * 100)
                    if current_progress - progress == PROGRESS_INDICATOR:
                        print("{}%".format(current_progress))
                        progress = current_progress


                if node1 != node2 and random.random() < args.con_prob:
                    weight = random.randint(1, max_weight)
                    con.sql(
                        '''
                        INSERT INTO {graph} VALUES ({f},{t},{w});
                        INSERT INTO {graph} VALUES ({t},{f},{w});
                        '''
                        .format(graph=graph_name, f = node1, t = node2, w = weight))