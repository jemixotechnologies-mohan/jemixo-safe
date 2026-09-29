// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ScanRecordsTable extends ScanRecords
    with TableInfo<$ScanRecordsTable, ScanRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScanRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _scanTypeMeta = const VerificationMeta(
    'scanType',
  );
  @override
  late final GeneratedColumn<String> scanType = GeneratedColumn<String>(
    'scan_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _riskLevelMeta = const VerificationMeta(
    'riskLevel',
  );
  @override
  late final GeneratedColumn<String> riskLevel = GeneratedColumn<String>(
    'risk_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _appsScannedMeta = const VerificationMeta(
    'appsScanned',
  );
  @override
  late final GeneratedColumn<int> appsScanned = GeneratedColumn<int>(
    'apps_scanned',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _findingsCountMeta = const VerificationMeta(
    'findingsCount',
  );
  @override
  late final GeneratedColumn<int> findingsCount = GeneratedColumn<int>(
    'findings_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _findingsHighMeta = const VerificationMeta(
    'findingsHigh',
  );
  @override
  late final GeneratedColumn<int> findingsHigh = GeneratedColumn<int>(
    'findings_high',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _findingsMediumMeta = const VerificationMeta(
    'findingsMedium',
  );
  @override
  late final GeneratedColumn<int> findingsMedium = GeneratedColumn<int>(
    'findings_medium',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _findingsLowMeta = const VerificationMeta(
    'findingsLow',
  );
  @override
  late final GeneratedColumn<int> findingsLow = GeneratedColumn<int>(
    'findings_low',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scanType,
    score,
    riskLevel,
    createdAt,
    durationMs,
    appsScanned,
    findingsCount,
    findingsHigh,
    findingsMedium,
    findingsLow,
    summary,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scan_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScanRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('scan_type')) {
      context.handle(
        _scanTypeMeta,
        scanType.isAcceptableOrUnknown(data['scan_type']!, _scanTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_scanTypeMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('risk_level')) {
      context.handle(
        _riskLevelMeta,
        riskLevel.isAcceptableOrUnknown(data['risk_level']!, _riskLevelMeta),
      );
    } else if (isInserting) {
      context.missing(_riskLevelMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('apps_scanned')) {
      context.handle(
        _appsScannedMeta,
        appsScanned.isAcceptableOrUnknown(
          data['apps_scanned']!,
          _appsScannedMeta,
        ),
      );
    }
    if (data.containsKey('findings_count')) {
      context.handle(
        _findingsCountMeta,
        findingsCount.isAcceptableOrUnknown(
          data['findings_count']!,
          _findingsCountMeta,
        ),
      );
    }
    if (data.containsKey('findings_high')) {
      context.handle(
        _findingsHighMeta,
        findingsHigh.isAcceptableOrUnknown(
          data['findings_high']!,
          _findingsHighMeta,
        ),
      );
    }
    if (data.containsKey('findings_medium')) {
      context.handle(
        _findingsMediumMeta,
        findingsMedium.isAcceptableOrUnknown(
          data['findings_medium']!,
          _findingsMediumMeta,
        ),
      );
    }
    if (data.containsKey('findings_low')) {
      context.handle(
        _findingsLowMeta,
        findingsLow.isAcceptableOrUnknown(
          data['findings_low']!,
          _findingsLowMeta,
        ),
      );
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScanRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScanRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      scanType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scan_type'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      riskLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}risk_level'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      appsScanned: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}apps_scanned'],
      )!,
      findingsCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}findings_count'],
      )!,
      findingsHigh: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}findings_high'],
      )!,
      findingsMedium: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}findings_medium'],
      )!,
      findingsLow: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}findings_low'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
    );
  }

  @override
  $ScanRecordsTable createAlias(String alias) {
    return $ScanRecordsTable(attachedDatabase, alias);
  }
}

