"""Rewrite the 25 page-head lines of the 90.05 conversion to the measured
print columns. Each line keeps its own leading indent: the conversion
flattens the head-to-body margin and this change does not touch that.
"""
import re

PATH = 'comtran-manuals/J28-6169/90.05-sample-program.md'
HEAD = re.compile(r'^(\s*)DATE 10/18/61\s+TIME\s+2\.45\s+ACCOUNT\s+ID\.\s+'
                  r'(CT PUBLICATIONS)\s+PAGE\s+(\d+)\s*$')

def measured(page):
    """The head at the measured columns, with print column 0 at the D."""
    row = [' '] * 89
    for col, text in ((0, 'DATE'), (5, '10/18/61'), (15, 'TIME'), (21, '2.45'),
                      (27, 'ACCOUNT'), (55, 'ID.'), (59, 'CT PUBLICATIONS'),
                      (83, 'PAGE')):
        row[col:col + len(text)] = text
    return ''.join(row) + page

src = open(PATH).read().split('\n')
changes = []
for i, line in enumerate(src):
    m = HEAD.match(line)
    if not m:
        continue
    indent, page = m.group(1), m.group(3)
    new = indent + measured(page)
    if new != line:
        changes.append((i + 1, line, new))
        src[i] = new

open(PATH, 'w').write('\n'.join(src))
print(f'{len(changes)} head lines rewritten\n')
for n, old, new in changes[:1] + changes[6:7] + changes[7:8] + changes[16:17]:
    print(f'line {n}\n  -{old}\n  +{new}\n')
