# GAIA Mobile

Aplikasi Flutter untuk marketplace thrifting GAIA. Aplikasi mobile mengambil data dari situs Django GAIA melalui Django REST Framework.

## Anggota dan pembagian modul

| Anggota | NPM | Modul |
| --- | --- | --- |
| Danar Iqbal Abi Zaidan Suharso | 2506534371 | User / Authentication |
| Kayla Kirana Ali Trimardhany | 2506603854 | Product / Listing |
| I Gede Devadatta A.D. | 2506622481 | Chat / Messaging |
| Salma Maharani | 2506586532 | Transaksi |
| Keisha Janice Maulina Napitupulu | 2506551232 | Review & Rating |

## Deskripsi aplikasi dan aktor

GAIA Mobile membantu pengguna menemukan pakaian preloved dan menggunakan marketplace Gaia.

- **Guest:** melihat katalog dan detail produk.
- **Pengguna terdaftar:** mengelola akun/listing, wishlist, chat, transaksi, dan review sesuai hak akses.
- **Admin/staff:** mengelola data dan menangani verifikasi pesanan sesuai izin.

## Modul dan API

| Modul | Cakupan | Endpoint |
| --- | --- | --- |
| User / Authentication | Kerangka masuk, daftar, profil/edit profil, wishlist, dan pengaturan keamanan | Route web sudah ada; endpoint DRF User belum tersedia, lihat [status User](#modul-user--checkpoint-1) |
| Product / Listing | Katalog dan detail produk | `GET /api/products/`, `GET /api/products/<id>/`; operasi tulis memerlukan autentikasi |
| Chat / Messaging | Inbox dan percakapan | Dalam pengembangan |
| Transaksi | Keranjang dan pesanan | Dalam pengembangan |
| Review & Rating | Review seller | Dalam pengembangan |

Data Product berasal dari endpoint Django REST Framework, bukan katalog statis dalam aplikasi.

## Modul User — Checkpoint 1

Penanggung jawab: **Danar Iqbal Abi Zaidan Suharso (2506534371)**.
Kerangka mobile mengikuti cakupan [modul User pada Gaia web](https://github.com/Gaia-sustainable-curated-thrift/Gaia#modul-user--authentication-danar).

- Tab **Akun** pada bottom navigation membuka halaman utama User.
- Akun → Masuk → Reset password / Daftar.
- Akun → Profil saya → Edit profil (nama, username, email read-only, telepon, kota, negara, dan placeholder foto).
- Akun → Wishlist.
- Akun → Pengaturan akun → Ganti password; tersedia placeholder verifikasi email, keluar, dan hapus akun.
- Setiap subhalaman bisa kembali menggunakan tombol Back. Halaman dapat digulir saat layar kecil atau keyboard terbuka.

Ini adalah **kerangka UI**, bukan autentikasi aktif. Menu profil, wishlist, dan pengaturan dapat dibuka sebagai pratinjau tanpa login. Input tidak dikirim atau disimpan, tidak ada akun/sesi palsu, dan tombol aksi backend dinonaktifkan. Google login, upload foto, validasi server, session/token, dan operasi data menjadi pekerjaan integrasi berikutnya. My Products menggunakan modul Product, sedangkan My Orders menggunakan modul Transaksi; keduanya tetap di tab masing-masing pada kerangka ini.

### Status API User

Pemeriksaan kode Gaia web (`accounts/urls.py`, `accounts/forms.py`, dan `gaia/urls.py`) menemukan route berikut. Route ini melayani halaman/form Django dengan session dan CSRF, **bukan endpoint Django REST Framework** dan belum dipanggil dari Flutter.

| Fitur | Route web yang sudah ada | Status mobile |
| --- | --- | --- |
| Masuk / daftar / keluar | `/accounts/login/`, `/accounts/register/`, `/accounts/logout/` | Kerangka; belum terintegrasi |
| Profil / edit profil | `/accounts/profile/`, `/accounts/profile/edit/` | Kerangka; belum terintegrasi |
| Wishlist | `/accounts/wishlist/`, `/accounts/wishlist/<pk>/remove/`, `/accounts/wishlist/undo/` | Kerangka; belum terintegrasi |
| Pengaturan / verifikasi | `/accounts/settings/`, `/accounts/verify/resend/` | Kerangka; belum terintegrasi |
| Ganti / reset password | `/accounts/password/change/`, `/accounts/password/reset/` | Kerangka; belum terintegrasi |
| Hapus akun | `/accounts/delete/` | Placeholder; belum terintegrasi |

Usulan kontrak DRF berikut perlu disepakati dan diimplementasikan di repository backend; **belum tersedia atau terverifikasi berjalan**:

| Metode | Usulan endpoint | Kegunaan |
| --- | --- | --- |
| POST | `/api/accounts/register/` | Registrasi |
| POST | `/api/accounts/login/` | Autentikasi |
| POST | `/api/accounts/logout/` | Mengakhiri sesi |
| GET, PATCH | `/api/accounts/me/` | Membaca/memperbarui profil sendiri |
| GET | `/api/accounts/wishlist/` | Daftar favorit pengguna |
| POST | `/api/accounts/wishlist/<product_id>/` | Menambah favorit |
| DELETE | `/api/accounts/wishlist/<product_id>/` | Menghapus favorit |
| POST | `/api/accounts/wishlist/undo/` | Membatalkan penghapusan terakhir |
| POST | `/api/accounts/verify/resend/` | Mengirim ulang verifikasi |
| POST | `/api/accounts/password/change/` | Mengganti password |
| POST | `/api/accounts/password/reset/` | Meminta tautan pemulihan |
| DELETE | `/api/accounts/me/` | Menghapus akun dengan konfirmasi |

Backend perlu menetapkan kontrak JSON, mekanisme autentikasi, proteksi CSRF bila menggunakan session, error validasi, pagination wishlist, dan konfirmasi operasi sensitif sebelum integrasi. Endpoint verifikasi/reset bertoken juga perlu disepakati untuk alur tautan email.

**Status checkpoint:** halaman dan navigasi modul User sudah tersedia. Syarat checkpoint berupa endpoint DRF yang sudah berjalan **belum terpenuhi untuk User**. Status modul lain mengikuti pekerjaan masing-masing penanggung jawab. Poin Aturan Umum nomor 6 perlu dicocokkan dengan dokumen tugas lengkap karena tangkapan layar hanya memuat instruksi checkpoint.

### Verifikasi kerangka

```bash
flutter analyze
flutter test
```

Pemeriksaan manual: buka tab Akun; kunjungi seluruh menu di atas; uji Back; buka keyboard di form dan gulir sampai bagian bawah. Tombol kirim/simpan harus tetap nonaktif dan tidak mengubah status login.

## Alur integrasi data

Flutter mengirim request HTTP ke endpoint DRF di situs Django Gaia. Viewset mengambil atau mengubah data model, serializer mengirim JSON, lalu Flutter mem-parsing JSON menjadi model `Product` untuk ditampilkan di katalog dan detail. Perubahan listing melalui API dibatasi untuk pengguna terautentikasi dan pemilik listing.

Endpoint bawaan: `https://danar-iqbal-gaia.pws.cs.ui.ac.id/api/products/`. Untuk emulator Android dengan server Django lokal, jalankan:

```bash
flutter run --dart-define=GAIA_API_BASE_URL=http://10.0.2.2:8000/api/products/
```

Pada perangkat fisik, gunakan alamat IP komputer yang menjalankan Django.

## Desain

[Figma GAIA](https://www.figma.com/design/gTTsLkfL1qaaPdEomnRfKf/Gaia?node-id=1-4&t=S3z03qUIKvsz1lNL-1)

## Menjalankan

```bash
flutter pub get
flutter run
```

## APK

Tautan APK akan ditambahkan setelah rilis.

## AI Disclosure

OpenAI ChatGPT digunakan untuk membantu implementasi awal dan dokumentasi. Kode ditinjau serta diuji oleh pengembang; keputusan desain dan integrasi menjadi tanggung jawab tim.
