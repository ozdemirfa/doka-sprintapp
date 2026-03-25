# Agent Team — Proje Kural Seti

## Bu proje nedir?
Bu proje, Claude Code ile yönetilen çok ajanlı bir full-stack geliştirme takımıdır.
Her ajan kendi sorumluluk alanında çalışır; Orchestrator görevi dağıtır ve koordine eder.

## Klasör yapısı

```
/
├── CLAUDE.md              ← Bu dosya (proje kuralları)
├── agents/                ← Her ajanın sistem promptu
│   ├── orchestrator.md
│   ├── pm.md
│   ├── sql.md             ← Supabase SQL ajanı (schema, views, RLS, triggers, seed)
│   ├── frontend.md
│   ├── reviewer.md
│   └── qa.md
├── output/                ← Ajanlar arası handoff dosyaları
│   ├── spec.md            ← PM → SQL + Frontend handoff
│   ├── sql/               ← SQL ajanı çıktıları
│   ├── frontend/          ← Frontend ajanı çıktıları
│   └── reviews/           ← Reviewer raporları
├── inputs/                ← Kullanıcı girdileri
│   └── requirements.md
├── src/                   ← Asıl kaynak kodu (statik site)
│   ├── index.html
│   ├── login.html
│   ├── pages/
│   ├── js/
│   ├── css/
│   └── sql/               ← SQL migration dosyaları
├── .env                   ← Supabase credentials (git'e eklenmez)
├── .env.example           ← Şablon
└── run.sh                 ← Takımı başlatan script
```

## Genel kurallar (tüm ajanlar için)

1. Her ajan görevini tamamlayınca `output/` altına sonucunu yazar.
2. Bir sonraki ajan çalışmadan önce öncekinin output'unu okur.
3. Hata durumunda orchestrator'a geri bildirir, kendi başına varsayım yapmaz.
4. Kod değişiklikleri her zaman `src/` altına yazılır.
5. Dosya silme işlemi yapmadan önce orchestrator onayı gerekir.

## Teknoloji stack

- Frontend: Vanilla HTML5 + CSS3 + JavaScript (ES Modules)
- CSS: Tailwind CSS (CDN)
- Drag & Drop: SortableJS (CDN)
- Grafikler: Chart.js (CDN)
- Backend/Auth/Realtime: Supabase
- Database: PostgreSQL (Supabase üzerinde)
- Supabase JS: CDN ESM import
- Test: Playwright (E2E)
- Deploy: GitHub Pages veya Vercel (statik site, build adımı yok)

## İletişim formatı

Her ajan output dosyasının başına şu başlığı yazar:
```
Agent: <ajan-adı>
Görev: <görev-özeti>
Durum: TAMAMLANDI | BEKLEMEDE | HATA
Sonraki adım: <orchestrator için yönlendirme>
---
```
