#!/bin/bash
set -euo pipefail

# Verzeichnisse
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "  Dart & Flutter Lehrbuch - PDF-Erzeugung"
echo "=========================================="
echo ""

# --- Hilfsfunktionen ---

# Inhalt einer Markdown-Datei einfügen (erste # Überschrift entfernen, Headings +2 shiften)
insert_content() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    return
  fi
  sed '1{/^# /d}' "$file" \
    | sed '/^> \*\*Dauer:\*\*/d' \
    | sed '/^> \*\*Schwierigkeit:\*\*/d' \
    | sed 's/^######/########/; s/^#####/#######/; s/^####/######/; s/^###/#####/; s/^##/####/' \
    | sed '/^---$/d; /^> \*\*Dauer:/d' \
    | sed 's/┌/+/g; s/┐/+/g; s/└/+/g; s/┘/+/g; s/├/+/g; s/┤/+/g; s/┬/+/g; s/┴/+/g; s/┼/+/g; s/─/-/g; s/│/|/g; s/✓/[x]/g; s/✗/[ ]/g; s/→/->/g; s/←/<-/g'
  echo ""
}

# Eine Einheit (Lehrstoff + Übung + Lösung + Ressourcen) einfügen
insert_unit() {
  local unit_dir="$1"
  local unit_num="$2"
  local unit_title="$3"

  echo ""
  echo "## ${unit_num}: ${unit_title}"
  echo ""

  # Lehrstoff
  if [[ -f "$unit_dir/lehrstoff.md" ]]; then
    insert_content "$unit_dir/lehrstoff.md"
    echo ""
  fi

  # Übung
  if [[ -f "$unit_dir/uebung.md" ]]; then
    echo "### Übung"
    echo ""
    insert_content "$unit_dir/uebung.md"
    echo ""
  fi

  # Lösung
  if [[ -f "$unit_dir/loesung.md" ]]; then
    echo "### Lösung"
    echo ""
    insert_content "$unit_dir/loesung.md"
    echo ""
  fi

  # Ressourcen
  if [[ -f "$unit_dir/ressourcen.md" ]]; then
    echo "### Ressourcen"
    echo ""
    insert_content "$unit_dir/ressourcen.md"
    echo ""
  fi
}

# Markdown zu PDF konvertieren
build_pdf() {
  local md_file="$1"
  local pdf_file="$2"
  local title="$3"
  local subtitle="$4"

  echo "  pandoc -> $pdf_file ..."

  pandoc "$md_file" \
    -o "$pdf_file" \
    --pdf-engine=lualatex \
    --top-level-division=chapter \
    --toc \
    --toc-depth=2 \
    --number-sections \
    -V documentclass=report \
    -V papersize=a4 \
    -V fontsize=11pt \
    -V title="$title" \
    -V subtitle="$subtitle" \
    -V author="Lehrplan für Entwickler mit Vorkenntnissen in C++, JavaScript und Python" \
    -V date="$(date +'%B %Y')" \
    -H "$SCRIPT_DIR/header.tex" \
    --highlight-style=tango \
    -V geometry:"top=2.5cm, bottom=2.5cm, left=2.5cm, right=2.5cm" \
    2>&1 | grep -v "^\[WARNING\]" || true

  if [[ -f "$pdf_file" ]]; then
    local size
    size=$(du -h "$pdf_file" | cut -f1)
    echo "  -> $pdf_file ($size)"
  else
    echo "  FEHLER: $pdf_file wurde nicht erzeugt!"
    return 1
  fi
}

# =====================================================
# PDF 1: FRONTEND (Blöcke 1-4)
# =====================================================

echo "[1/2] Erzeuge Frontend-Markdown..."

FRONTEND_MD="$SCRIPT_DIR/_frontend.md"
FRONTEND_PDF="$SCRIPT_DIR/Dart-Flutter-Frontend.pdf"

