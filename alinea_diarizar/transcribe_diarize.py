#!/usr/bin/env python3
"""
transcribe_diarize.py

Transcribe + diariza + exporta a TextGrid (Praat) y ELAN (.eaf).
Agrupa palabras en unidades entonativas (pausa ≥ umbral O cambio de hablante).

════════════════════════════════════════════════════════════════════════════
BACKENDS (selección automática)
════════════════════════════════════════════════════════════════════════════

  Mac Apple Silicon  →  mlx-whisper   (Neural Engine, ~10× real-time)
  Windows/Linux CUDA →  whisperx      (faster-whisper float16, ~50-100×)
  CPU                →  whisperx      (int8)

  Nota: mlx-whisper se ejecuta en subproceso aislado para evitar conflictos
  de OpenMP entre ctranslate2 (whisperx) y MLX (Apple).

════════════════════════════════════════════════════════════════════════════
MODELOS RECOMENDADOS
════════════════════════════════════════════════════════════════════════════

  Mac (mlx):
    large-v3-turbo   [RECOMENDADO — ~10× real-time en M-series]
    large-v3         [máxima calidad, ~5× real-time]
    medium           [más rápido, menor calidad]

  CUDA/CPU (whisperx):
    large-v3-turbo   [RECOMENDADO]
    large-v3         [máxima calidad]

  Parakeet (NVIDIA): solo inglés — no apto para español.

════════════════════════════════════════════════════════════════════════════
INSTALACIÓN
════════════════════════════════════════════════════════════════════════════

  Mac:
    pip install mlx-whisper whisperx praatio pympi-ling

  Windows/Linux CUDA — instala PyTorch con CUDA primero:
    pip install torch --index-url https://download.pytorch.org/whl/cu121
    pip install whisperx praatio pympi-ling

  Diarización (todas las plataformas):
    1. Acepta licencias en HuggingFace:
       https://huggingface.co/pyannote/speaker-diarization-3.1
       https://huggingface.co/pyannote/segmentation-3.0
    2. Crea token en https://huggingface.co/settings/tokens
    3. export HF_TOKEN=hf_tu_token   (o --hf-token)

════════════════════════════════════════════════════════════════════════════
USO
════════════════════════════════════════════════════════════════════════════

  python transcribe_diarize.py audio.wav
  python transcribe_diarize.py *.wav *.mp4 --language es
  python transcribe_diarize.py f.wav --hf-token hf_xxx --num-speakers 2
  python transcribe_diarize.py f.wav --model large-v3 --pause 0.25
  python transcribe_diarize.py f.wav --backend whisperx   # forzar backend

"""

import argparse
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

os.environ.setdefault("KMP_DUPLICATE_LIB_OK", "TRUE")

SUPPORTED_EXTENSIONS = {".wav", ".mp3", ".mp4", ".mkv", ".avi", ".mov", ".m4a", ".ogg", ".flac"}

MLX_MODEL_REPOS = {
    "large-v3-turbo": "mlx-community/whisper-large-v3-turbo",
    "large-v3":       "mlx-community/whisper-large-v3-mlx",
    "medium":         "mlx-community/whisper-medium-mlx",
    "small":          "mlx-community/whisper-small-mlx",
    "base":           "mlx-community/whisper-base-mlx",
    "tiny":           "mlx-community/whisper-tiny-mlx",
}

# Script que se lanza en subproceso aislado (sin torch/ctranslate2)
# Escribe el resultado a un fichero tmp en lugar de stdout para evitar
# problemas con buffers de pipe en archivos de audio muy largos.
_MLX_SUBPROCESS_SCRIPT = r"""
import json, sys, os
os.environ['KMP_DUPLICATE_LIB_OK'] = 'TRUE'
import mlx_whisper

audio_path  = sys.argv[1]
repo        = sys.argv[2]
language    = sys.argv[3] if sys.argv[3] != 'None' else None
output_file = sys.argv[4]

result = mlx_whisper.transcribe(
    audio_path,
    path_or_hf_repo=repo,
    language=language,
    word_timestamps=True,
    verbose=False,
)

import numpy as np

class Encoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, np.floating): return float(o)
        if isinstance(o, np.integer):  return int(o)
        if isinstance(o, np.ndarray):  return o.tolist()
        return super().default(o)

with open(output_file, 'w', encoding='utf-8') as fh:
    json.dump(result, fh, ensure_ascii=False, cls=Encoder)
"""


