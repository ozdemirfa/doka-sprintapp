// ============================================================
// Performans Özeti (perf-ozet.html) E2E testleri
// perf_gostergeler tablosu: tablo başlıkları, SOP filtre
// ============================================================
const { test, expect } = require('@playwright/test')
const { mockSupabase } = require('./helpers/auth')

const MOCK_PERF_GOSTERGELER = [
  {
    cg_kod: 'CG-01',
    sop: 'SOP-1',
    bilesen_kodu: 'B-01',
    bilesen_adi: 'Bileşen 1',
    cikti_gostergesi: 'Test Çıktı Göstergesi',
    birim: 'Adet',
    hedef: 100,
    tamamlanma_donemi: '2026/1',
    katki_sonuc_gostergesi: 'Sonuç 1',
    hedef_2024: 30,
    hedef_2025: 40,
    hedef_2026: 30,
    gerceklesen_2024: 25,
    gerceklesen_2025: 35,
    gerceklesen_2026: 10
  }
]

test.describe('Perf Ozet: Sayfa Yüklenmesi', () => {
  test('sayfa JS hatası olmadan yüklenmeli', async ({ page }) => {
    const errors = []
    page.on('pageerror', (err) => errors.push(err.message))
    await mockSupabase(page)
    await page.goto('/pages/perf-ozet.html')
    await page.waitForSelector('.main-content', { timeout: 10000 })
    await page.waitForTimeout(1000)

    const criticalErrors = errors.filter(e =>
      !e.includes('WebSocket') && !e.includes('realtime') && !e.includes('net::ERR')
    )
    expect(criticalErrors).toHaveLength(0)
  })

  test('ana içerik alanı görünmeli', async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/perf-ozet.html')
    await expect(page.locator('.main-content')).toBeVisible()
  })
})

test.describe('Perf Ozet: Tablo Başlıkları', () => {
  test.beforeEach(async ({ page }) => {
    await mockSupabase(page)

    // perf_gostergeler için özel mock — mockSupabase'den sonra LIFO olarak önceliklidir
    await page.route(
      (url) => url.toString().includes('/rest/v1/perf_gostergeler'),
      (route) => route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(MOCK_PERF_GOSTERGELER)
      })
    )

    await page.goto('/pages/perf-ozet.html')
    // perf-ozet.html'de tablo statik HTML'de var — auth bitmeden görünür
    await page.waitForSelector('.perf-table', { timeout: 10000 })
  })

  test('"ÇG Kodu" başlığı tabloda mevcut olmalı', async ({ page }) => {
    const headers = await page.locator('.perf-table th').allTextContents()
    const normalized = headers.map(h => h.trim())
    expect(normalized.some(h => h.includes('ÇG Kodu'))).toBe(true)
  })

  test('"SOP" başlığı tabloda mevcut olmalı', async ({ page }) => {
    const headers = await page.locator('.perf-table th').allTextContents()
    const normalized = headers.map(h => h.trim())
    expect(normalized.some(h => h.includes('SOP'))).toBe(true)
  })

  test('"Çıktı Göstergesi" başlığı tabloda mevcut olmalı', async ({ page }) => {
    const headers = await page.locator('.perf-table th').allTextContents()
    const normalized = headers.map(h => h.trim())
    expect(normalized.some(h => h.includes('Çıktı Göstergesi'))).toBe(true)
  })

  test('"Hedef" başlığı tabloda mevcut olmalı', async ({ page }) => {
    const headers = await page.locator('.perf-table th').allTextContents()
    const normalized = headers.map(h => h.trim())
    expect(normalized.some(h => h.includes('Hedef'))).toBe(true)
  })

  test('"Birim" başlığı tabloda mevcut olmalı', async ({ page }) => {
    const headers = await page.locator('.perf-table th').allTextContents()
    const normalized = headers.map(h => h.trim())
    expect(normalized.some(h => h.includes('Birim'))).toBe(true)
  })

  test('tablo en az 10 sütun başlığı içermeli', async ({ page }) => {
    const count = await page.locator('.perf-table th').count()
    expect(count).toBeGreaterThanOrEqual(10)
  })
})

test.describe('Perf Ozet: SOP Filtresi', () => {
  test('SOP filtre dropdown görünmeli', async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/perf-ozet.html')
    await page.waitForSelector('#filter-sop', { timeout: 10000 })
    await expect(page.locator('#filter-sop')).toBeVisible()
  })

  test('mock veriyle SOP filtre dropdown dolu olmalı', async ({ page }) => {
    await mockSupabase(page)

    await page.route(
      (url) => url.toString().includes('/rest/v1/perf_gostergeler'),
      (route) => route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(MOCK_PERF_GOSTERGELER)
      })
    )

    await page.goto('/pages/perf-ozet.html')
    await page.waitForSelector('#filter-sop', { timeout: 10000 })

    // loadData() SOP'ları dropdown'a ekliyor — "Tüm SOPlar" + en az 1 kayıt
    await page.waitForFunction(
      () => {
        const sel = document.getElementById('filter-sop')
        return sel && sel.options.length > 1
      },
      { timeout: 8000 }
    )

    const count = await page.locator('#filter-sop option').count()
    expect(count).toBeGreaterThan(1)
  })

  test('SOP filtresi değişince tablo hata vermemeli', async ({ page }) => {
    const errors = []
    page.on('pageerror', (err) => errors.push(err.message))

    await mockSupabase(page)
    await page.route(
      (url) => url.toString().includes('/rest/v1/perf_gostergeler'),
      (route) => route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(MOCK_PERF_GOSTERGELER)
      })
    )

    await page.goto('/pages/perf-ozet.html')
    await page.waitForSelector('#filter-sop', { timeout: 10000 })

    const optCount = await page.locator('#filter-sop option').count()
    if (optCount > 1) {
      await page.locator('#filter-sop').selectOption({ index: 1 })
      await page.waitForTimeout(500)
    }

    const criticalErrors = errors.filter(e =>
      !e.includes('WebSocket') && !e.includes('realtime') && !e.includes('net::ERR')
    )
    expect(criticalErrors).toHaveLength(0)
  })
})

test.describe('Perf Ozet: Tablo Verisi', () => {
  test('mock veriyle tablo satırları render edilmeli', async ({ page }) => {
    await mockSupabase(page)

    await page.route(
      (url) => url.toString().includes('/rest/v1/perf_gostergeler'),
      (route) => route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(MOCK_PERF_GOSTERGELER)
      })
    )

    await page.goto('/pages/perf-ozet.html')
    await page.waitForSelector('#perf-ozet-tbody', { timeout: 10000 })

    await page.waitForFunction(
      () => {
        const tbody = document.getElementById('perf-ozet-tbody')
        return tbody && tbody.querySelectorAll('tr').length > 0 &&
          !tbody.textContent.includes('Yükleniyor')
      },
      { timeout: 8000 }
    )

    const rows = await page.locator('#perf-ozet-tbody tr').count()
    expect(rows).toBeGreaterThan(0)
  })
})
