import sys
from pathlib import Path

# Path to the file
file_path = Path("d:/project/iosk/.venv/Lib/site-packages/tidevice/_wdaproxy.py")

if file_path.exists():
    print(file_path.read_text(encoding="utf-8"))
else:
    print(f"File not found: {file_path}")
