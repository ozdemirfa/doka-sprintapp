Agent: reviewer
Görev: Frontend revizyon incelemesi (Migration 008/009 ile gelen tüm HTML/JS değişiklikleri)
Durum: TAMAMLANDI
Sonraki adım: QA ajanı sayfa bazlı E2E testleri çalıştırmalı
---

## Genel Değerlendirme

Bu revizyonda yedi sayfada hideAyarlarForNonAdmin entegrasyonu yapılmış, sprint-perf-gos.html'e ÇG Kodu arama modalı eklenmiş, harcamalar.html çoklu ödeme satırı destekli yeni forma taşınmış, ayarlar.html'e Yıllık Bütçeler ve Birimler sekmeleri eklenmiş, retro.html'de org_puan → organizasyon_puan düzeltmesi yapılmış ve faaliyetler.html'den butce_2026 kolonu kaldırılmıştır. Genel kod kalitesi yüksektir; fonksiyonlar odaklı ve okunabilirdir.

---

## Sorunlar

### utils.js — hideAyarlarForNonAdmin

[ÖNCELİK: ORTA] utils.js:158-163 — Fonksiyon yalnızca `a[href*="ayarlar.html"]` CSS seçicisi ile eşleştirme yapar. Sayfa ayarlar.html'in kendisiyse (yani `window.location.href` zaten ayarlar.html ise) bu seçici yine çalışır ve menü linki gizlenir, ancak sayfa içeriği korunamaz. Oysa ayarlar.html'nin kendi JS'inde (satır 271-273) rol kontrolü yapılmaktadır; bu kısım uygundur. Bununla birlikte, hideAyarlarForNonAdmin sadece navigasyon linkini gizler, ayarlar.html URL'ine direkt erişimi engellemez.
Öneri: Mevcut davranış kabul edilebilir (ayarlar.html kendi rol kontrolünü yapar), ancak fonksiyon JSDoc açıklaması bu kısıtı belgelemelidir.

### utils.js — calcGort / calcAort isim uyumsuzluğu

[ÖNCELİK: DÜŞÜK] utils.js:50-54 — Fonksiyon adı hâlâ calcGort; calcAort, calcGort için alias olarak ihraç edilmiştir. retro.html satır 142'de calcGort import ediliyor, bu tutarlıdır. Ancak yorum satırı "aort adıyla geriye dönük uyumlu" diyor — aslında tam tersi: calcGort ismi korunmuş, calcAort alias. Bu, 007/009'dan gelen aort yeniden adlandırmasıyla ilgili kafa karışıklığı yaratabilir.
Öneri: İleride calcAort birincil fonksiyon adı olmalı; geriye dönük uyumluluk için calcGort alias tutulabilir.

### hideAyarlarForNonAdmin — 7 sayfa kontrol listesi

| Sayfa | Durum |
|-------|-------|
| kanban.js (index.html) | TAMAM — satır 26 |
| sprint-ozet.html | TAMAM — satır 155 |
| faaliyetler.html | TAMAM — satır 133 |
| retro.html | TAMAM — satır 149 |
| performans.html | TAMAM — satır 120 |
| sprint-perf-gos.html | TAMAM — satır 169 |
| harcamalar.html | TAMAM — satır 170 |
| izinler.html | TAMAM — satır 339 |

Tüm 7 hedef sayfa + kanban.js dahil toplam 8 konumda çağrı mevcut. TAMAM.

### sprint-perf-gos.html — ÇG Kodu Arama Modalı

[ÖNCELİK: YÜKSEK] sprint-perf-gos.html:379 — `row.dataset.cgKod` kullanılıyor, ancak HTML'de ilgili attribute `data-cg-kod` olarak tanımlanmış (satır 345). JavaScript'in dataset özelliği, kebab-case'i camelCase'e dönüştürür (`data-cg-kod` → `dataset.cgKod`). Bu doğrudur ve çalışır. Ancak dataset özelliği tarayıcıya göre farklılık gösterebileceğinden `row.getAttribute('data-cg-kod')` daha savunmacı bir yaklaşım olurdu.
Öneri: Mevcut haliyle çalışır, ancak getAttribute ile yazılması taşınabilirliği artırır. Düşük risk.

