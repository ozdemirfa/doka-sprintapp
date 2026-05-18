-- ============================================================
-- Migration 027: Yetki RLS Security Fixes — Sprint 2A
-- UTF-8 | DOKA Sprint Kanban
-- Tarih: 2026-05-18
-- Branch: feature/permission-matrix
-- Author: database-agent (Sprint 2A)
-- ============================================================
-- Bağımlılıklar: 024, 025, 026 uygulanmış olmalı
--   024_yetki_gruplari.sql    → tablo şemaları ve FOR ALL policies
--   025_yetki_seed.sql        → sistem grupları ve tablo kataloğu
--   026_yetki_rls_refactor.sql → current_user_has_permission() helper
--
-- Çözülen bulgular:
--   S-001 (Critical) — self-promotion: personel_yetki_grubu INSERT kontrolü eksik
--   S-002 (Critical) — FOR ALL policy yerine ayrık INSERT/UPDATE/DELETE policies
--   S-003 (Critical) — 9 tablo RLS'e current_user_has_permission() eklenmedi
--   S-004 (Critical) — sistem_grubu immutability trigger eksik
--   S-017 (Minor)    — yetki_grubu tablosunda audit trigger eksik
--   S-018 (Minor)    — yetki_grubu.ad UNIQUE constraint case-insensitive değil
--
-- NOT: Bu migration 024/025/026 dosyalarını değiştirmez; sadece eklemeler yapar.
-- ============================================================

BEGIN;

-- ============================================================
-- BÖLÜM 1: S-001 + S-002 — FOR ALL policy'leri ayrık per-operation
-- policy'lerle değiştir
-- Hedef tablolar: yetki_grubu, personel_yetki_grubu,
--                 yetki_grubu_tablo_izni, yetki_tablo_katalog
--
-- Neden: FOR ALL policy OR mantığı ile yeni bir permissive policy
-- eklendiğinde INSERT/UPDATE/DELETE gate'i by-pass olabilir.
-- Ayrıca self-promotion saldırısını engellemek için
-- personel_yetki_grubu INSERT'te özel kontrol gerekiyor.
-- ============================================================

-- ── yetki_grubu ─────────────────────────────────────────────

-- Eski FOR ALL policy'yi kaldır
DROP POLICY IF EXISTS "yetki_grubu_modify" ON yetki_grubu;

-- INSERT: yönetici rol_kodu VEYA permission matrisi yazma yetkisi
-- S-002: WITH CHECK açık yazılıyor; FOR ALL'ın örtük davranışına güvenilmiyor
DROP POLICY IF EXISTS "yetki_grubu_insert" ON yetki_grubu;
CREATE POLICY "yetki_grubu_insert"
  ON yetki_grubu FOR INSERT TO authenticated
  WITH CHECK (
    -- Klasik rol_kodu yönetici kontrolü (geriye uyum)
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    -- YENİ: permission matrisi üzerinden yazma yetkisi olan kullanıcı
    OR current_user_has_permission('yetki_grubu', 'yazma')
  );

-- UPDATE: USING + WITH CHECK ikisi de zorunlu (satır-görünürlük + değer denetimi)
DROP POLICY IF EXISTS "yetki_grubu_update" ON yetki_grubu;
CREATE POLICY "yetki_grubu_update"
  ON yetki_grubu FOR UPDATE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('yetki_grubu', 'guncelleme')
  )
  WITH CHECK (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('yetki_grubu', 'guncelleme')
  );

-- DELETE: sistem_grubu koruması S-004 trigger'ı tarafından ayrıca güvencelenecek
DROP POLICY IF EXISTS "yetki_grubu_delete" ON yetki_grubu;
CREATE POLICY "yetki_grubu_delete"
  ON yetki_grubu FOR DELETE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('yetki_grubu', 'silme')
  );

-- ── personel_yetki_grubu ─────────────────────────────────────
-- S-001 CRITICAL: self-promotion engeli INSERT'te WITH CHECK ile eklendi.
-- Bir kullanıcı kendi pkod'unu INSERT edemez (kendi yetkisini yükseltemez).

