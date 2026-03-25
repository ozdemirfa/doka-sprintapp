Agent: PM
Görev: TR90 Kalkınma Ajansı Sprint Kanban — Excel'den Supabase + Vanilla JS web uygulamasına geçiş için tam gereksinim spesifikasyonu
Durum: TAMAMLANDI
Sonraki adım: SQL Agent bu spec.md'yi okuyarak `src/sql/` altına veritabanı dosyalarını yazsın (001_schema.sql, 002_views.sql, 003_rls.sql, 004_triggers.sql, seed.sql). SQL Agent tamamlandıktan sonra Frontend Agent sayfaları oluştursun.

---

## Proje Özeti

TR90 Kalkınma Ajansı, SOP (Sonuç Odaklı Program) bazlı faaliyetlerini 3 haftalık sprint döngüleriyle Excel+VBA ile yönetmektedir. Bu proje, aynı iş mantığını çok kullanıcılı, gerçek zamanlı bir web uygulamasına taşır. Scrum Master Fatih sprint planlamasını yapar; 6 ekip üyesi (Zübeyde, Elifnaz, Mehmet, Oğuzhan, Nuray, Esen) görevlerini Kanban board üzerinde sürükleyerek günceller. Sprint sonunda retrospektif puanlar girilir, GKİ ve Hepiniss metrikleri otomatik hesaplanır.

**Stack:** Vanilla HTML/CSS/JS + Supabase (PostgreSQL + Auth + Realtime) + Tailwind CSS (CDN) + SortableJS (CDN) + Chart.js (CDN). Backend yoktur — tüm veri erişimi Supabase JS client üzerinden doğrudan frontend'den yapılır.

---

## Kullanıcı Hikayeleri

### US-1: Kanban Board — Görev Durumu Güncelleme
Bir ekip üyesi olarak,
görevimi Kanban board'da sürükleyerek sütun değiştirmek istiyorum,
böylece sprint görevimin güncel durumunu takım ile paylaşabilirim.

**Kabul Kriterleri:**
- [ ] Dört sütun görünür: Backlog (is_durum IS NULL), Devam Ediyor (Başladı), İncelemede, Tamamlandı
- [ ] Kart sürüklendiğinde `is_durum` veritabanında güncellenir
- [ ] Backlog → Başladı geçişinde `baslama_t = NOW()` otomatik set edilir
- [ ] Başladı → İncelemede geçişinde `inceleme_t = NOW()` set edilir
- [ ] İncelemede → Tamamlandı geçişinde `tamamlanma_t = NOW()` set edilir
- [ ] `guncel_tarih` ve `guncelleyen` her güncellemede audit trigger tarafından otomatik set edilir
- [ ] Bir kullanıcı kartı hareket ettirdiğinde diğer kullanıcılar Realtime ile anlık görür

**Öncelik:** MVP

### US-2: Kanban Board — Görev Filtreleme
Bir ekip üyesi olarak,
Kanban board'u sprint dönemine ve ekip üyesine göre filtrelemek istiyorum,
böylece sadece ilgili görevleri görebilirim.

**Kabul Kriterleri:**
- [ ] Sprint dönemi dropdown'ı `sprint_veri` tablosundan beslenir
- [ ] Ekip üyesi filtresi çalışır (kendi adıma göre varsayılan)
- [ ] Filtreler birlikte uygulanabilir

**Öncelik:** MVP

### US-3: Kanban Board — Yeni Görev & Düzenleme
Bir Scrum Master olarak,
yeni sprint görevi ekleyebilmek ve mevcut görevi düzenleyebilmek istiyorum,
böylece sprint planını web uygulaması üzerinden yönetebilirim.

**Kabul Kriterleri:**
- [ ] Yeni görev ekleme modal'ı açılır; sprint_donem, sprint_faaliyetleri, sno, plan_sure, ekip_uyesi alanları doldurulabilir
- [ ] Mevcut görev detay modal'ı açılır; tüm alanlar düzenlenebilir
- [ ] Kaydetme sonrası board anlık güncellenir

**Öncelik:** MVP

