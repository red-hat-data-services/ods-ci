"""Inserts properties from a config file into a xunit format XML file"""
import argparse
import codecs
import xml.etree.ElementTree as et
from xml.dom import minidom
import re
from copy import deepcopy
import yaml


def parse_args():
    """Parse CLI arguments"""
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description='Inject properties into junit xml for Polarion'
        )
    parser.add_argument("-c", "--testrunconfig",
                        help="polariontest run config file",
                        action="store", dest="config_file",
                        required=True)
    parser.add_argument("-i", "--robotresultxml",
                        help="robot test result XML file",
                        action="store", dest="robot_result_xml_file",
                        required=True)
    parser.add_argument("-x", "--xunitxml",
                        help="XUnit XML file",
                        action="store", dest="xunit_xml_file",
                        required=True)
    parser.add_argument("-o", "--out",
                        help="Output resulting XML file",
                        action="store", dest="output_file",
                        required=True)
    return parser.parse_args()


def parse_xml(filename):
    """parse the input XML"""
    tree = et.parse(filename)
    root = tree.getroot()

    return root


def add_testsuite_properties(xml_obj, tsconfig):
    """add properties to the testsuite"""
    properties = et.Element('properties')
    for name, value in tsconfig.items():
        attribs = {'name': name, 'value': value}
        element = et.Element('property', attrib=attribs)
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
        tcproperties = et.Element('properties')
        tcname, name = None, testcase.get('name')
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
            attribs = {'name': 'polarion-testcase-id', 'value': test_id}
            element = et.Element('property', attrib=attribs)
            tcproperties.append(element)
        else:
            for i in range(len(polarion_id)-1):
                xml_obj.append(deepcopy(testcase))
            multile_test_ids[testcase.get('name')] = polarion_id
            
        testcase.insert(0, tcproperties)

    for key in multile_test_ids.keys():
        for index, testcase in enumerate(xml_obj.findall(expression + "[@name='" + key + "']")):
            if (index < len(multile_test_ids[testcase.get('name')])):
                tcproperties = et.Element('properties')
                test_id = ""
                test_id = test_id.join(multile_test_ids[testcase.get('name')][index])
                attribs = {'name': 'polarion-testcase-id', 'value': test_id}
                element = et.Element('property', attrib=attribs)
                tcproperties.append(element)
                testcase.insert(0, tcproperties)
 
    return xml_obj

def get_polarion_id(xml_obj):
    """Gets testcase name and its polarion ids"""
    tc_data = {}
    for test_data in xml_obj.findall('.//test'):
        tags = test_data.findall('tag')
        polarion_id_list = []
        for tag in tags:
           if (tag.text.startswith("ODS-") or tag.text.startswith("ODH-")):
               polarion_id_list.append(tag.text)
               tc_data[test_data.attrib['name']] = polarion_id_list
    return (tc_data)

def write_xml(xml_obj, filename):
    """write propertified XML to a file"""
    new_xml = ''
    xml_lines = et.tostring(xml_obj, method='xml', encoding='unicode').split('\n')
    for line in xml_lines:
        new_xml += line.strip()
    xmlstr = minidom.parseString(new_xml).toprettyxml(indent="   ")

    if filename != 'STDOUT':
        with codecs.open(filename, 'w', 'utf-8') as xmlfd:
            xmlfd.write(xmlstr)
    else:
        print (xmlstr)

def main():
    """main function"""
    args = parse_args()

    root = parse_xml(args.xunit_xml_file)
    with open(args.config_file) as config:
        testsuite_config = yaml.load(config)

    tc_config = get_polarion_id(parse_xml(args.robot_result_xml_file))
    root = add_testsuite_properties(root, testsuite_config["testrun_info"])
    root = add_testcase_properties(root, tc_config)
    write_xml(root, args.output_file)


if __name__ == '__main__':
    main()
