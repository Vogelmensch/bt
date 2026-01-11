from query_tester import QueryTester

class AstarTester(QueryTester):
    def __init__(self):
        constants = []
        metrics = []
        super().__init__('astar', 'Perform A* query', constants, metrics)

    def define_specific_arguments(self, parser):
        parser.add_argument('db', type=str, help='path to .db-file holding the graph(s)')
        parser.add_argument('graph', type=str, help='name of the graph to perform the query on')
        parser.add_argument('start', type=int, help='id of the start node')
        parser.add_argument('goal', type=int, help='id of the goal node')
        parser.add_argument('heuristic', type=str, nargs='?', help='optional custom heuristic function. Default: h(x) = 0')

        parser.add_argument('-s', '--standard_heuristic', action='store_true', help='use standard heuristic file')

        parser.add_argument('-g', '--goals', type=int, nargs='+', help='Override provided goal with a list goals to perform MULTIPLE queries')

    def format_query(self, query):
        return query.format(graph=self.args.graph, start_node=self.args.start, goal_node=self.args.goal, heuristic=self.heuristic)


if __name__ == '__main__':
    constants = ['script', 'graph']
    metrics = ['path','nodes_count','total_weight','expanded_count','table_size']
    tester = AstarTester()