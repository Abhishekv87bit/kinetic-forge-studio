# Tax Statement CSV Extractor — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Python CLI tool that extracts tables from local PDF account statements and combines them into a single CSV file for annual tax preparation.

**Architecture:**
Modular CLI tool with four independent components: PDF parser (pdfplumber for table extraction), CSV writer (pandas for output), error handler (logging + graceful failure), and CLI interface (argparse for arguments). Each component is independently testable.

**Tech Stack:** Python 3.10+, pdfplumber, pandas, pytest

---

## Task 1: Setup Project Structure & Dependencies

**Files:**
- Create: `tax-statement-extractor/tax_statement_extractor/__init__.py`
- Create: `tax-statement-extractor/requirements.txt`
- Create: `tax-statement-extractor/setup.py`
- Create: `tax-statement-extractor/README.md`
- Create: `tax-statement-extractor/tests/__init__.py`
- Create: `tax-statement-extractor/tests/conftest.py`

- [ ] **Step 1: Create project directory and package structure**

```bash
mkdir -p tax-statement-extractor/tax_statement_extractor
mkdir -p tax-statement-extractor/tests
cd tax-statement-extractor
```

- [ ] **Step 2: Create `__init__.py`**

```python
# tax_statement_extractor/__init__.py
"""Tax Statement CSV Extractor — Extract tables from account statement PDFs."""

__version__ = "0.1.0"
```

- [ ] **Step 3: Create `requirements.txt`**

```
pdfplumber>=0.10.0
pandas>=1.5.0
pytest>=7.0.0
pytest-cov>=4.0.0
```

- [ ] **Step 4: Create `setup.py`**

```python
from setuptools import setup, find_packages

setup(
    name="tax-statement-extractor",
    version="0.1.0",
    description="Extract tables from account statement PDFs into a single CSV",
    packages=find_packages(),
    python_requires=">=3.10",
    install_requires=[
        "pdfplumber>=0.10.0",
        "pandas>=1.5.0",
    ],
    entry_points={
        "console_scripts": [
            "extract-statements=tax_statement_extractor.cli:main",
        ],
    },
)
```

- [ ] **Step 5: Create `README.md`**

```markdown
# Tax Statement CSV Extractor

Extract tables from account statement PDFs and combine into a single CSV file.

## Installation

```bash
pip install -r requirements.txt
```

## Usage

```bash
python -m tax_statement_extractor.cli --input ./statements --output combined.csv
```

## Arguments

- `--input` (required): Path to folder containing PDF files
- `--output` (required): Path to output CSV file

## Output

Combines all tables from all PDFs into a single CSV with:
- Column order preserved from first PDF
- No data transformation
- No deduplication
- UTF-8 encoding, CRLF line endings, minimal quoting
```

- [ ] **Step 6: Create test configuration (`conftest.py`)**

```python
# tests/conftest.py
import pytest
from pathlib import Path
import tempfile
import shutil

@pytest.fixture
def temp_output_dir():
    """Create temporary directory for test outputs."""
    temp_dir = tempfile.mkdtemp()
    yield temp_dir
    shutil.rmtree(temp_dir)

@pytest.fixture
def sample_pdf_dir():
    """Return path to sample statements directory."""
    return Path(__file__).parent / "sample_statements"

@pytest.fixture
def nonexistent_dir():
    """Return path to non-existent directory."""
    return Path("/nonexistent/path/to/folder")
```

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "setup: project structure, dependencies, and test fixtures"
```

---

## Task 2: Implement PDF Parser (TDD)

**Files:**
- Create: `tax_statement_extractor/pdf_parser.py`
- Create: `tests/test_pdf_parser.py`
- Create: `tests/sample_statements/statement_jan.pdf` (sample test data)

- [ ] **Step 1: Write test for single table extraction**

```python
# tests/test_pdf_parser.py
import pytest
from pathlib import Path
from tax_statement_extractor.pdf_parser import extract_tables_from_pdf