{
  # --- Block 1: Dart ---
  echo "# Block 1: Dart -- Die Sprache"
  echo ""
  echo "In diesem Block lernst du Dart als Sprache kennen. Da du bereits C++, JS und Python beherrschst, wirst du viele Konzepte wiedererkennen. Der Fokus liegt auf den Dart-spezifischen Eigenheiten."
  echo ""

  insert_unit "$PROJECT_DIR/block_1_dart/01_syntax_typsystem"              "Einheit 1.1"  "Dart Syntax & Typsystem"
  insert_unit "$PROJECT_DIR/block_1_dart/02_funktionen_kontrollstrukturen"  "Einheit 1.2"  "Funktionen & Kontrollstrukturen"
  insert_unit "$PROJECT_DIR/block_1_dart/03_klassen_konstruktoren"          "Einheit 1.3"  "Klassen & Konstruktoren"
  insert_unit "$PROJECT_DIR/block_1_dart/04_vererbung_interfaces"           "Einheit 1.4"  "Vererbung & Interfaces"
  insert_unit "$PROJECT_DIR/block_1_dart/05_mixins_extensions"              "Einheit 1.5"  "Mixins & Extensions"
  insert_unit "$PROJECT_DIR/block_1_dart/06_futures_async"                  "Einheit 1.6"  "Futures & async/await"
  insert_unit "$PROJECT_DIR/block_1_dart/07_streams"                        "Einheit 1.7"  "Streams"
  insert_unit "$PROJECT_DIR/block_1_dart/08_collections"                    "Einheit 1.8"  "Collections"
  insert_unit "$PROJECT_DIR/block_1_dart/09_generics_null_safety"           "Einheit 1.9"  "Generics & Null Safety"
  insert_unit "$PROJECT_DIR/block_1_dart/10_patterns_records"               "Einheit 1.10" "Pattern Matching & Records"

  # --- Block 2: Flutter Grundlagen ---
  echo "# Block 2: Flutter -- Grundlagen"
  echo ""
  echo "In diesem Block lernst du die Grundlagen von Flutter: Widgets, Layout, Navigation und Styling."
  echo ""

  insert_unit "$PROJECT_DIR/block_2_flutter_grundlagen/01_architektur_setup"     "Einheit 2.1"  "Architektur & Setup"
  insert_unit "$PROJECT_DIR/block_2_flutter_grundlagen/02_stateless_widgets"     "Einheit 2.2"  "StatelessWidget & Grundlagen"
  insert_unit "$PROJECT_DIR/block_2_flutter_grundlagen/03_stateful_grundlagen"   "Einheit 2.3"  "StatefulWidget Grundlagen"
  insert_unit "$PROJECT_DIR/block_2_flutter_grundlagen/04_lifecycle_keys"        "Einheit 2.4"  "Lifecycle & Keys"
  insert_unit "$PROJECT_DIR/block_2_flutter_grundlagen/05_layout_basics"         "Einheit 2.5"  "Layout Basics"
  insert_unit "$PROJECT_DIR/block_2_flutter_grundlagen/06_container_sizing"      "Einheit 2.6"  "Container & Sizing"
  insert_unit "$PROJECT_DIR/block_2_flutter_grundlagen/07_listen_scrolling"      "Einheit 2.7"  "Listen & Scrolling"
  insert_unit "$PROJECT_DIR/block_2_flutter_grundlagen/08_styling_themes"        "Einheit 2.8"  "Styling & Themes"
  insert_unit "$PROJECT_DIR/block_2_flutter_grundlagen/09_navigation_basics"     "Einheit 2.9"  "Navigation Basics"
  insert_unit "$PROJECT_DIR/block_2_flutter_grundlagen/10_named_routes_gorouter" "Einheit 2.10" "Named Routes & go_router"

  # --- Block 3: Flutter Fortgeschritten ---
  echo "# Block 3: Flutter -- Fortgeschritten"
  echo ""
  echo "State Management, HTTP, lokale Datenspeicherung und Formulare."
  echo ""

  insert_unit "$PROJECT_DIR/block_3_flutter_fortgeschritten/01_state_konzepte"       "Einheit 3.1"  "State Management Konzepte"
  insert_unit "$PROJECT_DIR/block_3_flutter_fortgeschritten/02_provider_basics"       "Einheit 3.2"  "Provider Basics"
  insert_unit "$PROJECT_DIR/block_3_flutter_fortgeschritten/03_provider_advanced"     "Einheit 3.3"  "Provider Advanced"
  insert_unit "$PROJECT_DIR/block_3_flutter_fortgeschritten/04_http_requests"         "Einheit 3.4"  "HTTP Requests"
  insert_unit "$PROJECT_DIR/block_3_flutter_fortgeschritten/05_json_models"           "Einheit 3.5"  "JSON & Models"
  insert_unit "$PROJECT_DIR/block_3_flutter_fortgeschritten/06_future_stream_builder" "Einheit 3.6"  "FutureBuilder & StreamBuilder"
  insert_unit "$PROJECT_DIR/block_3_flutter_fortgeschritten/07_shared_preferences"    "Einheit 3.7"  "SharedPreferences"
  insert_unit "$PROJECT_DIR/block_3_flutter_fortgeschritten/08_lokale_datenbanken"    "Einheit 3.8"  "Lokale Datenbanken"
  insert_unit "$PROJECT_DIR/block_3_flutter_fortgeschritten/09_formulare_basics"      "Einheit 3.9"  "Formulare Basics"
  insert_unit "$PROJECT_DIR/block_3_flutter_fortgeschritten/10_formular_validierung"  "Einheit 3.10" "Formular Validierung"
  insert_unit "$PROJECT_DIR/block_3_flutter_fortgeschritten/11_dropdowns_checkboxen"  "Einheit 3.11" "Dropdowns & Checkboxen"
  insert_unit "$PROJECT_DIR/block_3_flutter_fortgeschritten/12_datepicker_dialoge"    "Einheit 3.12" "DatePicker & Dialoge"

  # --- Block 4: Profi ---
  echo "# Block 4: Profi-Themen & Abschlussprojekt"
  echo ""
  echo "Animationen, Testing, Packages und App-Veröffentlichung."
  echo ""

  insert_unit "$PROJECT_DIR/block_4_profi/01_implizite_animationen"      "Einheit 4.1"  "Implizite Animationen"
  insert_unit "$PROJECT_DIR/block_4_profi/02_explizite_animationen"      "Einheit 4.2"  "Explizite Animationen"
  insert_unit "$PROJECT_DIR/block_4_profi/03_unit_tests"                 "Einheit 4.3"  "Unit Tests"
  insert_unit "$PROJECT_DIR/block_4_profi/04_widget_integration_tests"   "Einheit 4.4"  "Widget & Integration Tests"
  insert_unit "$PROJECT_DIR/block_4_profi/05_packages_plugins"           "Einheit 4.5"  "Packages & Plugins"
  insert_unit "$PROJECT_DIR/block_4_profi/06_build_release"              "Einheit 4.6"  "Build & Release"
  insert_unit "$PROJECT_DIR/block_4_profi/07_abschlussprojekt"           "Einheit 4.7"  "Abschlussprojekt Frontend"

} > "$FRONTEND_MD"

