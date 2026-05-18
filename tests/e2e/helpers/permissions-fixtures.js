// ============================================================
// Permission Fixtures — Yetki E2E testleri için mock veri
// 17 tablo, 6 fixture profili + 1 birleşik profil
// ============================================================

// Sistemdeki 17 tablo
export const ALL_TABLES = [
  'kanban',
  'faaliyet',
  'alt_faaliyet',
  'sop',
  'kategori',
  'harcama',
  'izin',
  'saha_gorevi',
  'personel',
  'birim',
  'sprint_periyod',
  'perf_gostergeler',
  'anahtar_sonuc',
  'sprint_is_plani',
  'audit_log',
  'yetki_grubu',
  'butce',
]

// Sistem grupları — yeniden adlandırma ve silme korumalı
export const SYSTEM_GROUPS = ['admin', 'yönetici', 'başkan', 'standart', 'izleyici']

// Tüm izinleri true olan bir tablo kaydı oluşturur
function allTrue(tableList) {
  const perms = {}
  for (const t of tableList) {
    perms[t] = { okuma: true, yazma: true, guncelleme: true, silme: true }
  }
  return perms
}

// Sadece okuma izni olan bir tablo kaydı oluşturur
function readOnly(tableList) {
  const perms = {}
  for (const t of tableList) {
    perms[t] = { okuma: true, yazma: false, guncelleme: false, silme: false }
  }
  return perms
}

// Seçili tablolarda okuma+yazma, geri kalanında hiç
function readWriteSubset(allowedTables) {
  const perms = {}
  for (const t of ALL_TABLES) {
    if (allowedTables.includes(t)) {
      perms[t] = { okuma: true, yazma: true, guncelleme: true, silme: false }
    }
    // kapsam dışı tablolar için kayıt yok
  }
  return perms
}

// İki iznin OR birleşimi
function mergePerms(a, b) {
  const merged = {}
  const tables = new Set([...Object.keys(a), ...Object.keys(b)])
  for (const t of tables) {
    const pa = a[t] || { okuma: false, yazma: false, guncelleme: false, silme: false }
    const pb = b[t] || { okuma: false, yazma: false, guncelleme: false, silme: false }
    merged[t] = {
      okuma:      pa.okuma      || pb.okuma,
      yazma:      pa.yazma      || pb.yazma,
      guncelleme: pa.guncelleme || pb.guncelleme,
      silme:      pa.silme      || pb.silme,
    }
  }
  return merged
}

// ── Fixture tanımları ─────────────────────────────────────────

const adminPerms = allTrue(ALL_TABLES)
const izleyiciPerms = readOnly(ALL_TABLES)
const standartPerms = readWriteSubset(['kanban', 'faaliyet', 'alt_faaliyet', 'harcama', 'izin', 'saha_gorevi', 'sprint_is_plani'])
const yoneticiPerms = allTrue(ALL_TABLES) // legacy admin — aynı yetkiler
const birimXPerms = readWriteSubset(['kanban', 'sprint_is_plani', 'faaliyet', 'harcama'])

