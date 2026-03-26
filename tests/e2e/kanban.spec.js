// ============================================================
// US-1: Kanban Board — Görev Durumu Güncelleme
// US-2: Kanban Board — Görev Filtreleme
// US-3: Kanban Board — Yeni Görev & Düzenleme
// ============================================================
const { test, expect } = require('@playwright/test')
const { mockSupabase, MOCK_IS_PLANI, SUPABASE_URL } = require('./helpers/auth')

test.describe('US-1: Kanban Board — Sütunlar ve Kartlar', () => {
  test.beforeEach(async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/index.html')
    // Auth ve veri yüklendikten sonra user-name güncellenir — sayfada kaldığımızı doğrular
    await page.waitForFunction(
      () => {
        const el = document.getElementById('user-name')
        return el && el.textContent !== 'Yükleniyor...'
      },
      { timeout: 15000 }
    )
  })

  test('dört Kanban sütunu görünür olmalı', async ({ page }) => {
    // US-1: Backlog, Devam Ediyor, İncelemede, Tamamlandı sütunları mevcut
    await expect(page.locator('#col-backlog')).toBeVisible()
    await expect(page.locator('#col-devam')).toBeVisible()
    await expect(page.locator('#col-inceleme')).toBeVisible()
    await expect(page.locator('#col-tamamlandi')).toBeVisible()
  })

  test('sütun başlıklarında doğru isimler görünmeli', async ({ page }) => {
    await expect(page.locator('.col-backlog .kanban-col-header span').first()).toContainText('Backlog')
    await expect(page.locator('.col-devam .kanban-col-header span').first()).toContainText('Devam Ediyor')
    await expect(page.locator('.col-inceleme .kanban-col-header span').first()).toContainText('İncelemede')
    await expect(page.locator('.col-tamamlandi .kanban-col-header span').first()).toContainText('Tamamlandı')
  })

  test('mock kartlar doğru sütunlara yerleştirilmeli', async ({ page }) => {
    // Mock veri: id=1 → Backlog, id=2 → Devam Ediyor, id=3 → Tamamlandı
    await expect(page.locator('#col-backlog .kanban-card')).toHaveCount(1)
    await expect(page.locator('#col-devam .kanban-card')).toHaveCount(1)
    await expect(page.locator('#col-tamamlandi .kanban-card')).toHaveCount(1)
  })

  test('kartın faaliyet açıklaması görünmeli', async ({ page }) => {
    await expect(page.locator('#col-backlog')).toContainText('Test Görevi 1')
    await expect(page.locator('#col-devam')).toContainText('Test Görevi 2')
  })
})

test.describe('US-1: Drag-and-drop PATCH isteği gönderilmeli', () => {
  test('kart sürüklendiğinde sprint_is_plani PATCH isteği gönderilmeli', async ({ page }) => {
    // US-1: is_durum veritabanında güncellenmeli
    let patchCalled = false
    let patchBody = null

    await mockSupabase(page)

    // PATCH isteğini yakala ve doğrula
    await page.route(`${SUPABASE_URL}/rest/v1/sprint_is_plani**`, async (route) => {
      if (route.request().method() === 'PATCH') {
        patchCalled = true
        patchBody = route.request().postDataJSON()
        return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(MOCK_IS_PLANI[0]) })
      }
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(MOCK_IS_PLANI) })
    })

    await page.goto('/index.html')
    await page.waitForFunction(
      () => { const el = document.getElementById('user-name'); return el && el.textContent !== 'Yükleniyor...' },
      { timeout: 15000 }
    )
    await page.waitForSelector('.kanban-card', { timeout: 10000 })

    // Backlog'daki ilk kartı Devam Ediyor sütununa sürükle (mouse events)
    const card = page.locator('#col-backlog .kanban-card').first()
    const target = page.locator('#col-devam')

    const cardBox = await card.boundingBox()
    const targetBox = await target.boundingBox()

    if (cardBox && targetBox) {
      await page.mouse.move(cardBox.x + cardBox.width / 2, cardBox.y + cardBox.height / 2)
      await page.mouse.down()
      // Kademeli hareket — SortableJS mouse event'lerini yakalaması için
      await page.mouse.move(targetBox.x + targetBox.width / 2, targetBox.y + 30, { steps: 15 })
      await page.mouse.up()
      // PATCH isteği için kısa bekleme
      await page.waitForTimeout(1000)
    }

    expect(patchCalled).toBe(true)
    if (patchBody) {
      expect(patchBody).toHaveProperty('is_durum')
    }
  })
})

