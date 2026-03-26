# Gereksinimler ve Düzeltmeler

## Genel

- G

---

## Kanban Board Sayfası

Yeni görev tuşu tıklandı ve form açıldı. Açılan formda:

- **Sprint Dönemi:** Açılışta içinde bulunduğumuz dönem gelsin (tarihe bakarak).
- **S.No kutusu:** Boş geliyor — doldurulmalı.
- **Performans göstergesi katkısı:** İlgili faaliyet herhangi bir performans göstergesine katkı sağladıysa kayıt edilmesi için bir seçim alanı olmalı.
- **Alt Faaliyet Tanımı:** `alt_faaliyet` alanı bilgisi gelsin.
- **Alt faaliyet arama özelliği:** Alt faaliyet seçimi yapabilmek için arama özelliği eklenmeli. SOP, Kategori, Faaliyet filtreleri ve `alt_faaliyet` alanı bilgisine göre metin arama yapılabilsin.

---

## Sprint Özeti

- Sayfa açılışında mevcut sprint dönemi verileri gelsin; sağ üstteki kutuda mevcut sprint seçilmiş olsun.
- Alttaki kutular boş görünüyor ("Veri yükleniyor" mesajı çıkıyor ama veri gelmiyor) — düzeltilmeli.

---

## Faaliyetler

- Sol üstte **"Doğu Karadeniz Kalkınma Ajansı"** yerine **"DOKA"** yazsın.
- **Yeni faaliyet tuşu** çalışmıyor — aktif hale getirilmeli.
- **Alt faaliyetler** de bu sayfada ilgili faaliyet altında bir tuşla eklenebilmeli.
- Faaliyetler altındaki tablolarda **alt faaliyet gerçekleşme oranları** ve **harcanan bütçe**, sprint iş planında tamamlanan faaliyetlerden ve harcama girişlerinden gelmeli — doğrulanmalı.
- Verilerde üstte **yıl bazında filtreleme** yapılmalı (SOPlar genelde 3 yıllık plan içerir).
- SOP bazında yapılan toplam, **ilgili üst başlık satırında** görünmeli.

---

## Retrospektif

- **Sprint Dönemi combobox:** Sayfa açılışında güncel dönem seçili olarak gelmeli.
- **Kayıt hatası:** `"Could not find the 'gort' column of 'sprint_retro' in the schema cache"` — düzeltilmeli.
- **Geçmiş retro kayıtları tablosu** boş geliyor — düzeltilmeli.

---

## Performans

### Performans Gerçekleşmeleri (SprintPerfGösterge)

Ayrı bir sayfada gösterilmeli. Girilen gerçekleşmelerin hepsi liste olarak görünecek.

**Tablo başlıkları:**
- Sprint Faaliyet
- ÇGKod
- Açıklama
- Gerçekleşme
- Tamamlanma Dönemi
- Tarih
- Yıl (tercihen)

**Erişim:**
- Kanban Board sayfasında sprint faaliyetine tıklandığında açılan formdan bir tuşla form girişi yapılabilmeli.
- Alternatif olarak bu sayfa üstünde bir tuşla da forma erişilebilmeli.

### Performans Göstergeleri Özeti

Ayrı bir sayfa olmalı. Girilen performans gerçekleşmeleri gösterge bazında özet sunulacak.
Bu tablo SOP planlama döneminde 3 yıllık olarak hazırlanır; ilgili SOP'un yürürlük yıllarına göre 1. Yıl, 2. Yıl ve 3. Yıl belirlenir.

**Tablo başlıkları:**
- ÇGKod
- SOP
- Bileşen Kodu
- Bileşen Adı
- Çıktı Göstergesi
- Birim
- Hedef
- Tamamlanma Dönemi
- Katkı Sağlanacak Sonuç Göstergesi
- Hedef 1. Yıl
- Hedef 2. Yıl
- Hedef 3. Yıl
- Kümülatif Gerç.
- 1. Yıl
- 2. Yıl
- 3. Yıl

---

## Harcamalar

- Harcama girişleri Kanban Board'dan yapılabiliyor ancak sprint faaliyeti üzerinde bir **tuş** ile formun çağrılması mevcut textbox'tan daha iyi olacak.
- **Yeni Harcama formu** — eklenmesi gerekenler:
  - Harcama onay kodu
  - Harcama onay tarihi
- Yeni harcama formunda **ödeme için birden fazla dönem eklenebilmeli**; her dönem için tutarlar ayrı girilebilmeli.
- Harcama girildikten sonra **durum takibi yapılmayacak** — ilgili alan kaldırılabilir.

---

## İzinler & Saha

- **Yeni izin ekle formu:** Kayıt yapılamıyor. Hata: `"Could not find the baslangic_tarih column of izinler in the schema cache"` — düzeltilmeli.
- **Yeni Saha görevi — iller listesi:** Sadece şu iller listelensin: Artvin, Giresun, Gümüşhane, Ordu, Rize, Trabzon.
- **Yeni saha görevi ekleme hatası:** `"Could not find the il column of saha_gorevleri in the schema cache"` — düzeltilmeli.

---

## RLS Kontrol

- Standart kullanıcı hesabıyla girildiğinde, başka kullanıcılar için Kanban Board'da görev girilebiliyor veya görevler taşınabiliyor.
- **Bu tür değişiklikler yalnızca yönetici tarafından yapılabilmeli** — RLS politikaları güncellenmeli.
