// ============================================================
// Kanban Board — TR90 Sprint Kanban
// ============================================================
import { supabase } from './supabase.js'
import { requireAuth, signOut } from './auth.js'
import { formatDate, formatCurrency, getPersonel, renderUserInfo, showToast, todayISO, populateSprintDropdown } from './utils.js'
import Sortable from 'https://cdn.jsdelivr.net/npm/sortablejs/+esm'

// ── State ────────────────────────────────────────────────────
let allGorevler = []
let sprints = []
let personeller = []
let altFaaliyetler = []
let currentSprint = null
let currentUser = null
let realtimeChannel = null

// ── Init ─────────────────────────────────────────────────────
const session = await requireAuth()
currentUser = session.user

const personel = await getPersonel(supabase, currentUser.id)
if (personel) renderUserInfo(personel.ad, personel.soyad)

document.getElementById('logout-btn').addEventListener('click', () => signOut())

await loadReferenceData()
await loadBoard()
initSortable()
initRealtime()
initFilters()
initModal()

// ── Veri Yükleme ─────────────────────────────────────────────

async function loadReferenceData() {
  const [sprintRes, personelRes, altFaalRes] = await Promise.all([
    supabase.from('sprint_veri').select('sprint_donem,sprint_adi,baslangic,bitis').order('sprint_donem', { ascending: false }),
    supabase.from('personel').select('ad,soyad').order('ad'),
    supabase.from('alt_faaliyetler').select('sno,fkod,aciklama').order('sno')
  ])

  sprints = sprintRes.data || []
  personeller = personelRes.data || []
  altFaaliyetler = altFaalRes.data || []

  // Sprint filtre dropdown
  const sprintFilter = document.getElementById('filter-sprint')
  sprints.forEach(s => {
    const opt = document.createElement('option')
    opt.value = s.sprint_donem
    opt.textContent = `${s.sprint_donem} — ${s.sprint_adi || ''}`
    sprintFilter.appendChild(opt)
  })

  // Aktif sprinti varsayılan seç (en son aktif)
  if (sprints.length > 0) {
    currentSprint = sprints[0].sprint_donem
    sprintFilter.value = currentSprint
  }

  // Ekip filtresi
  const ekipFilter = document.getElementById('filter-ekip')
  personeller.forEach(p => {
    const opt = document.createElement('option')
    opt.value = p.ad
    opt.textContent = `${p.ad} ${p.soyad}`
    ekipFilter.appendChild(opt)
  })

  // Kendi adını varsayılan seç
  if (personel) {
    ekipFilter.value = personel.ad
  }
}

async function loadBoard() {
  let query = supabase.from('sprint_is_plani').select('*').order('id')

  const sprintVal = document.getElementById('filter-sprint').value
  const ekipVal = document.getElementById('filter-ekip').value

  if (sprintVal) query = query.eq('sprint_donem', sprintVal)
  if (ekipVal) query = query.eq('ekip_uyesi', ekipVal)

  const { data, error } = await query

  if (error) {
    showToast('Görevler yüklenemedi: ' + error.message, 'error')
    return
  }

  allGorevler = data || []
  renderBoard()
}

// ── Board Render ──────────────────────────────────────────────

function renderBoard() {
  const cols = {
    '': document.getElementById('col-backlog'),
    'Başladı': document.getElementById('col-devam'),
    'İncelemede': document.getElementById('col-inceleme'),
    'Tamamlandı': document.getElementById('col-tamamlandi')
  }

  // Temizle
  Object.values(cols).forEach(c => { c.innerHTML = '' })

  let counts = { '': 0, 'Başladı': 0, 'İncelemede': 0, 'Tamamlandı': 0 }

  allGorevler.forEach(g => {
    const key = g.is_durum || ''
    if (!(key in cols)) return
    cols[key].appendChild(buildCard(g))
    counts[key]++
  })

  document.getElementById('badge-backlog').textContent = counts['']
  document.getElementById('badge-devam').textContent = counts['Başladı']
  document.getElementById('badge-inceleme').textContent = counts['İncelemede']
  document.getElementById('badge-tamamlandi').textContent = counts['Tamamlandı']

  const total = Object.values(counts).reduce((a, b) => a + b, 0)
  document.getElementById('board-empty').classList.toggle('hidden', total > 0)
}

function buildCard(g) {
  const card = document.createElement('div')
  card.className = 'kanban-card'
  card.dataset.id = g.id

  const baslama = g.baslama_t ? `<span style="font-size:0.65rem;color:#94a3b8;">▶ ${formatDate(g.baslama_t)}</span>` : ''
  const tamamlanma = g.tamamlanma_t ? `<span style="font-size:0.65rem;color:#94a3b8;">✓ ${formatDate(g.tamamlanma_t)}</span>` : ''
  const butce = g.harcanan_butce ? `<span class="badge-sure">${formatCurrency(g.harcanan_butce)}</span>` : ''

  card.innerHTML = `
    <div class="card-title">${escHtml(g.sprint_faaliyetleri || '—')}</div>
    <div class="card-meta">
      <span class="badge-sno">S.${g.sno || '?'}</span>
      ${g.ekip_uyesi ? `<span class="badge-ekip">${escHtml(g.ekip_uyesi)}</span>` : ''}
      ${g.plan_sure ? `<span class="badge-sure">${g.plan_sure}g</span>` : ''}
      ${butce}
    </div>
    <div style="margin-top:6px;display:flex;gap:6px;flex-wrap:wrap;">
      ${baslama}${tamamlanma}
    </div>
  `

  card.addEventListener('click', () => openEditModal(g))
  return card
}

