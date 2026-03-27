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
let currentPersonel = null
let realtimeChannel = null

// ── Init ─────────────────────────────────────────────────────
try {
  const session = await requireAuth()
  currentUser = session.user

  currentPersonel = await getPersonel(supabase, currentUser.id)
  if (currentPersonel) renderUserInfo(currentPersonel.ad, currentPersonel.soyad)

  document.getElementById('logout-btn').addEventListener('click', () => signOut())

  await loadReferenceData()
  await loadBoard()
  initSortable()
  initRealtime()
  initFilters()
  initModal()
} catch (e) {
  console.error('Başlatma hatası:', e)
  const main = document.querySelector('main')
  if (main) main.innerHTML = `<div style="padding:2rem;color:#dc2626;">Sayfa yüklenemedi: ${e.message}</div>`
}

// ── Veri Yükleme ─────────────────────────────────────────────

async function loadReferenceData() {
  const [sprintRes, personelRes, altFaalRes, perfGosRes] = await Promise.all([
    supabase.from('sprint_veri').select('sprint_donem,sprint_adi,baslangic,bitis').order('sprint_donem', { ascending: false }),
    supabase.from('personel').select('pkod,ad,soyad,rol_kodu').order('ad'),
    supabase.from('alt_faaliyetler')
      .select('sno,fkod,alt_faaliyet,p_sure,faaliyetler(skod,kkod,faaliyet,soplar(kisa),kategori_tipleri(kategori_adi))')
      .order('sno'),
    supabase.from('perf_gostergeler').select('cg_kod,cikti_gostergesi').order('cg_kod')
  ])

  sprints = sprintRes.data || []
  personeller = personelRes.data || []
  altFaaliyetler = altFaalRes.data || []
  window._perfGostergeler = perfGosRes.data || []

  // Sprint filtre dropdown
  const sprintFilter = document.getElementById('filter-sprint')
  sprints.forEach(s => {
    const opt = document.createElement('option')
    opt.value = s.sprint_donem
    opt.textContent = `${s.sprint_donem} — ${s.sprint_adi || ''}`
    sprintFilter.appendChild(opt)
  })

  // Güncel sprinti tarihe göre seç
  if (sprints.length > 0) {
    const today = new Date().toISOString().slice(0, 10)
    const current = sprints.find(s => s.baslangic <= today && s.bitis >= today)
    currentSprint = current ? current.sprint_donem : sprints[0].sprint_donem
    sprintFilter.value = currentSprint
  }

  // Ekip filtresi
  const ekipFilter = document.getElementById('filter-ekip')
  personeller.forEach(p => {
    const opt = document.createElement('option')
    opt.value = p.pkod
    opt.textContent = `${p.ad} ${p.soyad}`
    ekipFilter.appendChild(opt)
  })

  // Kendi pkod'unu varsayılan seç
  if (currentPersonel) {
    ekipFilter.value = currentPersonel.pkod
  }
}

