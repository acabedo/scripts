# app.R

library(shiny)
library(DT)
library(tuneR)
library(shinyjs)
library(shinythemes)  # <--- añadido

library(seewave)
library(wrassp)
library(tools)   # file_ext
library(av)      # Para convertir mp4 a wav

# Opcional para TextGrid
# install.packages("rPraat")
library(rPraat)

n_anot <- 33

anot_defs <- list(

  # ========= TAB 1: ESTRUCTURA =========

  anot1 = list(
    label   = "Tipo de enunciado (estructura):",
    choices = c(
      "",
      "Enunciado completo",
      "Fragmento",
      "Enunciado suspendido",
      "Respuesta mínima (sí, ya, claro...)",
      "Continuador (ajá, mhm, sí sí...)"
    )
  ),

  anot2 = list(
    label   = "Modalidad oracional:",
    choices = c(
      "",
      "Afirmativa",
      "Negativa",
      "Interrogativa total (sí/no)",
      "Interrogativa parcial (qu-)",
      "Imperativa / directiva",
      "Exclamativa",
      "Dubitativa / mitigada",
      "Optativa / desiderativa"
    )
  ),

  anot3 = list(
    label   = "Estatus informativo:",
    choices = c(
      "",
      "Información nueva",
      "Información dada",
      "Recordatorio / reactivación",
      "Reformulación de lo anterior",
      "Comentario metadiscursivo (sobre cómo se dice)"
    )
  ),

  anot4 = list(
    label   = "Complejidad sintáctica:",
    choices = c(
      "",
      "Simple",
      "Yuxtaposición de enunciados",
      "Coordinación",
      "Subordinación ligera",
      "Subordinación elaborada / estilo cercano a escrito"
    )
  ),

  anot5 = list(
    label   = "Reformulación / expansión:",
    choices = c(
      "",
      "Sin reformulación",
      "Autocorrección puntual",
      "Paráfrasis (decir lo mismo de otra forma)",
      "Expansión aclarativa / explicativa",
      "Resumir / recapitular lo anterior"
    )
  ),

  anot6 = list(
    label   = "Función discursiva global:",
    choices = c(
      "",
      "Narrativa (contar hechos)",
      "Descriptiva",
      "Explicativa / expositiva",
      "Argumentativa (defender un punto de vista)",
      "Instruccional / directiva"
    )
  ),

  anot7 = list(
    label   = "Referencia a discurso ajeno:",
    choices = c(
      "",
      "No hay cita",
      "Cita directa (dijo: \"...\")",
      "Cita indirecta (dijo que...)",
      "Estilo libre / eco del otro"
    )
  ),

  anot8 = list(
    label   = "Temporalidad del contenido:",
    choices = c(
      "",
      "Presente / general",
      "Pasado (relato)",
      "Futuro / proyección",
      "Hipotético / condicional"
    )
  ),

  # ========= TAB 2: PRAGMÁTICA (ATENUACIÓN / INTENSIFICACIÓN) =========

  anot9 = list(
    label   = "Función pragmática básica:",
    choices = c(
      "",
      "Asertiva / informativa",
      "Directiva (petición, orden, consejo)",
      "Expresiva (emoción, reacción)",
      "Fática (mantener contacto)",
      "Metapragmática (hablar del hablar)"
    )
  ),

  anot10 = list(
    label   = "Función interpersonal:",
    choices = c(
      "",
      "Neutra",
      "Gestión de acuerdo / desacuerdo",
      "Gestión de cercanía / complicidad",
      "Gestión de conflicto / tensión"
    )
  ),

  # --- ATENUACIÓN (inspirada en ficha Val.Es.Co.) ---

  anot11 = list(
    label   = "Atenuación: presencia y tipo global:",
    choices = c(
      "",
      "Sin atenuación",
      "Atenuación débil",
      "Atenuación media",
      "Atenuación fuerte"
    )
  ),

  anot12 = list(
    label   = "Atenuación: orientación principal:",
    choices = c(
      "",
      "Orientada al yo (autoprotección)",
      "Orientada al tú (no dañar al otro)",
      "Orientada al decir (presentación del enunciado)",
      "Orientada a la relación (cuidar el vínculo)"
    )
  ),

  anot13 = list(
    label   = "Atenuación: procedimiento dominante:",
    choices = c(
      "",
      "Léxico (un poco, algo, más bien...)",
      "Modalizadores (creo, me parece, supongo...)",
      "Reformulación / rodeos",
      "Marcadores atenuantes (bueno, hombre, oye...)",
      "Cita / referencia a terceros (según dicen...)",
      "Otros procedimientos"
    )
  ),

  # --- INTENSIFICACIÓN ---

  anot14 = list(
    label   = "Intensificación:",
    choices = c(
      "",
      "Sin intensificación",
      "Cuantitativa (mucho, un montón...)",
      "Cualitativa (súper, re-, -ísimo...)",
      "Acto de habla (te lo juro, de verdad...)",
      "Evaluativa (es brutal, es horrible...)",
      "Múltiple (varias combinadas)"
    )
  ),

  # --- CORTESÍA / IMAGEN / ALINEAMIENTO ---

  anot15 = list(
    label   = "Estrategia de cortesía:",
    choices = c(
      "",
      "No relevante / neutra",
      "Cortesía positiva (acercamiento, elogio)",
      "Cortesía negativa (no imponer, minimizar daño)",
      "Ataque a la imagen del otro",
      "Autoimagen mitigada (autocrítica, modestia)"
    )
  ),

  anot16 = list(
    label   = "Imagen del otro:",
    choices = c(
      "",
      "Neutra",
      "Apoyo / refuerzo del otro",
      "Crítica indirecta",
      "Crítica directa",
      "Broma / ironía sobre el otro"
    )
  ),

  anot17 = list(
    label   = "Autoimagen:",
    choices = c(
      "",
      "Neutra",
      "Autoelogio / autopromoción",
      "Autocrítica seria",
      "Autocrítica irónica / lúdica",
      "Justificación / excusa"
    )
  ),

  # ========= TAB 3: DISCURSO E INTERACCIÓN =========

  anot18 = list(
    label   = "Movimiento conversacional:",
    choices = c(
      "",
      "Inicio de tema / secuencia",
      "Continuación / desarrollo",
      "Respuesta directa al otro",
      "Reacción evaluativa",
      "Cambio de tema",
      "Cierre de secuencia"
    )
  ),

  anot19 = list(
    label   = "Gestión del turno:",
    choices = c(
      "",
      "Toma de turno limpia",
      "Autoseguimiento (seguir con el turno)",
      "Cesión de turno",
      "Interrupción",
      "Solapamiento cooperativo",
      "Solapamiento competitivo"
    )
  ),

  anot20 = list(
    label   = "Relación con el turno previo:",
    choices = c(
      "",
      "Continuación lineal",
      "Contraste / oposición",
      "Aclaración / precisión",
      "Respuesta a pregunta",
      "Desplazamiento temático"
    )
  ),

  anot21 = list(
    label   = "Dinámica interactiva (solapamiento/ritmo):",
    choices = c(
      "",
      "Interacción pausada (pocos solapamientos)",
      "Interacción ágil (turnos breves)",
      "Alta densidad de solapamientos cooperativos",
      "Solapamientos conflictivos / competitivos"
    )
  ),

  anot22 = list(
    label   = "Marcador discursivo principal:",
    choices = c(
      "",
      "Apertura (bueno, oye, mira...)",
      "Conectivo aditivo (y, además, encima...)",
      "Conectivo contrastivo (pero, sin embargo...)",
      "Consecuencia (entonces, así que, por eso...)",
      "Reformulación (o sea, quiero decir...)",
      "Cierre (en fin, nada...)"
    )
  ),

  anot23 = list(
    label   = "Función fática / de contacto:",
    choices = c(
      "",
      "No fática",
      "Asegurar contacto (¿sabes?, ¿no?, ¿eh?)",
      "Apelación directa al otro",
      "Confirmación / feedback mínimo",
      "Preguntas fáticas (¿vale?, ¿sí?)"
    )
  ),

  anot24 = list(
    label   = "Deixis dominante:",
    choices = c(
      "",
      "Personal (yo, tú, nosotros...)",
      "Espacial (aquí, ahí, allí...)",
      "Temporal (ahora, luego, antes...)",
      "Textual / anafórica (eso, lo dicho, aquello...)",
      "Exofórica (esto/eso de aquí y ahora)"
    )
  ),

  anot25 = list(
    label   = "Recursos coloquiales y muletillas:",
    choices = c(
      "",
      "Ninguno destacado",
      "Interjecciones (¡ay!, ¡jo!, ¡uf!...)",
      "Muletillas (en plan, ¿sabes?, ¿vale?, tío/tía...)",
      "Frases hechas / proverbios",
      "Argot / jerga específica"
    )
  ),

  # =============== TAB 4 — PARALINGÜÍSTICO Y SEÑALES NO VERBALES =================

# 26. Paralenguaje: sonidos no verbales
anot26 = list(
  label   = "Paralenguaje (sonidos no verbales):",
  choices = c(
    "",
    "Ninguno",
    "Risa",
    "Risa leve / nasal",
    "Risa solapada con habla",
    "Tos",
    "Carraspeo",
    "Suspiro",
    "Resoplido",
    "Chasquido / clic de lengua",
    "Sollozo / llanto",
    "Otros sonidos no verbales"
  )
),

# 27. Emociones según Ekman
anot27 = list(
  label   = "Tono emocional (Ekman):",
  choices = c(
    "",
    "Neutra / sin emoción marcada",
    "Alegría",
    "Tristeza",
    "Miedo",
    "Ira / enfado",
    "Asco",
    "Sorpresa",
    "Desprecio"
  )
),

# 28. Solapamientos no verbales
anot28 = list(
  label   = "Solapamientos no verbales:",
  choices = c(
    "",
    "No hay",
    "Risa solapada",
    "Suspiro solapado",
    "Sonidos incidentales del hablante",
    "Solapamiento cooperativo",
    "Solapamiento conflictivo"
  )
),

# 29. Ruido articulatorio / gestual audible
anot29 = list(
  label   = "Ruido articulatorio / gestual audible:",
  choices = c(
    "",
    "Ninguno",
    "Pensativo (mmm...)",
    "Desaprobación (tsk, clic)",
    "Llamada / atención (chss, besito)",
    "Esfuerzo / molestia",
    "Otros"
  )
),

# 30. Fenómenos respiratorios
anot30 = list(
  label   = "Fenómenos respiratorios:",
  choices = c(
    "",
    "Ninguno",
    "Inspiración audible",
    "Expiración marcada",
    "Suspiro largo",
    "Hiperventilación ligera"
  )
),

# 31. Sonidos no verbales como turno
anot31 = list(
  label   = "Sonidos no verbales como toma de turno:",
  choices = c(
    "",
    "No hay",
    "Mhm / ajá (aceptación)",
    "¿Eh? (petición de aclaración)",
    "Risa como toma de turno",
    "Sonidos que inician turno (chasquido, inspiración)",
    "Otros"
  )
),

# 32. Ruido ambiental relevante
anot32 = list(
  label   = "Ruido ambiental con impacto discursivo:",
  choices = c(
    "",
    "Irrelevante",
    "Ruido que interfiere en el turno",
    "Risas de terceros",
    "Golpes / choques / movimiento",
    "Música / sonido que provoca reformulación",
    "Otros"
  )
),

# 33. Actitud vocal no verbal (respeto/agresividad)
anot33 = list(
  label   = "Actitud vocal no verbal:",
  choices = c(
    "",
    "Neutra",
    "Cercanía / intimidad",
    "Tensión / ansiedad",
    "Confrontativa (bufidos, resoplidos)",
    "Desdén (risita nasal, clic)",
    "Lúdica / irónica"
  )
)

)


# Helper para crear un selectInput según anot_defs
make_select <- function(id) {
  def <- anot_defs[[id]]
  selectInput(id, def$label, choices = def$choices, width = "100%", multiple = TRUE)
}

# Helper para construir el orden de columnas del df
make_col_order <- function() {
  c(
    "speaker", "start", "end", "label", "contexto",
    "n_palabras", "palabras_por_seg",
    "F0_mean", "F0_range_st", "F0_delta_st",
    "F0_final_delta_st", "F0_final_pattern", "Int_mean",
    paste0("anot", 1:n_anot),
    "observaciones"
  )
}

