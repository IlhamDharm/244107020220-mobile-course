import '../repositories/announcement_repository.dart';

class GetAnnouncementDetail {
  const GetAnnouncementDetail(this._repository);

  final AnnouncementRepository _repository;

  Future<AnnouncementResult> call(String id) => _repository.findById(id);
}
