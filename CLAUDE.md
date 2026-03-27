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

<!-- VERCEL BEST PRACTICES START -->
## Best practices for developing on Vercel

These defaults are optimized for AI coding agents (and humans) working on apps that deploy to Vercel.

- Treat Vercel Functions as stateless + ephemeral (no durable RAM/FS, no background daemons), use Blob or marketplace integrations for preserving state
- Edge Functions (standalone) are deprecated; prefer Vercel Functions
- Don't start new projects on Vercel KV/Postgres (both discontinued); use Marketplace Redis/Postgres instead
- Store secrets in Vercel Env Variables; not in git or `NEXT_PUBLIC_*`
- Provision Marketplace native integrations with `vercel integration add` (CI/agent-friendly)
- Sync env + project settings with `vercel env pull` / `vercel pull` when you need local/offline parity
- Use `waitUntil` for post-response work; avoid the deprecated Function `context` parameter
- Set Function regions near your primary data source; avoid cross-region DB/service roundtrips
- Tune Fluid Compute knobs (e.g., `maxDuration`, memory/CPU) for long I/O-heavy calls (LLMs, APIs)
- Use Runtime Cache for fast **regional** caching + tag invalidation (don't treat it as global KV)
- Use Cron Jobs for schedules; cron runs in UTC and triggers your production URL via HTTP GET
- Use Vercel Blob for uploads/media; Use Edge Config for small, globally-read config
- If Enable Deployment Protection is enabled, use a bypass secret to directly access them
- Add OpenTelemetry via `@vercel/otel` on Node; don't expect OTEL support on the Edge runtime
- Enable Web Analytics + Speed Insights early
- Use AI Gateway for model routing, set AI_GATEWAY_API_KEY, using a model string (e.g. 'anthropic/claude-sonnet-4.6'), Gateway is already default in AI SDK
  needed. Always curl https://ai-gateway.vercel.sh/v1/models first; never trust model IDs from memory
- For durable agent loops or untrusted code: use Workflow (pause/resume/state) + Sandbox; use Vercel MCP for secure infra access
<!-- VERCEL BEST PRACTICES END -->
