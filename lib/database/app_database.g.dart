// GENERATED CODE - DO NOT MODIFY BY HAND
// Placeholder generated part file for AppDatabase.
// Running `dart run build_runner build --delete-conflicting-outputs` will
// regenerate this file using drift_dev.

part of 'app_database.dart';

class _SimpleResultSet extends ResultSetImplementation<_SimpleResultSet, Never> {
  @override
  final String entityName;
  final GeneratedDatabase attachedDatabase;

  _SimpleResultSet(this.entityName, this.attachedDatabase);

  @override
  _SimpleResultSet get asDslTable => this;

  @override
  List<GeneratedColumn> get $columns => const [];

  @override
  String get actualTableName => entityName;

  @override
  FutureOr<Never> map(Map<String, dynamic> data, {String? tablePrefix}) {
    throw UnimplementedError();
  }

  @override
  _SimpleResultSet createAlias(String alias) => this;
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(super.e);

  late final ResultSetImplementation profiles =
      _SimpleResultSet('profile', this);
  late final ResultSetImplementation goals = _SimpleResultSet('goals', this);
  late final ResultSetImplementation foods = _SimpleResultSet('foods', this);
  late final ResultSetImplementation foodLogs =
      _SimpleResultSet('food_logs', this);
  late final ResultSetImplementation waterLogs =
      _SimpleResultSet('water_logs', this);
  late final ResultSetImplementation reminderSettings =
      _SimpleResultSet('reminder_settings', this);
  late final ResultSetImplementation appSettings =
      _SimpleResultSet('app_settings', this);

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => const [];
}
