// ============================================================================
// main.dart
// Titik masuk (entry point) aplikasi Clean Chord. File ini bertugas menyiapkan seluruh layanan
// (service) inti, mengunci orientasi layar, kemudian menjalankan widget akar aplikasi (MyApp) yang
// menampilkan SplashPage sebagai halaman pertama.
// ============================================================================
// Paket Material Flutter: menyediakan widget dasar seperti MaterialApp, StatelessWidget, dan
// AssetImage.
import 'package:flutter/material.dart';
// Paket services: dibutuhkan untuk SystemChrome (pengaturan orientasi layar).
import 'package:flutter/services.dart';
// Tema global aplikasi (AppTheme.darkTheme) yang dipasang pada MaterialApp.
import 'core/theme/app_theme.dart';
// Barrel file modul progression; mengekspor ProgressionService (pengelola XP, level, dan progres
// belajar).
import 'core/progression/progression.dart';
// Barrel file modul profile; mengekspor ProfileService (pengelola nama, avatar, dan data profil
// pengguna).
import 'core/profile/profile.dart';
// Barrel file modul reward3d; mengekspor Reward3DService (pengelola hadiah model chord 3D).
import 'core/reward3d/reward3d.dart';
// Barrel file modul leaderboard; mengekspor LeaderboardService (pengelola papan peringkat XP).
import 'core/leaderboard/leaderboard.dart';
// Halaman pembuka (splash) yang pertama kali ditampilkan saat aplikasi dijalankan.
import 'features/home/pages/splash_page.dart';

// Fungsi utama yang pertama kali dieksekusi. Bertipe async karena beberapa service perlu menunggu
// proses pembacaan penyimpanan lokal (dan Firebase) selesai sebelum aplikasi dijalankan.
void main() async {
  // Wajib dipanggil terlebih dahulu apabila ada operasi asynchronous sebelum runApp(), agar binding
  // Flutter sudah siap digunakan.
  WidgetsFlutterBinding.ensureInitialized();

  // Init progression engine (tidak berubah)
  // Menginisialisasi ProgressionService terlebih dahulu karena service lain (Reward3D dan
  // Leaderboard) bergantung pada data total XP miliknya.
  await ProgressionService.instance.init();

  // Init profile engine (baru, terpisah)
  // Menginisialisasi ProfileService; Leaderboard membutuhkan nama profil, sehingga service ini
  // harus siap sebelum LeaderboardService.
  await ProfileService.instance.init();

  // Init reward 3D engine (baru, terpisah — baca totalXp dari
  // ProgressionService, jadi WAJIB di-init setelah baris di atas)
  // Menginisialisasi Reward3DService. Urutannya harus setelah ProgressionService karena hadiah 3D
  // dibuka berdasarkan total XP.
  await Reward3DService.instance.init();

  // Init leaderboard engine — WAJIB di-init setelah ProgressionService &
  // ProfileService (dia baca totalXp + nama profil buat sync ke cloud).
  // Aman dipanggil meskipun AppConfig.firebaseEnabled masih false — bakal
  // langsung no-op, nggak nyentuh Firebase SDK sama sekali.
  // Menginisialisasi LeaderboardService. Urutannya harus setelah ProgressionService dan
  // ProfileService. Apabila AppConfig.firebaseEnabled bernilai false, proses ini tidak melakukan
  // apa pun.
  await LeaderboardService.instance.init();

  // Mengunci orientasi aplikasi hanya pada mode potret (portrait), yaitu potret normal dan potret
  // terbalik.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Menjalankan aplikasi dengan MyApp sebagai widget akar (root widget).
  runApp(const MyApp());
}

// Widget akar aplikasi. Bersifat stateless karena tidak menyimpan state yang berubah; hanya
// mengatur konfigurasi MaterialApp.
class MyApp extends StatelessWidget {
  // Konstruktor const dengan parameter key untuk identitas widget di pohon widget Flutter.
  const MyApp({super.key});

  // Menandakan bahwa method build() menimpa (override) method milik kelas induk StatelessWidget.
  @override
  // Method build() membangun tampilan widget ini, yaitu MaterialApp sebagai kerangka utama
  // aplikasi.
  Widget build(BuildContext context) {
    return MaterialApp(
      // Menyembunyikan banner "DEBUG" di pojok kanan atas layar.
      debugShowCheckedModeBanner: false,
      // Judul aplikasi yang dipakai sistem (misalnya pada daftar aplikasi terbaru).
      title: 'Clean Chord',
      // Memasang tema gelap yang didefinisikan pada core/theme/app_theme.dart.
      theme: AppTheme.darkTheme,
      // Halaman awal aplikasi: SplashPage (features/home/pages/splash_page.dart).
      home: const SplashPage(),
      // builder dijalankan di atas seluruh halaman, sehingga cocok dipakai untuk melakukan precache
      // (pemuatan awal) gambar.
      builder: (context, child) {
        // Memuat gambar ikon aplikasi ke cache lebih awal agar tampil tanpa jeda saat dibutuhkan.
        precacheImage(const AssetImage('assets/images/iconapp.png'), context);
        // Memuat gambar avatar laki-laki (dipakai pada pemilihan avatar di halaman profil).
        precacheImage(const AssetImage('assets/images/man.jpg'), context);
        // Memuat gambar avatar perempuan (dipakai pada pemilihan avatar di halaman profil).
        precacheImage(const AssetImage('assets/images/woman.jpg'), context);
        // Mengembalikan halaman aktif (child) apa adanya; tanda ! menegaskan bahwa child tidak
        // bernilai null.
        return child!;
      },
    );
  }
}
