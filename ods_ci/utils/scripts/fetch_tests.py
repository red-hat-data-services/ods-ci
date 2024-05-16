from util import execute_command
import re
import xml.etree.ElementTree as ET


def extract_test_data(element):
    tests = []
    for child in element:
        if child.tag == "test":
            # tests.append(child.attrib["name"])
            test_tags = []
            for tag in child.findall("./tag"):
                print("RobotFramework tags: ", tag.text)
                test_tags.append(tag.text)
            tests.append({"name": child.attrib["name"], "tags": test_tags})
        else:
            tests += extract_test_data(child)
    return tests
            

def extract_new_test_cases(rf_xml):
    # TO DO: 
    #   - fetch git repo with branch/commit v1
    #   - run dry run and extract xml
    #   - fetch test + robotframework tags from xml
    #   - re-do for branch/commit v2
    #   - compare the 2 results and get diff
    tree = ET.parse(rf_xml)
    root = tree.getroot()
    print("tags: ",root.tag)
    tests = []
    for child in root:
        tests += extract_test_data(child)
    print(tests)

extract_new_test_cases("ods_ci/utils/scripts/fetch_new_tests/output.xml")