// ============================================================================
// kuis_chord_page.dart
// Halaman daftar level fitur Kuis Chord. Pemain menebak nama chord dari diagram fretboard. Level
// dikelompokkan menurut tingkat kesulitan (Easy, Medium, Hard). Status kunci tiap level dibaca
// dari ProgressionService. Saat kartu level ditekan, halaman membuka KuisChordGamePage. Data level
// berasal dari quizLevels pada quiz_level_model.dart (features/kuis_chord/models).
// ============================================================================
// Paket Material Flutter.
import 'package:flutter/material.dart';
// Barrel progression: ProgressionService, ProgressionConfig, dan LevelStatus.
import '../../../core/progression/progression.dart';
// Model QuizLevel dan daftar quizLevels yang menjadi sumber data level.
import '../models/quiz_level_model.dart';
// Halaman game (KuisChordGamePage) yang dibuka saat level dipilih.
import 'kuis_chord_game_page.dart';

// Widget stateless karena data level bersifat tetap dan pembaruan dilakukan lewat
// ListenableBuilder.
class KuisChordPage extends StatelessWidget {
  // Konstruktor const dengan parameter key.
  const KuisChordPage({super.key});

  // Warna latar halaman.
  static const Color _bg = Color(0xFF070A0F);
  // Warna cyan untuk tingkat Easy.
  static const Color _cyan = Color(0xFF00E5FF);
  // Warna ungu untuk tingkat Medium.
  static const Color _purple = Color(0xFFBD00FF);
  // Warna oranye untuk tingkat Hard.
  static const Color _orange = Color(0xFFFFAA00);

