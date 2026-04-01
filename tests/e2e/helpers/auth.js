// ============================================================
// Supabase Mock Helper — Tüm E2E testler bu modülü kullanır
// ============================================================

const SUPABASE_URL = 'https://tjvpcivuanvqjyepmbyy.supabase.co'
const PROJECT_REF = 'tjvpcivuanvqjyepmbyy'
const STORAGE_KEY = `sb-${PROJECT_REF}-auth-token`

// ── Mock veri ────────────────────────────────────────────────

const MOCK_PERSONEL = [
  { pkod: 1, ad: 'Fatih', soyad: 'Özdamar', bkod: 1, rol_kodu: 'yönetici' }
]

const MOCK_SPRINT_VERI = [
  {
    sprint_donem: '2024-S1', sprint_adi: '1. Sprint',
    baslangic_t: '2024-01-01', bitis_t: '2024-01-21',
    izin: 0, saha: 0
  }
]

const MOCK_IS_PLANI = [
  {
    id: 1, sprint_donem: '2024-S1',
    sprint_faaliyetleri: 'Test Görevi 1', sno: null,
    plan_sure: 2, ekip_uyesi: 'Fatih', is_durum: null,
    guncel_tarih: null, guncelleyen: null, harcanan_butce: null,
    baslama_t: null, inceleme_t: null, tamamlanma_t: null, bitis_donem: null,
    pkod: 1, andaki_birim: 1
  },
  {
    id: 2, sprint_donem: '2024-S1',
    sprint_faaliyetleri: 'Test Görevi 2', sno: null,
    plan_sure: 1, ekip_uyesi: 'Fatih', is_durum: 'Başladı',
    guncel_tarih: null, guncelleyen: null, harcanan_butce: null,
    baslama_t: '2024-01-02', inceleme_t: null, tamamlanma_t: null, bitis_donem: null,
    pkod: 1, andaki_birim: 1
  },
  {
    id: 3, sprint_donem: '2024-S1',
    sprint_faaliyetleri: 'Test Görevi 3', sno: null,
    plan_sure: 3, ekip_uyesi: 'Fatih', is_durum: 'Tamamlandı',
    guncel_tarih: null, guncelleyen: null, harcanan_butce: 0,
    baslama_t: '2024-01-02', inceleme_t: '2024-01-05',
    tamamlanma_t: '2024-01-10', bitis_donem: '2024-S1',
    pkod: 1, andaki_birim: 1
  }
]

const MOCK_BIRIMLER = [
  { bkod: 1, birim_kisa: 'SKB', birim_adi: 'Sera Kıyı Birimi', durum: 'aktif' },
  { bkod: 2, birim_kisa: 'MEKB', birim_adi: 'Mekanik Birim', durum: 'aktif' }
]

const MOCK_SPRINT_OZET = [
  {
    sprint_donem: '2024-S1', sprint_adi: '1. Sprint',
    baslangic_t: '2024-01-01', bitis_t: '2024-01-21',
    t_skor: 4.5, gki: 98.5, hepiniss: 4.2,
    plan_toplam: 6, gerceklesen: 5, org_puan: 4.0
  }
]

// ── Sahte JWT ─────────────────────────────────────────────────
// Supabase JS istemcisi JWT imzasını doğrulamaz; exp alanı geleceğe ayarlı.

function buildFakeJwt() {
  const header = Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).toString('base64url')
  const payload = Buffer.from(JSON.stringify({
    sub: '00000000-0000-0000-0000-000000000001',
    email: 'fatih@tr90.gov.tr',
    role: 'authenticated',
    aud: 'authenticated',
    exp: 9999999999,
    iat: Math.floor(Date.now() / 1000),
  })).toString('base64url')
  return `${header}.${payload}.fakesignature`
}

const FAKE_JWT = buildFakeJwt()

