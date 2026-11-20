# GAIA Mobile

GAIA Mobile merupakan aplikasi marketplace thrift untuk membeli dan menjual pakaian bekas layak pakai. Aplikasi ini melanjutkan website Django GAIA dari Proyek Tengah Semester PBP Fasilkom UI ke aplikasi Flutter dengan lima modul: Akun, Produk, Transaksi, Chat, serta Review dan Rating.

GAIA mendukung circular fashion dengan membantu pengguna menemukan barang thrift, berkomunikasi dengan penjual, melakukan transaksi, dan memberikan penilaian setelah pembelian.

| Informasi | Tautan |
| --- | --- |
| Repository Flutter | [gaia-mobile](https://github.com/Gaia-sustainable-curated-thrift/gaia-mobile) |
| Repository Django | [Gaia](https://github.com/Gaia-sustainable-curated-thrift/Gaia) |
| Website Django di PWS | [Website GAIA](https://danar-iqbal-gaia.pws.cs.ui.ac.id) |
| Desain Figma | [Desain GAIA](https://www.figma.com/design/gTTsLkfL1qaaPdEomnRfKf/Gaia?node-id=1-4) |
| APK | Belum tersedia; tautan unduhan akan ditambahkan setelah Checkpoint 1. |

## Anggota kelompok

| Nama | NPM |
| --- | --- |
| Danar Iqbal Abi Zaidan Suharso | 2506534371 |
| I Gede Devadatta A.D | 2506622481 |
| Keisha Janice Maulina Napitupulu | 2506551232 |
| Kayla Kirana Ali Trimardhany | 2506603854 |
| Salma Maharani | 2506586532 |

## Modul dan pembagian kerja

| Modul | Penanggung jawab | Cakupan pengembangan | Halaman Flutter |
| --- | --- | --- | --- |
| Akun dan Autentikasi | Danar | Registrasi, login/logout, profil, keamanan akun, dan wishlist. | `lib/pages/account_page.dart` |
| Produk | Kayla | Katalog, detail produk, pengelolaan listing, foto, kategori, harga, kondisi, serta pencarian/filter produk. | `lib/pages/product_page.dart` |
| Chat | Deva | Percakapan dan pesan antara pembeli dan penjual. | `lib/pages/chat_page.dart` |
| Transaksi | Salma | Keranjang, checkout, pesanan, pembayaran, dan status transaksi. | `lib/pages/transaction_page.dart` |
| Review dan Rating | Keisha | Ulasan dan rating penjual berdasarkan pesanan, helpful vote, balasan penjual, dan pelaporan ulasan. | `lib/pages/review_page.dart` |

Pada versi Flutter saat ini, kelima modul telah memiliki halaman kerangka yang terhubung melalui navigasi bawah di `lib/main.dart`. Kolom cakupan menjelaskan tanggung jawab pengembangan masing-masing anggota; fitur lengkap setiap modul belum seluruhnya diimplementasikan pada antarmuka Flutter. Halaman Review dan Rating masih berupa kerangka dan belum mengambil data dari API.

## Peran pengguna

| Aktor | Peran dan akses |
| --- | --- |
| Pengunjung atau guest | Melihat data publik, seperti katalog dan review, serta mendaftar atau login untuk menggunakan fitur pribadi. |
| Pembeli atau buyer | Pengguna terautentikasi yang menyimpan wishlist, menghubungi penjual, melakukan transaksi, dan menulis review untuk pesanan yang memenuhi syarat. |
| Penjual atau seller | Pengguna terautentikasi yang mengelola listing, berkomunikasi dengan pembeli, menerima pesanan, dan membalas review untuk tokonya. |
| Admin | Mengelola data dan proses administrasi melalui backend Django, termasuk pemeriksaan pesanan dan laporan ulasan sesuai kewenangan. Antarmuka admin khusus di Flutter belum dibuat. |

Pembeli dan penjual bukan jenis akun terpisah. Pengguna terdaftar dapat menjalankan kedua peran tersebut. Backend memeriksa autentikasi dan kepemilikan data pada setiap operasi yang memerlukannya.

## Integrasi data mobile dan website melalui DRF

Flutter akan menggunakan web service Django REST Framework pada backend GAIA yang sama dengan website PWS. Data produk, akun, pesanan, dan review tetap dikelola oleh model serta database Django yang sudah ada. Flutter berkomunikasi melalui HTTP dengan request dan respons JSON, tanpa mengakses database secara langsung.

Alur berikut menjadi kontrak integrasi yang akan dihubungkan ke halaman Flutter. Endpoint Review dan Rating sudah diimplementasikan pada backend; pemanggilan endpoint dari halaman Flutter masih merupakan pekerjaan integrasi berikutnya.

1. Pengguna melakukan login melalui aplikasi mobile. Klien mengirim `username` dan `password` sebagai JSON ke `POST /api/accounts/login/`. Backend memvalidasi akun dan mengembalikan token autentikasi beserta data pengguna.
2. Klien menggunakan token pada request pribadi melalui header `Authorization: Token <token>`. Endpoint publik, seperti daftar review, dapat dibaca tanpa login.
3. Klien meminta data melalui endpoint DRF, misalnya `GET /api/reviews/seller/<seller_id>/`. Backend membaca database yang sama dengan website dan mengembalikan JSON.
4. Flutter mengubah JSON menjadi model Dart dan menampilkannya pada widget. Daftar review membaca isi `results` serta mengikuti `next` dan `previous` untuk pagination. Antarmuka perlu menangani kondisi memuat, data kosong, dan request gagal.
5. Untuk menulis review, klien mengambil pesanan yang eligible, lalu mengirim ID pesanan, rating, judul, dan komentar ke `POST /api/reviews/` dengan token pengguna.
6. Backend memeriksa status serta kepemilikan pesanan, memvalidasi input, dan menyimpan review. Identitas reviewer berasal dari pengguna yang terautentikasi, sedangkan seller berasal dari pesanan; keduanya tidak ditentukan oleh input klien.
7. Setelah berhasil, backend mengembalikan JSON review yang tersimpan. Klien memperbarui tampilan atau mengambil ulang data. Perubahan yang sama tersedia pada website setelah data dimuat ulang karena kedua aplikasi menggunakan backend yang sama.

Pada kode backend lokal, API review mendukung `SessionAuthentication` dan `TokenAuthentication`. Dukungan token telah diperiksa menggunakan akun dan database pengujian terpisah. Perubahan dukungan token masih perlu disimpan ke repository backend dan dideploy sebelum dipakai pada PWS.

Request mobile yang hanya menggunakan token tidak memerlukan cookie session atau token CSRF. Alur website yang memakai session tetap memerlukan perlindungan CSRF untuk operasi tulis. Penjelasan skema autentikasi tersedia pada [dokumentasi DRF](https://www.django-rest-framework.org/api-guide/authentication/).

### Alamat backend

| Lingkungan | Base URL |
| --- | --- |
| PWS | `https://danar-iqbal-gaia.pws.cs.ui.ac.id` |
| Django lokal pada komputer pengembang | `http://127.0.0.1:8000` |

Ketersediaan endpoint PWS perlu diperiksa setelah deployment berhasil. Respons JSON dari localhost tidak menjadi bukti bahwa versi yang sama sudah tersedia di server PWS.

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

## Menjalankan proyek

Gunakan Flutter SDK yang menyediakan Dart sesuai constraint `sdk: ^3.13.7` pada `pubspec.yaml`. Dari root repository Flutter, jalankan:

```sh
flutter pub get
flutter devices
flutter run
```

Pilih perangkat yang tersedia. Untuk memeriksa kode Dart, gunakan `flutter analyze`. Referensi perintah tersedia pada [dokumentasi Flutter CLI](https://docs.flutter.dev/reference/flutter-cli).

Pada root repository Django dengan virtual environment dan konfigurasi lokal yang sudah disiapkan:

```powershell
.\env\Scripts\python.exe -m pip install -r requirements.txt
.\env\Scripts\python.exe manage.py migrate
.\env\Scripts\python.exe manage.py check
.\env\Scripts\python.exe manage.py runserver
```

Endpoint lokal dapat diperiksa melalui [daftar review lokal](http://127.0.0.1:8000/api/reviews/). Endpoint baca publik tidak memerlukan username atau password.

## Status Checkpoint 1

| Bagian | Status pada versi ini |
| --- | --- |
| Kerangka lima halaman Flutter | Tersedia. |
| Navigasi bawah antarmodul | Tersedia. |
| API DRF Review dan Rating | Tersedia pada backend Django. |
| Pengujian modul reviews | 102 pengujian lolos, termasuk 28 pengujian API, pada pemeriksaan lokal. |
| Dukungan token API review | Tersedia dan terverifikasi pada kode lokal; perubahan masih perlu dipublikasikan ke backend. |
| Integrasi data pada halaman Review Flutter | Belum diimplementasikan. |
| Endpoint review pada PWS | Perlu dikonfirmasi setelah deployment versi yang sesuai. |
| APK | Tautan dapat ditambahkan setelah Checkpoint 1. |

Pengujian backend modul reviews dapat diulang dari root Django:

```powershell
.\env\Scripts\python.exe manage.py test reviews --noinput
```

Endpoint dan hasil pengujian API modul anggota lain didokumentasikan oleh penanggung jawab masing-masing.

## Desain Figma dan APK

Desain aplikasi tersedia pada [Figma GAIA](https://www.figma.com/design/gTTsLkfL1qaaPdEomnRfKf/Gaia?node-id=1-4). Tautan ini menjadi referensi desain bersama untuk pengembangan antarmuka.

APK belum dipublikasikan. Tautan unduhan APK akan ditambahkan di bagian ini setelah tersedia; sesuai ketentuan Checkpoint 1, tautan tersebut boleh ditambahkan setelah checkpoint ini.