DROP POLICY IF EXISTS "personel_yetki_grubu_modify" ON personel_yetki_grubu;

-- INSERT: yönetici/permission VEYA izinli — AMA kendi pkod'una atama yapamaz
-- Tehdit modeli: non-admin kullanıcı doğrudan REST API'ye
--   POST /rest/v1/personel_yetki_grubu {"personel_pkod": KENDI_PKOD, "yetki_grubu_id": ADMIN_ID}
-- yaparak yönetici grubuna kendini ekleyemez.
DROP POLICY IF EXISTS "personel_yetki_grubu_insert" ON personel_yetki_grubu;
CREATE POLICY "personel_yetki_grubu_insert"
  ON personel_yetki_grubu FOR INSERT TO authenticated
  WITH CHECK (
    (
      -- Yönetici her kullanıcıyı her gruba ekleyebilir
      (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
      OR current_user_has_permission('personel_yetki_grubu', 'yazma')
    )
    -- S-001: Self-promotion engeli — kimse kendi pkod'unu ekleyemez
    AND personel_pkod <> (SELECT pkod FROM personel WHERE auth_id = auth.uid())
  );

-- UPDATE: grup ataması güncelleme
DROP POLICY IF EXISTS "personel_yetki_grubu_update" ON personel_yetki_grubu;
CREATE POLICY "personel_yetki_grubu_update"
  ON personel_yetki_grubu FOR UPDATE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('personel_yetki_grubu', 'guncelleme')
  )
  WITH CHECK (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('personel_yetki_grubu', 'guncelleme')
  );

-- DELETE: grup ataması silme
DROP POLICY IF EXISTS "personel_yetki_grubu_delete" ON personel_yetki_grubu;
CREATE POLICY "personel_yetki_grubu_delete"
  ON personel_yetki_grubu FOR DELETE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('personel_yetki_grubu', 'silme')
  );

-- ── yetki_grubu_tablo_izni ────────────────────────────────────

DROP POLICY IF EXISTS "yetki_grubu_tablo_izni_modify" ON yetki_grubu_tablo_izni;

DROP POLICY IF EXISTS "yetki_grubu_tablo_izni_insert" ON yetki_grubu_tablo_izni;
CREATE POLICY "yetki_grubu_tablo_izni_insert"
  ON yetki_grubu_tablo_izni FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('yetki_grubu_tablo_izni', 'yazma')
  );

DROP POLICY IF EXISTS "yetki_grubu_tablo_izni_update" ON yetki_grubu_tablo_izni;
CREATE POLICY "yetki_grubu_tablo_izni_update"
  ON yetki_grubu_tablo_izni FOR UPDATE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('yetki_grubu_tablo_izni', 'guncelleme')
  )
  WITH CHECK (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('yetki_grubu_tablo_izni', 'guncelleme')
  );

DROP POLICY IF EXISTS "yetki_grubu_tablo_izni_delete" ON yetki_grubu_tablo_izni;
CREATE POLICY "yetki_grubu_tablo_izni_delete"
  ON yetki_grubu_tablo_izni FOR DELETE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('yetki_grubu_tablo_izni', 'silme')
  );

-- ── yetki_tablo_katalog ───────────────────────────────────────
-- Katalog tablosu; sistem gruplarının nasıl göründüğünü etkiliyor.
-- Normal yönetici + permission denetimi uygulanır.

DROP POLICY IF EXISTS "yetki_tablo_katalog_modify" ON yetki_tablo_katalog;

DROP POLICY IF EXISTS "yetki_tablo_katalog_insert" ON yetki_tablo_katalog;
CREATE POLICY "yetki_tablo_katalog_insert"
  ON yetki_tablo_katalog FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('yetki_tablo_katalog', 'yazma')
  );

DROP POLICY IF EXISTS "yetki_tablo_katalog_update" ON yetki_tablo_katalog;
CREATE POLICY "yetki_tablo_katalog_update"
  ON yetki_tablo_katalog FOR UPDATE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('yetki_tablo_katalog', 'guncelleme')
  )
  WITH CHECK (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('yetki_tablo_katalog', 'guncelleme')
  );

