#!/usr/bin/env python3
"""
Example usage of the Architecture Detection functionality

This demonstrates how to use the new architecture detection functions
in your Robot Framework tests and provisioning scripts.
"""

from arch_utils import (
    get_node_architecture, 
    get_cluster_architecture_info,
    get_arch_compatible_instance_type,
    is_mixed_architecture_cluster,
    get_architecture_specific_images
)
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)

def main():
    """Demonstrate architecture detection usage"""
    
    print("=== Architecture Detection Demo ===\n")
    
    try:
        # 1. Basic architecture detection
        print("1. Detecting cluster architecture...")
        arch = get_node_architecture()
        print(f"   Detected architecture: {arch}\n")
        
        # 2. Comprehensive cluster info
        print("2. Getting detailed cluster architecture info...")
        arch_info = get_cluster_architecture_info()
        print(f"   Primary architecture: {arch_info['primary_architecture']}")
        print(f"   Worker architectures: {arch_info['worker_architectures']}")
        print(f"   Master architectures: {arch_info['master_architectures']}")
        print(f"   Mixed architecture cluster: {arch_info['mixed_architecture']}")
        print(f"   Total nodes: {len(arch_info['node_details'])}\n")
        
        # 3. Instance type compatibility
        print("3. Testing instance type compatibility...")
        original_instance = "m5.2xlarge"
        compatible_instance = get_arch_compatible_instance_type(original_instance)
        print(f"   Original: {original_instance}")
        print(f"   Compatible for {arch}: {compatible_instance}\n")
        
        # 4. Mixed architecture check
        print("4. Checking for mixed architecture...")
        is_mixed = is_mixed_architecture_cluster()
        print(f"   Mixed architecture cluster: {is_mixed}\n")
        
        # 5. Architecture-specific images (placeholder)
        print("5. Getting architecture-specific images...")
        base_images = {
            "ray": "quay.io/modh/ray:2.47.1-py312",
            "training": "quay.io/modh/training:py311-cuda121"
        }
        arch_images = get_architecture_specific_images(base_images)
        print(f"   Images for {arch}:")
        for name, image in arch_images.items():
            print(f"     {name}: {image}")
        
    except Exception as e:
        print(f"Error: {e}")
        print("\nThis is expected if you're not running in an OpenShift cluster environment.")


def robot_framework_integration_example():
    """
    Example of how to integrate this into Robot Framework tests
    
    This function shows the pattern you can use in your .robot files
    or Python libraries used by Robot Framework.
    """
    
    print("\n=== Robot Framework Integration Example ===\n")
    
    try:
        # Get the cluster architecture
        cluster_arch = get_node_architecture()
        
        # Use architecture-aware instance selection for GPU provisioning
        default_gpu_instance = "g4dn.xlarge"  # x86_64 default
        gpu_instance = get_arch_compatible_instance_type(default_gpu_instance, cluster_arch)
        
        print(f"Robot Framework Variable Setup:")
        print(f"   Set Suite Variable    ${{CLUSTER_ARCHITECTURE}}    {cluster_arch}")
        print(f"   Set Suite Variable    ${{GPU_INSTANCE_TYPE}}       {gpu_instance}")
        
        # Example of conditional logic based on architecture
        if cluster_arch == "arm64":
            print(f"   # ARM64-specific configurations")
            print(f"   Set Suite Variable    ${{NFD_CONFIG}}           nfd-arm64.yaml")
            print(f"   Set Suite Variable    ${{GPU_OPERATOR}}         arm64-gpu-operator")
        else:
            print(f"   # x86_64 configurations")  
            print(f"   Set Suite Variable    ${{NFD_CONFIG}}           nfd-x86_64.yaml")
            print(f"   Set Suite Variable    ${{GPU_OPERATOR}}         standard-gpu-operator")
            
    except RuntimeError as e:
        print(f"   # Fallback when architecture detection fails")
        print(f"   Set Suite Variable    ${{CLUSTER_ARCHITECTURE}}    x86_64")
        print(f"   Log    Architecture detection failed: {e}    WARN")


def provisioning_script_integration():
    """
    Example of how to integrate this into provisioning scripts
    """
    
    print("\n=== Provisioning Script Integration Example ===\n")
    
    try:
        # Auto-detect and provision compatible resources
        arch = get_node_architecture()
        
        # GPU provisioning example
        if arch == "arm64":
            gpu_instance_types = ["g5g.xlarge", "g5g.2xlarge"]  # Graviton2 + GPU
            print(f"ARM64 cluster detected - using Graviton2 GPU instances: {gpu_instance_types}")
        else:
            gpu_instance_types = ["g4dn.xlarge", "g4dn.2xlarge"]  # x86_64 GPU instances
            print(f"x86_64 cluster detected - using standard GPU instances: {gpu_instance_types}")
        
        # Mixed architecture handling
        if is_mixed_architecture_cluster():
            print("WARNING: Mixed architecture cluster detected!")
            print("Consider using node selectors to target specific architectures.")
            
            arch_info = get_cluster_architecture_info()
            for node in arch_info['node_details']:
                print(f"  Node {node['name']}: {node['architecture']} ({', '.join(node['roles'])})")
                
    except RuntimeError as e:
        print(f"Could not detect architecture, using defaults: {e}")


if __name__ == "__main__":
    main()
    robot_framework_integration_example()
    provisioning_script_integration()
