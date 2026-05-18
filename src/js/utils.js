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
 * Yönetici olmayan kullanıcılar için Ayarlar/Raporlar/Yetki menü linklerini DOM'dan kaldırır.
 * S-006: el.remove() kullanır (display:none yerine) — DOM'a erişim tamamen engellenir.
 * S-007: Grup üyeliğini de kontrol eder (rol_kodu yönetici VEYA yönetici grubunda).
 * @param {object|null} personel
 * @param {object} supabase — Supabase client (grup üyeliği sorgusu için)
 * @returns {Promise<void>}
 */
export async function hideAyarlarForNonAdmin(personel, supabase) {
  // S-007: grup üyeliğini de kontrol et
  let isAdmin = personel?.rol_kodu === 'yönetici'
  if (!isAdmin && personel?.pkod && supabase) {
    try {
      const { loadCurrentGroupNames } = await import('./permissions.js')
      const groupNames = await loadCurrentGroupNames(supabase, personel.pkod)
      isAdmin = groupNames.includes('yönetici')
    } catch (_) {
      // permissions.js yüklenemezse sadece rol_kodu'na güven
    }
  }
  if (!isAdmin) {
    // S-006: display:none yerine remove() — DOM'dan tamamen kaldır
    document.querySelectorAll('a[href*="ayarlar.html"]').forEach(el => el.remove())
    document.querySelectorAll('a[href*="raporlar.html"]').forEach(el => el.remove())
    document.querySelectorAll('a[href*="yetki-yonetimi.html"]').forEach(el => el.remove())
  }
  if (personel?.rol_kodu === 'gs') {
    document.querySelectorAll('a[href*="retro.html"]').forEach(el => el.remove())
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

// ============================================================
// UI Yardımcıları — modal confirm/alert + mobil sidebar toggle
// ============================================================

let _confirmEl = null

function _ensureConfirmShell() {
  if (_confirmEl) return _confirmEl
  const wrap = document.createElement('div')
  wrap.className = 'modal-overlay hidden'
  wrap.id = 'app-confirm'
  wrap.setAttribute('role', 'dialog')
  wrap.setAttribute('aria-modal', 'true')
  wrap.setAttribute('aria-labelledby', 'app-confirm-title')
  wrap.setAttribute('data-testid', 'confirm-dialog')
  wrap.innerHTML = `
    <div class="modal-box modal-sm" role="document">
      <h3 class="confirm-title" id="app-confirm-title"></h3>
      <p class="confirm-message" id="app-confirm-msg"></p>
      <div class="modal-actions">
        <button type="button" class="btn-secondary" data-confirm="cancel" data-testid="confirm-cancel">Vazgeç</button>
        <button type="button" class="btn-primary" data-confirm="ok" data-testid="confirm-ok">Tamam</button>
      </div>
    </div>
  `
  document.body.appendChild(wrap)
  _confirmEl = wrap
  return wrap
}

/**
 * Stillenmiş onay diyaloğu. Promise<boolean> döndürür.
 * @param {{title?:string, message:string, confirmText?:string, cancelText?:string, danger?:boolean}} opts
 * @returns {Promise<boolean>}
 */
export function showConfirm(opts) {
  const { title = 'Onay', message, confirmText = 'Tamam', cancelText = 'Vazgeç', danger = false } = opts
  const wrap = _ensureConfirmShell()
  wrap.querySelector('#app-confirm-title').textContent = title
  wrap.querySelector('#app-confirm-msg').textContent = message
  const okBtn = wrap.querySelector('[data-confirm="ok"]')
  const cancelBtn = wrap.querySelector('[data-confirm="cancel"]')
  okBtn.textContent = confirmText
  cancelBtn.textContent = cancelText
  okBtn.className = danger ? 'btn-danger' : 'btn-primary'

  return new Promise(resolve => {
    function close(result) {
      wrap.classList.add('hidden')
      okBtn.removeEventListener('click', onOk)
      cancelBtn.removeEventListener('click', onCancel)
      wrap.removeEventListener('click', onBackdrop)
      document.removeEventListener('keydown', onKey)
      resolve(result)
    }
    function onOk()     { close(true) }
    function onCancel() { close(false) }
    function onBackdrop(e) { if (e.target === wrap) close(false) }
    function onKey(e) {
      if (e.key === 'Escape') close(false)
      if (e.key === 'Enter')  close(true)
    }
    okBtn.addEventListener('click', onOk)
    cancelBtn.addEventListener('click', onCancel)
    wrap.addEventListener('click', onBackdrop)
    document.addEventListener('keydown', onKey)
    wrap.classList.remove('hidden')
    setTimeout(() => okBtn.focus(), 50)
  })
}

/**
 * Stillenmiş bilgilendirme diyaloğu (tek butonlu).
 * @param {string|{title?:string, message:string}} arg
 * @returns {Promise<void>}
 */
export function showAlert(arg) {
  const opts = typeof arg === 'string' ? { message: arg } : arg
  return showConfirm({ ...opts, title: opts.title || 'Bilgi', confirmText: 'Tamam', cancelText: '' })
    .then(() => undefined)
}

/**
 * Mobil ekranlarda topbar'a hamburger butonunu enjekte eder ve sidebar.open toggle'ını yönetir.
 * Idempotent — birden fazla çağrı emniyetli.
 */
export function initMobileSidebarToggle() {
  const sidebar = document.getElementById('sidebar') || document.querySelector('.sidebar')
  if (!sidebar) return
  if (document.getElementById('menu-toggle')) return

  const btn = document.createElement('button')
  btn.id = 'menu-toggle'
  btn.type = 'button'
  btn.className = 'menu-toggle'
  btn.setAttribute('aria-label', 'Menüyü aç/kapat')
  btn.setAttribute('aria-controls', sidebar.id || 'sidebar')
  btn.setAttribute('aria-expanded', 'false')
  btn.innerHTML = '<span aria-hidden="true">☰</span>'

  const backdrop = document.createElement('div')
  backdrop.className = 'sidebar-backdrop'
  backdrop.id = 'sidebar-backdrop'

  document.body.appendChild(btn)
  document.body.appendChild(backdrop)

  function close() {
    sidebar.classList.remove('open')
    backdrop.classList.remove('show')
    btn.setAttribute('aria-expanded', 'false')
  }
  function toggle() {
    const isOpen = sidebar.classList.toggle('open')
    backdrop.classList.toggle('show', isOpen)
    btn.setAttribute('aria-expanded', String(isOpen))
  }

  btn.addEventListener('click', toggle)
  backdrop.addEventListener('click', close)
  document.addEventListener('keydown', e => { if (e.key === 'Escape') close() })
  sidebar.addEventListener('click', e => {
    if (e.target.closest('a[href]')) close()
  })
}

/**
 * Form input'una `is-invalid` class'ı ekler ve mesaj gösterir.
 * @param {HTMLElement} input
 * @param {string} message
 */
export function setFieldError(input, message) {
  if (!input) return
  input.classList.add('is-invalid')
  input.setAttribute('aria-invalid', 'true')
  let msg = input.parentElement?.querySelector('.form-error-msg')
  if (!msg) {
    msg = document.createElement('p')
    msg.className = 'form-error-msg'
    input.parentElement?.appendChild(msg)
  }
  msg.textContent = message
}

/**
 * Form input'undan hata izlerini temizler.
 * @param {HTMLElement} input
 */
export function clearFieldError(input) {
  if (!input) return
  input.classList.remove('is-invalid')
  input.removeAttribute('aria-invalid')
  const msg = input.parentElement?.querySelector('.form-error-msg')
  if (msg) msg.remove()
}

// Tüm sayfalarda otomatik hamburger toggle (idempotent — birden fazla import güvenli)
if (typeof window !== 'undefined') {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initMobileSidebarToggle)
  } else {
    initMobileSidebarToggle()
  }
}