DROP POLICY IF EXISTS "yetki_tablo_katalog_delete" ON yetki_tablo_katalog;
CREATE POLICY "yetki_tablo_katalog_delete"
  ON yetki_tablo_katalog FOR DELETE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('yetki_tablo_katalog', 'silme')
  );

-- ============================================================
-- BÖLÜM 2: S-003 — 9 eksik tabloyu RLS'e bağla
-- current_user_has_permission() OR-kontrolünü mevcut yönetici
-- policy'lerine ek olarak ekle (DROP + yeniden CREATE pattern)
--
-- KAPSAM DIŞI — kasıtlı olarak:
--   kullanici_rolleri: Eski rol enum tablosu; yalnız okuma
--     amaçlı. Matrix UI'da "Eski Roller (Salt-Okunur)" olarak
--     işaretli. Yazma/silme yetkisi matrise dahil edilmemeli;
--     UI'dan bu tablonun yazma izin satırlarını kaldırın
--     (frontend görevi). DB policy'si yönetici-only kalır.
--   audit_log: Kesinlikle yazma/silme kapalı olmalı.
--     Sadece fn_audit_log() SECURITY DEFINER trigger'ı INSERT
--     yapabilir. Policy değiştirilmez; UI'da bu tablonun
--     INSERT/UPDATE/DELETE permission satırlarını gizleyin
--     (frontend görevi).
-- ============================================================

-- ── birimler ─────────────────────────────────────────────────
-- 003'te: birimler_insert_fatih, birimler_update_fatih,
--          birimler_delete_fatih (sadece yönetici)
-- Yeni: yönetici VEYA permission matrisinde ilgili yetki

DROP POLICY IF EXISTS "birimler_insert_fatih" ON birimler;
CREATE POLICY "birimler_insert_fatih"
  ON birimler FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('birimler', 'yazma')
  );

DROP POLICY IF EXISTS "birimler_update_fatih" ON birimler;
CREATE POLICY "birimler_update_fatih"
  ON birimler FOR UPDATE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('birimler', 'guncelleme')
  )
  WITH CHECK (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('birimler', 'guncelleme')
  );

DROP POLICY IF EXISTS "birimler_delete_fatih" ON birimler;
CREATE POLICY "birimler_delete_fatih"
  ON birimler FOR DELETE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('birimler', 'silme')
  );

-- ── kategoriler ───────────────────────────────────────────────
-- Tablo 007_revisions migration'inda DROP edildi (CASCADE). Policy yazimi atlandi --
-- tablo geri eklenirse ayri migration'da ele alinmali.

-- ── personel ──────────────────────────────────────────────────
-- 003'te: personel_insert_fatih, personel_update_fatih
-- NOT: personel_delete policy'si 003'te YOK (kasıtlı — personel
-- silinemez, deaktive edilir). Bu migration'da da eklenmez;
-- DELETE yönetici-only kalır ve matris UI'da personel silme izni
-- gösterilmesi önerilmez.

DROP POLICY IF EXISTS "personel_insert_fatih" ON personel;
CREATE POLICY "personel_insert_fatih"
  ON personel FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('personel', 'yazma')
  );

DROP POLICY IF EXISTS "personel_update_fatih" ON personel;
CREATE POLICY "personel_update_fatih"
  ON personel FOR UPDATE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('personel', 'guncelleme')
  )
  WITH CHECK (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('personel', 'guncelleme')
  );

-- ── sprint_veri ───────────────────────────────────────────────
-- 003'te: sprint_veri_insert_fatih, sprint_veri_update_fatih
-- DELETE policy 003'te yok; ekliyoruz (yönetici + permission)

DROP POLICY IF EXISTS "sprint_veri_insert_fatih" ON sprint_veri;
CREATE POLICY "sprint_veri_insert_fatih"
  ON sprint_veri FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('sprint_veri', 'yazma')
  );