ui <- fluidPage(
  title = "Oralstats Etiquetador v1.0",
  theme = shinythemes::shinytheme("united"),
  useShinyjs(),
  tags$head(
    tags$style(HTML("
      body {
        background-color: #eef2f7;
      }
.app-footer {
        margin-top: 10px;
        padding: 8px 0 4px;
        font-size: 11px;
        color: #9ca3af;
        text-align: center;
      }

      .app-footer a {
        color: #9ca3af;
        text-decoration: underline;
      }
      .app-container {
        max-width: 1400px;
        margin: 0 auto 20px auto;
      }

      .navbar, .navbar-default {
        border-radius: 0;
      }

      h2, h3, h4, h5 {
        font-weight: 600;
        color: #1f2933;
      }

      .sidebar-card,
      .main-card,
      .annotations-card,
      .export-bar {
        background-color: #ffffff;
        border-radius: 12px;
        box-shadow: 0 6px 18px rgba(15, 23, 42, 0.08);
        padding: 16px 18px;
        margin-bottom: 16px;
      }

      .sidebar-card {
        height: calc(100vh - 100px);
        overflow-y: auto;
        position: sticky;
        top: 20px;
      }

      .export-bar {
        border-top: 2px solid #e5e7eb;
      }

      .control-label {
        font-weight: 600;
        color: #374151;
      }

      .form-control, .selectize-input {
        border-radius: 8px;
      }

      .btn {
        border-radius: 999px;
        font-weight: 500;
      }

      .btn-primary {
        border: none;
      }

      .btn-success, .btn-info, .btn-danger, .btn-secondary {
        border: none;
      }

      .tabbable > .nav-tabs {
        border-bottom: none;
        margin-bottom: 10px;
      }

      .nav-tabs > li > a {
        border-radius: 999px !important;
        margin-right: 4px;
        padding: 6px 12px;
      }

      .nav-tabs > li.active > a,
      .nav-tabs > li.active > a:focus,
      .nav-tabs > li.active > a:hover {
        background-color: #2563eb;
        color: #ffffff !important;
      }

      #table, #context_table {
        font-size: 13px;
      }

      #annotation_status {
        font-size: 12px;
        color: #10b981;
        margin-top: 6px;
      }

      #sequential_position {
        font-weight: 500;
        color: #4b5563;
        margin-bottom: 6px;
      }

      .small-helper-text {
        font-size: 11px;
        color: #6b7280;
        margin-top: 4px;
      }

      .export-title {
        letter-spacing: 0.05em;
        text-transform: uppercase;
        font-size: 11px;
        color: #6b7280;
        margin-bottom: 8px;
      }
    "))
  ),

  div(class = "app-container",

      titlePanel(
        div(
          style = "display:flex; align-items:center; justify-content:space-between;",
          span("Etiquetador de datos orales. Version 1.0"),
          span(style = 'font-size: 12px; color:#6b7280;',
               "Oralstats – explorador prosódico")
        )
      ),

      fluidRow(
        # ------------------- COLUMNA IZQUIERDA -------------------
        column(
          3,
          div(class = "sidebar-card",

              h4("Material", style = "margin-top:0; margin-bottom:10px;"),

              tabsetPanel(
                type = "pills",
                tabPanel(
                  "📁 Precargados",
                  br(),
                  selectInput(
                    "file_pair",
                    "Seleccionar par:",
                    choices = c("-- Buscar archivos locales --" = ""),
                    width = "100%"
                  ),
                  actionButton(
                    "load_pair", "Cargar par",
                    icon = icon("upload"),
                    class = "btn-primary btn-sm",
                    style = "width: 100%; margin-top: 5px;"
                  )
                ),
                tabPanel(
                  "📤 Cargar",
                  br(),
                  fileInput(
                    "audio", "Audio (wav, mp3, mp4)",
                    accept = c(".wav", ".mp3", ".mp4")
                  ),
                  fileInput(
                    "trans", "Transcripción (csv, txt, TextGrid)",
                    accept = c(".csv", ".txt", ".TextGrid", ".textgrid")
                  )
                )
              ),

              hr(),

              h5("🎯 Navegación secuencial"),
              fluidRow(
                column(
                  6,
                  actionButton(
                    "prev_row", "⬅ Anterior",
                    class = "btn-secondary btn-sm",
                    style = "width: 100%;"
                  )
                ),
                column(
                  6,
                  actionButton(
                    "next_row", "Siguiente ➡",
                    class = "btn-secondary btn-sm",
                    style = "width: 100%;"
                  )
                )
              ),
              br(),
              textOutput("sequential_position"),

              numericInput(
                "goto_row",
                "Ir a fila:",
                value = 1,
                min = 1,
                step = 1,
                width = "100%"
              ),
              actionButton(
                "goto_row_btn",
                "Ir",
                class = "btn-secondary btn-sm",
                style = "width: 100%; margin-top: 5px;"
              )
          )
        ),

        # ------------------- COLUMNA DERECHA -------------------
        column(
          9,

          # --------- CARD: TABLA + ANÁLISIS ---------
          div(class = "main-card",

              tabsetPanel(
                tabPanel(
                  "📊 Tabla",
                  br(),
                  DTOutput("table")
                ),
                tabPanel(
                  "📜 Contexto",
                  br(),
                  fluidRow(
                    column(
                      4,
                      numericInput(
                        "context_rows",
                        "Filas de contexto (±):",
                        value = 5,
                        min = 1,
                        max = 20,
                        step = 1,
                        width = "100%"
                      )
                    ),
                    column(
                      8,
                      div(
                        class = "small-helper-text",
                        br(),
                        "El contexto se muestra en orden temporal y con formato ",
                        tags$code("speaker: texto")
                      )
                    )
                  ),
                  hr(),
                  DTOutput("context_table")
                ),
                tabPanel(
                  "📈 Análisis fonético",
                  br(),
                  fluidRow(
                    column(
                      12,
                      actionButton(
                        "play_segment1", "▶ Reproducir segmento",
                        icon = icon("play"),
                        class = "btn-success btn-sm",
                        style = "margin-right: 5px;"
                      ),
                      actionButton(
                        "compute_all",
                        "⚙️ Calcular F0/Int de todos los segmentos",
                        class = "btn-danger btn-sm"
                      ),
                      div(
                        class = "small-helper-text",
                        "Esto recorre todas las filas y calcula las métricas acústicas."
                      ),
                      hr()
                    )
                  ),
                  fluidRow(column(12, uiOutput("video_player"))),
                  br(),
                  fluidRow(
                    column(6, plotOutput("oscillo_plot", height = 250)),
                    column(6, plotOutput("spectro_plot", height = 250))
                  ),
                  br(),
                  plotOutput("pitch_plot", height = 300)
                ),
                tabPanel(
                  "📊 Métricas",
                  br(),
                  h5("Análisis prosódico de la fila actual"),
                  verbatimTextOutput("metrics_display")
                )
              )
          ),

          # --------- CARD: ANOTACIONES ---------
div(class = "annotations-card",
    h5(strong("✍️ Anotaciones y Observaciones")),

    # ---- Botones + contexto, en la misma fila visual ----
    fluidRow(
      column(
        6,
        div(
          style = "display:flex; gap:6px; align-items:flex-end;",
          actionButton(
            "play_segment", "▶️ Segmento",
            class = "btn-success btn-sm",
            style = "width: 100%;"
          ),
          numericInput(
            "context_before", "Antes:",
            value = 0, min = 0, max = 5, step = 0.5,
            width = "90px"
          )
        )
      ),
      column(
        6,
        div(
          style = "display:flex; gap:6px; align-items:flex-end;",
          numericInput(
            "context_after", "Después:",
            value = 0, min = 0, max = 5, step = 0.5,
            width = "90px"
          ),
          actionButton(
            "play_with_context", "▶️ Contexto",
            class = "btn-info btn-sm",
            style = "width: 100%;"
          ),
           actionButton(
          "save_annotation", "💾 Guardar",
          class = "btn-primary btn-sm",
          style = "width: 100%;"
        )
        )
      )
    ),

    hr(),

    # --- Tabs dinámicos de anotaciones (solo selects) ---
    tabsetPanel(
      type = "pills",

      # ========= TAB 1: ESTRUCTURA =========
      tabPanel(
        "Estructura",
        fluidRow(
          column(4, make_select("anot1"), make_select("anot2")),
          column(4, make_select("anot3"), make_select("anot4")),
          column(4, make_select("anot5"), make_select("anot6"))
        ),
        fluidRow(
          column(6, make_select("anot7")),
          column(6, make_select("anot8"))
        )
      ),

      # ========= TAB 2: PRAGMÁTICA =========
      tabPanel(
        "Pragmática (atenuación / intensificación)",
        fluidRow(
          column(4, make_select("anot9"),  make_select("anot10")),
          column(4, make_select("anot11"), make_select("anot12")),
          column(4, make_select("anot13"), make_select("anot14"))
        ),
        fluidRow(
          column(6, make_select("anot15")),
          column(6, make_select("anot16"))
        ),
        fluidRow(
          column(6, make_select("anot17"))
        )
      ),

      # ========= TAB 3: DISCURSO E INTERACCIÓN =========
      tabPanel(
        "Discurso e interacción",
        fluidRow(
          column(4, make_select("anot18"), make_select("anot19")),
          column(4, make_select("anot20"), make_select("anot21")),
          column(4, make_select("anot22"), make_select("anot23"))
        ),
        fluidRow(
          column(6, make_select("anot24")),
          column(6, make_select("anot25"))
        )
      ),

      # ========= TAB 4: PARALINGÜÍSTICO =========
      tabPanel(
        "Paralingüístico / no verbal",
        fluidRow(
          column(
            4,
            make_select("anot26"),
            make_select("anot27")
          ),
          column(
            4,
            make_select("anot28"),
            make_select("anot29")
          ),
          column(
            4,
            make_select("anot30")
          )
        ),
        br(),
        fluidRow(
          column(
            6,
            make_select("anot31"),
            make_select("anot32")
          ),
          column(
            6,
            make_select("anot33")
          )
        )
      )
    ),

    br(),

    # ---- Observaciones + Guardar SIEMPRE visibles ----
    fluidRow(
      column(
        8,
        textAreaInput(
          "observaciones", "Observaciones:",
          placeholder = "Notas...",
          rows = 2, width = "100%"
        )
      ),
      column(
        4,
        br(),
       
        textOutput("annotation_status")
      )
    )
)



        )
      ),

      # ------------------- BARRA DE EXPORTACIÓN -------------------
      div(
        class = "export-bar",
        h6(class = "export-title", "📤 Exportar"),
        fluidRow(
          column(
            3,
            downloadButton("download_csv", "📊 CSV", class = "btn-sm", style = "width:100%;")
          ),
          column(
            3,
            actionButton("export_txt", "📄 TXT", class = "btn-default btn-sm", style = "width:100%;")
          ),
          column(
            6,
            fluidRow(
              column(
                8,
                textInput("gsheet_url", NULL, placeholder = "URL Google Sheets...", width = "100%")
              ),
              column(
                4,
                actionButton(
                  "export_gsheet", "☁️ GSheets",
                  class = "btn-info btn-sm",
                  style = "width:100%;"
                )
              )
            )
          )
        ),
        br(),
        verbatimTextOutput("export_status")
      ),
        # <- coma para añadir un último elemento al fluidPage

  div(
    class = "app-footer",
    HTML(
      "&copy; 2025 Adrián Cabedo Nebot · Esta aplicación se distribuye bajo licencia 
      <strong>Creative Commons Atribución 4.0 Internacional (CC BY 4.0)</strong>. 
      Se permite el uso, distribución y modificación siempre que se cite la autoría. 
      <a href='https://creativecommons.org/licenses/by/4.0/deed.es' target='_blank'>
      Ver texto completo de la licencia</a>."
    )
  )
)
  )



