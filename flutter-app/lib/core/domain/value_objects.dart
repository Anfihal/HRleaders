import '../error/app_failure.dart';

final class Email {
  Email(String input) : value = input.trim().toLowerCase() {
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
      throw const AppFailure(FailureKind.validation, 'invalid_email');
    }
  }
  final String value;
}

final class EntityId {
  EntityId(this.value) {
    if (!RegExp(r'^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$')
        .hasMatch(value)) {
      throw const AppFailure(FailureKind.validation, 'invalid_id');
    }
  }
  final String value;
  @override
  bool operator ==(Object other) => other is EntityId && other.value == value;
  @override
  int get hashCode => value.hashCode;
}

final class Salary {
  Salary(this.amount) {
    if (amount <= 0) {
      throw const AppFailure(FailureKind.validation, 'invalid_salary');
    }
  }
  final int amount;
}

final class SalaryRange {
  SalaryRange(int from, int to) : from = Salary(from), to = Salary(to) {
    if (from > to) {
      throw const AppFailure(FailureKind.validation, 'invalid_salary_range');
    }
  }
  final Salary from;
  final Salary to;
  bool contains(Salary salary) =>
      salary.amount >= from.amount && salary.amount <= to.amount;
}

final class Page<T> {
  Page({
    required List<T> items,
    required this.total,
    required this.offset,
    required this.limit,
  }) : items = List.unmodifiable(items);
  final List<T> items;
  final int total;
  final int offset;
  final int limit;
  bool get hasMore => offset + items.length < total;
}
