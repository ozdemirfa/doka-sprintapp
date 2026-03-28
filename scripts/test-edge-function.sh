#!/usr/bin/env bash
# ============================================================
# Test: admin-reset-password Edge Function
# Kullanım: ./scripts/test-edge-function.sh <email> <sifre> <hedef_pkod> <yeni_sifre>
# Örnek:    ./scripts/test-edge-function.sh fatih@tr90.gov.tr Doka2026! 2 YeniSifre123
# ============================================================
set -e

if [ "$#" -ne 4 ]; then
  echo "Kullanım: $0 <email> <sifre> <hedef_pkod> <yeni_sifre>"
  exit 1
fi

# .env dosyasından SUPABASE_URL ve SUPABASE_ANON_KEY yükle
ENV_FILE="$(dirname "$0")/../src/.env"
if [ -f "$ENV_FILE" ]; then
  export $(grep -v '^#' "$ENV_FILE" | xargs)
else
  echo "HATA: $ENV_FILE bulunamadı"
  exit 1
fi

EMAIL="$1"
SIFRE="$2"
PKOD="$3"
YENI_SIFRE="$4"

echo ""
echo "=== admin-reset-password Edge Function Testi ==="
echo "Proje: $SUPABASE_URL"
echo "Hedef pkod: $PKOD"
echo ""

echo "--- Adım 1: Giriş yapılıyor ($EMAIL) ---"
LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  "${SUPABASE_URL}/auth/v1/token?grant_type=password" \
  -H "apikey: ${SUPABASE_ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"${EMAIL}\",\"password\":\"${SIFRE}\"}")

HTTP_CODE=$(echo "$LOGIN_RESPONSE" | tail -1)
BODY=$(echo "$LOGIN_RESPONSE" | head -n -1)

if [ "$HTTP_CODE" != "200" ]; then
  echo "HATA: Giriş başarısız (HTTP $HTTP_CODE)"
  echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
  exit 1
fi

TOKEN=$(echo "$BODY" | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")
echo "Token alındı: ${TOKEN:0:50}..."
echo ""

echo "--- Adım 2: Edge Function çağrılıyor ---"
EF_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  "${SUPABASE_URL}/functions/v1/admin-reset-password" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "apikey: ${SUPABASE_ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"pkod\":${PKOD},\"new_password\":\"${YENI_SIFRE}\"}")

EF_HTTP=$(echo "$EF_RESPONSE" | tail -1)
EF_BODY=$(echo "$EF_RESPONSE" | head -n -1)

echo "HTTP Status: $EF_HTTP"
echo "Response:"
echo "$EF_BODY" | python3 -m json.tool 2>/dev/null || echo "$EF_BODY"
echo ""

if [ "$EF_HTTP" == "200" ]; then
  echo "✓ BAŞARILI — şifre sıfırlandı"
else
  echo "✗ HATA — HTTP $EF_HTTP"
  exit 1
fi
