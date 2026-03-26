Agent: reviewer
Görev: Son değişiklikler kod incelemesi (006_fixes.sql + 10 HTML/JS dosyası)
Durum: TAMAMLANDI
Sonraki adım: QA ajanı aşağıdaki KRİTİK maddeleri test etmeli; düzeltmeler yapıldıktan sonra tekrar review isteyin.
---

## Genel Değerlendirme

11 dosya incelendi. Genel kalite yeterli; ancak 3 kritik ve 5 orta öncelikli sorun tespit edildi. En önemli sorunlar şunlardır: `sprint_retro` tablosuna eklenen `org_puan` sütunu eski `organizasyon_puan` sütunuyla çakışıyor ve retro.html yanlış sütun adı gönderiyor; `performans.html` birden fazla var-olmayan sütun/view referansına sahip; `izinler.html`'de izin formu `tur` sütununu gönderiyor ancak schema bu sütun adını desteklemez.

---

## KRİTİK (düzeltilmesi şart)

---

### [ÖNCELİK: YÜKSEK] src/sql/006_fixes.sql:9 — `org_puan` sütunu ile mevcut `organizasyon_puan` sütunu çakışıyor

**Sorun:**
`001_schema.sql`'de `sprint_retro` tablosu `organizasyon_puan INTEGER CHECK (organizasyon_puan BETWEEN 1 AND 10)` sütununu tanımlıyor.
`006_fixes.sql` satır 9'da `ADD COLUMN IF NOT EXISTS org_puan INTEGER CHECK (org_puan BETWEEN 1 AND 10)` ekleniyor.
Bu iki sütun aynı veriyi tutar; `retro.html` ise `INSERT` sırasında `org_puan` kullanıyor (satır 252).
Ancak tablodaki mevcut veri `organizasyon_puan`'da; `v_sprint_ozet` view'ı `AVG(org_puan)` hesaplıyor — eski kayıtlar için bu değer NULL döner ve sprint özet metrikleri yanlış hesaplanır.

**Öneri:**
Ya `org_puan` sütununu kaldırıp `organizasyon_puan`'ı kullanın (retro.html INSERT ve view'ı da güncelleyin), ya da migration'a `UPDATE sprint_retro SET org_puan = organizasyon_puan WHERE org_puan IS NULL;` ekleyin ve `organizasyon_puan`'ı deprecated olarak işaretleyin.

---

### [ÖNCELİK: YÜKSEK] src/pages/performans.html:177–179, 379–388, 424 — Var olmayan view, sütun ve element referansları

**Sorun 1 — View:** `performans.html` satır 177'de `v_perf_gosterge_ozet` view'ından veri çekiyor. Bu view `002_views.sql`'de veya `006_fixes.sql`'de tanımlanmamış. Sayfa çalışırken Supabase'den hata alacak ve tablo boş görünecek.

**Sorun 2 — Sütun:** Satır 379'da `alt_faaliyetler` tablosundan `aciklama` sütunu seçiliyor: `.select('sno, aciklama')`. Ancak `001_schema.sql` incelendiğinde `alt_faaliyetler`'de `aciklama` sütunu yok; doğru sütun adı `alt_faaliyet`.

**Sorun 3 — Element:** Satır 391'de `document.getElementById('btn-gerceklesme-gir')` ile bir butona event listener ekleniyor. HTML'de bu ID'ye sahip bir element yok (sayfa başlığındaki buton `sprint-perf-gos.html`'e yönlendiren bir `<a>` etiketi, ID'si yok). `addEventListener` çağrısı `null` üzerinde yapılır ve `TypeError` fırlatır.

**Sorun 4 — Schema:** Satır 424'te `sprint_perf_gos` tablosuna `donem` sütunu insert ediliyor. `001_schema.sql` ve `006_fixes.sql`'de bu tabloda `donem` sütunu tanımlı değil; var olanlar `tamamlanma_donemi (VARCHAR)` ve `sprint_donem (INTEGER)`.

