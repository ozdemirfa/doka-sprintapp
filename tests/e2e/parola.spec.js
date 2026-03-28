// ============================================================
// E2E: Parola İşlemleri (parola.html)
// ============================================================
const { test, expect } = require('@playwright/test')
const { mockSupabase, SUPABASE_URL } = require('./helpers/auth.js')

const FUNCTIONS_URL = `${SUPABASE_URL}/functions/v1/admin-reset-password`

// Edge function mock helpers
async function mockEdgeFunctionSuccess(page) {
  await page.route(FUNCTIONS_URL, async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ success: true, message: 'Test Kullanıcı için şifre güncellendi.' }),
    })
  })
}

async function mockEdgeFunctionError(page, status, errorMsg) {
  await page.route(FUNCTIONS_URL, async (route) => {
    await route.fulfill({
      status,
      contentType: 'application/json',
      body: JSON.stringify({ error: errorMsg }),
    })
  })
}

// ── Test grubu ───────────────────────────────────────────────

test.describe('Parola İşlemleri', () => {
  let consoleErrors = []

  test.beforeEach(async ({ page }) => {
    consoleErrors = []
    page.on('console', (msg) => {
      if (msg.type() === 'error') consoleErrors.push(msg.text())
    })
    page.on('pageerror', (err) => consoleErrors.push(err.message))
    await mockSupabase(page)
  })

  // ── US-P1: Sayfa Yükleme ──────────────────────────────────
  test('US-P1: sayfa hatasız yüklenir ve başlık görünür', async ({ page }) => {
    await page.goto('/pages/parola.html')
    await page.waitForSelector('h2', { timeout: 8000 })
    const title = await page.textContent('h2')
    expect(title).toContain('Parola')
    const jsErrors = consoleErrors.filter(e => !e.includes('favicon'))
    expect(jsErrors).toHaveLength(0)
  })

  // ── US-P2: Yönetici Paneli ────────────────────────────────
  test('US-P2: yönetici paneli görünür', async ({ page }) => {
    await page.goto('/pages/parola.html')
    await page.waitForSelector('#admin-panel', { timeout: 8000 })
    const display = await page.$eval('#admin-panel', el => el.style.display)
    expect(display).not.toBe('none')
  })

  // ── US-P3: Kendi Şifre Validasyonu — Çok Kısa ────────────
  test('US-P3: 7 karakterli şifre girilince hata toast gösterilir', async ({ page }) => {
    await page.goto('/pages/parola.html')
    await page.waitForSelector('#new-password', { timeout: 8000 })
    await page.fill('#new-password', 'kisa12')
    await page.fill('#new-password-confirm', 'kisa12')
    await page.click('#btn-sifre-degistir')
    const toast = await page.waitForSelector('.toast, [class*="toast"]', { timeout: 5000 })
    const toastText = await toast.textContent()
    expect(toastText).toMatch(/en az 8|karakter/i)
  })

  // ── US-P4: Kendi Şifre Validasyonu — Eşleşmeme ───────────
  test('US-P4: eşleşmeyen şifreler girilince hata toast gösterilir', async ({ page }) => {
    await page.goto('/pages/parola.html')
    await page.waitForSelector('#new-password', { timeout: 8000 })
    await page.fill('#new-password', 'Sifre123!')
    await page.fill('#new-password-confirm', 'Sifre456!')
    await page.click('#btn-sifre-degistir')
    const toast = await page.waitForSelector('.toast, [class*="toast"]', { timeout: 5000 })
    const toastText = await toast.textContent()
    expect(toastText).toMatch(/eşleşmiyor/i)
  })

  // ── US-P5: Yönetici Şifre Sıfırlama — Başarılı ───────────
  test('US-P5: yönetici şifre sıfırlama başarılı olduğunda success toast gösterilir', async ({ page }) => {
    await mockEdgeFunctionSuccess(page)
    await page.goto('/pages/parola.html')
    await page.waitForSelector('#admin-target-user', { timeout: 8000 })
    // Personel dropdown'u seç (mock bir değer)
    await page.evaluate(() => {
      const sel = document.getElementById('admin-target-user')
      const opt = document.createElement('option')
      opt.value = '2'
      opt.textContent = 'Test Kullanıcı'
      sel.appendChild(opt)
      sel.value = '2'
    })
    await page.fill('#admin-new-password', 'YeniSifre123!')
    await page.click('#btn-admin-sifre-sifirla')
    const toast = await page.waitForSelector('.toast, [class*="toast"]', { timeout: 5000 })
    const toastText = await toast.textContent()
    expect(toastText).toMatch(/başarıyla sıfırlandı/i)
  })

  // ── US-P6: Yönetici Şifre Sıfırlama — Edge Function Hatası
  test('US-P6: edge function hata döndürdüğünde gerçek hata mesajı gösterilir', async ({ page }) => {
    await mockEdgeFunctionError(page, 404, 'Kullanıcı bulunamadı veya auth_id eksik.')
    await page.goto('/pages/parola.html')
    await page.waitForSelector('#admin-target-user', { timeout: 8000 })
    await page.evaluate(() => {
      const sel = document.getElementById('admin-target-user')
      const opt = document.createElement('option')
      opt.value = '99'
      opt.textContent = 'Bilinmeyen'
      sel.appendChild(opt)
      sel.value = '99'
    })
    await page.fill('#admin-new-password', 'YeniSifre123!')
    await page.click('#btn-admin-sifre-sifirla')
    const toast = await page.waitForSelector('.toast, [class*="toast"]', { timeout: 5000 })
    const toastText = await toast.textContent()
    // Gerçek hata mesajı gösterilmeli (generic "non-2xx" değil)
    expect(toastText).toMatch(/bulunamadı|auth_id/i)
  })

  // ── US-P7: Yönetici Şifre Sıfırlama — Kullanıcı Seçilmemişse
  test('US-P7: kullanıcı seçilmeden sıfırla butonuna basılınca uyarı verilir', async ({ page }) => {
    await page.goto('/pages/parola.html')
    await page.waitForSelector('#admin-new-password', { timeout: 8000 })
    await page.fill('#admin-new-password', 'YeniSifre123!')
    // Kullanıcı seçmeden gönder
    await page.click('#btn-admin-sifre-sifirla')
    const toast = await page.waitForSelector('.toast, [class*="toast"]', { timeout: 5000 })
    const toastText = await toast.textContent()
    expect(toastText).toMatch(/kullanıcı seç/i)
  })
})