echo "  $(wc -l < "$FRONTEND_MD") Zeilen"
build_pdf "$FRONTEND_MD" "$FRONTEND_PDF" \
  "Dart \& Flutter -- Frontend" \
  "Lehrbuch Teil A: Dart, Flutter Grundlagen, Fortgeschritten \& Profi"

echo ""

# =====================================================
# PDF 2: BACKEND (Blöcke 5-9)
# =====================================================

echo "[2/2] Erzeuge Backend-Markdown..."

BACKEND_MD="$SCRIPT_DIR/_backend.md"
BACKEND_PDF="$SCRIPT_DIR/Dart-Flutter-Backend.pdf"

{
  # --- Block 5: Server-Grundlagen ---
  echo "# Block 5: Server-Grundlagen"
  echo ""
  echo "Dart auf dem Server, Shelf-Framework, Routing, Middleware und Projektstruktur."
  echo ""

  insert_unit "$PROJECT_DIR/block_5_server_grundlagen/01_dart_server"     "Einheit 5.1"  "Dart auf dem Server"
  insert_unit "$PROJECT_DIR/block_5_server_grundlagen/02_shelf_basics"    "Einheit 5.2"  "Shelf Framework Basics"
  insert_unit "$PROJECT_DIR/block_5_server_grundlagen/03_routing"         "Einheit 5.3"  "Routing mit shelf_router"
  insert_unit "$PROJECT_DIR/block_5_server_grundlagen/04_middleware"      "Einheit 5.4"  "Middleware"
  insert_unit "$PROJECT_DIR/block_5_server_grundlagen/05_konfiguration"   "Einheit 5.5"  "Konfiguration & Environment"
  insert_unit "$PROJECT_DIR/block_5_server_grundlagen/06_projektstruktur" "Einheit 5.6"  "Projektstruktur"

  # --- Block 6: REST API ---
  echo "# Block 6: REST API Entwicklung"
  echo ""
  echo "REST-Prinzipien, JSON, CRUD, Validierung, Error Handling und API-Dokumentation."
  echo ""

  insert_unit "$PROJECT_DIR/block_6_rest_api/01_rest_prinzipien"      "Einheit 6.1"  "REST Prinzipien & Design"
  insert_unit "$PROJECT_DIR/block_6_rest_api/02_json_serialisierung"  "Einheit 6.2"  "JSON Serialisierung"
  insert_unit "$PROJECT_DIR/block_6_rest_api/03_request_body"         "Einheit 6.3"  "Request Body Parsing"
  insert_unit "$PROJECT_DIR/block_6_rest_api/04_crud_operationen"     "Einheit 6.4"  "CRUD Operationen"
  insert_unit "$PROJECT_DIR/block_6_rest_api/05_input_validierung"    "Einheit 6.5"  "Input Validierung"
  insert_unit "$PROJECT_DIR/block_6_rest_api/06_error_handling"       "Einheit 6.6"  "Error Handling"
  insert_unit "$PROJECT_DIR/block_6_rest_api/07_pagination_filtering" "Einheit 6.7"  "Pagination & Filtering"
  insert_unit "$PROJECT_DIR/block_6_rest_api/08_dokumentation"        "Einheit 6.8"  "API Dokumentation"

  # --- Block 7: Datenbanken ---
  echo "# Block 7: Datenbanken"
  echo ""
  echo "SQL, PostgreSQL, Repository Pattern, MongoDB, Redis und Caching."
  echo ""

  insert_unit "$PROJECT_DIR/block_7_datenbanken/01_sql_grundlagen"           "Einheit 7.1"  "SQL Grundlagen & PostgreSQL"
  insert_unit "$PROJECT_DIR/block_7_datenbanken/02_postgres_dart"            "Einheit 7.2"  "PostgreSQL mit Dart"
  insert_unit "$PROJECT_DIR/block_7_datenbanken/03_repository_pattern"       "Einheit 7.3"  "Repository Pattern"
  insert_unit "$PROJECT_DIR/block_7_datenbanken/04_relationale_modellierung" "Einheit 7.4"  "Relationale Modellierung"
  insert_unit "$PROJECT_DIR/block_7_datenbanken/05_migrations"               "Einheit 7.5"  "Migrations"
  insert_unit "$PROJECT_DIR/block_7_datenbanken/06_mongodb"                  "Einheit 7.6"  "NoSQL mit MongoDB"
  insert_unit "$PROJECT_DIR/block_7_datenbanken/07_queries_aggregationen"    "Einheit 7.7"  "Queries & Aggregationen"
  insert_unit "$PROJECT_DIR/block_7_datenbanken/08_redis_caching"            "Einheit 7.8"  "Caching mit Redis"

  # --- Block 8: Auth & Sicherheit ---
  echo "# Block 8: Authentifizierung & Sicherheit"
  echo ""
  echo "Passwort-Hashing, JWT, OAuth, API-Sicherheit und Auth-Testing."
  echo ""

  insert_unit "$PROJECT_DIR/block_8_auth_sicherheit/01_passwort_hashing" "Einheit 8.1"  "Passwort Hashing"
  insert_unit "$PROJECT_DIR/block_8_auth_sicherheit/02_jwt"              "Einheit 8.2"  "JWT Authentication"
  insert_unit "$PROJECT_DIR/block_8_auth_sicherheit/03_auth_middleware"  "Einheit 8.3"  "Auth Middleware"
  insert_unit "$PROJECT_DIR/block_8_auth_sicherheit/04_oauth"            "Einheit 8.4"  "OAuth 2.0 & Social Login"
  insert_unit "$PROJECT_DIR/block_8_auth_sicherheit/05_api_sicherheit"   "Einheit 8.5"  "API Sicherheit"
  insert_unit "$PROJECT_DIR/block_8_auth_sicherheit/06_auth_testing"     "Einheit 8.6"  "Auth Testing"

  # --- Block 9: Produktion ---
  echo "# Block 9: Produktion & Abschlussprojekt"
  echo ""
  echo "WebSockets, Background Jobs, Logging, Deployment und das Backend-Abschlussprojekt."
  echo ""

  insert_unit "$PROJECT_DIR/block_9_produktion/01_websockets"        "Einheit 9.1"  "WebSockets & Real-time"
  insert_unit "$PROJECT_DIR/block_9_produktion/02_background_jobs"   "Einheit 9.2"  "Background Jobs & Scheduling"
  insert_unit "$PROJECT_DIR/block_9_produktion/03_logging_monitoring" "Einheit 9.3"  "Logging & Monitoring"
  insert_unit "$PROJECT_DIR/block_9_produktion/04_deployment"        "Einheit 9.4"  "Deployment & Docker"
  insert_unit "$PROJECT_DIR/block_9_produktion/05_abschlussprojekt"  "Einheit 9.5"  "Abschlussprojekt Backend"

} > "$BACKEND_MD"

echo "  $(wc -l < "$BACKEND_MD") Zeilen"
build_pdf "$BACKEND_MD" "$BACKEND_PDF" \
  "Dart Server -- Backend" \
  "Lehrbuch Teil B: Server, REST API, Datenbanken, Auth \& Deployment"

echo ""

# --- Aufräumen ---
rm -f "$SCRIPT_DIR/_frontend.md" "$SCRIPT_DIR/_backend.md" "$SCRIPT_DIR/_combined.md"

# --- Zusammenfassung ---
echo "=========================================="
echo "  Fertig!"
echo "=========================================="
echo ""
ls -lh "$SCRIPT_DIR"/*.pdf 2>/dev/null | awk '{print "  " $NF " (" $5 ")"}'
echo ""