DROP POLICY IF EXISTS "sprint_veri_update_fatih" ON sprint_veri;
CREATE POLICY "sprint_veri_update_fatih"
  ON sprint_veri FOR UPDATE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('sprint_veri', 'guncelleme')
  )
  WITH CHECK (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('sprint_veri', 'guncelleme')
  );

-- sprint_veri DELETE: 003'te tanımlı değildi — matris uyumu için ekliyoruz
DROP POLICY IF EXISTS "sprint_veri_delete" ON sprint_veri;
CREATE POLICY "sprint_veri_delete"
  ON sprint_veri FOR DELETE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('sprint_veri', 'silme')
  );

-- ── sprint_is_plani ───────────────────────────────────────────
-- 020'de tanımlı: _yönetici + _gs rolleri. Bu policy'ler
-- güncel; sadece DELETE policy'sine permission OR-kontrolü ekleniyor.
-- INSERT ve UPDATE policy'leri (pkod bazlı kendi görevi) uyumunu
-- bozmamak için mevcut yapı korunuyor.
-- NOT: gs rol_kodu uyumu sağlamak için INSERT + UPDATE'e de eklendi.

DROP POLICY IF EXISTS "sprint_is_plani_insert" ON sprint_is_plani;
CREATE POLICY "sprint_is_plani_insert"
  ON sprint_is_plani FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) IN ('yönetici', 'gs')
    OR pkod = (SELECT pkod FROM personel WHERE auth_id = auth.uid())
    OR current_user_has_permission('sprint_is_plani', 'yazma')
  );

DROP POLICY IF EXISTS "sprint_is_plani_update" ON sprint_is_plani;
CREATE POLICY "sprint_is_plani_update"
  ON sprint_is_plani FOR UPDATE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR pkod = (SELECT pkod FROM personel WHERE auth_id = auth.uid())
    OR current_user_has_permission('sprint_is_plani', 'guncelleme')
  )
  WITH CHECK (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR pkod = (SELECT pkod FROM personel WHERE auth_id = auth.uid())
    OR current_user_has_permission('sprint_is_plani', 'guncelleme')
  );

-- sprint_is_plani_update_gs 020'den geliyor; OR-kontrolü ekliyoruz
DROP POLICY IF EXISTS "sprint_is_plani_update_gs" ON sprint_is_plani;
CREATE POLICY "sprint_is_plani_update_gs"
  ON sprint_is_plani FOR UPDATE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'gs'
    OR current_user_has_permission('sprint_is_plani', 'guncelleme')
  )
  WITH CHECK (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'gs'
    OR current_user_has_permission('sprint_is_plani', 'guncelleme')
  );

DROP POLICY IF EXISTS "sprint_is_plani_delete" ON sprint_is_plani;
CREATE POLICY "sprint_is_plani_delete"
  ON sprint_is_plani FOR DELETE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('sprint_is_plani', 'silme')
  );

-- ── sprint_retro ──────────────────────────────────────────────
-- 003'te: sprint_retro_insert (kendi adıyla), sprint_retro_select
-- UPDATE ve DELETE policy'si 003'te yok. Matris uyumu için ekliyoruz.
-- INSERT semantiği korunur: kendi adıyla VEYA permission matrisinden.

DROP POLICY IF EXISTS "sprint_retro_insert" ON sprint_retro;
CREATE POLICY "sprint_retro_insert"
  ON sprint_retro FOR INSERT TO authenticated
  WITH CHECK (
    pkod = (SELECT pkod FROM personel WHERE auth_id = auth.uid())
    OR (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('sprint_retro', 'yazma')
  );

-- UPDATE: retro kayıtlarını sadece yönetici veya permission ile değiştir
DROP POLICY IF EXISTS "sprint_retro_update" ON sprint_retro;
CREATE POLICY "sprint_retro_update"
  ON sprint_retro FOR UPDATE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('sprint_retro', 'guncelleme')
  )
  WITH CHECK (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('sprint_retro', 'guncelleme')
  );

-- DELETE: retro kayıtlarını sil
DROP POLICY IF EXISTS "sprint_retro_delete" ON sprint_retro;
CREATE POLICY "sprint_retro_delete"
  ON sprint_retro FOR DELETE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('sprint_retro', 'silme')
  );