async function loadBoard() {
  let query = supabase.from('sprint_is_plani').select('*').order('id')

  const sprintVal = document.getElementById('filter-sprint').value
  const ekipVal = document.getElementById('filter-ekip').value

  if (sprintVal) query = query.eq('sprint_donem', sprintVal)
  if (ekipVal) query = query.eq('pkod', ekipVal)

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
  const ekipAdi = g.pkod ? (personeller.find(p => p.pkod === g.pkod) ?? null) : null
  const ekipBadge = ekipAdi ? `<span class="badge-ekip">${escHtml(ekipAdi.ad)}</span>` : ''

  card.innerHTML = `
    <div class="card-title">${escHtml(g.sprint_faaliyetleri || '—')}</div>
    <div class="card-meta">
      <span class="badge-sno">S.${g.sno || '?'}</span>
      ${ekipBadge}
      ${g.plan_sure ? `<span class="badge-sure">${g.plan_sure}g</span>` : ''}
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

  // Standart kullanıcı yalnızca kendi görevini taşıyabilir
  const isYonetici = currentPersonel?.rol_kodu === 'yönetici'
  if (!isYonetici && gorev.pkod !== currentPersonel?.pkod) {
    showToast('Sadece yönetici başkasının görevini taşıyabilir.', 'error')
    await loadBoard()
    return
  }

  // Tarih ve audit güncellemeleri
  const updates = {
    is_durum: newDurum || null,
    guncel_tarih: todayISO(),
    guncelleyen: currentPersonel ? `${currentPersonel.ad}.${currentPersonel.soyad}`.toLowerCase() : ''
  }

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

  // Alt faaliyet arama butonu
  document.getElementById('btn-alt-faaliyet-ara').addEventListener('click', () => openAltFaaliyetModal())

  // Ekip üyesi dropdown — standart kullanıcı sadece kendini seçebilir
  const gEkip = document.getElementById('g-ekip')
  const isYonetici = currentPersonel?.rol_kodu === 'yönetici'
  personeller.forEach(p => {
    const opt = document.createElement('option')
    opt.value = p.pkod
    opt.textContent = `${p.ad} ${p.soyad}`
    if (!isYonetici && currentPersonel && p.pkod !== currentPersonel.pkod) {
      opt.disabled = true
    }
    gEkip.appendChild(opt)
  })

  // Performans göstergesi dropdown
  const gPerfGos = document.getElementById('g-perf-gostergeler')
  if (gPerfGos) {
    ;(window._perfGostergeler || []).forEach(pg => {
      const opt = document.createElement('option')
      opt.value = pg.cg_kod
      opt.textContent = `${pg.cg_kod} — ${pg.cikti_gostergesi ? pg.cikti_gostergesi.substring(0, 60) : ''}`
      gPerfGos.appendChild(opt)
    })
  }

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
  document.getElementById('g-sno-hidden').value = ''
  document.getElementById('g-sno-display').value = ''
  document.getElementById('btn-sil').classList.add('hidden')
  document.getElementById('modal-error').classList.add('hidden')

  // Seçili sprinti varsayılan yap (bugünün dönemi)
  const sprintVal = document.getElementById('filter-sprint').value
  if (sprintVal) document.getElementById('g-sprint').value = sprintVal

  // Kendi pkod'unu varsayılan yap
  if (currentPersonel) document.getElementById('g-ekip').value = currentPersonel.pkod

  // Perf göstergeler seçimini temizle
  const gPerfGos = document.getElementById('g-perf-gostergeler')
  if (gPerfGos) Array.from(gPerfGos.options).forEach(o => o.selected = false)

  const perfBtn = document.getElementById('btn-perf-giris')
  if (perfBtn) perfBtn.classList.add('hidden')

  document.getElementById('modal-overlay').classList.remove('hidden')
}

function openEditModal(g) {
  document.getElementById('modal-title').textContent = 'Görevi Düzenle'
  document.getElementById('gorev-id').value = g.id
  document.getElementById('g-sprint').value = g.sprint_donem || ''
  document.getElementById('g-faaliyetleri').value = g.sprint_faaliyetleri || ''
  // Alt faaliyet göster
  const af = altFaaliyetler.find(a => a.sno === g.sno)
  document.getElementById('g-sno-display').value = g.sno ? `S.${g.sno} — ${af?.alt_faaliyet || ''}` : ''
  document.getElementById('g-sno-hidden').value = g.sno || ''
  document.getElementById('g-plansure').value = g.plan_sure || ''
  document.getElementById('g-ekip').value = g.pkod || ''
  document.getElementById('g-durum').value = g.is_durum || ''
  document.getElementById('modal-error').classList.add('hidden')

  // Performans göstergelerini seç
  const gPerfGos = document.getElementById('g-perf-gostergeler')
  if (gPerfGos && g.performans_gostergeler) {
    const secilenler = g.performans_gostergeler.split(',').map(s => s.trim())
    Array.from(gPerfGos.options).forEach(opt => {
      opt.selected = secilenler.includes(opt.value)
    })
  }

  // Sadece yönetici silebilir
  const isFatih = currentPersonel?.rol_kodu === 'yönetici'
  document.getElementById('btn-sil').classList.toggle('hidden', !isFatih)

  // Perf. Giriş butonu — URL'e faaliyet ve sno ekle
  const perfBtn = document.getElementById('btn-perf-giris')
  if (perfBtn) {
    const faaliyet = encodeURIComponent(g.sprint_faaliyetleri || '')
    const sno = g.sno || ''
    perfBtn.href = `pages/sprint-perf-gos.html?faaliyet=${faaliyet}&sno=${sno}`
    perfBtn.classList.remove('hidden')
  }

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
  const gPerfGos = document.getElementById('g-perf-gostergeler')
  const secilenPerfGos = gPerfGos
    ? Array.from(gPerfGos.selectedOptions).map(o => o.value).join(',') || null
    : null
  const payload = {
    sprint_donem: Number(document.getElementById('g-sprint').value),
    sprint_faaliyetleri: document.getElementById('g-faaliyetleri').value.trim(),
    sno: Number(document.getElementById('g-sno-hidden').value) || null,
    plan_sure: parseFloat(document.getElementById('g-plansure').value) || null,
    pkod: Number(document.getElementById('g-ekip').value) || null,
    is_durum: document.getElementById('g-durum').value || null,
    performans_gostergeler: secilenPerfGos
  }

  let error
  if (id) {
    // Güncelle — audit sütunlarını ekle
    const updatePayload = {
      ...payload,
      guncel_tarih: todayISO(),
      guncelleyen: currentPersonel ? `${currentPersonel.ad}.${currentPersonel.soyad}`.toLowerCase() : ''
    }
    ;({ error } = await supabase.from('sprint_is_plani').update(updatePayload).eq('id', id))
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

// ── Alt Faaliyet Arama Modalı ─────────────────────────────────

function openAltFaaliyetModal() {
  const modal = document.getElementById('af-search-modal')
  if (!modal) return

  // Dropdown'ları doldur (nested faaliyetler verisi üzerinden)
  const sopSet = [...new Set(altFaaliyetler.map(a => a.faaliyetler?.soplar?.kisa).filter(Boolean))]
  const katSet = [...new Set(altFaaliyetler.map(a => a.faaliyetler?.kategori_tipleri?.kategori_adi).filter(Boolean))]

  const sopSel = document.getElementById('af-filter-sop')
  sopSel.innerHTML = '<option value="">Tüm SOPlar</option>'
  sopSet.forEach(s => { const o = document.createElement('option'); o.value = s; o.textContent = s; sopSel.appendChild(o) })

  const katSel = document.getElementById('af-filter-kategori')
  katSel.innerHTML = '<option value="">Tüm Kategoriler</option>'
  katSet.forEach(k => { const o = document.createElement('option'); o.value = k; o.textContent = k; katSel.appendChild(o) })

  document.getElementById('af-filter-metin').value = ''
  renderAltFaaliyetList()
  modal.classList.remove('hidden')
}

function renderAltFaaliyetList() {
  const sop = document.getElementById('af-filter-sop').value
  const kat = document.getElementById('af-filter-kategori').value
  const metin = document.getElementById('af-filter-metin').value.toLowerCase()

  const filtered = altFaaliyetler.filter(af => {
    const afSop = af.faaliyetler?.soplar?.kisa
    const afKat = af.faaliyetler?.kategori_tipleri?.kategori_adi
    const afFaaliyet = af.faaliyetler?.faaliyet
    if (sop && afSop !== sop) return false
    if (kat && afKat !== kat) return false
    if (metin && !af.alt_faaliyet?.toLowerCase().includes(metin) && !String(af.sno).includes(metin) && !afFaaliyet?.toLowerCase().includes(metin)) return false
    return true
  })

  const tbody = document.getElementById('af-list-tbody')
  if (filtered.length === 0) {
    tbody.innerHTML = '<tr><td colspan="4" style="text-align:center;color:#94a3b8;padding:16px;">Sonuç bulunamadı.</td></tr>'
    return
  }

  tbody.innerHTML = filtered.slice(0, 100).map(af => `
    <tr style="cursor:pointer;" data-sno="${af.sno}" data-alt="${escHtml(af.alt_faaliyet || '')}">
      <td><span class="badge-sno">${af.sno}</span></td>
      <td style="font-size:0.78rem;color:#64748b;">${escHtml(af.faaliyetler?.soplar?.kisa || '')}</td>
      <td style="font-size:0.78rem;">${escHtml(af.faaliyetler?.faaliyet || '')}</td>
      <td style="font-size:0.78rem;">${escHtml(af.alt_faaliyet || '')}</td>
    </tr>
  `).join('')

  tbody.querySelectorAll('tr[data-sno]').forEach(row => {
    row.addEventListener('click', () => {
      document.getElementById('g-sno-hidden').value = row.dataset.sno
      document.getElementById('g-sno-display').value = `S.${row.dataset.sno} — ${row.dataset.alt}`
      document.getElementById('af-search-modal').classList.add('hidden')
    })
  })
}

document.getElementById('af-filter-sop')?.addEventListener('change', renderAltFaaliyetList)
document.getElementById('af-filter-kategori')?.addEventListener('change', renderAltFaaliyetList)
document.getElementById('af-filter-metin')?.addEventListener('input', renderAltFaaliyetList)
document.getElementById('af-modal-kapat')?.addEventListener('click', () => {
  document.getElementById('af-search-modal').classList.add('hidden')
})
