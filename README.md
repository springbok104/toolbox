🧵 Stitching things together, quietly

A collection of purpose-built scripts for workflows that should’ve just worked.

## Scripts

### `tm_sparsebundle.sh`
# bash-scripts

Minimal tools, quietly confident logic.

## Scripts

### `tm_sparsebundle.sh`

Time Machine can be fickle.  
This script was built after having to manually create sparsebundle images—multiple times—due to backup errors and quirks in Time Machine behavior.

Creates a Time Machine-compatible sparsebundle for network or local backups.  
Prompts user for volume name, size, and destination directory.  
Includes input validation, fallback logic, and directory checks.

> Designed for reproducibility. Works on macOS.

---

## Usage

```bash
./tm_sparsebundle.sh