-- ── sprint_perf_gos ───────────────────────────────────────────
-- 003'te: sprint_perf_gos_insert (authenticated herkese açık), _select
-- UPDATE ve DELETE policy'si 003'te yok.

DROP POLICY IF EXISTS "sprint_perf_gos_insert" ON sprint_perf_gos;
CREATE POLICY "sprint_perf_gos_insert"
  ON sprint_perf_gos FOR INSERT TO authenticated
  WITH CHECK (
    auth.role() = 'authenticated'
    OR current_user_has_permission('sprint_perf_gos', 'yazma')
  );

-- UPDATE: yönetici VEYA permission
DROP POLICY IF EXISTS "sprint_perf_gos_update" ON sprint_perf_gos;
CREATE POLICY "sprint_perf_gos_update"
  ON sprint_perf_gos FOR UPDATE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('sprint_perf_gos', 'guncelleme')
  )
  WITH CHECK (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('sprint_perf_gos', 'guncelleme')
  );

-- DELETE
DROP POLICY IF EXISTS "sprint_perf_gos_delete" ON sprint_perf_gos;
CREATE POLICY "sprint_perf_gos_delete"
  ON sprint_perf_gos FOR DELETE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('sprint_perf_gos', 'silme')
  );

-- ── anahtar_sonuclar ──────────────────────────────────────────
-- 003'te: _insert_fatih, _update_yonetici, _delete_yonetici

DROP POLICY IF EXISTS "anahtar_sonuclar_insert_fatih" ON anahtar_sonuclar;
CREATE POLICY "anahtar_sonuclar_insert_fatih"
  ON anahtar_sonuclar FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('anahtar_sonuclar', 'yazma')
  );

DROP POLICY IF EXISTS "anahtar_sonuclar_update_yonetici" ON anahtar_sonuclar;
CREATE POLICY "anahtar_sonuclar_update_yonetici"
  ON anahtar_sonuclar FOR UPDATE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('anahtar_sonuclar', 'guncelleme')
  )
  WITH CHECK (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('anahtar_sonuclar', 'guncelleme')
  );

DROP POLICY IF EXISTS "anahtar_sonuclar_delete_yonetici" ON anahtar_sonuclar;
CREATE POLICY "anahtar_sonuclar_delete_yonetici"
  ON anahtar_sonuclar FOR DELETE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('anahtar_sonuclar', 'silme')
  );

-- ── sop_birim ─────────────────────────────────────────────────
-- 023'te: sop_birim_modify (FOR ALL, yönetici-only EXISTS check)
-- S-003 kapsamında: permission matrisine bağlanmalı.
-- BONUS: 023'teki sop_birim_modify da FOR ALL — S-001/S-002 ile
-- aynı pattern; bu migration'da ayrık policy'lere bölünüyor.

DROP POLICY IF EXISTS "sop_birim_modify" ON sop_birim;

DROP POLICY IF EXISTS "sop_birim_insert" ON sop_birim;
CREATE POLICY "sop_birim_insert"
  ON sop_birim FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('sop_birim', 'yazma')
  );

DROP POLICY IF EXISTS "sop_birim_update" ON sop_birim;
CREATE POLICY "sop_birim_update"
  ON sop_birim FOR UPDATE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('sop_birim', 'guncelleme')
  )
  WITH CHECK (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('sop_birim', 'guncelleme')
  );

DROP POLICY IF EXISTS "sop_birim_delete" ON sop_birim;
CREATE POLICY "sop_birim_delete"
  ON sop_birim FOR DELETE TO authenticated
  USING (
    (SELECT rol_kodu FROM personel WHERE auth_id = auth.uid()) = 'yönetici'
    OR current_user_has_permission('sop_birim', 'silme')
  );

-- ============================================================
-- BÖLÜM 3: S-004 — sistem_grubu immutability trigger
-- Sistem gruplarının (sistem_grubu = TRUE) adı ve sistem_grubu
-- bayrağı DB seviyesinde değiştirilemez ve silinemez.
-- aciklama ve aktif alanları güncellemeye açık bırakılmıştır.
-- ============================================================

