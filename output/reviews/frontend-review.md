Agent: reviewer
Görev: Frontend (JS + HTML) kod incelemesi
Durum: TAMAMLANDI
Sonraki adım: Frontend ajanı YÜKSEK öncelikli sorunları düzelttikten sonra QA devam edebilir
---

### Genel Değerlendirme

8 HTML sayfası ve 6 JS modülü mevcut; spec'teki US-1 ila US-10 kabul kriterleri büyük ölçüde karşılanmış. Kanban drag-and-drop mantığı (status geçişleri, timestamp atamaları, bitis_donem), Realtime subscription ve auth guard doğru uygulanmış. Ancak 4 YÜKSEK öncelikli sorun MVP'yi bloke etmektedir: `sprint-ozet.html`'de Chart.js import eksik (çalışma zamanı hatası), `kanban.js`'de tüm UPDATE'lerde audit sütunları gönderilmiyor, `config.js`'de Supabase URL/key açık kodda ve `izinler.html`'de otomatik `sprint_veri` güncellemesi gerçekleşmiyor.

---

### Sorunlar

#### JavaScript Modülleri

```
[ÖNCELİK: YÜKSEK] src/js/config.js:7-8 — Supabase URL ve anon key kaynak koduna hardcoded
Öneri: Credentials'ı kaynak kontrolüne commit etme. Statik site için seçenekler:
  (a) Build adımı ekle (Vite/Parcel) ve .env kullan,
  (b) GitHub Pages için GitHub Secrets → deploy script → config.js üret,
  (c) Minimum: .gitignore'a ekle, .env.example'da belgele, kullanıcıya deploy öncesi düzenleme talimatı ver.
Mevcut durumda anon key public repo'ya push edilirse kötüye kullanılabilir.
```

```
[ÖNCELİK: YÜKSEK] src/js/kanban.js:201, 396, 399 — sprint_is_plani UPDATE sorgularında guncel_tarih ve guncelleyen sütunları gönderilmiyor
Spec (output/spec.md:165): "Her güncellemede audit trigger otomatik set eder" — BEFORE UPDATE trigger bu sütunları dolduruyor, ancak initial INSERT sırasında NULL kalıyor.
Öneri: Drag-and-drop ve modal save UPDATE payload'larına şu alanları ekle:
  guncel_tarih: new Date().toISOString().split('T')[0],
  guncelleyen: `${currentUser.ad}.${currentUser.soyad}`.toLowerCase()
(currentUser auth.js'den utils.getPersonel ile alınıyor — bu bilgi zaten mevcut)
```

```
[ÖNCELİK: YÜKSEK] src/js/kanban.js:19-32 — Top-level await zinciri try-catch olmadan; herhangi birinde hata olursa kullanıcıya boş/kırık sayfa gösterilir
Öneri: Init bloğunu tek try-catch ile sar ve kullanıcıya hata mesajı göster:
  try { await requireAuth(); ... } catch(e) { showError('Sayfa yüklenemedi: ' + e.message); }
```

```
[ÖNCELİK: ORTA] src/js/utils.js:132-140 — getPersonel sorgusunda id ve rol_kodu sütunları eksik
Öneri: .select('ad, soyad, bkod, id, rol_kodu') şeklinde güncelle; rol_kodu ileride yetki kontrolü için, id audit için gerekebilir.
```

```
[ÖNCELİK: ORTA] src/js/auth.js:29-32, 39-46 — getSession() ve requireAuth() ağ hatalarını yakalamıyor
Öneri: Her iki fonksiyona try-catch ekle; Supabase kapalıyken sonsuz döngü veya sessiz hata yerine kullanıcıya anlamlı mesaj göster.
```

```
[ÖNCELİK: ORTA] src/js/kanban.js:173-214 — Drag işlemi sırasında kart disable edilmiyor; async tamamlanmadan ikinci sürükleme mümkün, race condition riski
Öneri: handleDragEnd başında ilgili kartı pointer-events:none yap, UPDATE tamamlanınca geri aç.
```

```
[ÖNCELİK: DÜŞÜK] src/js/kanban.js:38-40 — loadReferenceData'da sprint_veri ve personel'den eksik sütunlar çekiliyor
Öneri: Savunmacı programlama için gerekli tüm sütunları select listesine ekle.
```

---

#### HTML Sayfaları

```
[ÖNCELİK: YÜKSEK] src/pages/sprint-ozet.html — Chart.js CDN import'u eksik; renderGkiTrend(), renderHepinissTrend() vb. çalışma zamanında "Chart is not defined" hatası verecek
Öneri: <head>'e şu satırı ekle (performans.html'deki gibi):
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
```

```
[ÖNCELİK: YÜKSEK] src/pages/izinler.html:548-554, 586-591 — İzin/saha formu submit sonrası sprint_veri.izin / sprint_veri.saha otomatik güncellenmiyor
Spec (output/spec.md:151): "Sprint dönemiyle örtüşen kayıtların toplamı otomatik sprint_veri.izin/saha'yı günceller"
Mevcut davranış: Sadece manuel "Özet Hesapla" butonuyla hesaplanıyor.
Öneri: İzin/saha INSERT başarılı olunca hesaplama fonksiyonunu otomatik çağır ve ilgili sprint_veri satırını UPDATE et.
```

