import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../models/announcement_model.dart';

class DemoAnnouncementRepository implements AnnouncementRepository {
  const DemoAnnouncementRepository();

  static final _items = <AnnouncementModel>[
    AnnouncementModel(
      id: '3',
      title: 'Jadwal kuliah berubah',
      body: 'Kuliah Pemrograman Mobile dipindah ke Ruang A2.',
      updatedAt: DateTime(2026, 9, 27, 13),
    ),
    AnnouncementModel(
      id: '2',
      title: 'Pembayaran UKT',
      body: 'Batas pembayaran UKT semester ini adalah Jumat pukul 15.00.',
      updatedAt: DateTime(2026, 9, 26, 9, 30),
    ),
  ];

  @override
  Future<AnnouncementsResult> fetchAnnouncements() async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      return (
        announcements: _items.map((item) => item.toEntity()).toList(),
        failure: null,
      );
    } catch (error) {
      return (
        announcements: const <Announcement>[],
        failure: LocalFailure('Gagal membaca pengumuman: $error'),
      );
    }
  }

  @override
  Future<AnnouncementResult> findById(String id) async {
    final result = await fetchAnnouncements();
    if (result.failure != null) {
      return (announcement: null, failure: result.failure);
    }

    for (final announcement in result.announcements) {
      if (announcement.id == id) {
        return (announcement: announcement, failure: null);
      }
    }
    return (
      announcement: null,
      failure: LocalFailure('Pengumuman #$id tidak ditemukan.'),
    );
  }
}