### US-4: Sprint Özet & GKİ Grafikleri
Bir Scrum Master olarak,
sprint dönemlerinin GKİ, Hepiniss ve diğer metriklerini grafik olarak görmek istiyorum,
böylece takım performansını trendler üzerinden izleyebilirim.

**Kabul Kriterleri:**
- [ ] `v_sprint_ozet` view'ı GKİ hesaplamasını Excel ile birebir aynı verir (Sprint 1: ~98.5, Sprint 2: ~86.8)
- [ ] GKİ trend çizgi grafiği gösterilir
- [ ] Hepiniss trend çizgi grafiği gösterilir (GEOMEAN = SQRT(ajanstaki_rolu × ajans_hakkinda))
- [ ] Plan vs Gerçekleşme bar chart gösterilir
- [ ] OrgPuan trend grafiği gösterilir
- [ ] Sprint karşılaştırma metrikleri kart yapısında listelenir

**Öncelik:** MVP

### US-5: Giriş / Çıkış
Bir kullanıcı olarak,
e-posta ve parola ile sisteme giriş yapabilmek istiyorum,
böylece yetkili veriye güvenli erişebilirim.

**Kabul Kriterleri:**
- [ ] `login.html` sayfasında e-posta/parola formu çalışır
- [ ] Giriş yapınca `auth.users.id` → `personel.auth_id` eşleşmesi yapılır
- [ ] Oturum açık değilse tüm sayfalar `login.html`'e yönlendirir
- [ ] Çıkış yapılabilir

**Öncelik:** MVP

### US-6: Faaliyetler & Alt Faaliyetler
Bir Scrum Master olarak,
faaliyetleri ve alt faaliyetleri SOP bazında gruplanmış şekilde görmek istiyorum,
böylece yıllık iş planının tamamlanma durumunu ve bütçe kullanımını izleyebilirim.

**Kabul Kriterleri:**
- [ ] SOP bazında accordion/tree yapısı gösterilir
- [ ] Her alt faaliyet yanında is_durum_oran progress bar (%0-100) gösterilir
- [ ] 2026 bütçesi vs harcanan bütçe bar/progress göstergesi gösterilir
- [ ] Aylık plan takvimi (JSONB `aylik_plan` alanından Oca-Ara) Gantt-benzeri görünümde gösterilir
- [ ] Anahtar sonuçlar accordion'unda listelenir
- [ ] Yeni faaliyet / alt faaliyet eklenebilir

**Öncelik:** MVP

### US-7: Retrospektif Formu
Bir ekip üyesi olarak,
sprint retro formunu doldurmak istiyorum,
böylece organizasyon ve memnuniyet puanlarımı kaydedebilirim.

**Kabul Kriterleri:**
- [ ] Sprint toplantısı dropdown'ından seçilir (`sprint_veri.bitis` tarihiyle eşleşir)
- [ ] OrganizasyonPuan, AjanstakiRolü, AjansHakkında (1-10 slider) doldurulabilir
- [ ] G.ort = SQRT(ajanstaki_rolu × ajans_hakkinda) anlık hesaplanıp gösterilir
- [ ] Geçmiş retro sonuçları tablosu görüntülenebilir
- [ ] RLS ile kişi sadece kendi adıyla kayıt ekleyebilir

**Öncelik:** MVP

### US-8: Performans Göstergeleri Dashboard
Bir yönetici veya Scrum Master olarak,
SOP bazlı performans göstergelerinin hedef ve gerçekleşme değerlerini görmek istiyorum,
böylece çıktı hedeflerine ne kadar ulaşıldığını anlık izleyebilirim.

**Kabul Kriterleri:**
- [ ] `v_perf_gosterge_ozet` view'ından SOP bazlı tablo gösterilir
- [ ] Hedef vs Gerçekleşme bar chart (2024, 2025, 2026 yıl bazlı) gösterilir
- [ ] Kümülatif ilerleme göstergesi (progress ring veya gauge) gösterilir
- [ ] Sprint bazlı gerçekleşme giriş formu (`sprint_perf_gos`) çalışır
- [ ] Tamamlanma dönemi takibi (2026/1-4) görüntülenir

