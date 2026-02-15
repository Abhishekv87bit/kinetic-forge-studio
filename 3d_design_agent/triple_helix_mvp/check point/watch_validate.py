#!/usr/bin/env python3
"""
Triple Helix MVP -- File Watcher + Auto-Validator
===================================================
Monitors the check point directory for .scad file changes and automatically
runs validate_geometry.py. Sends ntfy.sh notifications on completion.

Usage:
    python watch_validate.py                    # watch current directory
    python watch_validate.py --dir "D:\\path"   # watch specific directory
    python watch_validate.py --no-ntfy          # disable notifications

Requirements:
    pip install watchdog
"""

import argparse
import os
import re
import subprocess
import sys
import threading
import time
from datetime import datetime
from pathlib import Path

try:
    from watchdog.observers import Observer
    from watchdog.events import FileSystemEventHandler
except ImportError:
    print("ERROR: watchdog not installed. Run: pip install watchdog")
    sys.exit(1)


# ============================================================
# CONFIGURATION
# ============================================================
NTFY_TOPIC = "bussabtheakhaijanab1851421"
NTFY_URL = f"https://ntfy.sh/{NTFY_TOPIC}"
DEBOUNCE_SECONDS = 1.0

# File patterns to ignore (validation output files)
IGNORE_SUFFIXES = {".test.csg", ".validate.json", ".validate.png"}
IGNORE_PREFIXES = {"_test", "_temp", "_nul"}

# ANSI color codes for terminal output
class Colors:
    GREEN = "\033[92m"
    RED = "\033[91m"
    YELLOW = "\033[93m"
    CYAN = "\033[96m"
    BOLD = "\033[1m"
    DIM = "\033[2m"
    RESET = "\033[0m"


# ============================================================
# UTILITY FUNCTIONS
# ============================================================
def timestamp():
    """Return formatted timestamp string."""
    return datetime.now().strftime("%H:%M:%S")


def is_validation_output(filepath):
    """Check if a file is a validation output that should be ignored."""
    name = Path(filepath).name.lower()
    # Check compound suffixes like .test.csg, .validate.json, .validate.png
    for suffix in IGNORE_SUFFIXES:
        if name.endswith(suffix):
            return True
    # Check prefixed temp/test files
    for prefix in IGNORE_PREFIXES:
        if name.startswith(prefix):
            return True
    return False


def is_config_file(filepath):
    """Check if a file is a config file (starts with config_)."""
    return Path(filepath).name.startswith("config_")


def find_dependents(config_path, watch_dir):
    """
    Find all .scad files in watch_dir that include or use the given config file.
    Searches for both 'include <filename>' and 'use <filename>' patterns.
    """
    config_name = Path(config_path).name
    dependents = []
    pattern = re.compile(
        r'(?:include|use)\s*<\s*' + re.escape(config_name) + r'\s*>'
    )

    watch_path = Path(watch_dir)
    for scad_file in watch_path.glob("*.scad"):
        if scad_file.name == config_name:
            continue
        if is_validation_output(str(scad_file)):
            continue
        try:
            content = scad_file.read_text(encoding="utf-8", errors="replace")
            if pattern.search(content):
                dependents.append(str(scad_file))
        except (OSError, PermissionError):
            continue

    return dependents