```
[ÖNCELİK: YÜKSEK] src/pages/izinler.html:349 — Silme yetkisi `personel?.ad === 'Fatih'` ile isim karşılaştırmasıyla kontrol ediliyor
Spec: RLS rol bazlı yetki kullanıyor (rol_kodu='yönetici'). Frontend'de isim hardcode etmek kırılgan.
Öneri: `currentUser.rol_kodu === 'yönetici'` kontrolüyle değiştir; utils.getPersonel'e rol_kodu eklenmesi yeterli (bkz. yukarıdaki ORTA sorun).
```

```
[ÖNCELİK: ORTA] src/pages/harcamalar.html — Filtre değiştiğinde metrik kartlar (Toplam Harcama vb.) yeniden hesaplanmıyor; tablo filtreli, kartlar tüm kayıtları gösteriyor
Öneri: Filtre change handler'ında metrik hesaplamalarını da filtreli veri üzerinden yeniden çalıştır.
```

```
[ÖNCELİK: ORTA] src/pages/harcamalar.html:247 — sprint_is_plani sorgusu sprint_donem ile filtrelenmiyor; bütçe-harcama fark hesabı tüm dönemleri kapsıyor
Spec (output/spec.md:137): "fark = SUM(sprint_is_plani.harcanan_butce) - SUM(harcamalar.odenecek_kdvli)" sprint bazlı olmalı.
Öneri: sprint_is_plani sorgusuna .eq('sprint_donem', selectedSprint) filtresi ekle.
```

```
[ÖNCELİK: ORTA] src/pages/retro.html:170 — Form reset sonrası slider değer göstergeleri (org-val, rol-val, hakkinda-val) ve G.ort display güncellenmiyor
Öneri: Form reset handler'ında tüm değer göstergelerini başlangıç değerine (5) ve G.ort'u hesaplanmış değere sıfırla.
```

```
[ÖNCELİK: ORTA] src/index.html:75 — Backlog sütunu data-durum="" (boş string); Realtime'dan gelen NULL değeriyle eşleşmeyebilir
Öneri: Kanban.js'de NULL ve "" her ikisini de Backlog olarak işle (zaten yapılıyor olabilir — kanban.js'deki COLUMN_MAP'i doğrula).
```

```
[ÖNCELİK: DÜŞÜK] src/pages/sprint-ozet.html:85,88,91,94 — Canvas elementlerinde height="200" attribute var ama CSS height eksik; mobilde Chart.js yanlış boyutlanabilir
Öneri: Canvas'lara style="height:200px" veya Tailwind h-48 ekle.
```

```
[ÖNCELİK: DÜŞÜK] src/pages/performans.html:250, 310 — Chart yeniden render edilirken destroy/recreate flash oluşuyor
Öneri: Chart var ise dataset güncelle, yoksa yeni oluştur pattern'i kullan.
```

---

### Spec Uyum Özeti

| US | Sayfa | Kabul Kriteri | Durum | Not |
|---|---|---|---|---|
| US-1 | index.html | 4 Kanban sütunu | ✓ | |
| US-1 | kanban.js | baslama_t/inceleme_t/tamamlanma_t otomatik | ✓ | |
| US-1 | kanban.js | bitis_donem Tamamlandı'da set ediliyor | ✓ | KRİTİK doğrulandı |
| US-1 | kanban.js | Realtime subscription | ✓ | |
| US-2 | index.html | Sprint + üye filtresi | ✓ | |
| US-3 | index.html | Yeni görev + düzenleme modal | ✓ | |
| US-4 | sprint-ozet.html | GKİ, Hepiniss, Plan/Gerçekleşme, OrgPuan grafikleri | ✗ HATA | Chart.js import eksik |
| US-5 | login.html | E-posta/parola formu | ✓ | |
| US-5 | auth.js | Session guard + yönlendirme | ✓ | |
| US-5 | auth.js | auth_id → personel.ad eşleşmesi | ✓ | |
| US-6 | faaliyetler.html | SOP accordion, progress bar, Gantt | ✓ | |
| US-7 | retro.html | 3 slider, G.ort, geçmiş tablo | ✓ | Reset bug |
| US-8 | performans.html | SOP tablo, bar chart, doughnut | ✓ | |
| US-9 | harcamalar.html | Harcama tablo + form | ✓ | |
| US-9 | harcamalar.html | Bütçe fark hesabı sprint bazlı | ✗ HATA | Sprint filtresi eksik |
| US-10 | izinler.html | İzin/saha form | ✓ | |
| US-10 | izinler.html | Otomatik sprint_veri güncelleme | ✗ HATA | Manuel buton var, otomatik yok |

---

### Sonuç

**DÜZELTİLMELİ** — 4 YÜKSEK öncelikli sorun var (sprint-ozet Chart.js, kanban audit sütunları, izinler otomatik güncelleme, hardcoded isFatih). Frontend ajanı bu sorunları düzelttikten sonra QA devam edebilir.
