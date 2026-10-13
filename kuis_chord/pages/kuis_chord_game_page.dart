// ============================================================================
// kuis_chord_game_page.dart
// Halaman permainan Kuis Chord. Pemain melihat diagram fretboard sebuah chord (digambar oleh
// ChordFretboardWidget), lalu menebak namanya dari empat pilihan sebelum waktu habis. Skor
// bertambah jika benar dan berkurang jika salah. Ketika skor mencapai target, level diselesaikan
// melalui ProgressionService.completeLevel. Efek suara dimainkan oleh QuizAudioService. Dibuka dari
// KuisChordPage. File ini juga mendefinisikan fungsi formatChordName yang dipakai ulang oleh
// halaman Ear Training.
// ============================================================================
import 'dart:async';
// Library math: untuk Random, sin, dan pi.
import 'dart:math';
// Paket Material Flutter.
import 'package:flutter/material.dart';
// Paket services: untuk HapticFeedback (getaran).
import 'package:flutter/services.dart';
// Data pustaka chord (chordLibrary).
import '../../pustaka_chord/data/chord_library.dart';
// Model ChordModel.
import '../../pustaka_chord/models/chord_model.dart';
// Widget penggambar diagram fretboard chord dari fitur Pustaka Chord.
import '../../pustaka_chord/widgets/chord_fretboard_widget.dart';
// Model QuizLevel: data level (id, nama, daftar chord, target poin, batas waktu).
import '../models/quiz_level_model.dart';
// Layanan efek suara benar, salah, menang, dan gagal.
import '../../../core/services/quiz_audio_service.dart';
// Bilah progres poin menuju target.
import '../widgets/kuis_progress_bar.dart';
// Barrel progression: ProgressionService dan ProgressionConfig.
import '../../../core/progression/progression.dart';

// Fungsi pembantu pengubah ChordModel menjadi nama tampilan.
// ─────────────────────────────────────────────────────────────────────────────
// Helper — konversi ChordModel → nama tampil
// major  → root (e.g. 'C')
// minor  → root + 'm' (e.g. 'Am')
// lainnya → root + type (e.g. 'C7', 'Cmaj7', 'Csus4')
// ─────────────────────────────────────────────────────────────────────────────
// Mengembalikan nama chord untuk ditampilkan. Aturannya: major hanya root (C), minor ditambah huruf
// m (Am), tipe lain root ditambah tipe (C7, Cmaj7, Csus4). Dipakai pula oleh EarTrainingGamePage.
String formatChordName(ChordModel c) {
  // Tipe major: cukup root.
  if (c.type == 'major') return c.root;
  // Tipe minor: root ditambah huruf m.
  if (c.type == 'minor') return '${c.root}m';
  // Tipe lain: root digabung dengan tipe.
  return '${c.root}${c.type}';
}

// Widget stateful karena memiliki banyak data yang berubah selama permainan (skor, waktu, soal).
class KuisChordGamePage extends StatefulWidget {
  // Data level yang dimainkan.
  // Data level yang dimainkan (diterima dari KuisChordPage).
  final QuizLevel level;
  // Konstruktor dengan parameter level yang wajib diisi.
  const KuisChordGamePage({super.key, required this.level});

  // Menimpa createState() untuk membuat objek State.
  @override
  // Membuat state _KuisChordGamePageState.
  State<KuisChordGamePage> createState() => _KuisChordGamePageState();
}

