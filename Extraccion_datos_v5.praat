# ============================================================================
# SCRIPT DE ANÁLISIS PROSÓDICO AUTOMÁTICO - VERSIÓN 5
# ============================================================================
#
# Autor: Adrián Cabedo Nebot
# Afiliación: Universitat de València
# Fecha: 2024
#
# DESCRIPCIÓN:
# Extrae medidas prosódicas de cualquier intervalo no vacío de todos los
# tiers de intervalo de los TextGrids seleccionados.
#
# Medidas extraídas por intervalo:
#   - F0 media (Hz y ST) del intervalo completo, segmento inicial y final
#   - Inflexión F0: Hz, ST y % (final del intervalo - inicio del intervalo)
#   - Rango F0: Hz, ST y %
#   - Intensidad media (dB) del intervalo completo, segmento inicial y final
#   - Inflexión intensidad: dB y % (final - inicio)
#   - Rango intensidad: dB y %
#   - Reajuste F0: Hz, ST y % (inicio actual - final del intervalo anterior)
#   - Reajuste intensidad: dB y % (inicio actual - final del intervalo anterior)
#
# NOTA SOBRE EL REAJUSTE:
#   El reajuste se calcula dentro de cada tier de forma independiente.
#   Para el primer intervalo de cada tier (o tras un intervalo vacío), las
#   columnas de reajuste se escriben como 0 (sin valor de referencia previo).
#
# ============================================================================

beginPause: "SCRIPT DE ANÁLISIS PROSÓDICO AUTOMÁTICO"
    comment: "Autor: Adrián Cabedo Nebot"
    comment: "Universitat de València"
    comment: ""
    comment: "Extrae medidas prosódicas de cualquier intervalo no vacío"
    comment: "de todos los tiers de intervalo de los TextGrids."
    comment: ""
    comment: "Presiona OK para configurar los parámetros del análisis."
endPause: "Continuar", 1

form Parámetros de Análisis
    comment Rangos para el análisis de F0:
    positive Min_Pitch_(Hz) 75
    positive Max_Pitch_(Hz) 500
    comment Referencia para el cálculo de semitonos (Hz):
    positive Referencia_semitonos_(Hz) 1
    comment Porcentaje para segmentos inicial y final (%):
    positive Porcentaje_inicio_final 20
    comment Umbrales para el análisis de F0:
    positive Voice_threshold 0.15
    positive Silence_threshold 0.01
    comment ¿Calcular reajuste entre intervalos consecutivos?
    boolean Calcular_reajuste 1
endform

# ===== SELECCIÓN DE CARPETAS =====

pauseScript: "PASO 1/3: Selecciona la carpeta con los ARCHIVOS DE AUDIO (.wav)"
dirAudio$ = chooseDirectory$: "Carpeta de AUDIOS (.wav)"
if dirAudio$ = ""
    exitScript: "ERROR: No se seleccionó carpeta de audios"
endif

pauseScript: "PASO 2/3: Selecciona la carpeta con los TEXTGRIDS (.TextGrid)"
dirTG$ = chooseDirectory$: "Carpeta de TEXTGRIDS (.TextGrid)"
if dirTG$ = ""
    exitScript: "ERROR: No se seleccionó carpeta de TextGrids"
endif

pauseScript: "PASO 3/3: Selecciona la carpeta donde se GUARDARÁ EL ARCHIVO CSV"
dirOutput$ = chooseDirectory$: "Carpeta de SALIDA (CSV)"
if dirOutput$ = ""
    exitScript: "ERROR: No se seleccionó carpeta de salida"
endif

clearinfo
appendInfoLine: "========================================="
appendInfoLine: "CONFIGURACIÓN CONFIRMADA"
appendInfoLine: "========================================="
appendInfoLine: "Carpeta audios:    ", dirAudio$
appendInfoLine: "Carpeta TextGrids: ", dirTG$
appendInfoLine: "Carpeta salida:    ", dirOutput$
appendInfoLine: "Porcentaje inicio/final: ", porcentaje_inicio_final, "%"
appendInfoLine: "Calcular reajuste: ", calcular_reajuste
appendInfoLine: "========================================="
appendInfoLine: ""
pauseScript: "Confirma que las rutas son correctas. Presiona OK para continuar."

