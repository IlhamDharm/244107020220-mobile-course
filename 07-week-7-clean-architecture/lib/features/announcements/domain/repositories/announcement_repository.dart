import '../../../../core/failures.dart';
import '../entities/announcement.dart';

typedef AnnouncementsResult = ({
  List<Announcement> announcements,
  Failure? failure,
});
typedef AnnouncementResult = ({Announcement? announcement, Failure? failure});

abstract interface class AnnouncementRepository {
  Future<AnnouncementsResult> fetchAnnouncements();
  Future<AnnouncementResult> findById(String id);
}
