GAIA Mobile

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
| User / Authentication | Autentikasi, profil, wishlist, dan keamanan akun | `/api/accounts/`; lihat [integrasi User](#modul-user-integrasi-mobile-dan-web) |
| Product / Listing | Katalog dan detail produk | `GET /api/products/`, `GET /api/products/<id>/`; operasi tulis memerlukan autentikasi |
| Chat / Messaging | Inbox dan percakapan | Dalam pengembangan |
| Transaksi | Keranjang dan pesanan | Dalam pengembangan |
| Review & Rating | Review dan rating seller berdasarkan pesanan | `/api/reviews/`; API DRF tersedia, integrasi halaman Flutter belum selesai. Lihat [integrasi Review](#modul-review-dan-rating). |

Data Product berasal dari endpoint Django REST Framework, bukan katalog statis dalam aplikasi.

## Modul User: integrasi mobile dan web

Penanggung jawab: **Danar Iqbal Abi Zaidan Suharso (2506534371)**.
Flutter memakai endpoint DRF `/api/accounts/` pada backend Django Gaia. Akun, profil, dan wishlist menggunakan tabel yang sama dengan web: perubahan profil/favorit dari salah satu aplikasi terlihat di aplikasi lain setelah dimuat ulang.

Fitur terhubung:

- Registrasi dan login menggunakan email atau username; validasi mengikuti form Django web.
- Membaca/mengedit profil; email tetap read-only.
- Menyimpan produk dari ikon hati di detail produk; melihat wishlist dengan pagination 12 item, menghapus, dan undo.
- Mengirim ulang verifikasi email dan memperbarui status verifikasi.
- Ganti password, meminta reset melalui email, logout dengan konfirmasi, serta hapus akun lokal dengan password, frasa `DELETE`, dan persetujuan. Backend menolak penghapusan saat ada pesanan aktif.
- Error jaringan, validasi backend, loading, dan sesi dicabut ditampilkan pada UI. Halaman privat memerlukan login.

Login Google dan penggantian foto masih melalui web. Penghapusan akun tanpa password lokal memakai alur konfirmasi email di web; aplikasi menonaktifkan penghapusan untuk akun tersebut.

### Kontrak API User

Semua respons berupa JSON; operasi 204 tidak mempunyai body. Endpoint privat memakai header `Authorization: Token <token>`. Login/register mengembalikan `{token, user}`; `user` memuat `id`, `full_name`, `username`, `email`, `phone`, `city`, `country`, `avatar_url`, `email_verified`, dan `has_password`. Error validasi berbentuk `{field: [pesan]}` atau `{detail: pesan}`.

| Metode | Endpoint | Data / fungsi |
| --- | --- | --- |
| POST | `/api/accounts/register/` | `full_name`, `email`, `password1`, `password2` |
| POST | `/api/accounts/login/` | `username` (email atau username), `password` |
| POST | `/api/accounts/logout/` | Mencabut token; 204 |
| GET, PATCH | `/api/accounts/me/` | Profil sendiri; PATCH nama, username, phone, city, country |
| DELETE | `/api/accounts/me/` | `password`, `confirmation: DELETE`, `acknowledge: true`; 204 |
| GET | `/api/accounts/wishlist/?page=1` | `{count, next, previous, results}`; 12 item per halaman |
| POST | `/api/accounts/wishlist/products/<product_id>/` | Menyimpan produk tersedia milik pengguna lain |
| DELETE | `/api/accounts/wishlist/<item_id>/` | Soft delete item sendiri; 204 |
| POST | `/api/accounts/wishlist/<item_id>/restore/` | Memulihkan item sendiri untuk undo |
| POST | `/api/accounts/verify/resend/` | Mengirim email; cooldown 60 detik |
| POST | `/api/accounts/password/change/` | `old_password`, `new_password1`, `new_password2`; masuk ulang setelah berhasil |
| POST | `/api/accounts/password/reset/` | `email`; tautan email membuka form reset web |

Token disimpan di memori selama aplikasi berjalan; menutup aplikasi memerlukan login ulang. Password tidak disimpan. DRF menggunakan satu token per akun: logout mencabut token mobile akun tersebut pada seluruh perangkat, sedangkan sesi browser web tetap terpisah. Perubahan password dari mobile maupun web mencabut token mobile lama. Halaman web tetap menggunakan session dan proteksi CSRF.

### Backend dan konfigurasi

Backend pendamping sudah digabung melalui [Gaia PR #36](https://github.com/Gaia-sustainable-curated-thrift/Gaia/pull/36) dan [deploy PWS berhasil](https://github.com/Gaia-sustainable-curated-thrift/Gaia/actions/runs/44764616682) pada 20 November 2026. Endpoint User publik sudah merespons JSON; `/me/` dan `/wishlist/` menolak guest dengan 401, pemeriksaan token dummy mengembalikan 401 Invalid token (tabel token tersedia), dan katalog Product tetap merespons 200.

Untuk deployment baru, jalankan `python manage.py migrate` agar tabel `authtoken` bawaan DRF tersedia. Push branch fitur tidak otomatis deploy; workflow web melakukan deploy PWS dari `main`.

Default User: `https://danar-iqbal-gaia.pws.cs.ui.ac.id/api/accounts/`.
Default Product tetap `https://danar-iqbal-gaia.pws.cs.ui.ac.id/api/products/`.
Kedua konfigurasi menggunakan URL lengkap dengan trailing slash:

```bash
flutter run --dart-define=GAIA_USER_API_BASE_URL=http://10.0.2.2:8000/api/accounts/ --dart-define=GAIA_API_BASE_URL=http://10.0.2.2:8000/api/products/
```

Untuk perangkat fisik gunakan alamat server yang dapat dijangkau perangkat. Android release memiliki permission INTERNET; URL HTTPS publik adalah default. HTTP lokal hanya untuk pengembangan, dan dapat memerlukan konfigurasi cleartext khusus debug di perangkat.

### Verifikasi

```bash
flutter analyze
flutter test --concurrency=1
# Backend lokal terisolasi harus sudah berjalan dan sudah migrate.
# Gunakan EMAIL_BACKEND=django.core.mail.backends.locmem.EmailBackend untuk smoke test.
dart run tool/user_api_smoke.dart http://127.0.0.1:8897/api/accounts/
```

Smoke test membuat akun sementara, menjalankan HTTP nyata dari Dart ke Django, memeriksa profil/wishlist serta pencabutan token setelah logout, lalu menghapus akun sementara. Hanya host localhost/127.0.0.1 diizinkan oleh script.

Halaman/navigasi dan API User sudah terhubung; backend produksi sudah dideploy. Verifikasi registrasi/login/profil dilakukan menggunakan HTTP nyata terhadap database lokal terisolasi; pemeriksaan produksi dilakukan secara read-only tanpa mengubah akun pengguna. Pengiriman email ke inbox produksi belum diuji dan bergantung pada konfigurasi SMTP. Poin Aturan Umum nomor 6 tetap perlu dicocokkan dengan dokumen tugas lengkap.

## Modul Review dan Rating

Penanggung jawab: **Keisha Janice Maulina Napitupulu (2506551232)**.

Backend Django sudah menyediakan API DRF Review dan Rating, yang digabung melalui [Gaia PR #37](https://github.com/Gaia-sustainable-curated-thrift/Gaia/pull/37). API menggunakan model `Review`, `ReviewReport`, dan `AccountOrder` yang juga dipakai website, sehingga data review tersimpan pada backend yang sama.

**Status backend:** API telah diimplementasikan. Sebanyak 102 pengujian modul reviews lolos, termasuk 28 pengujian API, pada pemeriksaan lokal.

**Status Flutter:** halaman Review masih berupa kerangka dan belum memanggil API. Keterangan ini berlaku untuk integrasi antarmuka Review; endpoint backend sudah tersedia.

### Alur integrasi Review

1. Halaman Review mengambil data publik melalui `GET /api/reviews/` atau daftar review per seller, kemudian mem-parsing `results` menjadi model Dart untuk ditampilkan. `next` dan `previous` digunakan untuk pagination.
2. Untuk fitur pribadi, aplikasi menggunakan identitas hasil login modul User. Pada kode lokal, API Review menerima header `Authorization: Token <token>` selain autentikasi session.
3. Sebelum menulis review, klien mengambil pesanan eligible untuk seller terkait. Klien mengirim `order`, `rating`, `title`, `comment`, dan flag opsional melalui POST JSON. Reviewer berasal dari pengguna yang terautentikasi dan seller diturunkan dari pesanan.
4. Backend memvalidasi kepemilikan dan status pesanan serta rating, menyimpan data, lalu mengembalikan JSON. Setelah berhasil, halaman mengambil ulang daftar dan summary agar perubahan tampil. Website membaca data yang sama setelah dimuat ulang.

Tambahan dukungan token Review telah diverifikasi pada kode lokal menggunakan akun dan database pengujian terpisah. Perubahan token tersebut masih perlu dipublikasikan melalui repository backend dan deployment sebelum diandalkan pada PWS. Autentikasi session website tetap memerlukan cookie session dan CSRF untuk operasi tulis.

### Endpoint Review dan Rating

Seluruh path berikut relatif terhadap base URL backend dan menggunakan trailing slash.

| Metode | Endpoint | Fungsi dan akses |
| --- | --- | --- |
| GET | `/api/reviews/` | Daftar review publik dengan pagination. |
| POST | `/api/reviews/` | Membuat review; memerlukan login dan pesanan eligible. |
| GET | `/api/reviews/<id>/` | Detail review publik. |
| PUT, PATCH | `/api/reviews/<id>/` | Mengedit review; hanya penulisnya. |
| DELETE | `/api/reviews/<id>/` | Menghapus review; hanya penulisnya. |
| GET | `/api/reviews/mine/` | Daftar review yang ditulis pengguna login. |
| GET | `/api/reviews/seller/<seller_id>/` | Daftar review untuk penjual tertentu. |
| GET | `/api/reviews/seller/<seller_id>/summary/` | Rata-rata, jumlah review, dan distribusi rating penjual. |
| GET | `/api/reviews/seller/<seller_id>/eligible-orders/` | Pesanan pengguna yang memenuhi syarat untuk direview. |
| POST | `/api/reviews/<id>/helpful/` | Toggle helpful; penulis dan penjual terkait tidak boleh memilih. |
| POST, DELETE | `/api/reviews/<id>/reply/` | Menyimpan atau menghapus balasan; hanya penjual terkait. |
| POST | `/api/reviews/<id>/report/` | Melaporkan review; penulis tidak boleh melaporkan review sendiri. |
| GET | `/api/reviews/csrf/` | Mengambil token CSRF untuk klien yang memakai session. |

Daftar review mendukung filter `seller` dan `rating`, pengurutan `sort=newest|helpful|rating`, serta pagination `page` dan `page_size`.

### Aturan review

- Rating harus berupa integer 1 sampai 5.
- Pesanan harus berstatus `completed`, dimiliki pengguna yang login, memiliki penjual aktif, dan belum memiliki review.
- Pengguna tidak dapat mereview dirinya sendiri. Satu pesanan hanya memiliki satu review pada satu waktu.
- Input `reviewer` dan `seller` dari klien ditolak. Penulis, penjual, dan pesanan tidak dapat diganti melalui endpoint edit review.
- Review anonim menyembunyikan identitas penulis. Identitas reviewer juga disembunyikan dari pengunjung yang belum login. Nomor ID pesanan hanya terlihat oleh penulis review.

Contoh body `POST /api/reviews/` menggunakan ID pesanan ilustratif:

```json
{
  "order": 42,
  "rating": 5,
  "title": "Penjual ramah",
  "comment": "Komunikasi cepat dan barang sesuai deskripsi.",
  "is_anonymous": false,
  "is_friendly": true,
  "is_responsive": true,
  "is_trustworthy": true
}
```

Respons berhasil pembuatan review berstatus `201` dan berisi objek review. Penghapusan review menghasilkan `204` tanpa body. Error validasi menghasilkan `400`; akses tanpa izin pada API review menghasilkan `403`; objek tidak ditemukan menghasilkan `404`.

Contoh respons daftar kosong berstatus `200`:

```json
{
  "count": 0,
  "next": null,
  "previous": null,
  "results": []
}
```

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
