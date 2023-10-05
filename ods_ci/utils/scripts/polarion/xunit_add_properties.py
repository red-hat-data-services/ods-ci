"""Inserts properties from a config file into a xunit format XML file"""
import argparse
import codecs
import xml.etree.ElementTree as et
from copy import deepcopy
from xml.dom import minidom
import os
from junitparser import JUnitXml, TestCase, TestSuite, Failure, Error, Skipped
import yaml


def parse_args():
    """Parse CLI arguments"""
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description="Inject properties into junit xml for Polarion",
    )
    parser.add_argument(
        "-c",
        "--testrunconfig",
        help="polariontest run config file",
        action="store",
        dest="config_file",
        required=True,
    )
    parser.add_argument(
        "-i",
        "--robotresultxml",
        help="robot test result XML file",
        action="store",
        dest="robot_result_xml_file",
        required=True,
    )
    parser.add_argument(
        "-x",
        "--xunitxml",
        help="XUnit XML file",
        action="store",
        dest="xunit_xml_file",
        required=True,
    )
    parser.add_argument(
        "-o",
        "--out",
        help="Output resulting XML file",
        action="store",
        dest="output_file",
        required=True,
    )
    return parser.parse_args()


def parse_xml(filename):
    """parse the input XML"""
    tree = et.parse(filename)
    root = tree.getroot()

    return root


def add_testsuite_properties(xml_obj, tsconfig):
    """add properties to the testsuite"""
    properties = et.Element("properties")
    for name, value in tsconfig.items():
        attribs = {"name": name, "value": value}
        element = et.Element("property", attrib=attribs)
        properties.append(element)
    xml_obj.insert(0, properties)

    return xml_obj


def get_results(xml_obj):
    """get result status"""
    results = {}
    expression = "./testsuite"
    for testsuite in xml_obj.findall(expression):
        errors = int(testsuite.get("errors"))
        failures = int(testsuite.get("failures"))
        status = "passed"
        if failures or errors:
            status = "failed"
        results[testsuite.get("name")] = {
            "errors": errors,
            "failures": failures,
            "skipped": int(testsuite.get("skipped")),
            "tests": int(testsuite.get("tests")),
            "time": float(testsuite.get("time")),
            "status": status,
        }

    return results


def add_testcase_properties(xml_obj, tcconfig=None):
    """add properties to testcases"""
    if xml_obj.tag == "testsuites":
        expression = "./testsuite/testcase"
    else:
        expression = "./testcase"

    multile_test_ids = {}
    for testcase in xml_obj.findall(expression):
        tcname, name = None, testcase.get("name")
        if tcconfig.get(name):
            tcname = name
        elif tcconfig.get(name.lower()):
            tcname = name.lower()
        else:
            continue

        polarion_id = tcconfig[tcname]
        test_id = ""
        if len(polarion_id) == 1:
            test_id = test_id.join(polarion_id)
            tcproperties = et.Element("properties")
            attribs = {"name": "polarion-testcase-id", "value": test_id}
            element = et.Element("property", attrib=attribs)
            tcproperties.append(element)
            testcase.insert(0, tcproperties)
        else:
            xml_obj_testsuite = xml_obj.find("./testsuite")
            for i in range(len(polarion_id) - 1):
                xml_obj_testsuite.append(deepcopy(testcase))
            multile_test_ids[testcase.get("name")] = polarion_id

    for key in multile_test_ids.keys():
        for index, testcase in enumerate(
            xml_obj.findall(expression + "[@name='" + key + "']")
        ):
            if index < len(multile_test_ids[testcase.get("name")]):
                tcproperties = et.Element("properties")
                test_id = ""
                test_id = test_id.join(multile_test_ids[testcase.get("name")][index])
                attribs = {"name": "polarion-testcase-id", "value": test_id}
                element = et.Element("property", attrib=attribs)
                tcproperties.append(element)
                testcase.insert(0, tcproperties)

    return xml_obj


def get_polarion_id(xml_obj):
    """Gets testcase name and its polarion ids"""
    tc_data = {}
    for test_data in xml_obj.findall(".//test"):
        tags = test_data.findall("tag")
        polarion_id_list = []
        for tag in tags:
            if tag.text.startswith("ODS-") or tag.text.startswith("ODH-"):
                polarion_id_list.append(tag.text)
                tc_data[test_data.attrib["name"]] = polarion_id_list
    return tc_data


def write_xml(xml_obj, filename):
    """write propertified XML to a file"""
    new_xml = ""
    xml_lines = et.tostring(xml_obj, method="xml", encoding="unicode").split("\n")
    for line in xml_lines:
        new_xml += line.strip()
    xmlstr = minidom.parseString(new_xml).toprettyxml(indent="   ")

    if filename != "STDOUT":
        with codecs.open(filename, "w", "utf-8") as xmlfd:
            xmlfd.write(xmlstr)
    else:
        print(xmlstr)


def restructure_xml_for_polarion(src_xunit_xml_file, xunit_xml_file_restructured):
    """
    Modify the source xml for polarion test result update
    """

    # Read source xml file
    src_xml = JUnitXml.fromfile(src_xunit_xml_file)

    xml_testsuites = JUnitXml()
    xml_testsuite = TestSuite()

    # Add testsuite attributes to new xml file
    xml_testsuite.name = src_xml.name
    xml_testsuite.tests = src_xml.tests
    xml_testsuite.errors = src_xml.errors
    xml_testsuite.failures = src_xml.failures
    xml_testsuite.skipped = src_xml.skipped
    xml_testsuite.time = src_xml.time

    for suite in src_xml:
        tc = TestCase()
        tc.name = suite.name
        tc.time = suite.time

        if not suite.is_passed:
            if isinstance(suite.result[0], Failure):
                f = Failure()
                f.type = suite.result[0].type
                f.message = suite.result[0].message
                tc.append(f)
            elif isinstance(suite.result[0], Error):
                e = Error()
                e.type = suite.result[0].type
                e.message = suite.result[0].message
                tc.append(e)
            elif suite.is_skipped:
                s = Skipped()
                s.type = suite.result[0].type
                s.message = suite.result[0].message
                tc.append(s)
        xml_testsuite.append(tc)
    xml_testsuites.append(xml_testsuite)
    xml_testsuites.write(xunit_xml_file_restructured, pretty=True)


def main():
    """main function"""
    args = parse_args()

    # Restructure the robot test result xml file
    xunit_xml_file_restructured = (
        os.path.dirname(os.path.realpath(__file__)) + "/restructured_xml_file.xml"
    )
    restructure_xml_for_polarion(args.xunit_xml_file, xunit_xml_file_restructured)

    root = parse_xml(xunit_xml_file_restructured)
    with open(args.config_file) as config:
        testsuite_config = yaml.safe_load(config)

    tc_config = get_polarion_id(parse_xml(args.robot_result_xml_file))
    root = add_testsuite_properties(root, testsuite_config["testrun_info"])
    root = add_testcase_properties(root, tc_config)
    write_xml(root, args.output_file)


if __name__ == "__main__":
    main()
