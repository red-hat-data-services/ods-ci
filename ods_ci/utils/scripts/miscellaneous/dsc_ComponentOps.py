import argparse
import yaml
import os


def toggle_components(yaml_file, component_states, set_default=True):
    "This function will enable and disable the component"
    if os.path.exists(yaml_file):
        with open(yaml_file, "r") as f:
            data_science_cluster = yaml.safe_load(f)
    else:
        # If YAML file does not exist, create a new DataScienceCluster YAML
        data_science_cluster = {
            "apiVersion": "datasciencecluster.opendatahub.io/v1alpha1",
            "kind": "DataScienceCluster",
            "metadata": {"name": "example"},
            "spec": {"components": {}},
        }

    components = data_science_cluster["spec"]["components"]
    for component in components:
        if component in component_states:
            components[component]["enabled"] = component_states[component]
        elif set_default:
            # If component is not present and set_default is True, add it to the YAML with default state (False)
            components[component] = {"enabled": False}

    for component in component_states:
        if component not in components:
            # Add the component with its state to the YAML
            components[component] = {"enabled": component_states[component]}

    with open(yaml_file, "w") as f:
        yaml.dump(data_science_cluster, f)


def main():
    parser = argparse.ArgumentParser(
        description="Toggle components in DataScienceCluster YAML."
    )
    parser.add_argument("yaml_file", type=str, help="Path to the YAML file")

    # Dynamic component states as a single command-line argument in the format: --component component1:state1,component2:state2,...
    parser.add_argument(
        "--components",
        type=str,
        help="Comma-separated list of components and their states (component1:state1,component2:state2,...)",
    )

    # Optional argument to skip setting default value for unspecified components
    parser.add_argument(
        "--no-default",
        action="store_true",
        help="Do not set default value for unspecified components",
    )

    args = parser.parse_args()

    # Parse and convert the component states argument into a dictionary
    component_states = {}
    if args.components:
        components_list = args.components.split(",")
        for component in components_list:
            comp, state = component.split(":")
            component_states[comp] = True if state.lower() == "true" else False

    # Pass the set_default argument based on the --no-default parameter
    toggle_components(args.yaml_file, component_states, not args.no_default)
    print("DataScienceCluster YAML has been updated.")


if __name__ == "__main__":
    main()