// Kelas State; TickerProviderStateMixin menyediakan ticker untuk beberapa AnimationController
// sekaligus.
class _KuisChordGamePageState extends State<KuisChordGamePage>
    with TickerProviderStateMixin {
  // Bagian state permainan.
  // ── State ─────────────────────────────────────────────────────────────────
  // Skor pemain saat ini.
  int _points = 0;
  // Jumlah jawaban benar berturut-turut.
  int _streak = 0;
  // Sisa waktu dalam detik; diisi pada initState.
  late int _timeLeft;
  // Indeks bentuk (shape) chord yang ditampilkan; selalu 0 sehingga bentuk pertama yang dipakai.
  int _shapeIndex = 0;
  // Timer penghitung mundur; null bila belum berjalan.
  Timer? _timer;
  // Chord yang sedang ditanyakan.
  ChordModel? _currentChord;
  // Daftar empat pilihan jawaban.
  List<String> _options = [];
  // Penanda permainan sudah berakhir.
  bool _isGameOver = false;
  // Penanda layar intro (pratinjau) masih ditampilkan.
  bool _showIntro = true;
  // Penanda dialog hasil sedang tampil (mencegah dialog ganda).
  bool _dialogShowing = false;
  // Jawaban yang dipilih pemain; null bila belum menjawab.
  String? _selectedAnswer;
  // Pembuat angka acak untuk memilih soal dan mengacak pilihan.
  final Random _random = Random();

  // Bagian audio.
  // ── Audio ─────────────────────────────────────────────────────────────────
  // Efek suara permainan (benar, salah, menang, gagal).
  final QuizAudioService _audio = QuizAudioService();

  // Bagian pengendali animasi.
  // ── Animation controllers ─────────────────────────────────────────────────
  // Pengendali animasi kemunculan soal.
  late AnimationController _questionAnim;
  // Animasi memudar (fade) untuk soal.
  late Animation<double> _questionFade;
  // Pengendali animasi lencana streak.
  late AnimationController _streakAnim;
  // Animasi skala untuk lencana streak.
  late Animation<double> _streakScale;
  // Pengendali animasi cahaya (glow) yang berdenyut pada kartu soal.
  late AnimationController _glowAnim;
  // Animasi denyut dengan kurva halus dari pengendali glow.
  late Animation<double> _glowPulse;

  // Bagian palet warna.
  // ── Palette ───────────────────────────────────────────────────────────────
  // Warna latar halaman.
  static const Color _bg = Color(0xFF070A0F);
  // Warna kartu.
  static const Color _card = Color(0xFF0D1520);
  // Warna cyan (Easy).
  static const Color _cyan = Color(0xFF00E5FF);
  // Warna ungu (Medium).
  static const Color _purple = Color(0xFFBD00FF);
  // Warna oranye (Hard).
  static const Color _orange = Color(0xFFFFAA00);
  // Warna jawaban benar.
  static const Color _correct = Color(0xFF00E676);
  // Warna jawaban salah.
  static const Color _wrong = Color(0xFFFF4C4C);

  // Getter warna aksen sesuai tingkat kesulitan level.
  Color get _accentColor {
    switch (widget.level.difficulty) {
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

  // Bagian siklus hidup (lifecycle).
  // ── Lifecycle ─────────────────────────────────────────────────────────────
  // Menimpa initState() yang dijalankan sekali saat halaman dibuat.
  @override
  void initState() {
    // Memanggil initState() milik kelas induk.
    super.initState();
    // Mengisi sisa waktu dengan batas waktu level.
    _timeLeft = widget.level.timeLimitSeconds;

    // Membuat pengendali animasi soal (300 ms).
    _questionAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Membuat animasi fade dengan kurva easeIn.
    _questionFade = CurvedAnimation(
      parent: _questionAnim,
      curve: Curves.easeIn,
    );
    // Membuat pengendali animasi streak (400 ms).
    _streakAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    // Membuat animasi skala dengan kurva elasticOut.
    _streakScale = CurvedAnimation(
      parent: _streakAnim,
      curve: Curves.elasticOut,
    );
    // Membuat pengendali glow berdurasi 1,8 detik yang berulang bolak-balik.
    _glowAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    // Membuat animasi denyut dengan kurva easeInOut.
    _glowPulse = CurvedAnimation(parent: _glowAnim, curve: Curves.easeInOut);

    // Init audio di background — tidak blocking UI
    // Menyiapkan efek suara.
    _audio.init();

    // Membuat soal pertama.
    _generateQuestion();
    // Memulai animasi kemunculan soal.
    _questionAnim.forward();
  }

  // Menimpa dispose() yang dijalankan saat halaman ditutup.
  @override
  void dispose() {
    // Membatalkan timer.
    _timer?.cancel();
    // Melepas seluruh pengendali animasi.
    _questionAnim.dispose();
    _streakAnim.dispose();
    _glowAnim.dispose();
    // Melepas pemutar suara.
    _audio.dispose(); // bersihkan semua AudioPlayer
    // Memanggil dispose() milik kelas induk.
    super.dispose();
  }

  // Bagian alur permainan.
  // ── Game flow ─────────────────────────────────────────────────────────────
  // Memulai permainan saat tombol Mulai ditekan.
  void _startGame() {
    // Menyembunyikan layar intro.
    setState(() => _showIntro = false);
    // Menjalankan timer.
    _startTimer();
  }

  // Menjalankan timer hitung mundur per detik.
  void _startTimer() {
    // Membatalkan timer lama agar tidak ganda.
    _timer?.cancel();
    // Timer berulang setiap 1 detik.
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      // Jika halaman sudah ditutup (tidak mounted), timer dihentikan.
      if (!mounted) {
        t.cancel();
        return;
      }
      // Jika waktu masih ada, dikurangi 1 detik.
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      // Jika waktu habis, timer dihentikan.
      } else {
        t.cancel();
        // Jika permainan belum ditandai selesai, ditandai selesai.
        if (!_isGameOver) {
          setState(() => _isGameOver = true);
          // Suara gagal — sebelum dialog muncul
          // Memainkan suara gagal.
          _audio.playFail();
          // Menampilkan dialog akhir setelah frame selesai dibangun.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showEndDialog();
          });
        }
      }
    });
  }

  // Mengulang permainan dari awal (dipanggil dari dialog Coba Lagi).
  void _restartGame() {
    _timer?.cancel();
    // Mengembalikan seluruh nilai ke keadaan awal.
    setState(() {
      _points = 0;
      _streak = 0;
      _timeLeft = widget.level.timeLimitSeconds;
      _isGameOver = false;
      _dialogShowing = false;
      _selectedAnswer = null;
      _showIntro = false;
    });
    // Membuat soal baru lalu memulai ulang animasi dan timer.
    _generateQuestion();
    _questionAnim.reset();
    _questionAnim.forward();
    _startTimer();
  }

  // Keluar dari halaman permainan.
  void _exitGame() {
    _timer?.cancel();
    // Menutup halaman bila masih dapat ditutup.
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  // Getter daftar chord yang valid untuk level ini (nama chord ada pada daftar level).
  List<ChordModel> get _validChords => chordLibrary
      .where((c) => widget.level.chordNames.contains(formatChordName(c)))
      .toList();

  // Membuat soal baru.
  void _generateQuestion() {
    // FIX: guard race condition — timer habis saat Future.delayed 750ms masih pending
    // Jika permainan berakhir, tidak membuat soal.
    if (_isGameOver) return;
    // Mengambil seluruh chord yang valid untuk level ini.
    final valid = _validChords;
    // Jika tidak ada chord valid, berhenti.
    if (valid.isEmpty) return;

    // Memilih satu chord secara acak sebagai jawaban benar.
    _currentChord = valid[_random.nextInt(valid.length)];
    // Selalu memakai bentuk pertama dari chord.
    _shapeIndex = 0;

    // Nama jawaban benar.
    final correctName = formatChordName(_currentChord!);
    // Daftar nama chord level lalu jawaban benar dikeluarkan dan sisanya diacak untuk dijadikan
    // pengecoh.
    final allNames = widget.level.chordNames.toList();
    allNames.remove(correctName);
    allNames.shuffle(_random);

    // Pilihan jawaban dimulai dari jawaban benar lalu ditambah pengecoh hingga berjumlah empat.
    final opts = <String>[correctName];
    for (final n in allNames) {
      if (opts.length >= 4) break;
      opts.add(n);
    }
    // Jika pengecoh dari level kurang dari tiga, ditambah dari seluruh pustaka chord.
    if (opts.length < 4) {
      final extras =
          chordLibrary
              .map(formatChordName)
              .where((n) => !opts.contains(n))
              .toList()
            ..shuffle(_random);
      for (final e in extras) {
        if (opts.length >= 4) break;
        opts.add(e);
      }
    }
    // Pilihan diacak agar posisi jawaban benar tidak tetap.
    opts.shuffle(_random);

    // Memperbarui tampilan dengan pilihan baru dan menghapus jawaban sebelumnya.
    setState(() {
      _options = opts;
      _selectedAnswer = null;
    });
    // Memulai animasi kemunculan soal.
    _questionAnim.reset();
    _questionAnim.forward();
  }

  // Memeriksa jawaban yang dipilih pemain.
  void _checkAnswer(String selected) {
    // Diabaikan bila permainan berakhir atau pemain sudah menjawab pada soal ini.
    if (_isGameOver || _selectedAnswer != null) return;
    // Nama jawaban benar.
    final correct = formatChordName(_currentChord!);
    // True jika jawaban pemain sama dengan jawaban benar.
    final isCorrect = selected == correct;

    // Haptic + suara jawaban — berjalan bersamaan
    // Jika benar, getaran ringan dan suara benar.
    if (isCorrect) {
      // Getaran ringan.
      HapticFeedback.lightImpact();
      // Memainkan suara benar.
      _audio.playCorrect();
    } else {
      // Jika salah, getaran kuat dan suara salah.
      HapticFeedback.heavyImpact();
      // Memainkan suara salah.
      _audio.playWrong();
    // Suara salah.
    }

    // Memperbarui skor dan streak.
    setState(() {
      _selectedAnswer = selected;
      // Jika benar: skor dan streak bertambah, animasi streak dijalankan.
      if (isCorrect) {
        _points++;
        _streak++;
        _streakAnim
          ..reset()
          ..forward();
      } else {
        // Jika salah: skor berkurang 1 (tidak kurang dari 0) dan streak diatur ulang.
        if (_points > 0) _points--;
        _streak = 0;
      }
    });

    // Win condition
    // Jika skor mencapai target, permainan dimenangkan.
    if (_points >= widget.level.targetPoints) {
      // Timer dihentikan.
      _timer?.cancel();
      // Suara win setelah suara correct selesai (~0.4–0.5 detik)
      // Suara menang diputar setelah 500 ms.
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _audio.playWin();
      });
      // Dialog kemenangan ditampilkan setelah 700 ms.
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted && !_dialogShowing) _showWinDialog();
      });
      return;
    }

    // Jika belum mencapai target, soal berikutnya dibuat setelah 750 ms.
    Future.delayed(const Duration(milliseconds: 750), () {
      if (mounted && !_isGameOver) _generateQuestion();
    });
  }

  // Bagian pembantu warna tombol jawaban.
  // ── Button colour helpers ─────────────────────────────────────────────────
  // Warna latar tombol: hijau muda untuk jawaban benar, merah muda untuk jawaban salah yang
  // dipilih, selain itu warna kartu.
  Color _btnBg(String option) {
    if (_selectedAnswer == null) return _card;
    final c = formatChordName(_currentChord!);
    if (option == c) return _correct.withValues(alpha: 0.15);
    if (option == _selectedAnswer) return _wrong.withValues(alpha: 0.15);
    return _card;
  }

  // Warna border tombol dengan aturan yang sama.
  Color _btnBorder(String option) {
    if (_selectedAnswer == null) return Colors.white.withValues(alpha: 0.1);
    final c = formatChordName(_currentChord!);
    if (option == c) return _correct;
    if (option == _selectedAnswer) return _wrong;
    return Colors.white.withValues(alpha: 0.05);
  }

  // Warna teks tombol dengan aturan yang sama.
  Color _btnText(String option) {
    if (_selectedAnswer == null) return Colors.white;
    final c = formatChordName(_currentChord!);
    if (option == c) return _correct;
    if (option == _selectedAnswer) return _wrong;
    return Colors.white30;
  }

  // Ikon tombol: centang untuk jawaban benar, silang untuk jawaban salah yang dipilih, selain itu
  // tidak ada.
  IconData? _btnIcon(String option) {
    if (_selectedAnswer == null) return null;
    final c = formatChordName(_currentChord!);
    if (option == c) return Icons.check_circle_rounded;
    if (option == _selectedAnswer) return Icons.cancel_rounded;
    return null;
  }

  // Bagian dialog.
  // ── Dialogs ───────────────────────────────────────────────────────────────
  // Dialog kemenangan: menyelesaikan level lalu menampilkan hasilnya.
  void _showWinDialog() async {
    // Dihentikan bila halaman ditutup atau dialog sudah tampil.
    if (!mounted || _dialogShowing) return;
    // Menandai dialog sedang tampil.
    _dialogShowing = true;

    // ── Simpan progression ─────────────────────────────────────
    // Menyelesaikan level melalui ProgressionService; hasilnya berisi XP dan level baru yang
    // terbuka.
    final result = await ProgressionService.instance.completeLevel(
      // Kunci fitur Kuis Chord agar progres dicatat untuk fitur ini.
      ProgressionConfig.featureQuiz,
      widget.level.id,
    );
    // ──────────────────────────────────────────────────────────

    // Dihentikan bila halaman ditutup selama menunggu.
    if (!mounted) return;

    // Menampilkan dialog hasil kemenangan.
    _showResultDialog(
      icon: '🎸',
      title: 'Luar Biasa!',
      titleColor: _correct,
      message:
          'Level ${widget.level.id} selesai!\nSkor: $_points / ${widget.level.targetPoints}',
      actions: [
        // Kalau ada level baru terbuka → tampilkan banner unlock
        // Isi tombol dialog: banner level terbuka (jika ada) dan tombol Selesai.
        if (result.hasNewUnlock) _unlockBanner(result),
        _dialogAction('Selesai', _accentColor, () {
          Navigator.of(context, rootNavigator: false).pop();
          _exitGame();
        }),
      ],
    );
  }

  // Dialog akhir saat waktu habis dengan tombol Coba Lagi dan Keluar.
  void _showEndDialog() {
    // Dihentikan bila halaman ditutup atau dialog sudah tampil.
    if (!mounted || _dialogShowing) return;
    _dialogShowing = true;
    _showResultDialog(
      icon: '⏱',
      title: 'Waktu Habis!',
      titleColor: _wrong,
      message: 'Skor kamu: $_points / ${widget.level.targetPoints}',
      actions: [
        _dialogAction('Coba Lagi', _accentColor, () {
          Navigator.of(context, rootNavigator: false).pop();
          _restartGame();
        }),
        _dialogAction('Keluar', Colors.white38, () {
          Navigator.of(context, rootNavigator: false).pop();
          _exitGame();
        }),
      ],
    );
  }

  // Banner informasi XP dan level yang baru terbuka.
  Widget _unlockBanner(CompletionResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFBD00FF).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFBD00FF).withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_open_rounded,
            color: Color(0xFFBD00FF),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '+${result.xpGained} XP  •  '
              '${result.difficultyUnlocked} Level ${result.unlockedNextLevel} terbuka!',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontFamily: 'Orbitron',
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog hasil umum yang dipakai oleh dialog kemenangan dan dialog waktu habis.
  void _showResultDialog({
    required String icon,
    required String title,
    required Color titleColor,
    required String message,
    required List<Widget> actions,
  }) {
    // Dihentikan bila halaman sudah ditutup.
    if (!mounted) return;
    // showDialog menampilkan dialog di atas halaman; barrierDismissible false agar tidak dapat
    // ditutup dengan menekan area luar.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      // PopScope dengan canPop false mencegah dialog ditutup dengan tombol kembali.
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          // FIX: bungkus dengan ConstrainedBox agar dialog tidak overflow
          // di device kecil, lalu SingleChildScrollView agar konten scrollable
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            // Kotak isi dialog.
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1520),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: titleColor.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: titleColor.withValues(alpha: 0.15),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              // Isi dialog dapat digulir; berisi ikon, judul, pesan, dan tombol.
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 44)),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 22),
                    // Menyebarkan daftar tombol ke dalam kolom.
                    ...actions,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    // Setelah dialog ditutup, penanda dialog dikembalikan menjadi false.
    ).then((_) {
      if (mounted) setState(() => _dialogShowing = false);
    });
  }

  // Pembuat tombol dialog dengan label, warna, dan aksi.
  Widget _dialogAction(String label, Color color, VoidCallback onTap) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: color.withValues(alpha: 0.6)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(23),
              ),
            ),
            onPressed: onTap,
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );

  // Bagian membangun tampilan (BUILD).
  // ─────────────────────────────── BUILD ───────────────────────────────────
  // Menimpa build() untuk menyusun tampilan.
  @override
  // Menampilkan layar intro bila belum mulai, atau layar permainan bila sudah mulai.
  Widget build(BuildContext context) =>
      _showIntro ? _buildIntroScreen() : _buildGameScreen();

  // Cahaya latar dekoratif di belakang konten.
  // ── Ambient glow di belakang konten — biar background gak item polos ──────
  // Membangun dua cahaya latar dengan warna aksen dan warna pasangannya.
  Widget _buildAmbientGlow(Color accent) {
    // Warna pasangan: ungu jika aksen cyan, selain itu cyan.
    final Color partner = accent == _cyan ? _purple : _cyan;
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(top: -70, right: -60, child: _glowBlob(accent, 260)),
            Positioned(bottom: -100, left: -80, child: _glowBlob(partner, 300)),
          ],
        ),
      ),
    );
  }

  // Membuat satu lingkaran cahaya dengan gradien radial yang memudar.
  Widget _glowBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.16), color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }

  // Layar intro (pratinjau) sebelum permainan dimulai.
  // ─────────────────────── INTRO SCREEN ────────────────────────────────────
  // Method pembangun layar intro.
  Widget _buildIntroScreen() {
    // Daftar nama chord yang akan muncul pada level ini.
    final previewNames = widget.level.chordNames.toList();
    // Mengubah nama chord pada level menjadi objek ChordModel dengan mencari pada chordLibrary.
    final previewChords = previewNames
        .map((name) {
          try {
            // Mencari chord yang namanya sama.
            return chordLibrary.firstWhere((c) => formatChordName(c) == name);
          // Jika tidak ditemukan, hasilnya null.
          } catch (_) {
            return null;
          }
        })
        // whereType menyaring hasil null sehingga hanya ChordModel yang tersisa.
        .whereType<ChordModel>()
        .toList();

    // Warna aksen level.
    final accent = _accentColor;

    // Scaffold sebagai kerangka halaman.
    return Scaffold(
      backgroundColor: _bg,
      // Stack menumpuk cahaya latar di belakang konten.
      body: Stack(
        children: [
          // Cahaya latar.
          _buildAmbientGlow(accent),
          // SafeArea agar isi tidak tertutup poni atau bilah sistem.
          SafeArea(
            child: Column(
              children: [
                // Baris atas: tombol kembali, judul level, dan label tingkat kesulitan.
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white38,
                          size: 18,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Level ${widget.level.id}  •  ${widget.level.name}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          widget.level.difficulty,
                          style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Kartu utama berisi ikon, informasi level, dan daftar chord.
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.1),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 18),
                        // Teks judul: jumlah chord yang dipelajari pada level ini.
                        Text(
                          'PELAJARI CHORD  •  ${previewChords.length} CHORD',
                          style: TextStyle(
                            color: accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Teks target poin dan batas waktu.
                        Text(
                          'Target: ${widget.level.targetPoints} poin  •  ${widget.level.timeLimitSeconds} detik',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Grid pratinjau chord: setiap sel menampilkan nama chord dan diagram
                        // fretboard-nya.
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            // GridView.builder membuat sel sesuai jumlah chord.
                            child: GridView.builder(
                              // Efek memantul saat digulir.
                              physics: const BouncingScrollPhysics(),
                              // Jumlah sel sesuai jumlah chord.
                              itemCount: previewChords.length,
                              // Dua kolom dengan perbandingan ukuran sel 0,82.
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.82,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                              // Membuat satu sel untuk setiap chord.
                              itemBuilder: (context, i) {
                                // Chord pada sel ini.
                                final chord = previewChords[i];
                                // Nama tampil chord.
                                final name = formatChordName(chord);
                                return Container(
                                  decoration: BoxDecoration(
                                    color: _card,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: accent.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  padding: const EdgeInsets.fromLTRB(
                                    6,
                                    10,
                                    6,
                                    6,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          color: accent,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // Diagram fretboard bentuk pertama chord; chordName
                                      // dikosongkan karena nama sudah ada di atasnya.
                                      Expanded(
                                        // FittedBox menyesuaikan ukuran diagram agar muat pada sel.
                                        child: ClipRect(
                                          child: FittedBox(
                                            fit: BoxFit.contain,
                                            child: ChordFretboardWidget(
                                              shape: chord.shapes.first,
                                              chordName: '',
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // Tombol MULAI KUIS yang memanggil _startGame.
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent.withValues(alpha: 0.12),
                                foregroundColor: accent,
                                side: BorderSide(color: accent, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _startGame,
                              child: const Text(
                                'MULAI KUIS',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Layar permainan.
  // ─────────────────────────── GAME SCREEN ─────────────────────────────────
  // Method pembangun layar permainan.
  Widget _buildGameScreen() {
    // Warna aksen level.
    final accent = _accentColor;
    // Ambang waktu hampir habis: seperempat dari batas waktu, dibatasi antara 8 dan 15 detik.
    final int lowThreshold = (widget.level.timeLimitSeconds / 4).round().clamp(
      8,
      15,
    );
    // True jika sisa waktu sudah mencapai ambang sehingga penghitung waktu diberi warna merah.
    final bool timeLow = _timeLeft <= lowThreshold;

    // Scaffold sebagai kerangka layar permainan.
    return Scaffold(
      backgroundColor: _bg,
      // Stack menumpuk cahaya latar di belakang konten.
      body: Stack(
        children: [
          // Cahaya latar.
          _buildAmbientGlow(accent),
          // SafeArea agar isi tidak tertutup poni atau bilah sistem.
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Baris atas: tombol kembali, bilah progres, tombol mute, dan penghitung waktu.
                // ── Top bar ────────────────────────────────────────────────────
                // Baris atas: tombol kembali, bilah progres, tombol mute, dan penghitung waktu.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Tombol kembali.
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white54,
                            size: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Level ${widget.level.id}  •  ${widget.level.name}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            // Bilah progres poin menuju target.
                            KuisProgressBar(
                              currentPoints: _points,
                              targetPoints: widget.level.targetPoints,
                              accentColor: accent,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // ── Mute toggle ──────────────────────────────────────────
                      // Tombol mute: membalik status suara efek.
                      GestureDetector(
                        onTap: () => setState(() => _audio.toggleMute()),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Icon(
                            _audio.isMuted
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            color: _audio.isMuted
                                ? Colors.white24
                                : Colors.white54,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Timer badge
                      // Penghitung waktu; berubah merah bila waktu hampir habis.
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: timeLow
                              ? _wrong.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: timeLow
                                ? _wrong.withValues(alpha: 0.5)
                                : Colors.white12,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_rounded,
                              color: timeLow ? _wrong : Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${_timeLeft}s',
                              style: TextStyle(
                                color: timeLow ? _wrong : Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Question label ─────────────────────────────────────────────
                // Baris judul pertanyaan beserta lencana streak.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'CHORD APAKAH INI?',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                      ),
                    ),
                    // Lencana streak hanya muncul bila jawaban benar berturut-turut mencapai 3 atau
                    // lebih.
                    if (_streak >= 3) ...[
                      const SizedBox(width: 10),
                      // ScaleTransition menjalankan animasi skala pada lencana.
                      ScaleTransition(
                        scale: _streakScale,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _orange.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                color: _orange,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '×$_streak',
                                style: const TextStyle(
                                  color: _orange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 10),

                // Kartu soal: diagram fretboard chord yang harus ditebak.
                // ── Fretboard ─────────────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    // FadeTransition memudarkan kartu saat soal berganti.
                    child: FadeTransition(
                      opacity: _questionFade,
                      // AnimatedBuilder membuat border dan bayangan kartu berdenyut mengikuti
                      // animasi glow.
                      child: AnimatedBuilder(
                        animation: _glowPulse,
                        builder: (context, child) {
                          // Nilai denyut animasi glow.
                          final breathe = _glowPulse.value;
                          return Container(
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _card,
                                  Color.lerp(_card, accent, 0.08) ?? _card,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: accent.withValues(
                                  alpha: 0.10 + 0.14 * breathe,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(
                                    alpha: 0.06 + 0.10 * breathe,
                                  ),
                                  blurRadius: 24,
                                ),
                              ],
                            ),
                            child: child,
                          );
                        },
                        // Tumpukan isi kartu: ikon dekoratif dan diagram.
                        child: Stack(
                          children: [
                            // Dekor musik, murni visual, biar kartu gak polos kosong.
                            Positioned(
                              top: 14,
                              left: 16,
                              child: Icon(
                                Icons.music_note_rounded,
                                color: accent.withValues(alpha: 0.10),
                                size: 20,
                              ),
                            ),
                            Positioned(
                              bottom: 14,
                              right: 18,
                              child: Icon(
                                Icons.music_note_rounded,
                                color: accent.withValues(alpha: 0.08),
                                size: 28,
                              ),
                            ),
                            // Diagram fretboard chord soal; nama chord disembunyikan dan diganti
                            // tanda tanya.
                            Center(
                              // Jika chord sudah ada, diagram ditampilkan; jika belum, tampilan
                              // kosong.
                              child: _currentChord != null
                                  ? FittedBox(
                                      fit: BoxFit.contain,
                                      child: ChordFretboardWidget(
                                        shape:
                                            _currentChord!.shapes[_shapeIndex],
                                        chordName: '?',
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Grid empat pilihan jawaban; hanya tampil bila pilihan sudah dibuat.
                // ── Answer options ─────────────────────────────────────────────
                // Pilihan jawaban ditampilkan hanya jika daftarnya tidak kosong.
                if (_options.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    // GridView.builder dengan dua kolom.
                    child: GridView.builder(
                      // shrinkWrap membuat tinggi grid mengikuti isinya.
                      shrinkWrap: true,
                      // Grid tidak dapat digulir sendiri.
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _options.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 3.2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      // Membuat tombol untuk setiap pilihan.
                      itemBuilder: (context, i) {
                        // Teks pilihan.
                        final opt = _options[i];
                        // Ikon hasil jawaban (jika ada).
                        final icon = _btnIcon(opt);
                        // Kotak tombol dengan warna yang berubah sesuai hasil.
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          decoration: BoxDecoration(
                            color: _btnBg(opt),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _btnBorder(opt),
                              width: 1.5,
                            ),
                          ),
                          // InkWell memberi efek sentuhan; saat ditekan, jawaban diperiksa.
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _checkAnswer(opt),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (icon != null) ...[
                                  Icon(icon, color: _btnText(opt), size: 16),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  opt,
                                  style: TextStyle(
                                    color: _btnText(opt),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
