# Instrucciones: `transcribe_diarize.py`

## Qué hace el script

Toma un archivo de audio o vídeo, lo transcribe con Whisper, identifica quién habla en cada momento (diarización) y agrupa las palabras en unidades entonativas separadas por pausas o cambios de hablante. Genera tres archivos de salida en la misma carpeta que el audio:

| Archivo | Uso |
|---------|-----|
| `.TextGrid` | Praat |
| `.eaf` | ELAN |
| `.json` | transcripción completa con timestamps |

Para obtener alineación fonética precisa (phones + words con precisión ~10 ms), usa el script complementario `mfa_realign.py` sobre los TextGrids generados aquí.

---

## 1. Instalación (una sola vez)

Abre la Terminal y ejecuta:

```bash
pip install -r requirements.txt
```

La primera vez que uses el script descargará los modelos (~2 GB). Las siguientes ejecuciones son inmediatas.

---

## 2. Configurar el token de HuggingFace (una sola vez)

La diarización (identificación de hablantes) requiere aceptar dos licencias y crear un token gratuito:

1. Crea una cuenta en [huggingface.co](https://huggingface.co) si no tienes una.
2. Acepta la licencia en: [pyannote/speaker-diarization-3.1](https://huggingface.co/pyannote/speaker-diarization-3.1)
3. Acepta la licencia en: [pyannote/segmentation-3.0](https://huggingface.co/pyannote/segmentation-3.0)
4. Crea un token de acceso (*Read*) en: [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens)
5. Añade el token a tu entorno para que sea permanente. Edita el archivo `~/.zshrc` y añade al final:

```bash
export HF_TOKEN=hf_tu_token_aqui
```

Luego cierra y vuelve a abrir la Terminal, o ejecuta `source ~/.zshrc`.

---

## 3. Uso básico

Coloca el script en la misma carpeta que los archivos de audio/vídeo, o indica la ruta completa al archivo. Luego, en la Terminal:

```bash
# Un solo archivo
python transcribe_diarize.py entrevista.wav

# Indicar el número exacto de hablantes (más preciso)
python transcribe_diarize.py entrevista.wav --num-speakers 2

# Especificar idioma español (recomendado)
python transcribe_diarize.py entrevista.wav --language es --num-speakers 2

# Procesar varios archivos a la vez
python transcribe_diarize.py *.wav --language es

# Archivo de vídeo
python transcribe_diarize.py entrevista.mp4 --language es --num-speakers 3
```

---

## 4. Opciones principales

| Opción | Descripción | Ejemplo |
|--------|-------------|---------|
| `--language` | Código de idioma (si se omite, se detecta automáticamente) | `--language es` |
| `--num-speakers` | Número exacto de hablantes | `--num-speakers 2` |
| `--min-speakers` / `--max-speakers` | Rango si no sabes exactamente cuántos hay | `--min-speakers 2 --max-speakers 4` |
| `--pause` | Pausa mínima en segundos para delimitar unidades entonativas (por defecto: 0.3 s) | `--pause 0.5` |
| `--model` | Modelo Whisper (por defecto: `large-v3-turbo`) | `--model large-v3` |
| `--hf-token` | Token HuggingFace si no lo tienes en la variable de entorno | `--hf-token hf_xxx` |

### Modelos disponibles (de más rápido a más preciso)

| Modelo | Velocidad (Mac M-series) | Calidad |
|--------|--------------------------|---------|
| `large-v3-turbo` | ~10× real-time | Alta — **recomendado** |
| `large-v3` | ~5× real-time | Máxima |
| `medium` | ~20× real-time | Media |

---

## 5. Re-exportar sin volver a transcribir

Si ya tienes el `.json` y quieres regenerar el TextGrid o el ELAN —por ejemplo, para cambiar el umbral de pausa o añadir diarización a una transcripción anterior— usa `--from-json`:

```bash
# Re-exportar con umbral de pausa diferente
python transcribe_diarize.py entrevista.json --from-json --pause 0.5

# Re-exportar y añadir diarización
python transcribe_diarize.py entrevista.json --from-json --num-speakers 2

# También puedes pasar el audio directamente (busca el .json con el mismo nombre)
python transcribe_diarize.py entrevista.wav --from-json --pause 0.4
```

---

## 6. Notas

- Los archivos de salida se guardan **en la misma carpeta** que el audio, con el mismo nombre base.
- En un Mac con chip M-series la transcripción usa el Neural Engine y es aproximadamente **10× más rápida que el tiempo real**.
- Si omites `--language`, Whisper detecta el idioma automáticamente, pero indicarlo explícitamente (`--language es`) mejora la precisión y la velocidad.
- Si la diarización falla (por ejemplo, si el token no está configurado), todo el audio se asigna a un único hablante `SPEAKER_00` y la transcripción se guarda igualmente.
