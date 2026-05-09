-- ============================================================
-- Migration 025: Yetki Yönetimi — Sistem Grupları + Tablo Katalog Seed
-- UTF-8 | DOKA Sprint Kanban
-- Tarih: 2026-05-09
-- ============================================================
-- Bu migration:
--  1. Mevcut 5 rolü (yönetici, gs, başkan, standart, izleyici) sistem grubu
--     olarak yetki_grubu'na yazar.
--  2. Tüm operasyonel tabloları yetki_tablo_katalog'a ekler.
--  3. Her sistem grubuna mevcut RLS davranışını yansıtan izin satırlarını
--     yetki_grubu_tablo_izni'na ekler.
--  4. Mevcut personeli rol_kodu'na göre uygun gruba atar.
--
-- Tüm INSERT'ler ON CONFLICT DO NOTHING ile idempotenttir.
-- ============================================================

-- ── 1. Sistem grupları ──────────────────────────────────────
INSERT INTO yetki_grubu (ad, aciklama, sistem_grubu, aktif) VALUES
  ('yönetici',  'Sistem yöneticisi — tüm tablolarda tüm yetkiler',                       TRUE, TRUE),
  ('gs',        'Geniş Standart — tüm ekip adına görev tanımlayabilen takım yöneticisi', TRUE, TRUE),
  ('başkan',    'Başkan — tüm birimleri görüntüleyebilen, kendi biriminde görev atayabilen kullanıcı', TRUE, TRUE),
  ('standart',  'Standart ekip üyesi — kendi görevlerini yönetebilen kullanıcı',         TRUE, TRUE),
  ('izleyici',  'İzleyici — yalnızca okuma erişimine sahip kullanıcı',                   TRUE, TRUE)
ON CONFLICT (ad) DO NOTHING;

-- ── 2. Tablo kataloğu ───────────────────────────────────────
INSERT INTO yetki_tablo_katalog (tablo_adi, goruntu_adi, aciklama, kategori, sira) VALUES
  -- Çekirdek (Sprint/Kanban)
  ('sprint_is_plani',     'Sprint İş Planı (Kanban)', 'Sprint görev kartları — Kanban panosu',                  'Çekirdek',   10),
  ('sprint_retro',        'Sprint Retrospektif',      'Sprint sonu geri bildirim ve aksiyon maddeleri',         'Çekirdek',   20),
  ('sprint_veri',         'Sprint Tanımları',         'Sprint dönemleri ve sürelerinin tanım kayıtları',        'Çekirdek',   30),

  -- Operasyon
  ('faaliyetler',         'Faaliyetler',              'Birim faaliyetleri',                                     'Operasyon',  40),
  ('alt_faaliyetler',     'Alt Faaliyetler',          'Faaliyetlere bağlı alt faaliyetler',                     'Operasyon',  50),
  ('anahtar_sonuclar',    'Anahtar Sonuçlar',         'Alt faaliyetlere bağlı anahtar sonuç (KR) kayıtları',    'Operasyon',  60),
  ('perf_gostergeler',    'Performans Göstergeleri',  'KPI tanımları',                                          'Operasyon',  70),
  ('sprint_perf_gos',     'Performans Gerçekleşmeleri','Sprint bazlı KPI gerçekleşmeleri',                      'Operasyon',  80),
  ('harcamalar',          'Harcamalar',               'Faaliyet/sprint bazlı bütçe harcamaları',                'Operasyon',  90),
  ('izinler',             'İzinler',                  'Personel izin kayıtları',                                'Operasyon', 100),
  ('saha_gorevleri',      'Saha Görevleri',           'Saha çalışma kayıtları',                                 'Operasyon', 110),

  -- Lookup
  ('soplar',              'SOP Listesi',              'Standart İşlem Prosedürleri',                            'Lookup',    200),
  ('sop_birim',           'SOP—Birim İlişkisi',       'SOP ↔ Birim çoka-çok eşlemesi',                          'Lookup',    210),
  ('kategoriler',         'Kategoriler',              'Genel kategori normalizasyon kayıtları',                 'Lookup',    220),
  ('birimler',            'Birimler',                 'Organizasyon birimleri',                                 'Lookup',    230),

  -- Sistem
  ('personel',            'Personel',                 'Kullanıcı/personel kayıtları',                           'Sistem',    300),
  ('audit_log',           'Audit Log',                'Tüm INSERT/UPDATE/DELETE değişiklik geçmişi',            'Sistem',    310),
  ('kullanici_rolleri',   'Eski Roller (Salt-Okunur)','Eski rol_kodu enum kayıtları',                           'Sistem',    320)