class ScanRecord extends DataClass implements Insertable<ScanRecord> {
  final int id;
  final String scanType;
  final int score;
  final String riskLevel;
  final int createdAt;
  final int durationMs;
  final int appsScanned;
  final int findingsCount;
  final int findingsHigh;
  final int findingsMedium;
  final int findingsLow;
  final String summary;
  const ScanRecord({
    required this.id,
    required this.scanType,
    required this.score,
    required this.riskLevel,
    required this.createdAt,
    required this.durationMs,
    required this.appsScanned,
    required this.findingsCount,
    required this.findingsHigh,
    required this.findingsMedium,
    required this.findingsLow,
    required this.summary,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['scan_type'] = Variable<String>(scanType);
    map['score'] = Variable<int>(score);
    map['risk_level'] = Variable<String>(riskLevel);
    map['created_at'] = Variable<int>(createdAt);
    map['duration_ms'] = Variable<int>(durationMs);
    map['apps_scanned'] = Variable<int>(appsScanned);
    map['findings_count'] = Variable<int>(findingsCount);
    map['findings_high'] = Variable<int>(findingsHigh);
    map['findings_medium'] = Variable<int>(findingsMedium);
    map['findings_low'] = Variable<int>(findingsLow);
    map['summary'] = Variable<String>(summary);
    return map;
  }

  ScanRecordsCompanion toCompanion(bool nullToAbsent) {
    return ScanRecordsCompanion(
      id: Value(id),
      scanType: Value(scanType),
      score: Value(score),
      riskLevel: Value(riskLevel),
      createdAt: Value(createdAt),
      durationMs: Value(durationMs),
      appsScanned: Value(appsScanned),
      findingsCount: Value(findingsCount),
      findingsHigh: Value(findingsHigh),
      findingsMedium: Value(findingsMedium),
      findingsLow: Value(findingsLow),
      summary: Value(summary),
    );
  }

  factory ScanRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScanRecord(
      id: serializer.fromJson<int>(json['id']),
      scanType: serializer.fromJson<String>(json['scanType']),
      score: serializer.fromJson<int>(json['score']),
      riskLevel: serializer.fromJson<String>(json['riskLevel']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      appsScanned: serializer.fromJson<int>(json['appsScanned']),
      findingsCount: serializer.fromJson<int>(json['findingsCount']),
      findingsHigh: serializer.fromJson<int>(json['findingsHigh']),
      findingsMedium: serializer.fromJson<int>(json['findingsMedium']),
      findingsLow: serializer.fromJson<int>(json['findingsLow']),
      summary: serializer.fromJson<String>(json['summary']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'scanType': serializer.toJson<String>(scanType),
      'score': serializer.toJson<int>(score),
      'riskLevel': serializer.toJson<String>(riskLevel),
      'createdAt': serializer.toJson<int>(createdAt),
      'durationMs': serializer.toJson<int>(durationMs),
      'appsScanned': serializer.toJson<int>(appsScanned),
      'findingsCount': serializer.toJson<int>(findingsCount),
      'findingsHigh': serializer.toJson<int>(findingsHigh),
      'findingsMedium': serializer.toJson<int>(findingsMedium),
      'findingsLow': serializer.toJson<int>(findingsLow),
      'summary': serializer.toJson<String>(summary),
    };
  }

  ScanRecord copyWith({
    int? id,
    String? scanType,
    int? score,
    String? riskLevel,
    int? createdAt,
    int? durationMs,
    int? appsScanned,
    int? findingsCount,
    int? findingsHigh,
    int? findingsMedium,
    int? findingsLow,
    String? summary,
  }) => ScanRecord(
    id: id ?? this.id,
    scanType: scanType ?? this.scanType,
    score: score ?? this.score,
    riskLevel: riskLevel ?? this.riskLevel,
    createdAt: createdAt ?? this.createdAt,
    durationMs: durationMs ?? this.durationMs,
    appsScanned: appsScanned ?? this.appsScanned,
    findingsCount: findingsCount ?? this.findingsCount,
    findingsHigh: findingsHigh ?? this.findingsHigh,
    findingsMedium: findingsMedium ?? this.findingsMedium,
    findingsLow: findingsLow ?? this.findingsLow,
    summary: summary ?? this.summary,
  );
  ScanRecord copyWithCompanion(ScanRecordsCompanion data) {
    return ScanRecord(
      id: data.id.present ? data.id.value : this.id,
      scanType: data.scanType.present ? data.scanType.value : this.scanType,
      score: data.score.present ? data.score.value : this.score,
      riskLevel: data.riskLevel.present ? data.riskLevel.value : this.riskLevel,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      appsScanned: data.appsScanned.present
          ? data.appsScanned.value
          : this.appsScanned,
      findingsCount: data.findingsCount.present
          ? data.findingsCount.value
          : this.findingsCount,
      findingsHigh: data.findingsHigh.present
          ? data.findingsHigh.value
          : this.findingsHigh,
      findingsMedium: data.findingsMedium.present
          ? data.findingsMedium.value
          : this.findingsMedium,
      findingsLow: data.findingsLow.present
          ? data.findingsLow.value
          : this.findingsLow,
      summary: data.summary.present ? data.summary.value : this.summary,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScanRecord(')
          ..write('id: $id, ')
          ..write('scanType: $scanType, ')
          ..write('score: $score, ')
          ..write('riskLevel: $riskLevel, ')
          ..write('createdAt: $createdAt, ')
          ..write('durationMs: $durationMs, ')
          ..write('appsScanned: $appsScanned, ')
          ..write('findingsCount: $findingsCount, ')
          ..write('findingsHigh: $findingsHigh, ')
          ..write('findingsMedium: $findingsMedium, ')
          ..write('findingsLow: $findingsLow, ')
          ..write('summary: $summary')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scanType,
    score,
    riskLevel,
    createdAt,
    durationMs,
    appsScanned,
    findingsCount,
    findingsHigh,
    findingsMedium,
    findingsLow,
    summary,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScanRecord &&
          other.id == this.id &&
          other.scanType == this.scanType &&
          other.score == this.score &&
          other.riskLevel == this.riskLevel &&
          other.createdAt == this.createdAt &&
          other.durationMs == this.durationMs &&
          other.appsScanned == this.appsScanned &&
          other.findingsCount == this.findingsCount &&
          other.findingsHigh == this.findingsHigh &&
          other.findingsMedium == this.findingsMedium &&
          other.findingsLow == this.findingsLow &&
          other.summary == this.summary);
}

class ScanRecordsCompanion extends UpdateCompanion<ScanRecord> {
  final Value<int> id;
  final Value<String> scanType;
  final Value<int> score;
  final Value<String> riskLevel;
  final Value<int> createdAt;
  final Value<int> durationMs;
  final Value<int> appsScanned;
  final Value<int> findingsCount;
  final Value<int> findingsHigh;
  final Value<int> findingsMedium;
  final Value<int> findingsLow;
  final Value<String> summary;
  const ScanRecordsCompanion({
    this.id = const Value.absent(),
    this.scanType = const Value.absent(),
    this.score = const Value.absent(),
    this.riskLevel = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.appsScanned = const Value.absent(),
    this.findingsCount = const Value.absent(),
    this.findingsHigh = const Value.absent(),
    this.findingsMedium = const Value.absent(),
    this.findingsLow = const Value.absent(),
    this.summary = const Value.absent(),
  });
  ScanRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String scanType,
    required int score,
    required String riskLevel,
    required int createdAt,
    this.durationMs = const Value.absent(),
    this.appsScanned = const Value.absent(),
    this.findingsCount = const Value.absent(),
    this.findingsHigh = const Value.absent(),
    this.findingsMedium = const Value.absent(),
    this.findingsLow = const Value.absent(),
    this.summary = const Value.absent(),
  }) : scanType = Value(scanType),
       score = Value(score),
       riskLevel = Value(riskLevel),
       createdAt = Value(createdAt);
  static Insertable<ScanRecord> custom({
    Expression<int>? id,
    Expression<String>? scanType,
    Expression<int>? score,
    Expression<String>? riskLevel,
    Expression<int>? createdAt,
    Expression<int>? durationMs,
    Expression<int>? appsScanned,
    Expression<int>? findingsCount,
    Expression<int>? findingsHigh,
    Expression<int>? findingsMedium,
    Expression<int>? findingsLow,
    Expression<String>? summary,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scanType != null) 'scan_type': scanType,
      if (score != null) 'score': score,
      if (riskLevel != null) 'risk_level': riskLevel,
      if (createdAt != null) 'created_at': createdAt,
      if (durationMs != null) 'duration_ms': durationMs,
      if (appsScanned != null) 'apps_scanned': appsScanned,
      if (findingsCount != null) 'findings_count': findingsCount,
      if (findingsHigh != null) 'findings_high': findingsHigh,
      if (findingsMedium != null) 'findings_medium': findingsMedium,
      if (findingsLow != null) 'findings_low': findingsLow,
      if (summary != null) 'summary': summary,
    });
  }

