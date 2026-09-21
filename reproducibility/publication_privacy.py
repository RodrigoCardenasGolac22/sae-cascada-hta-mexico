#!/usr/bin/env python3
"""Suppress small municipal cells in publication files, retaining private inputs.

Run --apply after analytical outputs are complete; --check never modifies files.
Only the current publication tree is assessed, not historical Git objects.
"""
from __future__ import annotations
import argparse
import csv
import io
import json
import math
import shutil
import sys
import zipfile
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
STEPS = ('AWARE_ESH', 'AWARE_AHA', 'TRAT', 'CONTROL_ESH', 'CONTROL_AHA')
DIRECT = dict(zip(('conciencia_ESH', 'conciencia_AHA', 'tratamiento', 'control_ESH', 'control_AHA'), STEPS))
JSON_KEYS = dict(zip(('diag_esh', 'diag_aha', 'trat', 'ctrl_esh', 'ctrl_aha'), STEPS))
IDENTIFIERS = {'muni_idx', 'muni_id', 'cve_ent', 'cve_mun', 'nomgeo'}
METADATA = {'fuente', 'fuente_ESH', 'fuente_AHA', 'priv_ESH', 'priv_AHA',
            'ambos_directos', 'suprimir_privacidad'}
BLANK = {'', 'NA', 'NaN', 'null'}

def read_rows(path):
    with path.open(encoding='utf-8-sig', newline='') as f:
        reader = csv.DictReader(f)
        return reader.fieldnames, list(reader)

def true(value):
    return str(value).lower() in {'true', '1'}

def small(value):
    try:
        n = float(value)
        return math.isfinite(n) and 0 <= n < 10
    except (ValueError, TypeError):
        return False

def outcomes(name):
    for step in STEPS:
        if name in (f'NACIONAL_{step}.csv', f'cv_detalle_{step}.csv',
                    f'cv_detalle_{step}_contiguo.csv', f'sensibilidad_ponderada_detalle_{step}.csv'):
            return (step,)
    for label, step in DIRECT.items():
        if name == f'directa_{label}_municipio.csv': return (step,)
    for label, steps in [('conciencia', ('AWARE_ESH', 'AWARE_AHA')),
                         ('control', ('CONTROL_ESH', 'CONTROL_AHA'))]:
        if name in (f'reclasificacion_{label}_ESH_vs_AHA.csv',
                    f'NACIONAL_reclasificacion_{label}_ESH_vs_AHA.csv'): return steps
    return ()

def index_mapping(root):
    _, rows = read_rows(root/'data/processed/geography/muni_idx_grafo.csv')
    return {r['muni_idx']: r['cve_ent'].zfill(2)+r['cve_mun'].zfill(3) for r in rows}

def municipal_id(row, index):
    if 'muni_id' in row: return row['muni_id'].zfill(5)
    if 'muni_idx' in row: return index[row['muni_idx']]
    return row['cve_ent'].zfill(2)+row['cve_mun'].zfill(3)

def load_inputs(root):
    files = {}
    for p in sorted((root/'results/estimates').glob('*.csv')):
        if outcomes(p.name): files[p] = read_rows(p)
    expected = 29  # 5 national + 10 CV + 5 direct + 5 sensitivity + 4 reclassification
    if len(files) != expected: raise ValueError(f'Expected {expected} municipal CSV files, found {len(files)}')
    index = index_mapping(root)
    protected = {step: set() for step in STEPS}
    for path, (fields, rows) in files.items():
        steps = outcomes(path.name)
        if len(steps) != 1: continue
        for row in rows:
            if true(row.get('suprimir_privacidad')) or small(row.get('n')) or small(row.get('n_directo')):
                protected[steps[0]].add(municipal_id(row, index))
    return files, index, protected

def protected_row(row, steps, index, protected):
    return (true(row.get('suprimir_privacidad')) or
            any(municipal_id(row, index) in protected[step] for step in steps))

def save_private_and_replace(root, path, content):
    if path.read_bytes() == content: return
    private = root/'results/private/publication_inputs'/path.relative_to(root)
    private.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(path, private)
    path.write_bytes(content)

