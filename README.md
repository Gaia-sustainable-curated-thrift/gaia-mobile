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
| User / Authentication | Akun dan profil | Dalam pengembangan |
| Product / Listing | Katalog dan detail produk | `GET /api/products/`, `GET /api/products/<id>/`; operasi tulis memerlukan autentikasi |
| Chat / Messaging | Inbox dan percakapan | Dalam pengembangan |
| Transaksi | Keranjang dan pesanan | Dalam pengembangan |
| Review & Rating | Review seller | Dalam pengembangan |

Data Product berasal dari endpoint Django REST Framework, bukan katalog statis dalam aplikasi.

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