export const FIXTURES = {
  // Tam yetkili sistem admin
  admin: {
    pkod: 1,
    userId: '00000000-0000-0000-0000-000000000001',
    email: 'admin@tr90.gov.tr',
    rolKodu: 'yönetici',
    groups: ['admin'],
    perms: adminPerms,
    groupRows: [
      { id: 1, ad: 'admin', aciklama: 'Sistem yöneticisi', sistem_grubu: true, aktif: true }
    ],
    membershipRows: [
      { personel_pkod: 1, yetki_grubu_id: 1 }
    ],
    permRows: ALL_TABLES.map(t => ({
      yetki_grubu_id: 1,
      tablo_adi: t,
      okuma: true, yazma: true, guncelleme: true, silme: true
    }))
  },

  // Eski yönetici rolü (sistem grubu "yönetici")
  yonetici: {
    pkod: 2,
    userId: '00000000-0000-0000-0000-000000000002',
    email: 'yonetici@tr90.gov.tr',
    rolKodu: 'yönetici',
    groups: ['yönetici'],
    perms: yoneticiPerms,
    groupRows: [
      { id: 2, ad: 'yönetici', aciklama: 'Yönetici', sistem_grubu: true, aktif: true }
    ],
    membershipRows: [
      { personel_pkod: 2, yetki_grubu_id: 2 }
    ],
    permRows: ALL_TABLES.map(t => ({
      yetki_grubu_id: 2,
      tablo_adi: t,
      okuma: true, yazma: true, guncelleme: true, silme: true
    }))
  },

  // Standart kullanıcı — sınırlı yazma
  standart: {
    pkod: 3,
    userId: '00000000-0000-0000-0000-000000000003',
    email: 'standart@tr90.gov.tr',
    rolKodu: 'standart',
    groups: ['standart'],
    perms: standartPerms,
    groupRows: [
      { id: 3, ad: 'standart', aciklama: 'Standart kullanıcı', sistem_grubu: true, aktif: true }
    ],
    membershipRows: [
      { personel_pkod: 3, yetki_grubu_id: 3 }
    ],
    permRows: Object.entries(standartPerms).map(([t, p]) => ({
      yetki_grubu_id: 3,
      tablo_adi: t,
      ...p
    }))
  },

  // Salt okuyucu
  izleyici: {
    pkod: 4,
    userId: '00000000-0000-0000-0000-000000000004',
    email: 'izleyici@tr90.gov.tr',
    rolKodu: 'izleyici',
    groups: ['izleyici'],
    perms: izleyiciPerms,
    groupRows: [
      { id: 4, ad: 'izleyici', aciklama: 'İzleyici', sistem_grubu: true, aktif: true }
    ],
    membershipRows: [
      { personel_pkod: 4, yetki_grubu_id: 4 }
    ],
    permRows: ALL_TABLES.map(t => ({
      yetki_grubu_id: 4,
      tablo_adi: t,
      okuma: true, yazma: false, guncelleme: false, silme: false
    }))
  },

  // Birim-kapsamlı kullanıcı (özel grup, sistem grubu değil)
  birimScoped: {
    pkod: 5,
    userId: '00000000-0000-0000-0000-000000000005',
    email: 'birim@tr90.gov.tr',
    rolKodu: 'standart',
    groups: ['birim-x'],
    perms: birimXPerms,
    groupRows: [
      { id: 10, ad: 'birim-x', aciklama: 'Birim X özel', sistem_grubu: false, aktif: true }
    ],
    membershipRows: [
      { personel_pkod: 5, yetki_grubu_id: 10 }
    ],
    permRows: Object.entries(birimXPerms).map(([t, p]) => ({
      yetki_grubu_id: 10,
      tablo_adi: t,
      ...p
    }))
  },

  // Hiç grubu olmayan kullanıcı
  noAccess: {
    pkod: 6,
    userId: '00000000-0000-0000-0000-000000000006',
    email: 'noaccess@tr90.gov.tr',
    rolKodu: 'standart',
    groups: [],
    perms: {},
    groupRows: [],
    membershipRows: [],
    permRows: []
  },

  // Admin + izleyici birleşimi (OR-aggregation testi)
  adminPlusReadonly: {
    pkod: 7,
    userId: '00000000-0000-0000-0000-000000000007',
    email: 'combined@tr90.gov.tr',
    rolKodu: 'yönetici',
    groups: ['admin', 'izleyici'],
    perms: mergePerms(adminPerms, izleyiciPerms),
    groupRows: [
      { id: 1, ad: 'admin', aciklama: 'Sistem yöneticisi', sistem_grubu: true, aktif: true },
      { id: 4, ad: 'izleyici', aciklama: 'İzleyici', sistem_grubu: true, aktif: true }
    ],
    membershipRows: [
      { personel_pkod: 7, yetki_grubu_id: 1 },
      { personel_pkod: 7, yetki_grubu_id: 4 }
    ],
    permRows: [
      ...ALL_TABLES.map(t => ({
        yetki_grubu_id: 1,
        tablo_adi: t,
        okuma: true, yazma: true, guncelleme: true, silme: true
      })),
      ...ALL_TABLES.map(t => ({
        yetki_grubu_id: 4,
        tablo_adi: t,
        okuma: true, yazma: false, guncelleme: false, silme: false
      }))
    ]
  }
}

// İzin matrisinde beklenen tablo kataloğu (9 tablo — S-003 için)
export const MATRIX_CATALOG_TABLES = [
  'sprint_is_plani',
  'faaliyet',
  'alt_faaliyet',
  'sop',
  'kategori',
  'harcama',
  'izin',
  'personel',
  'birim',
]

// module.exports uyumluluğu — CommonJS require() için
module.exports = { FIXTURES, ALL_TABLES, SYSTEM_GROUPS, MATRIX_CATALOG_TABLES }