# ===== CABECERA CSV =====

outFile$ = dirOutput$ + "/resultados_prosodicos.csv"

header$ = "file,tier_num,tier_name,label,time_start,time_end,duration_ms,"

# F0 global
header$ = header$ + "f0_min_hz,f0_max_hz,f0_mean_hz,f0_mean_st,"
# F0 segmentos
header$ = header$ + "f0_inicio_hz,f0_inicio_st,f0_final_hz,f0_final_st,"
# Inflexión F0
header$ = header$ + "inflexion_f0_hz,inflexion_f0_st,inflexion_f0_pct,"
# Rango F0
header$ = header$ + "rango_f0_hz,rango_f0_st,rango_f0_pct,"

# Intensidad global
header$ = header$ + "int_min_db,int_max_db,int_mean_db,"
# Intensidad segmentos
header$ = header$ + "int_inicio_db,int_final_db,"
# Inflexión intensidad
header$ = header$ + "inflexion_int_db,inflexion_int_pct,"
# Rango intensidad
header$ = header$ + "rango_int_db,rango_int_pct"

# Columnas de reajuste (opcionales)
if calcular_reajuste
    header$ = header$ + ",reajuste_f0_hz,reajuste_f0_st,reajuste_f0_pct"
    header$ = header$ + ",reajuste_int_db,reajuste_int_pct"
endif

writeFileLine: outFile$, header$

# ===== PROCESAMIENTO DE ARCHIVOS =====

listadoAudio = Create Strings as file list: "list", dirAudio$ + "/*.wav"
nArchivos = Get number of strings

appendInfoLine: "Iniciando procesamiento de ", nArchivos, " archivos..."
appendInfoLine: ""

for i from 1 to nArchivos
    selectObject: listadoAudio
    fileAudio$ = Get string: i
    fileName$ = fileAudio$ - ".wav"

    appendInfoLine: "[", i, "/", nArchivos, "] Procesando: ", fileName$

    sound = Read from file: dirAudio$ + "/" + fileAudio$
    tgFile$ = dirTG$ + "/" + fileName$ + ".TextGrid"

    if fileReadable(tgFile$)
        tg = Read from file: tgFile$
        nTiers = Get number of tiers

        selectObject: sound
        pitch = To Pitch (ac): 0, min_Pitch, 15, "yes", silence_threshold, voice_threshold, 0.01, 0.35, 0.14, max_Pitch
        selectObject: sound
        intensity = To Intensity: 100, 0, "yes"

        for t from 1 to nTiers
            selectObject: tg
            tierName$ = Get tier name: t
            safe_tier$ = replace$(tierName$, ",", " ", 0)

            isInterval = Is interval tier: t
            if isInterval
                nIntervals = Get number of intervals: t

                # Inicializar memoria del intervalo anterior para este tier
                prev_f0_final_hz  = 0
                prev_int_final_db = 0
                hay_previo = 0

                for j from 1 to nIntervals
                    selectObject: tg
                    label$ = Get label of interval: t, j

                    if label$ <> ""
                        tmin = Get start time of interval: t, j
                        tmax = Get end time of interval: t, j
                        dur_ms = tmax - tmin

                        @calcularMedidas

                        # --- Reajuste respecto al intervalo anterior ---
                        if calcular_reajuste
                            if hay_previo = 1 and prev_f0_final_hz > 0 and f0_inicio_hz > 0
                                reajuste_f0_hz  = f0_inicio_hz - prev_f0_final_hz
                                reajuste_f0_st  = 12 * (ln(f0_inicio_hz / prev_f0_final_hz) / ln(2))
                                reajuste_f0_pct = (reajuste_f0_hz / prev_f0_final_hz) * 100
                            else
                                reajuste_f0_hz  = 0
                                reajuste_f0_st  = 0
                                reajuste_f0_pct = 0
                            endif

                            if hay_previo = 1 and prev_int_final_db > 0 and int_inicio > 0
                                reajuste_int_db  = int_inicio - prev_int_final_db
                                reajuste_int_pct = (reajuste_int_db / prev_int_final_db) * 100
                            else
                                reajuste_int_db  = 0
                                reajuste_int_pct = 0
                            endif
                        endif

                        # Guardar valores finales para el siguiente intervalo
                        prev_f0_final_hz  = f0_final_hz
                        prev_int_final_db = int_final
                        hay_previo = 1

                        safe_label$ = replace$(label$, ",", " ", 0)
                        @escribirCSV
                    endif
                endfor
            endif
        endfor

        selectObject: sound, tg, pitch, intensity
        Remove
    else
        appendInfoLine: "  ⚠ ADVERTENCIA: No se encontró TextGrid para ", fileName$
    endif