[ÖNCELİK: DÜŞÜK] sprint-perf-gos.html — CG kodu arama modalında `btn-cg-ara` tıklandığında `cg-filter-metin` ve `cg-filter-sop` sıfırlanıyor ve `renderCgList()` çağrılıyor. Bu, modalın her açılışta tüm listeyi göstermesini sağlar — davranış doğrudur ve bilinçli seçim gibi görünüyor.

[ÖNCELİK: DÜŞÜK] sprint-perf-gos.html — URL parametrelerinden gelen `faaliyet` ve `sno` değerleri (kanban.js satır 402-403 ile üretilmiş) `sprint-perf-gos.html`'de herhangi bir yerde okunmamaktadır. Bu parametreler modal açılışında otomatik doldurmaya niyetlenilmiş olabilir.
Öneri: URL parametreleri kullanılmıyorsa kanban.js'deki `perfBtn.href` oluşturma mantığından kaldırılmalı ya da sayfa yüklendiğinde okunup forma uygulanmalıdır.

### harcamalar.html — Çoklu Ödeme Satırları

[ÖNCELİK: ORTA] harcamalar.html:235 — totalIsPlani = 0 olarak sabit tanımlanmış. "İş Planı Toplam Bütçe" metrik kartı her zaman 0 göstermektedir. Bu bilinçli bir yer tutucu (placeholder) olabilir (faaliyet_yil_butce entegrasyonu henüz bitmemiş olabilir), ancak kullanıcıya yanlış bilgi sunmaktadır.
Öneri: 0 gösteriliyorsa metrik kartı gizlenmeli ya da "Yakında" etiketi koyulmalı; ya da faaliyet_yil_butce'den toplam bütçe çekilmelidir.

[ÖNCELİK: DÜŞÜK] harcamalar.html:409 — `odeme-donem` placeholder olarak "Dönem (ör: 2026/1)" yazıyor. Ancak harcamalar tablosundaki `odeme_donem` kolonu VARCHAR(20) ve örnekleri "2026.Oca" formatında (001_schema.sql satır 251). Placeholder ile gerçek format uyumsuz.
Öneri: Placeholder "ör: 2026.Oca" olarak güncellenmeli.

[ÖNCELİK: DÜŞÜK] harcamalar.html — initOdemeSatirlari() satır 416-419: Container `odeme-satirlari` henüz DOM'a eklenmeden çağrılırsa (modal açılmadan sayfa yüklendiğinde) sorun olmaz çünkü zaten modal içinde. `btn-yeni-harcama` tıklandığında çağrıldığı için güvenli.

### ayarlar.html — Yıllık Bütçeler (tab-yil-butce)

[ÖNCELİK: DÜŞÜK] ayarlar.html:589-606 — "Güncelle" butonu tıklandığında form alanları doldurulur ancak kullanıcı "Sil" sonrası tekrar eklemek isterse form temizlenmez (loadYilButce() çağrılır, bu tbody'yi yeniden oluşturur; event listener'lar kaybedilir). Ancak event delegation yerine doğrudan querySelectorAll ile listener ekleniyor; loadYilButce() her çağrıldığında satır 600'deki querySelectorAll yeniden çalışır ve yeni DOM'a bağlanır. Bu çalışır, ama potansiyel olarak çok sayıda event listener birikimi oluşturabilir.
Öneri: Silme/güncelleme işlemleri için event delegation kullanılmalıdır; `.page-body` üzerindeki delegasyon zaten row-del ve row-edit için kurulmuştur, yb-guncelle de oraya taşınabilir.

