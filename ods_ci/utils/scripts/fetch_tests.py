from util import execute_command
import re
import xml.etree.ElementTree as ET


def extract_test_data(element):
    tests = []
    for child in element:
        if child.tag == "test":
            test_tags = []
            # for tag in child.findall("./tag"):
            #     test_tags.append(tag.text)
            # tests.append({"name": child.attrib["name"], "tags": test_tags})
            tests.append(child.attrib["name"])
        else:
            tests += extract_test_data(child)
    return tests

def parse_and_extract(xml_filepath):
    tree = ET.parse(xml_filepath)
    root = tree.getroot()
    tests = []
    tests += extract_test_data(root[0])
    # print(tests)
    return  tests

def extract_new_test_cases(xml_0_filepath, xml_1_filepath):
    # TO DO: 
    #   - fetch git repo with branch/commit v1
    #   - run dry run and extract xml
    #   - fetch test + robotframework tags from xml
    #   - re-do for branch/commit v2
    #   - compare the 2 results and get diff
    print("\n---| Parsing tests from older branch |---")
    tests_0 = parse_and_extract(xml_0_filepath)
    print("Done. Found {num} test cases".format(num=len(tests_0)))
    print("\n---| Parsing tests from newer branch |---")
    tests_1 = parse_and_extract(xml_1_filepath)
    print("Done. Found {num} test cases".format(num=len(tests_1)))

    print("\n---| Computing differences |----")
    new_tests = list(set(tests_1) - set(tests_0))
    print("Done. Found {num} new tests in newer repo".format(num=len(new_tests)))
    print(new_tests)



extract_new_test_cases("ods_ci/utils/scripts/fetch_new_tests/output_0.xml", "ods_ci/utils/scripts/fetch_new_tests/output_1.xml")