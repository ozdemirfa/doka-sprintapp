Agent: sql-agent
Görev: Reviewer bulgularına göre SQL düzeltmeleri
Durum: TAMAMLANDI
Sonraki adım: Frontend ajanı kendi review bulgularını düzeltmeli (frontend-review.md)
---

## Yapılan Düzeltmeler

### 001_schema.sql

1. **bitis_donem FK kısıtı eklendi** (satır 182)
   - Önceki: `bitis_donem INTEGER,`
   - Sonraki: `bitis_donem INTEGER REFERENCES sprint_veri(sprint_donem),`
   - Etki: Orphan kayıt oluşması artık DB seviyesinde engellenir.

2. **guncel_tarih ve guncelleyen DEFAULT değerleri eklendi** (satır 194-195)
   - Önceki: `guncel_tarih DATE`, `guncelleyen VARCHAR(50)`
   - Sonraki: `guncel_tarih DATE DEFAULT NOW()::DATE`, `guncelleyen VARCHAR(50) DEFAULT ''`
   - Etki: Initial INSERT sonrası audit sütunları NULL kalmaz; trigger UPDATE'de üzerine yazar.

### 003_rls.sql

3. **anahtar_sonuclar UPDATE ve DELETE politikaları eklendi** (satır 218 sonrası)
   - `anahtar_sonuclar_update_yonetici`: rol_kodu='yönetici' kontrolü
   - `anahtar_sonuclar_delete_yonetici`: rol_kodu='yönetici' kontrolü
   - Etki: Yönetici artık anahtar sonuçları düzenleyip silebilir (RLS default-deny engeli kalktı).

4. **sprint_is_plani_update politika yorumu netleştirildi**
   - Rol bazlı kontrol (`rol_kodu='yönetici'`) spec'teki isim bazlı ifadeden daha sağlıklı.
   - Yorum güncellendi: "yönetici rolündeki kullanıcı (Scrum Master)"
   - Tasarım kararı: Seed'de yalnızca Fatih yöneticidir; ileride başka Scrum Master atanırsa rol güncellemesi yeterli.
