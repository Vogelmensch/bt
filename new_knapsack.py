from query_tester import QueryTester

class KnapsackTester(QueryTester):
    def __init__(self, constants, metrics):
        super().__init__('knapsack', 'Perform Knapsack Query', constants, metrics)

    def define_specific_arguments(self, parser):
        # specific arguments
        parser.add_argument('db', type=str, help='path to .db-file holding the item_table(s)')
        parser.add_argument('item_table', type=str, help='name of the item_table to perform the query on')
        parser.add_argument('max_weight', type=int, help='total max weight')

        parser.add_argument('-g', '--item_tables', type=str, nargs='*', help='additional item_tables to evaluate')
        parser.add_argument('-r', '--random', type=int, nargs='*', help='create random item-table of given size')

        # args
        return parser.parse_args()

    def format_query(self, query):
        return query.format(max_weight=self.args.max_weight, items=self.item_table)

    def prepare_knapsack(self):
        # Generate random item-tables for knapsack
        random_tables = []
        if self.args.random:
            with open('queries/knapsack/random-items.sql') as f:
                query_from_file = f.read()
            with duckdb.connect(self.args.db) as con:
                for idx, sample_size in enumerate(self.args.random):
                    table_name = f'generated_{idx}'
                    random_tables.append(table_name)
                    query = query_from_file.format(table_name=table_name, sample_size=sample_size)
                    con.sql(query)

        # returning item_tables
        if not self.args.random:
            return [self.args.item_table] + (self.args.item_tables if self.args.item_tables else [])
        else:
            return random_tables
        
if __name__ == '__main__':
    constants = ['script', 'item_table']
    metrics = ['max_value', 'items_count', 'table_size']
    tester = KnapsackTester(constants, metrics)
    
    item_tables = tester.prepare_knapsack()

    print(item_tables)

    for i, item_table in enumerate(item_tables):
        tester.item_table = item_table
        tester.run()