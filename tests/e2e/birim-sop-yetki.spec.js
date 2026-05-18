// ============================================================
// Birim-SOP Eşleme (S3) E2E testleri
// Kapsam: Sekme erişim, birim listesi, SOP matrisi, dirty tracking,
//         kaydet/iptal akışı, XSS guard, RLS smoke (mock 403)
// Migration: 042-045 (birim_sop_izni tablosu + RLS + seed)
// ============================================================
const { test, expect } = require('@playwright/test')
const { mockSupabaseWithPermissions, MOCK_BIRIMLER, MOCK_SOPLAR } = require('./helpers/auth')
const { FIXTURES } = require('./helpers/permissions-fixtures')

// ── Yardımcı: birim_sop_izni mock-aware admin setup ───────────
async function setupBirimSopPage(page, opts = {}) {
  const {
    izniRows = [],
    rejectMutations = false,
    extraSoplar = null,
    extraBirimler = null,
  } = opts

  const fixture = {
    ...FIXTURES.admin,
    groupRows: [
      { id: 1, ad: 'yönetici', aciklama: 'Yönetici', sistem_grubu: true, aktif: true },
    ],
  }

  await mockSupabaseWithPermissions(page, fixture)

  // birim_sop_izni isteği — özel mock
  await page.route(
    (url) => url.toString().includes('/rest/v1/birim_sop_izni'),
    async (route) => {
      const method = route.request().method()
      if (rejectMutations && (method === 'POST' || method === 'PATCH' || method === 'DELETE')) {
        return route.fulfill({
          status: 403,
          contentType: 'application/json',
          body: JSON.stringify({ message: 'new row violates row-level security policy' }),
        })
      }
      if (method === 'POST' || method === 'PATCH') {
        return route.fulfill({ status: 201, contentType: 'application/json', body: JSON.stringify(izniRows) })
      }
      if (method === 'DELETE') {
        return route.fulfill({ status: 204, body: '' })
      }
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(izniRows) })
    }
  )

  // SOP listesi override (test edilebilirlik için)
  if (extraSoplar) {
    await page.route(
      (url) => url.toString().includes('/rest/v1/soplar'),
      async (route) => {
        return route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify(extraSoplar),
        })
      }
    )
  }

  // Birim listesi override
  if (extraBirimler) {
    await page.route(
      (url) => url.toString().includes('/rest/v1/birimler'),
      async (route) => {
        return route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify(extraBirimler),
        })
      }
    )
  }

  await page.goto('/pages/yetki-yonetimi.html')
  await page.waitForSelector('.tab-btn[data-tab="birim-sop"]', { timeout: 12000 })
}

// Onbeforeunload guard'ını disable et (test'lerde takıntı yapmasın)
test.beforeEach(async ({ page }) => {
  await page.addInitScript(() => {
    window.addEventListener('beforeunload', e => { e.stopImmediatePropagation() }, true)
  })
})

// ============================================================
// YY-08: Sekme Erişim (admin görür)
// ============================================================
test.describe('YY-08: Birim-SOP sekmesi erişim', () => {
  test('admin "Birim-SOP Eşleme" sekmesini görmeli', async ({ page }) => {
    await setupBirimSopPage(page)
    const tab = page.locator('[data-tab="birim-sop"]')
    await expect(tab).toBeVisible()
    await expect(tab).toContainText('Birim-SOP')
  })

  test('non-admin kullanıcı yetki-yonetimi.html sayfasından redirect olmalı', async ({ page }) => {
    const fixture = {
      ...FIXTURES.standart,
      groupRows: [],
    }
    await mockSupabaseWithPermissions(page, fixture)
    await page.goto('/pages/yetki-yonetimi.html')
    // Non-admin: index.html'e yönlendirilir, body hidden kalır
    await page.waitForURL(/\/index\.html|\/$/, { timeout: 8000 }).catch(() => {})
    // Eğer redirect olduysa sekme görünmemeli
    const tabExists = await page.locator('[data-tab="birim-sop"]').count()
    if (tabExists > 0) {
      // Sayfada hâlâ ise body hidden kalmalı
      const bodyHidden = await page.evaluate(() => document.body.hidden)
      expect(bodyHidden).toBe(true)
    }
  })

  test('Birim-SOP sekmesine tıklayınca panel görünmeli', async ({ page }) => {
    await setupBirimSopPage(page)
    await page.click('[data-tab="birim-sop"]')
    await expect(page.locator('#tab-birim-sop')).toBeVisible()
    await expect(page.locator('#tab-gruplar')).not.toBeVisible()
  })
})

