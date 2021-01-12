import argparse
import subprocess
import os
import re
from collections import Counter
parser = argparse.ArgumentParser(description='exec zhrc commands')
parser.add_argument('--hgrep', type=str, default='None')
parser.add_argument('--top', type=int, default=10)

def main():
    args = parser.parse_args()
    if args.hgrep != 'None':
        hgrep_n = args.hgrep
        queries = [re.sub('^\d+\s+', '', x.strip()).replace('sudo', '').strip() for x in hgrep_n.split('\n ') if not (("history |" in x) or ("hgrep" in x))]
        query_counter = Counter(queries)
        os.system(f'echo "$(tput sgr0) Counts $(tput setaf 3) Commands";')
        elements = sorted(list(query_counter.items())[-(args.top):], key=lambda x: x[1])
        for i, x in enumerate(elements):
            if i != len(elements) - 1:
                os.system(f'echo "$(tput sgr0) {x[1]} $(tput setaf 3) {x[0]}"')
            else:
                os.system(f'echo "$(tput sgr0) {x[1]} $(tput setaf 2) {x[0]} $(tput sgr0) (Copied to clipboard!)" & echo {x[0]} | pbcopy')

main()
