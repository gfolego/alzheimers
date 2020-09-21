#!/usr/bin/python3

"""
"""


import os


# Definitions
SCRIPT_PATH = os.path.join('src',
                           os.path.basename(__file__))

REPO = os.path.abspath(__file__).replace(SCRIPT_PATH, '')

# Convert to abs path if necessary
def parse_path(path, abspath):
    if not os.path.isabs(path):
        path = os.path.join(abspath, path)
    return path

