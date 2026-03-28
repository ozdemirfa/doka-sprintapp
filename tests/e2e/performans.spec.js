// ============================================================
// Performans sayfası E2E testleri
// v_perf_gosterge_ozet tablosu, filtreler, tablo görünümü
// ============================================================
const { test, expect } = require('@playwright/test')
const { mockSupabase } = require('./helpers/auth')

test.describe('Performans: Sayfa Yüklenmesi', () => {
  test('performans sayfası JS hatası olmadan yüklenmeli', async ({ page }) => {
    const errors = []
    page.on('pageerror', (err) => errors.push(err.message))
    await mockSupabase(page)
    await page.goto('/pages/performans.html')
    await page.waitForSelector('.main-content', { timeout: 10000 })
    await page.waitForTimeout(1000)

    const criticalErrors = errors.filter(e =>
      !e.includes('WebSocket') && !e.includes('realtime') && !e.includes('net::ERR') &&
      !e.includes('getChart')  // Chart.js CDN test ortamında tam yüklenemeyebilir
    )
    expect(criticalErrors).toHaveLength(0)
  })

  test('sayfa başlığı "Performans" içermeli', async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/performans.html')
    await page.waitForSelector('.main-content', { timeout: 10000 })
    await expect(page.locator('h2')).toContainText('Performans')
  })

  test('ana içerik alanı görünmeli', async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/performans.html')
    await expect(page.locator('.main-content')).toBeVisible()
  })
})

test.describe('Performans: Filtreler', () => {
  test.beforeEach(async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/performans.html')
    await page.waitForSelector('#filter-sop', { timeout: 10000 })
  })

  test('SOP filtre dropdown görünmeli', async ({ page }) => {
    await expect(page.locator('#filter-sop')).toBeVisible()
  })

  test('yıl filtre dropdown görünmeli', async ({ page }) => {
    await expect(page.locator('#filter-yil')).toBeVisible()
  })

  test('yıl filtre dropdown "Tüm Yıllar" seçeneği içermeli', async ({ page }) => {
    // Yıl seçenekleri soplar verisinden dinamik doluyor; mock [] döndürüyor
    // Bu nedenle sadece "Tüm Yıllar" varsayılan seçenek test edilir
    const firstOption = page.locator('#filter-yil option').first()
    await expect(firstOption).toBeAttached()
    const text = await firstOption.textContent()
    expect(text).toMatch(/Tüm/)
  })

  test('SOP filtre değişince sayfa hata vermemeli', async ({ page }) => {
    const errors = []
    page.on('pageerror', (err) => errors.push(err.message))
    await page.locator('#filter-sop').selectOption({ index: 0 })
    await page.waitForTimeout(500)
    const criticalErrors = errors.filter(e =>
      !e.includes('WebSocket') && !e.includes('realtime') && !e.includes('net::ERR') &&
      !e.includes('getChart')
    )
    expect(criticalErrors).toHaveLength(0)
  })

  test('yıl filtresi varsayılan seçenekle sayfa hata vermemeli', async ({ page }) => {
    const errors = []
    page.on('pageerror', (err) => errors.push(err.message))
    // Mock [] döndüğünden yıl seçenekleri boş; varsayılan (index 0) seçilir
    await page.locator('#filter-yil').selectOption({ index: 0 })
    await page.waitForTimeout(500)
    const criticalErrors = errors.filter(e =>
      !e.includes('WebSocket') && !e.includes('realtime') && !e.includes('net::ERR') &&
      !e.includes('getChart')
    )
    expect(criticalErrors).toHaveLength(0)
  })
})

test.describe('Performans: Tablo', () => {
  test.beforeEach(async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/performans.html')
    await page.waitForSelector('#perf-tbody', { timeout: 10000 })
  })

  test('performans tablosu mevcut olmalı', async ({ page }) => {
    await expect(page.locator('#perf-tbody')).toBeAttached()
  })

  test('veri yokken tablo boş kalmalı ve hata vermemeli', async ({ page }) => {
    // Mock [] dönüyor — tablo boş render edilmeli, crash olmamalı
    const errors = []
    page.on('pageerror', (err) => errors.push(err.message))
    await page.waitForTimeout(1000)
    const criticalErrors = errors.filter(e =>
      !e.includes('WebSocket') && !e.includes('realtime') && !e.includes('net::ERR')
    )
    expect(criticalErrors).toHaveLength(0)
  })
})
