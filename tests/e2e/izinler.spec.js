// ============================================================
// İzinler & Saha sayfası E2E testleri
// US-10: İzinler (form modal, il dropdown, saha tab)
// ============================================================
const { test, expect } = require('@playwright/test')
const { mockSupabase } = require('./helpers/auth')

test.describe('İzinler: Sayfa Yüklenmesi', () => {
  test('izinler sayfası JS hatası olmadan yüklenmeli', async ({ page }) => {
    const errors = []
    page.on('pageerror', (err) => errors.push(err.message))
    await mockSupabase(page)
    await page.goto('/pages/izinler.html')
    await page.waitForSelector('#tab-izinler', { timeout: 10000 })
    await page.waitForTimeout(1000)

    const criticalErrors = errors.filter(e =>
      !e.includes('WebSocket') && !e.includes('realtime') && !e.includes('net::ERR')
    )
    expect(criticalErrors).toHaveLength(0)
  })

  test('izinler tab içeriği görünür olmalı', async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/izinler.html')
    await expect(page.locator('#tab-izinler')).toBeVisible()
  })

  test('saha sekmesi butonu görünür olmalı', async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/izinler.html')
    await page.waitForSelector('#tab-saha-btn', { timeout: 10000 })
    await expect(page.locator('#tab-saha-btn')).toBeVisible()
  })
})

test.describe('İzinler: Modal', () => {
  test.beforeEach(async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/izinler.html')
    await page.waitForSelector('#yeni-izin-btn', { timeout: 10000 })
  })

  test('Yeni İzin butonuna tıklanınca modal açılmalı', async ({ page }) => {
    await page.click('#yeni-izin-btn')
    await expect(page.locator('#izin-modal')).toHaveClass(/open/)
  })

  test('modal içinde izin formu görünmeli', async ({ page }) => {
    await page.click('#yeni-izin-btn')
    await expect(page.locator('#izin-form')).toBeVisible()
  })

  test('İptal butonuna tıklanınca modal kapanmalı', async ({ page }) => {
    await page.click('#yeni-izin-btn')
    await page.waitForFunction(
      () => document.getElementById('izin-modal')?.classList.contains('open'),
      { timeout: 5000 }
    )
    await page.click('#izin-modal-iptal')
    await expect(page.locator('#izin-modal')).not.toHaveClass(/open/)
  })

  test('modal kapat (X) butonuyla kapanmalı', async ({ page }) => {
    await page.click('#yeni-izin-btn')
    await page.waitForFunction(
      () => document.getElementById('izin-modal')?.classList.contains('open'),
      { timeout: 5000 }
    )
    await page.click('#izin-modal-close')
    await expect(page.locator('#izin-modal')).not.toHaveClass(/open/)
  })
})

test.describe('İzinler: Il Dropdown (DOKA illeri)', () => {
  // saha-il select is static HTML — accessible without opening modal
  // Modal is hidden by default; select element is still in DOM (just not visible)
  test('saha-il dropdown sadece 6 DOKA ilini içermeli', async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/izinler.html')
    await page.waitForSelector('#saha-il', { state: 'attached', timeout: 10000 })

    // "Seçin..." dışında 6 il seçeneği olmalı
    const options = await page.locator('#saha-il option').allTextContents()
    const dokaIlleri = options.filter(o => o !== 'Seçin...' && o !== '')
    expect(dokaIlleri).toHaveLength(6)

    const beklenenIller = ['Artvin', 'Giresun', 'Gümüşhane', 'Ordu', 'Rize', 'Trabzon']
    for (const il of beklenenIller) {
      expect(dokaIlleri).toContain(il)
    }
  })

  test('saha-il dropdown Artvin seçeneği içermeli', async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/izinler.html')
    await page.waitForSelector('#saha-il', { state: 'attached', timeout: 10000 })
    await expect(page.locator('#saha-il option[value="Artvin"]')).toBeAttached()
  })

  test('saha-il dropdown Trabzon seçeneği içermeli', async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/izinler.html')
    await page.waitForSelector('#saha-il', { state: 'attached', timeout: 10000 })
    await expect(page.locator('#saha-il option[value="Trabzon"]')).toBeAttached()
  })
})

test.describe('İzinler: Saha Görevi Tab', () => {
  test('Saha sekmesine tıklanınca tab-saha görünür hale gelmeli', async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/izinler.html')
    await page.waitForSelector('#tab-saha-btn', { timeout: 10000 })

    await page.click('#tab-saha-btn')
    await expect(page.locator('#tab-saha')).toBeVisible()
  })

  test('Saha sekmesinde Yeni Saha Görevi butonu görünmeli', async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/izinler.html')
    await page.waitForSelector('#tab-saha-btn', { timeout: 10000 })

    await page.click('#tab-saha-btn')
    await expect(page.locator('#yeni-saha-btn')).toBeVisible()
  })
})
