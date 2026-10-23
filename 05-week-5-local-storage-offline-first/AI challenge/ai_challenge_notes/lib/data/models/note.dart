/// Model catatan (Note) untuk menyimpan data ke SQLite via sqflite.
/// Menggunakan konversi Map agar kompatibel dengan database SQLite.
class Note {
  const Note({
    this.id,
    required this.title,
    this.body = '',
    required this.updatedAt,
    this.dirty = false,
  });

  /// Primary key auto-increment dari SQLite (null jika belum disimpan)
  final int? id;

  /// Judul catatan
  final String title;

  /// Isi/konten catatan
  final String body;

  /// Waktu terakhir diperbarui (digunakan untuk pengurutan & sync)
  final DateTime updatedAt;

  /// Flag sinkronisasi: true = belum di-sync ke server
  final bool dirty;

  /// Konversi Note ke Map untuk operasi INSERT/UPDATE SQLite
  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'updated_at': updatedAt.toIso8601String(),
        'dirty': dirty ? 1 : 0,
      };

  /// Factory constructor: buat Note dari Map hasil query SQLite.
  /// Aman terhadap null karena menggunakan fallback default pada setiap field.
  factory Note.fromMap(Map<String, Object?> map) {
    return Note(
      id: (map['id'] as num?)?.toInt(),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      dirty: ((map['dirty'] as num?)?.toInt() ?? 0) == 1,
    );
  }

  /// Helper: buat salinan Note dengan field tertentu diganti
  Note copyWith({
    int? id,
    String? title,
    String? body,
    DateTime? updatedAt,
    bool? dirty,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      updatedAt: updatedAt ?? this.updatedAt,
      dirty: dirty ?? this.dirty,
    );
  }
}
