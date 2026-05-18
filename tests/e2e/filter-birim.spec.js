// ============================================================
// Birim Filter — Davranışsal Regression Testleri (S2)
// ============================================================
// Her sayfada filter-birim seçildiğinde tablonun/içeriğin gerçekten
// daraldığını doğrular. Mock veri 2 birim (SKB=1, MEKB=2) × 2 SOP =
// 4 satır olacak şekilde kurulu. Birim seçimi sonrası 2 satır kalmalı.
// ============================================================
const { test, expect } = require('@playwright/test')
const { mockSupabase } = require('./helpers/auth')

// ── Yardımcı: dropdown'un dolmasını bekle ─────────────────────
async function waitForBirimOptions(page) {
  await page.waitForFunction(() => {
    const sel = document.getElementById('filter-birim')
    return sel && sel.options.length > 1
  }, { timeout: 10000 })
}

// ── 1. faaliyetler.html — birim seçimi tabloyu daraltmalı ────
test.describe('Birim Filter: faaliyetler.html', () => {
  test.beforeEach(async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/faaliyetler.html')
    await page.waitForSelector('#faaliyetler-container', { timeout: 10000 })
    await waitForBirimOptions(page)
    // İlk render'ın bitmesini bekle
    await page.waitForFunction(() => {
      const c = document.getElementById('faaliyetler-container')
      return c && !c.innerHTML.includes('Yükleniyor')
    }, { timeout: 10000 })
  })

  test('birim filter dropdown var ve birimler dolu', async ({ page }) => {
    const opts = await page.locator('#filter-birim option').count()
    // "Tüm Birimler" + 2 birim = 3 opt
    expect(opts).toBeGreaterThanOrEqual(3)
  })

  test('birim seçimi öncesi 4 SOP başlığı görünür (tüm birimler)', async ({ page }) => {
    const sopCount = await page.locator('.accordion-header:has-text("SOP:")').count()
    expect(sopCount).toBe(4)
  })

  test('SKB (bkod=1) birimi seçilince sadece SKB SOPları görünür', async ({ page }) => {
    await page.selectOption('#filter-birim', '1')
    await page.waitForTimeout(500)
    const sopHeaders = await page.locator('.accordion-header:has-text("SOP:")').allTextContents()
    expect(sopHeaders.length).toBe(2)
    sopHeaders.forEach(t => expect(t).toMatch(/SOP-A/))
  })

  test('MEKB (bkod=2) birimi seçilince sadece MEKB SOPları görünür', async ({ page }) => {
    await page.selectOption('#filter-birim', '2')
    await page.waitForTimeout(500)
    const sopHeaders = await page.locator('.accordion-header:has-text("SOP:")').allTextContents()
    expect(sopHeaders.length).toBe(2)
    sopHeaders.forEach(t => expect(t).toMatch(/SOP-B/))
  })

  test('"Tüm Birimler"e geri dönünce tüm SOPlar geri gelir', async ({ page }) => {
    await page.selectOption('#filter-birim', '1')
    await page.waitForTimeout(300)
    await page.selectOption('#filter-birim', '')
    await page.waitForTimeout(500)
    const sopCount = await page.locator('.accordion-header:has-text("SOP:")').count()
    expect(sopCount).toBe(4)
  })

  test('birim seçilince SOP dropdown da daralır', async ({ page }) => {
    const beforeAll = await page.locator('#filter-sop option').count()
    expect(beforeAll).toBeGreaterThanOrEqual(5) // Tüm + 4 SOP
    await page.selectOption('#filter-birim', '1')
    await page.waitForTimeout(300)
    const afterBirim = await page.locator('#filter-sop option').count()
    expect(afterBirim).toBe(3) // Tüm + 2 SOP (SKB)
  })
})