# ── detección de plataforma ────────────────────────────────────────────────

def detect_backend() -> tuple[str, str, str]:
    """(backend, device, compute_type)"""
    if sys.platform == "darwin":
        try:
            import mlx.core  # noqa: F401 — verifica que MLX está disponible
            return "mlx", "mps", "int8"
        except ImportError:
            pass
    import torch
    if torch.cuda.is_available():
        return "whisperx", "cuda", "float16"
    return "whisperx", "cpu", "int8"


# ── transcripción ─────────────────────────────────────────────────────────

def transcribe_mlx(audio_path: Path, model_name: str, language: str | None) -> dict:
    """
    Lanza mlx-whisper en un subproceso aislado para evitar el conflicto
    OMP entre ctranslate2 y MLX que causa segfault.
    El progreso se imprime en tiempo real (stderr pasa al terminal).
    """
    repo = MLX_MODEL_REPOS.get(model_name, model_name)
    print(f"  Backend: mlx-whisper | modelo: {repo.split('/')[-1]}")

    with tempfile.NamedTemporaryFile(mode="w", suffix=".py", delete=False) as f:
        f.write(_MLX_SUBPROCESS_SCRIPT)
        script_path = f.name

    out_fd, out_path = tempfile.mkstemp(suffix=".json")
    os.close(out_fd)
    try:
        proc = subprocess.Popen(
            [sys.executable, script_path, str(audio_path), repo, str(language), out_path],
            stdout=None,
            stderr=None,   # progreso visible en terminal
        )
        proc.wait(timeout=7200)
        if proc.returncode != 0:
            raise RuntimeError(f"mlx-whisper falló (código {proc.returncode})")
        with open(out_path, encoding="utf-8") as fh:
            return json.load(fh)
    finally:
        os.unlink(script_path)
        if os.path.exists(out_path):
            os.unlink(out_path)


def transcribe_whisperx(audio_path: Path, model_name: str, language: str | None,
                        batch_size: int, device: str, compute_type: str) -> dict:
    import whisperx
    print(f"  Backend: whisperx | modelo: {model_name} | device: {device}")
    audio = whisperx.load_audio(str(audio_path))
    model = whisperx.load_model(model_name, device, compute_type=compute_type, language=language)
    result = model.transcribe(audio, batch_size=batch_size, language=language)
    del model

    lang = result.get("language") or language or "?"
    print(f"  Alineando palabras (wav2vec2, idioma: {lang})...")
    try:
        align_model, metadata = whisperx.load_align_model(language_code=lang, device=device)
        result = whisperx.align(
            result["segments"], align_model, metadata, audio, device,
            return_char_alignments=False,
        )
        del align_model
    except Exception as exc:
        print(f"  [WARN] Alineación wav2vec2 falló ({exc}). Timestamps propios de Whisper.")
    return result


# ── diarización ────────────────────────────────────────────────────────────

def diarize_and_assign(result: dict, audio_path: Path, device: str,
                       hf_token: str, num_speakers, min_speakers, max_speakers) -> dict:
    import torch
    import whisperx
    from whisperx.diarize import DiarizationPipeline

    diarize_device = torch.device(device)
    pipeline = DiarizationPipeline(use_auth_token=hf_token, device=diarize_device)

    audio = whisperx.load_audio(str(audio_path))
    kw: dict = {}
    if num_speakers:
        kw["num_speakers"] = num_speakers
    else:
        if min_speakers: kw["min_speakers"] = min_speakers
        if max_speakers: kw["max_speakers"] = max_speakers

    try:
        from pyannote.audio.pipelines.utils.hook import ProgressHook
        with ProgressHook() as hook:
            diarize_segs = pipeline(audio, hook=hook, **kw)
    except Exception:
        diarize_segs = pipeline(audio, **kw)
    return whisperx.assign_word_speakers(diarize_segs, result)


# ── pipeline principal ────────────────────────────────────────────────────