-- Önce temizle (idempotency)
DROP TRIGGER IF EXISTS trg_protect_sistem_grubu ON yetki_grubu;
DROP FUNCTION IF EXISTS fn_protect_sistem_grubu();

CREATE OR REPLACE FUNCTION fn_protect_sistem_grubu()
RETURNS TRIGGER AS $$
BEGIN
  -- DELETE: sistem grubu silinemez
  IF TG_OP = 'DELETE' AND OLD.sistem_grubu = TRUE THEN
    RAISE EXCEPTION
      'Sistem grubu "%" korumalıdır ve silinemez. sistem_grubu=FALSE yapıp silebilirsiniz.',
      OLD.ad
      USING ERRCODE = 'restrict_violation';
  END IF;

  -- UPDATE: sistem grubunun adı ve sistem_grubu bayrağı değiştirilemez
  -- aciklama ve aktif değiştirilebilir (kasıtlı — bkz. S-004 remediasyonu)
  IF TG_OP = 'UPDATE' AND OLD.sistem_grubu = TRUE THEN
    IF NEW.ad IS DISTINCT FROM OLD.ad THEN
      RAISE EXCEPTION
        'Sistem grubu "%" adı değiştirilemez.',
        OLD.ad
        USING ERRCODE = 'restrict_violation';
    END IF;
    IF NEW.sistem_grubu IS DISTINCT FROM OLD.sistem_grubu THEN
      RAISE EXCEPTION
        'Sistem grubu "%" için sistem_grubu bayrağı değiştirilemez.',
        OLD.ad
        USING ERRCODE = 'restrict_violation';
    END IF;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql
-- NOT: SECURITY DEFINER KULLANILMADI — trigger zaten BEFORE çalışır,
-- çağrıcı auth context korunmalı. Admin (service_role) bu trigger'ı atlatmak
-- isterse pg_trigger'ı devre dışı bırakması gerekir (kasıtlı — break-glass).
;

-- BEFORE trigger: DML'den önce çalışır, RETURN NULL ile iptal edilemez
-- (RETURN COALESCE(NEW,OLD) ile satır geçirir — RAISE EXCEPTION bloklar)
CREATE TRIGGER trg_protect_sistem_grubu
  BEFORE UPDATE OR DELETE ON yetki_grubu
  FOR EACH ROW EXECUTE FUNCTION fn_protect_sistem_grubu();

COMMENT ON FUNCTION fn_protect_sistem_grubu() IS
  'S-004: sistem_grubu=TRUE satırların ad ve sistem_grubu alanlarını korur; '
  'aciklama ve aktif değiştirilebilir. Trigger BEFORE UPDATE OR DELETE on yetki_grubu.';

-- ============================================================
-- BÖLÜM 4: S-017 — yetki_grubu tablosuna audit trigger ekle
-- 026'da personel_yetki_grubu ve yetki_grubu_tablo_izni zaten
-- loglanıyor; yetki_grubu'nun kendisi (CREATE/RENAME/DELETE)
-- loglanmıyordu.
-- ============================================================

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'fn_audit_log') THEN
    DROP TRIGGER IF EXISTS trg_audit_yetki_grubu ON yetki_grubu;
    CREATE TRIGGER trg_audit_yetki_grubu
      AFTER INSERT OR UPDATE OR DELETE ON yetki_grubu
      FOR EACH ROW EXECUTE FUNCTION fn_audit_log();
  ELSE
    RAISE WARNING
      'fn_audit_log() bulunamadı — 017_audit_log.sql uygulanmamış olabilir. '
      'yetki_grubu audit trigger oluşturulmadı; 017 uygulandıktan sonra bu '
      'migration''ı tekrar çalıştırın.';
  END IF;
END $$;

