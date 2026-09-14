import 'package:flutter_riverpod/flutter_riverpod.dart';

// Model data ToDo (bersifat immutable)
class Todo {
  final String title;
  final bool done;

  Todo(this.title, {this.done = false});

  Todo copyWith({String? title, bool? done}) {
    return Todo(
      title ?? this.title,
      done: done ?? this.done,
    );
  }
}

// State notifier untuk mengelola List
class TodoListNotifier extends Notifier<List<Todo>> {
  @override
  List<Todo> build() => const [];

  void add(String title) {
    // Membuat list baru dengan spread operator agar memicu update
    state = [...state, Todo(title)];
  }

  void toggle(int index) {
    final todos = [...state];
    todos[index] = todos[index].copyWith(done: !todos[index].done);
    state = todos;
  }

  void remove(int index) {
    state = [...state]..removeAt(index);
  }
}

// Deklarasi global provider
final todoListProvider =
  NotifierProvider<TodoListNotifier, List<Todo>>(TodoListNotifier.new);

// Enum status filter
enum TodoFilter { all, active, completed }

// Notifier untuk mengelola state filter
class TodoFilterNotifier extends Notifier<TodoFilter> {
  @override
  TodoFilter build() => TodoFilter.all;

  void setFilter(TodoFilter filter) {
    state = filter;
  }
}

// Provider untuk filter
final todoFilterProvider =
  NotifierProvider<TodoFilterNotifier, TodoFilter>(TodoFilterNotifier.new);

// Provider turunan yang membaca todoListProvider dan todoFilterProvider
final filteredTodoListProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider);
  final filter = ref.watch(todoFilterProvider);

  switch (filter) {
    case TodoFilter.active:
      return todos.where((todo) => !todo.done).toList();
    case TodoFilter.completed:
      return todos.where((todo) => todo.done).toList();
    case TodoFilter.all:
      return todos;
  }
});