ON CONFLICT (tablo_adi) DO NOTHING;

-- ── 3. Sistem grupları için izin matrisi ────────────────────
-- yönetici: tüm tablolar, 4 izin de TRUE
INSERT INTO yetki_grubu_tablo_izni (yetki_grubu_id, tablo_adi, okuma, yazma, guncelleme, silme)
SELECT yg.id, k.tablo_adi, TRUE, TRUE, TRUE, TRUE
  FROM yetki_grubu yg, yetki_tablo_katalog k
 WHERE yg.ad = 'yönetici'
ON CONFLICT (yetki_grubu_id, tablo_adi) DO NOTHING;

-- izleyici: tüm tablolar, sadece okuma
INSERT INTO yetki_grubu_tablo_izni (yetki_grubu_id, tablo_adi, okuma, yazma, guncelleme, silme)
SELECT yg.id, k.tablo_adi, TRUE, FALSE, FALSE, FALSE
  FROM yetki_grubu yg, yetki_tablo_katalog k
 WHERE yg.ad = 'izleyici'
ON CONFLICT (yetki_grubu_id, tablo_adi) DO NOTHING;

-- standart: çekirdek + operasyon → okuma + yazma + güncelleme; lookup/sistem → sadece okuma
INSERT INTO yetki_grubu_tablo_izni (yetki_grubu_id, tablo_adi, okuma, yazma, guncelleme, silme)
SELECT yg.id,
       k.tablo_adi,
       TRUE,
       k.kategori IN ('Çekirdek','Operasyon'),
       k.kategori IN ('Çekirdek','Operasyon'),
       FALSE
  FROM yetki_grubu yg, yetki_tablo_katalog k
 WHERE yg.ad = 'standart'
ON CONFLICT (yetki_grubu_id, tablo_adi) DO NOTHING;

-- gs (geniş standart): çekirdek + operasyon → 4 izin; lookup/sistem → okuma
INSERT INTO yetki_grubu_tablo_izni (yetki_grubu_id, tablo_adi, okuma, yazma, guncelleme, silme)
SELECT yg.id,
       k.tablo_adi,
       TRUE,
       k.kategori IN ('Çekirdek','Operasyon'),
       k.kategori IN ('Çekirdek','Operasyon'),
       k.kategori = 'Çekirdek' AND k.tablo_adi = 'sprint_is_plani'  -- gs sadece kanban kartı silebilir
  FROM yetki_grubu yg, yetki_tablo_katalog k
 WHERE yg.ad = 'gs'
ON CONFLICT (yetki_grubu_id, tablo_adi) DO NOTHING;

-- başkan: çekirdek + operasyon → okuma + yazma + güncelleme; diğer → okuma
INSERT INTO yetki_grubu_tablo_izni (yetki_grubu_id, tablo_adi, okuma, yazma, guncelleme, silme)
SELECT yg.id,
       k.tablo_adi,
       TRUE,
       k.kategori IN ('Çekirdek','Operasyon'),
       k.kategori IN ('Çekirdek','Operasyon'),
       FALSE
  FROM yetki_grubu yg, yetki_tablo_katalog k
 WHERE yg.ad = 'başkan'
ON CONFLICT (yetki_grubu_id, tablo_adi) DO NOTHING;

-- ── 4. Mevcut personeli grubuna ata ─────────────────────────
INSERT INTO personel_yetki_grubu (personel_pkod, yetki_grubu_id)
SELECT p.pkod, yg.id
  FROM personel p
  JOIN yetki_grubu yg ON yg.ad = p.rol_kodu
 WHERE p.rol_kodu IS NOT NULL
ON CONFLICT (personel_pkod, yetki_grubu_id) DO NOTHING;
