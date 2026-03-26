Agent: reviewer
Görev: Backend (SQL) kod incelemesi
Durum: TAMAMLANDI
Sonraki adım: SQL ajanı 003_rls.sql ve 001_schema.sql dosyalarını düzelttikten sonra QA devam edebilir
---

### Genel Değerlendirme

SQL dosyaları büyük ölçüde spec ile uyumludur. 4 view'ın formülleri (GKİ, Hepiniss) doğrulanmış ve doğru çalışmaktadır. Seed verisi FK sırasına uygun, Türkçe karakterler sağlam. Ancak 3 YÜKSEK öncelikli sorun QA'yi bloke etmektedir: `bitis_donem` üzerinde FK kısıtı eksik, `anahtar_sonuclar` için UPDATE/DELETE RLS politikaları tanımlanmamış ve `sprint_is_plani` güncellemesi için yetki kontrolü spec'den (isim bazlı) farklı (rol bazlı) uygulanmış.

---

### Sorunlar

```
[ÖNCELİK: YÜKSEK] src/sql/001_schema.sql:182 — bitis_donem INTEGER tanımlı ama REFERENCES sprint_veri(sprint_donem) kısıtı yok
Öneri: REFERENCES sprint_veri(sprint_donem) ekle; böylece sprint_veri satırı silindiğinde orphan kayıt oluşması önlenir
```

```
[ÖNCELİK: YÜKSEK] src/sql/003_rls.sql:207-218 — anahtar_sonuclar tablosunda UPDATE ve DELETE politikaları tanımsız
Öneri: Aşağıdaki iki politikayı ekle:
  CREATE POLICY "anahtar_sonuclar_update_yonetici" ON anahtar_sonuclar FOR UPDATE
      TO authenticated USING ((SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici');
  CREATE POLICY "anahtar_sonuclar_delete_yonetici" ON anahtar_sonuclar FOR DELETE
      TO authenticated USING ((SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici');
RLS default-deny kuralı gereği bu politikalar olmadan yönetici bile anahtar sonuç düzenleyip silemez.
```

```
[ÖNCELİK: YÜKSEK] src/sql/003_rls.sql:289-290 — sprint_is_plani UPDATE politikası "Fatih" adını değil rol_kodu='yönetici' kontrolü yapıyor
Spec (output/spec.md:209): "ekip_uyesi = personel.ad VEYA personel adı 'Fatih'" (isim bazlı)
Mevcut kod: "ekip_uyesi = personel.ad OR rol_kodu = 'yönetici'" (rol bazlı)
Öneri: Seçenekler —
  (a) Spec'e sadık: WHERE auth.uid() = personel.auth_id AND personel.ad = 'Fatih' şeklinde sabit isim kontrolü (kırılgan),
  (b) Daha sağlıklı: rol_kodu='yönetici' kontrolünü koruyarak spec'i güncelleyin.
Şu an seed'de yalnızca Fatih yönetici olduğundan pratik sorun yok, ancak mimari belirsiz.
```

```
[ÖNCELİK: ORTA] src/sql/001_schema.sql:194-195 — guncel_tarih ve guncelleyen sütunları NULL'a izin veriyor
Öneri: İlk INSERT'te audit alanlarının boş kalmaması için DEFAULT NOW()::DATE (guncel_tarih) ve DEFAULT '' (guncelleyen) ekle ya da trigger'ı BEFORE INSERT OR UPDATE olarak genişlet.
```

```
[ÖNCELİK: ORTA] src/sql/003_rls.sql:32-111, 160-185 — Pek çok politikada COMMENT ON POLICY eksik
Öneri: Bakım kolaylığı için tüm politikalara COMMENT ON POLICY ekle (örnek: satır 273, 282'deki gibi).
```

```
[ÖNCELİK: DÜŞÜK] src/sql/seed.sql:619-885 — anahtar_sonuclar kayıt sayısı spec'teki 91'e ulaşıp ulaşmadığı belirsiz (tahmin ~91, doğrulama gerekli)
Öneri: SELECT COUNT(*) FROM anahtar_sonuclar; ile deploy sonrası doğrula.
```

---

### Kontrol listesi

- [ ] TypeScript hataları — N/A (SQL dosyaları)
- [x] Güvenlik: JWT işleme Supabase RLS'e devredilmiş; SQL injection riski yok (parametre bağlama kullanılıyor)
- [x] Yapısal ihlaller: Görünüm formülleri (GKİ, Hepiniss) spec ile birebir uyumlu
- [ ] Eksik hata işleme: anahtar_sonuclar UPDATE/DELETE politikaları eksik (YÜKSEK)
- [ ] Spec uyumsuzluğu: bitis_donem FK kısıtı eksik; anahtar_sonuclar RLS eksik; sprint_is_plani UPDATE yetki mantığı farklı
- [x] .env.example: Mevcut
- [x] Güvensiz sırlar: Seed dosyasında hardcoded credential yok
- [x] GKİ doğrulaması: Sprint 1 ~98.5%, Sprint 2 ~86.8% — spec ile birebir ✓
- [x] View'lar: v_sprint_ozet, v_alt_faaliyet_ozet, v_faaliyet_ozet, v_perf_gosterge_ozet — 4/4 mevcut ✓
- [x] Trigger'lar: trg_sprint_is_plani_audit, trg_harcamalar_audit — 2/2 mevcut ✓
- [x] Seed FK sırası: birimler→soplar→kategoriler→kullanici_rolleri→personel→... doğru ✓
- [x] Türkçe karakterler: UTF-8 sağlam ✓

---

### Spec Uyum Özeti

| Gereksinim | Beklenen | Mevcut | Durum |
|---|---|---|---|
| Tablo sayısı | 14+ | 16 | ✓ (sprint_retro dahil) |
| View sayısı | 4 | 4 | ✓ |
| RLS politikaları | Tüm tablolar | 14 tabloda; anahtar_sonuclar eksik | ⚠ |
| Audit trigger | 2 tablo | 2 tablo | ✓ |
| GKİ formülü | t_skor/(sure_gun×ekip-izin)×100 | Aynı | ✓ |
| Hepiniss formülü | AVG(SQRT(rol×memnuniyet)) | Aynı | ✓ |
| bitis_donem FK | Referential integrity | Eksik | ✗ |
| Seed kayıt sayıları | Spec ile aynı | Uyumlu (doğrulama gerekli) | ⚠ |

---

### Sonuç

**DÜZELTİLMELİ** — 3 YÜKSEK öncelikli sorun var; SQL ajanı `003_rls.sql` ve `001_schema.sql` dosyalarını düzelttikten sonra QA devam edebilir.