**Öneri:**
- `v_perf_gosterge_ozet` view'ını SQL migration olarak ekleyin veya `perf_gostergeler` tablosunu direkt sorgulayın.
- `alt_faaliyetler` sorgusundaki `aciklama` → `alt_faaliyet` olarak düzeltin.
- `btn-gerceklesme-gir` butonunu HTML'e ekleyin veya event listener'ı kaldırın.
- `donem` sütun referansını `tamamlanma_donemi` ile değiştirin.

---

### [ÖNCELİK: YÜKSEK] src/pages/izinler.html:527–533 — `tur` sütunu `izinler` tablosunda tanımlı değil

**Sorun:**
`izinler` INSERT payload'unda (satır 527–533) `tur: tur` gönderiliyor. `001_schema.sql`'deki `izinler` tablosunda `tur` sütunu yok. Tabloda yalnızca `izin_basl, izin_bitis, personel, aciklama, durum` sütunları tanımlı. İzin türü (Yıllık/Hastalık/Ücretsiz/Diğer) seçildikten sonra kayıt her seferinde DB hatası verecek.

Aynı şekilde tablo render sırasında `r.tur` ile erişiliyor (satır 431, 432, 435) — bu da NULL/undefined döner.

**Öneri:**
Ya `izinler` tablosuna `ALTER TABLE izinler ADD COLUMN IF NOT EXISTS tur VARCHAR(20);` migration ekleyin, ya da `aciklama` sütununu izin türü için kullanarak form değerini oraya yazın.

---

## ORTA (düzeltilmeli)

---

### [ÖNCELİK: ORTA] src/pages/retro.html:165 — `populateSprintDropdown`'a `reverse()` edilmiş liste gönderiliyor ancak `reverse()` orijinal diziyi de mutate eder