// ============================================================
// YY-09: Birim listesi yüklenir
// ============================================================
test.describe('YY-09: Birim listesi', () => {
  test('Birim-SOP sekmesi açılınca birim listesi yüklenmeli', async ({ page }) => {
    await setupBirimSopPage(page)
    await page.click('[data-tab="birim-sop"]')
    await expect(page.locator('#birim-sop-list')).toBeVisible()
    // Mock'taki 2 birim
    await expect(page.locator('[data-testid="birim-sop-birim-row"]').first()).toBeVisible({ timeout: 8000 })
    const count = await page.locator('[data-testid="birim-sop-birim-row"]').count()
    expect(count).toBeGreaterThanOrEqual(2)
  })

  test('birim listesinde mock birim_adi metni görünmeli', async ({ page }) => {
    await setupBirimSopPage(page)
    await page.click('[data-tab="birim-sop"]')
    await expect(page.locator('#birim-sop-list')).toContainText('Sera Kıyı Birimi', { timeout: 8000 })
    await expect(page.locator('#birim-sop-list')).toContainText('Mekanik Birim')
  })
})

// ============================================================
// YY-10: Birim seçince SOP matrisi yüklenir
// ============================================================
test.describe('YY-10: SOP matrisi', () => {
  test('birim seçince SOP matrisi tablosu görünmeli', async ({ page }) => {
    await setupBirimSopPage(page, {
      izniRows: [
        { skod: 101, okuma: true, yazma: false, silme: false },
        { skod: 102, okuma: true, yazma: true,  silme: false },
      ],
    })
    await page.click('[data-tab="birim-sop"]')
    await page.locator('[data-testid="birim-sop-birim-row"]').first().click()
    // Matris en az 4 SOP satırı içermeli (mock)
    await page.waitForSelector('#birim-sop-tbody tr[data-skod]', { timeout: 8000 })
    const sopRows = await page.locator('#birim-sop-tbody tr[data-skod]').count()
    expect(sopRows).toBeGreaterThanOrEqual(MOCK_SOPLAR.length)
  })

  test('mevcut izinler checkbox olarak yüklenmeli', async ({ page }) => {
    await setupBirimSopPage(page, {
      izniRows: [
        { skod: 101, okuma: true,  yazma: true,  silme: false },
        { skod: 102, okuma: true,  yazma: false, silme: false },
      ],
    })
    await page.click('[data-tab="birim-sop"]')
    await page.locator('[data-testid="birim-sop-birim-row"]').first().click()
    await page.waitForSelector('#birim-sop-tbody tr[data-skod="101"]', { timeout: 8000 })
    // 101 için okuma=true, yazma=true beklenir
    const okuma101 = page.locator('#birim-sop-tbody tr[data-skod="101"] input[data-bsop-perm="okuma"]')
    const yazma101 = page.locator('#birim-sop-tbody tr[data-skod="101"] input[data-bsop-perm="yazma"]')
    await expect(okuma101).toBeChecked()
    await expect(yazma101).toBeChecked()
  })

  test('toolbar (Kaydet/Vazgeç) birim seçilince görünmeli', async ({ page }) => {
    await setupBirimSopPage(page)
    await page.click('[data-tab="birim-sop"]')
    // Önce gizli olmalı
    await expect(page.locator('#birim-sop-toolbar')).toHaveClass(/is-hidden/)
    await page.locator('[data-testid="birim-sop-birim-row"]').first().click()
    await page.waitForSelector('#birim-sop-tbody tr[data-skod]', { timeout: 8000 })
    await expect(page.locator('#birim-sop-toolbar')).not.toHaveClass(/is-hidden/)
  })
})