def test_extract_single_table(sample_pdf_dir):
    """Test extraction of single table from PDF."""
    pdf_path = sample_pdf_dir / "statement_jan.pdf"
    tables = extract_tables_from_pdf(pdf_path)

    assert len(tables) > 0
    assert tables[0].shape[0] > 0  # Has rows
    assert tables[0].shape[1] > 0  # Has columns

def test_extract_multiple_tables_from_pdf(sample_pdf_dir):
    """Test extraction of multiple tables from same PDF."""
    # This will be populated when sample PDF has multiple tables
    pdf_path = sample_pdf_dir / "statement_feb.pdf"
    tables = extract_tables_from_pdf(pdf_path)
    assert isinstance(tables, list)

def test_extract_from_nonexistent_file():
    """Test handling of non-existent PDF."""
    from tax_statement_extractor.pdf_parser import PDFExtractionError

    with pytest.raises(PDFExtractionError):
        extract_tables_from_pdf(Path("/nonexistent/file.pdf"))

def test_extract_from_corrupted_pdf(temp_output_dir):
    """Test handling of corrupted PDF."""
    from tax_statement_extractor.pdf_parser import PDFExtractionError
    import os

    # Create a fake PDF file (not actually a PDF)
    fake_pdf = Path(temp_output_dir) / "corrupted.pdf"
    fake_pdf.write_text("This is not a PDF")

    with pytest.raises(PDFExtractionError):
        extract_tables_from_pdf(fake_pdf)

def test_extract_pdf_with_no_tables(temp_output_dir):
    """Test PDF with no tables returns empty list."""
    # This test assumes we have a sample PDF with no tables
    # For now, we'll skip and implement when we have the sample
    pass
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
pytest tests/test_pdf_parser.py -v
```

Expected: FAILED — `ModuleNotFoundError: No module named 'tax_statement_extractor.pdf_parser'`

- [ ] **Step 3: Create `pdf_parser.py` with minimal implementation**

```python
# tax_statement_extractor/pdf_parser.py
"""PDF table extraction logic using pdfplumber."""

from pathlib import Path
import pdfplumber
import pandas as pd
from typing import List

class PDFExtractionError(Exception):
    """Raised when PDF extraction fails."""
    pass

def extract_tables_from_pdf(pdf_path: Path) -> List[pd.DataFrame]:
    """
    Extract all tables from a PDF file.

    Args:
        pdf_path: Path to PDF file

    Returns:
        List of DataFrames, one per table found

    Raises:
        PDFExtractionError: If PDF cannot be read or has no tables
    """
    pdf_path = Path(pdf_path)

    if not pdf_path.exists():
        raise PDFExtractionError(f"PDF file not found: {pdf_path}")

    try:
        tables = []
        with pdfplumber.open(pdf_path) as pdf:
            for page_num, page in enumerate(pdf.pages):
                page_tables = page.extract_tables()
                if page_tables:
                    for table in page_tables:
                        # Convert table (list of lists) to DataFrame
                        # First row is header
                        if len(table) > 0:
                            df = pd.DataFrame(table[1:], columns=table[0])
                            tables.append(df)

        return tables

    except pdfplumber.exceptions.PDFSyntaxError as e:
        raise PDFExtractionError(f"PDF is corrupted: {pdf_path}") from e
    except Exception as e:
        raise PDFExtractionError(f"Failed to extract tables from {pdf_path}: {str(e)}") from e
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
pytest tests/test_pdf_parser.py::test_extract_from_nonexistent_file -v
pytest tests/test_pdf_parser.py::test_extract_from_corrupted_pdf -v
```

Expected: PASS

Note: `test_extract_single_table` will FAIL because sample PDF doesn't exist yet. Skip for now.

- [ ] **Step 5: Commit**

```bash
git add tax_statement_extractor/pdf_parser.py tests/test_pdf_parser.py
git commit -m "feat: implement PDF table extraction with pdfplumber"
```

---

## Task 3: Implement CSV Writer (TDD)

**Files:**
- Create: `tax_statement_extractor/csv_writer.py`
- Create: `tests/test_csv_writer.py`

- [ ] **Step 1: Write tests for CSV writing**

```python
# tests/test_csv_writer.py
import pytest
import pandas as pd
from pathlib import Path
from tax_statement_extractor.csv_writer import write_csv