endfor

selectObject: listadoAudio
Remove

appendInfoLine: ""
appendInfoLine: "========================================="
appendInfoLine: "✓ PROCESO COMPLETADO"
appendInfoLine: "========================================="
appendInfoLine: "Archivo de salida: ", outFile$
appendInfoLine: "Archivos procesados: ", nArchivos
appendInfoLine: "========================================="

# ============================================================================
# PROCEDIMIENTOS
# ============================================================================

procedure calcularMedidas

    # --- Límites de los segmentos inicial y final (en ms, igual que tmin/tmax) ---
    dur_seg      = dur_ms * (porcentaje_inicio_final / 100)
    t_inicio_fin = tmin + dur_seg
    t_final_ini  = tmax - dur_seg

    # --- F0 global ---
    selectObject: pitch
    f0_min     = Get minimum: tmin, tmax, "Hertz", "Parabolic"
    f0_max     = Get maximum: tmin, tmax, "Hertz", "Parabolic"
    f0_mean_hz = Get mean:    tmin, tmax, "Hertz"

    if f0_min <> undefined and f0_max <> undefined and f0_min > 0 and f0_max > 0
        rango_f0_hz  = f0_max - f0_min
        rango_f0_st  = 12 * (ln(f0_max / f0_min) / ln(2))
        rango_f0_pct = (rango_f0_hz / f0_min) * 100
    else
        f0_min       = 0
        f0_max       = 0
        rango_f0_hz  = 0
        rango_f0_st  = 0
        rango_f0_pct = 0
    endif

    if f0_mean_hz <> undefined and f0_mean_hz > 0
        f0_mean_st = 12 * (ln(f0_mean_hz / referencia_semitonos) / ln(2))
    else
        f0_mean_hz = 0
        f0_mean_st = 0
    endif

    # --- F0 segmento inicial ---
    f0_inicio_hz = Get mean: tmin, t_inicio_fin, "Hertz"
    if f0_inicio_hz <> undefined and f0_inicio_hz > 0
        f0_inicio_st = 12 * (ln(f0_inicio_hz / referencia_semitonos) / ln(2))
    else
        f0_inicio_hz = 0
        f0_inicio_st = 0
    endif

    # --- F0 segmento final ---
    f0_final_hz = Get mean: t_final_ini, tmax, "Hertz"
    if f0_final_hz <> undefined and f0_final_hz > 0
        f0_final_st = 12 * (ln(f0_final_hz / referencia_semitonos) / ln(2))
    else
        f0_final_hz = 0
        f0_final_st = 0
    endif

    # --- Inflexión F0 ---
    if f0_inicio_hz > 0 and f0_final_hz > 0
        inflexion_f0_hz  = f0_final_hz - f0_inicio_hz
        inflexion_f0_st  = 12 * (ln(f0_final_hz / f0_inicio_hz) / ln(2))
        inflexion_f0_pct = (inflexion_f0_hz / f0_inicio_hz) * 100
    else
        inflexion_f0_hz  = 0
        inflexion_f0_st  = 0
        inflexion_f0_pct = 0
    endif

    # --- Intensidad global ---
    selectObject: intensity
    int_min  = Get minimum: tmin, tmax, "Parabolic"
    int_max  = Get maximum: tmin, tmax, "Parabolic"
    int_mean = Get mean:    tmin, tmax, "energy"

    if int_min <> undefined and int_max <> undefined
        rango_int_db  = int_max - int_min
        if int_min > 0
            rango_int_pct = (rango_int_db / int_min) * 100
        else
            rango_int_pct = 0
        endif
    else
        int_min       = 0
        int_max       = 0
        int_mean      = 0
        rango_int_db  = 0
        rango_int_pct = 0
    endif

    if int_mean = undefined
        int_mean = 0
    endif

    # --- Intensidad segmento inicial ---
    int_inicio = Get mean: tmin, t_inicio_fin, "energy"
    if int_inicio = undefined
        int_inicio = 0
    endif

    # --- Intensidad segmento final ---
    int_final = Get mean: t_final_ini, tmax, "energy"
    if int_final = undefined
        int_final = 0
    endif

    # --- Inflexión intensidad ---
    if int_inicio > 0 and int_final > 0
        inflexion_int_db  = int_final - int_inicio
        inflexion_int_pct = (inflexion_int_db / int_inicio) * 100
    else
        inflexion_int_db  = 0
        inflexion_int_pct = 0
    endif