def run_pipeline(audio_path: Path, args, backend: str,
                 device: str, compute_type: str) -> tuple[dict, float]:
    import whisperx

    print(f"\n── {audio_path.name} ──")

    # Duración (necesita cargar audio brevemente)
    audio_np = whisperx.load_audio(str(audio_path))
    duration = len(audio_np) / 16_000
    del audio_np
    print(f"  Duración: {duration/60:.1f} min")

    print(f"  [1/3] Transcribiendo...")
    if backend == "mlx":
        result = transcribe_mlx(audio_path, args.model, args.language)
    else:
        result = transcribe_whisperx(
            audio_path, args.model, args.language, args.batch_size, device, compute_type
        )

    lang = result.get("language") or args.language or "?"
    print(f"        idioma: {lang}")

    if args.hf_token:
        print(f"  [2/3] Diarizando y asignando hablantes (pyannote)...")
        try:
            result = diarize_and_assign(
                result, audio_path, device, args.hf_token,
                args.num_speakers, args.min_speakers, args.max_speakers,
            )
        except Exception as exc:
            print(f"  [WARN] Diarización falló ({exc}). Todo → SPEAKER_00.")
            for seg in result.get("segments", []):
                seg.setdefault("speaker", "SPEAKER_00")
    else:
        print(f"  [2/3] Diarización omitida (sin HF_TOKEN) → SPEAKER_00")
        for seg in result.get("segments", []):
            seg.setdefault("speaker", "SPEAKER_00")

    print(f"  [3/3] Exportando...")
    return result, duration


# ── datos ─────────────────────────────────────────────────────────────────

MIN_WORD_DUR = 0.01  # praatio rechaza intervalos de duración cero


def sanitize_words(words: list[dict]) -> list[dict]:
    """
    Ordena palabras, corrige duración cero, elimina duplicados exactos
    y resuelve solapamientos truncando el final de la palabra anterior.
    """
    # Duración mínima y redondeo
    processed = []
    for w in words:
        start = round(float(w["start"]), 4)
        end   = round(float(w["end"]),   4)
        if end <= start:
            end = round(start + MIN_WORD_DUR, 4)
        processed.append({**w, "start": start, "end": end})

    # Ordenar por inicio
    processed.sort(key=lambda x: x["start"])

    # Eliminar duplicados exactos (mismo start, end y texto)
    seen = set()
    unique = []
    for w in processed:
        key = (w["start"], w["end"], w["word"])
        if key not in seen:
            seen.add(key)
            unique.append(w)

    # Resolver solapamientos: truncar fin de la anterior si solapa con la siguiente
    out = []
    for w in unique:
        if out and w["start"] < out[-1]["end"]:
            # Truncar la anterior para que termine justo antes de la actual
            prev = dict(out[-1])
            prev["end"] = round(w["start"] - 0.001, 4)
            if prev["end"] <= prev["start"]:
                out.pop()   # demasiado corta — descartar la anterior
            else:
                out[-1] = prev
        out.append(w)
    return out


def collect_words(result: dict) -> list[dict]:
    words = []
    for seg in result.get("segments", []):
        seg_speaker = seg.get("speaker") or "SPEAKER_00"
        for w in seg.get("words", []):
            if "start" not in w or "end" not in w:
                continue
            words.append({
                "word":    w["word"].strip(),
                "start":   float(w["start"]),
                "end":     float(w["end"]),
                "speaker": w.get("speaker") or seg_speaker,
            })
    return sanitize_words(words)


def group_intonation_units(words: list[dict], pause: float = 0.3) -> list[list[dict]]:
    """Nueva UE si pausa ≥ umbral O cambia el hablante."""
    if not words:
        return []
    units: list[list[dict]] = []
    current = [words[0]]
    for prev, curr in zip(words, words[1:]):
        if curr["start"] - prev["end"] >= pause or curr["speaker"] != prev["speaker"]:
            units.append(current)
            current = [curr]
        else:
            current.append(curr)
    units.append(current)
    return units



# ── exportación ───────────────────────────────────────────────────────────

