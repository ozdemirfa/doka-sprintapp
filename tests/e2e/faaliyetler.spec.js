// ============================================================
// Faaliyetler sayfası E2E testleri
// Accordion listesi, SOP filtresi, faaliyet + alt faaliyet modalları
// ============================================================
const { test, expect } = require('@playwright/test')
const { mockSupabase } = require('./helpers/auth')

test.describe('Faaliyetler: Sayfa Yüklenmesi', () => {
  test('faaliyetler sayfası JS hatası olmadan yüklenmeli', async ({ page }) => {
    const errors = []
    page.on('pageerror', (err) => errors.push(err.message))
    await mockSupabase(page)
    await page.goto('/pages/faaliyetler.html')
    await page.waitForSelector('#faaliyetler-container', { timeout: 10000 })
    await page.waitForTimeout(1000)

    const criticalErrors = errors.filter(e =>
      !e.includes('WebSocket') && !e.includes('realtime') && !e.includes('net::ERR')
    )
    expect(criticalErrors).toHaveLength(0)
  })

  test('sayfa başlığı "Faaliyetler" içermeli', async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/faaliyetler.html')
    await page.waitForSelector('#faaliyetler-container', { timeout: 10000 })
    await expect(page.locator('h2')).toContainText('Faaliyetler')
  })
})

test.describe('Faaliyetler: Filtreler', () => {
  test.beforeEach(async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/faaliyetler.html')
    await page.waitForSelector('#filter-sop', { timeout: 10000 })
  })

  test('SOP filtre dropdown görünmeli', async ({ page }) => {
    await expect(page.locator('#filter-sop')).toBeVisible()
  })

  test('"Tüm SOP\'lar" varsayılan seçenek mevcut olmalı', async ({ page }) => {
    const firstOption = page.locator('#filter-sop option').first()
    const text = await firstOption.textContent()
    expect(text).toMatch(/Tüm|All/)
  })
})

test.describe('Faaliyetler: İçerik Alanı', () => {
  test.beforeEach(async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/faaliyetler.html')
    await page.waitForSelector('#faaliyetler-container', { timeout: 10000 })
    await page.waitForTimeout(1000)
  })

  test('faaliyetler konteyneri görünmeli', async ({ page }) => {
    await expect(page.locator('#faaliyetler-container')).toBeAttached()
  })

  test('Yeni Faaliyet butonu görünmeli', async ({ page }) => {
    await expect(page.locator('#yeni-faaliyet-btn')).toBeVisible()
  })
})

test.describe('Faaliyetler: Faaliyet Modalı', () => {
  test.beforeEach(async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/faaliyetler.html')
    await page.waitForSelector('#yeni-faaliyet-btn', { timeout: 10000 })
  })

  test('"Yeni Faaliyet" butonuna tıklanınca modal açılmalı', async ({ page }) => {
    await page.click('#yeni-faaliyet-btn')
    await expect(page.locator('#modal-faaliyet')).not.toHaveClass(/hidden/)
  })

  test('modal başlığı "Yeni Faaliyet" içermeli', async ({ page }) => {
    await page.click('#yeni-faaliyet-btn')
    await page.waitForFunction(
      () => !document.getElementById('modal-faaliyet')?.classList.contains('hidden'),
      { timeout: 5000 }
    )
    await expect(page.locator('#modal-faaliyet-title')).toContainText('Yeni Faaliyet')
  })

  test('İptal butonuyla modal kapanmalı', async ({ page }) => {
    await page.click('#yeni-faaliyet-btn')
    await page.waitForFunction(
      () => !document.getElementById('modal-faaliyet')?.classList.contains('hidden'),
      { timeout: 5000 }
    )
    await page.click('#btn-faaliyet-kapat')
    await expect(page.locator('#modal-faaliyet')).toHaveClass(/hidden/)
  })
})

test.describe('Faaliyetler: Alt Faaliyet Modalı', () => {
  test.beforeEach(async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/faaliyetler.html')
    await page.waitForSelector('#faaliyetler-container', { timeout: 10000 })
  })

  test('alt faaliyet modal DOM\'da mevcut olmalı', async ({ page }) => {
    await expect(page.locator('#modal-alt-faaliyet')).toBeAttached()
  })
})
