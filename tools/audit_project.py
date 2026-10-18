"""Audit the current Godot game's resource graph; never deletes project files.

Run Godot's tools/audit_resources.gd first to include imported GLB dependencies.
The report lists candidates for human review; it does not prove they are obsolete.
"""
import argparse
import json
import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TEXT = {'.gd', '.tscn', '.tres', '.godot', '.json', '.gdshader', '.gdshaderinc', '.gdextension'}
IGNORED = {'.git', '.godot', 'Deleted', 'tmp', '__pycache__', 'QT milestones'}
ROOTS = ['project.godot', 'scenes/main/main.tscn',
         'scenes/previews/tutorial_book_preview.tscn',
         'scenes/previews/fandaniel_phase_six_preview.tscn']
# These loaders assemble filenames at runtime. Keep their explicit input sets.
DYNAMIC = {
    'scripts/main/ascian_arrival.gd': ['assets/effects/ascian_arrival/*'],
    'scripts/environment/solar_system.gd': ['assets/environment/solar_system/*.glb',
        'assets/environment/solar_system/preparation.json', 'assets/environment/spacecraft/*.glb'],
    'scripts/ui/tutorial_book.gd': ['assets/ui/tutorial_book/color_*.png'],
}


def audit():
    files = {p.relative_to(ROOT).as_posix(): p for p in ROOT.rglob('*')
             if p.is_file() and not any(part in IGNORED for part in p.relative_to(ROOT).parts)}
    imported_file = ROOT / 'tmp/import_dependencies.json'
    imported = json.loads(imported_file.read_text()) if imported_file.exists() else {}
    classes = {}
    for name, path in files.items():
        if path.suffix == '.gd' and name.startswith('scripts/'):
            match = re.search(r'^class_name\s+(\w+)', path.read_text(encoding='utf-8-sig'), re.M)
            if match: classes[match.group(1)] = name
    graph, missing = {}, []
    for name, path in files.items():
        dependencies = set()
        if path.suffix in TEXT:
            text = path.read_text(encoding='utf-8-sig')
            if path.suffix == '.gd':
                dependencies.update(classes[token] for token in set(re.findall(r'(?<![$\w])\b\w+\b', text)) if token in classes)
            for match in re.finditer(r'''["']res://([^"'\n]+)["']''', text):
                candidate = match.group(1)
                if candidate.startswith(('.godot/', 'tmp/', 'Deleted/')) or '%' in candidate: continue
                if candidate in files: dependencies.add(candidate)
                elif Path(candidate).suffix and not (ROOT / candidate).is_dir():
                    missing.append((name, candidate))
            for match in re.finditer(r'#include\s+"([^\"]+)"', text):
                include = match.group(1)
                dependencies.add(include.removeprefix('res://') if include.startswith('res://') else (path.parent / include).relative_to(ROOT).as_posix())
        for dependency in imported.get(name, []):
            if dependency.startswith('res://'):
                dependencies.add(dependency.removeprefix('res://'))
        for pattern in DYNAMIC.get(name, []):
            dependencies.update(p.relative_to(ROOT).as_posix() for p in ROOT.glob(pattern) if p.is_file() and p.suffix not in {'.import', '.uid'})
        graph[name] = dependencies
    used, reasons, queue = set(), {}, list(ROOTS)
    while queue:
        name = queue.pop()
        if name in used: continue
        used.add(name)
        for dependency in graph.get(name, []):
            reasons.setdefault(dependency, name)
            queue.append(dependency)
        for suffix in ['.import', '.uid']:
            if name + suffix in files:
                used.add(name + suffix)
                reasons[name + suffix] = name
    runtime_missing = [(a, b) for a, b in missing if a in used]
    groups = defaultdict(lambda: {'files': 0, 'bytes': 0})
    for name, path in files.items():
        kind = 'runtime' if name in used else name.split('/')[0]
        groups[kind]['files'] += 1
        groups[kind]['bytes'] += path.stat().st_size
    return {'roots': ROOTS, 'summary': dict(groups), 'runtime_missing': runtime_missing,
            'other_missing': [(a, b) for a, b in missing if a not in used],
            'runtime': sorted(used), 'reasons': reasons,
            'unused_assets': sorted(n for n in files if n.startswith('assets/') and n not in used),
            'unused_code': sorted(n for n in files if n.split('/')[0] in {'scripts', 'scenes', 'shaders'} and n not in used)}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', default='tmp/project_audit.json')
    args = parser.parse_args()
    report = audit()
    output = (ROOT / args.output).resolve()
    if not output.is_relative_to(ROOT): raise SystemExit('Report path must stay within the project.')
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    for group, values in report['summary'].items():
        print(f"{group}: {values['files']} files, {values['bytes']/1024**2:.1f} MiB")
    print('Missing runtime references:', report['runtime_missing'])
    print('Unused assets:', len(report['unused_assets']), '; unused code:', len(report['unused_code']))
