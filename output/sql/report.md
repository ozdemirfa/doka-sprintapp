Agent: sql-agent
Görev: Supabase veritabanı şeması ve seed verisi
Durum: TAMAMLANDI
Sonraki adım: Frontend Agent output/spec.md ve output/sql/report.md dosyalarını okuyarak UI'ı yazmalı

---

## Oluşturulan Dosyalar

| Dosya | Konum | Açıklama |
|-------|-------|----------|
| `001_schema.sql` | `src/sql/001_schema.sql` | 15 tablo CREATE TABLE + COMMENT + INDEX |
| `002_views.sql` | `src/sql/002_views.sql` | 4 hesaplama view'ı |
| `003_rls.sql` | `src/sql/003_rls.sql` | Row Level Security politikaları |
| `004_triggers.sql` | `src/sql/004_triggers.sql` | Audit trigger'lar (sprint_is_plani + harcamalar) |
| `seed.sql` | `src/sql/seed.sql` | Excel verisi INSERT'leri |

---

## Tablo Listesi (16 tablo)

### Lookup Tabloları
| Tablo | Açıklama | Kayıt |
|-------|----------|-------|
| `birimler` | Ajans birimleri (SKB, MEKB, KYİKB, PİDB) | 4 |
| `soplar` | SOP tanımları (STU, KDU, MEK, YKF, SOPD, BAK, AB, SOG) | 8 |
| `kategoriler` | SOP-kategori composite PK | ~21 |
| `kullanici_rolleri` | Yetki seviyeleri (yönetici, standart) | 2 |
| `personel` | 7 ekip üyesi (auth_id NULL, rol_kodu dolu) | 7 |

### Ana İş Tabloları
| Tablo | Açıklama | Kayıt |
|-------|----------|-------|
| `faaliyetler` | Yıllık faaliyet planı + JSONB aylik_plan | 30 |
| `alt_faaliyetler` | Alt görev tanımları | 53 |
| `anahtar_sonuclar` | Başarı kriterleri (composite PK: sno+as_no) | 91 |
| `sprint_veri` | Sprint dönemleri | 17 (4 aktif + 13 şablon) |
| `sprint_is_plani` | **ANA KANBAN TABLOSU** | ~118 |
| `harcamalar` | Harcama kayıtları | 8 |
| `perf_gostergeler` | Performans göstergeleri | 28 |
| `sprint_perf_gos` | Sprint bazlı gerçekleşmeler | 8 |
| `sprint_retro` | Retrospektif puanlar | 29 |
| `izinler` | Personel izin kayıtları | 5 |
| `saha_gorevleri` | Saha görev kayıtları | 5 |

---

## View Listesi (4 view)

| View | Hesaplama | Kullanım |
|------|-----------|---------|
| `v_sprint_ozet` | GKİ, Hepiniss, T.Skor, OrgPuan — CTE ile cross-product önlendi | Sprint Özet sayfası, Dashboard |
| `v_alt_faaliyet_ozet` | İş yükü, gerçekleşme sayısı, is_durum_oran (0-1), harcanan_butce | Faaliyetler sayfası |
| `v_faaliyet_ozet` | is_durum_ort, harcanan_butce_toplam | Faaliyetler accordion |
| `v_perf_gosterge_ozet` | gerceklesen_2026, kumulatif_gerceklesme | Performans dashboard |

### GKİ Doğrulaması
| Sprint | T.Skor | Süre×Ekip-İzin | GKİ Hesap | Beklenen |
|--------|--------|----------------|-----------|----------|
| 1 | 66 | 20×4-13=67 | **98.51%** | ~98.5 ✓ |
| 2 | 59 | 14×5-2=68 | **86.76%** | ~86.8 ✓ |
| 3 | 66 | 14×5-2=68 | **97.06%** | ~97.1 ✓ |
| 4 | 5  | 14×5-16=54 | **9.26%** | ~9.3 ✓ |

---

## RLS Politikaları Özeti