  ScanRecordsCompanion copyWith({
    Value<int>? id,
    Value<String>? scanType,
    Value<int>? score,
    Value<String>? riskLevel,
    Value<int>? createdAt,
    Value<int>? durationMs,
    Value<int>? appsScanned,
    Value<int>? findingsCount,
    Value<int>? findingsHigh,
    Value<int>? findingsMedium,
    Value<int>? findingsLow,
    Value<String>? summary,
  }) {
    return ScanRecordsCompanion(
      id: id ?? this.id,
      scanType: scanType ?? this.scanType,
      score: score ?? this.score,
      riskLevel: riskLevel ?? this.riskLevel,
      createdAt: createdAt ?? this.createdAt,
      durationMs: durationMs ?? this.durationMs,
      appsScanned: appsScanned ?? this.appsScanned,
      findingsCount: findingsCount ?? this.findingsCount,
      findingsHigh: findingsHigh ?? this.findingsHigh,
      findingsMedium: findingsMedium ?? this.findingsMedium,
      findingsLow: findingsLow ?? this.findingsLow,
      summary: summary ?? this.summary,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (scanType.present) {
      map['scan_type'] = Variable<String>(scanType.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (riskLevel.present) {
      map['risk_level'] = Variable<String>(riskLevel.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (appsScanned.present) {
      map['apps_scanned'] = Variable<int>(appsScanned.value);
    }
    if (findingsCount.present) {
      map['findings_count'] = Variable<int>(findingsCount.value);
    }
    if (findingsHigh.present) {
      map['findings_high'] = Variable<int>(findingsHigh.value);
    }
    if (findingsMedium.present) {
      map['findings_medium'] = Variable<int>(findingsMedium.value);
    }
    if (findingsLow.present) {
      map['findings_low'] = Variable<int>(findingsLow.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScanRecordsCompanion(')
          ..write('id: $id, ')
          ..write('scanType: $scanType, ')
          ..write('score: $score, ')
          ..write('riskLevel: $riskLevel, ')
          ..write('createdAt: $createdAt, ')
          ..write('durationMs: $durationMs, ')
          ..write('appsScanned: $appsScanned, ')
          ..write('findingsCount: $findingsCount, ')
          ..write('findingsHigh: $findingsHigh, ')
          ..write('findingsMedium: $findingsMedium, ')
          ..write('findingsLow: $findingsLow, ')
          ..write('summary: $summary')
          ..write(')'))
        .toString();
  }
}

class $AppSnapshotsTable extends AppSnapshots
    with TableInfo<$AppSnapshotsTable, AppSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _scanIdMeta = const VerificationMeta('scanId');
  @override
  late final GeneratedColumn<int> scanId = GeneratedColumn<int>(
    'scan_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packageNameMeta = const VerificationMeta(
    'packageName',
  );
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
    'package_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appNameMeta = const VerificationMeta(
    'appName',
  );
  @override
  late final GeneratedColumn<String> appName = GeneratedColumn<String>(
    'app_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _riskLevelMeta = const VerificationMeta(
    'riskLevel',
  );
  @override
  late final GeneratedColumn<String> riskLevel = GeneratedColumn<String>(
    'risk_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _riskScoreMeta = const VerificationMeta(
    'riskScore',
  );
  @override
  late final GeneratedColumn<int> riskScore = GeneratedColumn<int>(
    'risk_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _permissionsSensitiveMeta =
      const VerificationMeta('permissionsSensitive');
  @override
  late final GeneratedColumn<int> permissionsSensitive = GeneratedColumn<int>(
    'permissions_sensitive',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _elevatedPermissionsMeta =
      const VerificationMeta('elevatedPermissions');
  @override
  late final GeneratedColumn<int> elevatedPermissions = GeneratedColumn<int>(
    'elevated_permissions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sideloadedMeta = const VerificationMeta(
    'sideloaded',
  );
  @override
  late final GeneratedColumn<bool> sideloaded = GeneratedColumn<bool>(
    'sideloaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sideloaded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _systemAppMeta = const VerificationMeta(
    'systemApp',
  );
  @override
  late final GeneratedColumn<bool> systemApp = GeneratedColumn<bool>(
    'system_app',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("system_app" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reasonsMeta = const VerificationMeta(
    'reasons',
  );
  @override
  late final GeneratedColumn<String> reasons = GeneratedColumn<String>(
    'reasons',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _permissionsMeta = const VerificationMeta(
    'permissions',
  );
  @override
  late final GeneratedColumn<String> permissions = GeneratedColumn<String>(
    'permissions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scanId,
    packageName,
    appName,
    riskLevel,
    riskScore,
    permissionsSensitive,
    elevatedPermissions,
    sideloaded,
    systemApp,
    reasons,
    permissions,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSnapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('scan_id')) {
      context.handle(
        _scanIdMeta,
        scanId.isAcceptableOrUnknown(data['scan_id']!, _scanIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scanIdMeta);
    }
    if (data.containsKey('package_name')) {
      context.handle(
        _packageNameMeta,
        packageName.isAcceptableOrUnknown(
          data['package_name']!,
          _packageNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packageNameMeta);
    }
    if (data.containsKey('app_name')) {
      context.handle(
        _appNameMeta,
        appName.isAcceptableOrUnknown(data['app_name']!, _appNameMeta),
      );
    } else if (isInserting) {
      context.missing(_appNameMeta);
    }
    if (data.containsKey('risk_level')) {
      context.handle(
        _riskLevelMeta,
        riskLevel.isAcceptableOrUnknown(data['risk_level']!, _riskLevelMeta),
      );
    } else if (isInserting) {
      context.missing(_riskLevelMeta);
    }
    if (data.containsKey('risk_score')) {
      context.handle(
        _riskScoreMeta,
        riskScore.isAcceptableOrUnknown(data['risk_score']!, _riskScoreMeta),
      );
    } else if (isInserting) {
      context.missing(_riskScoreMeta);
    }
    if (data.containsKey('permissions_sensitive')) {
      context.handle(
        _permissionsSensitiveMeta,
        permissionsSensitive.isAcceptableOrUnknown(
          data['permissions_sensitive']!,
          _permissionsSensitiveMeta,
        ),
      );
    }
    if (data.containsKey('elevated_permissions')) {
      context.handle(
        _elevatedPermissionsMeta,
        elevatedPermissions.isAcceptableOrUnknown(
          data['elevated_permissions']!,
          _elevatedPermissionsMeta,
        ),
      );
    }
    if (data.containsKey('sideloaded')) {
      context.handle(
        _sideloadedMeta,
        sideloaded.isAcceptableOrUnknown(data['sideloaded']!, _sideloadedMeta),
      );
    }
    if (data.containsKey('system_app')) {
      context.handle(
        _systemAppMeta,
        systemApp.isAcceptableOrUnknown(data['system_app']!, _systemAppMeta),
      );
    }
    if (data.containsKey('reasons')) {
      context.handle(
        _reasonsMeta,
        reasons.isAcceptableOrUnknown(data['reasons']!, _reasonsMeta),
      );
    }
    if (data.containsKey('permissions')) {
      context.handle(
        _permissionsMeta,
        permissions.isAcceptableOrUnknown(
          data['permissions']!,
          _permissionsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSnapshot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      scanId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scan_id'],
      )!,
      packageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_name'],
      )!,
      appName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_name'],
      )!,
      riskLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}risk_level'],
      )!,
      riskScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}risk_score'],
      )!,
      permissionsSensitive: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}permissions_sensitive'],
      )!,
      elevatedPermissions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elevated_permissions'],
      )!,
      sideloaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sideloaded'],
      )!,
      systemApp: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}system_app'],
      )!,
      reasons: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reasons'],
      )!,
      permissions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}permissions'],
      )!,
    );
  }

  @override
  $AppSnapshotsTable createAlias(String alias) {
    return $AppSnapshotsTable(attachedDatabase, alias);
  }
}

class AppSnapshot extends DataClass implements Insertable<AppSnapshot> {
  final int id;
  final int scanId;
  final String packageName;
  final String appName;
  final String riskLevel;
  final int riskScore;
  final int permissionsSensitive;
  final int elevatedPermissions;
  final bool sideloaded;
  final bool systemApp;
  final String reasons;

  /// Newline-joined sensitive + elevated permission names at scan time, so
  /// two scans can be diffed ("this app now asks for contacts").
  final String permissions;
  const AppSnapshot({
    required this.id,
    required this.scanId,
    required this.packageName,
    required this.appName,
    required this.riskLevel,
    required this.riskScore,
    required this.permissionsSensitive,
    required this.elevatedPermissions,
    required this.sideloaded,
    required this.systemApp,
    required this.reasons,
    required this.permissions,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['scan_id'] = Variable<int>(scanId);
    map['package_name'] = Variable<String>(packageName);
    map['app_name'] = Variable<String>(appName);
    map['risk_level'] = Variable<String>(riskLevel);
    map['risk_score'] = Variable<int>(riskScore);
    map['permissions_sensitive'] = Variable<int>(permissionsSensitive);
    map['elevated_permissions'] = Variable<int>(elevatedPermissions);
    map['sideloaded'] = Variable<bool>(sideloaded);
    map['system_app'] = Variable<bool>(systemApp);
    map['reasons'] = Variable<String>(reasons);
    map['permissions'] = Variable<String>(permissions);
    return map;
  }

  AppSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return AppSnapshotsCompanion(
      id: Value(id),
      scanId: Value(scanId),
      packageName: Value(packageName),
      appName: Value(appName),
      riskLevel: Value(riskLevel),
      riskScore: Value(riskScore),
      permissionsSensitive: Value(permissionsSensitive),
      elevatedPermissions: Value(elevatedPermissions),
      sideloaded: Value(sideloaded),
      systemApp: Value(systemApp),
      reasons: Value(reasons),
      permissions: Value(permissions),
    );
  }

  factory AppSnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSnapshot(
      id: serializer.fromJson<int>(json['id']),
      scanId: serializer.fromJson<int>(json['scanId']),
      packageName: serializer.fromJson<String>(json['packageName']),
      appName: serializer.fromJson<String>(json['appName']),
      riskLevel: serializer.fromJson<String>(json['riskLevel']),
      riskScore: serializer.fromJson<int>(json['riskScore']),
      permissionsSensitive: serializer.fromJson<int>(
        json['permissionsSensitive'],
      ),
      elevatedPermissions: serializer.fromJson<int>(
        json['elevatedPermissions'],
      ),
      sideloaded: serializer.fromJson<bool>(json['sideloaded']),
      systemApp: serializer.fromJson<bool>(json['systemApp']),
      reasons: serializer.fromJson<String>(json['reasons']),
      permissions: serializer.fromJson<String>(json['permissions']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'scanId': serializer.toJson<int>(scanId),
      'packageName': serializer.toJson<String>(packageName),
      'appName': serializer.toJson<String>(appName),
      'riskLevel': serializer.toJson<String>(riskLevel),
      'riskScore': serializer.toJson<int>(riskScore),
      'permissionsSensitive': serializer.toJson<int>(permissionsSensitive),
      'elevatedPermissions': serializer.toJson<int>(elevatedPermissions),
      'sideloaded': serializer.toJson<bool>(sideloaded),
      'systemApp': serializer.toJson<bool>(systemApp),
      'reasons': serializer.toJson<String>(reasons),
      'permissions': serializer.toJson<String>(permissions),
    };
  }

