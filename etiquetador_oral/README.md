# Etiquetador de datos orales — v1.0

Aplicación Shiny en R para la anotación lingüística y el análisis acústico de corpus orales. Permite cargar archivos de audio y transcripción, navegar segmento a segmento, calcular métricas prosódicas automáticamente y exportar las anotaciones en varios formatos.

---

## Funcionalidades principales

- **Carga de material**: audio en WAV, MP3 o MP4 + transcripción en CSV, TXT o TextGrid (Praat). Conversión automática de MP3/MP4 a WAV para el análisis.
- **Navegación secuencial**: botones Anterior / Siguiente, salto directo a cualquier fila, e indicador de posición.
- **Análisis acústico automático** por segmento:
  - F0 media (Hz) calculada con `wrassp::ksvF0`
  - Rango de F0 en semitonos
  - Inflexión global y tonema final (último 20 %)
  - Patrón melódico del tonema (ascendente, descendente, plana, etc.)
  - Intensidad media (dB RMS)
- **Visualizaciones**: oscilograma, espectrograma y curva de pitch (con `seewave`).
- **33 categorías de anotación** organizadas en cuatro pestañas:
  | Pestaña | Categorías |
  |---|---|
  | Estructura | Tipo de enunciado, modalidad oracional, estatus informativo, complejidad sintáctica, reformulación, función discursiva, discurso ajeno, temporalidad |
  | Pragmática | Función pragmática, función interpersonal, atenuación (presencia, orientación, procedimiento), intensificación, cortesía, imagen del otro, autoimagen |
  | Discurso e interacción | Movimiento conversacional, gestión del turno, relación con el turno previo, dinámica interactiva, marcador discursivo, función fática, deixis, recursos coloquiales |
  | Paralingüístico / no verbal | Sonidos no verbales, tono emocional (Ekman), solapamientos no verbales, ruido articulatorio, fenómenos respiratorios, turnos no verbales, ruido ambiental, actitud vocal |
- **Vista de contexto**: muestra las N filas anteriores y posteriores a la selección actual (N configurable).
- **Guardado automático**: cada vez que se navega o anota, los datos se persisten en un archivo TSV (`analisis_<nombre>.txt`) y en un consolidado (`analisis_todos.txt`).
- **Sistema de backup**: copia de seguridad con marca de tiempo en la subcarpeta `backup/` al cargar datos.
- **Exportación**: CSV, TXT y volcado directo a Google Sheets.
- **Pares precargados**: coloca pares audio + transcripción con el mismo nombre base en `www/audios/` y la app los detecta automáticamente.

---

## Requisitos

- R ≥ 4.1
- Paquetes R:

```r
install.packages(c(
  "shiny", "DT", "tuneR", "shinyjs", "shinythemes",
  "seewave", "wrassp", "tools", "av", "rPraat"
))
```

> `rPraat` es necesario solo para leer archivos TextGrid de Praat.

---

## Instalación y uso

```r
# Clonar el repositorio y situarse en la carpeta
setwd("ruta/a/etiquetador_oral")

# Lanzar la aplicación
shiny::runApp("etiquetador.R")
```

### Organización de archivos

```
etiquetador_oral/
├── etiquetador.R       # Código principal de la app
├── www/
│   └── audios/              # Pares precargados (mismo nombre base)
│       ├── entrevista1.mp3
│       └── entrevista1.csv
├── backup/                  # Backups automáticos (se crea al cargar datos)
├── analisis_<nombre>.txt    # Análisis individual por corpus (generado automáticamente)
└── analisis_todos.txt       # Consolidado de todos los corpus (generado automáticamente)
```

### Formato de la transcripción (CSV / TXT)

La transcripción debe incluir al menos estas columnas:

| Columna | Descripción |
|---|---|
| `speaker` | Identificador del hablante |
| `start` | Tiempo de inicio en segundos |
| `end` | Tiempo de fin en segundos |
| `label` | Transcripción del segmento |

---

## Flujo de trabajo

1. Carga el audio y la transcripción (pestaña **📁 Precargados** o **📤 Cargar**).
2. Navega con los botones **⬅ Anterior / Siguiente ➡** o salta directamente a una fila.
3. Escucha el segmento con **▶️ Segmento** o con contexto previo/posterior ajustable.
4. Las métricas acústicas se calculan automáticamente al cambiar de fila.
5. Rellena las anotaciones en las pestañas de la sección **✍️ Anotaciones** y pulsa **💾 Guardar**.
6. Exporta el resultado completo como CSV, TXT o Google Sheets.

---

## Licencia

© 2025 Adrián Cabedo Nebot.  
Distribuido bajo licencia **Creative Commons Atribución 4.0 Internacional (CC BY 4.0)**.  
Se permite el uso, distribución y modificación siempre que se cite la autoría.  
[Ver texto completo de la licencia](https://creativecommons.org/licenses/by/4.0/deed.es)