function escHtml(str) {
  return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')
}

// ── Sortable (Drag & Drop) ────────────────────────────────────

function initSortable() {
  const colIds = ['col-backlog', 'col-devam', 'col-inceleme', 'col-tamamlandi']
  colIds.forEach(colId => {
    Sortable.create(document.getElementById(colId), {
      group: 'kanban',
      animation: 150,
      ghostClass: 'sortable-ghost',
      dragClass: 'sortable-drag',
      onEnd: handleDragEnd
    })
  })
}

async function handleDragEnd(evt) {
  const cardEl = evt.item
  const newColEl = evt.to
  const newDurum = newColEl.dataset.durum || null
  const gorevId = Number(cardEl.dataset.id)

  const gorev = allGorevler.find(g => g.id === gorevId)
  if (!gorev) return

  const eskiDurum = gorev.is_durum || null
  if (eskiDurum === newDurum) return

  // Tarih güncellemeleri
  const updates = { is_durum: newDurum || null }

  if (!eskiDurum && newDurum === 'Başladı') {
    updates.baslama_t = todayISO()
  }
  if (newDurum === 'İncelemede' && eskiDurum !== 'İncelemede') {
    updates.inceleme_t = todayISO()
  }
  if (newDurum === 'Tamamlandı') {
    updates.tamamlanma_t = todayISO()
    // bitis_donem: mevcut filtreli sprint ya da gorev'in sprint_donem'i
    const sprintVal = document.getElementById('filter-sprint').value
    updates.bitis_donem = sprintVal ? Number(sprintVal) : gorev.sprint_donem
  }

  const { error } = await supabase.from('sprint_is_plani').update(updates).eq('id', gorevId)

  if (error) {
    showToast('Güncelleme başarısız: ' + (error.message.includes('new row') ? 'Yetki yok.' : error.message), 'error')
    // Geri al
    await loadBoard()
    return
  }

  // Local state güncelle
  Object.assign(gorev, updates)
  updateBadges()
  showToast('Görev taşındı.', 'success')
}

function updateBadges() {
  const counts = { '': 0, 'Başladı': 0, 'İncelemede': 0, 'Tamamlandı': 0 }
  allGorevler.forEach(g => {
    const key = g.is_durum || ''
    if (key in counts) counts[key]++
  })
  document.getElementById('badge-backlog').textContent = counts['']
  document.getElementById('badge-devam').textContent = counts['Başladı']
  document.getElementById('badge-inceleme').textContent = counts['İncelemede']
  document.getElementById('badge-tamamlandi').textContent = counts['Tamamlandı']
}

// ── Realtime ──────────────────────────────────────────────────

function initRealtime() {
  realtimeChannel = supabase
    .channel('sprint_is_plani_changes')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'sprint_is_plani' }, handleRealtimeChange)
    .subscribe()
}

function handleRealtimeChange(payload) {
  const { eventType, new: newRow, old: oldRow } = payload

  if (eventType === 'INSERT') {
    allGorevler.push(newRow)
    const key = newRow.is_durum || ''
    const col = getColEl(key)
    if (col) col.appendChild(buildCard(newRow))
    updateBadges()

  } else if (eventType === 'UPDATE') {
    const idx = allGorevler.findIndex(g => g.id === newRow.id)
    if (idx !== -1) {
      allGorevler[idx] = newRow
    }
    // Kartı güncelle
    const existing = document.querySelector(`[data-id="${newRow.id}"]`)
    const newCard = buildCard(newRow)
    const newColEl = getColEl(newRow.is_durum || '')
    if (existing && newColEl) {
      if (existing.parentElement === newColEl) {
        existing.replaceWith(newCard)
      } else {
        existing.remove()
        newColEl.appendChild(newCard)
      }
    } else if (newColEl) {
      newColEl.appendChild(newCard)
    }
    updateBadges()

  } else if (eventType === 'DELETE') {
    allGorevler = allGorevler.filter(g => g.id !== oldRow.id)
    const existing = document.querySelector(`[data-id="${oldRow.id}"]`)
    if (existing) existing.remove()
    updateBadges()
  }
}

function getColEl(durum) {
  const map = {
    '': document.getElementById('col-backlog'),
    'Başladı': document.getElementById('col-devam'),
    'İncelemede': document.getElementById('col-inceleme'),
    'Tamamlandı': document.getElementById('col-tamamlandi')
  }
  return map[durum] || null
}

// ── Filtreler ─────────────────────────────────────────────────

function initFilters() {
  document.getElementById('filter-sprint').addEventListener('change', loadBoard)
  document.getElementById('filter-ekip').addEventListener('change', loadBoard)
}