def export_json(words, iu_units, duration, out: Path):
    data = {
        "duration_s": round(duration, 4),
        "words": words,
        "intonation_units": [
            {
                "speaker": u[0]["speaker"],
                "start":   u[0]["start"],
                "end":     u[-1]["end"],
                "text":    " ".join(w["word"] for w in u),
                "words":   u,
            }
            for u in iu_units
        ],
    }
    out.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"  → JSON:     {out.name}")


def export_textgrid(words, iu_units, duration, out: Path):
    from praatio import textgrid as tglib
    from praatio.utilities.constants import Interval

    def make_tier(name, triples):
        return tglib.IntervalTier(
            name, [Interval(s, e, lbl) for s, e, lbl in triples], 0, duration
        )

    tg = tglib.Textgrid()
    tg.addTier(make_tier("words",
        [(w["start"], w["end"], w["word"]) for w in words]))
    tg.addTier(make_tier("intonation_units",
        [(u[0]["start"], u[-1]["end"], " ".join(w["word"] for w in u)) for u in iu_units]))
    tg.addTier(make_tier("speakers",
        [(u[0]["start"], u[-1]["end"], u[0]["speaker"]) for u in iu_units]))

    tg.save(str(out), format="long_textgrid", includeBlankSpaces=True)
    print(f"  → TextGrid: {out.name}")


def export_elan(words, iu_units, media_path: Path, out: Path):
    import pympi

    eaf = pympi.Eaf(author="transcribe_diarize.py")
    for name in list(eaf.get_tier_names()):
        eaf.remove_tier(name)

    suffix = media_path.suffix.lower()
    mime = "audio/x-wav" if suffix == ".wav" else "video/mp4"
    eaf.add_linked_file(str(media_path.resolve()), relpath=media_path.name, mimetype=mime)

    speakers = sorted({u[0]["speaker"] for u in iu_units})
    for spk in speakers:
        eaf.add_tier(spk)
        eaf.add_tier(f"{spk}_words")

    for unit in iu_units:
        spk = unit[0]["speaker"]
        eaf.add_annotation(spk,
            int(unit[0]["start"] * 1000), int(unit[-1]["end"] * 1000),
            " ".join(w["word"] for w in unit))

    for w in words:
        eaf.add_annotation(f"{w['speaker']}_words",
            int(w["start"] * 1000), int(w["end"] * 1000), w["word"])

    eaf.to_file(str(out))
    print(f"  → ELAN:     {out.name}")


# ── orquestación ──────────────────────────────────────────────────────────

def process_file(file_path: str, args, backend: str, device: str, compute_type: str):
    p = Path(file_path)

    # ── modo --from-json: cargar transcripción existente y re-exportar ──
    if getattr(args, "from_json", False):
        json_path = p if p.suffix == ".json" else p.with_suffix(".json")
        # Buscar el fichero de media asociado (.wav preferido, luego .mp4)
        for ext in (".wav", ".mp4", ".mkv", ".mp3"):
            candidate = json_path.with_suffix(ext)
            if candidate.exists():
                media_path = candidate
                break
        else:
            media_path = json_path.with_suffix(".wav")

        if not json_path.exists():
            print(f"[ERROR] No existe JSON: {json_path}", file=sys.stderr)
            return
        print(f"\n── {json_path.name} (desde JSON) ──")
        data = json.loads(json_path.read_text(encoding="utf-8"))
        duration = data["duration_s"]
        words = data.get("words") or [
            w for u in data.get("intonation_units", []) for w in u["words"]
        ]
        words = sanitize_words(words)

        # Diarizar si hay token y el fichero de media existe
        if args.hf_token and media_path.exists():
            print(f"  Diarizando sobre {media_path.name} (pyannote)...")
            try:
                # Construir un result dict mínimo compatible con assign_word_speakers
                fake_result = {"segments": [
                    {"start": w["start"], "end": w["end"],
                     "text": w["word"], "words": [w]}
                    for w in words
                ]}
                fake_result = diarize_and_assign(
                    fake_result, media_path, device, args.hf_token,
                    args.num_speakers, args.min_speakers, args.max_speakers,
                )
                words = collect_words(fake_result)
            except Exception as exc:
                print(f"  [WARN] Diarización falló ({exc}). Se mantiene speaker original.")

        out_dir, stem = json_path.parent, json_path.stem
        iu_units = group_intonation_units(words, pause=args.pause)
        export_json(words, iu_units, duration, out_dir / f"{stem}.json")
        export_textgrid(words, iu_units, duration, out_dir / f"{stem}.TextGrid")
        export_elan(words, iu_units, media_path, out_dir / f"{stem}.eaf")
        speakers = sorted({u[0]["speaker"] for u in iu_units})
        print(f"  Listo: {len(words)} palabras · {len(iu_units)} UEs · "
              f"{len(speakers)} hablante(s): {', '.join(speakers)}")
        return

    # ── modo normal: transcribir desde audio/vídeo ──
    if not p.exists():
        print(f"[OMITIDO] No existe: {p}", file=sys.stderr)
        return
    if p.suffix.lower() not in SUPPORTED_EXTENSIONS:
        print(f"[OMITIDO] Extensión no soportada: {p.suffix}", file=sys.stderr)
        return

    result, duration = run_pipeline(p, args, backend, device, compute_type)
    words = collect_words(result)
    if not words:
        print("  [WARN] No se obtuvieron palabras con timestamps.")
        return

    iu_units = group_intonation_units(words, pause=args.pause)
    out_dir, stem = p.parent, p.stem

    export_json(words, iu_units, duration, out_dir / f"{stem}.json")
    export_textgrid(words, iu_units, duration, out_dir / f"{stem}.TextGrid")
    export_elan(words, iu_units, p, out_dir / f"{stem}.eaf")

    speakers = sorted({u[0]["speaker"] for u in iu_units})
    print(f"  Listo: {len(words)} palabras · {len(iu_units)} UEs · "
          f"{len(speakers)} hablante(s): {', '.join(speakers)}")


