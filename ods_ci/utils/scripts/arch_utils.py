"""
Architecture utilities for ARM64/x86_64 compatibility
"""
import subprocess
import logging
import json
from typing import Dict, List, Optional, Tuple, Any
from functools import lru_cache

AWS_INSTANCE_MAPPINGS = {
    "x86_64": {
        "general": ["m5.large", "m5.xlarge", "m5.2xlarge", "m5.4xlarge"],
        "memory": ["r5.large", "r5.xlarge", "r5.2xlarge"],
        "gpu": ["g4dn.xlarge", "g4dn.2xlarge", "p3.2xlarge"],
        "compute": ["c5.large", "c5.xlarge", "c5.2xlarge"]
    },
    "arm64": {
        "general": ["m6g.large", "m6g.xlarge", "m6g.2xlarge", "m6g.4xlarge"], 
        "memory": ["r6g.large", "r6g.xlarge", "r6g.2xlarge"],
        "gpu": ["g5g.xlarge", "g5g.2xlarge"],
        "compute": ["c6g.large", "c6g.xlarge", "c6g.2xlarge"]
    }
}

def get_compatible_instance_type(instance_type: str, target_arch: str) -> str:
    """Map x86_64 instance types to ARM64 equivalents"""
    if target_arch == "x86_64":
        return instance_type
        
    # Mapping logic for common instance types
    mappings = {
        "m5.large": "m6g.large",
        "m5.xlarge": "m6g.xlarge", 
        "m5.2xlarge": "m6g.2xlarge",
        "g4dn.xlarge": "g5g.xlarge",
        # Add more mappings as needed
    }
    
    return mappings.get(instance_type, instance_type)

def validate_architecture_support(arch: str, provider: str = "aws") -> bool:
    """Validate that architecture is supported"""
    supported_archs = ["x86_64", "arm64", "aarch64"]
    return arch.lower() in [a.lower() for a in supported_archs]


# Architecture Detection Functions

@lru_cache(maxsize=1)
def get_node_architecture() -> str:
    """
    Detect the cluster's worker node architecture
    
    Returns:
        str: Architecture string ('x86_64', 'arm64', etc.)
    
    Raises:
        RuntimeError: If unable to detect architecture
    """
    try:
        # Get the first worker node's architecture
        result = subprocess.run(
            ['oc', 'get', 'nodes', '-l', 'node-role.kubernetes.io/worker', 
             '-o', 'jsonpath="{.items[0].status.nodeInfo.architecture}"'],
            capture_output=True, 
            text=True, 
            timeout=30
        )
        
        if result.returncode == 0 and result.stdout.strip():
            arch = result.stdout.strip().strip('"')
            logging.info(f"Detected cluster architecture: {arch}")
            return arch
        else:
            # Fallback: try to get any node's architecture
            result = subprocess.run(
                ['oc', 'get', 'nodes', '-o', 'jsonpath="{.items[0].status.nodeInfo.architecture}"'],
                capture_output=True,
                text=True,
                timeout=30
            )
            if result.returncode == 0 and result.stdout.strip():
                arch = result.stdout.strip().strip('"')
                logging.warning(f"Detected architecture from master node (no workers found): {arch}")
                return arch
            
        raise RuntimeError(f"Failed to detect architecture. oc command failed: {result.stderr}")
        
    except subprocess.TimeoutExpired:
        raise RuntimeError("Timeout while trying to detect cluster architecture")
    except FileNotFoundError:
        raise RuntimeError("oc command not found. Please ensure OpenShift CLI is installed")
    except Exception as e:
        raise RuntimeError(f"Error detecting cluster architecture: {e}")


