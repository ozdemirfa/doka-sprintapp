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

// ── Permission-aware mock fonksiyonu ─────────────────────────

/**
 * Belirtilen fixture profiline göre Supabase auth + REST isteklerini mocklar.
 * Yetki testleri için `mockSupabase` yerine bu fonksiyon kullanılır.
 *
 * @param {import('@playwright/test').Page} page
 * @param {object} fixture — FIXTURES[key] nesnesi (permissions-fixtures.js)
 * @param {object} [opts]
 * @param {boolean} [opts.rejectForbiddenMutations=false] — true ise POST/PATCH/DELETE için 403 döndürür
 */
async function mockSupabaseWithPermissions(page, fixture, opts = {}) {
  const { rejectForbiddenMutations = false } = opts

  // Fixture'dan fake user oluştur
  const fixtureUser = {
    ...FAKE_USER,
    id: fixture.userId || FAKE_USER.id,
    email: fixture.email || FAKE_USER.email,
  }

  const fixtureJwt = buildFakeJwt()

  const fixtureSession = {
    ...FAKE_SESSION,
    access_token: fixtureJwt,
    user: fixtureUser,
  }

  const fixturePersonel = [{
    pkod: fixture.pkod || 1,
    ad: 'Test',
    soyad: 'Kullanici',
    bkod: 1,
    rol_kodu: fixture.rolKodu || 'standart',
    durum: 'aktif',
  }]

  // localStorage'a oturum enjekte et
  const sessionJson = JSON.stringify(fixtureSession)
  await page.addInitScript(({ key, val }) => {
    localStorage.setItem(key, val)
  }, { key: STORAGE_KEY, val: sessionJson })

  // Auth API istekleri
  await page.route(
    (url) => isAuthUrl(url.toString()),
    async (route) => {
      const url = route.request().url()
      if (url.includes('/token')) {
        return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(fixtureSession) })
      }
      if (url.includes('/user')) {
        return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(fixtureUser) })
      }
      return route.fulfill({ status: 200, contentType: 'application/json', body: '{}' })
    }
  )

  // REST API istekleri
  await page.route(
    (url) => isRestUrl(url.toString()),
    async (route) => {
      const url = route.request().url()
      const method = route.request().method()

      // Yetki tabloları — fixture verisini döndür
      if (url.includes('/yetki_grubu')) {
        if (rejectForbiddenMutations && (method === 'POST' || method === 'PATCH' || method === 'DELETE')) {
          return route.fulfill({ status: 403, contentType: 'application/json', body: JSON.stringify({ message: 'new row violates row-level security policy' }) })
        }
        return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(fixture.groupRows || []) })
      }

      if (url.includes('/personel_yetki_grubu')) {
        if (rejectForbiddenMutations && method === 'POST') {
          return route.fulfill({ status: 403, contentType: 'application/json', body: JSON.stringify({ message: 'new row violates row-level security policy' }) })
        }
        return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(fixture.membershipRows || []) })
      }

      if (url.includes('/yetki_grubu_tablo_izni')) {
        if (rejectForbiddenMutations && (method === 'POST' || method === 'PATCH' || method === 'DELETE')) {
          return route.fulfill({ status: 403, contentType: 'application/json', body: JSON.stringify({ message: 'new row violates row-level security policy' }) })
        }
        return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(fixture.permRows || []) })
      }

      if (url.includes('/yetki_tablo_katalog')) {
        // İzin matrisi kataloğu — sabit liste döndür
        const katalog = [
          { id: 1, tablo_adi: 'sprint_is_plani', goruntu_adi: 'Sprint İş Planı', kategori: 'Planlama', aciklama: '', sira: 1 },
          { id: 2, tablo_adi: 'faaliyet', goruntu_adi: 'Faaliyetler', kategori: 'Planlama', aciklama: '', sira: 2 },
          { id: 3, tablo_adi: 'alt_faaliyet', goruntu_adi: 'Alt Faaliyetler', kategori: 'Planlama', aciklama: '', sira: 3 },
          { id: 4, tablo_adi: 'sop', goruntu_adi: 'SOP\'lar', kategori: 'Konfigürasyon', aciklama: '', sira: 4 },
          { id: 5, tablo_adi: 'kategori', goruntu_adi: 'Kategoriler', kategori: 'Konfigürasyon', aciklama: '', sira: 5 },
          { id: 6, tablo_adi: 'harcama', goruntu_adi: 'Harcamalar', kategori: 'Finans', aciklama: '', sira: 6 },
          { id: 7, tablo_adi: 'izin', goruntu_adi: 'İzinler', kategori: 'İnsan Kaynakları', aciklama: '', sira: 7 },
          { id: 8, tablo_adi: 'personel', goruntu_adi: 'Personel', kategori: 'İnsan Kaynakları', aciklama: '', sira: 8 },
          { id: 9, tablo_adi: 'birim', goruntu_adi: 'Birimler', kategori: 'Organizasyon', aciklama: '', sira: 9 },
        ]
        return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(katalog) })
      }

      // Personel
      if (url.includes('/personel')) {
        return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(fixturePersonel) })
      }

      // Birimler
      if (url.includes('/birimler')) {
        return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(MOCK_BIRIMLER) })
      }

      // Sprint verileri
      if (url.includes('/sprint_veri')) {
        if (method === 'PATCH' || method === 'POST') {
          return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(MOCK_SPRINT_VERI[0]) })
        }
        return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(MOCK_SPRINT_VERI) })
      }

      if (url.includes('/sprint_is_plani')) {
        if (method === 'PATCH') return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(MOCK_IS_PLANI[0]) })
        if (method === 'POST') return route.fulfill({ status: 201, contentType: 'application/json', body: JSON.stringify({ ...MOCK_IS_PLANI[0], id: 99 }) })
        if (method === 'DELETE') return route.fulfill({ status: 204, body: '' })
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
  mockSupabaseWithPermissions,
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