def main():
    ap = argparse.ArgumentParser(
        description="Transcribe + diariza + exporta TextGrid/ELAN con unidades entonativas",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument("files", nargs="+", help="Ficheros de audio o vídeo")
    ap.add_argument("--model", default="large-v3-turbo",
                    help="Modelo Whisper (defecto: large-v3-turbo)")
    ap.add_argument("--language", default=None,
                    help="Código de idioma (p.ej. es, en). Auto si se omite.")
    ap.add_argument("--backend", choices=["auto", "mlx", "whisperx"], default="auto")
    ap.add_argument("--hf-token", default=os.environ.get("HF_TOKEN"), metavar="TOKEN",
                    help="Token HuggingFace para diarización (o env HF_TOKEN)")
    ap.add_argument("--num-speakers", type=int, default=None)
    ap.add_argument("--min-speakers", type=int, default=None)
    ap.add_argument("--max-speakers", type=int, default=None)
    ap.add_argument("--pause", type=float, default=0.3,
                    help="Umbral de pausa (s) para delimitar UEs (defecto: 0.3)")
    ap.add_argument("--batch-size", type=int, default=12,
                    help="Batch size para backend whisperx (defecto: 12)")
    ap.add_argument("--device", choices=["cuda", "mps", "cpu"], default=None)
    ap.add_argument("--compute-type", choices=["float16", "float32", "int8"], default=None)
    ap.add_argument("--from-json", action="store_true",
                    help="Cargar transcripción desde .json existente y re-exportar "
                         "(evita re-transcribir). Pasa el .json o el fichero de audio.")
    args = ap.parse_args()

    backend, device, compute_type = detect_backend()
    if args.backend != "auto":
        backend = args.backend
    if args.device:
        device = args.device
    if args.compute_type:
        compute_type = args.compute_type

    print(f"Backend: {backend}  |  Dispositivo: {device}  |  Cómputo: {compute_type}")
    if not args.hf_token:
        print("Aviso: HF_TOKEN no configurado — diarización desactivada.")
        print("       Configura 'export HF_TOKEN=hf_xxx' o usa --hf-token.")

    for f in args.files:
        try:
            process_file(f, args, backend, device, compute_type)
        except KeyboardInterrupt:
            print("\nInterrumpido.")
            sys.exit(1)
        except Exception as exc:
            print(f"[ERROR] {f}: {exc}", file=sys.stderr)
            import traceback
            traceback.print_exc()

    print("\nProcesamiento completado.")


if __name__ == "__main__":
    main()