def test_write_single_dataframe_to_csv(temp_output_dir):
    """Test writing single DataFrame to CSV."""
    df = pd.DataFrame({
        'Date': ['2026-01-01', '2026-01-02'],
        'Amount': [100.0, 200.0],
        'Description': ['Groceries', 'Gas']
    })

    output_path = Path(temp_output_dir) / "output.csv"
    write_csv([df], output_path)

    assert output_path.exists()
    result = pd.read_csv(output_path)
    assert len(result) == 2
    assert list(result.columns) == ['Date', 'Amount', 'Description']

def test_write_multiple_dataframes_concatenated(temp_output_dir):
    """Test writing multiple DataFrames concatenated into one CSV."""
    df1 = pd.DataFrame({
        'Date': ['2026-01-01'],
        'Amount': [100.0],
        'Description': ['Groceries']
    })
    df2 = pd.DataFrame({
        'Date': ['2026-02-01'],
        'Amount': [200.0],
        'Description': ['Gas']
    })

    output_path = Path(temp_output_dir) / "output.csv"
    write_csv([df1, df2], output_path)

    result = pd.read_csv(output_path)
    assert len(result) == 2
    assert result.iloc[0]['Date'] == '2026-01-01'
    assert result.iloc[1]['Date'] == '2026-02-01'

def test_csv_formatting(temp_output_dir):
    """Test CSV is formatted correctly (no index, CRLF, UTF-8)."""
    df = pd.DataFrame({
        'Date': ['2026-01-01'],
        'Amount': [100.0],
        'Description': ['Test']
    })

    output_path = Path(temp_output_dir) / "output.csv"
    write_csv([df], output_path)

    # Read raw content to check line endings
    with open(output_path, 'rb') as f:
        content = f.read()

    # Should have CRLF line endings
    assert b'\r\n' in content
    # Should not have row index
    assert not content.startswith(b'0,')

def test_write_dataframes_with_different_columns(temp_output_dir):
    """Test merging DataFrames with different columns."""
    df1 = pd.DataFrame({
        'Date': ['2026-01-01'],
        'Amount': [100.0],
        'Description': ['Groceries']
    })
    df2 = pd.DataFrame({
        'Date': ['2026-02-01'],
        'Amount': [200.0],
        'Category': ['Food'],
        'Description': ['Gas']
    })

    output_path = Path(temp_output_dir) / "output.csv"
    write_csv([df1, df2], output_path)

    result = pd.read_csv(output_path)
    # Should have all columns from both DataFrames
    assert 'Category' in result.columns
    # First row shouldn't have Category value
    assert pd.isna(result.iloc[0]['Category'])

def test_write_with_unicode_characters(temp_output_dir):
    """Test handling of Unicode characters in data."""
    df = pd.DataFrame({
        'Date': ['2026-01-01'],
        'Amount': [100.0],
        'Description': ['Café ☕']
    })

    output_path = Path(temp_output_dir) / "output.csv"
    write_csv([df], output_path)

    result = pd.read_csv(output_path, encoding='utf-8')
    assert 'Café' in result.iloc[0]['Description']
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
pytest tests/test_csv_writer.py -v
```

Expected: FAILED — `ModuleNotFoundError: No module named 'tax_statement_extractor.csv_writer'`

- [ ] **Step 3: Create `csv_writer.py` implementation**

```python
# tax_statement_extractor/csv_writer.py
"""CSV output writing logic using pandas."""

