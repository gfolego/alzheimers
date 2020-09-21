#!/usr/bin/python3

"""
"""

import sys
import argparse
import os

import subprocess

import utils


# Definitions
ATLAS_PATH = os.path.abspath(os.path.join(os.sep, 'mni_icbm152_nlin_asym_09c'))
ATLAS_IMAGE = os.path.join(ATLAS_PATH,
                           'mni_icbm152_t1_tal_nlin_asym_09c.nii')
ATLAS_MASK = os.path.join(ATLAS_PATH,
                          'mni_icbm152_t1_tal_nlin_asym_09c_mask.nii')

BRAIN_SCRIPT = os.path.join('src',
                            'brain_process.sh')

# Required for reproducibility
N_CPUS = 2


def parse_args(argv):
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('image', type=str,
                        help='input mri image file path')
    parser.add_argument('output', type=str,
                        help='output processed brain file path')
    args = parser.parse_args(args=argv)
    return args


def brain_process(image,
                  out_path,
                  atlas_image=ATLAS_IMAGE,
                  atlas_mask=ATLAS_MASK,
                  brain_script=BRAIN_SCRIPT,
                  cpus=N_CPUS):

    # Output
    os.makedirs(os.path.dirname(out_path), exist_ok=True)

    # Call brain preprocess
    subprocess.call(['bash', brain_script,
                     '-f', atlas_image,
                     '-x', atlas_mask,
                     '-i', image,
                     '-o', out_path,
                     '-n', str(cpus)])


def main(argv):
    # Parse arguments
    args = parse_args(argv)
    print("Args: %s" % str(args))

    # Prepare paths
    image = utils.parse_path(args.image, utils.REPO)
    atlas_image = utils.parse_path(ATLAS_IMAGE, utils.REPO)
    atlas_mask = utils.parse_path(ATLAS_MASK, utils.REPO)
    brain_script = utils.parse_path(BRAIN_SCRIPT, utils.REPO)
    out_path = utils.parse_path(args.output, utils.REPO)

    # Brain preprocessing
    brain_process(image,
                  out_path,
                  atlas_image,
                  atlas_mask,
                  brain_script,
                  N_CPUS)

    print("Done!")


if __name__ == "__main__":
    main(sys.argv[1:])