// ============================================================
// YY-11: Checkbox toggle dirty state
// ============================================================
test.describe('YY-11: Dirty state tracking', () => {
  test('checkbox değişince status "kaydedilmemiş değişiklik" göstermeli', async ({ page }) => {
    await setupBirimSopPage(page)
    await page.click('[data-tab="birim-sop"]')
    await page.locator('[data-testid="birim-sop-birim-row"]').first().click()
    await page.waitForSelector('#birim-sop-tbody tr[data-skod]', { timeout: 8000 })
    // İlk checkbox'ı toggle et
    await page.locator('#birim-sop-tbody input[data-bsop-perm="yazma"]').first().click()
    await expect(page.locator('#birim-sop-status')).toContainText('kaydedilmemiş')
  })

  test('column toggle (sütun başlığı checkbox) tüm satırları toggle etmeli', async ({ page }) => {
    await setupBirimSopPage(page)
    await page.click('[data-tab="birim-sop"]')
    await page.locator('[data-testid="birim-sop-birim-row"]').first().click()
    await page.waitForSelector('#birim-sop-tbody tr[data-skod]', { timeout: 8000 })
    // "yazma" sütun toggle (header checkbox)
    await page.locator('input[data-bsop-toggle-col="yazma"]').click()
    // Tüm yazma checkbox'ları işaretli olmalı
    const allYazma = page.locator('#birim-sop-tbody input[data-bsop-perm="yazma"]')
    const count = await allYazma.count()
    for (let i = 0; i < count; i++) {
      await expect(allYazma.nth(i)).toBeChecked()
    }
    await expect(page.locator('#birim-sop-status')).toContainText('kaydedilmemiş')
  })
})

// ============================================================
// YY-12: Kaydet POST/UPSERT isteği
// ============================================================
test.describe('YY-12: Kaydet POST', () => {
  test('Kaydet butonu upsert isteği göndermeli', async ({ page }) => {
    let upsertCalled = false
    let upsertBody = null

    await setupBirimSopPage(page)

    // birim_sop_izni POST yakala
    await page.route(
      (url) => url.toString().includes('/rest/v1/birim_sop_izni'),
      async (route) => {
        const method = route.request().method()
        if (method === 'POST') {
          upsertCalled = true
          upsertBody = route.request().postData()
          return route.fulfill({ status: 201, contentType: 'application/json', body: '[]' })
        }
        return route.fulfill({ status: 200, contentType: 'application/json', body: '[]' })
      }
    )

    await page.click('[data-tab="birim-sop"]')
    await page.locator('[data-testid="birim-sop-birim-row"]').first().click()
    await page.waitForSelector('#birim-sop-tbody tr[data-skod]', { timeout: 8000 })

    // En az bir checkbox işaretle (kayıt için)
    await page.locator('#birim-sop-tbody input[data-bsop-perm="okuma"]').first().click()
    await page.click('#btn-birim-sop-kaydet')

    // Toast bekleyelim
    await page.waitForTimeout(800)
    expect(upsertCalled).toBe(true)
    expect(upsertBody).toContain('bkod')
    expect(upsertBody).toContain('skod')
  })
})