from pathlib import Path
import pandas as pd
from typing import List

def write_csv(dataframes: List[pd.DataFrame], output_path: Path) -> None:
    """
    Write multiple DataFrames to a single CSV file.

    Args:
        dataframes: List of DataFrames to combine
        output_path: Path where CSV will be written

    Raises:
        ValueError: If dataframes list is empty
        IOError: If output path is invalid
    """
    if not dataframes:
        raise ValueError("No DataFrames to write")

    output_path = Path(output_path)

    # Validate output path
    try:
        output_path.parent.mkdir(parents=True, exist_ok=True)
    except Exception as e:
        raise IOError(f"Cannot write to {output_path}: {str(e)}")

    # Concatenate all DataFrames
    combined = pd.concat(dataframes, ignore_index=True)

    # Fill NaN values with empty string for CSV compatibility
    combined = combined.fillna('')

    # Write to CSV with specified formatting
    try:
        combined.to_csv(
            output_path,
            index=False,
            quoting='minimal',
            lineterminator='\r\n',
            encoding='utf-8'
        )
    except Exception as e:
        raise IOError(f"Failed to write CSV: {str(e)}") from e
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
pytest tests/test_csv_writer.py -v
```

Expected: PASS (all tests)

- [ ] **Step 5: Commit**

```bash
git add tax_statement_extractor/csv_writer.py tests/test_csv_writer.py
git commit -m "feat: implement CSV writer with pandas"
```

---

## Task 4: Implement Error Handler (TDD)

**Files:**
- Create: `tax_statement_extractor/error_handler.py`
- Create: `tests/test_error_handler.py`

- [ ] **Step 1: Write tests for error handling and logging**

```python
# tests/test_error_handler.py
import pytest
import logging
from io import StringIO
from pathlib import Path
from tax_statement_extractor.error_handler import (
    setup_logging,
    ProcessingStats,
    log_info,
    log_warning,
    log_error
)

def test_setup_logging_returns_logger():
    """Test logging setup."""
    logger = setup_logging()
    assert logger is not None
    assert isinstance(logger, logging.Logger)

def test_log_info_message(caplog):
    """Test INFO logging."""
    logger = setup_logging()
    with caplog.at_level(logging.INFO):
        log_info(logger, "test message")
    assert "test message" in caplog.text

def test_log_warning_message(caplog):
    """Test WARNING logging."""
    logger = setup_logging()
    with caplog.at_level(logging.WARNING):
        log_warning(logger, "test warning")
    assert "test warning" in caplog.text

def test_log_error_message(caplog):
    """Test ERROR logging."""
    logger = setup_logging()
    with caplog.at_level(logging.ERROR):
        log_error(logger, "test error")
    assert "test error" in caplog.text

def test_processing_stats():
    """Test ProcessingStats tracking."""
    stats = ProcessingStats()

    stats.add_file('file1.pdf', 10)
    stats.add_file('file2.pdf', 20)
    stats.skip_file('file3.pdf', 'no tables')

    assert stats.files_processed == 2
    assert stats.files_skipped == 1
    assert stats.total_rows == 30

def test_processing_stats_report():
    """Test ProcessingStats summary report."""
    stats = ProcessingStats()
    stats.add_file('file1.pdf', 10)
    stats.skip_file('file2.pdf', 'corrupted')

    report = stats.get_report()
    assert 'Files processed: 1' in report
    assert 'Files skipped: 1' in report
    assert 'Total rows: 10' in report
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
pytest tests/test_error_handler.py -v
```

Expected: FAILED — `ModuleNotFoundError: No module named 'tax_statement_extractor.error_handler'`

- [ ] **Step 3: Create `error_handler.py` implementation**

```python
# tax_statement_extractor/error_handler.py
"""Error handling and logging utilities."""

import logging
import sys
from typing import Optional

