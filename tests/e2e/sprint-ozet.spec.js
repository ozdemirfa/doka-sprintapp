// ============================================================
// US-4: Sprint Özet & GKİ Grafikleri
// Scrum Master sprint metriklerini grafik olarak görmelidir.
// ============================================================
const { test, expect } = require('@playwright/test')
const { mockSupabase } = require('./helpers/auth')

test.describe('US-4: Sprint Özet sayfası', () => {
  test.beforeEach(async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/sprint-ozet.html')
    // Auth + veri yüklendikten sonra user-name güncellenir
    await page.waitForFunction(
      () => { const el = document.getElementById('user-name'); return el && el.textContent !== 'Yükleniyor...' },
      { timeout: 15000 }
    )
  })

  test('sayfa "Chart is not defined" hatası vermeden yüklenmeli', async ({ page }) => {
    // US-4: Chart.js import eksikliği düzeltildi — runtime hatası olmamalı
    const errors = []
    page.on('pageerror', (err) => errors.push(err.message))
    await page.waitForTimeout(2000)
    const chartErrors = errors.filter(e => e.includes('Chart is not defined'))
    expect(chartErrors).toHaveLength(0)
  })

  test('GKİ ve Hepiniss canvas elementleri DOM\'da mevcut olmalı', async ({ page }) => {
    // US-4: 3 grafik canvas elementi bulunmalı (GKİ+Hepiniss birleşik tek canvas)
    await expect(page.locator('#chart-gki-hepiniss')).toBeVisible()
    await expect(page.locator('#chart-plan')).toBeVisible()
    await expect(page.locator('#chart-org')).toBeVisible()
  })

  test('GKİ metrik kartı render olmalı', async ({ page }) => {
    // US-4: GKİ değeri gösterilmeli (mock: 98.5)
    await expect(page.locator('#metric-gki')).toBeVisible()
  })

  test('Hepiniss metrik kartı render olmalı', async ({ page }) => {
    // US-4: Hepiniss GEOMEAN değeri gösterilmeli (mock: 4.2)
    await expect(page.locator('#metric-hepiniss')).toBeVisible()
  })

  test('Plan Toplam metrik kartı render olmalı', async ({ page }) => {
    // US-4: Plan/Gerçekleşme değerleri gösterilmeli
    await expect(page.locator('#metric-plan')).toBeVisible()
  })

  test('sprint karşılaştırma tablosu render olmalı', async ({ page }) => {
    // US-4: Sprint karşılaştırma metrikleri tablo yapısında listelenir
    await expect(page.locator('#sprint-table')).toBeVisible()
  })

  test('sprint filtresi dropdown\'ı mevcut olmalı', async ({ page }) => {
    // US-4: Sprint dropdown sprint_veri'den beslenir
    await expect(page.locator('#filter-sprint')).toBeVisible()
  })

  test('birim filtresi dropdown\'ı mevcut olmalı', async ({ page }) => {
    // Sprint Özet'e de birim bazlı filtre eklendi (loadBirimData ile hesaplama)
    await expect(page.locator('#filter-birim')).toBeVisible()
  })
})
