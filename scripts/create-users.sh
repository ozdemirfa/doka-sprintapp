#!/bin/bash
# ============================================================
# Supabase Auth Kullanıcı Kurulumu
# 7 personel için Auth hesabı oluşturur, UPDATE SQL üretir
#
# Ön koşul: src/.env dosyasına şunu ekle →
#   SUPABASE_SERVICE_ROLE_JWT=eyJ...
#   (Supabase Dashboard → Project Settings → API → service_role)
#
# Kullanım (proje kökünden): bash scripts/create-users.sh
# ============================================================

set -euo pipefail

BLUE='\033[0;34m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${BLUE}[Auth]${NC} $1"; }
ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
err()  { echo -e "${RED}[Hata]${NC} $1"; exit 1; }
warn() { echo -e "${YELLOW}[Uyarı]${NC} $1"; }

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$BASE_DIR/src/.env"

# SUPABASE_URL
SUPABASE_URL=$(grep "^SUPABASE_URL=" "$ENV_FILE" \
  | sed 's/SUPABASE_URL=\s*//' | tr -d '"' | tr -d "'" | tr -d ' ')

# SUPABASE_SERVICE_ROLE_JWT (eyJ... ile başlayan JWT)
SERVICE_JWT=$(grep "^SUPABASE_SERVICE_ROLE_JWT=" "$ENV_FILE" 2>/dev/null \
  | sed 's/SUPABASE_SERVICE_ROLE_JWT=\s*//' | tr -d '"' | tr -d "'" | tr -d ' ' \
  || true)

if [ -z "$SERVICE_JWT" ] || [[ "$SERVICE_JWT" != eyJ* ]]; then
  err "SUPABASE_SERVICE_ROLE_JWT eksik veya geçersiz!

  Adımlar:
  1. https://supabase.com/dashboard/project/tjvpcivuanvqjyepmbyy/settings/api
  2. 'service_role' anahtarını kopyala (eyJ... ile başlar)
  3. src/.env dosyasına şu satırı ekle:
     SUPABASE_SERVICE_ROLE_JWT=eyJ..."
fi

# Varsayılan şifre — tüm kullanıcılar için aynı başlangıç şifresi
DEFAULT_PASS="Doka2026!"

AUTH_URL="${SUPABASE_URL}/auth/v1/admin/users"

# Kullanıcı listesi: "pkod|ad|soyad|email"
declare -a USERS=(
  "1|Zübeyde|Altun|zubeyde.altun@doka.org.tr"
  "2|Elifnaz|Akdeniz|elifnaz.akdeniz@doka.org.tr"
  "3|Mehmet|Sezgin|mehmet.sezgin@doka.org.tr"
  "4|Oğuzhan|Şatır|oguzhan.satir@doka.org.tr"
  "5|Esen|Baylan|esen.baylan@doka.org.tr"
  "6|Nuray|Efendioğlu|nuray.efendioglu@doka.org.tr"
  "7|Fatih|Özdemir|fatih.ozdemir@doka.org.tr"
)

UPDATE_SQL=""
ERRORS=0

log "7 Auth kullanıcısı oluşturuluyor... (başlangıç şifresi: $DEFAULT_PASS)"
echo ""

for user_line in "${USERS[@]}"; do
  IFS='|' read -r pkod ad soyad email <<< "$user_line"

  RESPONSE=$(curl -s -X POST "$AUTH_URL" \
    -H "Authorization: Bearer $SERVICE_JWT" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$email\",\"password\":\"$DEFAULT_PASS\",\"email_confirm\":true}")

  UUID=$(echo "$RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | sed 's/"id":"//;s/"//')

  if [ -z "$UUID" ]; then
    MSG=$(echo "$RESPONSE" | grep -o '"message":"[^"]*"' | head -1 | sed 's/"message":"//;s/"//')
    warn "[$pkod] $email → HATA: $MSG"
    UPDATE_SQL+="-- [$pkod] $ad $soyad — oluşturulamadı: $MSG\n"
    ERRORS=$((ERRORS + 1))
  else
    ok "[$pkod] $ad $soyad → $UUID"
    UPDATE_SQL+="UPDATE personel SET auth_id = '$UUID' WHERE pkod = $pkod;  -- $ad $soyad\n"
  fi
done

echo ""
echo "================================================================"
echo "  Supabase SQL Editor'de çalıştırılacak UPDATE SQL:"
echo "================================================================"
echo ""
echo -e "$UPDATE_SQL"
echo "-- Doğrulama:"
echo "SELECT pkod, ad, soyad, auth_id, rol_kodu FROM personel ORDER BY pkod;"
echo ""
echo "================================================================"

if [ "$ERRORS" -gt 0 ]; then
  warn "$ERRORS kullanıcı oluşturulamadı. -- ile başlayan satırları atla."
else
  ok "Tüm kullanıcılar başarıyla oluşturuldu!"
fi

log "Supabase Dashboard → SQL Editor → yukarıdaki SQL'i yapıştır ve çalıştır"
