"""Last pipeline step: suppress publication data and rebuild the embedded explorer."""
from pathlib import Path
import json
import runpy
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from reproducibility.publication_privacy import apply, check

report = apply(ROOT)
runpy.run_path(str(ROOT / 'analysis/25_explorador_html.py'), run_name='__main__')
verified = check(ROOT)
print(json.dumps({'suppressed_explorer_cells': report['suppressed_explorer_cells'], **verified}))
