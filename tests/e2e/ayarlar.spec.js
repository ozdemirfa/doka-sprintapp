// ============================================================
// Ayarlar sayfası E2E testleri
// Sekmeler: SOP, Kategoriler, Perf.Göstergeleri, Personel,
//           Sprint Dönemleri, Yıllık Bütçeler, Birimler
// ============================================================
const { test, expect } = require('@playwright/test')
const { mockSupabase } = require('./helpers/auth')

test.describe('Ayarlar: Sayfa Yüklenmesi', () => {
  test('ayarlar sayfası JS hatası olmadan yüklenmeli', async ({ page }) => {
    const errors = []
    page.on('pageerror', (err) => errors.push(err.message))
    await mockSupabase(page)
    await page.goto('/pages/ayarlar.html')
    await page.waitForSelector('.tab-btn', { timeout: 10000 })
    await page.waitForTimeout(1000)

    const criticalErrors = errors.filter(e =>
      !e.includes('WebSocket') && !e.includes('realtime') && !e.includes('net::ERR')
    )
    expect(criticalErrors).toHaveLength(0)
  })

  test('sayfa başlığı "Ayarlar" içermeli', async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/ayarlar.html')
    await page.waitForSelector('.tab-btn', { timeout: 10000 })
    await expect(page.locator('h2')).toContainText('Ayarlar')
  })
})

test.describe('Ayarlar: Sekme Navigasyonu', () => {
  test.beforeEach(async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/ayarlar.html')
    await page.waitForSelector('.tab-btn', { timeout: 10000 })
  })

  test('tüm sekme butonları görünmeli', async ({ page }) => {
    await expect(page.locator('[data-tab="soplar"]')).toBeVisible()
    await expect(page.locator('[data-tab="kategoriler"]')).toBeVisible()
    await expect(page.locator('[data-tab="perf-gostergeler"]')).toBeVisible()
    await expect(page.locator('[data-tab="personel"]')).toBeVisible()
    await expect(page.locator('[data-tab="sprint-donemler"]')).toBeVisible()
    await expect(page.locator('[data-tab="yil-butce"]')).toBeVisible()
    await expect(page.locator('[data-tab="birimler"]')).toBeVisible()
  })

  test('Yıllık Bütçeler sekmesine tıklanınca panel görünmeli', async ({ page }) => {
    await page.click('[data-tab="yil-butce"]')
    await expect(page.locator('#tab-yil-butce')).toBeVisible()
  })

  test('Birimler sekmesine tıklanınca panel görünmeli', async ({ page }) => {
    await page.click('[data-tab="birimler"]')
    await expect(page.locator('#tab-birimler')).toBeVisible()
  })
})

test.describe('Ayarlar: SOP Sekmesi', () => {
  test.beforeEach(async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/ayarlar.html')
    await page.waitForSelector('#soplar-tbody', { timeout: 10000 })
  })

  test('SOP tablosu mevcut olmalı', async ({ page }) => {
    await expect(page.locator('#soplar-tbody')).toBeAttached()
  })

  test('SOP ekleme form alanları görünmeli', async ({ page }) => {
    await expect(page.locator('#sop-kisa')).toBeVisible()
    await expect(page.locator('#sop-adi')).toBeVisible()
    await expect(page.locator('#btn-sop-ekle')).toBeVisible()
  })

  test('SOP form alanlarına değer girilebilmeli', async ({ page }) => {
    await page.fill('#sop-kisa', 'TST')
    await page.fill('#sop-adi', 'Test SOP')
    await expect(page.locator('#sop-kisa')).toHaveValue('TST')
    await expect(page.locator('#sop-adi')).toHaveValue('Test SOP')
  })
})