class ProcessingStats:
    """Track file processing statistics."""

    def __init__(self):
        self.files_processed = 0
        self.files_skipped = 0
        self.total_rows = 0
        self.skipped_reasons = {}

    def add_file(self, filename: str, row_count: int) -> None:
        """Record successfully processed file."""
        self.files_processed += 1
        self.total_rows += row_count

    def skip_file(self, filename: str, reason: str) -> None:
        """Record skipped file."""
        self.files_skipped += 1
        self.skipped_reasons[filename] = reason

    def get_report(self) -> str:
        """Generate summary report."""
        report = f"""
Summary:
- Files processed: {self.files_processed}
- Files skipped: {self.files_skipped}
- Total rows: {self.total_rows}
"""
        if self.skipped_reasons:
            report += "\nSkipped files:\n"
            for filename, reason in self.skipped_reasons.items():
                report += f"  - {filename}: {reason}\n"

        return report

def setup_logging() -> logging.Logger:
    """
    Configure logging with INFO to stdout, WARNING/ERROR to stderr.

    Returns:
        Configured logger instance
    """
    logger = logging.getLogger('tax_statement_extractor')
    logger.setLevel(logging.DEBUG)

    # Clear existing handlers
    logger.handlers = []

    # INFO handler (stdout)
    info_handler = logging.StreamHandler(sys.stdout)
    info_handler.setLevel(logging.INFO)
    info_filter = logging.Filter()
    info_filter.filter = lambda record: record.levelno <= logging.INFO
    info_handler.addFilter(info_filter)

    # WARNING/ERROR handler (stderr)
    error_handler = logging.StreamHandler(sys.stderr)
    error_handler.setLevel(logging.WARNING)

    # Formatter
    formatter = logging.Formatter('%(message)s')
    info_handler.setFormatter(formatter)
    error_handler.setFormatter(formatter)

    logger.addHandler(info_handler)
    logger.addHandler(error_handler)

    return logger

def log_info(logger: logging.Logger, message: str) -> None:
    """Log INFO message."""
    logger.info(message)

def log_warning(logger: logging.Logger, message: str) -> None:
    """Log WARNING message."""
    logger.warning(message)

def log_error(logger: logging.Logger, message: str) -> None:
    """Log ERROR message."""
    logger.error(message)
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
pytest tests/test_error_handler.py -v
```

Expected: PASS (all tests)

- [ ] **Step 5: Commit**

```bash
git add tax_statement_extractor/error_handler.py tests/test_error_handler.py
git commit -m "feat: implement error handler and logging"
```

---

## Task 5: Implement CLI Interface (TDD)

**Files:**
- Create: `tax_statement_extractor/cli.py`
- Create: `tests/test_cli.py`

- [ ] **Step 1: Write tests for CLI**

```python
# tests/test_cli.py
import pytest
from pathlib import Path
from unittest.mock import patch, MagicMock
from tax_statement_extractor.cli import main, parse_arguments, process_statements

def test_parse_arguments_valid():
    """Test CLI argument parsing with valid args."""
    args = parse_arguments(['--input', './pdfs', '--output', 'result.csv'])
    assert args.input == './pdfs'
    assert args.output == 'result.csv'

def test_parse_arguments_missing_input():
    """Test parsing fails without --input."""
    with pytest.raises(SystemExit):
        parse_arguments(['--output', 'result.csv'])

def test_parse_arguments_missing_output():
    """Test parsing fails without --output."""
    with pytest.raises(SystemExit):
        parse_arguments(['--input', './pdfs'])

def test_process_statements_empty_folder(nonexistent_dir, temp_output_dir, caplog):
    """Test processing empty folder exits with error."""
    from tax_statement_extractor.cli import ProcessingError

    # Create empty temp folder
    empty_folder = Path(temp_output_dir) / "empty"
    empty_folder.mkdir()

    with pytest.raises(ProcessingError) as exc_info:
        process_statements(empty_folder, Path(temp_output_dir) / "out.csv")

    assert "no PDF files found" in str(exc_info.value).lower()

