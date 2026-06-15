# Etiquetador de datos orales — v2.0

> *Oralstats — explorador prosódico*

Aplicación Shiny en R para la anotación lingüística y el análisis acústico de corpus orales. Permite cargar audio y transcripción, navegar grupo entonativo a grupo entonativo, calcular automáticamente métricas prosódicas, anotar con categorías totalmente configurables y explorar los resultados con tablas, figuras tipo Praat y gráficos estadísticos.

![Pantalla inicial del etiquetador](imgs/1_etiquetador_pantalla_inicial.png)

---

## Novedades de la v2.0

- **Editor de variables de anotación**: ahora todas las categorías (etiquetas y valores posibles) son configurables desde la propia interfaz, sin tocar el código.
- **Nueva pestaña *Emociones*** con tono emocional de Ekman e intensidad.
- **Pestaña *Métricas*** con un informe prosódico textual completo de la fila activa.
- **Pestaña *Praatpicture*** para renderizar figuras multipanel al estilo Praat.
- **Pestaña *Estadísticas*** con gráficos de barras y diagramas de caja sobre las anotaciones.
- Panel lateral con **navegación secuencial**, reproducción del segmento y de su contexto previo/posterior ajustable.

---

## Funcionalidades principales

La app se organiza en ocho pestañas superiores:

| Pestaña | Función |
|---|---|
| **Anotaciones** | Formulario de etiquetado dividido en cinco bloques temáticos (ver más abajo). |
| **Tabla** | Tabla navegable y filtrable de todas las filas, con columna de `contexto` opcional. |
| **Contexto** | Muestra las N filas anteriores y posteriores a la selección actual, resaltando la fila activa. |
| **Análisis fonético** | Oscilograma, espectrograma y curva melódica (F0) del segmento; reproducción y cálculo de F0/intensidad de todos los segmentos. |
| **Métricas** | Informe prosódico textual de la fila activa (pausas, velocidad de habla, F0, intensidad). |
| **Praatpicture** | Figura multipanel al estilo Praat (oscilograma, espectrograma, F0, intensidad) renderizable a la carta. |
| **Estadísticas** | Gráficos de barras (variables categóricas) y diagramas de caja (variables numéricas). |
| **Configuración** | Editor de variables de anotación: personaliza etiquetas y categorías. |

### Carga de material y navegación

- **Carga de material**: audio en WAV, MP3 o MP4 + transcripción en CSV, TXT o TextGrid (Praat). Conversión automática de MP3/MP4 a WAV para el análisis.
- **Navegación secuencial**: botones ⬅ Anterior / Siguiente ➡, salto directo a cualquier fila e indicador de posición (`Fila X de N`).
- **Reproducción**: del segmento aislado o con contexto previo/posterior, ajustando los segundos *Antes (s)* y *Después (s)*.
- **Pares precargados**: coloca audio + transcripción con el mismo nombre base en `www/audios/` y la app los detecta automáticamente.

### Análisis acústico automático por segmento

Las métricas se recalculan automáticamente al cambiar de fila:

- F0 media y mediana (Hz), con `wrassp::ksvF0`
- Desviación típica y rango de F0 (en semitonos / p10–p90)
- Inflexión global y tonema final (último 20 %), con su patrón melódico
- Intensidad media (dB)
- Velocidad de habla (palabras/s y fonemas/s) y pausas anterior/posterior

![Análisis fonético: oscilograma, espectrograma y curva melódica](imgs/5_analisis_fonetico.png)

![Métricas: informe prosódico textual de la fila activa](imgs/6_valores_foneticos.png)

![Praatpicture: figura multipanel al estilo Praat](imgs/7_praatpicture.png)

### Anotación

El formulario de **Anotaciones** se divide en cinco bloques. Las categorías que se muestran son las de fábrica, pero pueden modificarse por completo desde **Configuración**:

| Bloque | Ejemplos de categorías |
|---|---|
| **Estructura** | Tipo de enunciado, modalidad oracional, estatus informativo, complejidad sintáctica, reformulación / expansión, función discursiva global, referencia a discurso ajeno, temporalidad del contenido |
| **Pragmática** | Función pragmática, función interpersonal, atenuación, intensificación, cortesía, imagen del otro, autoimagen |
| **Discurso e interacción** | Movimiento conversacional, gestión del turno, relación con el turno previo, dinámica interactiva, marcador discursivo, función fática, deixis, recursos coloquiales |
| **Paralingüístico / no verbal** | Sonidos no verbales, solapamientos no verbales, ruido articulatorio, fenómenos respiratorios, turnos no verbales, ruido ambiental, actitud vocal |
| **Emociones** | Tono emocional de Ekman (Neutra, Alegría, Tristeza, Miedo, Ira, Asco, Sorpresa, Desprecio) e intensidad (1–5) |

![Anotación: bloque de Emociones (tono emocional de Ekman e intensidad)](imgs/2_anotacion.png)

### Tablas y contexto

![Tabla de anotación con columna de contexto](imgs/3_tabla_anotacion_contexto.png)

![Vista de contexto: N filas anteriores y posteriores a la selección actual](imgs/4_tabla_contexto.png)

### Estadísticas

![Estadísticas: gráfico de barras de una variable categórica](imgs/8_grafico_barras.png)

![Estadísticas: diagrama de caja de una variable numérica](imgs/9_grafico_boxplot.png)

### Configuración (editor de variables)

Cada variable de anotación (`anot1`, `anot2`, …) tiene una etiqueta editable y su lista de categorías (una por línea). Así, el mismo etiquetador sirve para esquemas de anotación distintos sin reprogramar nada.

![Editor de variables de anotación](imgs/10_edicion_variables.png)

### Persistencia y exportación

- **Guardado automático**: al navegar o anotar, los datos se persisten en un TSV (`analisis_<nombre>.txt`) y en un consolidado (`analisis_todos.txt`).
- **Sistema de backup**: copia de seguridad con marca de tiempo en `backup/` al cargar datos.
- **Exportación**: CSV, TXT y volcado directo a Google Sheets.

---

## Requisitos

- R ≥ 4.1
- Paquetes R:

```r
install.packages(c(
  "shiny", "DT", "tuneR", "shinyjs", "shinythemes",
  "seewave", "wrassp", "praatpicture", "tools", "av", "rPraat"
))
```

> `rPraat` es necesario solo para leer archivos TextGrid de Praat; `praatpicture` solo para la pestaña *Praatpicture*.

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
├── etiquetador.R            # Código principal de la app
├── imgs/                    # Capturas de ejemplo (este README)
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

1. Carga el audio y la transcripción (pestaña **Precargados** o **Cargar**).
2. Navega con **⬅ Anterior / Siguiente ➡** o salta directamente a una fila.
3. Escucha el segmento con **▶ Segmento** o con contexto previo/posterior ajustable.
4. Las métricas acústicas se calculan automáticamente al cambiar de fila (pestañas *Análisis fonético* y *Métricas*).
5. Rellena las anotaciones en los bloques de **Anotaciones** y pulsa **Guardar**.
6. Si lo necesitas, ajusta el esquema de etiquetas en **Configuración**.
7. Explora los resultados en **Estadísticas** y exporta como CSV, TXT o Google Sheets.

---

## Licencia

© 2025 Adrián Cabedo Nebot.  
Distribuido bajo licencia **Creative Commons Atribución 4.0 Internacional (CC BY 4.0)**.  
Se permite el uso, distribución y modificación siempre que se cite la autoría.  
[Ver texto completo de la licencia](https://creativecommons.org/licenses/by/4.0/deed.es)
