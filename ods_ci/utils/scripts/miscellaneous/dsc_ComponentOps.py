import argparse
import yaml

def toggle_components(yaml_file, component_states):
    "This function will enable and disable the component"
    with open(yaml_file, 'r') as f:
        data_science_cluster = yaml.safe_load(f)

    components = data_science_cluster['spec']['components']
    for component, enabled in component_states.items():
        if component in components:
            components[component]['enabled'] = enabled
        else:
            # If component is not present, add it to the YAML
            components[component] = {'enabled': enabled}

    with open(yaml_file, 'w') as f:
        yaml.dump(data_science_cluster, f)

def main():
    parser = argparse.ArgumentParser(description='Toggle components in DataScienceCluster YAML.')
    parser.add_argument('yaml_file', type=str, help='Path to the YAML file')

    # Dynamic component states as a single command-line argument in the format: --component component1:state1,component2:state2,...
    parser.add_argument('--components', type=str, help='Comma-separated list of components and their states (component1:state1,component2:state2,...)')

    args = parser.parse_args()

    # Parse and convert the component states argument into a dictionary
    component_states = {}
    if args.components:
        components_list = args.components.split(',')
        for component in components_list:
            comp, state = component.split(':')
            component_states[comp] = True if state.lower() == 'true' else False

    toggle_components(args.yaml_file, component_states)
    print("DataScienceCluster YAML has been updated.")

if __name__ == "__main__":
    main()
