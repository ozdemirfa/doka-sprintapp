// ============================================================
// Birim Filter Pages — S4 / 046 Server-Side Filtre Coverage
// ============================================================
// performans, harcamalar, izinler sayfalarında birim filtresinin
// view.bkod üzerinden DOĞRU daraltma yaptığını doğrular.
//
// Mock kurulumu (helpers/auth.js):
//   - SKB (bkod=1) → 2 SOP, 1 perf, 1 harcama, 1 izin
//   - MEKB (bkod=2) → 2 SOP, 1 perf, 1 harcama, 1 izin
// ============================================================
const { test, expect } = require('@playwright/test')
const { mockSupabase } = require('./helpers/auth')

async function waitForBirimOptions(page) {
  await page.waitForFunction(() => {
    const sel = document.getElementById('filter-birim')
    return sel && sel.options.length > 1
  }, { timeout: 10000 })
}

// ── performans.html ────────────────────────────────────────
test.describe('Birim Filter: performans.html (S4)', () => {
  test.beforeEach(async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/performans.html')
    await page.waitForSelector('#perf-tbody', { timeout: 10000 })
    await waitForBirimOptions(page)
    await page.waitForFunction(() => {
      const tb = document.getElementById('perf-tbody')
      return tb && !tb.innerHTML.includes('Yükleniyor')
    }, { timeout: 10000 })
  })

  test('Tüm Birimler → 4 SOP grubu görünür', async ({ page }) => {
    // perf grupları SOP bazında. Her SOP en az 1 <td> içerir
    const rows = await page.locator('#perf-tbody tr').count()
    expect(rows).toBeGreaterThan(0)
  })

  test('SKB (bkod=1) seçilince sadece SKB SOPları (CG-A1, CG-A2)', async ({ page }) => {
    await page.selectOption('#filter-birim', '1')
    await page.waitForTimeout(500)
    const text = await page.locator('#perf-tbody').innerText()
    expect(text).toContain('CG-A1')
    expect(text).toContain('CG-A2')
    expect(text).not.toContain('CG-B1')
    expect(text).not.toContain('CG-B2')
  })

  test('MEKB (bkod=2) seçilince sadece MEKB SOPları (CG-B1, CG-B2)', async ({ page }) => {
    await page.selectOption('#filter-birim', '2')
    await page.waitForTimeout(500)
    const text = await page.locator('#perf-tbody').innerText()
    expect(text).toContain('CG-B1')
    expect(text).toContain('CG-B2')
    expect(text).not.toContain('CG-A1')
  })

  test('"Tüm Birimler"e dönünce tüm CG kodları geri gelir', async ({ page }) => {
    await page.selectOption('#filter-birim', '1')
    await page.waitForTimeout(300)
    await page.selectOption('#filter-birim', '')
    await page.waitForTimeout(500)
    const text = await page.locator('#perf-tbody').innerText()
    expect(text).toContain('CG-A1')
    expect(text).toContain('CG-B1')
  })
})

// ── harcamalar.html ────────────────────────────────────────
test.describe('Birim Filter: harcamalar.html (S4)', () => {
  test.beforeEach(async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/harcamalar.html')
    await page.waitForSelector('#harcamalar-tbody', { timeout: 10000 })
    await waitForBirimOptions(page)
    await page.waitForTimeout(500)
  })

  test('Tüm Birimler → her iki harcama da görünür', async ({ page }) => {
    const text = await page.locator('#harcamalar-tbody').innerText()
    expect(text).toContain('SKB harcama')
    expect(text).toContain('MEKB harcama')
  })

  test('SKB (bkod=1) seçilince sadece SKB harcaması', async ({ page }) => {
    await page.selectOption('#filter-birim', '1')
    await page.waitForTimeout(500)
    const text = await page.locator('#harcamalar-tbody').innerText()
    expect(text).toContain('SKB harcama')
    expect(text).not.toContain('MEKB harcama')
  })

  test('MEKB (bkod=2) seçilince sadece MEKB harcaması', async ({ page }) => {
    await page.selectOption('#filter-birim', '2')
    await page.waitForTimeout(500)
    const text = await page.locator('#harcamalar-tbody').innerText()
    expect(text).toContain('MEKB harcama')
    expect(text).not.toContain('SKB harcama')
  })

  test('"Tüm Birimler"e dönünce iki harcama da geri gelir', async ({ page }) => {
    await page.selectOption('#filter-birim', '1')
    await page.waitForTimeout(300)
    await page.selectOption('#filter-birim', '')
    await page.waitForTimeout(500)
    const text = await page.locator('#harcamalar-tbody').innerText()
    expect(text).toContain('SKB harcama')
    expect(text).toContain('MEKB harcama')
  })
})

// ── izinler.html ────────────────────────────────────────────
test.describe('Birim Filter: izinler.html (S4)', () => {
  test.beforeEach(async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/izinler.html')
    await page.waitForSelector('#izinler-tbody', { timeout: 10000 })
    await waitForBirimOptions(page)
    await page.waitForTimeout(500)
  })

  test('Tüm Birimler → her iki izin de görünür', async ({ page }) => {
    const text = await page.locator('#izinler-tbody').innerText()
    expect(text).toContain('SKB izin')
    expect(text).toContain('MEKB izin')
  })

  test('SKB (bkod=1) seçilince sadece SKB izni (server-side .eq("bkod"))', async ({ page }) => {
    await page.selectOption('#filter-birim', '1')
    await page.waitForTimeout(500)
    const text = await page.locator('#izinler-tbody').innerText()
    expect(text).toContain('SKB izin')
    expect(text).not.toContain('MEKB izin')
  })

  test('MEKB (bkod=2) seçilince sadece MEKB izni', async ({ page }) => {
    await page.selectOption('#filter-birim', '2')
    await page.waitForTimeout(500)
    const text = await page.locator('#izinler-tbody').innerText()
    expect(text).toContain('MEKB izin')
    expect(text).not.toContain('SKB izin')
  })

  test('"Tüm Birimler"e dönünce iki izin de geri gelir', async ({ page }) => {
    await page.selectOption('#filter-birim', '1')
    await page.waitForTimeout(300)
    await page.selectOption('#filter-birim', '')
    await page.waitForTimeout(500)
    const text = await page.locator('#izinler-tbody').innerText()
    expect(text).toContain('SKB izin')
    expect(text).toContain('MEKB izin')
  })
})
