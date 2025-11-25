import duckdb
import argparse

# Run the test on the query with inputs s1, s2 and compare the result to the expected output.
def run_test(query, string1, string2, expected):
    res = duckdb.sql(query.format(string1='\'' + string1 + '\'', string2='\'' + string2 + '\'')).fetchall()[0]

    # both are lists. sort to compare.
    expected.sort() 
    res = list(zip(res[0], res[1]))
    res.sort()

    if expected == res:
        print('✅ Success')
    else:
        print('❌ Failure for inputs \'{s1}\' and \'{s2}\':'.format(s1=string1, s2=string2))
        print('Expected \'{e}\' but got \'{r}\''.format(e=expected, r=res))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Test lcs query.')
    parser.add_argument('-c','--classic', action='store_true', help='use classic CTE')
    args = parser.parse_args()

    if args.classic:
        script = 'queries/needleman/classic.sql'
        print('classic query')
    else:
        script = 'queries/needleman/using-key.sql'
        print('USING KEY')

    with open(script) as f:
        query = f.read()


    # --- DEFINE TESTS HERE ---
    run_test(query, '', '', [('', '')])
    run_test(query, 'some arbitrary string', '', [('', '')])
    run_test(query, '', 'some other string', [('', '')])
    run_test(query, 'GCATGCG', 'GATTACA', [
        ('GCAT-GCG', 'G-ATTACA'),
        ('GCA-TGCG', 'G-ATTACA'),
        ('GCATG-CG', 'G-ATTACA')
    ])
