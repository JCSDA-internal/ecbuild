# (C) Copyright 2011- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

"""
Create documentation for a given list of ecBuild macros.
"""

from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter
import logging
from os import environ, path, makedirs
import requests


log = logging.getLogger('create')
log.setLevel(logging.DEBUG)


def writeRST(rst, directory):
    "Write rST documentation to ``fname``.rst"

    if not path.exists(directory):
        makedirs(directory)

    for key, value in rst.items():
        fh = open('%s/%s.rst' % (directory, key), 'w')
        fh.write(value)
        fh.close()

    return


def extract(fname):
    "Extract rST documentation from CMake module ``fname``."
    with open(fname) as f:
        rst = False
        lines = []
        for line in f:
            line = line.strip()
            # Only consider comments
            if not line.startswith('#'):
                rst = False
                continue
            # Lines with the magic cooke '.rst:' start an rST block
            if line.endswith('.rst:'):
                rst = True
                continue
            # Only add lines in an rST block
            if rst:
                line = line.lstrip('#')
                # Blank lines are syntactically relevant
                lines.append(line[1:] if line else line)
        return lines


def indexRST():

    strings = []

    strings.append('#####################\n')
    strings.append('ecBuild Documentation\n')
    strings.append('#####################\n')
    strings.append('\n')
    strings.append('.. toctree::\n')
    strings.append('\t:maxdepth: 2\n')
    strings.append('\n')
    strings.append('\tmacros/index.rst\n')
    strings.append('\n')
    strings.append('##################\n')
    strings.append('Indices and tables\n')
    strings.append('##################\n')
    strings.append('\n')
    #strings.append('* :ref:`genindex`\n')
    strings.append('* :ref:`search`\n')

    return ''.join(strings)


def macrosRST(macros):

    strings = []

    strings.append('##############\n')
    strings.append('ecBuild macros\n')
    strings.append('##############\n')
    strings.append('.. toctree::\n')
    strings.append('\t:maxdepth: 2\n')
    strings.append('\n')

    for m in macros:
        mname, _ = path.splitext(m)
        strings.append('\t'+mname+'.rst\n')

    return ''.join(strings)


def main():
    parser = ArgumentParser(description=__doc__,
                            formatter_class=ArgumentDefaultsHelpFormatter)
    parser.add_argument('--logfile', default='create_doc.log',
                        help='Path to log file')
    parser.add_argument('--source', default='./_source',
                        help='Path to stage Sphinx .rst files')
    parser.add_argument('macro', nargs='+',
                        help='list of paths to ecBuild macros')
    args = parser.parse_args()

    # Log to file with level DEBUG
    fh = logging.FileHandler(args.logfile)
    fh.setLevel(logging.DEBUG)
    fmt = logging.Formatter('%(asctime)s %(name)s %(levelname)-5s - %(message)s')
    fh.setFormatter(fmt)
    log.addHandler(fh)
    # Log to console with level INFO
    ch = logging.StreamHandler()
    ch.setLevel(logging.INFO)
    log.addHandler(ch)
    # Also log requests at debug level to file
    logging.getLogger('requests').addHandler(fh)
    logging.getLogger('requests').setLevel(logging.DEBUG)

    log.info('====== Start creating documentation ======')
    log.info('Logging to file %s', args.logfile)
    rst = {}
    for m in args.macro:
        mname, _ = path.splitext(m)
        mname = path.basename(mname)
        rst[mname] = '\n'.join(extract(m))

    writeRST(rst, args.source+'/macros')

    writeRST({'index': indexRST()}, args.source)
    writeRST({'index': macrosRST(rst.keys())}, args.source+'/macros')

    log.info('====== Finished creating documentation ======')

if __name__ == '__main__':
    main()