// ── Modal ─────────────────────────────────────────────────────

function initModal() {
  const overlay = document.getElementById('modal-overlay')
  const form = document.getElementById('gorev-form')

  // Sprint dropdown modal içinde
  const gSprint = document.getElementById('g-sprint')
  populateSprintDropdown(gSprint, sprints)

  // Alt faaliyet dropdown
  const gSno = document.getElementById('g-sno')
  gSno.innerHTML = '<option value="">Seçiniz...</option>'
  altFaaliyetler.forEach(af => {
    const opt = document.createElement('option')
    opt.value = af.sno
    opt.textContent = `${af.sno} — ${af.aciklama ? af.aciklama.substring(0, 50) : ''}`
    gSno.appendChild(opt)
  })

  // Ekip üyesi dropdown
  const gEkip = document.getElementById('g-ekip')
  personeller.forEach(p => {
    const opt = document.createElement('option')
    opt.value = p.ad
    opt.textContent = `${p.ad} ${p.soyad}`
    gEkip.appendChild(opt)
  })

  // Yeni görev butonu
  document.getElementById('btn-yeni-gorev').addEventListener('click', () => openNewModal())

  // İptal
  document.getElementById('modal-cancel').addEventListener('click', closeModal)
  overlay.addEventListener('click', (e) => { if (e.target === overlay) closeModal() })

  // Sil
  document.getElementById('btn-sil').addEventListener('click', handleSil)

  // Kaydet
  form.addEventListener('submit', handleSave)
}

function openNewModal() {
  document.getElementById('modal-title').textContent = 'Yeni Görev'
  document.getElementById('gorev-id').value = ''
  document.getElementById('gorev-form').reset()
  document.getElementById('btn-sil').classList.add('hidden')
  document.getElementById('modal-error').classList.add('hidden')

  // Seçili sprinti varsayılan yap
  const sprintVal = document.getElementById('filter-sprint').value
  if (sprintVal) document.getElementById('g-sprint').value = sprintVal

  // Kendi adını varsayılan yap
  if (personel) document.getElementById('g-ekip').value = personel.ad

  document.getElementById('modal-overlay').classList.remove('hidden')
}

function openEditModal(g) {
  document.getElementById('modal-title').textContent = 'Görevi Düzenle'
  document.getElementById('gorev-id').value = g.id
  document.getElementById('g-sprint').value = g.sprint_donem || ''
  document.getElementById('g-faaliyetleri').value = g.sprint_faaliyetleri || ''
  document.getElementById('g-sno').value = g.sno || ''
  document.getElementById('g-plansure').value = g.plan_sure || ''
  document.getElementById('g-ekip').value = g.ekip_uyesi || ''
  document.getElementById('g-durum').value = g.is_durum || ''
  document.getElementById('g-butce').value = g.harcanan_butce || ''
  document.getElementById('modal-error').classList.add('hidden')

  // Sadece Fatih silebilir
  const isFatih = personel && personel.ad === 'Fatih'
  document.getElementById('btn-sil').classList.toggle('hidden', !isFatih)

  document.getElementById('modal-overlay').classList.remove('hidden')
}

function closeModal() {
  document.getElementById('modal-overlay').classList.add('hidden')
}

async function handleSave(e) {
  e.preventDefault()
  const saveBtn = document.getElementById('modal-save')
  saveBtn.disabled = true
  saveBtn.textContent = 'Kaydediliyor...'

  const id = document.getElementById('gorev-id').value
  const payload = {
    sprint_donem: Number(document.getElementById('g-sprint').value),
    sprint_faaliyetleri: document.getElementById('g-faaliyetleri').value.trim(),
    sno: document.getElementById('g-sno').value || null,
    plan_sure: parseFloat(document.getElementById('g-plansure').value) || null,
    ekip_uyesi: document.getElementById('g-ekip').value || null,
    is_durum: document.getElementById('g-durum').value || null,
    harcanan_butce: parseFloat(document.getElementById('g-butce').value) || null
  }

  let error
  if (id) {
    // Güncelle
    ;({ error } = await supabase.from('sprint_is_plani').update(payload).eq('id', id))
  } else {
    // Ekle
    ;({ error } = await supabase.from('sprint_is_plani').insert(payload))
  }

  saveBtn.disabled = false
  saveBtn.textContent = 'Kaydet'

  if (error) {
    const errEl = document.getElementById('modal-error')
    errEl.textContent = error.message.includes('new row') ? 'Yetki hatası: Bu işlem için yetkiniz yok.' : error.message
    errEl.classList.remove('hidden')
    return
  }

  closeModal()
  showToast(id ? 'Görev güncellendi.' : 'Görev eklendi.', 'success')
  await loadBoard()
}

async function handleSil() {
  const id = document.getElementById('gorev-id').value
  if (!id) return
  if (!confirm('Bu görevi silmek istediğinizden emin misiniz?')) return

  const { error } = await supabase.from('sprint_is_plani').delete().eq('id', id)
  if (error) {
    showToast('Silme hatası: ' + error.message, 'error')
    return
  }

  closeModal()
  showToast('Görev silindi.', 'warning')
  await loadBoard()
}
