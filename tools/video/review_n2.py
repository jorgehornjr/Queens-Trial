"""Extract review frames and a contact sheet from the final N2 video."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / "tmp/n2_video"
FPS = 30


def output_frame(source_frame, sections):
    for section in sections:
        if section["source_start"] <= source_frame < section["source_end"]:
            return section["output_start"] + source_frame - section["source_start"]
    return None


def timestamp(seconds):
    return f"{int(seconds) // 60:02d}:{int(seconds) % 60:02d}"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("video", type=Path)
    args = parser.parse_args()
    ffmpeg = shutil.which("ffmpeg")
    timeline = json.loads((WORK / "timeline.json").read_text(encoding="utf-8"))
    sections = json.loads((WORK / "edit_plan.json").read_text(encoding="utf-8"))
    marks = {entry["name"]: entry["frame"] for entry in timeline["markers"]}
    points = [
        ("Menu", marks["menu_click"] - 30),
        ("Tutorial e regras", marks["book_1_revealed"] + 60),
        ("Erro explicado", marks["failure_visible"] + 90),
        ("Resposta correta", marks["phase_1_walk"] + 45),
        ("Progressao", marks["phase_2_walk"] + 50),
        ("Torres", marks["phase_3_walk"] + 100),
        ("Pares de ataques", marks["phase_4_walk"] + 100),
        ("Tutorial dos bispos", marks["book_5_revealed"] + 60),
        ("Bispos", marks["phase_5_walk"] + 100),
        ("Globo e balanca", marks["phase_6_start"] + 50),
        ("Tutorial da balanca", marks["book_6_revealed"] + 60),
        ("Comparacao dos pesos", marks["balance_tilt_0"] + 30),
        ("Balanca sem indicacao", marks["balance_round_2"] + 45),
        ("Ordem crescente", marks["ascending_correct"] - 40),
        ("Ordem decrescente", marks["descending_correct"] - 40),
        ("Associacao", marks["matching_correct"] - 40),
        ("Decreto falso", marks["false_decree_correct"] - 35),
        ("Pausa", marks["pause_visible"] + 50),
        ("Chaotic", marks["chaotic_preparation"] + 60),
        ("Encerramento", marks["end"] - 45),
    ]
    folder = WORK / "review"
    folder.mkdir(exist_ok=True)
    samples = []
    for index, (label, source_frame) in enumerate(points):
        frame = output_frame(source_frame, sections)
        if frame is None:
            raise ValueError(f"Review point was cut: {label}")
        path = folder / f"{index:02d}.png"
        subprocess.run([ffmpeg, "-hide_banner", "-loglevel", "error", "-y", "-ss", str(frame / FPS),
                        "-i", str(args.video), "-frames:v", "1", "-update", "1", str(path)], check=True)
        samples.append(dict(label=label, time=frame / FPS, path=str(path)))
    sheet = Image.new("RGB", (1920, 5 * 310), "#14101b")
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 19)
    for index, sample in enumerate(samples):
        x, y = index % 4 * 480, index // 4 * 310
        with Image.open(sample["path"]) as frame:
            sheet.paste(frame.resize((480, 270), Image.Resampling.LANCZOS), (x, y))
        draw.text((x + 10, y + 279), f"{timestamp(sample['time'])}  {sample['label']}", font=font, fill="#f7e9ce")
    sheet.save(folder / "contact_sheet.jpg", quality=92)
    (folder / "samples.json").write_text(json.dumps(samples, ensure_ascii=False, indent=2), encoding="utf-8")
    with (folder / "audio_analysis.log").open("w", encoding="utf-8") as log:
        subprocess.run([ffmpeg, "-hide_banner", "-i", str(args.video), "-vn", "-af",
                        "volumedetect,silencedetect=noise=-50dB:d=2", "-f", "null", "NUL"],
                       stdout=log, stderr=subprocess.STDOUT, check=True)
    print(f"REVIEW: {len(samples)} frames, contact sheet and audio analysis in {folder}")


if __name__ == "__main__":
    main()