const FAKE_USER = {
  id: '00000000-0000-0000-0000-000000000001',
  aud: 'authenticated',
  role: 'authenticated',
  email: 'fatih@tr90.gov.tr',
  email_confirmed_at: '2024-01-01T00:00:00.000000Z',
  confirmed_at: '2024-01-01T00:00:00.000000Z',
  last_sign_in_at: '2024-01-01T00:00:00.000000Z',
  app_metadata: { provider: 'email', providers: ['email'] },
  user_metadata: {},
  identities: [],
  created_at: '2024-01-01T00:00:00.000000Z',
  updated_at: '2024-01-01T00:00:00.000000Z',
}

const FAKE_SESSION = {
  access_token: FAKE_JWT,
  token_type: 'bearer',
  expires_in: 3600,
  expires_at: 9999999999,
  refresh_token: 'fake-refresh-token',
  user: FAKE_USER,
}

// ── URL yardımcıları ─────────────────────────────────────────

function isAuthUrl(url) {
  return url.includes(`${PROJECT_REF}.supabase.co/auth/v1`)
}

function isRestUrl(url) {
  return url.includes(`${PROJECT_REF}.supabase.co/rest/v1`)
}

// ── Ana mock fonksiyonu ───────────────────────────────────────

/**
 * Korumalı sayfalara erişim için Supabase oturumunu ve API çağrılarını mocklar.
 * page.goto() çağrısından ÖNCE çağrılmalıdır.
 *
 * @param {import('@playwright/test').Page} page
 */
async function mockSupabase(page) {
  // 1. Oturumu localStorage'a enjekte et (page yüklenmeden önce çalışır)
  const sessionJson = JSON.stringify(FAKE_SESSION)
  await page.addInitScript(({ key, val }) => {
    localStorage.setItem(key, val)
  }, { key: STORAGE_KEY, val: sessionJson })

  // 2. Auth API çağrılarını yakala (function predicate — en güvenilir yöntem)
  await page.route(
    (url) => isAuthUrl(url.toString()),
    async (route) => {
      const url = route.request().url()
      if (url.includes('/token')) {
        return route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify(FAKE_SESSION),
        })
      }
      if (url.includes('/user')) {
        return route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify(FAKE_USER),
        })
      }
      return route.fulfill({ status: 200, contentType: 'application/json', body: '{}' })
    }
  )

  // 3. REST API çağrılarını yakala (function predicate)
  await page.route(
    (url) => isRestUrl(url.toString()),
    async (route) => {
      const url = route.request().url()
      const method = route.request().method()

      if (url.includes('/personel')) {
        return route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify(MOCK_PERSONEL),
        })
      }
      if (url.includes('/birimler')) {
        return route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify(MOCK_BIRIMLER),
        })
      }
      if (url.includes('/sprint_veri')) {
        if (method === 'PATCH' || method === 'POST') {
          return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(MOCK_SPRINT_VERI[0]) })
        }
        return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(MOCK_SPRINT_VERI) })
      }
      if (url.includes('/sprint_is_plani')) {
        if (method === 'PATCH') {
          return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(MOCK_IS_PLANI[0]) })
        }
        if (method === 'POST') {
          return route.fulfill({ status: 201, contentType: 'application/json', body: JSON.stringify({ ...MOCK_IS_PLANI[0], id: 99 }) })
        }
        if (method === 'DELETE') {
          return route.fulfill({ status: 204, body: '' })
        }
        return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(MOCK_IS_PLANI) })
      }
      if (url.includes('/v_sprint_ozet')) {
        return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(MOCK_SPRINT_OZET) })
      }
      // Bilinmeyen tablolar
      if (method === 'GET') {
        return route.fulfill({ status: 200, contentType: 'application/json', body: '[]' })
      }
      return route.fulfill({ status: 200, contentType: 'application/json', body: '{}' })
    }
  )
}

module.exports = {
  mockSupabase,
  FAKE_SESSION,
  FAKE_USER,
  MOCK_IS_PLANI,
  MOCK_SPRINT_VERI,
  MOCK_PERSONEL,
  MOCK_BIRIMLER,
  SUPABASE_URL,
  isAuthUrl,
  isRestUrl,
}
