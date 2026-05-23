# Script de Análisis Prosódico Automático

**Autor:** Adrián Cabedo Nebot  
**Afiliación:** Universitat de València  
**Versión:** 5  
**Herramienta:** [Praat](https://www.fon.hum.uva.nl/praat/) (requiere v6.0 o posterior)

---

## Descripción

Script de Praat que extrae automáticamente medidas prosódicas de los intervalos anotados en TextGrids, procesando por lotes todos los archivos de una carpeta. Para cada intervalo no vacío de cada tier de intervalo genera una fila en un archivo CSV con métricas de F0 e intensidad.

---

## Requisitos

- Praat instalado (descargable en https://www.fon.hum.uva.nl/praat/)
- Archivos de audio en formato `.wav`
- Archivos de anotación `.TextGrid` con el mismo nombre base que los `.wav`
- Los TextGrids deben contener al menos un *interval tier* con intervalos etiquetados

---

## Uso

1. Abre Praat y ve a **Praat > Open Praat script…**
2. Selecciona el archivo `Extraccion_datos.praat` y haz clic en **Run**
3. El script mostrará un formulario de configuración con los parámetros de análisis (ver sección siguiente). Ajústalos y haz clic en **OK**
4. A continuación pedirá tres carpetas mediante diálogos de selección:
   - **Paso 1/3** — carpeta con los archivos `.wav`
   - **Paso 2/3** — carpeta con los archivos `.TextGrid`
   - **Paso 3/3** — carpeta donde se guardará el CSV de salida
5. Confirma las rutas y el script procesará todos los archivos automáticamente
6. El resultado se guarda en `resultados_prosodicos.csv` dentro de la carpeta de salida

> Si un `.wav` no tiene un `.TextGrid` con el mismo nombre, se registra una advertencia en el Info de Praat y se continúa con el siguiente archivo.

---

## Parámetros de análisis

| Parámetro | Valor por defecto | Descripción |
|---|---|---|
| `Min Pitch (Hz)` | 75 | Frecuencia mínima para el análisis de F0 |
| `Max Pitch (Hz)` | 500 | Frecuencia máxima para el análisis de F0 |
| `Referencia semitonos (Hz)` | 1 | Frecuencia de referencia para el cálculo de semitonos (ST = 12 · log₂(f0 / ref)) |
| `Porcentaje inicio/final` | 20 | Porcentaje de la duración del intervalo que se usa como segmento inicial y segmento final |
| `Voice threshold` | 0.15 | Umbral de periodicidad para considerar sonido vocalizado en el análisis de F0 |
| `Silence threshold` | 0.01 | Umbral de silencio para el análisis de F0 |
| `Calcular reajuste` | Sí | Si está activo, añade columnas de reajuste (diferencia entre el inicio del intervalo actual y el final del anterior) |

---

## Variables computadas

Cada fila del CSV corresponde a un intervalo etiquetado. Las columnas son:

### Identificación

| Columna | Descripción |
|---|---|
| `file` | Nombre del archivo (sin extensión) |
| `tier_num` | Número del tier dentro del TextGrid |
| `tier_name` | Nombre del tier |
| `label` | Etiqueta del intervalo |
| `time_start` | Tiempo de inicio del intervalo (s) |
| `time_end` | Tiempo de fin del intervalo (s) |
| `duration_ms` | Duración del intervalo (ms) |

### F0 global del intervalo

| Columna | Descripción |
|---|---|
| `f0_min_hz` | F0 mínima del intervalo (Hz) |
| `f0_max_hz` | F0 máxima del intervalo (Hz) |
| `f0_mean_hz` | F0 media del intervalo (Hz) |
| `f0_mean_st` | F0 media del intervalo (semitonos respecto a la referencia) |

### F0 en segmentos inicial y final

El segmento inicial abarca desde el inicio del intervalo hasta el `porcentaje_inicio_final`% de su duración. El segmento final abarca el último `porcentaje_inicio_final`% de la duración.

| Columna | Descripción |
|---|---|
| `f0_inicio_hz` | F0 media del segmento inicial (Hz) |
| `f0_inicio_st` | F0 media del segmento inicial (ST) |
| `f0_final_hz` | F0 media del segmento final (Hz) |
| `f0_final_st` | F0 media del segmento final (ST) |

### Inflexión de F0

Diferencia entre el segmento final y el segmento inicial del mismo intervalo.

| Columna | Fórmula | Descripción |
|---|---|---|
| `inflexion_f0_hz` | f0_final_hz − f0_inicio_hz | Inflexión en Hz |
| `inflexion_f0_st` | 12 · log₂(f0_final / f0_inicio) | Inflexión en semitonos |
| `inflexion_f0_pct` | (inflexion_hz / f0_inicio_hz) · 100 | Inflexión en porcentaje |

### Rango de F0

| Columna | Fórmula | Descripción |
|---|---|---|
| `rango_f0_hz` | f0_max − f0_min | Rango en Hz |
| `rango_f0_st` | 12 · log₂(f0_max / f0_min) | Rango en semitonos |
| `rango_f0_pct` | (rango_hz / f0_min) · 100 | Rango en porcentaje |

### Intensidad global del intervalo

| Columna | Descripción |
|---|---|
| `int_min_db` | Intensidad mínima del intervalo (dB) |
| `int_max_db` | Intensidad máxima del intervalo (dB) |
| `int_mean_db` | Intensidad media del intervalo (dB, promediada por energía) |

### Intensidad en segmentos inicial y final

| Columna | Descripción |
|---|---|
| `int_inicio_db` | Intensidad media del segmento inicial (dB) |
| `int_final_db` | Intensidad media del segmento final (dB) |

### Inflexión de intensidad

| Columna | Fórmula | Descripción |
|---|---|---|
| `inflexion_int_db` | int_final − int_inicio | Inflexión en dB |
| `inflexion_int_pct` | (inflexion_db / int_inicio) · 100 | Inflexión en porcentaje |

### Rango de intensidad

| Columna | Fórmula | Descripción |
|---|---|---|
| `rango_int_db` | int_max − int_min | Rango en dB |
| `rango_int_pct` | (rango_db / int_min) · 100 | Rango en porcentaje |

### Reajuste (columnas opcionales)

El reajuste mide la diferencia entre el **inicio del intervalo actual** y el **final del intervalo inmediatamente anterior** dentro del mismo tier. Solo se calcula cuando el parámetro `Calcular reajuste` está activado.

| Columna | Fórmula | Descripción |
|---|---|---|
| `reajuste_f0_hz` | f0_inicio_actual − f0_final_anterior | Reajuste de F0 en Hz |
| `reajuste_f0_st` | 12 · log₂(f0_inicio_actual / f0_final_anterior) | Reajuste de F0 en semitonos |
| `reajuste_f0_pct` | (reajuste_hz / f0_final_anterior) · 100 | Reajuste de F0 en porcentaje |
| `reajuste_int_db` | int_inicio_actual − int_final_anterior | Reajuste de intensidad en dB |
| `reajuste_int_pct` | (reajuste_db / int_final_anterior) · 100 | Reajuste de intensidad en porcentaje |

> El reajuste se inicializa a `0` para el primer intervalo etiquetado de cada tier y para cualquier intervalo que siga a un intervalo vacío (sin etiqueta). El cálculo es independiente para cada tier.

---

## Valores `0` en el CSV

El script codifica la ausencia de datos con `0` en lugar de dejarlo vacío o como `undefined`. Esto ocurre cuando:

- No hay segmentos sonorizados (F0 = 0) en el intervalo o en el segmento inicial/final
- No hay intervalo previo etiquetado (reajuste = 0)

Conviene tenerlo en cuenta al filtrar los datos en R, Python u otra herramienta estadística.

---

## Licencia

Este script se distribuye con fines académicos y de investigación. Si lo usas en una publicación, cita al autor.