[ÖNCELİK: DÜŞÜK] ayarlar.html:613 — `if (!faaliyetId || !yil || isNaN(butce) || butce < 0)` kontrolü butce = 0 girişine izin verir. 0 bütçe mantıklı bir değer olabilir, ancak "0 bütçe eklenmeli mi?" sorusu net değil.
Öneri: İş kuralı netleştirilebilir; mevcut hali kabul edilebilir.

### ayarlar.html — Birimler (tab-birimler)

[ÖNCELİK: ORTA] ayarlar.html — Birimler silme işleminde (satır 656-658) `data-table="birim"` kullanılıyor, ancak HTML'deki satır 801'de yine `data-table="birim"` yazılmış. Bu tutarlıdır ve silme doğru çalışır.

[ÖNCELİK: DÜŞÜK] ayarlar.html:811 — birim_kisa için uzunluk/format validasyonu yok; bir karakter bile kabul edilir. 001_schema.sql'de birim_kisa VARCHAR(10) ve UNIQUE tanımlı; DB'de kısıt var, ancak frontend'de bilgilendirici bir validasyon hata mesajı yok.
Öneri: Birim kısa adı için minimum 2, maksimum 10 karakter validasyonu ve toUpperCase() uygulanabilir (satır 809'da toUpperCase() zaten var, bu iyi).

### faaliyetler.html — butce_2026 kaldırıldı

[ÖNCELİK: DÜŞÜK] faaliyetler.html — Faaliyet modalından butce_2026 input alanı kaldırılmıştır. Mevcut kodda faaliyet ekleme/güncelleme payload'ında butce_2026 gönderilmemektedir. Ancak v_faaliyet_ozet view'ı hâlâ butce_2026'yı SELECT etmektedir (008 SQL'de de tespit edildi). Frontend'de bu view okunuyorsa (faaliyetler.html'de doğrudan okunmuyor; tablo üzerinden veri alınıyor), uyumsuzluk yok.
Öneri: Tamamdır, ancak v_faaliyet_ozet'in butce_2026'yı ne zaman kaldıracağı netleştirilmeli.

### retro.html — org_puan → organizasyon_puan düzeltmesi

[ÖNCELİK: DÜŞÜK] retro.html:230 — `r.organizasyon_puan` doğru kolonu referans alıyor. 007 migration'ında `org_puan` kolonu kaldırılmış ve yalnızca `organizasyon_puan` kalmıştır. Fix doğrudur.

Form submit'te (satır 264-270) insert payload'u: `{ sprint_donem, pkod, organizasyon_puan, ajanstaki_rolu, ajans_hakkinda }`. aort sütunu gönderilmemektedir; bu kasıtlıdır çünkü `fn_update_aort()` trigger'ı BEFORE INSERT tetiklenerek aort'u otomatik hesaplar. Doğru yaklaşım.

[ÖNCELİK: DÜŞÜK] retro.html:225 — `r.aort ?? calcGort(...)` ifadesi, aort NULL ise JS'de hesaplama yapar. 009 backfill'i çalıştıktan sonra tüm kayıtlarda aort dolu olacağından bu fallback gereksiz kalacak; ancak zarar vermez ve güvenli bir koruma katmanıdır.

### performans.html — kumulatif_hedef hesabı

[ÖNCELİK: ORTA] performans.html:203 — `kumHedef = (r.hedef_2024 || 0) + (r.hedef_2025 || 0) + (r.hedef_2026 || 0)` hesabı frontend'de yapılmaktadır. Tablo sütunu başlığı "Kümülatif Hedef" doğrudur. Ancak v_perf_gosterge_ozet view'ında (007) `kumulatif_gerceklesme` kolonu üretilmiş fakat "kumulatif_hedef" kolonu view'da yoktur. Hedef toplamı frontend'de hesaplanıyor — bu tutarlıdır, ancak view'a eklenseydi daha temiz olurdu.
Öneri: Mevcut haliyle çalışır. İleride v_perf_gosterge_ozet'e kumulatif_hedef kolonu eklenebilir.

