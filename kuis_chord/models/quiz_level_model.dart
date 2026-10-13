// ============================================================================
// quiz_level_model.dart
// Model data level Kuis Chord beserta daftar quizLevels (20 level). Dipakai oleh KuisChordPage dan
// KuisChordGamePage; juga menjadi sumber data bagi earLevels (Ear Training) dan dirujuk oleh
// halaman lain yang memakai QuizLevel.
// ============================================================================
// Kelas model data satu level kuis (immutable).
class QuizLevel {
  // Nomor level (1 sampai 20).
  final int id;
  // Nama level yang ditampilkan.
  final String name;
  // Subjudul berisi daftar chord pada level tersebut.
  final String subtitle;
  // Daftar nama chord yang diujikan pada level.
  final List<String> chordNames;
  // Tipe chord level (major, minor, 7, sus4, add9, maj7, m7, 5, atau mixed).
  final String type;
  // Target poin yang harus dicapai untuk menyelesaikan level.
  final int targetPoints;
  // Tingkat kesulitan (Easy, Medium, atau Hard).
  final String difficulty;
  // Batas waktu permainan dalam detik.
  final int timeLimitSeconds;

  // Konstruktor const; targetPoints bawaan 10 dan timeLimitSeconds bawaan 120.
  const QuizLevel({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.chordNames,
    required this.type,
    required this.difficulty,
    this.targetPoints = 10,
    this.timeLimitSeconds = 120,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Durasi waktu: FLAT 120 detik untuk semua level & tingkat kesulitan (sengaja
// tidak dibedakan per level — arahan dosen pembimbing, biar nggak jadi
// blunder pas diuji: waktu cuma dipakai sebagai batas tantangan, sama sekali
// tidak mempengaruhi besaran XP (lihat ProgressionService.completeLevel).
// ─────────────────────────────────────────────────────────────────────────────
// Daftar seluruh level kuis, diurutkan dari Easy, Medium, Hard, hingga Grand Master.
final List<QuizLevel> quizLevels = [

  // ══════════════════════════════════════════════════════════════
  //  EASY
  // ══════════════════════════════════════════════════════════════
  // Level 1: Major Dasar (target 8 poin).
  const QuizLevel(
    id: 1,
    name: 'Major Dasar',
    subtitle: 'C · G · D · A · E',
    chordNames: ['C', 'G', 'D', 'A', 'E'],
    type: 'major',
    difficulty: 'Easy',
    targetPoints: 8,
  ),
  // Level 2: Minor Dasar (target 8 poin).
  const QuizLevel(
    id: 2,
    name: 'Minor Dasar',
    subtitle: 'Am · Em · Dm · Bm',
    chordNames: ['Am', 'Em', 'Dm', 'Bm'],
    type: 'minor',
    difficulty: 'Easy',
    targetPoints: 8,
  ),
  // Level 3: campuran Major dan Minor (target 10 poin).
  const QuizLevel(
    id: 3,
    name: 'Major & Minor Mix',
    subtitle: 'C · Am · G · Em · D · Bm · F · Fm',
    chordNames: ['C', 'Am', 'G', 'Em', 'D', 'Bm', 'F', 'Fm'],
    type: 'mixed',
    difficulty: 'Easy',
    targetPoints: 10,
  ),
  // Level 4: seluruh chord Major natural.
  const QuizLevel(
    id: 4,
    name: 'Major Lengkap (Natural)',
    subtitle: 'C · D · E · F · G · A · B',
    chordNames: ['C', 'D', 'E', 'F', 'G', 'A', 'B'],
    type: 'major',
    difficulty: 'Easy',
    targetPoints: 10,
  ),
  // Level 5: seluruh chord Minor natural.
  const QuizLevel(
    id: 5,
    name: 'Minor Lengkap (Natural)',
    subtitle: 'Cm · Dm · Em · Fm · Gm · Am · Bm',
    chordNames: ['Cm', 'Dm', 'Em', 'Fm', 'Gm', 'Am', 'Bm'],
    type: 'minor',
    difficulty: 'Easy',
    targetPoints: 10,
  ),

  // Awal tingkat Medium.
  // ══════════════════════════════════════════════════════════════
  //  MEDIUM
  // ══════════════════════════════════════════════════════════════
  // Level 6: Major kromatik (chord dengan tanda #).
  const QuizLevel(
    id: 6,
    name: 'Major Kromatik',
    subtitle: 'C# · D# · F# · G# · A#',
    chordNames: ['C#', 'D#', 'F#', 'G#', 'A#'],
    type: 'major',
    difficulty: 'Medium',
    targetPoints: 10,
  ),
  // Level 7: Minor kromatik.
  const QuizLevel(
    id: 7,
    name: 'Minor Kromatik',
    subtitle: 'C#m · D#m · F#m · G#m · A#m',
    chordNames: ['C#m', 'D#m', 'F#m', 'G#m', 'A#m'],
    type: 'minor',
    difficulty: 'Medium',
    targetPoints: 10,
  ),
  // Level 8: Dominant 7th natural.
  const QuizLevel(
    id: 8,
    name: 'Dominant 7th (Natural)',
    subtitle: 'C7 · D7 · E7 · F7 · G7 · A7 · B7',
    chordNames: ['C7', 'D7', 'E7', 'F7', 'G7', 'A7', 'B7'],
    type: '7',
    difficulty: 'Medium',
    targetPoints: 10,
  ),
  // Level 9: Dominant 7th kromatik.
  const QuizLevel(
    id: 9,
    name: 'Dominant 7th (Kromatik)',
    subtitle: 'C#7 · D#7 · F#7 · G#7 · A#7',
    chordNames: ['C#7', 'D#7', 'F#7', 'G#7', 'A#7'],
    type: '7',
    difficulty: 'Medium',
    targetPoints: 10,
  ),
  // Level 10: Sus4 natural.
  const QuizLevel(
    id: 10,
    name: 'Sus4 (Natural)',
    subtitle: 'Csus4 · Dsus4 · Esus4 · Fsus4 · Gsus4 · Asus4 · Bsus4',
    chordNames: ['Csus4', 'Dsus4', 'Esus4', 'Fsus4', 'Gsus4', 'Asus4', 'Bsus4'],
    type: 'sus4',
    difficulty: 'Medium',
    targetPoints: 10,
  ),
  // Level 11: Sus4 kromatik.
  const QuizLevel(
    id: 11,
    name: 'Sus4 (Kromatik)',
    subtitle: 'C#sus4 · D#sus4 · F#sus4 · G#sus4 · A#sus4',
    chordNames: ['C#sus4', 'D#sus4', 'F#sus4', 'G#sus4', 'A#sus4'],
    type: 'sus4',
    difficulty: 'Medium',
    targetPoints: 10,
  ),
  // Level 12: Add9 natural.
  const QuizLevel(
    id: 12,
    name: 'Add9 (Natural)',
    subtitle: 'Cadd9 · Dadd9 · Eadd9 · Fadd9 · Gadd9 · Aadd9 · Badd9',
    chordNames: ['Cadd9', 'Dadd9', 'Eadd9', 'Fadd9', 'Gadd9', 'Aadd9', 'Badd9'],
    type: 'add9',
    difficulty: 'Medium',
    targetPoints: 10,
  ),
  // Level 13: Add9 kromatik.
  const QuizLevel(
    id: 13,
    name: 'Add9 (Kromatik)',
    subtitle: 'C#add9 · D#add9 · F#add9 · G#add9 · A#add9',
    chordNames: ['C#add9', 'D#add9', 'F#add9', 'G#add9', 'A#add9'],
    type: 'add9',
    difficulty: 'Medium',
    targetPoints: 10,
  ),

  // Awal tingkat Hard.
  // ══════════════════════════════════════════════════════════════
  //  HARD
  // ══════════════════════════════════════════════════════════════
  // Level 14: Major 7th natural (target 12 poin).
  const QuizLevel(
    id: 14,
    name: 'Major 7th (Natural)',
    subtitle: 'Cmaj7 · Dmaj7 · Emaj7 · Fmaj7 · Gmaj7 · Amaj7 · Bmaj7',
    chordNames: ['Cmaj7', 'Dmaj7', 'Emaj7', 'Fmaj7', 'Gmaj7', 'Amaj7', 'Bmaj7'],
    type: 'maj7',
    difficulty: 'Hard',
    targetPoints: 12,
  ),
  // Level 15: Major 7th kromatik.
  const QuizLevel(
    id: 15,
    name: 'Major 7th (Kromatik)',
    subtitle: 'C#maj7 · D#maj7 · F#maj7 · G#maj7 · A#maj7',
    chordNames: ['C#maj7', 'D#maj7', 'F#maj7', 'G#maj7', 'A#maj7'],
    type: 'maj7',
    difficulty: 'Hard',
    targetPoints: 12,
  ),
  // Level 16: Minor 7th natural.
  const QuizLevel(
    id: 16,
    name: 'Minor 7th (Natural)',
    subtitle: 'Cm7 · Dm7 · Em7 · Fm7 · Gm7 · Am7 · Bm7',
    chordNames: ['Cm7', 'Dm7', 'Em7', 'Fm7', 'Gm7', 'Am7', 'Bm7'],
    type: 'm7',
    difficulty: 'Hard',
    targetPoints: 12,
  ),
  // Level 17: Minor 7th kromatik.
  const QuizLevel(
    id: 17,
    name: 'Minor 7th (Kromatik)',
    subtitle: 'C#m7 · D#m7 · F#m7 · G#m7 · A#m7',
    chordNames: ['C#m7', 'D#m7', 'F#m7', 'G#m7', 'A#m7'],
    type: 'm7',
    difficulty: 'Hard',
    targetPoints: 12,
  ),
  // Level 18: Power Chord natural.
  const QuizLevel(
    id: 18,
    name: 'Power Chord (Natural)',
    subtitle: 'C5 · D5 · E5 · F5 · G5 · A5 · B5',
    chordNames: ['C5', 'D5', 'E5', 'F5', 'G5', 'A5', 'B5'],
    type: '5',
    difficulty: 'Hard',
    targetPoints: 12,
  ),
  // Level 19: Power Chord kromatik.
  const QuizLevel(
    id: 19,
    name: 'Power Chord (Kromatik)',
    subtitle: 'C#5 · D#5 · F#5 · G#5 · A#5',
    chordNames: ['C#5', 'D#5', 'F#5', 'G#5', 'A#5'],
    type: '5',
    difficulty: 'Hard',
    targetPoints: 12,
  ),

  // Level penutup.
  // ══════════════════════════════════════════════════════════════
  //  GRAND MASTER — 96 chord, semua dari level 1-19 ✓
  //  FIX: sebelumnya hanya 59 chord (37 hilang) + subtitle salah "96 total"
  // ══════════════════════════════════════════════════════════════
  // Level 20: Grand Master, gabungan seluruh jenis chord pada level 1 sampai 19 (target 20 poin).
  const QuizLevel(
    id: 20,
    name: 'Grand Master',
    subtitle: 'Semua jenis chord — 96 chord total',
    // Daftar seluruh chord pada level Grand Master, dikelompokkan per jenis.
    chordNames: [
      // Major natural (7)
      'C', 'D', 'E', 'F', 'G', 'A', 'B',
      // Major kromatik (5)
      'C#', 'D#', 'F#', 'G#', 'A#',
      // Minor natural (7)
      'Cm', 'Dm', 'Em', 'Fm', 'Gm', 'Am', 'Bm',
      // Minor kromatik (5)
      'C#m', 'D#m', 'F#m', 'G#m', 'A#m',
      // Dominant 7th natural (7)
      'C7', 'D7', 'E7', 'F7', 'G7', 'A7', 'B7',
      // Dominant 7th kromatik (5)
      'C#7', 'D#7', 'F#7', 'G#7', 'A#7',
      // Major 7th natural (7)
      'Cmaj7', 'Dmaj7', 'Emaj7', 'Fmaj7', 'Gmaj7', 'Amaj7', 'Bmaj7',
      // Major 7th kromatik (5)
      'C#maj7', 'D#maj7', 'F#maj7', 'G#maj7', 'A#maj7',
      // Minor 7th natural (7)
      'Cm7', 'Dm7', 'Em7', 'Fm7', 'Gm7', 'Am7', 'Bm7',
      // Minor 7th kromatik (5)
      'C#m7', 'D#m7', 'F#m7', 'G#m7', 'A#m7',
      // Sus4 natural (7)
      'Csus4', 'Dsus4', 'Esus4', 'Fsus4', 'Gsus4', 'Asus4', 'Bsus4',
      // Sus4 kromatik (5)
      'C#sus4', 'D#sus4', 'F#sus4', 'G#sus4', 'A#sus4',
      // Add9 natural (7)
      'Cadd9', 'Dadd9', 'Eadd9', 'Fadd9', 'Gadd9', 'Aadd9', 'Badd9',
      // Add9 kromatik (5)
      'C#add9', 'D#add9', 'F#add9', 'G#add9', 'A#add9',
      // Power chord natural (7)
      'C5', 'D5', 'E5', 'F5', 'G5', 'A5', 'B5',
      // Power chord kromatik (5)
      'C#5', 'D#5', 'F#5', 'G#5', 'A#5',
    ],
    type: 'mixed',
    difficulty: 'Hard',
    targetPoints: 20,
  ),
];
