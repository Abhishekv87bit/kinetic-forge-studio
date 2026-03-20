# Annual Tax Statement CSV Extractor — Design Spec

**Date:** 2026-03-20
**Status:** Design Phase
**Purpose:** Extract tabular data from account statement PDFs and combine into single CSV for tax preparation

---

## 1. Overview

A Python CLI tool that processes multiple account statement PDFs from a local folder, extracts all table data, and writes to a single combined CSV file with zero transformation or deduplication.

**Use Case:** Annual tax preparation — user downloads all 12 months of account statements as PDFs, runs the tool once, gets combined CSV ready for tax software.

---

## 2. Requirements

### Functional
- Accept directory path containing PDF files
- Extract all tables from each PDF in order
- Concatenate all table rows into single output CSV
- Preserve column names and order exactly as they appear in PDFs
- Write output to specified CSV file
- Report row count per PDF for user verification

### Non-Functional
- **No data transformation:** Keep all values as-is (no cleaning, normalization, or formatting)
- **No deduplication:** If a transaction appears in multiple statements, include it multiple times
- **Error resilience:** Skip unreadable PDFs, continue processing, log warnings
- **Performance:** Handle 12-month yearly batch in <5 seconds

---

## 3. Architecture

### Components

#### PDF Parser
- Uses `pdfplumber` library to extract tables from PDFs
- Iterates through each page of each PDF
- Extracts all tables found (handles multiple tables per page)
- Returns list of DataFrames (one per table)

#### Column Consolidation
- Detects column structure from first PDF
- Verifies subsequent PDFs have same columns (warn if different)
- If columns differ, use union of all column names (fill missing cells with None)

#### CSV Writer
- Combines all DataFrames row-by-row
- Writes to output CSV with UTF-8 encoding
- Uses pandas `.to_csv()` for standard formatting

#### Error Handler
- Wraps PDF parsing in try-except
- Logs filename and error message for failed PDFs
- Continues to next file
- Reports summary at end: total files processed, files skipped, total rows extracted

### Data Flow
```
Input Folder
    ├── statement_jan.pdf ──┐
    ├── statement_feb.pdf ──┤
    └── statement_dec.pdf ──┤
                            ├──> PDF Parser (pdfplumber)
                            │    ├── Extract tables
                            │    └── Return DataFrames
                            ├──> Column Consolidation
                            │    └── Verify/merge columns
                            ├──> CSV Writer (pandas)
                            │    └── Concatenate rows
                            └──> combined_statements.csv
```

---

## 4. CLI Interface

### Command
```bash
python extract_statements.py --input <input_dir> --output <output_file>
```

### Arguments
- `--input` (required): Path to folder containing PDF files
- `--output` (required): Path to output CSV file

### Examples
```bash
python extract_statements.py --input ./tax_statements --output combined.csv
python extract_statements.py --input /home/user/Downloads/pdfs --output ~/tax_2026.csv
```

### Output
```
Processing tax_statements/jan.pdf ... OK (42 rows)
Processing tax_statements/feb.pdf ... OK (38 rows)
Processing tax_statements/mar.pdf ... OK (45 rows)
...
Processing tax_statements/dec.pdf ... OK (52 rows)

Summary:
- Files processed: 12
- Files skipped: 0
- Total rows: 525
- Output: combined.csv
```

---

## 5. Implementation Details

### Dependencies
```
pdfplumber>=0.10.0
pandas>=1.5.0
```

### File Structure
```
tax-statement-extractor/
├── extract_statements.py     # Main CLI entry point
├── pdf_parser.py             # PDF table extraction logic
├── csv_writer.py             # CSV output logic
├── error_handler.py          # Error logging/handling
├── requirements.txt          # Python dependencies
├── README.md                 # Usage instructions
└── tests/
    ├── sample_statements/    # Sample PDFs for testing
    └── test_extraction.py    # Unit tests
```

### Column Handling Strategy
1. **First PDF:** Read column names from first table, store as schema
2. **Subsequent PDFs:**
   - If columns match exactly: concatenate data directly
   - If columns differ: warn user, merge column sets (order preserved from first PDF, new columns appended)
3. **Missing values:** Fill with empty string or None (pandas default)

### Error Scenarios
| Scenario | Behavior |
|----------|----------|
| PDF has no tables | Skip, log warning, continue |
| PDF is corrupted/unreadable | Skip, log error, continue |
| PDF has different columns | Log warning, merge columns, continue |
| Input folder is empty | Exit with error message |
| Output path is invalid | Exit with error message |

---

## 6. Testing Strategy

### Unit Tests
- [ ] Extract single table from sample PDF
- [ ] Extract multiple tables from same PDF
- [ ] Concatenate multiple PDFs with identical columns
- [ ] Handle PDFs with different column sets
- [ ] Skip corrupted PDF, continue processing
- [ ] Generate valid CSV with correct row count

### Manual Verification
- [ ] Test with 3-month sample statements (Jan, Feb, Mar)
- [ ] Verify column order preserved
- [ ] Verify all rows included (count matches expected)
- [ ] Open output CSV in Excel, verify readability

---

## 7. Success Criteria

- ✅ CLI runs without errors on 12-month statement batch
- ✅ Output CSV contains all rows from all PDFs
- ✅ Column order matches first PDF
- ✅ No data transformation applied
- ✅ Skipped files logged with reason
- ✅ Summary report shows file count and row count
- ✅ Output CSV is valid and opens in Excel/Sheets

---

## 8. Future Enhancements (Out of Scope)

- Support for PDFs with non-table data (OCR extraction)
- Column name auto-mapping across different statement formats
- Deduplication by transaction signature
- Data validation rules
- Batch scheduling for monthly automatic extraction

---

## 9. Decision Log

| Decision | Rationale |
|----------|-----------|
| Use `pdfplumber` over PyPDF2 | pdfplumber excels at table extraction; PyPDF2 is better for text manipulation |
| Preserve column order exactly | Matches user requirement; simplifies logic; columns may vary by PDF |
| No deduplication | User requirement; annual use case where duplication is rare |
| No data cleaning | User requirement; flexibility for downstream processing |
| CLI over GUI | User preference; faster for annual batch job |
| Single output CSV | User requirement; simpler downstream processing for tax software |

---

**Next Step:** Implementation plan with task breakdown and sequencing.