// ── 2. perf-ozet.html — birim filter YENİ EKLENDİ ────────────
test.describe('Birim Filter: perf-ozet.html (yeni)', () => {
  test.beforeEach(async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/perf-ozet.html')
    await page.waitForSelector('#perf-ozet-tbody', { timeout: 10000 })
    await waitForBirimOptions(page)
    // İlk render bitsin
    await page.waitForFunction(() => {
      const tb = document.getElementById('perf-ozet-tbody')
      return tb && !tb.innerHTML.includes('Yükleniyor')
    }, { timeout: 10000 })
  })

  test('birim filter dropdown sayfada mevcut', async ({ page }) => {
    await expect(page.locator('#filter-birim')).toBeVisible()
    const opts = await page.locator('#filter-birim option').count()
    expect(opts).toBeGreaterThanOrEqual(3)
  })

  test('birim seçimi öncesi 4 satır görünür', async ({ page }) => {
    const rows = await page.locator('#perf-ozet-tbody tr').count()
    expect(rows).toBe(4)
  })

  test('SKB seçilince sadece 2 satır kalır (SOP-A1, SOP-A2)', async ({ page }) => {
    await page.selectOption('#filter-birim', '1')
    await page.waitForTimeout(500)
    const rows = page.locator('#perf-ozet-tbody tr')
    await expect(rows).toHaveCount(2)
    const text = await page.locator('#perf-ozet-tbody').innerText()
    expect(text).toContain('SOP-A1')
    expect(text).toContain('SOP-A2')
    expect(text).not.toContain('SOP-B1')
    expect(text).not.toContain('SOP-B2')
  })

  test('MEKB seçilince sadece 2 satır kalır (SOP-B1, SOP-B2)', async ({ page }) => {
    await page.selectOption('#filter-birim', '2')
    await page.waitForTimeout(500)
    const rows = page.locator('#perf-ozet-tbody tr')
    await expect(rows).toHaveCount(2)
    const text = await page.locator('#perf-ozet-tbody').innerText()
    expect(text).toContain('SOP-B1')
    expect(text).toContain('SOP-B2')
    expect(text).not.toContain('SOP-A1')
  })

  test('birim seçilince SOP dropdown da daralır', async ({ page }) => {
    const beforeAll = await page.locator('#filter-sop option').count()
    expect(beforeAll).toBeGreaterThanOrEqual(5)
    await page.selectOption('#filter-birim', '1')
    await page.waitForTimeout(300)
    const afterBirim = await page.locator('#filter-sop option').count()
    expect(afterBirim).toBe(3) // Tüm + 2 SOP
  })

  test('"Tüm Birimler"e dönünce 4 satır geri gelir', async ({ page }) => {
    await page.selectOption('#filter-birim', '2')
    await page.waitForTimeout(300)
    await page.selectOption('#filter-birim', '')
    await page.waitForTimeout(500)
    const rows = await page.locator('#perf-ozet-tbody tr').count()
    expect(rows).toBe(4)
  })
})

// ── 3. Diğer 7 sayfa — filter-birim dropdown sağlık kontrolü ─
// Bu sayfaların kendi spec'lerinde davranış testi yapılır; burada
// dropdown'un varlığı + seçilebilirliği smoke düzeyinde garanti edilir.
const SAYFALAR_FILTER_BIRIM = [
  { url: '/index.html', adi: 'kanban (index)' },
  { url: '/pages/harcamalar.html', adi: 'harcamalar' },
  { url: '/pages/izinler.html', adi: 'izinler' },
  { url: '/pages/performans.html', adi: 'performans' },
  { url: '/pages/retro.html', adi: 'retro' },
  { url: '/pages/sprint-ozet.html', adi: 'sprint-ozet' },
  { url: '/pages/sprint-perf-gos.html', adi: 'sprint-perf-gos' },
]

test.describe('Birim Filter: diğer 7 sayfa smoke', () => {
  for (const sayfa of SAYFALAR_FILTER_BIRIM) {
    test(`${sayfa.adi} sayfasında filter-birim mevcut ve dolu`, async ({ page }) => {
      await mockSupabase(page)
      await page.goto(sayfa.url)
      await page.waitForSelector('#filter-birim', { timeout: 10000 })
      await waitForBirimOptions(page)
      const opts = await page.locator('#filter-birim option').count()
      expect(opts).toBeGreaterThanOrEqual(3) // Tüm + en az 2 birim
      // Seçimi değiştir, hata fırlatmamalı
      await page.selectOption('#filter-birim', '1')
      await page.waitForTimeout(300)
      // Sayfa hâlâ ayakta
      await expect(page.locator('#filter-birim')).toBeVisible()
    })
  }
})
