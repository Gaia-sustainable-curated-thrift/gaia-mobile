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
| User / Authentication | Autentikasi, profil, wishlist, dan keamanan akun | `/api/accounts/`; lihat [integrasi User](#modul-user-integrasi-mobile-dan-web) |
| Product / Listing | Katalog dan detail produk | `GET /api/products/`, `GET /api/products/<id>/`; operasi tulis memerlukan autentikasi |
| Chat / Messaging | Inbox dan percakapan | Dalam pengembangan |
| Transaksi | Keranjang dan pesanan | Dalam pengembangan |
| Review & Rating | Review seller | Dalam pengembangan |

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
