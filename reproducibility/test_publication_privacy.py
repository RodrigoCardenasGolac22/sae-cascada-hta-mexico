"""Regression checks against accidental re-publication of suppressed values."""
import csv
import importlib.util
import json
from pathlib import Path
import shutil
import tempfile
import unittest

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('publication_privacy', HERE/'publication_privacy.py')
privacy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(privacy)

class PublicationPrivacyTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for directory in ['results/estimates', 'docs', 'reproducibility', 'data/processed/geography']:
            (self.root/directory).mkdir(parents=True, exist_ok=True)
        for source in (privacy.ROOT/'results/estimates').glob('*.csv'):
            if privacy.outcomes(source.name):
                shutil.copyfile(source, self.root/'results/estimates'/source.name)
        for name in ['docs/datos.json', 'data/processed/geography/muni_idx_grafo.csv']:
            shutil.copyfile(privacy.ROOT/name, self.root/name)

    def test_release_contains_no_suppressed_values(self):
        result = privacy.check(privacy.ROOT)
        self.assertEqual(result['municipal_csv_files_checked'], 29)

    def test_rejects_exact_count_reintroduced_in_explorer(self):
        path = self.root/'docs/datos.json'
        data = json.loads(path.read_text(encoding='utf-8'))
        cell = next(c for m in data['munis'] for c in m['est'].values() if c['f']==2)
        cell['n'] = 3
        path.write_text(json.dumps(data), encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'Explorer'):
            privacy.check(self.root, include_workbooks=False)

    def test_rejects_value_even_if_local_flag_was_removed(self):
        path = self.root/'results/estimates/cv_detalle_AWARE_ESH.csv'
        fields, rows = privacy.read_rows(path)
        row = next(r for r in rows if privacy.true(r['suprimir_privacidad']))
        row['obs'] = '0.75'; row['suprimir_privacidad'] = 'FALSE'
        with path.open('w', encoding='utf-8', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=fields); writer.writeheader(); writer.writerows(rows)
        with self.assertRaisesRegex(ValueError, 'suppressed municipal row'):
            privacy.check(self.root, include_workbooks=False)

    def test_suppression_is_idempotent(self):
        before = {p.relative_to(self.root):p.read_bytes() for p in (self.root/'results/estimates').glob('*.csv')}
        json_before = (self.root/'docs/datos.json').read_bytes()
        privacy.apply(self.root)
        privacy.apply(self.root)
        for path, content in before.items(): self.assertEqual(content, (self.root/path).read_bytes())
        self.assertEqual(json_before, (self.root/'docs/datos.json').read_bytes())
        privacy.check(self.root, include_workbooks=False)

if __name__ == '__main__': unittest.main()
