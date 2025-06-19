from sys import argv

# converts a dig trace to a csv:
# no header row, comments, location label
# and with comma separator

if __name__ == '__main__':
    with open(argv[1], 'r') as fp:
        raw = fp.read()
    entries = [','.join(filter(lambda c: c, (map(
        lambda c: c.strip(), x.split(';')[1:]))))
               for x in raw.split('\n')
               if x and not x.strip().startswith('#')][1:]

    print('\n'.join(entries))
