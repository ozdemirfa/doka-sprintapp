// ============================================================
// Paylaşılan Yardımcı Fonksiyonlar — TR90 Sprint Kanban
// ============================================================

/**
 * Tarih nesnesi veya string'i Türkçe yerel formata çevirir
 * @param {string|Date} date
 * @returns {string} örn: "15.03.2026"
 */
export function formatDate(date) {
  if (!date) return '—'
  const d = new Date(date)
  if (isNaN(d.getTime())) return '—'
  return d.toLocaleDateString('tr-TR', { day: '2-digit', month: '2-digit', year: 'numeric' })
}

/**
 * Sayıyı Türkçe para formatına çevirir
 * @param {number} amount
 * @returns {string} örn: "1.250.000,50 ₺"
 */
export function formatCurrency(amount) {
  if (amount == null || isNaN(amount)) return '—'
  return new Intl.NumberFormat('tr-TR', {
    style: 'currency',
    currency: 'TRY',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(amount)
}

/**
 * Sayıyı yüzde formatına çevirir
 * @param {number} value
 * @param {number} decimals
 * @returns {string} örn: "98.51%"
 */
export function formatPercent(value, decimals = 1) {
  if (value == null || isNaN(value)) return '—'
  return `${Number(value).toFixed(decimals)}%`
}

/**
 * Hepiniss A.ort hesabı: (rol + hakkında) / 2
 * (gort adıyla geriye dönük uyumlu tutuldu)
 * @param {number} rol
 * @param {number} hakkinda
 * @returns {number}
 */
export function calcGort(rol, hakkinda) {
  if (!rol || !hakkinda) return 0
  return (rol + hakkinda) / 2
}
export { calcGort as calcAort }

/**
 * GKİ hesabı: T.Skor / (sure_gun × ekip - izin) × 100
 * @param {number} tSkor
 * @param {number} sureGun
 * @param {number} ekip
 * @param {number} izin
 * @returns {number}
 */
export function calcGki(tSkor, sureGun, ekip, izin = 0) {
  const payda = sureGun * ekip - izin
  if (payda <= 0) return 0
  return (tSkor / payda) * 100
}

/**
 * Sprint seçim dropdown'ını doldurur
 * @param {HTMLSelectElement} selectEl
 * @param {Array} sprints — sprint_veri kayıtları
 * @param {string|number} selectedVal
 */
export function populateSprintDropdown(selectEl, sprints, selectedVal = null) {
  selectEl.innerHTML = ''
  sprints.forEach(s => {
    const opt = document.createElement('option')
    opt.value = s.sprint_donem
    opt.textContent = `${s.sprint_donem} — ${s.sprint_adi || ''} (${formatDate(s.baslangic)} – ${formatDate(s.bitis)})`
    if (String(s.sprint_donem) === String(selectedVal)) opt.selected = true
    selectEl.appendChild(opt)
  })
}

/**
 * Toast bildirimi gösterir
 * @param {string} message
 * @param {'success'|'error'|'warning'} type
 */
export function showToast(message, type = 'success') {
  let toast = document.getElementById('app-toast')
  if (!toast) {
    toast = document.createElement('div')
    toast.id = 'app-toast'
    toast.className = 'toast'
    document.body.appendChild(toast)
  }
  toast.textContent = message
  toast.className = `toast ${type}`
  // Trigger reflow
  void toast.offsetWidth
  toast.classList.add('show')
  setTimeout(() => toast.classList.remove('show'), 3000)
}

/**
 * Bugünün tarihini YYYY-MM-DD formatında döndürür
 * @returns {string}
 */
export function todayISO() {
  return new Date().toISOString().split('T')[0]
}

/**
 * Aylık plan anahtar etiketleri (Gantt için)
 */
export const AY_LABELS = {
  oca: 'Oca', sub: 'Şub', mar: 'Mar', nis: 'Nis',
  may: 'May', haz: 'Haz', tem: 'Tem', agu: 'Ağu',
  eyl: 'Eyl', eki: 'Eki', kas: 'Kas', ara: 'Ara'
}

export const AY_KEYS = Object.keys(AY_LABELS)

/**
 * Kullanıcı adını session'dan alıp göstermek için personel tablosunu sorgular
 * Bu async helper her sayfada kullanılır
 * @param {object} supabase
 * @param {string} authId
 * @returns {Promise<object|null>} personel kaydı
 */
export async function getPersonel(supabase, authId) {
  if (!authId) return null
  const { data } = await supabase
    .from('personel')
    .select('pkod, ad, soyad, bkod, rol_kodu')
    .eq('auth_id', authId)
    .limit(1)
  return data?.[0] ?? null
}

/**
 * Sidebar'daki kullanıcı bilgisi alanını günceller
 * @param {string} ad
 * @param {string} soyad
 */
export function renderUserInfo(ad, soyad) {
  const el = document.getElementById('user-name')
  if (el) el.textContent = `${ad} ${soyad}`
}

/**
 * Yönetici olmayan kullanıcılar için Ayarlar menü linkini gizler
 * @param {object|null} personel
 */
export function hideAyarlarForNonAdmin(personel) {
  if (personel?.rol_kodu !== 'yönetici') {
    document.querySelectorAll('a[href*="ayarlar.html"]').forEach(el => {
      el.style.display = 'none'
    })
  }
}

/**
 * Personelin izleyici (read-only) olup olmadığını döndürür
 * @param {object|null} personel
 * @returns {boolean}
 */
export function isReadOnly(personel) {
  return personel?.rol_kodu === 'izleyici'
}

/**
 * İzleyici personel için body'e viewer-mode class'ı ekler
 * CSS ile .btn-gold, .row-action vb. gizlenir
 * @param {object|null} personel
 */
export function applyViewerRestrictions(personel) {
  if (isReadOnly(personel)) {
    document.body.classList.add('viewer-mode')
  }
}

/**
 * Sadece Aktif ve izleyici olmayan personeli döndürür (form dropdownları için)
 * @param {object} supabase
 * @returns {Promise<Array>}
 */
export async function loadActivePersonel(supabase) {
  const { data } = await supabase
    .from('personel')
    .select('pkod,ad,soyad,bkod,rol_kodu,durum')
    .neq('rol_kodu', 'izleyici')
    .neq('durum', 'Pasif')
    .order('ad')
  return data || []
}

/**
 * Aktif birimleri döndürür
 * @param {object} supabase
 * @returns {Promise<Array>}
 */
export async function loadBirimler(supabase) {
  const { data } = await supabase
    .from('birimler')
    .select('bkod,birim_kisa,birim_adi')
    .eq('durum', 'Aktif')
    .order('birim_kisa')
  return data || []
}

/**
 * Birim dropdown'ını doldurur
 * @param {HTMLSelectElement} selectEl
 * @param {Array} birimler
 */
export function populateBirimDropdown(selectEl, birimler) {
  selectEl.innerHTML = '<option value="">Tüm Birimler</option>'
  birimler.forEach(b => {
    const opt = document.createElement('option')
    opt.value = b.bkod
    opt.textContent = b.birim_kisa
    selectEl.appendChild(opt)
  })
}