server <- function(input, output, session){
  
  # Crear directorio temporal para videos
  video_temp_dir <- tempdir()
  addResourcePath("tmpvideo", video_temp_dir)
  
  # Crear carpeta de backup si no existe
  backup_dir <- "backup"
  if (!dir.exists(backup_dir)) {
    dir.create(backup_dir, recursive = TRUE)
  }
  
  # Función para obtener nombre del archivo de análisis
  get_analysis_filename <- function(original_filename) {
    base_name <- tools::file_path_sans_ext(basename(original_filename))
    paste0("analisis_", base_name, ".txt")
  }
  
  # Función para hacer backup
  make_backup <- function(file_path) {
    if (file.exists(file_path)) {
      timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
      base_name <- basename(file_path)
      backup_name <- paste0(tools::file_path_sans_ext(base_name), 
                           "_backup_", timestamp, 
                           ".", tools::file_ext(base_name))
      backup_path <- file.path(backup_dir, backup_name)
      file.copy(file_path, backup_path, overwrite = TRUE)
      return(backup_path)
    }
    return(NULL)
  }
  
  # Función para guardar análisis individual
  save_analysis_file <- function(df, filename, make_backup_copy = FALSE) {
    analysis_file <- get_analysis_filename(filename)
    
    # Hacer backup solo si se solicita (primera carga)
    if (make_backup_copy && file.exists(analysis_file)) {
      backup_path <- make_backup(analysis_file)
      message("Backup creado: ", backup_path)
    }
    
    # Guardar archivo individual
    write.table(df, analysis_file, sep = "\t", row.names = FALSE, 
                quote = FALSE, na = "", fileEncoding = "UTF-8")
    
    # Actualizar analisis_todos.txt
    update_consolidated_file(df, filename)
    
    return(analysis_file)
  }
  
  # Función para actualizar analisis_todos.txt
  update_consolidated_file <- function(df, filename) {
    consolidated_file <- "analisis_todos.txt"
    
    # Agregar columna filename
    df_with_file <- df
    df_with_file$filename <- basename(filename)
    
    if (file.exists(consolidated_file)) {
      # Leer datos existentes
      existing_data <- read.table(consolidated_file, sep = "\t", header = TRUE,
                                   stringsAsFactors = FALSE, fileEncoding = "UTF-8",
                                   quote = "", na.strings = "")
      
      # Eliminar datos antiguos del mismo archivo
      existing_data <- existing_data[existing_data$filename != basename(filename), ]
      
      # Combinar con nuevos datos
      combined_data <- rbind(existing_data, df_with_file)
    } else {
      combined_data <- df_with_file
    }
    
    # Guardar consolidado
    write.table(combined_data, consolidated_file, sep = "\t", row.names = FALSE,
                quote = FALSE, na = "", fileEncoding = "UTF-8")
  }
  
  # Función para cargar análisis previo
  load_previous_analysis <- function(filename) {
    analysis_file <- get_analysis_filename(filename)
    if (file.exists(analysis_file)) {
      tryCatch({
        df <- read.table(analysis_file, sep = "\t", header = TRUE,
                        stringsAsFactors = FALSE, fileEncoding = "UTF-8",
                        quote = "", na.strings = "")
        message("Datos previos cargados desde: ", analysis_file)
        return(df)
      }, error = function(e) {
        message("Error al cargar análisis previo: ", e$message)
        return(NULL)
      })
    }
    return(NULL)
  }
  
ensure_annotation_cols <- function(df, n_anot) {
  for (i in 1:n_anot) {
    col_name <- paste0("anot", i)
    if (!col_name %in% names(df)) df[[col_name]] <- NA_character_
  }
  if (!"observaciones" %in% names(df)) df$observaciones <- NA_character_
  df
}

get_col_order <- function(df, n_anot) {
  base_cols <- c(
    "speaker", "start", "end", "label", "contexto",
    "n_palabras", "palabras_por_seg",
    "F0_mean", "F0_range_st", "F0_delta_st",
    "F0_final_delta_st", "F0_final_pattern", "Int_mean"
  )
  anot_cols <- paste0("anot", 1:n_anot)
  c(base_cols, anot_cols, "observaciones")
}

  rv <- reactiveValues(
    df = NULL,
    df_full = NULL,  # DataFrame completo original
    df_display = NULL,  # DataFrame filtrado para mostrar
    audio_path = NULL,
    audio_cached = NULL,  # Audio completo en memoria (cache)
    selected_segment = NULL,
    pitch_data = NULL,
    video_path = NULL,
    video_url = NULL,
    is_video = FALSE,
    selected_start = NULL,
    selected_end = NULL,
    acoustic_done = FALSE,
    selected_row_index = NULL,  # Índice cacheado de la fila seleccionada (independiente de table reload)
    sequential_index = 1,  # Índice para navegación secuencial
    random_indices = NULL,  # Índices de muestra aleatoria
    file_pairs = NULL,  # Pares de archivos precargados desde www/audios
    current_filename = NULL,  # Nombre del archivo de transcripción actual para guardado
    initial_backup_done = FALSE  # Control para hacer backup solo una vez al cargar
  )
  
play_sound <- function(path) {
  os <- Sys.info()[["sysname"]]
  
  # Normalizamos la ruta por si hay espacios
  path <- normalizePath(path, winslash = "\\", mustWork = FALSE)
  
  if (os == "Darwin") {
    # macOS
    system2("afplay", shQuote(path), wait = FALSE)
    
  } else if (os == "Windows") {
    # Windows: abre el archivo con el reproductor por defecto
    shell.exec(path)
    
  } else {
    # Linux u otros: intenta con 'aplay' o 'paplay'
    # Ajusta esto si sabes qué comando tienes instalado
    ok <- try(system2("aplay", shQuote(path), wait = FALSE), silent = TRUE)
    if (inherits(ok, "try-error")) {
      try(system2("paplay", shQuote(path), wait = FALSE), silent = TRUE)
    }
  }
}

rv$acoustic_done <- FALSE

  # ---- FUNCIÓN: Buscar pares de archivos audio + transcripción en www/audios ----
  scan_audio_folder <- function() {
    audios_dir <- file.path(getwd(), "www", "audios")
    
    if (!dir.exists(audios_dir)) {
      return(list())  # Retornar lista vacía si la carpeta no existe
    }
    
    # Extensiones válidas (prioridad: mp3 > wav > mp4)
    audio_exts <- c("mp3", "wav", "mp4")
    trans_exts <- c("csv", "txt", "textgrid")
    
    # Listar archivos
    files <- list.files(audios_dir, full.names = TRUE)
    
    # Separar por tipo
    audio_files <- files[tolower(file_ext(files)) %in% audio_exts]
    trans_files <- files[tolower(file_ext(files)) %in% trans_exts]
    
    # Obtener nombres base (sin extensión)
    audio_bases <- basename(audio_files)
    audio_bases <- sub("\\.[^.]*$", "", audio_bases)
    
    trans_bases <- basename(trans_files)
    trans_bases <- sub("\\.[^.]*$", "", trans_bases)
    
    # Encontrar bases comunes
    common_bases <- unique(audio_bases[audio_bases %in% trans_bases])
    
    # Crear pares con prioridad de formato
    pairs <- list()
    for (base in common_bases) {
      # Buscar archivos de audio con este base (puede haber múltiples formatos)
      matching_audio <- audio_files[audio_bases == base]
      
      # Seleccionar audio según prioridad: mp3 > wav > mp4
      selected_audio <- NULL
      for (ext in c("mp3", "wav", "mp4")) {
        candidates <- matching_audio[tolower(file_ext(matching_audio)) == ext]
        if (length(candidates) > 0) {
          selected_audio <- candidates[1]
          break
        }
      }
      
      # Buscar archivo de transcripción (tomar el primero si hay varios)
      matching_trans <- trans_files[trans_bases == base]
      selected_trans <- if (length(matching_trans) > 0) matching_trans[1] else NULL
      
      if (!is.null(selected_audio) && !is.null(selected_trans)) {
        pairs[[base]] <- list(
          audio = selected_audio,
          trans = selected_trans,
          audio_name = basename(selected_audio),
          trans_name = basename(selected_trans)
        )
      }
    }
    
    return(pairs)
  }
  
  # ---- OBSERVAR: Inicializar selector de pares al cargar la app ----
  observe({
    pairs <- scan_audio_folder()
    rv$file_pairs <- pairs
    
    if (length(pairs) > 0) {
      pair_choices <- setNames(
        names(pairs),
        sprintf("%s", names(pairs))
      )
      updateSelectInput(
        session, "file_pair",
        choices = c("-- Seleccionar --" = "", pair_choices),
        selected = ""
      )
    } else {
      updateSelectInput(
        session, "file_pair",
        choices = c("-- No se encontraron pares en www/audios --" = ""),
        selected = ""
      )
    }
  })
  
  # ---- OBSERVAR: Cargar par de archivos seleccionado ----
 
# ---- OBSERVAR: Cargar par de archivos seleccionado ----
# ---- OBSERVAR: Cargar par de archivos seleccionado ----
observeEvent(input$load_pair, {
  req(input$file_pair, rv$file_pairs, input$file_pair != "")

  pair_name <- input$file_pair
  pair <- rv$file_pairs[[pair_name]]

  if (is.null(pair)) {
    showNotification("Par no encontrado", type = "error", duration = 3)
    return()
  }

  # tiempos por defecto (para que no reviente el summary si hay error)
  t_total_start  <- Sys.time()
  t_audio_elapsed <- NA_real_
  t_trans_elapsed <- NA_real_
  t_proc_elapsed  <- NA_real_

  withProgress(message = "Cargando par de archivos...", value = 0, {

    # ---- PASO 1: Cargar audio ----
    incProgress(0.1, detail = "Leyendo archivo de audio...")
    t_audio_start <- Sys.time()

    tryCatch({
      audio_ext <- tolower(file_ext(pair$audio))

      if (audio_ext == "mp4") {
        incProgress(0.15, detail = "Convirtiendo MP4 a WAV...")
        temp_wav <- tempfile(fileext = ".wav")
        av::av_audio_convert(pair$audio, temp_wav, format = "wav")
        rv$audio_path <- temp_wav

        incProgress(0.2, detail = "Cargando audio en memoria...")
        rv$audio_cached <- readWave(rv$audio_path)

        incProgress(0.25, detail = "Preparando video...")
        video_filename <- paste0("video_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".mp4")
        video_dest <- file.path(video_temp_dir, video_filename)
        file.copy(pair$audio, video_dest, overwrite = TRUE)

        rv$video_path <- video_dest
        rv$video_url  <- paste0("tmpvideo/", video_filename)
        rv$is_video   <- TRUE

      } else if (audio_ext == "mp3") {
        incProgress(0.2, detail = "Convirtiendo MP3 a WAV...")
        temp_wav <- tempfile(fileext = ".wav")
        av::av_audio_convert(pair$audio, temp_wav, format = "wav")

        rv$audio_path   <- temp_wav
        rv$audio_cached <- readWave(rv$audio_path)
        rv$is_video     <- FALSE
        rv$video_path   <- NULL
        rv$video_url    <- NULL

      } else {
        incProgress(0.2, detail = "Cargando WAV en memoria...")
        rv$audio_path   <- pair$audio
        rv$audio_cached <- readWave(rv$audio_path)
        rv$is_video     <- FALSE
        rv$video_path   <- NULL
        rv$video_url    <- NULL
      }

      t_audio_elapsed <- as.numeric(difftime(Sys.time(), t_audio_start, units = "secs"))

    }, error = function(e) {
      showNotification(paste("Error al cargar audio:", e$message),
                       type = "error", duration = 5)
      rv$audio_path   <- NULL
      rv$audio_cached <- NULL
      rv$is_video     <- FALSE
      rv$video_path   <- NULL
      rv$video_url    <- NULL
    })


    # ---- PASO 2: Cargar transcripción ----
    incProgress(0.3, detail = "Leyendo archivo de transcripción...")
    t_trans_start <- Sys.time()

    df <- NULL
    tryCatch({
      trans_ext <- tolower(file_ext(pair$trans))

      if (trans_ext %in% c("csv", "txt")) {
        df <- read.table(
          pair$trans,
          header = TRUE,
          sep = if (trans_ext == "csv") "," else "\t",
          stringsAsFactors = FALSE
        )

      } else if (trans_ext == "textgrid") {
        incProgress(0.35, detail = "Parseando TextGrid...")

        tg <- tg.read(pair$trans)
        nTiers <- tg.getNumberOfTiers(tg)
        all_tiers_data <- list()

        for (tierInd in 1:nTiers) {
          if (!tg.isIntervalTier(tg, tierInd)) next
          n <- tg.getNumberOfIntervals(tg, tierInd)

          tierName <- tryCatch({
            nm <- tg.getTierName(tg, tierInd)
            if (is.null(nm) || nm == "") paste0("Tier_", tierInd) else as.character(nm)
          }, error = function(e) paste0("Tier_", tierInd))

          tier_df <- data.frame(
            speaker = rep(tierName, n),
            start   = sapply(1:n, function(i) tg.getIntervalStartTime(tg, tierInd, i)),
            end     = sapply(1:n, function(i) tg.getIntervalEndTime(tg, tierInd, i)),
            label   = sapply(1:n, function(i) tg.getLabel(tg, tierInd, i)),
            stringsAsFactors = FALSE
          )

          all_tiers_data[[tierInd]] <- tier_df
        }

        df <- if (length(all_tiers_data) > 0) do.call(rbind, all_tiers_data) else NULL
      }

      if (is.null(df)) {
        showNotification("Error al leer transcripción", type = "error", duration = 3)
        return()
      }

      t_trans_elapsed <- as.numeric(difftime(Sys.time(), t_trans_start, units = "secs"))

    }, error = function(e) {
      showNotification(paste("Error al cargar transcripción:", e$message),
                       type = "error", duration = 5)
      return()
    })


    # ---- PASO 3: Procesar columnas y contexto ----
    incProgress(0.5, detail = "Procesando columnas y contexto...")
    t_proc_start <- Sys.time()

    # columnas base
    if (!"speaker" %in% names(df)) df$speaker <- ""
    if (!"F0_mean" %in% names(df)) df$F0_mean <- NA_real_
    if (!"Int_mean" %in% names(df)) df$Int_mean <- NA_real_
    if (!"F0_range_st" %in% names(df)) df$F0_range_st <- NA_real_
    if (!"F0_delta_st" %in% names(df)) df$F0_delta_st <- NA_real_
    if (!"F0_final_delta_st" %in% names(df)) df$F0_final_delta_st <- NA_real_
    if (!"F0_final_pattern" %in% names(df)) df$F0_final_pattern <- NA_character_

    if (!"n_palabras" %in% names(df)) df$n_palabras <- NA_integer_
    if (!"palabras_por_seg" %in% names(df)) df$palabras_por_seg <- NA_real_

    # anotaciones 1..25
    for (i in 1:n_anot) {
      col_name <- paste0("anot", i)
      if (!col_name %in% names(df)) df[[col_name]] <- NA_character_
    }
    if (!"observaciones" %in% names(df)) df$observaciones <- NA_character_

    # filtrar etiquetas vacías
    if ("label" %in% names(df)) {
      df <- df[!is.na(df$label) & nzchar(trimws(df$label)), ]
    }

    # ordenar por start
    if ("start" %in% names(df)) {
      df <- df[order(df$start, na.last = TRUE), ]
    }

    # calcular palabras y velocidad
    for (i in seq_len(nrow(df))) {
      if (!is.na(df$label[i]) && nzchar(trimws(df$label[i]))) {
        palabras <- strsplit(trimws(df$label[i]), "\\s+")[[1]]
        df$n_palabras[i] <- length(palabras[nzchar(palabras)])

        duracion <- df$end[i] - df$start[i]
        if (!is.na(duracion) && duracion > 0) {
          df$palabras_por_seg[i] <- df$n_palabras[i] / duracion
        }
      }
    }

    # contexto ±5
    if (!"contexto" %in% names(df)) df$contexto <- NA_character_
    n_rows <- nrow(df)

    for (i in 1:n_rows) {
      idx_start <- max(1, i - 5)
      idx_end   <- min(n_rows, i + 5)
      filas_ctx <- idx_start:idx_end

      context_texts <- mapply(
        function(sp, lab) {
          sp_trim  <- trimws(ifelse(is.na(sp),  "", sp))
          lab_trim <- trimws(ifelse(is.na(lab), "", lab))
          if (!nzchar(lab_trim)) return("")
          if (nzchar(sp_trim)) paste0(sp_trim, ": ", lab_trim) else lab_trim
        },
        df$speaker[filas_ctx],
        df$label[filas_ctx]
      )

      context_texts <- context_texts[nzchar(context_texts)]
      df$contexto[i] <- paste(context_texts, collapse = " | ")

      if (i %% max(1, n_rows %/% 10) == 0) {
        incProgress(0.3 * (i / n_rows),
                    detail = sprintf("Contexto: %d/%d", i, n_rows))
      }
    }

    t_proc_elapsed <- as.numeric(difftime(Sys.time(), t_proc_start, units = "secs"))


    # ---- PASO 4: Cargar análisis previo ----
    incProgress(0.85, detail = "Buscando análisis previo...")
    rv$current_filename <- pair$trans

    previous_data <- load_previous_analysis(pair$trans)

    # restaurar 25 anotaciones + métricas
    if (!is.null(previous_data)) {
      incProgress(0.9, detail = "Restaurando anotaciones previas...")

      for (i in seq_len(nrow(df))) {

        match_idx <- which(
          abs(previous_data$start - df$start[i]) < 0.001 &
          abs(previous_data$end   - df$end[i])   < 0.001 &
          previous_data$label == df$label[i]
        )

        if (length(match_idx) > 0) {
          match_idx <- match_idx[1]

          metric_cols <- c(
            "F0_mean","Int_mean","F0_range_st","F0_delta_st",
            "F0_final_delta_st","F0_final_pattern"
          )

          for (mc in metric_cols) {
            if (mc %in% names(previous_data) && !is.na(previous_data[[mc]][match_idx])) {
              df[[mc]][i] <- previous_data[[mc]][match_idx]
            }
          }

          for (j in 1:n_anot) {
            col_name <- paste0("anot", j)
            if (col_name %in% names(previous_data) &&
                !is.na(previous_data[[col_name]][match_idx]) &&
                nzchar(previous_data[[col_name]][match_idx])) {
              df[[col_name]][i] <- previous_data[[col_name]][match_idx]
            }
          }

          if ("observaciones" %in% names(previous_data) &&
              !is.na(previous_data$observaciones[match_idx])) {
            df$observaciones[i] <- previous_data$observaciones[match_idx]
          }
        }
      }

      showNotification(
        sprintf("✓ Análisis previo restaurado: %d filas", nrow(previous_data)),
        type = "message",
        duration = 5
      )
    }


    # ---- PASO 5: Reordenar y asignar ----
    incProgress(0.95, detail = "Finalizando...")

    col_order <- c(
      "speaker","start","end","label","contexto",
      "n_palabras","palabras_por_seg",
      "F0_mean","F0_range_st","F0_delta_st",
      "F0_final_delta_st","F0_final_pattern","Int_mean",
      paste0("anot", 1:n_anot),
      "observaciones"
    )
    df <- df[, col_order[col_order %in% names(df)]]

    rv$df_full <- df
    rv$df <- df
    rv$acoustic_done <- FALSE
    rv$sequential_index <- 1
    rv$random_indices <- NULL

    # guardar inicial con backup 1 vez
    tryCatch({
      make_backup_copy <- !rv$initial_backup_done
      saved_file <- save_analysis_file(rv$df_full, rv$current_filename,
                                       make_backup_copy = make_backup_copy)
      if (make_backup_copy) rv$initial_backup_done <- TRUE
      message("✓ Archivo de análisis creado/actualizado: ", saved_file)
    }, error = function(e) {
      showNotification(paste("Error al crear archivo de análisis:", e$message),
                       type = "warning")
    })

    incProgress(1, detail = "✓ Completado")
  })

  # ---- resumen final ----
  t_total_elapsed <- as.numeric(difftime(Sys.time(), t_total_start, units = "secs"))

  summary_msg <- sprintf(
    "✓ Cargado exitosamente en %.2f s\n\n📊 Audio: %d Hz, %.1f s\n📋 Transcripción: %d filas\n\n⏱ Tiempos:\n  Audio: %.2f s\n  Transcripción: %.2f s\n  Procesamiento: %.2f s\n  TOTAL: %.2f s",
    t_total_elapsed,
    rv$audio_cached@samp.rate,
    length(rv$audio_cached@left) / rv$audio_cached@samp.rate,
    nrow(rv$df_full),
    ifelse(is.na(t_audio_elapsed), 0, t_audio_elapsed),
    ifelse(is.na(t_trans_elapsed), 0, t_trans_elapsed),
    ifelse(is.na(t_proc_elapsed), 0, t_proc_elapsed),
    t_total_elapsed
  )

  showNotification(summary_msg, type = "message", duration = 10)
})


  # Guardar ruta del audio subido
  # Guardar ruta del audio subido
  observeEvent(input$audio, {
    req(input$audio)
    audio_ext <- tolower(tools::file_ext(input$audio$name))
    
    # Crear un archivo temporal WAV siempre
    temp_wav <- tempfile(fileext = ".wav")
    
    tryCatch({
      if (audio_ext == "mp3") {
        # CASO MP3: Convertir a WAV usando tuneR o av
        # Opción A: Usando tuneR (a veces falla con mp3 complejos)
        # mp3_obj <- readMP3(input$audio$datapath)
        # writeWave(mp3_obj, temp_wav)
        
        # Opción B (Más robusta): Usando av (igual que con mp4)
        av::av_audio_convert(input$audio$datapath, temp_wav, format = "wav")
        
        rv$audio_path <- temp_wav
        rv$audio_cached <- readWave(rv$audio_path)
        rv$video_path <- NULL
        rv$is_video <- FALSE
        
      } else if (audio_ext == "mp4") {
        # CASO MP4
        av::av_audio_convert(input$audio$datapath, temp_wav, format = "wav")
        rv$audio_path <- temp_wav
        rv$audio_cached <- readWave(rv$audio_path)
        
        # Video setup
        video_filename <- paste0("video_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".mp4")
        video_dest <- file.path(video_temp_dir, video_filename)
        file.copy(input$audio$datapath, video_dest, overwrite = TRUE)
        rv$video_path <- video_dest
        rv$video_url <- paste0("tmpvideo/", video_filename)
        rv$is_video <- TRUE
        
      } else {
        # CASO WAV (Directo)
        rv$audio_path <- input$audio$datapath
        rv$audio_cached <- readWave(rv$audio_path)
        rv$video_path <- NULL
        rv$is_video <- FALSE
      }
      
      showNotification("Audio cargado y procesado correctamente.", type = "message")
      
    }, error = function(e) {
      showNotification(paste("Error cargando audio:", e$message), type = "error")
    })
  })
  
  # Leer transcripción
 
# ---- OBSERVAR: Cargar transcripción subida por el usuario ----

  # ---- Leer transcripción subida ----
observeEvent(input$trans, {
  req(input$trans)

  ext  <- tolower(file_ext(input$trans$name))
  path <- input$trans$datapath

  df <- NULL

  # ---- 1) Leer fichero ----
  if (ext %in% c("csv", "txt")) {
    df <- read.table(
      path,
      header = TRUE,
      sep = if (ext == "csv") "," else "\t",
      stringsAsFactors = FALSE
    )

  } else if (ext == "textgrid") {

    if (!requireNamespace("rPraat", quietly = TRUE)) {
      showNotification("Instala el paquete 'rPraat' para leer TextGrid.",
                       type = "error")
      return(NULL)
    }

    tg <- tg.read(path)
    nTiers <- tg.getNumberOfTiers(tg)
    all_tiers_data <- list()

    for (tierInd in 1:nTiers) {
      if (!tg.isIntervalTier(tg, tierInd)) next
      n <- tg.getNumberOfIntervals(tg, tierInd)

      tierName <- tryCatch({
        nm <- tg.getTierName(tg, tierInd)
        if (is.null(nm) || nm == "") paste0("Tier_", tierInd) else nm
      }, error = function(e) paste0("Tier_", tierInd))

      tier_df <- data.frame(
        speaker = rep(tierName, n),
        start   = sapply(1:n, function(i) tg.getIntervalStartTime(tg, tierInd, i)),
        end     = sapply(1:n, function(i) tg.getIntervalEndTime(tg, tierInd, i)),
        label   = sapply(1:n, function(i) tg.getLabel(tg, tierInd, i)),
        stringsAsFactors = FALSE
      )

      all_tiers_data[[tierInd]] <- tier_df
    }

    if (length(all_tiers_data) > 0) {
      df <- do.call(rbind, all_tiers_data)
    } else {
      showNotification("No se encontraron tiers de intervalos en el TextGrid.",
                       type = "error")
      return(NULL)
    }

  } else {
    showNotification("Formato de transcripción no reconocido.",
                     type = "error")
    return(NULL)
  }

  req(df)

  # ---- 2) Asegurar columnas base ----
  if (!"speaker" %in% names(df)) df$speaker <- ""
  if (!"F0_mean" %in% names(df)) df$F0_mean <- NA_real_
  if (!"Int_mean" %in% names(df)) df$Int_mean <- NA_real_
  if (!"F0_range_st" %in% names(df)) df$F0_range_st <- NA_real_
  if (!"F0_delta_st" %in% names(df)) df$F0_delta_st <- NA_real_
  if (!"F0_final_delta_st" %in% names(df)) df$F0_final_delta_st <- NA_real_
  if (!"F0_final_pattern" %in% names(df)) df$F0_final_pattern <- NA_character_

  if (!"n_palabras" %in% names(df)) df$n_palabras <- NA_integer_
  if (!"palabras_por_seg" %in% names(df)) df$palabras_por_seg <- NA_real_

  # anotaciones 1..25
  for (i in 1:n_anot) {
    col_name <- paste0("anot", i)
    if (!col_name %in% names(df)) df[[col_name]] <- NA_character_
  }
  if (!"observaciones" %in% names(df)) df$observaciones <- NA_character_

  # ---- 3) Filtrar vacíos + ordenar ----
  if ("label" %in% names(df)) {
    df <- df[!is.na(df$label) & nzchar(trimws(df$label)), ]
  }
  if ("start" %in% names(df)) {
    df <- df[order(df$start, na.last = TRUE), ]
  }

  # ---- 4) Palabras y velocidad ----
  for (i in seq_len(nrow(df))) {
    if (!is.na(df$label[i]) && nzchar(trimws(df$label[i]))) {
      palabras <- strsplit(trimws(df$label[i]), "\\s+")[[1]]
      df$n_palabras[i] <- length(palabras[nzchar(palabras)])

      duracion <- df$end[i] - df$start[i]
      if (!is.na(duracion) && duracion > 0) {
        df$palabras_por_seg[i] <- df$n_palabras[i] / duracion
      }
    }
  }

  # ---- 5) Contexto ±5 ----
  if (!"contexto" %in% names(df)) df$contexto <- NA_character_
  n_rows <- nrow(df)

  for (i in 1:n_rows) {
    idx_start <- max(1, i - 5)
    idx_end   <- min(n_rows, i + 5)
    filas_ctx <- idx_start:idx_end

    context_texts <- mapply(
      function(sp, lab) {
        sp_trim  <- trimws(ifelse(is.na(sp),  "", sp))
        lab_trim <- trimws(ifelse(is.na(lab), "", lab))
        if (!nzchar(lab_trim)) return("")
        if (nzchar(sp_trim)) paste0(sp_trim, ": ", lab_trim) else lab_trim
      },
      df$speaker[filas_ctx],
      df$label[filas_ctx]
    )

    context_texts <- context_texts[nzchar(context_texts)]
    df$contexto[i] <- paste(context_texts, collapse = " | ")
  }

  # ---- 6) Reordenar columnas ----
  col_order <- c(
    "speaker","start","end","label","contexto",
    "n_palabras","palabras_por_seg",
    "F0_mean","F0_range_st","F0_delta_st",
    "F0_final_delta_st","F0_final_pattern","Int_mean",
    paste0("anot", 1:n_anot),
    "observaciones"
  )
  df <- df[, col_order[col_order %in% names(df)]]

  # ---- 7) Nombre actual + restaurar análisis previo ----
  rv$current_filename <- input$trans$name
  previous_data <- load_previous_analysis(input$trans$name)

  if (!is.null(previous_data)) {

    for (i in seq_len(nrow(df))) {

      match_idx <- which(
        abs(previous_data$start - df$start[i]) < 0.001 &
        abs(previous_data$end   - df$end[i])   < 0.001 &
        previous_data$label == df$label[i]
      )

      if (length(match_idx) > 0) {
        match_idx <- match_idx[1]

        metric_cols <- c(
          "F0_mean","Int_mean","F0_range_st","F0_delta_st",
          "F0_final_delta_st","F0_final_pattern"
        )

        for (mc in metric_cols) {
          if (mc %in% names(previous_data) && !is.na(previous_data[[mc]][match_idx])) {
            df[[mc]][i] <- previous_data[[mc]][match_idx]
          }
        }

        for (j in 1:n_anot) {
          col_name <- paste0("anot", j)
          if (col_name %in% names(previous_data) &&
              !is.na(previous_data[[col_name]][match_idx]) &&
              nzchar(previous_data[[col_name]][match_idx])) {
            df[[col_name]][i] <- previous_data[[col_name]][match_idx]
          }
        }

        if ("observaciones" %in% names(previous_data) &&
            !is.na(previous_data$observaciones[match_idx])) {
          df$observaciones[i] <- previous_data$observaciones[match_idx]
        }
      }
    }

    showNotification(
      sprintf("✓ Análisis previo restaurado: %d filas", nrow(previous_data)),
      type = "message",
      duration = 5
    )
  }

  # ---- 8) Asignar a RV + guardar inicial ----
  rv$df_full <- df
  rv$df <- df
  rv$sequential_index <- 1
  rv$random_indices <- NULL
  rv$acoustic_done <- FALSE

  tryCatch({
    make_backup_copy <- !rv$initial_backup_done
    saved_file <- save_analysis_file(rv$df_full, rv$current_filename,
                                     make_backup_copy = make_backup_copy)
    if (make_backup_copy) rv$initial_backup_done <- TRUE
    message("✓ Archivo de análisis creado/actualizado: ", saved_file)
  }, error = function(e) {
    showNotification(paste("Error al crear archivo de análisis:", e$message),
                     type = "warning")
  })
})

  # Reactive para determinar qué filas mostrar según el modo
 df_to_display <- reactive({
  req(rv$df_full)
  
  idx <- rv$sequential_index
  if (is.null(idx) || idx < 1 || idx > nrow(rv$df_full)) {
    idx <- 1
  }
  
  df_row <- rv$df_full[idx, , drop = FALSE]
  
  df_display <- data.frame(
    Fila     = idx,
    speaker  = df_row$speaker,
    label    = df_row$label,
    contexto = df_row$contexto,
    stringsAsFactors = FALSE
  )
  
  df_display
})

  
  # Actualizar tabla cuando cambia el modo o los datos
  observe({
    rv$df <- df_to_display()
  })
  
  # Navegación secuencial - Siguiente
  observeEvent(input$next_row, {
    req(rv$df_full)
    if (rv$sequential_index < nrow(rv$df_full)) {
      rv$sequential_index <- rv$sequential_index + 1
    } else {
      showNotification("Ya estás en la última fila", type = "warning", duration = 2)
    }
  })
  
  # Navegación secuencial - Anterior
  observeEvent(input$prev_row, {
    req(rv$df_full)
    if (rv$sequential_index > 1) {
      rv$sequential_index <- rv$sequential_index - 1
    } else {
      showNotification("Ya estás en la primera fila", type = "warning", duration = 2)
    }
  })

  observeEvent(input$goto_row_btn, {
  req(rv$df_full)
  
  n <- nrow(rv$df_full)
  fila <- as.integer(input$goto_row)
  
  if (is.na(fila)) {
    showNotification("Introduce un número de fila válido.", type = "error", duration = 3)
    return()
  }
  
  if (fila < 1 || fila > n) {
    showNotification(
      sprintf("La fila debe estar entre 1 y %d.", n),
      type = "warning",
      duration = 3
    )
    return()
  }
  
  # Este cambio dispara todo tu flujo: selección, métricas, gráficos, etc.
  rv$sequential_index <- fila
})
  
  # Mostrar posición en modo secuencial
  output$sequential_position <- renderText({
    req(rv$df_full)
    sprintf("Fila %d de %d", rv$sequential_index, nrow(rv$df_full))
  })
  
  # Nueva muestra aleatoria
  # Mostrar tabla (editable)
  output$table <- renderDT({
    req(rv$df)
    datatable(
      rv$df,
      selection = "single",
      editable  = TRUE,
      options   = list(
        pageLength = 20,
        scrollX = TRUE
      ),
      rownames = FALSE
    )
  }, server = TRUE)  # Cambiado a TRUE para que replaceData funcione
  
  proxy <- dataTableProxy("table")
  
  # Tabla de contexto (±N filas)
  output$context_table <- renderDT({
  req(rv$df_full, rv$selected_row_index, input$context_rows)
  
  idx <- rv$selected_row_index
  n_context <- input$context_rows
  
  idx_start <- max(1, idx - n_context)
  idx_end   <- min(nrow(rv$df_full), idx + n_context)
  
  filas <- idx_start:idx_end
  
  context_df <- data.frame(
    Fila     = filas,
    speaker  = rv$df_full$speaker[filas],
    label    = rv$df_full$label[filas],
    contexto = rv$df_full$contexto[filas],
    es_actual = (filas == idx),
    stringsAsFactors = FALSE
  )
  
  datatable(
    context_df,
    options = list(
      pageLength = 2 * n_context + 1,
      scrollX = TRUE,
      searching = FALSE,
      paging = FALSE,
      columnDefs = list(
        list(targets = 4, visible = FALSE)  # ocultar columna es_actual
      )
    ),
    rownames = FALSE
  ) %>%
    formatStyle(
      'es_actual',
      target = 'row',
      backgroundColor = styleEqual(c(TRUE, FALSE), c('#ffffcc', 'white'))
    )
})


  
  # Display de métricas calculadas
 
# ---- Display de métricas calculadas (fila actual) ----

  # ---- Display de métricas calculadas (fila actual) ----
output$metrics_display <- renderPrint({
  req(rv$df_full, rv$selected_row_index)

  idx <- rv$selected_row_index
  row_data <- rv$df_full[idx, , drop = FALSE]

  cat("═══════════════════════════════════════════\n")
  cat("  ANÁLISIS PROSÓDICO - Fila", idx, "\n")
  cat("═══════════════════════════════════════════\n\n")

  cat("📝 SEGMENTO:\n")
  cat("  Hablante:", row_data$speaker, "\n")
  cat("  Inicio:", sprintf("%.3f s", row_data$start), "\n")
  cat("  Fin:", sprintf("%.3f s", row_data$end), "\n")
  cat("  Duración:", sprintf("%.3f s", row_data$end - row_data$start), "\n")
  cat("  Etiqueta:", row_data$label, "\n\n")

  cat("📊 TEXTO Y VELOCIDAD:\n")
  cat(
    "  Palabras:",
    if (!is.na(row_data$n_palabras)) sprintf("%d", row_data$n_palabras) else "No calculado",
    "\n"
  )
  cat(
    "  Velocidad:",
    if (!is.na(row_data$palabras_por_seg)) sprintf("%.2f palabras/s", row_data$palabras_por_seg) else "No calculado",
    "\n\n"
  )

  cat("🎵 FRECUENCIA FUNDAMENTAL (F0):\n")
  cat("  Media:", if (!is.na(row_data$F0_mean)) sprintf("%.1f Hz", row_data$F0_mean) else "No calculado", "\n")
  cat("  Rango:", if (!is.na(row_data$F0_range_st)) sprintf("%.2f semitonos", row_data$F0_range_st) else "No calculado", "\n")
  cat("  Inflexión:", if (!is.na(row_data$F0_delta_st)) sprintf("%.2f st", row_data$F0_delta_st) else "No calculado", "\n")
  cat("  Tonema (20%):", if (!is.na(row_data$F0_final_delta_st)) sprintf("%.2f st", row_data$F0_final_delta_st) else "No calculado", "\n")
  cat("  Patrón final:", if (!is.na(row_data$F0_final_pattern)) as.character(row_data$F0_final_pattern) else "No calculado", "\n\n")

  cat("📢 INTENSIDAD:\n")
  cat("  Media:", if (!is.na(row_data$Int_mean)) sprintf("%.1f dB", row_data$Int_mean) else "No calculado", "\n\n")

  cat("✍️ ANOTACIONES:\n")
  any_anot <- FALSE
  for (j in 1:n_anot) {
    col_name <- paste0("anot", j)
    if (col_name %in% names(row_data)) {
      val <- row_data[[col_name]]
      if (!is.na(val) && nzchar(trimws(val))) {
        cat(sprintf("  %s: %s\n", col_name, val))
        any_anot <- TRUE
      }
    }
  }
  if (!any_anot) cat("  (sin anotaciones)\n")

  if ("observaciones" %in% names(row_data)) {
    obs <- row_data$observaciones
    if (!is.na(obs) && nzchar(trimws(obs))) {
      cat("\n💬 OBSERVACIONES:\n")
      cat("  ", gsub("\n", "\n  ", obs), "\n")
    }
  }

  cat("\n═══════════════════════════════════════════\n")
})


  # Permitir edición manual
  observeEvent(input$table_cell_edit, {
    info <- input$table_cell_edit
    i <- info$row
    j <- info$col
    v <- info$value
    rv$df[i, j] <- v
  })
  
  # ---- Función que calcula F0 media e intensidad media para una fila ----
  compute_measures <- function(row_index, show_timing = FALSE) {
    df <- rv$df_full  # Usar el dataframe completo
    req(df, rv$audio_cached)  # Ahora requiere audio en cache
    
    start  <- as.numeric(df$start[row_index])
    end    <- as.numeric(df$end[row_index])
    
    if (is.na(start) || is.na(end) || end <= start) {
      showNotification("Intervalo no válido.", type = "error")
      return(NULL)
    }
    
    # -------------------------------------------------------------------
    # OPTIMIZACIÓN: Extraer solo el segmento de audio antes de procesarlo
    # MEJORA: Usar audio en cache en lugar de leer del disco
    # -------------------------------------------------------------------
    tryCatch({
      t_total <- Sys.time()
      
      # PASO 1: Extraer segmento desde audio en memoria (cache)
      t1 <- Sys.time()
      wave_full <- rv$audio_cached  # Audio ya en memoria
      
      # Extraer solo el segmento
      fs <- wave_full@samp.rate
      seg <- seewave::cutw(
        wave_full,
        from = start,
        to = end,
        output = "Wave",
        f = fs
      )
      
      # Guardar segmento temporalmente
      temp_seg_file <- tempfile(fileext = ".wav")
      tuneR::writeWave(seg, filename = temp_seg_file)
      t1_elapsed <- as.numeric(difftime(Sys.time(), t1, units = "secs"))
      
      if (show_timing) cat(sprintf("  [1] Extracción de segmento: %.2f s\n", t1_elapsed))
      
      # PASO 2: Calcular F0
      t2 <- Sys.time()
      F0 <- NA_real_
      F0_range_st <- NA_real_
      F0_delta_st <- NA_real_
      F0_final_delta_st <- NA_real_
      F0_final_pattern <- NA_character_
      
      # F0 del segmento
      f0_obj <- try(wrassp::ksvF0(temp_seg_file, toFile = FALSE), silent = TRUE)
      t2_elapsed <- as.numeric(difftime(Sys.time(), t2, units = "secs"))
      if (show_timing) cat(sprintf("  [2] Cálculo de F0 (ksvF0): %.2f s\n", t2_elapsed))
      
      # PASO 3: Procesar datos de F0
      t3 <- Sys.time()
      if (!inherits(f0_obj, "try-error")) {
        f0_vals <- f0_obj$F0
        f0_times <- seq(attr(f0_obj, "startTime"), 
                        by = attr(f0_obj, "sampleRate")^-1, 
                        length.out = length(f0_vals))
        
        # Filtrar valores válidos
        sel_f0 <- f0_vals > 0
        
        if (any(sel_f0)) {
          selected_f0 <- f0_vals[sel_f0]
          selected_times <- f0_times[sel_f0]
          F0 <- mean(selected_f0, na.rm = TRUE)
          
          # Calcular rango en semitonos: 12 * log2(f_max / f_min)
          if (length(selected_f0) > 1) {
            f0_min <- min(selected_f0, na.rm = TRUE)
            f0_max <- max(selected_f0, na.rm = TRUE)
            if (f0_min > 0 && f0_max > 0) {
              F0_range_st <- 12 * log2(f0_max / f0_min)
            }
            
            # Calcular diferencia inicial-final en semitonos
            f0_start <- selected_f0[1]
            f0_end <- selected_f0[length(selected_f0)]
            if (f0_start > 0 && f0_end > 0) {
              F0_delta_st <- 12 * log2(f0_end / f0_start)
            }
            
            # Análisis del 20% final del enunciado
            # Usar tiempos relativos al segmento
            duration_seg <- f0_times[length(f0_times)] - f0_times[1]
            final_20_start <- f0_times[length(f0_times)] - (duration_seg * 0.2)
            
            # Seleccionar solo el 20% final
            sel_final_20 <- selected_times >= final_20_start
            
            if (sum(sel_final_20) >= 4) {  # Necesitamos al menos 4 puntos
              final_f0 <- selected_f0[sel_final_20]
              n_points <- length(final_f0)
              
              # Dividir el 20% final en 4 partes iguales (con índices válidos)
              # Asegurar que cada cuarto tenga al menos 1 punto
              breaks <- round(seq(1, n_points + 1, length.out = 5))
              
              q1_idx <- breaks[1]:(breaks[2]-1)
              q2_idx <- breaks[2]:(breaks[3]-1)
              q3_idx <- breaks[3]:(breaks[4]-1)
              q4_idx <- breaks[4]:breaks[5]
              
              # Calcular promedios de cada cuarto (solo si hay datos válidos)
              f0_q1 <- if (length(q1_idx) > 0) mean(final_f0[q1_idx], na.rm = TRUE) else NA_real_
              f0_q2 <- if (length(q2_idx) > 0) mean(final_f0[q2_idx], na.rm = TRUE) else NA_real_
              f0_q3 <- if (length(q3_idx) > 0) mean(final_f0[q3_idx], na.rm = TRUE) else NA_real_
              f0_q4 <- if (length(q4_idx) > 0) mean(final_f0[q4_idx], na.rm = TRUE) else NA_real_
              
              # Verificar que todos los cuartos son válidos y positivos
              all_quarters_valid <- !is.na(f0_q1) && !is.na(f0_q4) && 
                                   is.finite(f0_q1) && is.finite(f0_q4) &&
                                   f0_q1 > 0 && f0_q4 > 0
              
              if (all_quarters_valid) {
                # Diferencia en semitonos entre último y primer cuarto
                F0_final_delta_st <- 12 * log2(f0_q4 / f0_q1)
                
                # Determinar patrón melódico (solo si todos los cuartos son válidos)
                if (!is.na(f0_q2) && !is.na(f0_q3) && 
                    is.finite(f0_q2) && is.finite(f0_q3) &&
                    f0_q2 > 0 && f0_q3 > 0) {
                  
                  threshold_st <- 0.5
                  
                  d1 <- 12 * log2(f0_q2 / f0_q1)
                  d2 <- 12 * log2(f0_q3 / f0_q2)
                  d3 <- 12 * log2(f0_q4 / f0_q3)
                  
                  # Verificar que las diferencias son finitas
                  if (is.finite(d1) && is.finite(d2) && is.finite(d3)) {
                    c1 <- if (d1 > threshold_st) "A" else if (d1 < -threshold_st) "D" else "P"
                    c2 <- if (d2 > threshold_st) "A" else if (d2 < -threshold_st) "D" else "P"
                    c3 <- if (d3 > threshold_st) "A" else if (d3 < -threshold_st) "D" else "P"
                    
                    pattern_code <- paste0(c1, c2, c3)
                    
                    F0_final_pattern <- switch(pattern_code,
                      "AAA" = "Ascendente continua",
                      "DDD" = "Descendente continua",
                      "PPP" = "Plana",
                      "ADA" = "Ascendente-Descendente-Ascendente",
                      "DAD" = "Descendente-Ascendente-Descendente",
                      "AAD" = "Ascendente-Descendente",
                      "ADD" = "Ascendente-Descendente",
                      "DAA" = "Descendente-Ascendente",
                      "DDA" = "Descendente-Ascendente",
                      "AAP" = "Ascendente",
                      "PAA" = "Ascendente",
                      "DDP" = "Descendente",
                      "PDD" = "Descendente",
                      "ADP" = "Ascendente-Descendente",
                      "DAP" = "Descendente-Ascendente",
                      "PAD" = "Ascendente-Descendente",
                      "PDA" = "Descendente-Ascendente",
                      pattern_code
                    )
                  }
                }
              }
            }
          }
        }
      }
      t3_elapsed <- as.numeric(difftime(Sys.time(), t3, units = "secs"))
      if (show_timing) cat(sprintf("  [3] Análisis de F0 (patrones): %.2f s\n", t3_elapsed))
      
      # PASO 4: Intensidad (RMS) del segmento
      t4 <- Sys.time()
      Int <- NA_real_
      rms_obj <- try(wrassp::rmsana(temp_seg_file, toFile = FALSE), silent = TRUE)
      t4_elapsed <- as.numeric(difftime(Sys.time(), t4, units = "secs"))
      if (show_timing) cat(sprintf("  [4] Cálculo de intensidad (rmsana): %.2f s\n", t4_elapsed))
      
      if (!inherits(rms_obj, "try-error")) {
        rms_vals <- rms_obj$rms
        sel_i <- rms_vals > 0
        if (any(sel_i)) {
          mean_rms <- mean(rms_vals[sel_i], na.rm = TRUE)
          Int <- 10 * log10(mean_rms^2)
        }
      }
      
      # Limpiar archivo temporal
      unlink(temp_seg_file)
      
      t_total_elapsed <- as.numeric(difftime(Sys.time(), t_total, units = "secs"))
      if (show_timing) {
        cat(sprintf("  [TOTAL] Tiempo total: %.2f s\n", t_total_elapsed))
        cat(sprintf("    Breakdown: Extracción=%.0f%%, F0=%.0f%%, Análisis=%.0f%%, Intensidad=%.0f%%\n",
                    100*t1_elapsed/t_total_elapsed,
                    100*t2_elapsed/t_total_elapsed,
                    100*t3_elapsed/t_total_elapsed,
                    100*t4_elapsed/t_total_elapsed))
      }
      
      return(list(F0 = F0, Int = Int, F0_range_st = F0_range_st, F0_delta_st = F0_delta_st,
                  F0_final_delta_st = F0_final_delta_st, F0_final_pattern = F0_final_pattern))
      
    }, error = function(e) {
      showNotification(paste("Error en compute_measures:", e$message), type = "error")
      return(NULL)
    })
  }
  
  # Cuando seleccionas una fila, calcula F0/Int y actualiza la tabla
  # Observer automático: Reacciona a cambios en sequential_index
  observe({
    req(rv$df_full, rv$audio_cached, rv$sequential_index)
    
    i_full <- rv$sequential_index
    
    # Validar índice
    if (i_full < 1 || i_full > nrow(rv$df_full)) {
      return()
    }
    
    # CACHEAR el índice
    rv$selected_row_index <- i_full
    
    # Extraer segmento de audio para visualizaciones
    start <- as.numeric(rv$df_full$start[i_full])
    end <- as.numeric(rv$df_full$end[i_full])
    
    # Guardar tiempos para el reproductor de video
    rv$selected_start <- start
    rv$selected_end <- end
    
    if (!is.na(start) && !is.na(end) && end > start) {
      tryCatch({
        # Usar audio en memoria (cache)
        wave_full <- rv$audio_cached
        
        if (!is.null(wave_full)) {
          # Extraer segmento
          fs <- wave_full@samp.rate
          seg <- seewave::cutw(
            wave_full,
            from = start,
            to = end,
            output = "Wave",
            f = fs
          )
          rv$selected_segment <- seg
          
          # Calcular pitch con wrassp::ksvF0
          temp_seg_file <- tempfile(fileext = ".wav")
          tuneR::writeWave(seg, filename = temp_seg_file)
          
          f0_obj <- try(wrassp::ksvF0(temp_seg_file, toFile = FALSE), silent = TRUE)
          unlink(temp_seg_file)
          
          if (!inherits(f0_obj, "try-error") && !is.null(f0_obj)) {
            f0_vals <- f0_obj$F0
            f0_times <- seq(
              attr(f0_obj, "startTime"), 
              by = attr(f0_obj, "sampleRate")^-1, 
              length.out = length(f0_vals)
            )
            
            pitch_df <- data.frame(
              time = f0_times,
              freq = f0_vals
            )
            
            pitch_df <- pitch_df[pitch_df$freq > 0 & pitch_df$freq < 600 & is.finite(pitch_df$freq), ]
            
            if (nrow(pitch_df) > 0) {
              rv$pitch_data <- pitch_df
            } else {
              rv$pitch_data <- NULL
            }
          } else {
            rv$pitch_data <- NULL
          }
        }
      }, error = function(e) {
        message("Error al extraer segmento: ", e$message)
      })
    }
    
    # Calcular métricas automáticamente si está activado
    if (is.na(rv$df_full$F0_mean[i_full]) || is.na(rv$df_full$Int_mean[i_full])) {
      res <- compute_measures(i_full, show_timing = FALSE)
      
      if (!is.null(res)) {
        rv$df_full$F0_mean[i_full]           <- res$F0
        rv$df_full$Int_mean[i_full]          <- res$Int
        rv$df_full$F0_range_st[i_full]       <- res$F0_range_st
        rv$df_full$F0_delta_st[i_full]       <- res$F0_delta_st
        rv$df_full$F0_final_delta_st[i_full] <- res$F0_final_delta_st
        rv$df_full$F0_final_pattern[i_full]  <- res$F0_final_pattern
        
        # Guardar automáticamente después de calcular (sin backup)
        if (!is.null(rv$current_filename)) {
          tryCatch({
            save_analysis_file(rv$df_full, rv$current_filename, make_backup_copy = FALSE)
          }, error = function(e) {
            message("Error al guardar después de calcular: ", e$message)
          })
        }
        
        # Actualizar df mostrado
        rv$df <- df_to_display()
        replaceData(proxy, rv$df, resetPaging = FALSE, rownames = FALSE)
      }
    }
    
    # Cargar anotaciones existentes en los selectInputs
    # Cargar anotaciones existentes en los selectInputs (1..25)
for (j in 1:n_anot) {
  col_name <- paste0("anot", j)
  if (col_name %in% names(rv$df_full)) {
    current <- rv$df_full[[col_name]][i_full]

    # Si está vacío → nada seleccionado
    if (is.na(current) || current == "") {
      sel <- character(0)
    } else {
      # Dividir la cadena "A; B; C" en c("A", "B", "C")
      sel <- unlist(strsplit(current, ";\\s*"))
    }

    updateSelectInput(session, col_name, selected = sel)
  }
}

# Cargar observaciones existentes
updateTextAreaInput(
  session, "observaciones",
  value = ifelse(is.na(rv$df_full$observaciones[i_full]),
                 "", rv$df_full$observaciones[i_full])
)

  })
  
  # Mostrar texto de la fila seleccionada
  output$selected_text <- renderText({
    req(rv$df_full, rv$selected_row_index)
    i_full <- rv$selected_row_index
    rv$df_full$label[i_full]
  })
  
  # Guardar anotaciones
 
  # ---- Guardar anotaciones (anot1..anot25 + observaciones) ----

  # ---- Guardar anotaciones (anot1..anot25 + observaciones) ----
observeEvent(input$save_annotation, {
  req(rv$df_full, rv$selected_row_index, rv$current_filename)

  i_full <- rv$selected_row_index
  if (is.null(i_full) || is.na(i_full) || i_full < 1 || i_full > nrow(rv$df_full)) {
    showNotification("Error: no hay fila seleccionada válida", type = "error")
    return()
  }

  # Guardar todas las anotaciones dinámicamente
  for (j in 1:n_anot) {
  id <- paste0("anot", j)
  val <- input[[id]]  # puede ser vector

  # Si no hay nada seleccionado → NA
  if (is.null(val) || length(val) == 0) {
    rv$df_full[[id]][i_full] <- NA_character_
  } else {
    # Colapsar multiselección en "opción1; opción2; opción3"
    rv$df_full[[id]][i_full] <- paste(val, collapse = "; ")
  }
}

  # Guardar observaciones
  rv$df_full$observaciones[i_full] <- if (is.null(input$observaciones) || input$observaciones == "") {
    NA_character_
  } else {
    input$observaciones
  }

  # Guardar archivo automáticamente
  tryCatch({
    saved_file <- save_analysis_file(
      rv$df_full,
      rv$current_filename,
      make_backup_copy = FALSE
    )
    message("✓ Análisis guardado en: ", saved_file)
  }, error = function(e) {
    showNotification(paste("Error al guardar:", e$message), type = "error")
    return()
  })

  # Actualizar df mostrado + tabla
  rv$df <- df_to_display()
  replaceData(proxy, rv$df, resetPaging = FALSE, rownames = FALSE)

  # Status UI
  output$annotation_status <- renderText({
    sprintf(
      "✓ Guardado en analisis_%s (fila %d)",
      tools::file_path_sans_ext(basename(rv$current_filename)),
      i_full
    )
  })

  showNotification("Anotaciones guardadas y sincronizadas", type = "message", duration = 2)
})


  # Calcular todas las filas
  observeEvent(input$compute_all, {
    req(rv$df_full, rv$audio_path)
    
    n_rows <- nrow(rv$df_full)
    output$compute_status <- renderText({
      sprintf("Procesando fila 0 de %d...", n_rows)
    })
    
    start_time <- Sys.time()
    times_per_row <- numeric()
    
    withProgress(message = 'Calculando métricas...', value = 0, {
      for (i in 1:n_rows) {
        row_start <- Sys.time()
        
        # Calcular métricas
        res <- compute_measures(i, show_timing = FALSE)
        if (!is.null(res)) {
          rv$df_full$F0_mean[i]  <- res$F0
          rv$df_full$Int_mean[i] <- res$Int
          rv$df_full$F0_range_st[i] <- res$F0_range_st
          rv$df_full$F0_delta_st[i] <- res$F0_delta_st
          rv$df_full$F0_final_delta_st[i] <- res$F0_final_delta_st
          rv$df_full$F0_final_pattern[i] <- res$F0_final_pattern
        }
        
        # Calcular tiempo estimado restante
        row_elapsed <- as.numeric(difftime(Sys.time(), row_start, units = "secs"))
        times_per_row <- c(times_per_row, row_elapsed)
        
        avg_time <- mean(times_per_row)
        remaining_rows <- n_rows - i
        eta_seconds <- remaining_rows * avg_time
        eta_formatted <- if (eta_seconds > 60) {
          sprintf("~%.1f min", eta_seconds / 60)
        } else {
          sprintf("~%.0f seg", eta_seconds)
        }
        
        # Actualizar progreso
        incProgress(1/n_rows, 
                    detail = sprintf("Fila %d/%d (%.1f s/fila, ETA: %s)", 
                                     i, n_rows, avg_time, eta_formatted))
        
        # Actualizar status cada 5 filas
        if (i %% 5 == 0 || i == n_rows) {
          output$compute_status <- renderText({
            sprintf("Procesando: %d/%d filas (%.1f%%). Tiempo promedio: %.2f s/fila. ETA: %s", 
                    i, n_rows, 100*i/n_rows, avg_time, eta_formatted)
          })
        }
      }
    })
    
    # Actualizar df mostrado y tabla
    rv$df <- df_to_display()
    replaceData(proxy, rv$df, resetPaging = FALSE, rownames = FALSE)
    
    # Guardar análisis automáticamente después de calcular todas las métricas
    if (!is.null(rv$current_filename)) {
      tryCatch({
        saved_file <- save_analysis_file(rv$df_full, rv$current_filename, make_backup_copy = FALSE)
        message("Análisis completo guardado en: ", saved_file)
      }, error = function(e) {
        showNotification(paste("Error al guardar:", e$message), type = "error")
      })
    }
    
    # Mostrar resumen final
    total_elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    n_valid_f0 <- sum(!is.na(rv$df_full$F0_mean))
    n_valid_int <- sum(!is.na(rv$df_full$Int_mean))
    
    output$compute_status <- renderText({
      sprintf("✓ Completado y guardado: %d/%d filas con F0, %d/%d con intensidad\nTiempo total: %.1f min (%.2f s/fila promedio)", 
              n_valid_f0, n_rows, n_valid_int, n_rows,
              total_elapsed / 60, total_elapsed / n_rows)
    })
    
    showNotification(sprintf("Cálculo completado y guardado en %.1f minutos", total_elapsed / 60), 
                     type = "message", duration = 5)
  })
  
  # Renderizar reproductor de video
 
# Renderizar reproductor de video CORREGIDO
  output$video_player <- renderUI({
    # Verificamos condiciones
    if (rv$is_video && !is.null(rv$video_url) && !is.null(rv$selected_start)) {
      
      start_time <- round(rv$selected_start, 3)
      end_time   <- round(rv$selected_end, 3)
      
      # Generar ID único para evitar conflictos
      video_id <- paste0("video_", round(runif(1) * 10000))
      
      tagList(
        h4("Video del segmento seleccionado"),
        tags$video(
          id = video_id,
          width = "100%",
          height = "300px",
          controls = "controls",
          preload = "auto",
          playsinline = "playsinline", # Ayuda en navegadores modernos
          tags$source(
            src = rv$video_url,
            type = "video/mp4"
          ),
          "Tu navegador no soporta el elemento video."
        ),
        tags$script(HTML(sprintf(
          "
          (function() {
            var video = document.getElementById('%s');
            if (video) {
              // 1. Forzar carga de metadatos
              video.load();
              
              // 2. Cuando los metadatos carguen, saltar al inicio del segmento
              video.onloadedmetadata = function() {
                 if(Number.isFinite(%f)) {
                    video.currentTime = %f;
                 }
              };
            }
          })();
          ",
          video_id, start_time, start_time
        ))),
        p(sprintf("Segmento: %.2f s - %.2f s (duración: %.2f s)", 
                  start_time, end_time, end_time - start_time),
          style = "color: #666; font-size: 12px; margin-top: 5px;")
      )
    } else {
      NULL
    }
  })

  # Renderizar oscilograma
  output$oscillo_plot <- renderPlot({
    req(rv$selected_segment)
    seewave::oscillo(
      rv$selected_segment,
      f = rv$selected_segment@samp.rate,
      k = 1,
      colwave = "steelblue"
    )
    title("Oscilograma")
  })
  
  # Renderizar espectrograma
  output$spectro_plot <- renderPlot({
  req(rv$selected_segment)
  
  seg <- rv$selected_segment
  
  # Comprobaciones de seguridad
  if (!inherits(seg, "Wave")) {
    plot.new()
    title("Espectrograma")
    text(0.5, 0.5, "Objeto no es de clase 'Wave'", cex = 1, col = "red")
    return()
  }
  
  fs <- seg@samp.rate
  n  <- length(seg@left)
  
  if (is.null(fs) || is.na(fs) || fs <= 0 || is.null(n) || n < 32) {
    plot.new()
    title("Espectrograma")
    msg <- sprintf("Segmento inválido: fs=%s, n=%s", fs, n)
    text(0.5, 0.5, msg, cex = 0.9, col = "red")
    return()
  }
  
  # Ventana: nunca más grande que el segmento
  wl_use <- min(256L, n)
  
  # Intentar dibujar el espectrograma; si falla, mostrar mensaje en vez de petar
  tryCatch({
    seewave::spectro(
      seg,
      f     = fs,
      wl    = wl_use,
      ovlp  = 85,
      osc   = FALSE,
      scale = TRUE
      # SIN flim, SIN palette → quitamos las fuentes típicas de "subscript out of bounds"
    )
    title("Espectrograma (banda ancha)")
  }, error = function(e) {
    plot.new()
    title("Espectrograma - error")
    text(0.5, 0.5,
         paste("Error en spectro():", e$message),
         cex = 0.8, col = "red")
  })
})



  
  # Renderizar curva de pitch
  output$pitch_plot <- renderPlot({
    if (is.null(rv$pitch_data)) {
      plot.new()
      title("Curva melódica (F0)")
      text(0.5, 0.5, "Sin valores de F0 detectados", cex = 1.2, col = "gray50")
      return()
    }
    
    if (nrow(rv$pitch_data) == 0) {
      plot.new()
      title("Curva melódica (F0)")
      text(0.5, 0.5, "No hay puntos de F0 válidos", cex = 1.2, col = "gray50")
      return()
    }
    
    # Usar escala automática por defecto de R
    plot(
      rv$pitch_data$time,
      rv$pitch_data$freq,
      type = "b",
      pch = 19,
      col = "dodgerblue3",
      lwd = 2,
      cex = 1.2,
      xlab = "Tiempo (s)",
      ylab = "Frecuencia (Hz)",
      main = sprintf("Curva melódica (F0) - %d puntos", nrow(rv$pitch_data))
    )
    grid(col = "gray80", lwd = 1)
  })
  
  # Exportar a TXT
  observeEvent(input$export_txt, {
    req(rv$df_full)
    
    tryCatch({
      filename <- paste0("anotaciones_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".txt")
      write.table(rv$df_full, file = filename, sep = "\t", row.names = FALSE, quote = FALSE, na = "")
      
      output$export_status <- renderText({
        sprintf("✓ Archivo exportado exitosamente: %s\nRuta: %s", filename, normalizePath(filename))
      })
      
      showNotification(paste("Datos exportados a", filename), type = "message", duration = 5)
    }, error = function(e) {
      output$export_status <- renderText({
        paste("✗ Error al exportar:", e$message)
      })
      showNotification(paste("Error:", e$message), type = "error", duration = 5)
    })
  })
  
  # Descargar CSV
  output$download_csv <- downloadHandler(
    filename = function() {
      paste0("anotaciones_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv")
    },
    content = function(file) {
      write.csv(rv$df_full, file, row.names = FALSE, na = "")
    }
  )
  
  # Exportar a Google Sheets
  observeEvent(input$export_gsheet, {
    req(rv$df_full, input$gsheet_url)
    
    if (!requireNamespace("googlesheets4", quietly = TRUE)) {
      output$export_status <- renderText({
        "✗ Error: El paquete 'googlesheets4' no está instalado.\nInstálalo con: install.packages('googlesheets4')"
      })
      showNotification("Instala el paquete 'googlesheets4' primero", type = "error", duration = 5)
      return()
    }
    
    tryCatch({
      library(googlesheets4)
      
      # Extraer ID de la URL
      sheet_id <- input$gsheet_url
      if (grepl("/d/", sheet_id)) {
        sheet_id <- sub(".*/d/([a-zA-Z0-9_-]+).*", "\\1", sheet_id)
      }
      
      # Validar que no sea URL vacía
      if (nchar(trimws(sheet_id)) == 0) {
        output$export_status <- renderText({
          "✗ Error: URL de Google Sheets inválida"
        })
        showNotification("Por favor, ingresa una URL válida de Google Sheets", type = "error", duration = 5)
        return()
      }
      
      # Desactivar oauth_email para usar credenciales en caché sin requerir email
      gs4_deauth()
      
      withProgress(message = 'Exportando a Google Sheets...', value = 0, {
        incProgress(0.3, detail = "Limpiando hoja anterior...")
        
        # Intentar limpiar la hoja anterior
        tryCatch({
          range_clear(ss = sheet_id, sheet = "Anotaciones")
        }, error = function(e) {
          # Si falla la limpieza, continuamos igual
          NULL
        })
        
        incProgress(0.6, detail = "Escribiendo datos...")
        
        # Escribir datos con range_write (más control y estable)
        range_write(
          ss = sheet_id,
          data = rv$df_full,
          sheet = "Anotaciones",
          range = "A1",
          reformat = FALSE
        )
        
        incProgress(1, detail = "✓ Completado")
      })
      
      output$export_status <- renderText({
        sprintf("✓ Datos exportados exitosamente a Google Sheets\n\n📊 Filas: %d | 📋 Columnas: %d\n🔗 URL: %s", 
                nrow(rv$df_full), ncol(rv$df_full), input$gsheet_url)
      })
      
      showNotification("✓ Datos exportados a Google Sheets correctamente", type = "message", duration = 5)
    }, error = function(e) {
      error_msg <- as.character(e$message)
      
      # Detectar tipo de error específico
      if (grepl("403|PERMISSION", error_msg, ignore.case = TRUE)) {
        detailed_error <- paste(
          "⚠️ Error de permisos (403)\n\n",
          "Soluciones:\n\n",
          "OPCIÓN 1 - Reautenticar:\n",
          "Ejecuta en la consola R:\n",
          "  googlesheets4::gs4_auth(new_user = TRUE)\n\n",
          "OPCIÓN 2 - Usar descarga CSV:\n",
          "Ve a la pestaña 'Exportar' y descarga\n",
          "el archivo CSV directamente\n\n",
          "OPCIÓN 3 - URL correcta:\n",
          "Verifica que copiaste la URL completa"
        )
      } else if (grepl("404|NOT_FOUND", error_msg, ignore.case = TRUE)) {
        detailed_error <- paste(
          "✗ Documento no encontrado (404)\n\n",
          "Verifica:\n",
          "- La URL sea correcta\n",
          "- El documento no fue eliminado\n",
          "- Tengas acceso al documento"
        )
      } else if (grepl("UNAUTHENTICATED", error_msg, ignore.case = TRUE)) {
        detailed_error <- paste(
          "✗ No autenticado\n\n",
          "Ejecuta en consola R:\n",
          "  googlesheets4::gs4_auth(new_user = TRUE)"
        )
      } else {
        detailed_error <- paste("✗ Error:", error_msg)
      }
      
      output$export_status <- renderText({
        detailed_error
      })
      showNotification(paste("Error:", error_msg), type = "error", duration = 7)
    })
  })
  
  # Mostrar texto de la fila seleccionada
  # Reproducir segmento de audio (sin contexto)
  observeEvent(input$play_segment, {
    req(rv$df_full, rv$selected_row_index, rv$audio_cached)  # Usar índice cacheado
    
    i_full <- rv$selected_row_index
    
    tryCatch({
      # Validar índice
      if (is.null(i_full) || is.na(i_full) || i_full < 1 || i_full > nrow(rv$df_full)) {
        showNotification("Selecciona una fila válida primero", type = "error", duration = 3)
        return()
      }
      
      # Acceder al dataframe completo con el índice cacheado
      start <- as.numeric(rv$df_full$start[i_full])
      end <- as.numeric(rv$df_full$end[i_full])
      
      if (is.na(start) || is.na(end)) {
        showNotification("Tiempos de inicio/fin no válidos", type = "error", duration = 3)
        return()
      }
      
      # Extraer segmento desde audio en cache
      wave_full <- rv$audio_cached
      fs <- wave_full@samp.rate
      seg <- seewave::cutw(wave_full, from = start, to = end, output = "Wave", f = fs)
      
      # Guardar temporalmente y reproducir
      temp_audio <- tempfile(fileext = ".wav")
      tuneR::writeWave(seg, filename = temp_audio)
      
  # Reproducir con afplay (macOS) de forma asíncrona usando system2
  # Evitar poner '&' en la cadena cuando se usa wait = FALSE, porque
  # internamente R ya lanza el proceso en background y añadir '&'
  # causa un '... & &' que falla en zsh.
  play_sound(temp_audio)
      
      showNotification(sprintf("▶️ Reproduciendo segmento (%.2f s)", end - start), 
                      type = "message", duration = 2)
    }, error = function(e) {
      showNotification(paste("Error al reproducir:", e$message), type = "error", duration = 3)
    })
  })

  observeEvent(input$play_segment1, {
    req(rv$df_full, rv$selected_row_index, rv$audio_cached)  # Usar índice cacheado
    
    i_full <- rv$selected_row_index
    
    tryCatch({
      # Validar índice
      if (is.null(i_full) || is.na(i_full) || i_full < 1 || i_full > nrow(rv$df_full)) {
        showNotification("Selecciona una fila válida primero", type = "error", duration = 3)
        return()
      }
      
      # Acceder al dataframe completo con el índice cacheado
      start <- as.numeric(rv$df_full$start[i_full])
      end <- as.numeric(rv$df_full$end[i_full])
      
      if (is.na(start) || is.na(end)) {
        showNotification("Tiempos de inicio/fin no válidos", type = "error", duration = 3)
        return()
      }
      
      # Extraer segmento desde audio en cache
      wave_full <- rv$audio_cached
      fs <- wave_full@samp.rate
      seg <- seewave::cutw(wave_full, from = start, to = end, output = "Wave", f = fs)
      
      # Guardar temporalmente y reproducir
      temp_audio <- tempfile(fileext = ".wav")
      tuneR::writeWave(seg, filename = temp_audio)
      
  # Reproducir con afplay (macOS) de forma asíncrona usando system2
  # Evitar poner '&' en la cadena cuando se usa wait = FALSE, porque
  # internamente R ya lanza el proceso en background y añadir '&'
  # causa un '... & &' que falla en zsh.
  play_sound(temp_audio)
      
      showNotification(sprintf("▶️ Reproduciendo segmento (%.2f s)", end - start), 
                      type = "message", duration = 2)
    }, error = function(e) {
      showNotification(paste("Error al reproducir:", e$message), type = "error", duration = 3)
    })
  })
  
  # Reproducir con contexto ampliado
  observeEvent(input$play_with_context, {
    req(rv$df_full, rv$selected_row_index, rv$audio_cached)  # Usar índice cacheado
    
    i_full <- rv$selected_row_index
    
    tryCatch({
      # Validar índice
      if (is.null(i_full) || is.na(i_full) || i_full < 1 || i_full > nrow(rv$df_full)) {
        showNotification("Selecciona una fila válida primero", type = "error", duration = 3)
        return()
      }
      
      # Acceder al dataframe completo con el índice cacheado
      start <- as.numeric(rv$df_full$start[i_full])
      end <- as.numeric(rv$df_full$end[i_full])
      
      if (is.na(start) || is.na(end)) {
        showNotification("Tiempos de inicio/fin no válidos", type = "error", duration = 3)
        return()
      }
      
      # Ampliar con contexto - validar inputs
      context_before <- input$context_before
      context_after <- input$context_after
      
      if (is.null(context_before) || is.na(context_before)) context_before <- 0
      if (is.null(context_after) || is.na(context_after)) context_after <- 0
      
      # Asegurar valores numéricos
      context_before <- as.numeric(context_before)
      context_after <- as.numeric(context_after)
      
      start_extended <- max(0, start - context_before)
      
      # Obtener duración total del audio
      wave_full <- rv$audio_cached
      total_duration <- length(wave_full@left) / wave_full@samp.rate
      end_extended <- min(total_duration, end + context_after)
      
      # Extraer segmento ampliado desde audio en cache
      fs <- wave_full@samp.rate
      seg <- seewave::cutw(wave_full, from = start_extended, to = end_extended, output = "Wave", f = fs)
      
      # Guardar temporalmente y reproducir
      temp_audio <- tempfile(fileext = ".wav")
      tuneR::writeWave(seg, filename = temp_audio)
      
  # Reproducir con afplay (macOS) de forma asíncrona usando system2
  play_sound(temp_audio)
      
      showNotification(
        sprintf("▶️ Reproduciendo con contexto: -%.1fs +%.1fs (total: %.2f s)", 
                context_before, context_after, end_extended - start_extended), 
        type = "message", duration = 3
      )
    }, error = function(e) {
      showNotification(paste("Error al reproducir con contexto:", e$message), type = "error", duration = 5)
    })


  })

  compute_segment_metrics <- function(wav_path, t_start, t_end) {
    tryCatch({
      # wrassp requiere rutas de archivo, por eso era vital convertir mp3 a wav
      
      # 1. Calcular F0 usando ksvF0 (algoritmo estándar)
      # windowShift = 10ms
      f0_data <- wrassp::ksvF0(wav_path, beginTime = t_start, endTime = t_end, toFile = FALSE)
      
      # Extraer valores (la primera columna suelen ser los Hz)
      f0_vals <- f0_data$F0
      f0_vals <- f0_vals[f0_vals > 0] # Eliminar 0s (silencios/sordos)
      
      mean_f0 <- if(length(f0_vals) > 0) mean(f0_vals, na.rm=TRUE) else NA
      
      # 2. Calcular Intensidad (RMS)
      rms_data <- wrassp::rmsana(wav_path, beginTime = t_start, endTime = t_end, toFile = FALSE)
      rms_vals <- rms_data$rms
      rms_vals <- rms_vals[rms_vals > 0]
      
      # Convertir a decibelios si wrassp lo devuelve lineal (wrassp suele devolver lineal)
      # Pero a veces es más fácil usar la media directa si solo buscas cambios relativos.
      # Una aproximación simple a dB: 20 * log10(val)
      mean_int <- if(length(rms_vals) > 0) mean(rms_vals, na.rm=TRUE) else NA
      
      return(list(f0 = mean_f0, int = mean_int))
      
    }, error = function(e) {
      return(list(f0 = NA, int = NA))
    })
  }

  # Observador para calcular cuando se carga la tabla
  # Observador para calcular métricas cuando se carga/modifica la tabla
observe({
  # Mensajes posibles
  mensajes <- c(
    "¡Vamos, Alba/Yaiza, estás en el camino hacia el TFM! 🚀✨",
    "Hoy es un buen día para avanzar un poquito más 😌💡",
    "Tu investigación importa. Sigue adelante 🌱📖",
    "La ciencia te necesita, sigue trabajando 🧠🌟"
  )

  # Elegir uno al azar
  mensaje <- sample(mensajes, 1)

  # Mostrar popup motivacional
  shinyjs::runjs(sprintf("alert('%s');", mensaje))
})

}

  


shinyApp(ui, server)
