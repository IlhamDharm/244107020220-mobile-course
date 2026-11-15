/// Kontrak antarmuka TaskRepository sesuai Langkah 4 Modul 12.
/// Memisahkan sumber data sehingga kode mudah diuji dengan Fake Repository.
abstract interface class TaskRepository {
  Future<List<String>> getTasks();
  Future<void> addTask(String title);
}

/// Service logika aplikasi yang berinteraksi dengan TaskRepository.
class TaskService {
  TaskService(this._repository);

  final TaskRepository _repository;

  Future<List<String>> loadTasks() {
    return _repository.getTasks();
  }

  Future<void> createTask(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Judul tugas tidak boleh kosong');
    }
    await _repository.addTask(trimmed);
  }
}