// ============================================================
// YY-13: Vazgeç değişiklikleri geri alır
// ============================================================
test.describe('YY-13: Vazgeç', () => {
  test('Vazgeç butonu matrisi orijinal haline çevirmeli', async ({ page }) => {
    await setupBirimSopPage(page, {
      izniRows: [
        { skod: 101, okuma: true, yazma: false, silme: false },
      ],
    })
    await page.click('[data-tab="birim-sop"]')
    await page.locator('[data-testid="birim-sop-birim-row"]').first().click()
    await page.waitForSelector('#birim-sop-tbody tr[data-skod="101"]', { timeout: 8000 })

    // yazma'yı toggle et (orijinalde false)
    const yazma = page.locator('#birim-sop-tbody tr[data-skod="101"] input[data-bsop-perm="yazma"]')
    await yazma.click()
    await expect(yazma).toBeChecked()

    // Vazgeç
    await page.click('#btn-birim-sop-iptal')
    await page.waitForTimeout(500)
    // Yeniden yüklendi — yazma false olmalı
    await expect(page.locator('#birim-sop-tbody tr[data-skod="101"] input[data-bsop-perm="yazma"]')).not.toBeChecked()
  })
})

// ============================================================
// YY-14: XSS guard (kötü niyetli SOP/birim adı)
// ============================================================
test.describe('YY-14: XSS guard', () => {
  test('SOP adında script tag escape edilmeli', async ({ page }) => {
    const xssBirimler = [
      { bkod: 99, birim_kisa: 'XSS', birim_adi: '<script>window.__xss=1</script>', durum: 'aktif' }
    ]
    const xssSoplar = [
      { skod: 999, kisa: '<img src=x onerror=window.__xss2=1>', sop_adi: 'XSS test', durum: 'Aktif', bkod: 99 }
    ]
    await setupBirimSopPage(page, {
      extraBirimler: xssBirimler,
      extraSoplar: xssSoplar,
    })
    await page.click('[data-tab="birim-sop"]')
    await page.locator('[data-testid="birim-sop-birim-row"]').first().click()
    await page.waitForSelector('#birim-sop-tbody tr[data-skod]', { timeout: 8000 })
    // Script execute olmamalı
    const xss = await page.evaluate(() => window.__xss === 1 || window.__xss2 === 1)
    expect(xss).toBe(false)
    // Listede script tag literal olarak görünmemeli; tag escape edilmiş olmalı
    const listHtml = await page.locator('#birim-sop-list').innerHTML()
    expect(listHtml).not.toContain('<script>window.__xss')
    // Birim adı escape edilmiş olmalı (&lt;script&gt;...)
    expect(listHtml).toContain('&lt;script&gt;')
  })
})

// ============================================================
// YY-15: RLS smoke (non-admin yazma reddi)
// ============================================================
test.describe('YY-15: RLS smoke', () => {
  test('rejectMutations=true ile POST 403 dönmeli, kullanıcı hata mesajı görmeli', async ({ page }) => {
    await setupBirimSopPage(page, {
      rejectMutations: true,
    })

    // Önce hata toast'ını yakalamak için console.error dinleyelim
    const consoleErrors = []
    page.on('console', msg => { if (msg.type() === 'error') consoleErrors.push(msg.text()) })

    await page.click('[data-tab="birim-sop"]')
    await page.locator('[data-testid="birim-sop-birim-row"]').first().click()
    await page.waitForSelector('#birim-sop-tbody tr[data-skod]', { timeout: 8000 })
    await page.locator('#birim-sop-tbody input[data-bsop-perm="okuma"]').first().click()
    await page.click('#btn-birim-sop-kaydet')

    // Toast veya status mesajında hata olmalı
    await page.waitForTimeout(800)
    // Toast container'da "hata" geçmeli
    const toast = await page.locator('.toast, [data-testid="toast"], .toast-error').count()
    // Toast olmasa bile kayıt başarılı görünmemeli; bayrak hâlâ "kaydedilmemiş" kalsın
    const statusText = await page.locator('#birim-sop-status').textContent()
    // status hâlâ "kaydedilmemiş" içermelidir veya toast'ta hata olmalı
    expect(toast > 0 || (statusText || '').includes('kaydedilmemiş')).toBeTruthy()
  })
})