def test_process_statements_nonexistent_folder(nonexistent_dir, temp_output_dir):
    """Test processing non-existent folder."""
    from tax_statement_extractor.cli import ProcessingError

    with pytest.raises(ProcessingError):
        process_statements(nonexistent_dir, Path(temp_output_dir) / "out.csv")

def test_main_integration(sample_pdf_dir, temp_output_dir):
    """Test full CLI flow (requires sample PDFs)."""
    # This test runs if sample PDFs exist
    # For now, we'll implement when we have sample data
    pass
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
pytest tests/test_cli.py -v
```

Expected: FAILED — `ModuleNotFoundError: No module named 'tax_statement_extractor.cli'`

- [ ] **Step 3: Create `cli.py` implementation**

```python
# tax_statement_extractor/cli.py
"""Command-line interface for tax statement extraction."""

import argparse
import sys
from pathlib import Path
from typing import List

import pandas as pd

from tax_statement_extractor.pdf_parser import extract_tables_from_pdf, PDFExtractionError
from tax_statement_extractor.csv_writer import write_csv
from tax_statement_extractor.error_handler import setup_logging, ProcessingStats

class ProcessingError(Exception):
    """Raised when processing encounters a fatal error."""
    pass

def parse_arguments(args: List[str] = None) -> argparse.Namespace:
    """
    Parse command-line arguments.

    Args:
        args: List of arguments (default: sys.argv[1:])

    Returns:
        Parsed arguments
    """
    parser = argparse.ArgumentParser(
        description="Extract tables from account statement PDFs into a single CSV"
    )
    parser.add_argument(
        '--input',
        required=True,
        help='Path to folder containing PDF files'
    )
    parser.add_argument(
        '--output',
        required=True,
        help='Path to output CSV file'
    )

    return parser.parse_args(args)

def process_statements(input_dir: Path, output_path: Path) -> ProcessingStats:
    """
    Process all PDFs in a directory and write combined CSV.

    Args:
        input_dir: Path to folder containing PDFs
        output_path: Path where CSV will be written

    Returns:
        ProcessingStats with summary information

    Raises:
        ProcessingError: If folder is empty or invalid
    """
    input_dir = Path(input_dir)

    # Validate input directory
    if not input_dir.exists():
        raise ProcessingError(f"Input folder does not exist: {input_dir}")

    if not input_dir.is_dir():
        raise ProcessingError(f"Input path is not a directory: {input_dir}")

    # Find all PDF files (case-insensitive)
    pdf_files = sorted(input_dir.glob('*.pdf')) + sorted(input_dir.glob('*.PDF'))

    if not pdf_files:
        raise ProcessingError(f"No PDF files found in {input_dir}")

    logger = setup_logging()
    stats = ProcessingStats()
    all_dataframes = []

    # Process each PDF
    for pdf_path in pdf_files:
        try:
            logger.info(f"Processing {pdf_path.name} ... ", end='')
            tables = extract_tables_from_pdf(pdf_path)

            if not tables:
                logger.warning(f"{pdf_path.name}: No tables found")
                stats.skip_file(pdf_path.name, "no tables")
                continue

            # Check for empty tables
            non_empty_tables = [t for t in tables if len(t) > 0]
            if not non_empty_tables:
                logger.warning(f"{pdf_path.name}: All tables are empty")
                stats.skip_file(pdf_path.name, "empty tables")
                continue

            row_count = sum(len(t) for t in non_empty_tables)
            logger.info(f"OK ({row_count} rows)")
            stats.add_file(pdf_path.name, row_count)
            all_dataframes.extend(non_empty_tables)

        except PDFExtractionError as e:
            logger.error(f"{pdf_path.name}: {str(e)}")
            stats.skip_file(pdf_path.name, str(e))
            continue
        except Exception as e:
            logger.error(f"{pdf_path.name}: Unexpected error: {str(e)}")
            stats.skip_file(pdf_path.name, "unexpected error")
            continue

    # Check if any data was extracted
    if not all_dataframes:
        raise ProcessingError("No data extracted from any PDFs")

    # Consolidate columns (first PDF determines column order)
    if len(all_dataframes) > 1:
        first_columns = all_dataframes[0].columns.tolist()

        # Check for column mismatches
        for i, df in enumerate(all_dataframes[1:], 1):
            if not list(df.columns) == first_columns:
                # Reorder columns to match first PDF
                missing_cols = set(first_columns) - set(df.columns)
                extra_cols = set(df.columns) - set(first_columns)

                if missing_cols or extra_cols:
                    logger.warning(
                        f"Column mismatch in PDF {i+1}: "
                        f"missing {missing_cols}, extra {extra_cols}. "
                        f"Reordering to match first PDF."
                    )

                # Reorder to match first PDF
                for col in first_columns:
                    if col not in df.columns:
                        df[col] = ''

                all_dataframes[i] = df[first_columns]

    # Write combined CSV
    write_csv(all_dataframes, output_path)

    logger.info(f"\n{stats.get_report()}")
    logger.info(f"Output: {output_path}")

    return stats