  AppSnapshot copyWith({
    int? id,
    int? scanId,
    String? packageName,
    String? appName,
    String? riskLevel,
    int? riskScore,
    int? permissionsSensitive,
    int? elevatedPermissions,
    bool? sideloaded,
    bool? systemApp,
    String? reasons,
    String? permissions,
  }) => AppSnapshot(
    id: id ?? this.id,
    scanId: scanId ?? this.scanId,
    packageName: packageName ?? this.packageName,
    appName: appName ?? this.appName,
    riskLevel: riskLevel ?? this.riskLevel,
    riskScore: riskScore ?? this.riskScore,
    permissionsSensitive: permissionsSensitive ?? this.permissionsSensitive,
    elevatedPermissions: elevatedPermissions ?? this.elevatedPermissions,
    sideloaded: sideloaded ?? this.sideloaded,
    systemApp: systemApp ?? this.systemApp,
    reasons: reasons ?? this.reasons,
    permissions: permissions ?? this.permissions,
  );
  AppSnapshot copyWithCompanion(AppSnapshotsCompanion data) {
    return AppSnapshot(
      id: data.id.present ? data.id.value : this.id,
      scanId: data.scanId.present ? data.scanId.value : this.scanId,
      packageName: data.packageName.present
          ? data.packageName.value
          : this.packageName,
      appName: data.appName.present ? data.appName.value : this.appName,
      riskLevel: data.riskLevel.present ? data.riskLevel.value : this.riskLevel,
      riskScore: data.riskScore.present ? data.riskScore.value : this.riskScore,
      permissionsSensitive: data.permissionsSensitive.present
          ? data.permissionsSensitive.value
          : this.permissionsSensitive,
      elevatedPermissions: data.elevatedPermissions.present
          ? data.elevatedPermissions.value
          : this.elevatedPermissions,
      sideloaded: data.sideloaded.present
          ? data.sideloaded.value
          : this.sideloaded,
      systemApp: data.systemApp.present ? data.systemApp.value : this.systemApp,
      reasons: data.reasons.present ? data.reasons.value : this.reasons,
      permissions: data.permissions.present
          ? data.permissions.value
          : this.permissions,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSnapshot(')
          ..write('id: $id, ')
          ..write('scanId: $scanId, ')
          ..write('packageName: $packageName, ')
          ..write('appName: $appName, ')
          ..write('riskLevel: $riskLevel, ')
          ..write('riskScore: $riskScore, ')
          ..write('permissionsSensitive: $permissionsSensitive, ')
          ..write('elevatedPermissions: $elevatedPermissions, ')
          ..write('sideloaded: $sideloaded, ')
          ..write('systemApp: $systemApp, ')
          ..write('reasons: $reasons, ')
          ..write('permissions: $permissions')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scanId,
    packageName,
    appName,
    riskLevel,
    riskScore,
    permissionsSensitive,
    elevatedPermissions,
    sideloaded,
    systemApp,
    reasons,
    permissions,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSnapshot &&
          other.id == this.id &&
          other.scanId == this.scanId &&
          other.packageName == this.packageName &&
          other.appName == this.appName &&
          other.riskLevel == this.riskLevel &&
          other.riskScore == this.riskScore &&
          other.permissionsSensitive == this.permissionsSensitive &&
          other.elevatedPermissions == this.elevatedPermissions &&
          other.sideloaded == this.sideloaded &&
          other.systemApp == this.systemApp &&
          other.reasons == this.reasons &&
          other.permissions == this.permissions);
}

class AppSnapshotsCompanion extends UpdateCompanion<AppSnapshot> {
  final Value<int> id;
  final Value<int> scanId;
  final Value<String> packageName;
  final Value<String> appName;
  final Value<String> riskLevel;
  final Value<int> riskScore;
  final Value<int> permissionsSensitive;
  final Value<int> elevatedPermissions;
  final Value<bool> sideloaded;
  final Value<bool> systemApp;
  final Value<String> reasons;
  final Value<String> permissions;
  const AppSnapshotsCompanion({
    this.id = const Value.absent(),
    this.scanId = const Value.absent(),
    this.packageName = const Value.absent(),
    this.appName = const Value.absent(),
    this.riskLevel = const Value.absent(),
    this.riskScore = const Value.absent(),
    this.permissionsSensitive = const Value.absent(),
    this.elevatedPermissions = const Value.absent(),
    this.sideloaded = const Value.absent(),
    this.systemApp = const Value.absent(),
    this.reasons = const Value.absent(),
    this.permissions = const Value.absent(),
  });
  AppSnapshotsCompanion.insert({
    this.id = const Value.absent(),
    required int scanId,
    required String packageName,
    required String appName,
    required String riskLevel,
    required int riskScore,
    this.permissionsSensitive = const Value.absent(),
    this.elevatedPermissions = const Value.absent(),
    this.sideloaded = const Value.absent(),
    this.systemApp = const Value.absent(),
    this.reasons = const Value.absent(),
    this.permissions = const Value.absent(),
  }) : scanId = Value(scanId),
       packageName = Value(packageName),
       appName = Value(appName),
       riskLevel = Value(riskLevel),
       riskScore = Value(riskScore);
  static Insertable<AppSnapshot> custom({
    Expression<int>? id,
    Expression<int>? scanId,
    Expression<String>? packageName,
    Expression<String>? appName,
    Expression<String>? riskLevel,
    Expression<int>? riskScore,
    Expression<int>? permissionsSensitive,
    Expression<int>? elevatedPermissions,
    Expression<bool>? sideloaded,
    Expression<bool>? systemApp,
    Expression<String>? reasons,
    Expression<String>? permissions,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scanId != null) 'scan_id': scanId,
      if (packageName != null) 'package_name': packageName,
      if (appName != null) 'app_name': appName,
      if (riskLevel != null) 'risk_level': riskLevel,
      if (riskScore != null) 'risk_score': riskScore,
      if (permissionsSensitive != null)
        'permissions_sensitive': permissionsSensitive,
      if (elevatedPermissions != null)
        'elevated_permissions': elevatedPermissions,
      if (sideloaded != null) 'sideloaded': sideloaded,
      if (systemApp != null) 'system_app': systemApp,
      if (reasons != null) 'reasons': reasons,
      if (permissions != null) 'permissions': permissions,
    });
  }

