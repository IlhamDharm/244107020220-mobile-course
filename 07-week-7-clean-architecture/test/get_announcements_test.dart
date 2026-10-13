import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:campus_notify/features/announcements/domain/usecases/get_announcements.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAnnouncementRepository implements AnnouncementRepository {
  FakeAnnouncementRepository({this.items = const [], this.fail = false});

  final List<Announcement> items;
  final bool fail;

  @override
  Future<AnnouncementsResult> fetchAnnouncements() async {
    if (fail) {
      return (
        announcements: const <Announcement>[],
        failure: const LocalFailure('db locked (simulasi)'),
      );
    }
    return (announcements: items, failure: null);
  }

  @override
  Future<AnnouncementResult> findById(String id) async {
    final result = await fetchAnnouncements();
    if (result.failure != null) {
      return (announcement: null, failure: result.failure);
    }
    for (final item in items) {
      if (item.id == id) return (announcement: item, failure: null);
    }
    return (
      announcement: null,
      failure: LocalFailure('Pengumuman #$id tidak ditemukan.'),
    );
  }
}

void main() {
  test('GetAnnouncements meneruskan daftar dari repository', () async {
    final repo = FakeAnnouncementRepository(
      items: [
        Announcement(
          id: '3',
          title: 'Jadwal kuliah berubah',
          body: 'Kelas pindah ke A2.',
          updatedAt: DateTime(2026, 9, 27),
        ),
      ],
    );

    final result = await GetAnnouncements(repo).call();

    expect(result.failure, isNull);
    expect(result.announcements.length, 1);
    expect(result.announcements.first.title, 'Jadwal kuliah berubah');
  });

  test('GetAnnouncements meneruskan failure tanpa melempar', () async {
    final repo = FakeAnnouncementRepository(fail: true);

    final result = await GetAnnouncements(repo).call();

    expect(result.failure, isA<LocalFailure>());
    expect(result.announcements, isEmpty);
  });
}
