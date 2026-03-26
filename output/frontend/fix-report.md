Agent: frontend-agent
Görev: Reviewer bulgularına göre frontend düzeltmeleri
Durum: TAMAMLANDI
Sonraki adım: QA ajanı E2E testleri yazabilir
---

## Yapılan Düzeltmeler

### YÜKSEK Öncelik

1. **src/pages/sprint-ozet.html** — Chart.js CDN import eklendi
   - `<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>` head'e eklendi
   - Etki: renderGkiTrend, renderHepinissTrend vb. artık çalışma zamanı hatası vermez

2. **src/js/utils.js** — getPersonel'e `rol_kodu` eklendi
   - `.select('ad, soyad, bkod, rol_kodu')` olarak güncellendi
   - Etki: Tüm sayfalarda personel.rol_kodu kullanılabilir

3. **src/js/kanban.js** — Audit sütunları + try-catch
   - `let currentPersonel = null` state'e eklendi
   - Init bloğu try-catch ile sarıldı; hata olursa kullanıcıya mesaj gösterilir
   - handleDragEnd'de `guncel_tarih` ve `guncelleyen` update payload'a eklendi
   - handleSave'de UPDATE sırasında `guncel_tarih` ve `guncelleyen` ayrı payload ile gönderiliyor

4. **src/pages/izinler.html** — İsim bazlı yetki kaldırıldı + otomatik güncelleme
   - `isFatih = personel?.ad === 'Fatih'` → `isFatih = personel?.rol_kodu === 'yönetici'`
   - İzin form submit sonrası: `if (sprintSelectIzin.value) await hesaplaSprintOzet()`
   - Saha form submit sonrası: `if (sprintSelectIzin.value) await hesaplaSprintOzet()`
   - Etki: sprint_veri.izin / saha artık form kaydetme anında otomatik güncelleniyor

### ORTA Öncelik

5. **src/pages/harcamalar.html** — Metrik kartlar + sprint bazlı iş planı filtresi
   - `updateMetrics(rows)` fonksiyonu ayrıştırıldı (async)
   - sprint_is_plani sorgusu aktif sprint filtresine göre filtreleniyor
   - `applyFilters()` çağrısında `updateMetrics(filtered)` de çağrılıyor
   - Etki: Filtre değiştiğinde metrik kartlar ve bütçe farkı doğru sprint'e göre hesaplanır

6. **src/pages/retro.html** — Form reset sonrası gösterge temizleme
   - Submit sonrası `e.target.reset()` ile form temizleniyor
   - Slider değer göstergeleri (org-val, rol-val, hakkinda-val) '5'e sıfırlanıyor
   - G.ort display varsayılan değerle güncelleniyor

### Kapsam Dışı Bırakılan

- **config.js hardcoded credentials**: Statik site yapısı nedeniyle tam çözüm deploy pipeline gerektirir. Bu bir tasarım kısıtıdır. Şu an için `.gitignore`'a eklenmesi önerilir.
