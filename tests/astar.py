import duckdb
import argparse

# Run the test on the query with inputs s1, s2 and compare the result to the expected output.
def run_test(query, graph, start, goal, expected, heuristic='0'):
    res = con.sql(query.format(graph=graph, start_node=start, goal_node=goal, heuristic=heuristic)).fetchall()

    if len(res) == 0:
        res = ''
    else:
        res = res[0]

    if expected == res:
        print('✅ Success')
    else:
        print('❌ Failure for inputs \'{}\', \'{}\', \'{}\' and \'{}\':'.format(graph, start, goal, heuristic))
        print('Expected \'{e}\' but got \'{r}\''.format(e=expected, r=res))

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Test A* query.')
    parser.add_argument('-c','--classic', action='store_true', help='use classic CTE')
    args = parser.parse_args()

    with duckdb.connect('graphs.db') as con:
        if args.classic:
            script = 'queries/astar_classic.sql'
            print('classic query')
        else:
            script = 'queries/astar.sql'
            print('USING KEY')

        with open(script) as f:
            query = f.read()
    
    
        # --- DEFINE TESTS HERE ---
        run_test(query, 'simple', 0, 0, ('0', 0))
        run_test(query, 'simple', 0, 6, ('0 -> 1 -> 3 -> 5 -> 6', 5))
        run_test(query, 'simple', 0, 7, '')