"""Edit the native Godot recording into a 4:59 Full HD submission.

Only repeated presentations and selected cinematic shots are removed. Gameplay
and sound keep their original speed; short picture/sound dissolves join cuts.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import json
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]
FPS = 30
TARGET_FRAMES = 299 * FPS
DISSOLVE_FRAMES = 9
WORK = ROOT / "tmp/n2_video"
FFMPEG = shutil.which("ffmpeg")
FFPROBE = shutil.which("ffprobe")
CAPTIONS = []


def command(args, log):
    with log.open("w", encoding="utf-8") as stream:
        result = subprocess.run(args, stdout=stream, stderr=subprocess.STDOUT)
    if result.returncode:
        raise RuntimeError(f"Command failed; see {log}")


def plan(timeline):
    marks = timeline["markers"]
    m = {entry["name"]: entry["frame"] for entry in marks}
    second_drags = [entry["frame"] for entry in marks
                    if entry["name"].startswith("drag_")
                    and m["phase_7_descending"] < entry["frame"] < m["descending_correct"]]
    if len(second_drags) != 5:
        raise ValueError("The descending round must contain five genuine drags")
    sections = [
        ["Menu principal", 0, m["opening_start"]],
        ["Chegada do protagonista", m["opening_start"] + 306, m["opening_start"] + 744],
        ["Rainha e tabuleiro", m["opening_start"] + 900, m["phase_1_start"]],
        ["Tutorial, objetivo e primeiro édito", m["phase_1_start"], m["phase_1_first_cards_end"] + 90],
        ["Resposta incorreta e explicação", m["failure_attempt_start"], m["failure_confirm"] + 24],
        ["Correção e avanço para a fase II", m["phase_1_solution"], m["phase_3_start"]],
        ["Torres e progressão para a fase IV", m["phase_3_cards_start"], m["phase_4_cards_flipped"] + 24],
        ["Ataques em pares", m["phase_4_walk"], m["phase_4_edict_1"] + 36],
        ["Conclusão da fase IV", m["phase_4_correct"], m["phase_5_start"]],
        ["Tutorial dos bispos", m["book_5_reading"], m["phase_5_cards_flipped"] + 30],
        ["Bispos, transformação e tutorial da balança", m["phase_5_walk"], m["balance_round_1"]],
        ["Balança sem indicação e entrada nas cartas", m["balance_tilt_1"] + 90, m["phase_7_descending"]],
        ["Ordem decrescente: início", m["phase_7_descending"], second_drags[0] + 9],
        ["Ordem decrescente: confirmação", second_drags[-2] + 3, m["phase_8_matching"]],
        ["Associação, decreto falso, pausa e Chaotic", m["phase_8_matching"], m["chaotic_preparation"] + 120],
        ["Encerramento", m["end"] - 120, m["end"]],
    ]
    desired_sum = TARGET_FRAMES + DISSOLVE_FRAMES * (len(sections) - 1)
    excess = sum(end - start for _, start, end in sections) - desired_sum
    # Fine adjustment uses establishing shots, never tutorial/feedback reading.
    for index, minimum in [(0, 300), (1, 270), (2, 240)]:
        if excess <= 0:
            break
        available = sections[index][2] - sections[index][1] - minimum
        removed = min(excess, max(0, available))
        sections[index][1] += removed
        excess -= removed
    if excess != 0:
        raise ValueError("Unexpected recording timing: review the edit manually")
    offset = 0
    result = []
    for index, (label, start, end) in enumerate(sections):
        if not 0 <= start < end <= m["end"]:
            raise ValueError((label, start, end))
        duration = end - start
        result.append(dict(index=index, label=label, source_start=start, source_end=end,
                           frames=duration, output_start=offset, output_end=offset + duration))
        offset += duration - DISSOLVE_FRAMES
    if result[-1]["output_end"] != TARGET_FRAMES:
        raise ValueError("The final edit must contain exactly 8970 frames")
    return result


def caption_filters(first, count):
    result = []
    for item in CAPTIONS:
        begin = max(0, item["start"] - first)
        end = min(count, item["end"] - first)
        if begin >= end:
            continue
        enabled = f"enable='between(t,{begin / FPS:.9f},{end / FPS:.9f})'"
        result += [
            f"drawbox=x=0:y=18:w=1920:h=164:color=0x050308:t=fill:{enabled}",
            f"drawbox=x=0:y=180:w=1920:h=2:color=0xB88C4F:t=fill:{enabled}",
        ]
        for line_index, textfile in enumerate(item["files"]):
            result.append("drawtext=fontfile=assets/fonts/Alegreya-Variable.ttf:"
                          f"textfile={textfile}:expansion=none:fontsize=34:fontcolor=0xFAF0D6:"
                          f"x=(w-tw)/2:y={50 + line_index * 55}:{enabled}")
    return "," + ",".join(result) if result else ""


def prepare_captions(timeline):
    m = {entry["name"]: entry["frame"] for entry in timeline["markers"]}
    blocks = [
        (m["book_1_hidden"], m["failure_attempt_start"],
         "Objetivo: cumpra os éditos e termine na casa iluminada.\nWASD move uma casa por tecla. Nas fases iniciais, não há cronômetro."),
        (m["failure_attempt_start"], m["failure_visible"],
         "Ir e voltar soma passos,\nmas pode deixar a distância final menor que a pedida."),
        (m["phase_1_solution"], m["phase_2_start"],
         "Agora, cada passo aumenta a distância do ponto de partida.\nA distância final deve ser igual ao valor da carta."),
        (m["phase_2_start"], m["phase_3_start"],
         "Fase II · Dois éditos\nCumpra os números em ordem: primeiro a carta da esquerda, depois a da direita."),
        (m["book_3_hidden"], m["phase_4_start"],
         "Fase III · As torres atacam em linha reta.\nO numeral de cada peça indica quantas casas ela avança."),
        (m["phase_4_start"], m["phase_5_start"],
         "Fase IV · Quatro torres, dois pares de ataques.\nAs flechas mostram qual par vai agir neste édito."),
        (m["book_5_hidden"], m["phase_5_correct"],
         "Fase V · Bispos atacam pelas diagonais; torres, em linha reta.\nPlaneje a posição final de cada édito para evitar as duas ondas."),
        (m["balance_round_0"], m["balance_round_1"],
         "Compare os valores das duas cartas. Qual lado pesa mais?\nAntes da inclinação, mova o personagem para o lado mais leve."),
        (m["balance_tilt_1"] + 90, m["balance_round_2"],
         "A balança perdeu a indicação visual.\nNa próxima rodada, compare os números das cartas para escolher o lado."),
        (m["balance_round_2"], m["phase_7_transition"] - 10,
         "A interrogação substitui a indicação dos pratos.\nO maior número continua determinando o lado mais pesado."),
        (m["phase_7_ascending"], m["phase_7_descending"],
         "Fase VII · Ordem crescente\nArraste os numerais do menor para o maior. A carta fixa serve de referência."),
        (m["phase_7_descending"], m["phase_8_matching"],
         "Fase VII · Ordem decrescente\nAgora, arraste os numerais do maior para o menor e confirme a resposta."),
        (m["phase_8_matching"], m["phase_8_false_decree"],
         "Fase VIII · Associe as escritas do mesmo número.\nXIV = 10 + 4 = 14 · XVIII = 10 + 5 + 3 = 18 · XIX = 10 + 9 = 19."),
        (m["phase_8_false_decree"], m["false_decree_correct"] + 105,
         "Decreto falso · Encontre a correspondência incorreta.\nCompare o valor do numeral romano com o número indicado."),
        (m["pause_visible"], m["chaotic_start"],
         "O menu de pausa permite retomar a partida ou escolher uma prova.\nChaotic reúne desafios extras, com tempo e ataques combinados."),
        (m["chaotic_start"], m["chaotic_completed"],
         "Chaotic · Desafio extra\nDez segundos para escolher a posição inicial; depois, cumpra os éditos no tempo."),
    ]
    folder = WORK / "captions"
    folder.mkdir(exist_ok=True)
    for index, (start, end, words) in enumerate(blocks):
        files = []
        for line_index, line in enumerate(words.splitlines()):
            path = folder / f"{index:02d}_{line_index}.txt"
            path.write_text(line, encoding="utf-8")
            files.append(path.relative_to(ROOT).as_posix())
        CAPTIONS.append(dict(start=start, end=end, files=files))


def render_piece(piece, raw, clips):
    index, kind, first, second, count, closing = piece
    destination = clips / f"{index:02d}.mkv"
    args = [FFMPEG, "-hide_banner", "-y", "-filter_complex_threads", "1",
            "-threads", "2", "-ss", str(first / FPS), "-i", str(raw)]
    if kind == "transition":
        args += ["-threads", "2", "-ss", str(second / FPS), "-i", str(raw)]
        filters = (
            "[0:v]trim=duration=0.3,settb=AVTB,setpts=PTS-STARTPTS,format=yuv420p"
            + caption_filters(first, count) + "[v0];"
            "[1:v]trim=duration=0.3,settb=AVTB,setpts=PTS-STARTPTS,format=yuv420p"
            + caption_filters(second, count) + "[v1];"
            "[v0][v1]xfade=transition=fade:duration=0.3:offset=0,format=yuv420p[v];"
            "[0:a]atrim=duration=0.3,asetpts=PTS-STARTPTS[a0];"
            "[1:a]atrim=duration=0.3,asetpts=PTS-STARTPTS[a1];"
            "[a0][a1]acrossfade=d=0.3:c1=tri:c2=tri[a]"
        )
        args += ["-filter_complex", filters, "-map", "[v]", "-map", "[a]"]
    else:
        video = "format=yuv420p,setsar=1" + caption_filters(first, count)
        audio = "anull"
        if closing:
            fade_start = count / FPS - 1
            video += f",fade=t=out:st={fade_start}:d=1"
            audio += f",afade=t=out:st={fade_start}:d=1"
        args += ["-map", "0:v:0", "-map", "0:a:0", "-vf", video, "-af", audio]
    args += ["-t", str(count / FPS), "-frames:v", str(count), "-r", str(FPS),
             "-c:v", "libx264", "-preset", "medium", "-crf", "18", "-profile:v", "high",
             "-pix_fmt", "yuv420p", "-threads", "3", "-c:a", "pcm_s16le",
             "-ar", "48000", "-ac", "2", str(destination)]
    command(args, clips / f"{index:02d}.log")
    print(f"PIECE {index + 1}: {kind} ({count / FPS:.2f}s)", flush=True)
    return destination


def render(sections, raw, clips, output):
    # Encode one or two source ranges at a time to bound memory on a 16 GB PC.
    # PCM stays lossless until the final AAC pass; each video frame is encoded once.
    pieces = []
    for index, section in enumerate(sections):
        if index:
            previous = sections[index - 1]
            pieces.append((len(pieces), "transition", previous["source_end"] - DISSOLVE_FRAMES,
                           section["source_start"], DISSOLVE_FRAMES, False))
        first = section["source_start"] + (DISSOLVE_FRAMES if index else 0)
        last = section["source_end"] - (DISSOLVE_FRAMES if index < len(sections) - 1 else 0)
        pieces.append((len(pieces), "core", first, None, last - first, index == len(sections) - 1))
    if sum(piece[4] for piece in pieces) != TARGET_FRAMES:
        raise ValueError("Incorrect piece duration")
    with ThreadPoolExecutor(max_workers=2) as executor:
        jobs = [executor.submit(render_piece, piece, raw, clips) for piece in pieces]
        for job in as_completed(jobs):
            job.result()
    listing = clips / "concat.txt"
    listing.write_text("\n".join(f"file '{index:02d}.mkv'" for index in range(len(pieces))), encoding="utf-8")
    command([FFMPEG, "-hide_banner", "-y", "-f", "concat", "-safe", "0", "-i", str(listing),
             "-map", "0:v:0", "-map", "0:a:0", "-c:v", "copy", "-c:a", "aac", "-b:a", "192k",
             "-af", "alimiter=limit=0.95:level=false", "-ar", "48000", "-ac", "2", "-t", "299",
             "-movflags", "+faststart", "-metadata", "title=Queen's Trial - Demonstracao N2",
             "-metadata", "comment=Gameplay original, sem narracao. Full HD, 30 fps.", str(output)],
            WORK / "final_encode.log")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--plan-only", action="store_true")
    options = parser.parse_args()
    timeline = json.loads((WORK / "timeline.json").read_text(encoding="utf-8"))
    sections = plan(timeline)
    (WORK / "edit_plan.json").write_text(json.dumps(sections, ensure_ascii=False, indent=2), encoding="utf-8")
    for section in sections:
        print(f"{section['output_start'] / FPS:7.2f}s {section['label']}", flush=True)
    if options.plan_only:
        return
    if not FFMPEG or not FFPROBE:
        raise SystemExit("ffmpeg and ffprobe are required")
    options.output_dir.mkdir(parents=True, exist_ok=True)
    clips = WORK / "clips"
    clips.mkdir(exist_ok=True)
    raw = WORK / "queens_trial_raw.avi"
    output = options.output_dir / "Queens_Trial_N2_1080p.mp4"
    prepare_captions(timeline)
    render(sections, raw, clips, output)
    probe = subprocess.check_output([FFPROBE, "-v", "error", "-count_frames",
                                    "-show_streams", "-show_format", "-of", "json", str(output)])
    metadata = json.loads(probe)
    video = next(stream for stream in metadata["streams"] if stream["codec_type"] == "video")
    audio = next(stream for stream in metadata["streams"] if stream["codec_type"] == "audio")
    assert (video["width"], video["height"], video["r_frame_rate"]) == (1920, 1080, "30/1")
    assert int(video["nb_read_frames"]) == TARGET_FRAMES
    assert 298.9 <= float(metadata["format"]["duration"]) < 300.0
    assert audio["channels"] == 2 and audio["sample_rate"] == "48000"
    (options.output_dir / "validacao_tecnica.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"FINAL_VALIDATED: {output}", flush=True)


if __name__ == "__main__":
    main()
