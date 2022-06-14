#!/usr/bin/env python
# vim: et
# example: SplitSuite.py:3:1 => divide whole suite into 3 parts and execute 1st part
# from parts.
# Author: Akash Shende

from robot.api import SuiteVisitor
from itertools import islice
import math
import sys


MAX_SUITE_LEVELS = 3


def chunked(lst, nchunk):
    iter_lst = iter(lst)
    return iter(lambda: list(islice(iter_lst, nchunk)), [])


def fetch_subsuites(parent):
    children = [child for child in parent.suites]
    return children


def fetch_subsuites_from_list(parents_list):
    children = []
    # children += [fetch_subsuites(parent) for parent in parents_list]
    for parent in parents_list:
        children += fetch_subsuites(parent)
    return children


def fetch_suites_names(suites_list):
    names = [s.name for s in suites_list]
    return names


class SplitSuite(SuiteVisitor):
    """Visitor that keeps only every Xth test in the visited suite structure."""

    def __init__(self, parts, which_part=1):
        self.parts = float(parts)
        self.which_part = int(which_part)

    def visit_suite(self, suite):
        print("Visiting SUITE:", suite)
        sub_suites_list = []
        if MAX_SUITE_LEVELS == 1:
            sub_suites_list = suite.suites
        else:
            for suite_lev_1 in suite.suites:
                found = False
                next_lev_suites = fetch_subsuites(suite_lev_1)
                for lev in range(2, MAX_SUITE_LEVELS+1):
                    print("Extracting suites with level: ", lev)
                    current_lev_suites = next_lev_suites
                    print("Current Lev suites: ", current_lev_suites)
                    next_lev_suites = fetch_subsuites_from_list(next_lev_suites)
                    print("next level suites: ", next_lev_suites)
                    if not next_lev_suites:
                        print("Fetching sub suites from level: ", lev)
                        print("fetched from lev2: ",fetch_subsuites_from_list(current_lev_suites))
                        sub_suites_list += fetch_subsuites_from_list(current_lev_suites)
                        found = True
                if not found:
                    sub_suites_list += fetch_subsuites(suite_lev_1)
                print("\n")

        print("Total number of 1st level suites:", len(suite.suites))
        print("1st level suites:", suite.suites)
        print("Total number of fetched suites: ", len(sub_suites_list))
        suite_names = fetch_suites_names(sub_suites_list)
        test_names = [t.name for t in sub_suites_list]
        print("Test names in the suite: ", test_names)
        print("Suites names in the suite: ", suite_names)
        num_suite = math.ceil(len(sub_suites_list) / self.parts)
        print("Number of suites per split:", num_suite)
        chunked_suites = [i for i in chunked(sub_suites_list, num_suite)]
        print("Number of chunked suites: ", len(chunked_suites))
        print("Chunked suites: ", chunked_suites)
        suite_to_execute = chunked_suites[self.which_part - 1]

        try:
            if len(chunked_suites[self.which_part]) < num_suite and int(self.which_part) == int(self.parts):
                suite_to_execute.extend(chunked_suites[self.which_part])
        except IndexError:
            pass

        print("Suites in this part:", len(suite_to_execute))
        print("Suites to be execute:", suite_to_execute)
        suite.suites = suite_to_execute
