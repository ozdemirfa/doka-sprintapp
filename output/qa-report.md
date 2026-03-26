Agent: qa-engineer
Görev: E2E test çalıştırma ve hata giderme
Durum: TAMAMLANDI
Sonraki adım: Tüm testler geçti — commit ve deploy hazır
---

## Test Sonuçları

**42/42 test geçti**
Tarayıcı: Chromium
Süre: ~1 dakika

| Dosya | US | Test Sayısı | Durum |
|---|---|---|---|
| `tests/e2e/login.spec.js` | US-5 | 4 | Geçti |
| `tests/e2e/kanban.spec.js` | US-1, US-2, US-3 | 12 | Geçti |
| `tests/e2e/sprint-ozet.spec.js` | US-4 | 7 | Geçti |
| `tests/e2e/subpages.spec.js` | US-6–US-10 | 19 | Geçti |

---

## Düzeltilen Hatalar

### 1. `src/js/kanban.js` — Tanımsız `personel` değişkeni (US-3, 4 test)
- **Sorun:** `openNewModal()` ve `openEditModal()` fonksiyonları `personel` değişkenini kullanıyordu ancak modül kapsamındaki değişken `currentPersonel` adında.
- **Düzeltme:** `personel` → `currentPersonel` (satır 359, 377-378)
- **Ek:** `openEditModal` içindeki `personel.ad === 'Fatih'` isim kontrolü `currentPersonel?.rol_kodu === 'yönetici'` rol kontrolüyle değiştirildi (reviewer önerisiyle uyumlu)

### 2. `src/js/utils.js` — `.single()` mock uyumsuzluğu (US-10, 1 test)
- **Sorun:** `getPersonel` `.single()` kullanıyordu; Supabase JS mock array yanıtını unwrap etmeyip `data = [{...}]` (dizi) dönüyordu. Bu yüzden `personel.ad` ve `personel.rol_kodu` `undefined` kalıyordu → `isFatih = false` → sil butonu görünmüyordu.
- **Düzeltme:** `.single()` → `.limit(1)` + `return data?.[0] ?? null`
- **Prodüksiyon etkisi:** Davranış aynı (auth_id unique olduğundan tek satır döner)

### 3. `tests/e2e/login.spec.js` — URL assertion (US-5, 1 test)
- **Sorun:** Test `page.url().toContain('login.html')` ile kontrol ediyordu; `serve` sunucusu `.html` uzantısını kaldırarak `/login` URL'si döndürüyordu.
- **Düzeltme:** `toContain('login.html')` → `toMatch(/\/login(\.html?)?$/)`

---

## Kabul Kriteri Durumu

| US | Kriter | Durum |
|---|---|---|
| US-1 | Kanban 4 sütun, drag-drop, kart yerleşimi | Geçti |
| US-2 | Sprint ve ekip üyesi filtreleme | Geçti |
| US-3 | Yeni görev / düzenleme modal | Geçti |
| US-4 | Sprint özet, Chart.js grafikleri | Geçti |
| US-5 | Login / logout / session guard | Geçti |
| US-6 | Faaliyetler sayfası | Geçti |
| US-7 | Retrospektif sliderlar | Geçti |
| US-8 | Performans sayfası | Geçti |
| US-9 | Harcamalar tablosu ve filtre | Geçti |
| US-10 | İzinler/saha form, yönetici sil yetkisi | Geçti |