test.describe('US-2: Kanban Board — Filtreleme', () => {
  test.beforeEach(async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/index.html')
    await page.waitForFunction(
      () => { const el = document.getElementById('user-name'); return el && el.textContent !== 'Yükleniyor...' },
      { timeout: 15000 }
    )
  })

  test('sprint filtresi dropdown\'ında sprint seçenekleri görünmeli', async ({ page }) => {
    // US-2: sprint_veri'den beslenen sprint dropdown
    const filterSprint = page.locator('#filter-sprint')
    await expect(filterSprint).toBeVisible()
    // Mock verisi 1 sprint döndürüyor — "Tüm Sprintler" + "2024-S1"
    const options = filterSprint.locator('option')
    await expect(options).toHaveCount(2)
  })

  test('ekip üyesi filtresi dropdown\'ı görünmeli', async ({ page }) => {
    // US-2: Ekip üyesi filtresi
    await expect(page.locator('#filter-ekip')).toBeVisible()
  })

  test('sprint filtresi seçildiğinde kartlar filtrelenmeli', async ({ page }) => {
    // US-2: Filtreler uygulanınca board güncellenir
    const filterSprint = page.locator('#filter-sprint')
    await filterSprint.selectOption('2024-S1')
    await page.waitForTimeout(500)
    // Kartlar hâlâ görünür (tüm mock kartlar 2024-S1 döneminde)
    await expect(page.locator('.kanban-card').first()).toBeVisible()
  })
})

test.describe('US-3: Kanban Board — Yeni Görev & Düzenleme', () => {
  test.beforeEach(async ({ page }) => {
    await mockSupabase(page)
    await page.goto('/index.html')
    // initModal() is called AFTER loadBoard() renders cards — wait for cards to ensure modal handlers are ready
    await page.waitForSelector('.kanban-card', { timeout: 15000 })
  })

  test('Yeni Görev butonuna tıklanınca modal açılmalı', async ({ page }) => {
    // US-3: Yeni görev ekleme modal'ı açılır
    await page.click('#btn-yeni-gorev')
    await expect(page.locator('#modal-overlay')).not.toHaveClass(/hidden/)
    await expect(page.locator('#modal-title')).toContainText('Yeni Görev')
  })

  test('modal form alanları doldurulabilmeli', async ({ page }) => {
    // US-3: Sprint, faaliyet, plan süre ve ekip üyesi alanları
    await page.click('#btn-yeni-gorev')
    await page.waitForSelector('#modal-overlay:not(.hidden)', { timeout: 5000 })

    await page.fill('#g-faaliyetleri', 'Yeni test görevi')
    await page.fill('#g-plansure', '3')

    await expect(page.locator('#g-faaliyetleri')).toHaveValue('Yeni test görevi')
    await expect(page.locator('#g-plansure')).toHaveValue('3')
  })

  test('İptal butonuna basınca modal kapanmalı', async ({ page }) => {
    // US-3: Modal iptal edilebilir
    await page.click('#btn-yeni-gorev')
    await page.waitForSelector('#modal-overlay:not(.hidden)', { timeout: 5000 })
    await page.click('#modal-cancel')
    await expect(page.locator('#modal-overlay')).toHaveClass(/hidden/)
  })

  test('mevcut karta tıklanınca düzenleme modal\'ı açılmalı', async ({ page }) => {
    // US-3: Kart detay/düzenleme modal'ı açılır
    await page.waitForSelector('.kanban-card', { timeout: 10000 })
    await page.locator('.kanban-card').first().click()
    await expect(page.locator('#modal-overlay')).not.toHaveClass(/hidden/)
  })
})
