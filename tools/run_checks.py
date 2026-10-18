"""Run the current game's headless regression suite with per-test logs."""
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
import shutil
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
TESTS = ['run_all', 'test_vanilla_generation', 'test_phase_playthrough', 'test_feedback_presentation',
         'test_starred_guidance', 'test_hud_integration', 'test_tutorial_book',
         'test_opening_cutscene', 'test_music_handoff', 'test_fandaniel',
         'test_balance_trial', 'test_pause_phase_selector', 'test_card_trials',
         'test_savage', 'test_savage_audio', 'test_main_menu',
         'test_piece_readability', 'test_failure_audio', 'test_card_burn_audio']


def run(name, godot):
    start = time.monotonic()
    result = subprocess.run([godot, '--headless', '--path', str(ROOT), '--script', f'tests/{name}.gd'],
                            cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=150)
    try: output = result.stdout.decode('utf-8')
    except UnicodeDecodeError: output = result.stdout.decode('cp1252', errors='replace')
    (ROOT / f'tmp/checks/{name}.log').write_text(output, encoding='utf-8')
    ok = result.returncode == 0 and not any(marker in output for marker in ['SCRIPT ERROR:', 'Parse Error:', 'FALHA:'])
    return name, ok, time.monotonic() - start, output


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--jobs', type=int, default=1)
    parser.add_argument('tests', nargs='*', choices=TESTS)
    args = parser.parse_args()
    godot = shutil.which('godot_console') or shutil.which('godot')
    if not godot: raise SystemExit('Godot not found in PATH.')
    (ROOT / 'tmp/checks').mkdir(parents=True, exist_ok=True)
    failed = []
    with ThreadPoolExecutor(max_workers=max(1, min(3, args.jobs))) as executor:
        futures = [executor.submit(run, name, godot) for name in (args.tests or TESTS)]
        for future in as_completed(futures):
            try: name, ok, seconds, output = future.result()
            except Exception as error:
                failed.append(str(error)); print('FAIL:', error, flush=True); continue
            print(f'{"PASS" if ok else "FAIL"}: {name} ({seconds:.1f}s)', flush=True)
            if not ok:
                failed.append(name)
                print(output[-6000:], flush=True)
    print(f'Failed: {len(failed)}', flush=True)
    raise SystemExit(1 if failed else 0)