**Öncelik:** Nice-to-have (MVP sonrası)

### US-9: Harcamalar
Bir Scrum Master olarak,
harcama kayıtlarını girmek ve bütçe doğrulama farkını görmek istiyorum,
böylece SprintİşPlanı ile Harcamalar tablosu arasındaki tutarlılığı kontrol edebirim.

**Kabul Kriterleri:**
- [ ] Harcama listesi tablosu (sprint, dönem, durum filtreli) gösterilir
- [ ] Yeni harcama giriş formu çalışır
- [ ] `fark = SUM(sprint_is_plani.harcanan_butce) - SUM(harcamalar.odenecek_kdvli)` gösterilir
- [ ] Ödeme dönemi bazlı toplam özet görüntülenir
- [ ] SOP/Faaliyet bazlı bütçe kullanım raporu gösterilir

**Öncelik:** Nice-to-have (MVP sonrası)

### US-10: İzinler & Saha Görevleri
Bir Scrum Master olarak,
izin ve saha görevlerini kaydetmek istiyorum,
böylece GKİ hesaplamasında kullanılan `sprint_veri.izin` ve `sprint_veri.saha` değerleri doğru olsun.

**Kabul Kriterleri:**
- [ ] İzin giriş formu çalışır (personel, tarih aralığı, tür)
- [ ] Saha görevi giriş formu çalışır (personel, tarih, il, açıklama)
- [ ] Sprint dönemiyle örtüşen kayıtların toplamı otomatik `sprint_veri.izin` / `sprint_veri.saha`'yı günceller
- [ ] Takvim görünümü (isteğe bağlı)

**Öncelik:** Nice-to-have (MVP sonrası)

---

## SQL Gereksinimleri

### Kararlar & Tasarım Notları