def send_ntfy(message, tags="white_check_mark", priority="default"):
    """Send notification via ntfy.sh. Non-blocking, fire-and-forget."""
    try:
        cmd = [
            "curl", "-s",
            "-H", f"Tags: {tags}",
            "-H", f"Priority: {priority}",
            "-d", message,
            NTFY_URL,
        ]
        subprocess.Popen(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except Exception as e:
        print(f"  {Colors.DIM}(ntfy send failed: {e}){Colors.RESET}")


def run_validation(scad_file, watch_dir, notify=True):
    """
    Run validate_geometry.py on a single .scad file.
    Returns (exit_code, pass_count, fail_count, total_count).
    """
    scad_path = Path(scad_file).resolve()
    validator = Path(watch_dir) / "validate_geometry.py"
    filename = scad_path.name

    if not validator.exists():
        print(f"  {Colors.RED}ERROR: validate_geometry.py not found in {watch_dir}{Colors.RESET}")
        if notify:
            send_ntfy(
                f"validate_geometry.py not found for {filename}",
                tags="warning",
                priority="urgent",
            )
        return (2, 0, 0, 0)

    print(f"\n{Colors.CYAN}{Colors.BOLD}[{timestamp()}] Validating: {filename}{Colors.RESET}")
    print(f"  {Colors.DIM}Path: {scad_path}{Colors.RESET}")

    try:
        result = subprocess.run(
            [sys.executable, str(validator), str(scad_path)],
            capture_output=True,
            text=True,
            timeout=180,
            cwd=str(watch_dir),
        )
    except subprocess.TimeoutExpired:
        msg = f"TIMEOUT: {filename} validation exceeded 180s"
        print(f"  {Colors.RED}{msg}{Colors.RESET}")
        if notify:
            send_ntfy(msg, tags="warning", priority="urgent")
        return (2, 0, 0, 0)
    except FileNotFoundError as e:
        msg = f"ERROR: Could not run validator -- {e}"
        print(f"  {Colors.RED}{msg}{Colors.RESET}")
        if notify:
            send_ntfy(msg, tags="warning", priority="urgent")
        return (2, 0, 0, 0)

    output = result.stdout + result.stderr

    # Parse results from output
    pass_count = 0
    fail_count = 0
    total_count = 0

    # Look for the RESULTS summary line
    results_match = re.search(
        r'RESULTS:\s*(\d+)\s*PASS,\s*(\d+)\s*FAIL,\s*(\d+)\s*total', output
    )
    if results_match:
        pass_count = int(results_match.group(1))
        fail_count = int(results_match.group(2))
        total_count = int(results_match.group(3))

    # Colorize and print the output
    for line in output.splitlines():
        if "[XX]" in line or "FAIL" in line:
            print(f"  {Colors.RED}{line}{Colors.RESET}")
        elif "[OK]" in line or "PASS" in line:
            print(f"  {Colors.GREEN}{line}{Colors.RESET}")
        elif "COMPILE ERROR" in line or "ERROR" in line:
            print(f"  {Colors.RED}{Colors.BOLD}{line}{Colors.RESET}")
        elif "Warning" in line or "WARNING" in line:
            print(f"  {Colors.YELLOW}{line}{Colors.RESET}")
        elif line.startswith("===") or line.startswith("---"):
            print(f"  {Colors.DIM}{line}{Colors.RESET}")
        else:
            print(f"  {line}")

    exit_code = result.returncode

    # Send notification
    if notify:
        if exit_code == 2:
            send_ntfy(
                f"COMPILE ERROR: {filename}",
                tags="warning",
                priority="urgent",
            )
        elif exit_code == 1 or fail_count > 0:
            send_ntfy(
                f"{filename}: {pass_count} PASS, {fail_count} FAIL",
                tags="x",
                priority="high",
            )
        else:
            send_ntfy(
                f"{filename}: {pass_count}/{total_count} PASS",
                tags="white_check_mark",
                priority="default",
            )

    # Print summary bar
    if exit_code == 2:
        print(f"  {Colors.RED}{Colors.BOLD}>>> COMPILE ERROR <<<{Colors.RESET}")
    elif fail_count > 0:
        print(
            f"  {Colors.RED}{Colors.BOLD}"
            f">>> {filename}: {pass_count} PASS, {fail_count} FAIL <<<"
            f"{Colors.RESET}"
        )
    else:
        print(
            f"  {Colors.GREEN}{Colors.BOLD}"
            f">>> {filename}: {pass_count}/{total_count} PASS <<<"
            f"{Colors.RESET}"
        )

    return (exit_code, pass_count, fail_count, total_count)


# ============================================================
# FILE WATCHER
# ============================================================
class ScadFileHandler(FileSystemEventHandler):
    """Watches for .scad file modifications with debouncing."""

    def __init__(self, watch_dir, notify=True):
        super().__init__()
        self.watch_dir = str(Path(watch_dir).resolve())
        self.notify = notify
        self._pending = {}  # filepath -> timer
        self._lock = threading.Lock()

    def on_modified(self, event):
        if event.is_directory:
            return
        self._handle_event(event.src_path)

    def on_created(self, event):
        if event.is_directory:
            return
        self._handle_event(event.src_path)

    def _handle_event(self, filepath):
        """Schedule validation with debounce."""
        filepath = str(Path(filepath).resolve())

        # Only care about .scad files
        if not filepath.lower().endswith(".scad"):
            return

        # Skip validation output files
        if is_validation_output(filepath):
            return

        # Skip files not in the watch directory (subdirectories)
        file_dir = str(Path(filepath).parent.resolve())
        if file_dir != self.watch_dir:
            return

        with self._lock:
            # Cancel any pending timer for this file
            if filepath in self._pending:
                self._pending[filepath].cancel()

            # Schedule new validation after debounce period
            timer = threading.Timer(
                DEBOUNCE_SECONDS,
                self._run_validation,
                args=[filepath],
            )
            timer.daemon = True
            self._pending[filepath] = timer
            timer.start()

    def _run_validation(self, filepath):
        """Run validation (called after debounce timer fires)."""
        with self._lock:
            self._pending.pop(filepath, None)

        scad_path = Path(filepath)
        if not scad_path.exists():
            return

        if is_config_file(filepath):
            # Config file changed -- find and validate all dependents
            dependents = find_dependents(filepath, self.watch_dir)
            if dependents:
                config_name = scad_path.name
                print(
                    f"\n{Colors.YELLOW}{Colors.BOLD}"
                    f"[{timestamp()}] Config changed: {config_name} "
                    f"-- validating {len(dependents)} dependent file(s)"
                    f"{Colors.RESET}"
                )
                for dep in sorted(dependents):
                    run_validation(dep, self.watch_dir, notify=self.notify)
            else:
                print(
                    f"\n{Colors.DIM}"
                    f"[{timestamp()}] Config changed: {scad_path.name} "
                    f"-- no dependent .scad files found"
                    f"{Colors.RESET}"
                )
        else:
            # Regular .scad file -- validate directly
            run_validation(filepath, self.watch_dir, notify=self.notify)


# ============================================================
# MAIN
# ============================================================
def main():
    parser = argparse.ArgumentParser(
        description="Watch .scad files and auto-run validate_geometry.py"
    )
    parser.add_argument(
        "--dir",
        type=str,
        default=None,
        help="Directory to watch (default: current directory)",
    )
    parser.add_argument(
        "--no-ntfy",
        action="store_true",
        help="Disable ntfy.sh notifications",
    )
    args = parser.parse_args()

    watch_dir = Path(args.dir).resolve() if args.dir else Path.cwd().resolve()

    if not watch_dir.is_dir():
        print(f"ERROR: Not a directory: {watch_dir}")
        sys.exit(1)

    validator = watch_dir / "validate_geometry.py"
    if not validator.exists():
        print(f"WARNING: validate_geometry.py not found in {watch_dir}")
        print("         Validation will fail until this file is present.")

    notify = not args.no_ntfy

    # Count .scad files
    scad_files = list(watch_dir.glob("*.scad"))
    scad_count = len([f for f in scad_files if not is_validation_output(str(f))])

    print(f"{Colors.CYAN}{Colors.BOLD}")
    print("=" * 60)
    print("  SCAD FILE WATCHER + AUTO-VALIDATOR")
    print("=" * 60)
    print(f"{Colors.RESET}")
    print(f"  Directory:     {watch_dir}")
    print(f"  .scad files:   {scad_count}")
    print(f"  Notifications: {'ENABLED' if notify else 'DISABLED'}")
    print(f"  Debounce:      {DEBOUNCE_SECONDS}s")
    print(f"  Started:       {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    print(f"  {Colors.DIM}Watching for .scad file changes... (Ctrl+C to stop){Colors.RESET}")
    print()

    # Send startup notification
    if notify:
        send_ntfy(
            f"Watcher started: {scad_count} .scad files in {watch_dir.name}/",
            tags="eyes",
            priority="low",
        )

    handler = ScadFileHandler(watch_dir, notify=notify)
    observer = Observer()
    observer.schedule(handler, str(watch_dir), recursive=False)
    observer.start()

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Stopping watcher...{Colors.RESET}")
        observer.stop()
        if notify:
            send_ntfy("Watcher stopped", tags="octagonal_sign", priority="low")
    finally:
        observer.join()
        print(f"{Colors.DIM}Done.{Colors.RESET}")


if __name__ == "__main__":
    main()