  // Mengembalikan warna aksen sesuai tingkat kesulitan (Easy cyan, Medium ungu, Hard oranye).
  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return _cyan;
      case 'Medium':
        return _purple;
      case 'Hard':
        return _orange;
      default:
        return _cyan;
    }
  }

  // Mengembalikan ikon bintang sesuai tingkat kesulitan (kosong, setengah, penuh).
  IconData _difficultyIcon(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return Icons.star_outline_rounded;
      case 'Medium':
        return Icons.star_half_rounded;
      case 'Hard':
        return Icons.star_rounded;
      default:
        return Icons.star_outline_rounded;
    }
  }

  @override
  // Method build() menyusun tampilan halaman.
  Widget build(BuildContext context) {
    // Mengelompokkan level berdasarkan tingkat kesulitan menggunakan where dan toList.
    final Map<String, List<QuizLevel>> grouped = {
      'Easy': quizLevels.where((l) => l.difficulty == 'Easy').toList(),
      'Medium': quizLevels.where((l) => l.difficulty == 'Medium').toList(),
      'Hard': quizLevels.where((l) => l.difficulty == 'Hard').toList(),
    };

    // Scaffold sebagai kerangka halaman.
    return Scaffold(
      backgroundColor: _bg,
      // SafeArea agar isi tidak tertutup poni atau bilah sistem.
      body: SafeArea(
        // ListenableBuilder membangun ulang daftar bila progres berubah (misalnya level baru
        // terbuka).
        child: ListenableBuilder(
          // Objek yang didengarkan: ProgressionService.
          listenable: ProgressionService.instance,
          builder: (context, _) {
            // ListView agar halaman dapat digulir.
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white70,
                        size: 18,
                      ),
                      // Tombol kembali: menutup halaman ini dan kembali ke halaman sebelumnya.
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.quiz_rounded,
                      color: Color(0xFF00E5FF),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Kuis Chord',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Kotak informasi singkat tentang fitur ini.
                // Header info
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _cyan.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _cyan.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _cyan.withValues(alpha: 0.1),
                          border: Border.all(
                            color: _cyan.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: _cyan,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Uji Kemampuanmu!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Tebak chord dari diagram fretboard',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Membuat satu bagian untuk setiap tingkat kesulitan. Tanda ... menyebarkan hasil
                // map ke dalam daftar anak.
                // Grouped levels
                ...grouped.entries.map((entry) {
                  // Nama tingkat kesulitan (kunci kelompok).
                  final difficulty = entry.key;
                  // Daftar level pada tingkat tersebut.
                  final levels = entry.value;
                  // Warna aksen untuk tingkat tersebut.
                  final color = _difficultyColor(difficulty);
                  // Ikon untuk tingkat tersebut.
                  final icon = _difficultyIcon(difficulty);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10, top: 4),
                        child: Row(
                          children: [
                            Icon(icon, color: color, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              difficulty.toUpperCase(),
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: color.withValues(alpha: 0.15),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Membuat kartu untuk setiap level pada tingkat tersebut.
                      ...levels.map((level) {
                        // Membaca status level (locked, unlocked, atau completed) dari
                        // ProgressionService.
                        final status = ProgressionService.instance.levelStatus(
                          // Kunci fitur Kuis Chord agar progres dibaca khusus untuk fitur ini.
                          ProgressionConfig.featureQuiz,
                          level.id,
                        );
                        // Membuat kartu level dengan data level, warna aksen, dan status.
                        return _LevelCard(
                          level: level,
                          accentColor: color,
                          status: status,
                        );
                      }),
                      const SizedBox(height: 12),
                    ],
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Kartu satu level pada daftar Kuis Chord (private, hanya dipakai di file ini).
class _LevelCard extends StatelessWidget {
  // Data level yang ditampilkan pada kartu.
  final QuizLevel level;
  // Warna aksen sesuai tingkat kesulitan.
  final Color accentColor;
  // Status level (terkunci, terbuka, atau selesai).
  final LevelStatus status;

  const _LevelCard({
    required this.level,
    required this.accentColor,
    required this.status,
  });

  // Warna latar kartu.
  static const Color _card = Color(0xFF0D1520);

  @override
  // Method build() menyusun tampilan kartu.
  Widget build(BuildContext context) {
    // True jika level terkunci.
    final isLocked = status == LevelStatus.locked;
    // True jika level sudah selesai.
    final isCompleted = status == LevelStatus.completed;
    // Warna kartu: lebih redup bila terkunci.
    final cardColor = isLocked ? accentColor.withValues(alpha: 0.04) : _card;
    // Warna border: abu-abu bila terkunci, aksen tegas bila selesai, aksen tipis bila terbuka.
    final borderColor = isLocked
        ? Colors.white12
        : isCompleted
        ? accentColor.withValues(alpha: 0.35)
        : accentColor.withValues(alpha: 0.12);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        // Kartu terkunci dibuat lebih transparan.
        opacity: isLocked ? 0.45 : 1.0,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            // Jika terkunci, menampilkan pesan peringatan; jika tidak, membuka KuisChordGamePage
            // dengan level terpilih.
            onTap: isLocked
                ? () => _showLockedSnackbar(context)
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => KuisChordGamePage(level: level),
                    ),
                  ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Row(
                children: [
                  // Lencana bulat di kiri: ikon gembok bila terkunci, atau nomor level.
                  // Level number / lock icon
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLocked
                          ? Colors.white.withValues(alpha: 0.04)
                          : accentColor.withValues(alpha: 0.08),
                      border: Border.all(
                        color: isLocked
                            ? Colors.white24
                            : accentColor.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: isLocked
                          ? const Icon(
                              Icons.lock_rounded,
                              color: Colors.white30,
                              size: 16,
                            )
                          : Text(
                              '${level.id}',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          level.name,
                          style: TextStyle(
                            color: isLocked ? Colors.white38 : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isLocked
                              ? 'Selesaikan level sebelumnya untuk membuka'
                              : level.subtitle,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Bagian kanan kartu: poin target (dalam satuan pts) dan ikon status (gembok,
                  // centang, atau panah).
                  // Trailing: points + status icon
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${level.targetPoints} pts',
                        style: TextStyle(
                          color: isLocked ? Colors.white24 : accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'target',
                        style: TextStyle(color: Colors.white24, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isLocked
                        ? Icons.lock_rounded
                        : isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.chevron_right_rounded,
                    color: isLocked
                        ? Colors.white12
                        : isCompleted
                        ? accentColor
                        : Colors.white24,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Menampilkan SnackBar peringatan bahwa level sebelumnya harus diselesaikan terlebih dahulu.
  void _showLockedSnackbar(BuildContext context) {
    // ScaffoldMessenger menampilkan SnackBar di Scaffold terdekat.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.lock_rounded, color: Colors.white70, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Selesaikan level sebelumnya terlebih dahulu!',
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
