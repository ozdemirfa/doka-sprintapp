-- ============================================================
-- Migration 009: aort Backfill + Bug Fixes
-- UTF-8 | DOKA Sprint Kanban
-- Tarih: 2026-03-28
-- ============================================================

-- sprint_retro.aort backfill: 007 trigger mevcut kayıtlar için çalışmadı
UPDATE sprint_retro
SET aort = (ajanstaki_rolu + ajans_hakkinda) / 2.0
WHERE aort IS NULL
  AND ajanstaki_rolu IS NOT NULL
  AND ajans_hakkinda IS NOT NULL;
