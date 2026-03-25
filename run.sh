#!/bin/bash
# ============================================================
# Agent Team - Ana başlatma scripti
# Kullanım: ./run.sh [requirements.md yolu]
# Örnek:    ./run.sh inputs/requirements.md
# ============================================================

set -euo pipefail

REQUIREMENTS="${1:-inputs/requirements.md}"
OUTPUT_DIR="output"
AGENTS_DIR="agents"
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

# Renkli çıktı
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${BLUE}[Orchestrator]${NC} $1"; }
ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[Uyarı]${NC} $1"; }
err()  { echo -e "${RED}[Hata]${NC} $1"; exit 1; }

# Gerekli klasörleri oluştur
mkdir -p "$OUTPUT_DIR/backend" "$OUTPUT_DIR/frontend" "$OUTPUT_DIR/reviews" \
         src/backend src/frontend inputs

# Gereksinim dosyası kontrolü
if [ ! -f "$REQUIREMENTS" ]; then
  err "Gereksinim dosyası bulunamadı: $REQUIREMENTS\nKullanım: ./run.sh inputs/requirements.md"
fi

# Durum alanını kontrol eden yardımcı fonksiyon
check_status() {
  local file="$1"
  local stage="$2"
  if [ ! -f "$file" ]; then
    err "[$stage] Beklenen çıktı dosyası oluşturulmadı: $file"
  fi
  local status
  status=$(grep -m1 "^Durum:" "$file" | cut -d' ' -f2- | tr -d '[:space:]')
  if [ "$status" = "HATA" ]; then
    err "[$stage] Ajan HATA döndürdü. Detay için bakın: $file"
  fi
  if [ "$status" = "BEKLEMEDE" ]; then
    warn "[$stage] Ajan BEKLEMEDE durumunda. Devam etmek için Enter'a basın veya Ctrl+C ile iptal edin."
    read -r
  fi
}

# Ajan çalıştırıcı: run_agent <aşama-adı> <sistem-prompt-dosyası> <kullanıcı-mesajı>
run_agent() {
  local stage="$1"
  local prompt_file="$2"
  local user_msg="$3"

  local full_prompt
  full_prompt="$(cat "$prompt_file")

---

## Çalışma Dizini
$BASE_DIR

$user_msg"

  echo "$full_prompt" | claude --print --dangerously-skip-permissions
}

log "Pipeline başlatılıyor..."
log "Gereksinimler: $REQUIREMENTS"
echo ""

# ─── ADIM 1: PM Agent ───────────────────────────────────────
log "PM Agent çalışıyor..."
run_agent "pm" "$AGENTS_DIR/pm.md" \
"Aşağıdaki gereksinimleri oku ve output/spec.md dosyasına yaz.

## Gereksinimler
$(cat "$REQUIREMENTS")"

check_status "$OUTPUT_DIR/spec.md" "PM"
ok "Spec hazır → output/spec.md"
echo ""

# ─── ADIM 2: Backend Agent ──────────────────────────────────
log "Backend Developer çalışıyor..."
run_agent "backend" "$AGENTS_DIR/backend.md" \
"Aşağıdaki spec dosyasını oku, TypeScript/Express API'yi src/backend/ altına yaz ve output/backend/report.md oluştur.

## Spec (output/spec.md)
$(cat "$OUTPUT_DIR/spec.md")"

check_status "$OUTPUT_DIR/backend/report.md" "Backend"
ok "Backend tamamlandı → src/backend/ + output/backend/report.md"
echo ""

# ─── ADIM 3: Frontend Agent ─────────────────────────────────
log "Frontend Developer çalışıyor..."
run_agent "frontend" "$AGENTS_DIR/frontend.md" \
"Aşağıdaki spec ve backend raporunu oku, React/Vite UI'ı src/frontend/ altına yaz ve output/frontend/report.md oluştur.

## Spec (output/spec.md)
$(cat "$OUTPUT_DIR/spec.md")

## Backend Raporu (output/backend/report.md)
$(cat "$OUTPUT_DIR/backend/report.md")"

check_status "$OUTPUT_DIR/frontend/report.md" "Frontend"
ok "Frontend tamamlandı → src/frontend/ + output/frontend/report.md"
echo ""

# ─── ADIM 4: Reviewer Agent ─────────────────────────────────
log "Reviewer çalışıyor..."
run_agent "reviewer" "$AGENTS_DIR/reviewer.md" \
"Aşağıdaki spec, backend raporu ve frontend raporunu oku. Ardından src/backend/ ve src/frontend/ dizinlerindeki kodları incele.
output/reviews/backend-review.md ve output/reviews/frontend-review.md dosyalarını oluştur.

## Spec (output/spec.md)
$(cat "$OUTPUT_DIR/spec.md")

## Backend Raporu (output/backend/report.md)
$(cat "$OUTPUT_DIR/backend/report.md")

## Frontend Raporu (output/frontend/report.md)
$(cat "$OUTPUT_DIR/frontend/report.md")

Kaynak kod için şu dizinleri oku: src/backend/ ve src/frontend/"

check_status "$OUTPUT_DIR/reviews/backend-review.md" "Reviewer"
ok "İnceleme tamamlandı → output/reviews/"
echo ""

# ─── ADIM 5: QA Agent ───────────────────────────────────────
log "QA Engineer çalışıyor..."
run_agent "qa" "$AGENTS_DIR/qa.md" \
"Aşağıdaki spec ve raporları oku. Ardından src/ altındaki kaynak kodları incele.
Test dosyalarını src/backend/ ve src/frontend/ altına yaz. output/qa-report.md oluştur.

## Spec (output/spec.md)
$(cat "$OUTPUT_DIR/spec.md")

## Backend Raporu
$(cat "$OUTPUT_DIR/backend/report.md")

## Frontend Raporu
$(cat "$OUTPUT_DIR/frontend/report.md")

## Backend Review
$(cat "$OUTPUT_DIR/reviews/backend-review.md")

## Frontend Review
$(cat "$OUTPUT_DIR/reviews/frontend-review.md")

Kaynak kod için şu dizinleri oku: src/backend/ ve src/frontend/"

check_status "$OUTPUT_DIR/qa-report.md" "QA"
ok "Testler tamamlandı → src/*/tests/ + output/qa-report.md"
echo ""

# ─── ÖZET ────────────────────────────────────────────────────
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Pipeline tamamlandı!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "Üretilen kaynak dosyalar:"
find src/ \( -name "*.ts" -o -name "*.tsx" \) 2>/dev/null | head -30
echo ""
echo "Çıktılar:"
echo "  output/spec.md               — PM spec"
echo "  output/backend/report.md     — Backend özet"
echo "  output/frontend/report.md    — Frontend özet"
echo "  output/reviews/              — Kod inceleme raporları"
echo "  output/qa-report.md          — Test planı"