def get_cluster_architecture_info() -> Dict[str, Any]:
    """
    Get comprehensive cluster architecture information
    
    Returns:
        Dict containing architecture details for all node types
    """
    try:
        # Get all nodes with their architecture and role information
        result = subprocess.run([
            'oc', 'get', 'nodes', '-o', 'json'
        ], capture_output=True, text=True, timeout=30)
        
        if result.returncode != 0:
            raise RuntimeError(f"Failed to get node information: {result.stderr}")
            
        nodes_data = json.loads(result.stdout)
        
        arch_info = {
            "master_architectures": set(),
            "worker_architectures": set(), 
            "all_architectures": set(),
            "mixed_architecture": False,
            "node_details": []
        }
        
        for node in nodes_data.get("items", []):
            node_name = node["metadata"]["name"]
            arch = node["status"]["nodeInfo"]["architecture"]
            labels = node["metadata"].get("labels", {})
            
            arch_info["all_architectures"].add(arch)
            
            # Determine node role
            roles = []
            if "node-role.kubernetes.io/control-plane" in labels or "node-role.kubernetes.io/master" in labels:
                roles.append("master")
                arch_info["master_architectures"].add(arch)
            if "node-role.kubernetes.io/worker" in labels:
                roles.append("worker") 
                arch_info["worker_architectures"].add(arch)
            
            arch_info["node_details"].append({
                "name": node_name,
                "architecture": arch,
                "roles": roles if roles else ["unknown"]
            })
        
        # Convert sets to lists for JSON serialization
        arch_info["master_architectures"] = list(arch_info["master_architectures"])
        arch_info["worker_architectures"] = list(arch_info["worker_architectures"])
        arch_info["all_architectures"] = list(arch_info["all_architectures"])
        
        # Check if cluster has mixed architectures
        arch_info["mixed_architecture"] = len(arch_info["all_architectures"]) > 1
        
        # Set primary architecture (most common among workers, fallback to masters)
        if arch_info["worker_architectures"]:
            arch_info["primary_architecture"] = arch_info["worker_architectures"][0]
        elif arch_info["master_architectures"]:
            arch_info["primary_architecture"] = arch_info["master_architectures"][0]
        else:
            arch_info["primary_architecture"] = "unknown"
            
        logging.info(f"Cluster architecture info: {arch_info}")
        return arch_info
        
    except json.JSONDecodeError as e:
        raise RuntimeError(f"Failed to parse node information JSON: {e}")
    except subprocess.TimeoutExpired:
        raise RuntimeError("Timeout while getting cluster architecture information")
    except Exception as e:
        raise RuntimeError(f"Error getting cluster architecture info: {e}")


def get_arch_compatible_instance_type(instance_type: str, target_arch: Optional[str] = None) -> str:
    """
    Get architecture-compatible instance type, auto-detecting cluster architecture if needed
    
    Args:
        instance_type: Original instance type
        target_arch: Target architecture (if None, auto-detect from cluster)
        
    Returns:
        str: Compatible instance type for the target architecture
    """
    if target_arch is None:
        try:
            target_arch = get_node_architecture()
        except RuntimeError as e:
            logging.warning(f"Could not auto-detect architecture ({e}), defaulting to x86_64")
            target_arch = "x86_64"
    
    return get_compatible_instance_type(instance_type, target_arch)


def is_mixed_architecture_cluster() -> bool:
    """
    Check if the cluster has mixed architectures
    
    Returns:
        bool: True if cluster has nodes with different architectures
    """
    try:
        arch_info = get_cluster_architecture_info()
        return arch_info["mixed_architecture"]
    except RuntimeError:
        return False


def get_architecture_specific_images(base_images: Dict[str, str], arch: Optional[str] = None) -> Dict[str, str]:
    """
    Get architecture-specific container images
    
    Args:
        base_images: Dictionary of image names to base image URLs
        arch: Target architecture (if None, auto-detect)
        
    Returns:
        Dict of image names to architecture-specific image URLs
        
    Note: This is a placeholder for future implementation when multi-arch images are available
    """
    if arch is None:
        try:
            arch = get_node_architecture()
        except RuntimeError:
            arch = "x86_64"
    
    # For now, return the base images as-is
    # In the future, this could map to architecture-specific image variants
    logging.info(f"Using base images for architecture: {arch}")
    return base_images.copy()