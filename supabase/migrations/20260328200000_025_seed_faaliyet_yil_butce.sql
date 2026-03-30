-- 025_seed_faaliyet_yil_butce.sql
-- inputs/faaliyet_yil_butce.csv → faaliyet_yil_butce

BEGIN;

INSERT INTO faaliyet_yil_butce (faaliyet_id, yil, butce)
VALUES
  ((SELECT id FROM faaliyetler WHERE fkod = 'ABP601'), 2026, 0),
  ((SELECT id FROM faaliyetler WHERE fkod = 'BAK601'), 2026, 0),
  ((SELECT id FROM faaliyetler WHERE fkod = 'KDU101'), 2026, 0),
  ((SELECT id FROM faaliyetler WHERE fkod = 'KDU103'), 2026, 1000000),
  ((SELECT id FROM faaliyetler WHERE fkod = 'KDU108'), 2026, 5000000),
  ((SELECT id FROM faaliyetler WHERE fkod = 'KDU204'), 2026, 0),
  ((SELECT id FROM faaliyetler WHERE fkod = 'KDU205'), 2026, 500000),
  ((SELECT id FROM faaliyetler WHERE fkod = 'KDU301'), 2026, 2000000),
  ((SELECT id FROM faaliyetler WHERE fkod = 'KDU302'), 2026, 1000000),
  ((SELECT id FROM faaliyetler WHERE fkod = 'KDU304'), 2026, 3000000),
  ((SELECT id FROM faaliyetler WHERE fkod = 'KDU305'), 2026, 2000000),
  ((SELECT id FROM faaliyetler WHERE fkod = 'KDU406'), 2026, 2000000),
  ((SELECT id FROM faaliyetler WHERE fkod = 'KDU407'), 2026, 500000),
  ((SELECT id FROM faaliyetler WHERE fkod = 'KDU501'), 2026, 20000000),
  ((SELECT id FROM faaliyetler WHERE fkod = 'SOG601'), 2026, 40000000),
  ((SELECT id FROM faaliyetler WHERE fkod = 'SDD601'), 2026, 0),
  ((SELECT id FROM faaliyetler WHERE fkod = 'STU101'), 2026, 14000000.00),
  ((SELECT id FROM faaliyetler WHERE fkod = 'STU102'), 2026, 2000000),
  ((SELECT id FROM faaliyetler WHERE fkod = 'STU103'), 2026, 11000000),
  ((SELECT id FROM faaliyetler WHERE fkod = 'STU104'), 2026, 10000000),
  ((SELECT id FROM faaliyetler WHERE fkod = 'STU201'), 2026, 4000000),
  ((SELECT id FROM faaliyetler WHERE fkod = 'STU301'), 2026, 1000000),
  ((SELECT id FROM faaliyetler WHERE fkod = 'STU302'), 2026, 1000000),
  ((SELECT id FROM faaliyetler WHERE fkod = 'STU401'), 2026, 3000000),
  ((SELECT id FROM faaliyetler WHERE fkod = 'STU402'), 2026, 7000000),
  ((SELECT id FROM faaliyetler WHERE fkod = 'STU403'), 2026, 3000000),
  ((SELECT id FROM faaliyetler WHERE fkod = 'STU404'), 2026, 2000000),
  ((SELECT id FROM faaliyetler WHERE fkod = 'STU405'), 2026, 2000000),
  ((SELECT id FROM faaliyetler WHERE fkod = 'STU501'), 2026, 10000000),
  ((SELECT id FROM faaliyetler WHERE fkod = 'STU502'), 2026, 0)
ON CONFLICT (faaliyet_id, yil) DO UPDATE SET
  butce = EXCLUDED.butce;

COMMIT;
