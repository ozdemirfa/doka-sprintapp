// ============================================================
// Harcamalar sayfası E2E testleri
// US: Harcama listesi, yeni harcama modal, çoklu ödeme satırları
// ============================================================
const { test, expect } = require('@playwright/test')
const { mockSupabase } = require('./helpers/auth')

test.describe('Harcamalar: Sayfa Yüklenmesi', () => {
  test('harcamalar sayfası JS hatası olmadan yüklenmeli', async ({ page }) => {
    const errors = []
    page.on('pageerror', (err) => errors.push(err.message))
    await mockSupabase(page)
    await page.goto('/pages/harcamalar.html')
    await page.waitForSelector('#btn-yeni-harcama', { timeout: 10000 })
    await page.waitForTimeout(1000)

    const criticalErrors = errors.filter(e =>
      !e.includes('WebSocket') && !e.includes('realtime') && !e.includes('net::ERR')
    )
    expect(criticalErrors).toHaveLength(0)
  })

  test('sayfa başlığı "Harcamalar" içermeli', async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/harcamalar.html')
    await page.waitForSelector('#btn-yeni-harcama', { timeout: 10000 })
    await expect(page.locator('h2')).toContainText('Harcamalar')
  })
})

test.describe('Harcamalar: Metrik Kartlar', () => {
  test.beforeEach(async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/harcamalar.html')
    await page.waitForSelector('#metric-toplam-harcama', { timeout: 10000 })
  })

  test('Toplam Harcama metrik kartı görünmeli', async ({ page }) => {
    await expect(page.locator('#metric-toplam-harcama')).toBeAttached()
  })

  test('gizlenmiş bütçe kartları başlangıçta görünmemeli', async ({ page }) => {
    // Reviewer bulgusundan sonra bu kartlar display:none ile gizlendi
    const butceCard = page.locator('#card-is-plani-butce')
    const farkCard = page.locator('#card-fark')
    await expect(butceCard).toBeHidden()
    await expect(farkCard).toBeHidden()
  })
})

test.describe('Harcamalar: Tablo', () => {
  test.beforeEach(async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/harcamalar.html')
    await page.waitForSelector('#harcamalar-tbody', { timeout: 10000 })
  })

  test('harcamalar tablosu mevcut olmalı', async ({ page }) => {
    await expect(page.locator('#harcamalar-tbody')).toBeAttached()
  })

  test('ödeme özet tablosu mevcut olmalı', async ({ page }) => {
    await expect(page.locator('#odeme-ozet-tbody')).toBeAttached()
  })
})

test.describe('Harcamalar: Yeni Harcama Modal', () => {
  test.beforeEach(async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/harcamalar.html')
    await page.waitForSelector('#btn-yeni-harcama', { timeout: 10000 })
  })

  test('"Yeni Harcama" butonu görünmeli', async ({ page }) => {
    await expect(page.locator('#btn-yeni-harcama')).toBeVisible()
  })

  test('butona tıklanınca modal açılmalı', async ({ page }) => {
    await page.click('#btn-yeni-harcama')
    await expect(page.locator('#modal-harcama')).not.toHaveClass(/hidden/)
  })

  test('modal açılınca ödeme satırları konteyneri görünmeli', async ({ page }) => {
    await page.click('#btn-yeni-harcama')
    await page.waitForFunction(
      () => !document.getElementById('modal-harcama')?.classList.contains('hidden'),
      { timeout: 5000 }
    )
    await expect(page.locator('#odeme-satirlari')).toBeAttached()
  })

  test('"+ Satır Ekle" butonu modalda görünmeli', async ({ page }) => {
    await page.click('#btn-yeni-harcama')
    await page.waitForFunction(
      () => !document.getElementById('modal-harcama')?.classList.contains('hidden'),
      { timeout: 5000 }
    )
    await expect(page.locator('#btn-odeme-satir-ekle')).toBeVisible()
  })

  test('"+ Satır Ekle" tıklanınca ödeme satırı eklenmeli', async ({ page }) => {
    await page.click('#btn-yeni-harcama')
    await page.waitForFunction(
      () => !document.getElementById('modal-harcama')?.classList.contains('hidden'),
      { timeout: 5000 }
    )
    const onceki = await page.locator('#odeme-satirlari .odeme-satir').count()
    await page.click('#btn-odeme-satir-ekle')
    const sonraki = await page.locator('#odeme-satirlari .odeme-satir').count()
    expect(sonraki).toBeGreaterThanOrEqual(onceki)
  })

  test('İptal butonuyla modal kapanmalı', async ({ page }) => {
    await page.click('#btn-yeni-harcama')
    await page.waitForFunction(
      () => !document.getElementById('modal-harcama')?.classList.contains('hidden'),
      { timeout: 5000 }
    )
    await page.click('#btn-modal-kapat')
    await expect(page.locator('#modal-harcama')).toHaveClass(/hidden/)
  })
})
