-- 026_sprint_perf_gos_rls.sql
-- sprint_perf_gos tablosuna UPDATE ve DELETE RLS politikaları ekle
-- Kök neden: Tablo için yalnızca SELECT ve INSERT politikaları mevcuttu;
--            UPDATE/DELETE yokken Supabase RLS sessizce 0 satır etkiler (hata vermez).

CREATE POLICY "sprint_perf_gos_update"
    ON sprint_perf_gos FOR UPDATE
    TO authenticated
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "sprint_perf_gos_delete"
    ON sprint_perf_gos FOR DELETE
    TO authenticated
    USING (auth.role() = 'authenticated');
