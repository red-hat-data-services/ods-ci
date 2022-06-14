#!/usr/bin/env python
# vim: et
# example: SplitSuite.py:3:1 => divide whole suite into 3 parts and execute 1st part
# from parts.
# Author: Akash Shende

from robot.api import SuiteVisitor
from itertools import islice
import math


def chunked(lst, nchunk):
    iter_lst = iter(lst)
    return iter(lambda: list(islice(iter_lst, nchunk)), [])


class SplitSuiteOrig(SuiteVisitor):
    """Visitor that keeps only every Xth test in the visited suite structure."""

    def __init__(self, parts, which_part=1):
        self.parts = float(parts)
        self.which_part = int(which_part)

    def visit_suite(self, suite):
        print("Visiting SUITE:", suite)
        print("Total number of suites:", len(suite.suites))
        num_suite = math.ceil(len(suite.suites) / self.parts)
        print("Number of suites:", num_suite)
        chunked_suites = [i for i in chunked(suite.suites, num_suite)]
        print("Total number of fetched suites: ", len(chunked_suites))
        print("Chunked suites: ", chunked_suites)
        suite_to_execute = chunked_suites[self.which_part - 1]

        try:
            if len(chunked_suites[self.which_part]) < num_suite and int(self.which_part) == int(self.parts):
                suite_to_execute.extend(chunked_suites[self.which_part])
        except IndexError:
            pass

        print("Suites in this part:", len(suite_to_execute))
        print("Suites to be execute:", suite_to_execute)
        print("Suites to be execute:", type(suite_to_execute))
        suite.suites = suite_to_execute
