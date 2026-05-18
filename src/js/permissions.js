// ============================================================
// Frontend Yetki (Permission) Yardımcıları
// Migration 024-026 ile gelen yetki_grubu / personel_yetki_grubu
// /yetki_grubu_tablo_izni tablolarından kullanıcı izinlerini yükler.
// ============================================================

/**
 * Mevcut kullanıcının tüm tablo bazlı izinlerini map olarak döndürür.
 *
 *   { sprint_is_plani: { okuma: true, yazma: true, guncelleme: true, silme: false }, ... }
 *
 * Birden fazla aktif gruba üye olan kullanıcı için izinler OR'lanır
 * (en geniş yetki kazanır).
 *
 * @param {object} supabase
 * @param {number} personelPkod
 * @returns {Promise<Record<string,{okuma:boolean,yazma:boolean,guncelleme:boolean,silme:boolean}>>}
 */
export async function loadCurrentPermissions(supabase, personelPkod) {
  if (!personelPkod) return {}

  // Aktif grup üyelikleri
  const { data: memberships, error: e1 } = await supabase
    .from('personel_yetki_grubu')
    .select('yetki_grubu_id, yetki_grubu!inner(ad, aktif)')
    .eq('personel_pkod', personelPkod)

  if (e1 || !memberships?.length) return {}

  const groupIds = memberships
    .filter(m => m.yetki_grubu?.aktif)
    .map(m => m.yetki_grubu_id)

  if (!groupIds.length) return {}

  // İzin matrisi
  const { data: rows, error: e2 } = await supabase
    .from('yetki_grubu_tablo_izni')
    .select('tablo_adi, okuma, yazma, guncelleme, silme')
    .in('yetki_grubu_id', groupIds)

  if (e2 || !rows) return {}

  const map = {}
  for (const r of rows) {
    const m = map[r.tablo_adi] ||= { okuma: false, yazma: false, guncelleme: false, silme: false }
    m.okuma      = m.okuma      || r.okuma
    m.yazma      = m.yazma      || r.yazma
    m.guncelleme = m.guncelleme || r.guncelleme
    m.silme      = m.silme      || r.silme
  }
  return map
}

/**
 * Bir tablonun belirli bir aksiyonu için yetki kontrolü.
 * @param {object} perms — loadCurrentPermissions çıktısı
 * @param {string} table
 * @param {'okuma'|'yazma'|'guncelleme'|'silme'} action
 * @returns {boolean}
 */
export function can(perms, table, action) {
  return Boolean(perms?.[table]?.[action])
}

/**
 * Mevcut kullanıcının üye olduğu aktif grup adlarını döndürür.
 * @param {object} supabase
 * @param {number} personelPkod
 * @returns {Promise<string[]>}
 */
export async function loadCurrentGroupNames(supabase, personelPkod) {
  if (!personelPkod) return []
  const { data } = await supabase
    .from('personel_yetki_grubu')
    .select('yetki_grubu!inner(ad, aktif)')
    .eq('personel_pkod', personelPkod)
  return (data || [])
    .filter(r => r.yetki_grubu?.aktif)
    .map(r => r.yetki_grubu.ad)
}
