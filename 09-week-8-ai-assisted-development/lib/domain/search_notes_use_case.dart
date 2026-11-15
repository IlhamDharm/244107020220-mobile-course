import '../data/local/note.dart';

/// Pure domain use case for filtering and searching notes.
///
/// This class has no dependencies on Flutter UI frameworks, database
/// drivers (SQLite), or network libraries (Dio), fulfilling the Clean Architecture
/// dependency rule where inner domain logic remains pure and easily testable.
class SearchNotesUseCase {
  const SearchNotesUseCase();

  /// Filters [notes] based on [query].
  ///
  /// - Empty or whitespace-only queries return the original [notes] unmodified.
  /// - Search is case-insensitive.
  /// - Matches either note title or note body.
  List<Note> execute(List<Note> notes, String query) {
    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.isEmpty) {
      return notes;
    }

    return notes.where((note) {
      final title = note.title.toLowerCase();
      final body = note.body.toLowerCase();
      return title.contains(trimmedQuery) || body.contains(trimmedQuery);
    }).toList();
  }
}