  AppSnapshotsCompanion copyWith({
    Value<int>? id,
    Value<int>? scanId,
    Value<String>? packageName,
    Value<String>? appName,
    Value<String>? riskLevel,
    Value<int>? riskScore,
    Value<int>? permissionsSensitive,
    Value<int>? elevatedPermissions,
    Value<bool>? sideloaded,
    Value<bool>? systemApp,
    Value<String>? reasons,
    Value<String>? permissions,
  }) {
    return AppSnapshotsCompanion(
      id: id ?? this.id,
      scanId: scanId ?? this.scanId,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      riskLevel: riskLevel ?? this.riskLevel,
      riskScore: riskScore ?? this.riskScore,
      permissionsSensitive: permissionsSensitive ?? this.permissionsSensitive,
      elevatedPermissions: elevatedPermissions ?? this.elevatedPermissions,
      sideloaded: sideloaded ?? this.sideloaded,
      systemApp: systemApp ?? this.systemApp,
      reasons: reasons ?? this.reasons,
      permissions: permissions ?? this.permissions,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (scanId.present) {
      map['scan_id'] = Variable<int>(scanId.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (appName.present) {
      map['app_name'] = Variable<String>(appName.value);
    }
    if (riskLevel.present) {
      map['risk_level'] = Variable<String>(riskLevel.value);
    }
    if (riskScore.present) {
      map['risk_score'] = Variable<int>(riskScore.value);
    }
    if (permissionsSensitive.present) {
      map['permissions_sensitive'] = Variable<int>(permissionsSensitive.value);
    }
    if (elevatedPermissions.present) {
      map['elevated_permissions'] = Variable<int>(elevatedPermissions.value);
    }
    if (sideloaded.present) {
      map['sideloaded'] = Variable<bool>(sideloaded.value);
    }
    if (systemApp.present) {
      map['system_app'] = Variable<bool>(systemApp.value);
    }
    if (reasons.present) {
      map['reasons'] = Variable<String>(reasons.value);
    }
    if (permissions.present) {
      map['permissions'] = Variable<String>(permissions.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('scanId: $scanId, ')
          ..write('packageName: $packageName, ')
          ..write('appName: $appName, ')
          ..write('riskLevel: $riskLevel, ')
          ..write('riskScore: $riskScore, ')
          ..write('permissionsSensitive: $permissionsSensitive, ')
          ..write('elevatedPermissions: $elevatedPermissions, ')
          ..write('sideloaded: $sideloaded, ')
          ..write('systemApp: $systemApp, ')
          ..write('reasons: $reasons, ')
          ..write('permissions: $permissions')
          ..write(')'))
        .toString();
  }
}

class $FindingRecordsTable extends FindingRecords
    with TableInfo<$FindingRecordsTable, FindingRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FindingRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _scanIdMeta = const VerificationMeta('scanId');
  @override
  late final GeneratedColumn<int> scanId = GeneratedColumn<int>(
    'scan_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailMeta = const VerificationMeta('detail');
  @override
  late final GeneratedColumn<String> detail = GeneratedColumn<String>(
    'detail',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
    'severity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scanId,
    category,
    title,
    detail,
    severity,
    subject,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'finding_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<FindingRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('scan_id')) {
      context.handle(
        _scanIdMeta,
        scanId.isAcceptableOrUnknown(data['scan_id']!, _scanIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scanIdMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('detail')) {
      context.handle(
        _detailMeta,
        detail.isAcceptableOrUnknown(data['detail']!, _detailMeta),
      );
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FindingRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FindingRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      scanId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scan_id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      detail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail'],
      )!,
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}severity'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
    );
  }

  @override
  $FindingRecordsTable createAlias(String alias) {
    return $FindingRecordsTable(attachedDatabase, alias);
  }
}

class FindingRecord extends DataClass implements Insertable<FindingRecord> {
  final int id;
  final int scanId;
  final String category;
  final String title;
  final String detail;
  final String severity;
  final String subject;
  const FindingRecord({
    required this.id,
    required this.scanId,
    required this.category,
    required this.title,
    required this.detail,
    required this.severity,
    required this.subject,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['scan_id'] = Variable<int>(scanId);
    map['category'] = Variable<String>(category);
    map['title'] = Variable<String>(title);
    map['detail'] = Variable<String>(detail);
    map['severity'] = Variable<String>(severity);
    map['subject'] = Variable<String>(subject);
    return map;
  }

  FindingRecordsCompanion toCompanion(bool nullToAbsent) {
    return FindingRecordsCompanion(
      id: Value(id),
      scanId: Value(scanId),
      category: Value(category),
      title: Value(title),
      detail: Value(detail),
      severity: Value(severity),
      subject: Value(subject),
    );
  }

  factory FindingRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FindingRecord(
      id: serializer.fromJson<int>(json['id']),
      scanId: serializer.fromJson<int>(json['scanId']),
      category: serializer.fromJson<String>(json['category']),
      title: serializer.fromJson<String>(json['title']),
      detail: serializer.fromJson<String>(json['detail']),
      severity: serializer.fromJson<String>(json['severity']),
      subject: serializer.fromJson<String>(json['subject']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'scanId': serializer.toJson<int>(scanId),
      'category': serializer.toJson<String>(category),
      'title': serializer.toJson<String>(title),
      'detail': serializer.toJson<String>(detail),
      'severity': serializer.toJson<String>(severity),
      'subject': serializer.toJson<String>(subject),
    };
  }

  FindingRecord copyWith({
    int? id,
    int? scanId,
    String? category,
    String? title,
    String? detail,
    String? severity,
    String? subject,
  }) => FindingRecord(
    id: id ?? this.id,
    scanId: scanId ?? this.scanId,
    category: category ?? this.category,
    title: title ?? this.title,
    detail: detail ?? this.detail,
    severity: severity ?? this.severity,
    subject: subject ?? this.subject,
  );
  FindingRecord copyWithCompanion(FindingRecordsCompanion data) {
    return FindingRecord(
      id: data.id.present ? data.id.value : this.id,
      scanId: data.scanId.present ? data.scanId.value : this.scanId,
      category: data.category.present ? data.category.value : this.category,
      title: data.title.present ? data.title.value : this.title,
      detail: data.detail.present ? data.detail.value : this.detail,
      severity: data.severity.present ? data.severity.value : this.severity,
      subject: data.subject.present ? data.subject.value : this.subject,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FindingRecord(')
          ..write('id: $id, ')
          ..write('scanId: $scanId, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('detail: $detail, ')
          ..write('severity: $severity, ')
          ..write('subject: $subject')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, scanId, category, title, detail, severity, subject);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FindingRecord &&
          other.id == this.id &&
          other.scanId == this.scanId &&
          other.category == this.category &&
          other.title == this.title &&
          other.detail == this.detail &&
          other.severity == this.severity &&
          other.subject == this.subject);
}

class FindingRecordsCompanion extends UpdateCompanion<FindingRecord> {
  final Value<int> id;
  final Value<int> scanId;
  final Value<String> category;
  final Value<String> title;
  final Value<String> detail;
  final Value<String> severity;
  final Value<String> subject;
  const FindingRecordsCompanion({
    this.id = const Value.absent(),
    this.scanId = const Value.absent(),
    this.category = const Value.absent(),
    this.title = const Value.absent(),
    this.detail = const Value.absent(),
    this.severity = const Value.absent(),
    this.subject = const Value.absent(),
  });
  FindingRecordsCompanion.insert({
    this.id = const Value.absent(),
    required int scanId,
    required String category,
    required String title,
    this.detail = const Value.absent(),
    required String severity,
    this.subject = const Value.absent(),
  }) : scanId = Value(scanId),
       category = Value(category),
       title = Value(title),
       severity = Value(severity);
  static Insertable<FindingRecord> custom({
    Expression<int>? id,
    Expression<int>? scanId,
    Expression<String>? category,
    Expression<String>? title,
    Expression<String>? detail,
    Expression<String>? severity,
    Expression<String>? subject,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scanId != null) 'scan_id': scanId,
      if (category != null) 'category': category,
      if (title != null) 'title': title,
      if (detail != null) 'detail': detail,
      if (severity != null) 'severity': severity,
      if (subject != null) 'subject': subject,
    });
  }

  FindingRecordsCompanion copyWith({
    Value<int>? id,
    Value<int>? scanId,
    Value<String>? category,
    Value<String>? title,
    Value<String>? detail,
    Value<String>? severity,
    Value<String>? subject,
  }) {
    return FindingRecordsCompanion(
      id: id ?? this.id,
      scanId: scanId ?? this.scanId,
      category: category ?? this.category,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      severity: severity ?? this.severity,
      subject: subject ?? this.subject,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (scanId.present) {
      map['scan_id'] = Variable<int>(scanId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (detail.present) {
      map['detail'] = Variable<String>(detail.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FindingRecordsCompanion(')
          ..write('id: $id, ')
          ..write('scanId: $scanId, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('detail: $detail, ')
          ..write('severity: $severity, ')
          ..write('subject: $subject')
          ..write(')'))
        .toString();
  }
}

class $IgnoreRecordsTable extends IgnoreRecords
    with TableInfo<$IgnoreRecordsTable, IgnoreRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IgnoreRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetMeta = const VerificationMeta('target');
  @override
  late final GeneratedColumn<String> target = GeneratedColumn<String>(
    'target',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, kind, target, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ignore_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<IgnoreRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('target')) {
      context.handle(
        _targetMeta,
        target.isAcceptableOrUnknown(data['target']!, _targetMeta),
      );
    } else if (isInserting) {
      context.missing(_targetMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IgnoreRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IgnoreRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      target: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $IgnoreRecordsTable createAlias(String alias) {
    return $IgnoreRecordsTable(attachedDatabase, alias);
  }
}

class IgnoreRecord extends DataClass implements Insertable<IgnoreRecord> {
  final int id;
  final String kind;
  final String target;
  final int createdAt;
  const IgnoreRecord({
    required this.id,
    required this.kind,
    required this.target,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<String>(kind);
    map['target'] = Variable<String>(target);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  IgnoreRecordsCompanion toCompanion(bool nullToAbsent) {
    return IgnoreRecordsCompanion(
      id: Value(id),
      kind: Value(kind),
      target: Value(target),
      createdAt: Value(createdAt),
    );
  }

  factory IgnoreRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IgnoreRecord(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      target: serializer.fromJson<String>(json['target']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(kind),
      'target': serializer.toJson<String>(target),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  IgnoreRecord copyWith({
    int? id,
    String? kind,
    String? target,
    int? createdAt,
  }) => IgnoreRecord(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    target: target ?? this.target,
    createdAt: createdAt ?? this.createdAt,
  );
  IgnoreRecord copyWithCompanion(IgnoreRecordsCompanion data) {
    return IgnoreRecord(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      target: data.target.present ? data.target.value : this.target,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IgnoreRecord(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('target: $target, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, kind, target, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IgnoreRecord &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.target == this.target &&
          other.createdAt == this.createdAt);
}

class IgnoreRecordsCompanion extends UpdateCompanion<IgnoreRecord> {
  final Value<int> id;
  final Value<String> kind;
  final Value<String> target;
  final Value<int> createdAt;
  const IgnoreRecordsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.target = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  IgnoreRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String kind,
    required String target,
    required int createdAt,
  }) : kind = Value(kind),
       target = Value(target),
       createdAt = Value(createdAt);
  static Insertable<IgnoreRecord> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<String>? target,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (target != null) 'target': target,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  IgnoreRecordsCompanion copyWith({
    Value<int>? id,
    Value<String>? kind,
    Value<String>? target,
    Value<int>? createdAt,
  }) {
    return IgnoreRecordsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      target: target ?? this.target,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (target.present) {
      map['target'] = Variable<String>(target.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IgnoreRecordsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('target: $target, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SettingRecordsTable extends SettingRecords
    with TableInfo<$SettingRecordsTable, SettingRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'setting_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRecord(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingRecordsTable createAlias(String alias) {
    return $SettingRecordsTable(attachedDatabase, alias);
  }
}

class SettingRecord extends DataClass implements Insertable<SettingRecord> {
  final String key;
  final String value;
  const SettingRecord({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingRecordsCompanion toCompanion(bool nullToAbsent) {
    return SettingRecordsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRecord(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRecord copyWith({String? key, String? value}) =>
      SettingRecord(key: key ?? this.key, value: value ?? this.value);
  SettingRecord copyWithCompanion(SettingRecordsCompanion data) {
    return SettingRecord(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRecord(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRecord &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingRecordsCompanion extends UpdateCompanion<SettingRecord> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingRecordsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingRecordsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRecord> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingRecordsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingRecordsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingRecordsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ScanRecordsTable scanRecords = $ScanRecordsTable(this);
  late final $AppSnapshotsTable appSnapshots = $AppSnapshotsTable(this);
  late final $FindingRecordsTable findingRecords = $FindingRecordsTable(this);
  late final $IgnoreRecordsTable ignoreRecords = $IgnoreRecordsTable(this);
  late final $SettingRecordsTable settingRecords = $SettingRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    scanRecords,
    appSnapshots,
    findingRecords,
    ignoreRecords,
    settingRecords,
  ];
}

typedef $$ScanRecordsTableCreateCompanionBuilder =
    ScanRecordsCompanion Function({
      Value<int> id,
      required String scanType,
      required int score,
      required String riskLevel,
      required int createdAt,
      Value<int> durationMs,
      Value<int> appsScanned,
      Value<int> findingsCount,
      Value<int> findingsHigh,
      Value<int> findingsMedium,
      Value<int> findingsLow,
      Value<String> summary,
    });
typedef $$ScanRecordsTableUpdateCompanionBuilder =
    ScanRecordsCompanion Function({
      Value<int> id,
      Value<String> scanType,
      Value<int> score,
      Value<String> riskLevel,
      Value<int> createdAt,
      Value<int> durationMs,
      Value<int> appsScanned,
      Value<int> findingsCount,
      Value<int> findingsHigh,
      Value<int> findingsMedium,
      Value<int> findingsLow,
      Value<String> summary,
    });

class $$ScanRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ScanRecordsTable> {
  $$ScanRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scanType => $composableBuilder(
    column: $table.scanType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get riskLevel => $composableBuilder(
    column: $table.riskLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get appsScanned => $composableBuilder(
    column: $table.appsScanned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get findingsCount => $composableBuilder(
    column: $table.findingsCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get findingsHigh => $composableBuilder(
    column: $table.findingsHigh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get findingsMedium => $composableBuilder(
    column: $table.findingsMedium,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get findingsLow => $composableBuilder(
    column: $table.findingsLow,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ScanRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScanRecordsTable> {
  $$ScanRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scanType => $composableBuilder(
    column: $table.scanType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get riskLevel => $composableBuilder(
    column: $table.riskLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get appsScanned => $composableBuilder(
    column: $table.appsScanned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get findingsCount => $composableBuilder(
    column: $table.findingsCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get findingsHigh => $composableBuilder(
    column: $table.findingsHigh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get findingsMedium => $composableBuilder(
    column: $table.findingsMedium,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get findingsLow => $composableBuilder(
    column: $table.findingsLow,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScanRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScanRecordsTable> {
  $$ScanRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scanType =>
      $composableBuilder(column: $table.scanType, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<String> get riskLevel =>
      $composableBuilder(column: $table.riskLevel, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get appsScanned => $composableBuilder(
    column: $table.appsScanned,
    builder: (column) => column,
  );

  GeneratedColumn<int> get findingsCount => $composableBuilder(
    column: $table.findingsCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get findingsHigh => $composableBuilder(
    column: $table.findingsHigh,
    builder: (column) => column,
  );

  GeneratedColumn<int> get findingsMedium => $composableBuilder(
    column: $table.findingsMedium,
    builder: (column) => column,
  );

  GeneratedColumn<int> get findingsLow => $composableBuilder(
    column: $table.findingsLow,
    builder: (column) => column,
  );

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);
}

class $$ScanRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScanRecordsTable,
          ScanRecord,
          $$ScanRecordsTableFilterComposer,
          $$ScanRecordsTableOrderingComposer,
          $$ScanRecordsTableAnnotationComposer,
          $$ScanRecordsTableCreateCompanionBuilder,
          $$ScanRecordsTableUpdateCompanionBuilder,
          (
            ScanRecord,
            BaseReferences<_$AppDatabase, $ScanRecordsTable, ScanRecord>,
          ),
          ScanRecord,
          PrefetchHooks Function()
        > {
  $$ScanRecordsTableTableManager(_$AppDatabase db, $ScanRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScanRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScanRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScanRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> scanType = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<String> riskLevel = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int> appsScanned = const Value.absent(),
                Value<int> findingsCount = const Value.absent(),
                Value<int> findingsHigh = const Value.absent(),
                Value<int> findingsMedium = const Value.absent(),
                Value<int> findingsLow = const Value.absent(),
                Value<String> summary = const Value.absent(),
              }) => ScanRecordsCompanion(
                id: id,
                scanType: scanType,
                score: score,
                riskLevel: riskLevel,
                createdAt: createdAt,
                durationMs: durationMs,
                appsScanned: appsScanned,
                findingsCount: findingsCount,
                findingsHigh: findingsHigh,
                findingsMedium: findingsMedium,
                findingsLow: findingsLow,
                summary: summary,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String scanType,
                required int score,
                required String riskLevel,
                required int createdAt,
                Value<int> durationMs = const Value.absent(),
                Value<int> appsScanned = const Value.absent(),
                Value<int> findingsCount = const Value.absent(),
                Value<int> findingsHigh = const Value.absent(),
                Value<int> findingsMedium = const Value.absent(),
                Value<int> findingsLow = const Value.absent(),
                Value<String> summary = const Value.absent(),
              }) => ScanRecordsCompanion.insert(
                id: id,
                scanType: scanType,
                score: score,
                riskLevel: riskLevel,
                createdAt: createdAt,
                durationMs: durationMs,
                appsScanned: appsScanned,
                findingsCount: findingsCount,
                findingsHigh: findingsHigh,
                findingsMedium: findingsMedium,
                findingsLow: findingsLow,
                summary: summary,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScanRecordsTable, ScanRecord>(table),
                  BaseReferences<_$AppDatabase, $ScanRecordsTable, ScanRecord>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScanRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScanRecordsTable,
      ScanRecord,
      $$ScanRecordsTableFilterComposer,
      $$ScanRecordsTableOrderingComposer,
      $$ScanRecordsTableAnnotationComposer,
      $$ScanRecordsTableCreateCompanionBuilder,
      $$ScanRecordsTableUpdateCompanionBuilder,
      (
        ScanRecord,
        BaseReferences<_$AppDatabase, $ScanRecordsTable, ScanRecord>,
      ),
      ScanRecord,
      PrefetchHooks Function()
    >;
typedef $$AppSnapshotsTableCreateCompanionBuilder =
    AppSnapshotsCompanion Function({
      Value<int> id,
      required int scanId,
      required String packageName,
      required String appName,
      required String riskLevel,
      required int riskScore,
      Value<int> permissionsSensitive,
      Value<int> elevatedPermissions,
      Value<bool> sideloaded,
      Value<bool> systemApp,
      Value<String> reasons,
      Value<String> permissions,
    });
typedef $$AppSnapshotsTableUpdateCompanionBuilder =
    AppSnapshotsCompanion Function({
      Value<int> id,
      Value<int> scanId,
      Value<String> packageName,
      Value<String> appName,
      Value<String> riskLevel,
      Value<int> riskScore,
      Value<int> permissionsSensitive,
      Value<int> elevatedPermissions,
      Value<bool> sideloaded,
      Value<bool> systemApp,
      Value<String> reasons,
      Value<String> permissions,
    });

class $$AppSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSnapshotsTable> {
  $$AppSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scanId => $composableBuilder(
    column: $table.scanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get riskLevel => $composableBuilder(
    column: $table.riskLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get riskScore => $composableBuilder(
    column: $table.riskScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get permissionsSensitive => $composableBuilder(
    column: $table.permissionsSensitive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elevatedPermissions => $composableBuilder(
    column: $table.elevatedPermissions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sideloaded => $composableBuilder(
    column: $table.sideloaded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get systemApp => $composableBuilder(
    column: $table.systemApp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reasons => $composableBuilder(
    column: $table.reasons,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get permissions => $composableBuilder(
    column: $table.permissions,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSnapshotsTable> {
  $$AppSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scanId => $composableBuilder(
    column: $table.scanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get riskLevel => $composableBuilder(
    column: $table.riskLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get riskScore => $composableBuilder(
    column: $table.riskScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get permissionsSensitive => $composableBuilder(
    column: $table.permissionsSensitive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elevatedPermissions => $composableBuilder(
    column: $table.elevatedPermissions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sideloaded => $composableBuilder(
    column: $table.sideloaded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get systemApp => $composableBuilder(
    column: $table.systemApp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasons => $composableBuilder(
    column: $table.reasons,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get permissions => $composableBuilder(
    column: $table.permissions,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSnapshotsTable> {
  $$AppSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get scanId =>
      $composableBuilder(column: $table.scanId, builder: (column) => column);

  GeneratedColumn<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appName =>
      $composableBuilder(column: $table.appName, builder: (column) => column);

  GeneratedColumn<String> get riskLevel =>
      $composableBuilder(column: $table.riskLevel, builder: (column) => column);

  GeneratedColumn<int> get riskScore =>
      $composableBuilder(column: $table.riskScore, builder: (column) => column);

  GeneratedColumn<int> get permissionsSensitive => $composableBuilder(
    column: $table.permissionsSensitive,
    builder: (column) => column,
  );

  GeneratedColumn<int> get elevatedPermissions => $composableBuilder(
    column: $table.elevatedPermissions,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get sideloaded => $composableBuilder(
    column: $table.sideloaded,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get systemApp =>
      $composableBuilder(column: $table.systemApp, builder: (column) => column);

  GeneratedColumn<String> get reasons =>
      $composableBuilder(column: $table.reasons, builder: (column) => column);

  GeneratedColumn<String> get permissions => $composableBuilder(
    column: $table.permissions,
    builder: (column) => column,
  );
}

class $$AppSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSnapshotsTable,
          AppSnapshot,
          $$AppSnapshotsTableFilterComposer,
          $$AppSnapshotsTableOrderingComposer,
          $$AppSnapshotsTableAnnotationComposer,
          $$AppSnapshotsTableCreateCompanionBuilder,
          $$AppSnapshotsTableUpdateCompanionBuilder,
          (
            AppSnapshot,
            BaseReferences<_$AppDatabase, $AppSnapshotsTable, AppSnapshot>,
          ),
          AppSnapshot,
          PrefetchHooks Function()
        > {
  $$AppSnapshotsTableTableManager(_$AppDatabase db, $AppSnapshotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> scanId = const Value.absent(),
                Value<String> packageName = const Value.absent(),
                Value<String> appName = const Value.absent(),
                Value<String> riskLevel = const Value.absent(),
                Value<int> riskScore = const Value.absent(),
                Value<int> permissionsSensitive = const Value.absent(),
                Value<int> elevatedPermissions = const Value.absent(),
                Value<bool> sideloaded = const Value.absent(),
                Value<bool> systemApp = const Value.absent(),
                Value<String> reasons = const Value.absent(),
                Value<String> permissions = const Value.absent(),
              }) => AppSnapshotsCompanion(
                id: id,
                scanId: scanId,
                packageName: packageName,
                appName: appName,
                riskLevel: riskLevel,
                riskScore: riskScore,
                permissionsSensitive: permissionsSensitive,
                elevatedPermissions: elevatedPermissions,
                sideloaded: sideloaded,
                systemApp: systemApp,
                reasons: reasons,
                permissions: permissions,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int scanId,
                required String packageName,
                required String appName,
                required String riskLevel,
                required int riskScore,
                Value<int> permissionsSensitive = const Value.absent(),
                Value<int> elevatedPermissions = const Value.absent(),
                Value<bool> sideloaded = const Value.absent(),
                Value<bool> systemApp = const Value.absent(),
                Value<String> reasons = const Value.absent(),
                Value<String> permissions = const Value.absent(),
              }) => AppSnapshotsCompanion.insert(
                id: id,
                scanId: scanId,
                packageName: packageName,
                appName: appName,
                riskLevel: riskLevel,
                riskScore: riskScore,
                permissionsSensitive: permissionsSensitive,
                elevatedPermissions: elevatedPermissions,
                sideloaded: sideloaded,
                systemApp: systemApp,
                reasons: reasons,
                permissions: permissions,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSnapshotsTable, AppSnapshot>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AppSnapshotsTable,
                    AppSnapshot
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSnapshotsTable,
      AppSnapshot,
      $$AppSnapshotsTableFilterComposer,
      $$AppSnapshotsTableOrderingComposer,
      $$AppSnapshotsTableAnnotationComposer,
      $$AppSnapshotsTableCreateCompanionBuilder,
      $$AppSnapshotsTableUpdateCompanionBuilder,
      (
        AppSnapshot,
        BaseReferences<_$AppDatabase, $AppSnapshotsTable, AppSnapshot>,
      ),
      AppSnapshot,
      PrefetchHooks Function()
    >;
typedef $$FindingRecordsTableCreateCompanionBuilder =
    FindingRecordsCompanion Function({
      Value<int> id,
      required int scanId,
      required String category,
      required String title,
      Value<String> detail,
      required String severity,
      Value<String> subject,
    });
typedef $$FindingRecordsTableUpdateCompanionBuilder =
    FindingRecordsCompanion Function({
      Value<int> id,
      Value<int> scanId,
      Value<String> category,
      Value<String> title,
      Value<String> detail,
      Value<String> severity,
      Value<String> subject,
    });

class $$FindingRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $FindingRecordsTable> {
  $$FindingRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scanId => $composableBuilder(
    column: $table.scanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FindingRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $FindingRecordsTable> {
  $$FindingRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scanId => $composableBuilder(
    column: $table.scanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FindingRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FindingRecordsTable> {
  $$FindingRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get scanId =>
      $composableBuilder(column: $table.scanId, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get detail =>
      $composableBuilder(column: $table.detail, builder: (column) => column);

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);
}

class $$FindingRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FindingRecordsTable,
          FindingRecord,
          $$FindingRecordsTableFilterComposer,
          $$FindingRecordsTableOrderingComposer,
          $$FindingRecordsTableAnnotationComposer,
          $$FindingRecordsTableCreateCompanionBuilder,
          $$FindingRecordsTableUpdateCompanionBuilder,
          (
            FindingRecord,
            BaseReferences<_$AppDatabase, $FindingRecordsTable, FindingRecord>,
          ),
          FindingRecord,
          PrefetchHooks Function()
        > {
  $$FindingRecordsTableTableManager(
    _$AppDatabase db,
    $FindingRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FindingRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FindingRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FindingRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> scanId = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> detail = const Value.absent(),
                Value<String> severity = const Value.absent(),
                Value<String> subject = const Value.absent(),
              }) => FindingRecordsCompanion(
                id: id,
                scanId: scanId,
                category: category,
                title: title,
                detail: detail,
                severity: severity,
                subject: subject,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int scanId,
                required String category,
                required String title,
                Value<String> detail = const Value.absent(),
                required String severity,
                Value<String> subject = const Value.absent(),
              }) => FindingRecordsCompanion.insert(
                id: id,
                scanId: scanId,
                category: category,
                title: title,
                detail: detail,
                severity: severity,
                subject: subject,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FindingRecordsTable, FindingRecord>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FindingRecordsTable,
                    FindingRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FindingRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FindingRecordsTable,
      FindingRecord,
      $$FindingRecordsTableFilterComposer,
      $$FindingRecordsTableOrderingComposer,
      $$FindingRecordsTableAnnotationComposer,
      $$FindingRecordsTableCreateCompanionBuilder,
      $$FindingRecordsTableUpdateCompanionBuilder,
      (
        FindingRecord,
        BaseReferences<_$AppDatabase, $FindingRecordsTable, FindingRecord>,
      ),
      FindingRecord,
      PrefetchHooks Function()
    >;
typedef $$IgnoreRecordsTableCreateCompanionBuilder =
    IgnoreRecordsCompanion Function({
      Value<int> id,
      required String kind,
      required String target,
      required int createdAt,
    });
typedef $$IgnoreRecordsTableUpdateCompanionBuilder =
    IgnoreRecordsCompanion Function({
      Value<int> id,
      Value<String> kind,
      Value<String> target,
      Value<int> createdAt,
    });

class $$IgnoreRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $IgnoreRecordsTable> {
  $$IgnoreRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IgnoreRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $IgnoreRecordsTable> {
  $$IgnoreRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IgnoreRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IgnoreRecordsTable> {
  $$IgnoreRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get target =>
      $composableBuilder(column: $table.target, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$IgnoreRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IgnoreRecordsTable,
          IgnoreRecord,
          $$IgnoreRecordsTableFilterComposer,
          $$IgnoreRecordsTableOrderingComposer,
          $$IgnoreRecordsTableAnnotationComposer,
          $$IgnoreRecordsTableCreateCompanionBuilder,
          $$IgnoreRecordsTableUpdateCompanionBuilder,
          (
            IgnoreRecord,
            BaseReferences<_$AppDatabase, $IgnoreRecordsTable, IgnoreRecord>,
          ),
          IgnoreRecord,
          PrefetchHooks Function()
        > {
  $$IgnoreRecordsTableTableManager(_$AppDatabase db, $IgnoreRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IgnoreRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IgnoreRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IgnoreRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> target = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => IgnoreRecordsCompanion(
                id: id,
                kind: kind,
                target: target,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String kind,
                required String target,
                required int createdAt,
              }) => IgnoreRecordsCompanion.insert(
                id: id,
                kind: kind,
                target: target,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IgnoreRecordsTable, IgnoreRecord>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $IgnoreRecordsTable,
                    IgnoreRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IgnoreRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IgnoreRecordsTable,
      IgnoreRecord,
      $$IgnoreRecordsTableFilterComposer,
      $$IgnoreRecordsTableOrderingComposer,
      $$IgnoreRecordsTableAnnotationComposer,
      $$IgnoreRecordsTableCreateCompanionBuilder,
      $$IgnoreRecordsTableUpdateCompanionBuilder,
      (
        IgnoreRecord,
        BaseReferences<_$AppDatabase, $IgnoreRecordsTable, IgnoreRecord>,
      ),
      IgnoreRecord,
      PrefetchHooks Function()
    >;
typedef $$SettingRecordsTableCreateCompanionBuilder =
    SettingRecordsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingRecordsTableUpdateCompanionBuilder =
    SettingRecordsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingRecordsTable> {
  $$SettingRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingRecordsTable> {
  $$SettingRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingRecordsTable> {
  $$SettingRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingRecordsTable,
          SettingRecord,
          $$SettingRecordsTableFilterComposer,
          $$SettingRecordsTableOrderingComposer,
          $$SettingRecordsTableAnnotationComposer,
          $$SettingRecordsTableCreateCompanionBuilder,
          $$SettingRecordsTableUpdateCompanionBuilder,
          (
            SettingRecord,
            BaseReferences<_$AppDatabase, $SettingRecordsTable, SettingRecord>,
          ),
          SettingRecord,
          PrefetchHooks Function()
        > {
  $$SettingRecordsTableTableManager(
    _$AppDatabase db,
    $SettingRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingRecordsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingRecordsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingRecordsTable, SettingRecord>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SettingRecordsTable,
                    SettingRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingRecordsTable,
      SettingRecord,
      $$SettingRecordsTableFilterComposer,
      $$SettingRecordsTableOrderingComposer,
      $$SettingRecordsTableAnnotationComposer,
      $$SettingRecordsTableCreateCompanionBuilder,
      $$SettingRecordsTableUpdateCompanionBuilder,
      (
        SettingRecord,
        BaseReferences<_$AppDatabase, $SettingRecordsTable, SettingRecord>,
      ),
      SettingRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ScanRecordsTableTableManager get scanRecords =>
      $$ScanRecordsTableTableManager(_db, _db.scanRecords);
  $$AppSnapshotsTableTableManager get appSnapshots =>
      $$AppSnapshotsTableTableManager(_db, _db.appSnapshots);
  $$FindingRecordsTableTableManager get findingRecords =>
      $$FindingRecordsTableTableManager(_db, _db.findingRecords);
  $$IgnoreRecordsTableTableManager get ignoreRecords =>
      $$IgnoreRecordsTableTableManager(_db, _db.ignoreRecords);
  $$SettingRecordsTableTableManager get settingRecords =>
      $$SettingRecordsTableTableManager(_db, _db.settingRecords);
}
