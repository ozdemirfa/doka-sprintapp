// ============================================================
// Retrospektif sayfası E2E testleri
// US-7: Retrospektif (sprint dropdown, form alanları, G.ort)
// ============================================================
const { test, expect } = require('@playwright/test')
const { mockSupabase, SUPABASE_URL } = require('./helpers/auth')

// Belirli bir rol ile personel mock'u oluşturmak için yardımcı
async function mockPersonelWithRole(page, rolKodu) {
  await page.route(
    (url) => url.toString().includes('/rest/v1/personel'),
    (route) => route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify([{ pkod: 2, ad: 'Test', soyad: 'Kullanıcı', bkod: 1, rol_kodu: rolKodu }])
    })
  )
}

test.describe('Retro: Sayfa Yüklenmesi', () => {
  test.beforeEach(async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/retro.html')
    await page.waitForSelector('#retro-form', { timeout: 10000 })
  })

  test('retro sayfası JS hatası olmadan yüklenmeli', async ({ page }) => {
    const errors = []
    page.on('pageerror', (err) => errors.push(err.message))
    await page.waitForTimeout(1000)

    const criticalErrors = errors.filter(e =>
      !e.includes('WebSocket') && !e.includes('realtime') && !e.includes('net::ERR')
    )
    expect(criticalErrors).toHaveLength(0)
  })

  test('retro form görünür olmalı', async ({ page }) => {
    await expect(page.locator('#retro-form')).toBeVisible()
  })

  test('sayfa başlığı doğru olmalı', async ({ page }) => {
    await expect(page.locator('h2')).toContainText('Retrospektif')
  })
})

test.describe('Retro: Sprint Dropdown', () => {
  test('sprint dropdown mevcut olmalı', async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/retro.html')
    await page.waitForSelector('#sprint-select', { timeout: 10000 })

    await expect(page.locator('#sprint-select')).toBeVisible()
  })

  test('sprint dropdown mock verisiyle dolmalı', async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/retro.html')
    await page.waitForSelector('#sprint-select', { timeout: 10000 })
    // Mock 1 sprint döndürüyor — dropdown en az 1 option içermeli
    await page.waitForFunction(
      () => {
        const sel = document.getElementById('sprint-select')
        return sel && sel.options.length > 0 && sel.options[0].value !== ''
      },
      { timeout: 8000 }
    )
    const count = await page.locator('#sprint-select option').count()
    expect(count).toBeGreaterThan(0)
  })
})

test.describe('Retro: Form Alanları', () => {
  test.beforeEach(async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/retro.html')
    await page.waitForSelector('#retro-form', { timeout: 10000 })
  })

  test('org-slider (Organizasyon Puanı) görünür olmalı', async ({ page }) => {
    await expect(page.locator('#org-slider')).toBeVisible()
  })

  test('org-val (org_puan göstergesi) görünür ve başlangıç değeri 5 olmalı', async ({ page }) => {
    await expect(page.locator('#org-val')).toBeVisible()
    await expect(page.locator('#org-val')).toHaveText('5')
  })

  test('rol-slider (Ajanstaki Rolü) görünür olmalı', async ({ page }) => {
    await expect(page.locator('#rol-slider')).toBeVisible()
  })

  test('hakkinda-slider (Ajans Hakkında) görünür olmalı', async ({ page }) => {
    await expect(page.locator('#hakkinda-slider')).toBeVisible()
  })

  test('gort-display (G.ort) alanı görünür olmalı', async ({ page }) => {
    await expect(page.locator('#gort-display')).toBeVisible()
  })

  test('gort-display başlangıç değeri 5.00 olmalı', async ({ page }) => {
    const text = await page.locator('#gort-display').textContent()
    expect(text).toMatch(/5\.00/)
  })

  test('org-slider değişince org-val güncellenmeli', async ({ page }) => {
    await page.locator('#org-slider').evaluate((el) => {
      el.value = '8'
      el.dispatchEvent(new Event('input', { bubbles: true }))
    })
    await expect(page.locator('#org-val')).toHaveText('8')
  })

  test('retro geçmiş kayıtlar tablosu görünür olmalı', async ({ page }) => {
    await expect(page.locator('#retro-tablo-body')).toBeAttached()
  })
})

test.describe('Retro: Yetki — gs Redirect', () => {
  test('gs rolüyle retro sayfası açılınca index.html\'ye yönlendirilmeli', async ({ page }) => {
    await mockSupabase(page)
    await mockPersonelWithRole(page, 'gs')
    await page.goto('/pages/retro.html')
    // ../index.html → kök URL veya /index.html'e yönlendirilir
    await page.waitForFunction(
      () => !window.location.pathname.includes('retro.html'),
      { timeout: 10000 }
    )
    expect(page.url()).not.toContain('retro.html')
  })
})

test.describe('Retro: Yetki — Geçmiş Tablo Görünürlüğü', () => {
  test('yönetici rolünde #gecmis-retro-panel görünmeli', async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/retro.html')
    await page.waitForSelector('#retro-form', { timeout: 10000 })
    await page.waitForFunction(
      () => document.getElementById('gecmis-retro-panel') !== null,
      { timeout: 5000 }
    )
    const display = await page.locator('#gecmis-retro-panel').evaluate(el => el.style.display)
    expect(display).not.toBe('none')
  })

  test('standart rolünde #gecmis-retro-panel gizlenmeli', async ({ page }) => {
    await mockSupabase(page)
    await mockPersonelWithRole(page, 'standart')
    await page.goto('/pages/retro.html')
    await page.waitForSelector('#retro-form', { timeout: 10000 })
    await page.waitForFunction(
      () => {
        const el = document.getElementById('gecmis-retro-panel')
        return el && el.style.display === 'none'
      },
      { timeout: 5000 }
    )
    const display = await page.locator('#gecmis-retro-panel').evaluate(el => el.style.display)
    expect(display).toBe('none')
  })
})
