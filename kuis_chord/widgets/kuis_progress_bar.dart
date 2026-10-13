// ============================================================================
// kuis_progress_bar.dart
// Widget bilah progres poin (misalnya 3 / 10) beserta animasi isiannya. Dipakai pada halaman game
// Kuis Chord, Ear Training, Gambar Chord, dan Latihan Final.
// ============================================================================
// Paket Material Flutter.
import 'package:flutter/material.dart';

// Widget stateless karena seluruh datanya diterima lewat konstruktor.
class KuisProgressBar extends StatelessWidget {
  // Poin yang sudah diperoleh.
  final int currentPoints;
  // Target poin yang harus dicapai.
  final int targetPoints;
  // Warna aksen bilah.
  final Color accentColor;

  // Konstruktor const; semua parameter wajib diisi.
  const KuisProgressBar({
    super.key,
    required this.currentPoints,
    required this.targetPoints,
    required this.accentColor,
  });

  // Menimpa build() untuk menyusun tampilan bilah.
  @override
  Widget build(BuildContext context) {
    // Menghitung persentase progres (poin dibagi target) dan membatasinya antara 0 dan 1 dengan
    // clamp.
    final double progress = (currentPoints / targetPoints).clamp(0.0, 1.0);

    // Susunan vertikal: baris label lalu bilah.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Baris label: tulisan Progress di kiri dan angka poin di kanan.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$currentPoints / $targetPoints',
              style: TextStyle(
                color: accentColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Pemotong sudut agar bilah berujung membulat.
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          // Stack menumpuk bilah isian di atas bilah latar.
          child: Stack(
            children: [
              // Bilah latar (kosong) berwarna putih transparan.
              Container(
                height: 6,
                width: double.infinity,
                color: Colors.white.withValues(alpha: 0.06),
              ),
              // LayoutBuilder dipakai untuk mengetahui lebar maksimum yang tersedia.
              LayoutBuilder(
                // AnimatedContainer menganimasikan perubahan lebar isian selama 400 ms.
                builder: (context, constraints) => AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  height: 6,
                  // Lebar isian dihitung dari lebar maksimum dikali progres.
                  width: constraints.maxWidth * progress,
                  // Isian berupa gradien warna aksen dengan bayangan (glow).
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.6),
                        accentColor,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
