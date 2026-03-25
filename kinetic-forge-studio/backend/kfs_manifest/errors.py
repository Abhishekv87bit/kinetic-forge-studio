class KFSManifestError(Exception):
    """Base exception for KFS Manifest system errors."""
    pass


class ManifestParsingError(KFSManifestError):
    """Exception raised for errors during manifest file parsing.

    Attributes:
        message (str): Explanation of the error.
        file_path (str, optional): The path to the manifest file that caused the error.
    """

    def __init__(self, message: str, file_path: str | None = None) -> None:
        super().__init__(message)
        self.message = message
        self.file_path = file_path

    def __str__(self) -> str:
        if self.file_path:
            return f"Manifest Parsing Error in '{self.file_path}': {self.message}"
        return f"Manifest Parsing Error: {self.message}"


class ManifestValidationError(KFSManifestError):
    """Exception raised for errors during manifest data validation.

    Attributes:
        message (str): Explanation of the error.
        errors (list[dict], optional): A list of validation error details, e.g., from Pydantic.
        file_path (str, optional): The path to the manifest file that caused the error.
    """

    def __init__(self, message: str, errors: list[dict] | None = None, file_path: str | None = None) -> None:
        super().__init__(message)
        self.message = message
        self.errors = errors if errors is not None else []
        self.file_path = file_path

    def __str__(self) -> str:
        error_details = f"\nValidation Errors: {self.errors}" if self.errors else ""
        if self.file_path:
            return f"Manifest Validation Error in '{self.file_path}': {self.message}{error_details}"
        return f"Manifest Validation Error: {self.message}{error_details}"


class AssetResolutionError(KFSManifestError):
    """Exception raised when an asset referenced in the manifest cannot be resolved."""

    def __init__(self, message: str, asset_ref: str | None = None) -> None:
        super().__init__(message)
        self.message = message
        self.asset_ref = asset_ref

    def __str__(self) -> str:
        if self.asset_ref:
            return f"Asset Resolution Error for '{self.asset_ref}': {self.message}"
        return f"Asset Resolution Error: {self.message}"

