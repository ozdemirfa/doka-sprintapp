Agent: reviewer
Görev: SQL Migration 008 + 009 incelemesi
Durum: TAMAMLANDI
Sonraki adım: QA ajanı doğrulama sorgularını çalıştırmalı
---

## Genel Değerlendirme

Migration 008, üç odaklı değişiklik içermektedir: (1) butce_2026 tekil kolonunu normalize eden faaliyet_yil_butce yeni tablosu, (2) sprint_perf_gos değişikliklerinde performans_gostergeler sütununu otomatik güncelleyen iki trigger, (3) is_durum_oran ve gki için ROUND(..., 2) eklenerek güncellenen view'lar. Migration 009 ise 007'de tanımlanan aort trigger'ının mevcut (pre-trigger) kayıtları için eksik kalan backfill'i tamamlamaktadır.

---

## Sorunlar

### 008_revisions2.sql

[ÖNCELİK: ORTA] 008:117 — fn_sync_performans_gostergeler() SECURITY DEFINER tanımlandı, ancak fonksiyon yalnızca sprint_is_plani tablosunu günceller; bu tablo zaten authenticated kullanıcılar tarafından erişilebilir. SECURITY DEFINER gereksiz yetki genişlemesi riski taşır; SECURITY INVOKER ile aynı sonuç elde edilir.
Öneri: Fonksiyon yalnızca UPDATE işlemi yaptığından SECURITY DEFINER kaldırılabilir ya da sebebi bir yorum satırı ile açıklanmalıdır.

[ÖNCELİK: ORTA] 008:144 — fn_set_tamamlanma_donemi() SECURITY DEFINER olmadan tanımlandı. Bu tutarlılık açısından fn_sync_performans_gostergeler() ile ters düşmektedir; iki trigger fonksiyonu arasındaki SECURITY DEFINER farkı kasıtlıysa belgelenmelidir.
Öneri: Her iki fonksiyon için de tutarlı bir SECURITY seçimi yapılmalı ve yorum eklenmeli.

[ÖNCELİK: ORTA] 008:196-199 — v_faaliyet_ozet view'ı hâlâ butce_2026 kolonunu referans alıyor. Bu migration'ın amacı yıllık bütçeyi normalize etmektir; ancak bu view faaliyet_yil_butce tablosundan veri çekmemektedir. View, yeni tabloyu görmediğinden eski single-column mantığını sürdürmektedir.
Öneri: View ya faaliyet_yil_butce'yi JOIN ile dahil etmeli, ya da migration notunda "butce_2026 henüz kaldırılmıyor" niyeti açıkça belirtilmeli (belirtilmiş durumda: satır 68, takdir edilir, ama view da uyarı almalı).

[ÖNCELİK: DÜŞÜK] 008:171 — v_alt_faaliyet_ozet'te harcamalar join'i LEFT JOIN harcamalar h ON h.sprint_is_plani_id = si.id şeklinde yapılmıştır. Aynı sprint_is_plani_id'ye bağlı birden fazla harcama satırı varsa SUM(h.odenecek_kdvli) çarpılmış (multiplied) gerceklesme_sayi üretecektir. Bu 007'den devralınan davranış olup 008'de değişmedi; ancak bilinçli kabul görmüşse yorum ile belgelenmelidir.
Öneri: Hesaplama mantığını doğrulamak için QA'nın çoklu harcama satırı olan bir sprint_is_plani örneği ile test etmesi gerekir.

[ÖNCELİK: DÜŞÜK] 008:37 — faaliyet_yil_butce için INSERT politikasında WITH CHECK kullanılmış (doğru), ancak UPDATE politikasında satır 54'te yalnızca USING var, WITH CHECK eksik. USING mevcut satırları filtreler; yeni değerler için WITH CHECK de gereklidir.
Öneri: UPDATE politikasına da WITH CHECK (...) = 'yönetici' koşulu eklenmeli.

[ÖNCELİK: DÜŞÜK] 008:13-15 — BÖLÜM 0'da v_perf_gosterge_ozet ve v_faaliyet_harcama view'ları DROP edilmedi. Bu view'lar 007'de oluşturuldu. Eğer bu migration sırasında söz konusu view'ları kullanan başka bağımlılıklar devreye girmiş ise sorun çıkmayabilir; ancak tutarlılık için açıkça "bu view'lar bu migration'da değişmez" notu eklenebilir.
Öneri: BÖLÜM 0'a bir yorum satırı eklenerek hangi view'ların doğrudan etkilenmediği belgelenebilir.

### 009_fixes.sql

[ÖNCELİK: YÜKSEK] 009:8-12 — aort backfill formülü (ajanstaki_rolu + ajans_hakkinda) / 2.0. Bu, 007'deki trg_sprint_retro_aort trigger fonksiyonu fn_update_aort() ile birebir tutarlıdır. Ancak 007 migration'ı zaten aynı formülle tüm satırlar için bir UPDATE çalıştırdı (satır 298-300). 009'daki koşul WHERE aort IS NULL şeklinde yazıldığından çakışma olmaz; yine de 007 sonrası eklenen fakat trigger'ın işlemediği satırlar hedeflenmiştir. Bu durum neden oluştu diye bakıldığında: 007'deki UPDATE koşulsuzken, 009 WHERE aort IS NULL koyuyor. Bu, yalnızca 007 sonrasında girilen ve trigger çalışmadan kalan kayıtları hedefler. Formül doğrudur.
Öneri: Sorun yok; ancak bu backfill'e neden gerek duyulduğu (örn. 007 trigger'ı tetiklemeden eklenen veriler) migrasyonun başına kısa bir yorum olarak eklenirse anlamlı olur.

---

## Spec Uyum Özeti

| Konu | Durum |
|------|-------|
| faaliyet_yil_butce tablosu oluşturuldu | TAMAM |
| RLS: SELECT tüm authenticated | TAMAM |
| RLS: INSERT/DELETE yönetici | TAMAM |
| RLS: UPDATE WITH CHECK eksik | EKSIK |
| Seed: butce_2026 → faaliyet_yil_butce | TAMAM |
| fn_sync_performans_gostergeler trigger | TAMAM |
| fn_set_tamamlanma_donemi trigger | TAMAM |
| v_alt_faaliyet_ozet ROUND eklendi | TAMAM |
| v_sprint_ozet gki ROUND eklendi | TAMAM |
| v_faaliyet_ozet butce_2026 referansı eski | UYARI |
| aort backfill (009) formül doğru | TAMAM |
| Geri alınamaz işlem uyarısı verilmiş | TAMAM |

---

## Sonuç

DÜZELTİLMELİ (minor)

Kritik bir hata bulunmamaktadır. Migration güvenle çalışabilir. Ancak iki işlem üretime geçmeden ele alınmalıdır: (1) faaliyet_yil_butce UPDATE politikasına WITH CHECK eklenmeli; (2) fn_sync_performans_gostergeler() için SECURITY DEFINER kararı belgelenmelidir. v_faaliyet_ozet'in butce_2026 bağımlılığı, faaliyet_yil_butce'ye geçişin tamamlandığı ileri bir migration'a bırakıldıysa kabul edilebilir — bu niyetin koda yorum olarak eklenmesi yeterlidir.