- **`aylik_plan` JSONB olarak modellenir** (`faaliyetler` tablosunda): `aylik_plan JSONB DEFAULT '{}'` — `{"oca": 1, "sub": 0, "mar": 1, ...}` formatında. Ayrı tablo yerine JSONB tercih edildi (Excel'e sadık, sorgu basitliği).
- **`bitis_donem` vs `sprint_donem`:** GKİ hesaplamasında `bitis_donem` kullanılır. Bir görev bir sprint'te başlayıp farklı bir sprint'te tamamlanabilir; `bitis_donem` tamamlandığı dönemi tutar. `v_sprint_ozet` view'ında T.Skor ve GKİ `bitis_donem = sv.sprint_donem` koşuluyla hesaplanır.
- **Sprint otomatik tarih mantığı frontend'de uygulanır** (yeni sprint eklenirken): başlangıç = önceki bitiş + 3 gün, bitiş = başlangıç + 18 gün. DB trigger gerekli değildir.
- **Audit trigger kapsamı:** `sprint_is_plani` ve `harcamalar` tablolarının ikisi de `guncel_tarih` ve `guncelleyen` sütunlarına sahiptir; her ikisine de `trg_audit` uygulanmalıdır.

### Tablolar

- [ ] `birimler` — Birim lookup (4 kayıt: SKB, MEKB, KYİKB, PİDB)
- [ ] `soplar` — SOP lookup (8 kayıt); `bkod` FK → birimler
- [ ] `kategoriler` — SOP-kategori composite PK (skod + kkod); `skod` FK → soplar
- [ ] `kullanici_rolleri` — Yetki seviyeleri (2 kayıt: yönetici, standart); `rol_kodu VARCHAR(20) PK`
- [ ] `personel` — 7 kullanıcı; `bkod` FK → birimler; `auth_id` UUID UNIQUE FK → auth.users.id; `rol_kodu` FK → kullanici_rolleri
- [ ] `faaliyetler` — 30 faaliyet; `sop` FK → soplar.kisa; `aylik_plan JSONB DEFAULT '{}'`; `butce_2026 DECIMAL(15,2)`
- [ ] `alt_faaliyetler` — 53 alt faaliyet; `fkod` FK → faaliyetler.fkod; `p_sure DECIMAL(5,1)`, `tekrar_sayisi INTEGER`
- [ ] `anahtar_sonuclar` — 91 kayıt; composite PK (sno, as_no); `sno` FK → alt_faaliyetler.sno
- [ ] `sprint_veri` — 17 dönem (4 aktif + 13 şablon); `sprint_donem` PK; `izin INTEGER DEFAULT 0`, `saha INTEGER DEFAULT 0`
- [ ] `sprint_is_plani` — 102 kayıt; ANA KANBAN TABLOSU; `id SERIAL PK`; `sprint_donem` FK → sprint_veri; `sno` FK → alt_faaliyetler; `is_durum VARCHAR(20)` CHECK (`is_durum IN ('Başladı', 'İncelemede', 'Tamamlandı') OR is_durum IS NULL`); `bitis_donem INTEGER`; `guncel_tarih DATE`, `guncelleyen VARCHAR(50)` (audit trigger ile)
- [ ] `harcamalar` — 8 kayıt; `sprint_donem` FK → sprint_veri; `sno` FK → alt_faaliyetler; `odenecek_kdvli DECIMAL(15,2) NOT NULL`; `guncel_tarih`, `guncelleyen` (audit trigger ile)
- [ ] `perf_gostergeler` — 28 kayıt; `cg_kod VARCHAR(20) PK`; `sop` FK → soplar.kisa
- [ ] `sprint_perf_gos` — 8 kayıt; `sno` FK → alt_faaliyetler; `cg_kod` FK → perf_gostergeler
- [ ] `izinler` — 5 kayıt; personel adı VARCHAR (auth bağımsız)
- [ ] `saha_gorevleri` — 5 kayıt; personel adı VARCHAR

### View'lar

- [ ] `v_sprint_ozet` — sprint_veri × sprint_is_plani × sprint_retro: `org_puan`, `hepiniss` (SQRT(ajanstaki_rolu * ajans_hakkinda)), `t_skor` (bitis_donem kullanılır), `gki` = t_skor / (sure_gun * ekip - izin) * 100, `plan_toplam`, `gerceklesme`
- [ ] `v_alt_faaliyet_ozet` — alt_faaliyetler × sprint_is_plani × harcamalar: `is_yuku` (p_sure × tekrar_sayisi), `gerceklesme_sayi`, `gercek_is_yuku`, `is_durum_oran`, `harcanan_butce`
- [ ] `v_faaliyet_ozet` — faaliyetler × v_alt_faaliyet_ozet: `is_durum_ort`, `harcanan_butce_toplam`
- [ ] `v_perf_gosterge_ozet` — perf_gostergeler × sprint_perf_gos: `gerceklesen_2026` (yil=2026 SUMIFS), `kumulatif_gerceklesme` (2024+2025+2026)

### RLS Politikaları

**Lookup / okuma tablolarında (tüm authenticated kullanıcılar SELECT):**
- [ ] `kullanici_rolleri` — SELECT FOR ALL authenticated users; INSERT/UPDATE/DELETE sadece yönetici
- [ ] `birimler` — SELECT FOR ALL authenticated users
- [ ] `soplar` — SELECT FOR ALL authenticated users
- [ ] `kategoriler` — SELECT FOR ALL authenticated users
- [ ] `personel` — SELECT FOR ALL authenticated users
- [ ] `faaliyetler` — SELECT FOR ALL authenticated users
- [ ] `alt_faaliyetler` — SELECT FOR ALL authenticated users
- [ ] `anahtar_sonuclar` — SELECT FOR ALL authenticated users
- [ ] `perf_gostergeler` — SELECT FOR ALL authenticated users
- [ ] `sprint_veri` — SELECT FOR ALL authenticated users

**sprint_is_plani:**
- [ ] SELECT — tüm ekip tüm görevleri görebilir (`USING (true)` + `auth.role() = 'authenticated'`)
- [ ] INSERT — tüm ekip görev ekleyebilir
- [ ] UPDATE — `ekip_uyesi = personel.ad (auth_id = auth.uid())` VEYA personel adı 'Fatih' (Scrum Master)
- [ ] DELETE — sadece Scrum Master (Fatih)

**sprint_retro:**
- [ ] INSERT — `ad = personel.ad (auth_id = auth.uid())` (herkes sadece kendi adıyla)
- [ ] SELECT — tüm ekip görebilir

**harcamalar:**
- [ ] INSERT — tüm ekip girebilir
- [ ] SELECT — tüm ekip görebilir
- [ ] UPDATE — sadece Scrum Master

**sprint_perf_gos, izinler, saha_gorevleri:**
- [ ] INSERT/SELECT — tüm authenticated users

### Trigger'lar

- [ ] `trg_sprint_is_plani_audit` — BEFORE UPDATE ON sprint_is_plani: `guncel_tarih = NOW()`, `guncelleyen = ad || '.' || soyad FROM personel WHERE auth_id = auth.uid()`
- [ ] `trg_harcamalar_audit` — BEFORE UPDATE ON harcamalar: aynı mantık (`guncel_tarih`, `guncelleyen`)

### Seed Data Önceliği

1. birimler (4 kayıt)
2. soplar (8 kayıt)
3. kategoriler (~21 kayıt)
4. kullanici_rolleri (2 kayıt: yönetici, standart) — personel'den önce girilmeli (FK bağımlılığı)
5. personel (7 kayıt) — `auth_id` NULL olarak girilir, Supabase Auth kullanıcıları oluşturulduktan sonra UPDATE ile eşleştirilir; `rol_kodu` girilir
6. faaliyetler (30 kayıt) — `aylik_plan` JSONB dahil
7. alt_faaliyetler (53 kayıt)
8. perf_gostergeler (28 kayıt)
9. sprint_veri (4 aktif + 13 şablon = 17 kayıt)
10. sprint_is_plani (102 kayıt) — KRİTİK
11. anahtar_sonuclar (91 kayıt)
12. sprint_retro (29 kayıt)
13. harcamalar (8 kayıt)
14. sprint_perf_gos (8 kayıt)
15. izinler (5 kayıt)
16. saha_gorevleri (5 kayıt)

**NOT:** Tüm SQL dosyaları UTF-8 encoding ile yazılır. Türkçe karakterler (İ, ş, ö, ğ, ü, ç, Ş, Ö, Ğ, Ü, Ç) korunur.

---

## Frontend Gereksinimleri

### Sayfalar

| Dosya | Başlık | Supabase Tablosu/View | Ana Özellikler |
|-------|--------|-----------------------|----------------|
| `index.html` | Kanban Board | `sprint_is_plani` | Drag & drop (SortableJS), 4 sütun, Realtime, sprint & üye filtresi, yeni görev modal, detay/düzenleme modal |
| `login.html` | Giriş | `auth.users` + `personel` | Email/password form, session yönetimi, yönlendirme |
| `pages/sprint-ozet.html` | Sprint Özet | `v_sprint_ozet` | GKİ trend grafiği (Chart.js), Hepiniss trend, Plan vs Gerçekleşme bar, OrgPuan trend, sprint kart metrikleri |
| `pages/faaliyetler.html` | Faaliyetler | `v_faaliyet_ozet`, `alt_faaliyetler`, `anahtar_sonuclar` | SOP accordion/tree, is_durum_oran progress bar, bütçe progress, aylik_plan Gantt görünümü, yeni faaliyet/alt faaliyet formu |
| `pages/performans.html` | Performans | `v_perf_gosterge_ozet`, `sprint_perf_gos` | SOP bazlı tablo, hedef/gerçekleşme bar chart, kümülatif progress ring, gerçekleşme giriş formu |
| `pages/retro.html` | Retrospektif | `sprint_retro`, `sprint_veri` | Sprint seçim dropdown, 3 slider (1-10), G.ort anlık hesaplama, geçmiş retro tablosu |
| `pages/harcamalar.html` | Harcamalar | `harcamalar`, `sprint_is_plani` | Filtrelenebilir tablo, yeni harcama formu, bütçe-harcama fark kontrolü, ödeme dönemi özet |
| `pages/izinler.html` | İzinler & Saha | `izinler`, `saha_gorevleri`, `sprint_veri` | İzin giriş formu, saha görevi formu, sprint bazlı otomatik toplam, sprint_veri.izin/saha güncelleme |

### JavaScript Modülleri

| Dosya | Sorumluluk |
|-------|------------|
| `js/supabase-client.js` | `createClient` ile Supabase bağlantısı; `SUPABASE_URL` ve `SUPABASE_ANON_KEY` `.env` / config'den |
| `js/auth.js` | signIn, signOut, getSession, sayfa yönlendirme (login guard) |
| `js/kanban.js` | SortableJS init, sürükleme olayları, `is_durum` güncelleme, otomatik tarih atamaları, Realtime subscription |
| `js/charts.js` | Chart.js grafik fonksiyonları (GKİ trend, Hepiniss, Plan/Gerçekleşme, bütçe) |
| `js/utils.js` | Tarih formatlama, Türkçe karakter yardımcıları, sprint dropdown doldurma, G.ort hesaplama |

### Supabase Entegrasyonları

- [ ] **Auth:** `supabase.auth.signInWithPassword()` — e-posta/parola ile giriş; tüm sayfalar session kontrolü yapar; `session.user.id` → `personel.auth_id` JOIN ile kullanıcı adı ve birimi alınır
- [ ] **Realtime:** `sprint_is_plani` tablosunda Supabase Realtime subscription (INSERT, UPDATE, DELETE). Sadece bu tablo. Kanban board anlık yenilenir. `supabase.channel('sprint_is_plani').on('postgres_changes', ...)` kullanılır.
- [ ] **RLS — Frontend Etkisi:** UPDATE işlemlerinde Supabase kendi auth context'ini kullanır; frontend ekstra güvenlik kodu yazmaz. Başarısız UPDATE'ler (yetki dışı) Supabase error olarak döner, frontend kullanıcıya "Yetki yok" uyarısı gösterir.

### UI/UX Notları

- Responsive (mobil + masaüstü) — Tailwind CSS utility classes
- Kanban kart içeriği: sprint_faaliyetleri (başlık), S.No, plan_sure, ekip_uyesi (badge), baslama_t/tamamlanma_t, harcanan_butce (varsa)
- Sprint otomatik tarih hesabı (yeni sprint eklenirken): `baslangic = onceki_bitis + 3`, `bitis = baslangic + 18` — frontend JS ile uygulanır
- `is_durum` NULL değeri Backlog olarak işlenir; form'larda boş seçenek "Backlog" olarak gösterilir
- Tüm sayfalarda ortak sidebar/navbar bulunur: Kanban, Sprint Özet, Faaliyetler, Retro, Performans, Harcamalar, İzinler + kullanıcı adı / Çıkış butonu

---

## Öncelik Sırası

**MVP (ilk teslim):**

1. DB şeması — 14 tablo (`src/sql/001_schema.sql`)
2. View'lar — 4 hesaplama view'ı (`src/sql/002_views.sql`)
3. RLS politikaları — tüm tablolar (`src/sql/003_rls.sql`)
4. Audit trigger'lar — sprint_is_plani + harcamalar (`src/sql/004_triggers.sql`)
5. Seed data — Excel verisi (`src/sql/seed.sql`)
6. Supabase client + Auth — giriş/çıkış/session (`js/supabase-client.js`, `js/auth.js`, `login.html`)
7. **Kanban Board** — ana sayfa, drag & drop, Realtime (`index.html`, `js/kanban.js`)
8. Sprint Özet sayfası + GKİ/Hepiniss grafikleri (`pages/sprint-ozet.html`, `js/charts.js`)
9. Faaliyetler sayfası — SOP accordion, bütçe, aylik_plan Gantt (`pages/faaliyetler.html`)
10. Retrospektif formu (`pages/retro.html`)

**Nice-to-have (MVP sonrası):**

11. Performans göstergeleri dashboard (`pages/performans.html`)
12. Harcamalar sayfası (`pages/harcamalar.html`)
13. İzinler & Saha görevleri (`pages/izinler.html`)
14. Deploy config + README (`.env.example`, `README.md`)