**Sorun:**
Satır 165: `populateSprintDropdown(sprintSelect, [...sprintler].reverse(), selectedDonem)`
Spread operatörü ile kopya oluşturulduğundan `reverse()` orijinal `sprintler` dizisini etkilemez — bu kısım doğru. Ancak sprint-ozet.html, kanban.js ve diğer sayfalarda `populateSprintDropdown` zaten `descending` sıralı gelen listeyi tekrar `reverse()` etmeden kullanıyor. Sadece retro.html bu şekilde listeyi ters çeviriyor: amaç kronolojik sıra (eski→yeni) olabilir, ancak `selectedDonem` mantığı (`sprintler[0].sprint_donem`, yani descending'in ilki = en yeni) ile çelişiyor.

**Öneri:**
Tüm sayfalarda `populateSprintDropdown` çağrısında tutarlı bir sıralama stratejisi benimseyin. Retro'da en yeni sprint seçili olması gerekiyorsa `reverse()` kaldırılabilir.

---

### [ÖNCELİK: ORTA] src/pages/harcamalar.html:469 — Tek dönemli kayıtta `odeme_kalemleri: null` tutarsızlığı

**Sorun:**
Satır 469: `odeme_kalemleri: donemler.length > 1 ? donemler : null`
Tek dönem girildiğinde `odeme_kalemleri` NULL kalıyor; dönemin verisi yalnızca `odeme_donem` ve `odenecek_kdvli` alanlarına yazılıyor. Bu kasıtlı bir "geriye dönük uyumluluk" tasarımı olsa da tabloda sorgu yapıldığında `odeme_kalemleri IS NOT NULL` kontrolü birden fazla dönemin olduğunu değil, tek dönem varlığını gizliyor. Ayrıca ödeme dönemi özet tablosu yalnızca `r.odeme_donem` üzerinden hesaplıyor; `odeme_kalemleri`'ndeki ek dönemler özet tabloya yansıtılmıyor.

**Öneri:**
`renderOdemeDonemiOzet` fonksiyonunu `odeme_kalemleri` JSONB varsa ondan, yoksa `odeme_donem/odenecek_kdvli`'den okuyacak şekilde güncelleyin. Böylece çoklu dönemli kayıtlar doğru özetlenir.

---

### [ÖNCELİK: ORTA] src/pages/faaliyetler.html:276–452 — `renderPage` fonksiyonu içindeki indentation inconsistency (potansiyel closure sorunu)

**Sorun:**
`renderPage` async fonksiyonu 245. satırda açılıyor. 275. satırdan itibaren iç değişkenler (`sopMap`, `altMap`, `asMap`, `planMap`, `html`) orijinal fonksiyon bloğu yerine bir seviye daha dışarı girintilendi. Fonksiyon gerçek anlamda kapanıyor (satır 453 `} // end renderPage`), bu yüzden JavaScript açısından çalışabilir. Ancak HTML kapatma tag'ı eksikliği riski var: satır 437–449 arasındaki `html +=` blokları incelendiğinde SOP döngüsü `html += '</div></div></div>'` (satır 445–449) ile biter ve ardından dış `if (html) container.innerHTML = html` ile render edilir. Genel mantık doğru görünmekle birlikte, her `<div class="accordion-item">` için açılan `<div class="accordion-body">` (satır 350) iki kapanış `</div>` ile kapatılıyor (satır 440–442); SOP wrapper ise üç kapanış `</div>` istiyor. HTML çıktısında dengesiz tag kalıp kalmadığını tarayıcıda doğrulayın.

**Öneri:**
`renderPage` fonksiyonunu okunabilirlik için düzgün indentleyın ve DevTools Elements panelinde accordion HTML çıktısını kontrol edin.

---

### [ÖNCELİK: ORTA] src/pages/sprint-perf-gos.html:176–178 — URL parametresiyle modal açılıyor ancak `openModal()` çağrısı `sprintler` undefined olabilir

**Sorun:**
Satır 158'de `[{ data: sprintler }, { data: perfGostergeler }] = await Promise.all([...])` çekimi yapılıyor. Satır 176'da URL'de `faaliyet` veya `sno` parametresi varsa hemen `openModal()` çağrılıyor. `openModal()` içinde satır 237'de `[...(sprintler || [])].reverse()` kullanıldığından `sprintler` null/undefined olsa bile çökmez. Ancak `perfGostergeler` boşsa ÇG Kodu dropdown'ı boş kalır ve kullanıcıya neden boş olduğu söylenmez.

**Öneri:**
Referans veriler yüklendikten sonra, hata varsa bir uyarı gösterin ve modal'ı açmadan önce veri kontrolü yapın.

---

### [ÖNCELİK: ORTA] src/sql/006_fixes.sql:96 — `v_sprint_ozet` view'ında `faaliyetler` tablosundan `yil` sütunu yok

**Sorun:**
`006_fixes.sql` satır 99–112 arasındaki `v_faaliyet_ozet` view'ı `f.yil` sütununu seçiyor. Ancak `001_schema.sql`'deki `faaliyetler` tablosunda `yil` sütunu tanımlı değil (yalnızca `fkod, sop, kategori, faaliyet, butce_2026, aylik_plan` var). Bu view oluşturma adımı DB'de hata üretir ve `faaliyetler.html` yıl filtreleme özelliği çalışmaz.

**Öneri:**
`faaliyetler` tablosuna `ALTER TABLE faaliyetler ADD COLUMN IF NOT EXISTS yil INTEGER DEFAULT 2026;` migration ekleyin (tercihen 006_fixes.sql içinde, view'dan önce).

---

## DÜŞÜK (opsiyonel)

---

### [ÖNCELİK: DÜŞÜK] src/pages/izinler.html:554 — `saha_gorevleri` INSERT'te `il` değeri `saha-il` select'ten alınıyor ancak `.trim()` gereksiz

`document.getElementById('saha-il').value.trim()` — `<select>` elementinden gelen değer zaten trim'li olur, önemsiz.

---

### [ÖNCELİK: DÜŞÜK] src/js/kanban.js:198 — RLS yetki kontrolü client-side'da yapılıyor

Satır 196–202: standart kullanıcının başkasına ait görevi taşıyıp taşıyamayacağı client-side JS ile kontrol ediliyor. RLS politikası zaten bu kısıtlamayı sunucu tarafında da uyguluyor (006_fixes.sql satır 37–43). Client-side kontrol iyi bir UX sağlasa da güvenlik için tek başına yeterli değil; mevcut RLS politikasıyla birlikte çalışması doğru bir tasarım. Sadece belgelenmelidir.

---

### [ÖNCELİK: DÜŞÜK] src/pages/perf-ozet.html:140 — `gerceklesen_2026` sütunu var olmayabilir

`perf-ozet.html` satır 140'ta `r.gerceklesen_2026` kullanıyor; `perf_gostergeler` tablosunda bu sütun `006_fixes.sql:13` ile ekleniyor. Migration uygulanmamışsa bu alan NULL döner ve tüm kümülatif hesaplamalar 0 gösterir. Migration'ın uygulandığından emin olun.

---

### [ÖNCELİK: DÜŞÜK] src/pages/retro.html — `gort` hesaplama ile SQL view farklı formül kullanıyor

`retro.html` → `calcGort(ajanstakiRolu, ajansHakkinda)` → `utils.js`'deki `calcGort` fonksiyonu (muhtemelen geometrik ortalama: `sqrt(a*b)`).
`006_fixes.sql` satır 67: `AVG(SQRT(ajanstaki_rolu::float * ajans_hakkinda::float))` — tüm kişilerin geometrik ortalamalarının aritmetik ortalaması.
Retro kayıt formunda gösterilen G.ort değeri (tek kişi için `sqrt(rol*hakkinda)`) ile sprint özet view'ındaki hepiniss (grup ortalaması) farklı anlam taşıyor — bu tasarımsal bir tutarsızlık değil, bilinçli bir fark gibi görünüyor. Sadece dokümantasyonda belirtilmeli.

---

## Spec Uyum Özeti

| Konu | Durum |
|---|---|
| `sprint_retro` `sprint_donem` ile birleşimi | Uygulandı (006_fixes.sql) — ancak eski sütun çakışması var |
| `perf_gostergeler.gerceklesen_2026` | Uygulandı |
| `harcamalar.odeme_kalemleri` JSONB | Uygulandı — çoklu dönem özet tablosuna yansıtılmıyor |
| `sprint_perf_gos.sprint_donem` FK | Uygulandı |
| `v_sprint_ozet` retro_agg düzeltmesi | Uygulandı |
| `v_faaliyet_ozet` yil sütunu | Uygulandı — ancak `faaliyetler.yil` sütunu migration'da eksik |
| RLS sprint_is_plani INSERT/UPDATE | Uygulandı |
| performans.html v_perf_gosterge_ozet view | EKSIK — view tanımlı değil |
| izinler.html `tur` sütunu | EKSIK — schema'da tanımlı değil |

---

## Sonuç

`DÜZELTİLMELİ` — 3 YÜKSEK öncelikli sorun var. Özellikle:
1. `izinler` tablosuna `tur` sütunu eklenmeden izin kayıtları DB'de hata verecek.
2. `v_perf_gosterge_ozet` view tanımlanmadan `performans.html` çalışmayacak; aynı sayfada null element hatası app'i çökertecek.
3. `faaliyetler` tablosuna `yil` sütunu eklenmeden `v_faaliyet_ozet` view'ı oluşturulamayacak ve yıl filtresi kullanılamayacak.

Bu 3 madde düzeltildikten sonra QA ajanı E2E testlerini çalıştırabilir.
