#!/bin/bash
# ============================================================
# Supabase DB Kurulum — SQL dosyalarını sırayla çalıştırır
# Gereksinim: psql kurulu olmalı
# Kullanım (proje kökünden): bash scripts/setup-db.sh
# ============================================================

set -euo pipefail

BLUE='\033[0;34m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
log() { echo -e "${BLUE}[DB]${NC} $1"; }
ok()  { echo -e "${GREEN}[OK]${NC} $1"; }
err() { echo -e "${RED}[Hata]${NC} $1"; exit 1; }

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SQL_DIR="$BASE_DIR/src/sql"
ENV_FILE="$BASE_DIR/src/.env"

# psql kontrolü
command -v psql >/dev/null 2>&1 || err "psql bulunamadı.
  Kurulum: https://www.postgresql.org/download/windows/ → Stack Builder → Command Line Tools"

# .env'den postgres URL'ini oku
PG_RAW=$(grep "^SUPABASE_SERVICE_ROLE_KEY=" "$ENV_FILE" \
  | sed 's/SUPABASE_SERVICE_ROLE_KEY=\s*//' \
  | tr -d '"' | tr -d "'" | tr -d ' ')

[[ -z "$PG_RAW" || "$PG_RAW" != postgresql* ]] && \
  err "SUPABASE_SERVICE_ROLE_KEY src/.env'de postgres URL formatında değil"

# Bileşenleri çıkar
PG_HOST=$(echo "$PG_RAW" | sed 's|postgresql://[^@]*@||' | cut -d: -f1)
PG_PORT=$(echo "$PG_RAW" | sed 's|postgresql://[^@]*@[^:]*:||' | cut -d/ -f1)
PG_USER=$(echo "$PG_RAW" | sed 's|postgresql://||' | cut -d: -f1)
PG_DB="postgres"
# Şifre: "postgresql://user:PASS@host" formatından PASS'i çıkar
PG_PASS=$(echo "$PG_RAW" | sed 's|postgresql://[^:]*:||' | sed 's|@.*||')

export PGPASSWORD="$PG_PASS"

log "Bağlantı kontrol ediliyor → $PG_HOST:$PG_PORT/$PG_DB"
psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" \
     --set=sslmode=require \
     -c "SELECT current_database(), NOW()::DATE AS bugun;" \
     >/dev/null 2>&1 || err "Veritabanına bağlanılamadı. Şifreyi veya bağlantı URL'ini kontrol et."
ok "Bağlantı başarılı"
echo ""

SQL_FILES=(
  "001_schema.sql"
  "002_views.sql"
  "003_rls.sql"
  "004_triggers.sql"
  "seed.sql"
)

for f in "${SQL_FILES[@]}"; do
  log "Çalıştırılıyor: $f ..."
  psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" \
       --set=sslmode=require \
       -v ON_ERROR_STOP=1 \
       -f "$SQL_DIR/$f"
  ok "$f tamamlandı"
  echo ""
done

unset PGPASSWORD

echo ""
ok "Tüm SQL dosyaları başarıyla uygulandı!"
log "Sonraki adım: bash scripts/create-users.sh"
