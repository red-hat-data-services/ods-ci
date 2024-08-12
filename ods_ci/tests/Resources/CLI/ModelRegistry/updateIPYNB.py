import json
import subprocess

# Define the filenames
input_filename = "tests/Resources/CLI/ModelRegistry/MRMS_TEST_RUNNER.ipynb"
output_filename = "tests/Resources/CLI/ModelRegistry/MRMS_UPDATED.ipynb"


# Function to run an oc command and retrieve output
def get_oc_command_output(command):
    try:
        result = subprocess.run(command, check=True, capture_output=True, text=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        raise RuntimeError(f"Failed to run oc command: {e}\n{e.stderr}") from e


# Run the oc command to get the domain
command = ["oc", "get", "ingresses.config/cluster", "-o", "jsonpath={.spec.domain}"]
replacement_text = get_oc_command_output(command)

# Check if the replacement text was successfully retrieved
if not replacement_text:
    raise ValueError("The domain value could not be retrieved from the oc command.")

print(f"Replacement text (DOMAIN) is: {replacement_text}")

# Read the notebook file
with open(input_filename, "r") as file:
    notebook = json.load(file)

# Replace placeholder text in code cells
placeholder = "PLACEHOLDER"
for cell in notebook.get("cells", []):
    if cell.get("cell_type") == "code":
        source = cell.get("source", [])
        # Replace the placeholder text with the replacement text
        cell["source"] = [line.replace(placeholder, replacement_text) for line in source]

# Save the modified notebook
with open(output_filename, "w") as file:
    json.dump(notebook, file, indent=2)

print(f"Modified notebook saved as {output_filename}")
