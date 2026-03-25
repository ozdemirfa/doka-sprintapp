// ============================================================
// Auth Modülü — Giriş, Çıkış, Session Yönetimi
// ============================================================
import { supabase } from './supabase.js'

/**
 * E-posta ve parola ile giriş yapar
 * @param {string} email
 * @param {string} password
 * @returns {Promise<{session, error}>}
 */
export async function signIn(email, password) {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password })
  return { session: data?.session, error }
}

/**
 * Oturumu kapatır ve login sayfasına yönlendirir
 */
export async function signOut() {
  await supabase.auth.signOut()
  window.location.href = getLoginPath()
}

/**
 * Mevcut session'ı döndürür
 * @returns {Promise<Session|null>}
 */
export async function getSession() {
  const { data: { session } } = await supabase.auth.getSession()
  return session
}

/**
 * Auth guard — session yoksa login'e yönlendirir
 * Her korumalı sayfanın başında çağrılır
 * @returns {Promise<Session>} geçerli session
 */
export async function requireAuth() {
  const session = await getSession()
  if (!session) {
    window.location.href = getLoginPath()
    throw new Error('Kimlik doğrulanmadı — login sayfasına yönlendiriliyor')
  }
  return session
}

/**
 * Mevcut sayfanın konumuna göre doğru login yolu döndürür
 */
function getLoginPath() {
  const path = window.location.pathname
  // pages/ dizinindeki sayfalar için ../login.html
  if (path.includes('/pages/')) return '../login.html'
  return '/login.html'
}

/**
 * Auth state değişikliklerini dinler
 * @param {Function} callback (event, session) =>
 */
export function onAuthChange(callback) {
  return supabase.auth.onAuthStateChange(callback)
}