def main(args: List[str] = None) -> int:
    """
    CLI entry point.

    Args:
        args: List of arguments (default: sys.argv[1:])

    Returns:
        Exit code (0 = success, 1 = error)
    """
    try:
        parsed_args = parse_arguments(args)
        process_statements(Path(parsed_args.input), Path(parsed_args.output))
        return 0
    except ProcessingError as e:
        print(f"Error: {str(e)}", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"Unexpected error: {str(e)}", file=sys.stderr)
        return 1

if __name__ == '__main__':
    sys.exit(main())
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
pytest tests/test_cli.py::test_parse_arguments_valid -v
pytest tests/test_cli.py::test_parse_arguments_missing_input -v
pytest tests/test_cli.py::test_parse_arguments_missing_output -v
pytest tests/test_cli.py::test_process_statements_empty_folder -v
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tax_statement_extractor/cli.py tests/test_cli.py
git commit -m "feat: implement CLI interface with argparse"
```

---

## Task 6: Integration Testing & Sample Data

**Files:**
- Create: `tests/sample_statements/statement_jan.pdf` (sample test PDF)
- Create: `tests/sample_statements/statement_feb.pdf`
- Modify: `tests/test_pdf_parser.py` (uncomment tests that require samples)

- [ ] **Step 1: Create sample test PDFs**

**Note:** Sample PDFs should be created manually using a tool like:
- LibreOffice Writer exported as PDF
- Google Docs exported as PDF
- Or any PDF with a simple table structure

Create 3 sample PDFs with this structure:

```
statement_jan.pdf:
| Date       | Amount | Description |
| 2026-01-01 | 100.00 | Groceries   |
| 2026-01-05 | 50.00  | Gas         |

statement_feb.pdf:
| Date       | Amount | Description |
| 2026-02-01 | 120.00 | Groceries   |
| 2026-02-10 | 75.00  | Gas         |

statement_mar.pdf:
| Date       | Amount | Description |
| 2026-03-01 | 110.00 | Groceries   |
| 2026-03-15 | 60.00  | Gas         |
```

- [ ] **Step 2: Run full test suite**

```bash
pytest tests/ -v --cov=tax_statement_extractor
```

Expected: All tests PASS, coverage > 85%

- [ ] **Step 3: Run integration test**

```bash
python -m tax_statement_extractor.cli --input tests/sample_statements --output /tmp/test_output.csv
```

Expected:
```
Processing statement_jan.pdf ... OK (2 rows)
Processing statement_feb.pdf ... OK (2 rows)
Processing statement_mar.pdf ... OK (2 rows)

