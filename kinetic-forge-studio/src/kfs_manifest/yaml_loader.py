import sys
from pathlib import Path
from typing import Any, Dict, Optional, Union

import yaml


def load_kfs_yaml(
    file_path: Union[str, Path]
) -> Optional[Dict[str, Any]]:
    """
    Safely loads and parses a YAML file into a Python dictionary.

    Args:
        file_path: The path to the YAML file.

    Returns:
        A dictionary representing the YAML content if successful, otherwise None.
        Returns None if the file is not found, cannot be read, or is malformed YAML.
    """
    path = Path(file_path)

    if not path.is_file():
        print(f"Error: File not found at {path}")
        return None

    try:
        with open(path, 'r', encoding='utf-8') as f:
            data = yaml.safe_load(f)
            return data if isinstance(data, dict) else {}
    except FileNotFoundError:
        print(f"Error: File not found at {path}")
        return None
    except IOError as e:
        print(f"Error reading file {path}: {e}")
        return None
    except yaml.YAMLError as e:
        error_type = type(e).__name__
        print(f"Error parsing YAML from {path} ({error_type} - parser error): {e}")
        return None
    except Exception as e:
        print(f"An unexpected error occurred while loading YAML from {path}: {e}")
        return None