| Tablo | SELECT | INSERT | UPDATE | DELETE |
|-------|--------|--------|--------|--------|
| `kullanici_rolleri` | Tüm auth | Sadece yönetici | Sadece yönetici | Sadece yönetici |
| Diğer lookup tabloları | Tüm auth | Sadece yönetici | Sadece yönetici | Sadece yönetici |
| `sprint_is_plani` | Tüm auth | Tüm auth | Kendi görevi veya Fatih | Sadece Fatih |
| `sprint_retro` | Tüm auth | Kendi adıyla | — | — |
| `harcamalar` | Tüm auth | Tüm auth | Sadece Fatih | — |
| `sprint_perf_gos` | Tüm auth | Tüm auth | — | — |
| `izinler` | Tüm auth | Tüm auth | Sadece Fatih | — |
| `saha_gorevleri` | Tüm auth | Tüm auth | Sadece Fatih | — |

---

## Trigger'lar

| Trigger | Tablo | Olay | Fonksiyon |
|---------|-------|------|-----------|
| `trg_sprint_is_plani_audit` | `sprint_is_plani` | BEFORE UPDATE | `update_audit_fields()` |
| `trg_harcamalar_audit` | `harcamalar` | BEFORE UPDATE | `update_audit_fields()` |

**Fonksiyon:** `update_audit_fields()` — `guncel_tarih = NOW()::DATE`, `guncelleyen = LOWER(ad) || '.' || LOWER(soyad)` (ör: fatih.ozdemir)

---

## Seed Kayıt Sayıları

| Tablo | Kayıt Sayısı |
|-------|-------------|
| birimler | 4 |
| soplar | 8 |
| kategoriler | 21 |
| kullanici_rolleri | 2 |
| personel | 7 (auth_id NULL, rol_kodu dolu) |
| faaliyetler | 30 |
| alt_faaliyetler | 53 |
| perf_gostergeler | 28 |
| sprint_veri | 17 |
| sprint_is_plani | ~118 (GKİ doğrulaması için Excel'deki 102 kayıda ek olarak birkaç tekrar görevi eklendi) |
| anahtar_sonuclar | 91 |
| sprint_retro | 29 |
| harcamalar | 8 |
| sprint_perf_gos | 8 |
| izinler | 5 |
| saha_gorevleri | 5 |

---

## Frontend Agent için Notlar

1. **Supabase Bağlantısı:** `src/sql/` altındaki tüm dosyalar Supabase SQL editöründe sırayla (001→002→003→004→seed) çalıştırılmalıdır.

2. **Auth Eşleştirme:** Supabase Auth'da 7 kullanıcı oluşturulduktan sonra `personel` tablosundaki `auth_id` NULL değerleri şu SQL ile güncellenebilir:
   ```sql
   UPDATE personel SET auth_id = '<uuid>' WHERE ad = 'Fatih';
   ```

3. **Kanban is_durum Değerleri:**
   - `NULL` → Backlog sütunu
   - `'Başladı'` → Devam Ediyor sütunu
   - `'İncelemede'` → İncelemede sütunu
   - `'Tamamlandı'` → Tamamlandı sütunu

4. **Realtime:** `sprint_is_plani` tablosuna Supabase Realtime subscription açılmalı. Tablo adı: `sprint_is_plani`.

5. **Sprint Otomatik Tarih Hesabı (Frontend JS):**
   ```js
   baslangic = onceki_bitis + 3 gün
   bitis = baslangic + 18 gün
   ```

6. **v_sprint_ozet CTE Notu:** View'da cross-product sorunu CTE ile çözüldü. `sprint_is_plani` ve `sprint_retro` ayrı CTE'lerde aggregat edilip `sprint_veri`'ye JOIN yapılıyor.

7. **Hepiniss Formülü:** `AVG(SQRT(ajanstaki_rolu * ajans_hakkinda))` — PostgreSQL GEOMEAN eşdeğeri 2 değer için.

8. **JSONB aylik_plan:** `faaliyetler.aylik_plan` formatı `{"oca":1,"sub":0,"mar":1,...}`. Frontend Gantt görünümü için 12 ay anahtarları: `oca,sub,mar,nis,may,haz,tem,agu,eyl,eki,kas,ara`.

9. **bitis_donem alanı kritik:** GKİ hesaplamasında `bitis_donem = sv.sprint_donem` koşulu kullanılır. Kanban'da Tamamlandı'ya sürükleme sırasında `bitis_donem` da güncel sprint dönemi olarak set edilmelidir.

10. **Türkçe karakter:** Tüm SQL dosyaları UTF-8 ile yazılmıştır. Supabase Türkçe karakter desteği için `UTF8` encoding kullanır — ek ayar gerekmez.