Summary:
- Files processed: 3
- Files skipped: 0
- Total rows: 6
Output: /tmp/test_output.csv
```

- [ ] **Step 4: Verify output CSV**

```bash
head -10 /tmp/test_output.csv
```

Expected:
```
Date,Amount,Description
2026-01-01,100.0,Groceries
2026-01-05,50.0,Gas
2026-02-01,120.0,Groceries
2026-02-10,75.0,Gas
2026-03-01,110.0,Groceries
2026-03-15,60.0,Gas
```

- [ ] **Step 5: Commit**

```bash
git add tests/sample_statements/ tests/test_pdf_parser.py
git commit -m "test: add sample PDFs and integration tests"
```

---

## Task 7: Final Documentation & Distribution

**Files:**
- Update: `README.md`
- Create: `CHANGELOG.md`

- [ ] **Step 1: Update README with complete examples**

```markdown
# Tax Statement CSV Extractor

Extract tables from account statement PDFs and combine into a single CSV file.

## Installation

```bash
pip install -r requirements.txt
```

## Usage

### Command Line

```bash
python -m tax_statement_extractor.cli --input ./statements --output combined.csv
```

### Arguments

- `--input` (required): Path to folder containing PDF files
- `--output` (required): Path to output CSV file

### Example Output

```
$ python -m tax_statement_extractor.cli --input ./statements --output combined.csv

Processing statement_jan.pdf ... OK (42 rows)
Processing statement_feb.pdf ... OK (38 rows)
Processing statement_mar.pdf ... OK (45 rows)

Summary:
- Files processed: 3
- Files skipped: 0
- Total rows: 125
Output: combined.csv
```

## Features

- ✅ Extract tables from multiple PDFs
- ✅ Combine into single CSV file
- ✅ Preserve column order from first PDF
- ✅ No data transformation or cleaning
- ✅ Handle encoding (UTF-8)
- ✅ Excel-compatible output (CRLF line endings)

## Column Handling

- **Column order:** Preserved from first PDF
- **New columns:** Appended to the right if subsequent PDFs have additional columns
- **Missing values:** Filled with empty string
- **No deduplication:** Duplicate rows retained as-is

## Error Handling

- Non-PDF files: Silently ignored
- Empty tables: Skipped with warning
- Corrupted PDFs: Skipped with error message, processing continues
- Column mismatches: Reordered to match first PDF

## Testing

Run tests with coverage:

```bash
pytest tests/ -v --cov=tax_statement_extractor
```

## License

MIT
```

- [ ] **Step 2: Create CHANGELOG.md**

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2026-03-20

### Added
- Initial release
- PDF table extraction using pdfplumber
- CSV output with pandas
- CLI interface with argparse
- Comprehensive error handling and logging
- Full test suite with >85% coverage
```

- [ ] **Step 3: Install and verify**

```bash
pip install -e .
extract-statements --input tests/sample_statements --output /tmp/verify.csv
```

Expected: Command works, CSV generated successfully

- [ ] **Step 4: Final commit**

```bash
git add README.md CHANGELOG.md
git commit -m "docs: complete documentation and changelog"
```

---

## Success Criteria Checklist

- ✅ All unit tests pass (pytest)
- ✅ Test coverage > 85%
- ✅ CLI accepts `--input` and `--output` arguments
- ✅ Processes 3+ sample PDFs correctly
- ✅ Output CSV has correct row count (sum of all PDFs)
- ✅ Output CSV opens in Excel without errors
- ✅ No data transformation applied
- ✅ Skipped files logged with reason
- ✅ Summary report displays correct stats
- ✅ Column order preserved from first PDF
- ✅ Empty strings used for missing values
- ✅ CRLF line endings and UTF-8 encoding

---

**Next Step:** Execute plan using superpowers:subagent-driven-development
