import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/domain/task_contract.dart';

/// Fake implementation of TaskRepository according to Step 4 of Codelab #12.
class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository({List<String>? initialTasks, this.error})
    : _tasks = List.of(initialTasks ?? []);

  final List<String> _tasks;
  final Exception? error;

  @override
  Future<List<String>> getTasks() async {
    if (error != null) throw error!;
    return List.unmodifiable(_tasks);
  }

  @override
  Future<void> addTask(String title) async {
    if (error != null) throw error!;
    _tasks.add(title);
  }
}

void main() {
  group('TaskService with FakeTaskRepository (Async & Dependency Tests)', () {
    test(
      'loadTasks() meneruskan data dari repository saat sukses (Happy Path)',
      () async {
        // Arrange
        final fakeRepo = FakeTaskRepository(
          initialTasks: ['Belajar Flutter', 'Mengerjakan Modul 12'],
        );
        final service = TaskService(fakeRepo);

        // Act
        final result = await service.loadTasks();

        // Assert
        expect(result, ['Belajar Flutter', 'Mengerjakan Modul 12']);
      },
    );

    test('loadTasks() melempar exception saat terjadi kegagalan jaringan/database (Error Path)', () async {
      // Arrange
      final fakeRepo = FakeTaskRepository(
        error: Exception('Koneksi timeout ke server'),
      );
      final service = TaskService(fakeRepo);

      // Act & Assert
      expect(
        () async => await service.loadTasks(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'pesan',
            contains('Koneksi timeout ke server'),
          ),
        ),
      );
    });

    test('createTask() menambahkan tugas baru ke repository', () async {
      // Arrange
      final fakeRepo = FakeTaskRepository(initialTasks: ['Tugas 1']);
      final service = TaskService(fakeRepo);

      // Act
      await service.createTask('Tugas 2');

      // Assert
      final tasks = await service.loadTasks();
      expect(tasks, ['Tugas 1', 'Tugas 2']);
    });

    test(
      'createTask() menolak judul kosong dengan ArgumentError (Edge Case)',
      () async {
        // Arrange
        final fakeRepo = FakeTaskRepository();
        final service = TaskService(fakeRepo);

        // Act & Assert
        expect(
          () async => await service.createTask('   '),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Judul tugas tidak boleh kosong'),
            ),
          ),
        );
      },
    );
  });
}
