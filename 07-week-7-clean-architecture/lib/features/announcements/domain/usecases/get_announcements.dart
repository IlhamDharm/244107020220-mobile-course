import '../repositories/announcement_repository.dart';

class GetAnnouncements {
  const GetAnnouncements(this._repository);

  final AnnouncementRepository _repository;

  Future<AnnouncementsResult> call() => _repository.fetchAnnouncements();
}