-- ============================================================
-- BÖLÜM 5: S-018 — yetki_grubu.ad case-insensitive UNIQUE index
-- Türkçe karakterlerde "Yönetici" ve "yönetici" iki ayrı kayıt
-- olabilir; LOWER() bazlı unique index ile engelleniyor.
--
-- ÖNCE KONTROL: varsa case-insensitive duplicate'leri tespit et
-- ve HATA fırlat (böyle veri olmamalı — ama güvenlik gereği).
-- ============================================================

DO $$
DECLARE
  dup_count INTEGER;
  dup_ornek TEXT;
BEGIN
  SELECT COUNT(*), MIN(lower_ad)
    INTO dup_count, dup_ornek
    FROM (
      SELECT LOWER(ad) AS lower_ad, COUNT(*) AS cnt
        FROM yetki_grubu
       GROUP BY LOWER(ad)
      HAVING COUNT(*) > 1
    ) sub;

  IF dup_count > 0 THEN
    RAISE EXCEPTION
      'yetki_grubu tablosunda case-insensitive duplicate ad tespit edildi '
      '(örnek: "%"). Önce duplikatları temizleyin.',
      dup_ornek
      USING ERRCODE = 'unique_violation';
  END IF;
END $$;

-- Mevcut case-sensitive UNIQUE constraint'i kaldır
-- (yetki_grubu.ad sütununda UNIQUE tanımlı — 024'te varchar UNIQUE)
-- Constraint adı PostgreSQL'de otomatik: yetki_grubu_ad_key
ALTER TABLE yetki_grubu DROP CONSTRAINT IF EXISTS yetki_grubu_ad_key;

-- Case-insensitive unique index oluştur
DROP INDEX IF EXISTS yetki_grubu_ad_ci_uniq;
CREATE UNIQUE INDEX yetki_grubu_ad_ci_uniq ON yetki_grubu (LOWER(ad));

COMMENT ON INDEX yetki_grubu_ad_ci_uniq IS
  'S-018: Türkçe karakterlerde case-insensitive tekil ad garantisi. '
  '"Yönetici" ve "yönetici" aynı anda var olamaz.';

-- ============================================================
-- DOĞRULAMA SORGULARI (yorum olarak — canlı DB''de çalıştırılabilir)
-- ============================================================
-- -- S-001/S-002: Ayrık policy'ler var mı?
-- SELECT policyname, cmd FROM pg_policies
--   WHERE tablename IN ('yetki_grubu','personel_yetki_grubu',
--                       'yetki_grubu_tablo_izni','yetki_tablo_katalog')
--     AND cmd IN ('INSERT','UPDATE','DELETE')
--   ORDER BY tablename, cmd;
-- → yetki_grubu_insert/update/delete, personel_yetki_grubu_insert/... vb.
--
-- -- S-003: 9 tabloda permission OR-kontrolü var mı?
-- SELECT policyname, tablename, cmd FROM pg_policies
--   WHERE tablename IN ('birimler','kategoriler','personel','sprint_veri',
--                       'sprint_is_plani','sprint_retro','sprint_perf_gos',
--                       'anahtar_sonuclar','sop_birim')
--     AND cmd IN ('INSERT','UPDATE','DELETE')
--   ORDER BY tablename, cmd;
--
-- -- S-004: Trigger var mı?
-- SELECT tgname, tgtype FROM pg_trigger
--   WHERE tgrelid = 'yetki_grubu'::regclass
--     AND tgname = 'trg_protect_sistem_grubu';
--
-- -- S-017: Audit trigger var mı?
-- SELECT tgname FROM pg_trigger
--   WHERE tgrelid = 'yetki_grubu'::regclass
--     AND tgname = 'trg_audit_yetki_grubu';
--
-- -- S-018: CI unique index var mı?
-- SELECT indexname FROM pg_indexes
--   WHERE tablename = 'yetki_grubu'
--     AND indexname = 'yetki_grubu_ad_ci_uniq';
--
-- -- Self-promotion engeli testi (non-admin olarak):
-- -- INSERT INTO personel_yetki_grubu (personel_pkod, yetki_grubu_id)
-- --   VALUES (auth.uid()::int, <yonetici_id>);
-- -- → "new row violates row-level security policy" döndürmeli

COMMIT;
