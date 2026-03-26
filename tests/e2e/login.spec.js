// ============================================================
// US-5: Giriş / Çıkış
// Kullanıcı e-posta ve parola ile sisteme giriş yapabilmelidir.
// ============================================================
const { test, expect } = require('@playwright/test')
const { isAuthUrl, isRestUrl } = require('./helpers/auth')

const SUPABASE_AUTH = (url) => isAuthUrl(url.toString())
const SUPABASE_REST = (url) => isRestUrl(url.toString())

test.describe('US-5: Login sayfası', () => {
  test('login sayfası doğru şekilde render olmalı', async ({ page }) => {
    // Oturum yok — localStorage boş, getSession() → null → sayfada kalır
    await page.route(SUPABASE_AUTH, (route) =>
      route.fulfill({ status: 200, contentType: 'application/json', body: '{"data":{"session":null}}' })
    )
    await page.goto('/login.html')

    await expect(page.locator('.login-card')).toBeVisible()
    await expect(page.locator('#email')).toBeVisible()
    await expect(page.locator('#password')).toBeVisible()
    await expect(page.locator('#login-btn')).toBeVisible()
    await expect(page.locator('#error-msg')).toBeHidden()
  })

  test('hatalı kimlik bilgileriyle giriş denenince hata mesajı gösterilmeli', async ({ page }) => {
    // US-5: Auth hatası → hata mesajı gösterilir, yönlendirme olmaz
    await page.route(SUPABASE_AUTH, (route) => {
      const url = route.request().url()
      if (url.includes('/token')) {
        return route.fulfill({
          status: 400,
          contentType: 'application/json',
          body: JSON.stringify({ error: 'invalid_grant', error_description: 'Invalid login credentials' }),
        })
      }
      return route.fulfill({ status: 200, contentType: 'application/json', body: '{"data":{"session":null}}' })
    })

    await page.goto('/login.html')

    await page.fill('#email', 'yanlis@email.com')
    await page.fill('#password', 'yanlis-parola')
    await page.click('#login-btn')

    await expect(page.locator('#error-msg')).toBeVisible()
    await expect(page.locator('#error-msg')).toContainText('E-posta veya parola hatalı')
    expect(page.url()).toMatch(/\/login(\.html?)?$/)
  })

  test('geçerli kimlik bilgileriyle giriş yapılınca index.html\'e yönlendirilmeli', async ({ page }) => {
    // US-5: Başarılı giriş → session döner → index.html'e yönlendirme
    const fakeToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIwMSIsImV4cCI6OTk5OTk5OTk5OX0.fakesig'
    const fakeUser = { id: '01', email: 'fatih@tr90.gov.tr', role: 'authenticated' }
    const fakeSession = { access_token: fakeToken, token_type: 'bearer', expires_in: 3600, expires_at: 9999999999, refresh_token: 'fake', user: fakeUser }

    await page.route(SUPABASE_AUTH, (route) => {
      const url = route.request().url()
      if (url.includes('/token')) {
        return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(fakeSession) })
      }
      if (url.includes('/user')) {
        return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(fakeUser) })
      }
      return route.fulfill({ status: 200, contentType: 'application/json', body: '{}' })
    })
    await page.route(SUPABASE_REST, (route) =>
      route.fulfill({ status: 200, contentType: 'application/json', body: '[]' })
    )

    await page.goto('/login.html')
    await page.fill('#email', 'fatih@tr90.gov.tr')
    await page.fill('#password', 'dogru-parola')
    await page.click('#login-btn')

    // serve redirects /index.html → / so match both
    await page.waitForURL(url => !url.toString().includes('login.html'), { timeout: 8000 })
    expect(page.url()).not.toContain('login.html')
  })

  test('zaten oturumu açık kullanıcı login sayfasına girince index.html\'e yönlenmeli', async ({ page }) => {
    // US-5: Var olan session → login sayfasında kanban'a yönlendirme
    const { mockSupabase } = require('./helpers/auth')
    await mockSupabase(page)
    await page.goto('/login.html')
    await page.waitForURL(url => !url.toString().includes('login.html'), { timeout: 8000 })
    expect(page.url()).not.toContain('login.html')
  })
})