[ÖNCELİK: DÜŞÜK] performans.html:139 — `perfData = ... .map(r => ({ ...r, sop: r.soplar?.kisa ?? null }))` yapılıyor, ancak v_perf_gosterge_ozet view'ı `soplar` join'i içermemektedir (007'deki view SELECT'inde soplar inner join yok). Sonuç olarak `r.soplar` her zaman undefined/null olur ve `r.sop` null kalır. Bu, SOP filtresi çalışmayacağı anlamına gelir.
Öneri: v_perf_gosterge_ozet view'ına soplar join'i eklenmeli ya da performans.html ayrı bir soplar sorgusu yapmalıdır. Mevcut durumda SOP filtresi hiçbir zaman veri döndürmez.

### izinler.html — hideAyarlarForNonAdmin

[ÖNCELİK: DÜŞÜK] izinler.html — hideAyarlarForNonAdmin eklenmesi doğru ve yerinde. Diğer sayfalarda `if (personel) hideAyarlarForNonAdmin(personel)` kalıbı kullanılırken izinler.html'de de aynı kalıp uygulanmış. Tutarlıdır.

### sprint-ozet.html

[ÖNCELİK: DÜŞÜK] sprint-ozet.html — hideAyarlarForNonAdmin doğru entegre edilmiş (satır 155).

---

## Spec Uyum Özeti

| Kontrol | Durum |
|---------|-------|
| hideAyarlarForNonAdmin — kanban.js | TAMAM |
| hideAyarlarForNonAdmin — sprint-ozet.html | TAMAM |
| hideAyarlarForNonAdmin — faaliyetler.html | TAMAM |
| hideAyarlarForNonAdmin — retro.html | TAMAM |
| hideAyarlarForNonAdmin — performans.html | TAMAM |
| hideAyarlarForNonAdmin — sprint-perf-gos.html | TAMAM |
| hideAyarlarForNonAdmin — harcamalar.html | TAMAM |
| hideAyarlarForNonAdmin — izinler.html | TAMAM |
| ÇG Kodu modal — btn-cg-ara handler | TAMAM |
| ÇG Kodu modal — cg-modal-kapat handler | TAMAM |
| ÇG Kodu modal — cg-filter-sop handler | TAMAM |
| ÇG Kodu modal — cg-filter-metin handler | TAMAM |
| ÇG Kodu modal — cg-list-tbody click handler | TAMAM |
| retro.html org_puan → organizasyon_puan fix | TAMAM |
| harcamalar.html initOdemeSatirlari | TAMAM |
| ayarlar.html loadYilButce / btn-yb-ekle / silme | TAMAM |
| ayarlar.html loadBirimler / btn-bir-ekle / silme | TAMAM |
| performans.html SOP+yıl filtresi | KISMI — SOP filtresi view'dan sop verisi gelmiyor |
| performans.html kumulatif_hedef hesabı | TAMAM — frontend'de hesaplanıyor |
| faaliyetler.html butce_2026 kaldırıldı | TAMAM |
| URL parametreleri sprint-perf-gos.html'de okunmuyor | EKSIK |
| harcamalar.html totalIsPlani = 0 hardcoded | UYARI |

---

## Sonuç

DÜZELTİLMELİ (minor)

Tüm kontrol listesi maddelerinin büyük çoğunluğu doğru uygulanmıştır. Üretime geçmeden önce iki konu ele alınmalıdır: (1) performans.html'de SOP filtresi çalışmıyor — v_perf_gosterge_ozet soplar join'i içermediğinden `r.soplar?.kisa` her zaman null dönüyor; (2) harcamalar.html'de totalIsPlani = 0 hardcoded ve "İş Planı Toplam Bütçe" metrik kartı yanlış bilgi gösteriyor. Bunların dışındaki tüm değişiklikler doğru ve tutarlı biçimde uygulanmıştır.
