#!/usr/bin/env python
# vim: et
# example: SplitSuite.py:3:1
# => divide whole suite into 3 parts and execute 1st part
# from parts.
# Based on Splitter authored by: Akash Shende
# https://github.com/akash0x53/robot-parallel/blob/master/SplitSuite.py

import math
from itertools import islice

from robot.api import SuiteVisitor


def chunked(lst, nchunk):
    iter_lst = iter(lst)
    return iter(lambda: list(islice(iter_lst, nchunk)), [])


def fetch_subsuites(parent):
    children = list(parent.suites)
    return children


def fetch_suites_names(suites_list):
    names = [s.name for s in suites_list]
    return names


class SplitSuite(SuiteVisitor):
    """
    Visitor that keeps only every Xth test in the visited suite structure.
    """

    def __init__(self, parts, which_part=1, max_suite_level=2):
        self.parts = float(parts)
        self.which_part = int(which_part)
        self.max_suite_level = max_suite_level

    def visit_suite(self, suite):
        print("Visiting SUITE:", suite)
        sub_suites_list = []
        if self.max_suite_level == 1:
            sub_suites_list = suite.suites
        else:
            for suite_lev_1 in suite.suites:
                print("> Suite Lev 1: ", suite_lev_1.name)
                next_lev_suites = fetch_subsuites(suite_lev_1)
                for lev in range(2, self.max_suite_level + 1):
                    print(">>> Extracting suites with level: ", lev)
                    current_lev_suites = next_lev_suites.copy()
                    if lev == self.max_suite_level:
                        sub_suites_list += current_lev_suites
                        continue
                    next_lev_suites = []
                    for curr_lev_suite in current_lev_suites:
                        next_lev_suites_tmp = fetch_subsuites(curr_lev_suite)
                        if not next_lev_suites_tmp:
                            # print(
                            # "Fetching sub suites from previous level: ", str(
                            # lev-1))
                            sub_suites_list.append(curr_lev_suite)
                        else:
                            next_lev_suites += next_lev_suites_tmp

        print("Total number of 1st level suites:", len(suite.suites))
        print("1st level suites:", suite.suites)
        print("Total number of fetched suites: ", len(sub_suites_list))
        suite_names = fetch_suites_names(sub_suites_list)
        print("Suites names in the suite: ", suite_names)
        num_suite = math.ceil(len(sub_suites_list) / self.parts)
        print("Number of suites per split:", num_suite)
        chunked_suites = list(chunked(sub_suites_list, num_suite))
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