endproc

procedure escribirCSV
    data_line$ = fileName$ + ","
    data_line$ = data_line$ + string$(t) + ","
    data_line$ = data_line$ + safe_tier$ + ","
    data_line$ = data_line$ + safe_label$ + ","
    data_line$ = data_line$ + fixed$(tmin, 3) + ","
    data_line$ = data_line$ + fixed$(tmax, 3) + ","
    data_line$ = data_line$ + fixed$(dur_ms, 0) + ","

    # F0 global
    data_line$ = data_line$ + fixed$(f0_min, 1) + ","
    data_line$ = data_line$ + fixed$(f0_max, 1) + ","
    data_line$ = data_line$ + fixed$(f0_mean_hz, 1) + ","
    data_line$ = data_line$ + fixed$(f0_mean_st, 2) + ","
    # F0 segmentos
    data_line$ = data_line$ + fixed$(f0_inicio_hz, 1) + ","
    data_line$ = data_line$ + fixed$(f0_inicio_st, 2) + ","
    data_line$ = data_line$ + fixed$(f0_final_hz, 1) + ","
    data_line$ = data_line$ + fixed$(f0_final_st, 2) + ","
    # Inflexión F0
    data_line$ = data_line$ + fixed$(inflexion_f0_hz, 1) + ","
    data_line$ = data_line$ + fixed$(inflexion_f0_st, 2) + ","
    data_line$ = data_line$ + fixed$(inflexion_f0_pct, 2) + ","
    # Rango F0
    data_line$ = data_line$ + fixed$(rango_f0_hz, 1) + ","
    data_line$ = data_line$ + fixed$(rango_f0_st, 2) + ","
    data_line$ = data_line$ + fixed$(rango_f0_pct, 2) + ","

    # Intensidad global
    data_line$ = data_line$ + fixed$(int_min, 1) + ","
    data_line$ = data_line$ + fixed$(int_max, 1) + ","
    data_line$ = data_line$ + fixed$(int_mean, 1) + ","
    # Intensidad segmentos
    data_line$ = data_line$ + fixed$(int_inicio, 1) + ","
    data_line$ = data_line$ + fixed$(int_final, 1) + ","
    # Inflexión intensidad
    data_line$ = data_line$ + fixed$(inflexion_int_db, 2) + ","
    data_line$ = data_line$ + fixed$(inflexion_int_pct, 2) + ","
    # Rango intensidad
    data_line$ = data_line$ + fixed$(rango_int_db, 2) + ","
    data_line$ = data_line$ + fixed$(rango_int_pct, 2)

    # Reajuste (columnas opcionales al final)
    if calcular_reajuste
        data_line$ = data_line$ + "," + fixed$(reajuste_f0_hz, 1)
        data_line$ = data_line$ + "," + fixed$(reajuste_f0_st, 2)
        data_line$ = data_line$ + "," + fixed$(reajuste_f0_pct, 2)
        data_line$ = data_line$ + "," + fixed$(reajuste_int_db, 2)
        data_line$ = data_line$ + "," + fixed$(reajuste_int_pct, 2)
    endif

    appendFileLine: outFile$, data_line$
endproc