def apply(root):
    files, index, protected = load_inputs(root)
    counts = {}
    for path, (fields, rows) in files.items():
        if 'suprimir_privacidad' not in fields: fields = fields + ['suprimir_privacidad']
        count = 0
        for row in rows:
            suppress = protected_row(row, outcomes(path.name), index, protected)
            row['suprimir_privacidad'] = 'TRUE' if suppress else 'FALSE'
            if suppress:
                count += 1
                for field in fields:
                    if field not in IDENTIFIERS | METADATA: row[field] = ''
        buf = io.StringIO(newline='')
        writer = csv.DictWriter(buf, fieldnames=fields, lineterminator='\n')
        writer.writeheader(); writer.writerows(rows)
        save_private_and_replace(root, path, buf.getvalue().encode('utf-8'))
        counts[path.name] = count
    path = root/'docs/datos.json'
    data = json.loads(path.read_text(encoding='utf-8'))
    json_count = 0
    for municipality in data['munis']:
        for key, cell in municipality['est'].items():
            if cell.get('f') == 2 or municipality['id'] in protected[JSON_KEYS[key]]:
                cell.update(v=None, lo=None, hi=None, n=None, f=2)
                json_count += 1
    save_private_and_replace(root, path, json.dumps(data, ensure_ascii=False, separators=(',', ':')).encode('utf-8'))
    report = {'policy': 'Suppress municipal estimates, intervals, interval widths and exact counts when the clinical denominator is below 10.',
              'scope': 'Current publication tree; historical commits and tags are not rewritten.',
              'suppressed_rows_by_csv': counts, 'suppressed_explorer_cells': json_count,
              'private_inputs_directory': 'results/private/publication_inputs/',
              'analytical_models_refitted': False}
    (root/'reproducibility/publication_privacy.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8', newline='\n')
    return report

def workbook_rows(path):
    ns = {'s': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
    with zipfile.ZipFile(path) as z:
        strings = []
        if 'xl/sharedStrings.xml' in z.namelist():
            strings = [''.join(n.itertext()) for n in ET.fromstring(z.read('xl/sharedStrings.xml'))]
        sheets = sorted(n for n in z.namelist() if n.startswith('xl/worksheets/sheet') and n.endswith('.xml'))
        for sheet in sheets:
            output = []
            for row in ET.fromstring(z.read(sheet)).findall('.//s:sheetData/s:row', ns):
                cells = {}
                for c in row.findall('s:c', ns):
                    col = ''.join(x for x in c.attrib['r'] if x.isalpha())
                    value = c.find('s:v', ns)
                    value = value.text if value is not None else ''
                    if c.attrib.get('t') == 's': value = strings[int(value)]
                    elif c.attrib.get('t') == 'inlineStr': value = ''.join(c.find('s:is', ns).itertext())
                    cells[col] = value
                output.append(cells)
            header = output[0]
            yield [{name: row.get(col, '') for col, name in header.items()} for row in output[1:]]

def check(root, include_workbooks=True):
    files, index, protected = load_inputs(root)
    errors = []
    cells = 0
    for path, (fields, rows) in files.items():
        if 'suprimir_privacidad' not in fields: errors.append(f'{path.name}: missing suppression flag')
        for row in rows:
            if protected_row(row, outcomes(path.name), index, protected):
                cells += 1
                if not true(row.get('suprimir_privacidad')): errors.append(f'{path.name}: inconsistent flag')
                if any(row.get(f, '') not in BLANK for f in fields if f not in IDENTIFIERS | METADATA):
                    errors.append(f'{path.name}: a suppressed municipal row retains numeric data')
    data = json.loads((root/'docs/datos.json').read_text(encoding='utf-8'))
    for municipality in data['munis']:
        for key, cell in municipality['est'].items():
            if cell.get('f') == 2 or municipality['id'] in protected[JSON_KEYS[key]]:
                if cell.get('f') != 2 or any(cell.get(k) is not None for k in ('v', 'lo', 'hi', 'n')):
                    errors.append('Explorer: suppressed cell retains data')
    if include_workbooks:
        for filename, groups in [('Fig2_datos.xlsx', [('AWARE_ESH',), ('TRAT',), ('CONTROL_ESH',)]),
                                 ('Fig3_datos.xlsx', [('AWARE_ESH', 'AWARE_AHA'), ('CONTROL_ESH', 'CONTROL_AHA')])]:
            sheets = list(workbook_rows(root/'results/figures/data'/filename))
            if len(sheets) != len(groups): errors.append(f'{filename}: unexpected sheets'); continue
            for rows, steps in zip(sheets, groups):
                for row in rows:
                    if any(municipal_id(row, index) in protected[s] for s in steps):
                        if any(value not in BLANK for key, value in row.items() if key not in IDENTIFIERS | METADATA):
                            errors.append(f'{filename}: suppressed municipal data remain in workbook')
    if errors: raise ValueError('\n'.join(sorted(set(errors))))
    return {'municipal_csv_files_checked': len(files), 'suppressed_rows_checked': cells,
            'figure_workbooks_checked': 2 if include_workbooks else 0}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    if args.apply == args.check: parser.error('Choose --apply or --check')
    try:
        result = apply(ROOT) if args.apply else check(ROOT)
        print(json.dumps(result, indent=2))
    except (OSError, ValueError, KeyError) as exc:
        print(str(exc), file=sys.stderr); return 1
    return 0

if __name__ == '__main__': raise SystemExit(main())