test.describe('Ayarlar: Personel Sekmesi', () => {
  test.beforeEach(async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/ayarlar.html')
    // Personel sekmesini aç
    await page.click('[data-tab="personel"]')
    await page.waitForSelector('#personel-tbody', { timeout: 10000 })
  })

  test('personel tablosu mevcut olmalı', async ({ page }) => {
    await expect(page.locator('#personel-tbody')).toBeAttached()
  })

  test('"+ Yeni Personel" butonu görünmeli', async ({ page }) => {
    // Personel form modal dinamik oluşturuluyor (#btn-p-ekle ile açılır)
    await expect(page.locator('#btn-p-ekle')).toBeVisible()
  })

  test('personel ekleme modal form alanları görünmeli', async ({ page }) => {
    // Form elemanları modal içinde dinamik oluşturuluyor
    await page.click('#btn-p-ekle')
    await page.waitForSelector('#edit-pad', { timeout: 5000 })
    await expect(page.locator('#edit-pad')).toBeVisible()    // Ad
    await expect(page.locator('#edit-psoyad')).toBeVisible() // Soyad
    await expect(page.locator('#edit-pbkod')).toBeVisible()  // Birim
    await expect(page.locator('#edit-prol')).toBeVisible()   // Rol
  })

  test('personel rol dropdown standart ve yönetici seçeneklerini içermeli', async ({ page }) => {
    await page.click('#btn-p-ekle')
    await page.waitForSelector('#edit-prol', { timeout: 5000 })
    const options = await page.locator('#edit-prol option').allTextContents()
    expect(options).toContain('Standart')
    expect(options).toContain('Yönetici')
  })

  test('personel rol dropdown başkan seçeneğini içermeli', async ({ page }) => {
    // başkan rolü: birim bazlı drag yetkisi ve yönetim görünümü için eklendi
    await page.click('#btn-p-ekle')
    await page.waitForSelector('#edit-prol', { timeout: 5000 })
    const options = await page.locator('#edit-prol option').allTextContents()
    expect(options).toContain('Başkan')
  })

  test('birim seçim dropdown mevcut olmalı', async ({ page }) => {
    await page.click('#btn-p-ekle')
    await page.waitForSelector('#edit-pbkod', { timeout: 5000 })
    await expect(page.locator('#edit-pbkod')).toBeVisible()
  })
})

test.describe('Ayarlar: Yıllık Bütçeler Sekmesi', () => {
  test.beforeEach(async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/ayarlar.html')
    await page.click('[data-tab="yil-butce"]')
    await page.waitForSelector('#yilbutce-tbody', { timeout: 10000 })
  })

  test('yıllık bütçe tablosu mevcut olmalı', async ({ page }) => {
    await expect(page.locator('#yilbutce-tbody')).toBeAttached()
  })

  test('faaliyet seçim dropdown görünmeli', async ({ page }) => {
    await expect(page.locator('#yb-faaliyet-id')).toBeVisible()
  })

  test('yıl ve bütçe alanları görünmeli', async ({ page }) => {
    await expect(page.locator('#yb-yil')).toBeVisible()
    await expect(page.locator('#yb-butce')).toBeVisible()
  })

  test('ekle butonu görünmeli', async ({ page }) => {
    await expect(page.locator('#btn-yb-ekle')).toBeVisible()
  })
})

test.describe('Ayarlar: Birimler Sekmesi', () => {
  test.beforeEach(async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/ayarlar.html')
    await page.click('[data-tab="birimler"]')
    await page.waitForSelector('#birimler-tbody', { timeout: 10000 })
  })

  test('birimler tablosu mevcut olmalı', async ({ page }) => {
    await expect(page.locator('#birimler-tbody')).toBeAttached()
  })

  test('birim ekleme form alanları görünmeli', async ({ page }) => {
    await expect(page.locator('#bir-kisa')).toBeVisible()
    await expect(page.locator('#bir-adi')).toBeVisible()
    await expect(page.locator('#btn-bir-ekle')).toBeVisible()
  })

  test('birim kısa adı alanına değer girilebilmeli', async ({ page }) => {
    await page.fill('#bir-kisa', 'SKB')
    await expect(page.locator('#bir-kisa')).toHaveValue('SKB')
  })
})

test.describe('Ayarlar: Sprint Dönemleri Sekmesi', () => {
  test.beforeEach(async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/pages/ayarlar.html')
    await page.click('[data-tab="sprint-donemler"]')
    await page.waitForSelector('#sprint-tbody', { timeout: 10000 })
  })

  test('sprint dönemi tablosu mevcut olmalı', async ({ page }) => {
    await expect(page.locator('#sprint-tbody')).toBeAttached()
  })

  test('sprint ekleme formu görünmeli', async ({ page }) => {
    await expect(page.locator('#sv-donem')).toBeVisible()
    await expect(page.locator('#sv-adi')).toBeVisible()
    await expect(page.locator('#btn-sv-ekle')).toBeVisible()
  })
})
