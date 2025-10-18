// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UserTable extends User with TableInfo<$UserTable, UserData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passwordMeta = const VerificationMeta(
    'password',
  );
  @override
  late final GeneratedColumn<String> password = GeneratedColumn<String>(
    'password',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mobileNumberMeta = const VerificationMeta(
    'mobileNumber',
  );
  @override
  late final GeneratedColumn<String> mobileNumber = GeneratedColumn<String>(
    'mobile_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    email,
    password,
    mobileNumber,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('password')) {
      context.handle(
        _passwordMeta,
        password.isAcceptableOrUnknown(data['password']!, _passwordMeta),
      );
    } else if (isInserting) {
      context.missing(_passwordMeta);
    }
    if (data.containsKey('mobile_number')) {
      context.handle(
        _mobileNumberMeta,
        mobileNumber.isAcceptableOrUnknown(
          data['mobile_number']!,
          _mobileNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mobileNumberMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      email:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}email'],
          )!,
      password:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}password'],
          )!,
      mobileNumber:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}mobile_number'],
          )!,
    );
  }

  @override
  $UserTable createAlias(String alias) {
    return $UserTable(attachedDatabase, alias);
  }
}

class UserData extends DataClass implements Insertable<UserData> {
  final int id;
  final String name;
  final String email;
  final String password;
  final String mobileNumber;
  const UserData({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.mobileNumber,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['email'] = Variable<String>(email);
    map['password'] = Variable<String>(password);
    map['mobile_number'] = Variable<String>(mobileNumber);
    return map;
  }

  UserCompanion toCompanion(bool nullToAbsent) {
    return UserCompanion(
      id: Value(id),
      name: Value(name),
      email: Value(email),
      password: Value(password),
      mobileNumber: Value(mobileNumber),
    );
  }

  factory UserData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String>(json['email']),
      password: serializer.fromJson<String>(json['password']),
      mobileNumber: serializer.fromJson<String>(json['mobileNumber']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String>(email),
      'password': serializer.toJson<String>(password),
      'mobileNumber': serializer.toJson<String>(mobileNumber),
    };
  }

  UserData copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    String? mobileNumber,
  }) => UserData(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    password: password ?? this.password,
    mobileNumber: mobileNumber ?? this.mobileNumber,
  );
  UserData copyWithCompanion(UserCompanion data) {
    return UserData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      password: data.password.present ? data.password.value : this.password,
      mobileNumber:
          data.mobileNumber.present
              ? data.mobileNumber.value
              : this.mobileNumber,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('password: $password, ')
          ..write('mobileNumber: $mobileNumber')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, email, password, mobileNumber);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserData &&
          other.id == this.id &&
          other.name == this.name &&
          other.email == this.email &&
          other.password == this.password &&
          other.mobileNumber == this.mobileNumber);
}

class UserCompanion extends UpdateCompanion<UserData> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> email;
  final Value<String> password;
  final Value<String> mobileNumber;
  const UserCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.password = const Value.absent(),
    this.mobileNumber = const Value.absent(),
  });
  UserCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String email,
    required String password,
    required String mobileNumber,
  }) : name = Value(name),
       email = Value(email),
       password = Value(password),
       mobileNumber = Value(mobileNumber);
  static Insertable<UserData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? password,
    Expression<String>? mobileNumber,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (password != null) 'password': password,
      if (mobileNumber != null) 'mobile_number': mobileNumber,
    });
  }

  UserCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? email,
    Value<String>? password,
    Value<String>? mobileNumber,
  }) {
    return UserCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      mobileNumber: mobileNumber ?? this.mobileNumber,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (password.present) {
      map['password'] = Variable<String>(password.value);
    }
    if (mobileNumber.present) {
      map['mobile_number'] = Variable<String>(mobileNumber.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('password: $password, ')
          ..write('mobileNumber: $mobileNumber')
          ..write(')'))
        .toString();
  }
}

class $PanelTable extends Panel with TableInfo<$PanelTable, PanelData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PanelTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _panelSimNumberMeta = const VerificationMeta(
    'panelSimNumber',
  );
  @override
  late final GeneratedColumn<String> panelSimNumber = GeneratedColumn<String>(
    'panel_sim_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _siteNameMeta = const VerificationMeta(
    'siteName',
  );
  @override
  late final GeneratedColumn<String> siteName = GeneratedColumn<String>(
    'site_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  static const VerificationMeta _panelNameMeta = const VerificationMeta(
    'panelName',
  );
  @override
  late final GeneratedColumn<String> panelName = GeneratedColumn<String>(
    'panel_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _adminCodeMeta = const VerificationMeta(
    'adminCode',
  );
  @override
  late final GeneratedColumn<String> adminCode = GeneratedColumn<String>(
    'admin_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _adminMobileNumberMeta = const VerificationMeta(
    'adminMobileNumber',
  );
  @override
  late final GeneratedColumn<String> adminMobileNumber =
      GeneratedColumn<String>(
        'admin_mobile_number',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _panelTypeMeta = const VerificationMeta(
    'panelType',
  );
  @override
  late final GeneratedColumn<String> panelType = GeneratedColumn<String>(
    'panel_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mobileNumber1Meta = const VerificationMeta(
    'mobileNumber1',
  );
  @override
  late final GeneratedColumn<String> mobileNumber1 = GeneratedColumn<String>(
    'mobile_number1',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant("0000000000"),
  );
  static const VerificationMeta _mobileNumber2Meta = const VerificationMeta(
    'mobileNumber2',
  );
  @override
  late final GeneratedColumn<String> mobileNumber2 = GeneratedColumn<String>(
    'mobile_number2',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant("0000000000"),
  );
  static const VerificationMeta _mobileNumber3Meta = const VerificationMeta(
    'mobileNumber3',
  );
  @override
  late final GeneratedColumn<String> mobileNumber3 = GeneratedColumn<String>(
    'mobile_number3',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant("0000000000"),
  );
  static const VerificationMeta _mobileNumber4Meta = const VerificationMeta(
    'mobileNumber4',
  );
  @override
  late final GeneratedColumn<String> mobileNumber4 = GeneratedColumn<String>(
    'mobile_number4',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant("0000000000"),
  );
  static const VerificationMeta _mobileNumber5Meta = const VerificationMeta(
    'mobileNumber5',
  );
  @override
  late final GeneratedColumn<String> mobileNumber5 = GeneratedColumn<String>(
    'mobile_number5',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant("0000000000"),
  );
  static const VerificationMeta _mobileNumber6Meta = const VerificationMeta(
    'mobileNumber6',
  );
  @override
  late final GeneratedColumn<String> mobileNumber6 = GeneratedColumn<String>(
    'mobile_number6',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant("0000000000"),
  );
  static const VerificationMeta _mobileNumber7Meta = const VerificationMeta(
    'mobileNumber7',
  );
  @override
  late final GeneratedColumn<String> mobileNumber7 = GeneratedColumn<String>(
    'mobile_number7',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant("0000000000"),
  );
  static const VerificationMeta _mobileNumber8Meta = const VerificationMeta(
    'mobileNumber8',
  );
  @override
  late final GeneratedColumn<String> mobileNumber8 = GeneratedColumn<String>(
    'mobile_number8',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant("0000000000"),
  );
  static const VerificationMeta _mobileNumber9Meta = const VerificationMeta(
    'mobileNumber9',
  );
  @override
  late final GeneratedColumn<String> mobileNumber9 = GeneratedColumn<String>(
    'mobile_number9',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant("0000000000"),
  );
  static const VerificationMeta _mobileNumber10Meta = const VerificationMeta(
    'mobileNumber10',
  );
  @override
  late final GeneratedColumn<String> mobileNumber10 = GeneratedColumn<String>(
    'mobile_number10',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant("0000000000"),
  );
  static const VerificationMeta _isIPPanelMeta = const VerificationMeta(
    'isIPPanel',
  );
  @override
  late final GeneratedColumn<bool> isIPPanel = GeneratedColumn<bool>(
    'is_i_p_panel',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_i_p_panel" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isIPGPRSPanelMeta = const VerificationMeta(
    'isIPGPRSPanel',
  );
  @override
  late final GeneratedColumn<bool> isIPGPRSPanel = GeneratedColumn<bool>(
    'is_i_p_g_p_r_s_panel',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_i_p_g_p_r_s_panel" IN (0, 1))',
    ),
  );
  static const VerificationMeta _ipAddressMeta = const VerificationMeta(
    'ipAddress',
  );
  @override
  late final GeneratedColumn<String> ipAddress = GeneratedColumn<String>(
    'ip_address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _portMeta = const VerificationMeta('port');
  @override
  late final GeneratedColumn<String> port = GeneratedColumn<String>(
    'port',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _staticIPAddressMeta = const VerificationMeta(
    'staticIPAddress',
  );
  @override
  late final GeneratedColumn<String> staticIPAddress = GeneratedColumn<String>(
    'static_i_p_address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _staticPortMeta = const VerificationMeta(
    'staticPort',
  );
  @override
  late final GeneratedColumn<String> staticPort = GeneratedColumn<String>(
    'static_port',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ipPasswordMeta = const VerificationMeta(
    'ipPassword',
  );
  @override
  late final GeneratedColumn<String> ipPassword = GeneratedColumn<String>(
    'ip_password',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    panelSimNumber,
    userId,
    siteName,
    panelName,
    adminCode,
    adminMobileNumber,
    panelType,
    address,
    mobileNumber1,
    mobileNumber2,
    mobileNumber3,
    mobileNumber4,
    mobileNumber5,
    mobileNumber6,
    mobileNumber7,
    mobileNumber8,
    mobileNumber9,
    mobileNumber10,
    isIPPanel,
    isIPGPRSPanel,
    ipAddress,
    port,
    staticIPAddress,
    staticPort,
    ipPassword,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'panel';
  @override
  VerificationContext validateIntegrity(
    Insertable<PanelData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('panel_sim_number')) {
      context.handle(
        _panelSimNumberMeta,
        panelSimNumber.isAcceptableOrUnknown(
          data['panel_sim_number']!,
          _panelSimNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_panelSimNumberMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('site_name')) {
      context.handle(
        _siteNameMeta,
        siteName.isAcceptableOrUnknown(data['site_name']!, _siteNameMeta),
      );
    } else if (isInserting) {
      context.missing(_siteNameMeta);
    }
    if (data.containsKey('panel_name')) {
      context.handle(
        _panelNameMeta,
        panelName.isAcceptableOrUnknown(data['panel_name']!, _panelNameMeta),
      );
    } else if (isInserting) {
      context.missing(_panelNameMeta);
    }
    if (data.containsKey('admin_code')) {
      context.handle(
        _adminCodeMeta,
        adminCode.isAcceptableOrUnknown(data['admin_code']!, _adminCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_adminCodeMeta);
    }
    if (data.containsKey('admin_mobile_number')) {
      context.handle(
        _adminMobileNumberMeta,
        adminMobileNumber.isAcceptableOrUnknown(
          data['admin_mobile_number']!,
          _adminMobileNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_adminMobileNumberMeta);
    }
    if (data.containsKey('panel_type')) {
      context.handle(
        _panelTypeMeta,
        panelType.isAcceptableOrUnknown(data['panel_type']!, _panelTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_panelTypeMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('mobile_number1')) {
      context.handle(
        _mobileNumber1Meta,
        mobileNumber1.isAcceptableOrUnknown(
          data['mobile_number1']!,
          _mobileNumber1Meta,
        ),
      );
    }
    if (data.containsKey('mobile_number2')) {
      context.handle(
        _mobileNumber2Meta,
        mobileNumber2.isAcceptableOrUnknown(
          data['mobile_number2']!,
          _mobileNumber2Meta,
        ),
      );
    }
    if (data.containsKey('mobile_number3')) {
      context.handle(
        _mobileNumber3Meta,
        mobileNumber3.isAcceptableOrUnknown(
          data['mobile_number3']!,
          _mobileNumber3Meta,
        ),
      );
    }
    if (data.containsKey('mobile_number4')) {
      context.handle(
        _mobileNumber4Meta,
        mobileNumber4.isAcceptableOrUnknown(
          data['mobile_number4']!,
          _mobileNumber4Meta,
        ),
      );
    }
    if (data.containsKey('mobile_number5')) {
      context.handle(
        _mobileNumber5Meta,
        mobileNumber5.isAcceptableOrUnknown(
          data['mobile_number5']!,
          _mobileNumber5Meta,
        ),
      );
    }
    if (data.containsKey('mobile_number6')) {
      context.handle(
        _mobileNumber6Meta,
        mobileNumber6.isAcceptableOrUnknown(
          data['mobile_number6']!,
          _mobileNumber6Meta,
        ),
      );
    }
    if (data.containsKey('mobile_number7')) {
      context.handle(
        _mobileNumber7Meta,
        mobileNumber7.isAcceptableOrUnknown(
          data['mobile_number7']!,
          _mobileNumber7Meta,
        ),
      );
    }
    if (data.containsKey('mobile_number8')) {
      context.handle(
        _mobileNumber8Meta,
        mobileNumber8.isAcceptableOrUnknown(
          data['mobile_number8']!,
          _mobileNumber8Meta,
        ),
      );
    }
    if (data.containsKey('mobile_number9')) {
      context.handle(
        _mobileNumber9Meta,
        mobileNumber9.isAcceptableOrUnknown(
          data['mobile_number9']!,
          _mobileNumber9Meta,
        ),
      );
    }
    if (data.containsKey('mobile_number10')) {
      context.handle(
        _mobileNumber10Meta,
        mobileNumber10.isAcceptableOrUnknown(
          data['mobile_number10']!,
          _mobileNumber10Meta,
        ),
      );
    }
    if (data.containsKey('is_i_p_panel')) {
      context.handle(
        _isIPPanelMeta,
        isIPPanel.isAcceptableOrUnknown(data['is_i_p_panel']!, _isIPPanelMeta),
      );
    } else if (isInserting) {
      context.missing(_isIPPanelMeta);
    }
    if (data.containsKey('is_i_p_g_p_r_s_panel')) {
      context.handle(
        _isIPGPRSPanelMeta,
        isIPGPRSPanel.isAcceptableOrUnknown(
          data['is_i_p_g_p_r_s_panel']!,
          _isIPGPRSPanelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isIPGPRSPanelMeta);
    }
    if (data.containsKey('ip_address')) {
      context.handle(
        _ipAddressMeta,
        ipAddress.isAcceptableOrUnknown(data['ip_address']!, _ipAddressMeta),
      );
    } else if (isInserting) {
      context.missing(_ipAddressMeta);
    }
    if (data.containsKey('port')) {
      context.handle(
        _portMeta,
        port.isAcceptableOrUnknown(data['port']!, _portMeta),
      );
    } else if (isInserting) {
      context.missing(_portMeta);
    }
    if (data.containsKey('static_i_p_address')) {
      context.handle(
        _staticIPAddressMeta,
        staticIPAddress.isAcceptableOrUnknown(
          data['static_i_p_address']!,
          _staticIPAddressMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_staticIPAddressMeta);
    }
    if (data.containsKey('static_port')) {
      context.handle(
        _staticPortMeta,
        staticPort.isAcceptableOrUnknown(data['static_port']!, _staticPortMeta),
      );
    } else if (isInserting) {
      context.missing(_staticPortMeta);
    }
    if (data.containsKey('ip_password')) {
      context.handle(
        _ipPasswordMeta,
        ipPassword.isAcceptableOrUnknown(data['ip_password']!, _ipPasswordMeta),
      );
    } else if (isInserting) {
      context.missing(_ipPasswordMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PanelData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PanelData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      panelSimNumber:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}panel_sim_number'],
          )!,
      userId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}user_id'],
          )!,
      siteName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}site_name'],
          )!,
      panelName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}panel_name'],
          )!,
      adminCode:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}admin_code'],
          )!,
      adminMobileNumber:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}admin_mobile_number'],
          )!,
      panelType:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}panel_type'],
          )!,
      address:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}address'],
          )!,
      mobileNumber1:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}mobile_number1'],
          )!,
      mobileNumber2:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}mobile_number2'],
          )!,
      mobileNumber3:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}mobile_number3'],
          )!,
      mobileNumber4:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}mobile_number4'],
          )!,
      mobileNumber5:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}mobile_number5'],
          )!,
      mobileNumber6:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}mobile_number6'],
          )!,
      mobileNumber7:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}mobile_number7'],
          )!,
      mobileNumber8:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}mobile_number8'],
          )!,
      mobileNumber9:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}mobile_number9'],
          )!,
      mobileNumber10:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}mobile_number10'],
          )!,
      isIPPanel:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_i_p_panel'],
          )!,
      isIPGPRSPanel:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_i_p_g_p_r_s_panel'],
          )!,
      ipAddress:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}ip_address'],
          )!,
      port:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}port'],
          )!,
      staticIPAddress:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}static_i_p_address'],
          )!,
      staticPort:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}static_port'],
          )!,
      ipPassword:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}ip_password'],
          )!,
    );
  }

  @override
  $PanelTable createAlias(String alias) {
    return $PanelTable(attachedDatabase, alias);
  }
}

class PanelData extends DataClass implements Insertable<PanelData> {
  final int id;
  final String panelSimNumber;
  final int userId;
  final String siteName;
  final String panelName;
  final String adminCode;
  final String adminMobileNumber;
  final String panelType;
  final String address;
  final String mobileNumber1;
  final String mobileNumber2;
  final String mobileNumber3;
  final String mobileNumber4;
  final String mobileNumber5;
  final String mobileNumber6;
  final String mobileNumber7;
  final String mobileNumber8;
  final String mobileNumber9;
  final String mobileNumber10;
  final bool isIPPanel;
  final bool isIPGPRSPanel;
  final String ipAddress;
  final String port;
  final String staticIPAddress;
  final String staticPort;
  final String ipPassword;
  const PanelData({
    required this.id,
    required this.panelSimNumber,
    required this.userId,
    required this.siteName,
    required this.panelName,
    required this.adminCode,
    required this.adminMobileNumber,
    required this.panelType,
    required this.address,
    required this.mobileNumber1,
    required this.mobileNumber2,
    required this.mobileNumber3,
    required this.mobileNumber4,
    required this.mobileNumber5,
    required this.mobileNumber6,
    required this.mobileNumber7,
    required this.mobileNumber8,
    required this.mobileNumber9,
    required this.mobileNumber10,
    required this.isIPPanel,
    required this.isIPGPRSPanel,
    required this.ipAddress,
    required this.port,
    required this.staticIPAddress,
    required this.staticPort,
    required this.ipPassword,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['panel_sim_number'] = Variable<String>(panelSimNumber);
    map['user_id'] = Variable<int>(userId);
    map['site_name'] = Variable<String>(siteName);
    map['panel_name'] = Variable<String>(panelName);
    map['admin_code'] = Variable<String>(adminCode);
    map['admin_mobile_number'] = Variable<String>(adminMobileNumber);
    map['panel_type'] = Variable<String>(panelType);
    map['address'] = Variable<String>(address);
    map['mobile_number1'] = Variable<String>(mobileNumber1);
    map['mobile_number2'] = Variable<String>(mobileNumber2);
    map['mobile_number3'] = Variable<String>(mobileNumber3);
    map['mobile_number4'] = Variable<String>(mobileNumber4);
    map['mobile_number5'] = Variable<String>(mobileNumber5);
    map['mobile_number6'] = Variable<String>(mobileNumber6);
    map['mobile_number7'] = Variable<String>(mobileNumber7);
    map['mobile_number8'] = Variable<String>(mobileNumber8);
    map['mobile_number9'] = Variable<String>(mobileNumber9);
    map['mobile_number10'] = Variable<String>(mobileNumber10);
    map['is_i_p_panel'] = Variable<bool>(isIPPanel);
    map['is_i_p_g_p_r_s_panel'] = Variable<bool>(isIPGPRSPanel);
    map['ip_address'] = Variable<String>(ipAddress);
    map['port'] = Variable<String>(port);
    map['static_i_p_address'] = Variable<String>(staticIPAddress);
    map['static_port'] = Variable<String>(staticPort);
    map['ip_password'] = Variable<String>(ipPassword);
    return map;
  }

  PanelCompanion toCompanion(bool nullToAbsent) {
    return PanelCompanion(
      id: Value(id),
      panelSimNumber: Value(panelSimNumber),
      userId: Value(userId),
      siteName: Value(siteName),
      panelName: Value(panelName),
      adminCode: Value(adminCode),
      adminMobileNumber: Value(adminMobileNumber),
      panelType: Value(panelType),
      address: Value(address),
      mobileNumber1: Value(mobileNumber1),
      mobileNumber2: Value(mobileNumber2),
      mobileNumber3: Value(mobileNumber3),
      mobileNumber4: Value(mobileNumber4),
      mobileNumber5: Value(mobileNumber5),
      mobileNumber6: Value(mobileNumber6),
      mobileNumber7: Value(mobileNumber7),
      mobileNumber8: Value(mobileNumber8),
      mobileNumber9: Value(mobileNumber9),
      mobileNumber10: Value(mobileNumber10),
      isIPPanel: Value(isIPPanel),
      isIPGPRSPanel: Value(isIPGPRSPanel),
      ipAddress: Value(ipAddress),
      port: Value(port),
      staticIPAddress: Value(staticIPAddress),
      staticPort: Value(staticPort),
      ipPassword: Value(ipPassword),
    );
  }

  factory PanelData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PanelData(
      id: serializer.fromJson<int>(json['id']),
      panelSimNumber: serializer.fromJson<String>(json['panelSimNumber']),
      userId: serializer.fromJson<int>(json['userId']),
      siteName: serializer.fromJson<String>(json['siteName']),
      panelName: serializer.fromJson<String>(json['panelName']),
      adminCode: serializer.fromJson<String>(json['adminCode']),
      adminMobileNumber: serializer.fromJson<String>(json['adminMobileNumber']),
      panelType: serializer.fromJson<String>(json['panelType']),
      address: serializer.fromJson<String>(json['address']),
      mobileNumber1: serializer.fromJson<String>(json['mobileNumber1']),
      mobileNumber2: serializer.fromJson<String>(json['mobileNumber2']),
      mobileNumber3: serializer.fromJson<String>(json['mobileNumber3']),
      mobileNumber4: serializer.fromJson<String>(json['mobileNumber4']),
      mobileNumber5: serializer.fromJson<String>(json['mobileNumber5']),
      mobileNumber6: serializer.fromJson<String>(json['mobileNumber6']),
      mobileNumber7: serializer.fromJson<String>(json['mobileNumber7']),
      mobileNumber8: serializer.fromJson<String>(json['mobileNumber8']),
      mobileNumber9: serializer.fromJson<String>(json['mobileNumber9']),
      mobileNumber10: serializer.fromJson<String>(json['mobileNumber10']),
      isIPPanel: serializer.fromJson<bool>(json['isIPPanel']),
      isIPGPRSPanel: serializer.fromJson<bool>(json['isIPGPRSPanel']),
      ipAddress: serializer.fromJson<String>(json['ipAddress']),
      port: serializer.fromJson<String>(json['port']),
      staticIPAddress: serializer.fromJson<String>(json['staticIPAddress']),
      staticPort: serializer.fromJson<String>(json['staticPort']),
      ipPassword: serializer.fromJson<String>(json['ipPassword']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'panelSimNumber': serializer.toJson<String>(panelSimNumber),
      'userId': serializer.toJson<int>(userId),
      'siteName': serializer.toJson<String>(siteName),
      'panelName': serializer.toJson<String>(panelName),
      'adminCode': serializer.toJson<String>(adminCode),
      'adminMobileNumber': serializer.toJson<String>(adminMobileNumber),
      'panelType': serializer.toJson<String>(panelType),
      'address': serializer.toJson<String>(address),
      'mobileNumber1': serializer.toJson<String>(mobileNumber1),
      'mobileNumber2': serializer.toJson<String>(mobileNumber2),
      'mobileNumber3': serializer.toJson<String>(mobileNumber3),
      'mobileNumber4': serializer.toJson<String>(mobileNumber4),
      'mobileNumber5': serializer.toJson<String>(mobileNumber5),
      'mobileNumber6': serializer.toJson<String>(mobileNumber6),
      'mobileNumber7': serializer.toJson<String>(mobileNumber7),
      'mobileNumber8': serializer.toJson<String>(mobileNumber8),
      'mobileNumber9': serializer.toJson<String>(mobileNumber9),
      'mobileNumber10': serializer.toJson<String>(mobileNumber10),
      'isIPPanel': serializer.toJson<bool>(isIPPanel),
      'isIPGPRSPanel': serializer.toJson<bool>(isIPGPRSPanel),
      'ipAddress': serializer.toJson<String>(ipAddress),
      'port': serializer.toJson<String>(port),
      'staticIPAddress': serializer.toJson<String>(staticIPAddress),
      'staticPort': serializer.toJson<String>(staticPort),
      'ipPassword': serializer.toJson<String>(ipPassword),
    };
  }

  PanelData copyWith({
    int? id,
    String? panelSimNumber,
    int? userId,
    String? siteName,
    String? panelName,
    String? adminCode,
    String? adminMobileNumber,
    String? panelType,
    String? address,
    String? mobileNumber1,
    String? mobileNumber2,
    String? mobileNumber3,
    String? mobileNumber4,
    String? mobileNumber5,
    String? mobileNumber6,
    String? mobileNumber7,
    String? mobileNumber8,
    String? mobileNumber9,
    String? mobileNumber10,
    bool? isIPPanel,
    bool? isIPGPRSPanel,
    String? ipAddress,
    String? port,
    String? staticIPAddress,
    String? staticPort,
    String? ipPassword,
  }) => PanelData(
    id: id ?? this.id,
    panelSimNumber: panelSimNumber ?? this.panelSimNumber,
    userId: userId ?? this.userId,
    siteName: siteName ?? this.siteName,
    panelName: panelName ?? this.panelName,
    adminCode: adminCode ?? this.adminCode,
    adminMobileNumber: adminMobileNumber ?? this.adminMobileNumber,
    panelType: panelType ?? this.panelType,
    address: address ?? this.address,
    mobileNumber1: mobileNumber1 ?? this.mobileNumber1,
    mobileNumber2: mobileNumber2 ?? this.mobileNumber2,
    mobileNumber3: mobileNumber3 ?? this.mobileNumber3,
    mobileNumber4: mobileNumber4 ?? this.mobileNumber4,
    mobileNumber5: mobileNumber5 ?? this.mobileNumber5,
    mobileNumber6: mobileNumber6 ?? this.mobileNumber6,
    mobileNumber7: mobileNumber7 ?? this.mobileNumber7,
    mobileNumber8: mobileNumber8 ?? this.mobileNumber8,
    mobileNumber9: mobileNumber9 ?? this.mobileNumber9,
    mobileNumber10: mobileNumber10 ?? this.mobileNumber10,
    isIPPanel: isIPPanel ?? this.isIPPanel,
    isIPGPRSPanel: isIPGPRSPanel ?? this.isIPGPRSPanel,
    ipAddress: ipAddress ?? this.ipAddress,
    port: port ?? this.port,
    staticIPAddress: staticIPAddress ?? this.staticIPAddress,
    staticPort: staticPort ?? this.staticPort,
    ipPassword: ipPassword ?? this.ipPassword,
  );
  PanelData copyWithCompanion(PanelCompanion data) {
    return PanelData(
      id: data.id.present ? data.id.value : this.id,
      panelSimNumber:
          data.panelSimNumber.present
              ? data.panelSimNumber.value
              : this.panelSimNumber,
      userId: data.userId.present ? data.userId.value : this.userId,
      siteName: data.siteName.present ? data.siteName.value : this.siteName,
      panelName: data.panelName.present ? data.panelName.value : this.panelName,
      adminCode: data.adminCode.present ? data.adminCode.value : this.adminCode,
      adminMobileNumber:
          data.adminMobileNumber.present
              ? data.adminMobileNumber.value
              : this.adminMobileNumber,
      panelType: data.panelType.present ? data.panelType.value : this.panelType,
      address: data.address.present ? data.address.value : this.address,
      mobileNumber1:
          data.mobileNumber1.present
              ? data.mobileNumber1.value
              : this.mobileNumber1,
      mobileNumber2:
          data.mobileNumber2.present
              ? data.mobileNumber2.value
              : this.mobileNumber2,
      mobileNumber3:
          data.mobileNumber3.present
              ? data.mobileNumber3.value
              : this.mobileNumber3,
      mobileNumber4:
          data.mobileNumber4.present
              ? data.mobileNumber4.value
              : this.mobileNumber4,
      mobileNumber5:
          data.mobileNumber5.present
              ? data.mobileNumber5.value
              : this.mobileNumber5,
      mobileNumber6:
          data.mobileNumber6.present
              ? data.mobileNumber6.value
              : this.mobileNumber6,
      mobileNumber7:
          data.mobileNumber7.present
              ? data.mobileNumber7.value
              : this.mobileNumber7,
      mobileNumber8:
          data.mobileNumber8.present
              ? data.mobileNumber8.value
              : this.mobileNumber8,
      mobileNumber9:
          data.mobileNumber9.present
              ? data.mobileNumber9.value
              : this.mobileNumber9,
      mobileNumber10:
          data.mobileNumber10.present
              ? data.mobileNumber10.value
              : this.mobileNumber10,
      isIPPanel: data.isIPPanel.present ? data.isIPPanel.value : this.isIPPanel,
      isIPGPRSPanel:
          data.isIPGPRSPanel.present
              ? data.isIPGPRSPanel.value
              : this.isIPGPRSPanel,
      ipAddress: data.ipAddress.present ? data.ipAddress.value : this.ipAddress,
      port: data.port.present ? data.port.value : this.port,
      staticIPAddress:
          data.staticIPAddress.present
              ? data.staticIPAddress.value
              : this.staticIPAddress,
      staticPort:
          data.staticPort.present ? data.staticPort.value : this.staticPort,
      ipPassword:
          data.ipPassword.present ? data.ipPassword.value : this.ipPassword,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PanelData(')
          ..write('id: $id, ')
          ..write('panelSimNumber: $panelSimNumber, ')
          ..write('userId: $userId, ')
          ..write('siteName: $siteName, ')
          ..write('panelName: $panelName, ')
          ..write('adminCode: $adminCode, ')
          ..write('adminMobileNumber: $adminMobileNumber, ')
          ..write('panelType: $panelType, ')
          ..write('address: $address, ')
          ..write('mobileNumber1: $mobileNumber1, ')
          ..write('mobileNumber2: $mobileNumber2, ')
          ..write('mobileNumber3: $mobileNumber3, ')
          ..write('mobileNumber4: $mobileNumber4, ')
          ..write('mobileNumber5: $mobileNumber5, ')
          ..write('mobileNumber6: $mobileNumber6, ')
          ..write('mobileNumber7: $mobileNumber7, ')
          ..write('mobileNumber8: $mobileNumber8, ')
          ..write('mobileNumber9: $mobileNumber9, ')
          ..write('mobileNumber10: $mobileNumber10, ')
          ..write('isIPPanel: $isIPPanel, ')
          ..write('isIPGPRSPanel: $isIPGPRSPanel, ')
          ..write('ipAddress: $ipAddress, ')
          ..write('port: $port, ')
          ..write('staticIPAddress: $staticIPAddress, ')
          ..write('staticPort: $staticPort, ')
          ..write('ipPassword: $ipPassword')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    panelSimNumber,
    userId,
    siteName,
    panelName,
    adminCode,
    adminMobileNumber,
    panelType,
    address,
    mobileNumber1,
    mobileNumber2,
    mobileNumber3,
    mobileNumber4,
    mobileNumber5,
    mobileNumber6,
    mobileNumber7,
    mobileNumber8,
    mobileNumber9,
    mobileNumber10,
    isIPPanel,
    isIPGPRSPanel,
    ipAddress,
    port,
    staticIPAddress,
    staticPort,
    ipPassword,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PanelData &&
          other.id == this.id &&
          other.panelSimNumber == this.panelSimNumber &&
          other.userId == this.userId &&
          other.siteName == this.siteName &&
          other.panelName == this.panelName &&
          other.adminCode == this.adminCode &&
          other.adminMobileNumber == this.adminMobileNumber &&
          other.panelType == this.panelType &&
          other.address == this.address &&
          other.mobileNumber1 == this.mobileNumber1 &&
          other.mobileNumber2 == this.mobileNumber2 &&
          other.mobileNumber3 == this.mobileNumber3 &&
          other.mobileNumber4 == this.mobileNumber4 &&
          other.mobileNumber5 == this.mobileNumber5 &&
          other.mobileNumber6 == this.mobileNumber6 &&
          other.mobileNumber7 == this.mobileNumber7 &&
          other.mobileNumber8 == this.mobileNumber8 &&
          other.mobileNumber9 == this.mobileNumber9 &&
          other.mobileNumber10 == this.mobileNumber10 &&
          other.isIPPanel == this.isIPPanel &&
          other.isIPGPRSPanel == this.isIPGPRSPanel &&
          other.ipAddress == this.ipAddress &&
          other.port == this.port &&
          other.staticIPAddress == this.staticIPAddress &&
          other.staticPort == this.staticPort &&
          other.ipPassword == this.ipPassword);
}

class PanelCompanion extends UpdateCompanion<PanelData> {
  final Value<int> id;
  final Value<String> panelSimNumber;
  final Value<int> userId;
  final Value<String> siteName;
  final Value<String> panelName;
  final Value<String> adminCode;
  final Value<String> adminMobileNumber;
  final Value<String> panelType;
  final Value<String> address;
  final Value<String> mobileNumber1;
  final Value<String> mobileNumber2;
  final Value<String> mobileNumber3;
  final Value<String> mobileNumber4;
  final Value<String> mobileNumber5;
  final Value<String> mobileNumber6;
  final Value<String> mobileNumber7;
  final Value<String> mobileNumber8;
  final Value<String> mobileNumber9;
  final Value<String> mobileNumber10;
  final Value<bool> isIPPanel;
  final Value<bool> isIPGPRSPanel;
  final Value<String> ipAddress;
  final Value<String> port;
  final Value<String> staticIPAddress;
  final Value<String> staticPort;
  final Value<String> ipPassword;
  const PanelCompanion({
    this.id = const Value.absent(),
    this.panelSimNumber = const Value.absent(),
    this.userId = const Value.absent(),
    this.siteName = const Value.absent(),
    this.panelName = const Value.absent(),
    this.adminCode = const Value.absent(),
    this.adminMobileNumber = const Value.absent(),
    this.panelType = const Value.absent(),
    this.address = const Value.absent(),
    this.mobileNumber1 = const Value.absent(),
    this.mobileNumber2 = const Value.absent(),
    this.mobileNumber3 = const Value.absent(),
    this.mobileNumber4 = const Value.absent(),
    this.mobileNumber5 = const Value.absent(),
    this.mobileNumber6 = const Value.absent(),
    this.mobileNumber7 = const Value.absent(),
    this.mobileNumber8 = const Value.absent(),
    this.mobileNumber9 = const Value.absent(),
    this.mobileNumber10 = const Value.absent(),
    this.isIPPanel = const Value.absent(),
    this.isIPGPRSPanel = const Value.absent(),
    this.ipAddress = const Value.absent(),
    this.port = const Value.absent(),
    this.staticIPAddress = const Value.absent(),
    this.staticPort = const Value.absent(),
    this.ipPassword = const Value.absent(),
  });
  PanelCompanion.insert({
    this.id = const Value.absent(),
    required String panelSimNumber,
    required int userId,
    required String siteName,
    required String panelName,
    required String adminCode,
    required String adminMobileNumber,
    required String panelType,
    required String address,
    this.mobileNumber1 = const Value.absent(),
    this.mobileNumber2 = const Value.absent(),
    this.mobileNumber3 = const Value.absent(),
    this.mobileNumber4 = const Value.absent(),
    this.mobileNumber5 = const Value.absent(),
    this.mobileNumber6 = const Value.absent(),
    this.mobileNumber7 = const Value.absent(),
    this.mobileNumber8 = const Value.absent(),
    this.mobileNumber9 = const Value.absent(),
    this.mobileNumber10 = const Value.absent(),
    required bool isIPPanel,
    required bool isIPGPRSPanel,
    required String ipAddress,
    required String port,
    required String staticIPAddress,
    required String staticPort,
    required String ipPassword,
  }) : panelSimNumber = Value(panelSimNumber),
       userId = Value(userId),
       siteName = Value(siteName),
       panelName = Value(panelName),
       adminCode = Value(adminCode),
       adminMobileNumber = Value(adminMobileNumber),
       panelType = Value(panelType),
       address = Value(address),
       isIPPanel = Value(isIPPanel),
       isIPGPRSPanel = Value(isIPGPRSPanel),
       ipAddress = Value(ipAddress),
       port = Value(port),
       staticIPAddress = Value(staticIPAddress),
       staticPort = Value(staticPort),
       ipPassword = Value(ipPassword);
  static Insertable<PanelData> custom({
    Expression<int>? id,
    Expression<String>? panelSimNumber,
    Expression<int>? userId,
    Expression<String>? siteName,
    Expression<String>? panelName,
    Expression<String>? adminCode,
    Expression<String>? adminMobileNumber,
    Expression<String>? panelType,
    Expression<String>? address,
    Expression<String>? mobileNumber1,
    Expression<String>? mobileNumber2,
    Expression<String>? mobileNumber3,
    Expression<String>? mobileNumber4,
    Expression<String>? mobileNumber5,
    Expression<String>? mobileNumber6,
    Expression<String>? mobileNumber7,
    Expression<String>? mobileNumber8,
    Expression<String>? mobileNumber9,
    Expression<String>? mobileNumber10,
    Expression<bool>? isIPPanel,
    Expression<bool>? isIPGPRSPanel,
    Expression<String>? ipAddress,
    Expression<String>? port,
    Expression<String>? staticIPAddress,
    Expression<String>? staticPort,
    Expression<String>? ipPassword,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (panelSimNumber != null) 'panel_sim_number': panelSimNumber,
      if (userId != null) 'user_id': userId,
      if (siteName != null) 'site_name': siteName,
      if (panelName != null) 'panel_name': panelName,
      if (adminCode != null) 'admin_code': adminCode,
      if (adminMobileNumber != null) 'admin_mobile_number': adminMobileNumber,
      if (panelType != null) 'panel_type': panelType,
      if (address != null) 'address': address,
      if (mobileNumber1 != null) 'mobile_number1': mobileNumber1,
      if (mobileNumber2 != null) 'mobile_number2': mobileNumber2,
      if (mobileNumber3 != null) 'mobile_number3': mobileNumber3,
      if (mobileNumber4 != null) 'mobile_number4': mobileNumber4,
      if (mobileNumber5 != null) 'mobile_number5': mobileNumber5,
      if (mobileNumber6 != null) 'mobile_number6': mobileNumber6,
      if (mobileNumber7 != null) 'mobile_number7': mobileNumber7,
      if (mobileNumber8 != null) 'mobile_number8': mobileNumber8,
      if (mobileNumber9 != null) 'mobile_number9': mobileNumber9,
      if (mobileNumber10 != null) 'mobile_number10': mobileNumber10,
      if (isIPPanel != null) 'is_i_p_panel': isIPPanel,
      if (isIPGPRSPanel != null) 'is_i_p_g_p_r_s_panel': isIPGPRSPanel,
      if (ipAddress != null) 'ip_address': ipAddress,
      if (port != null) 'port': port,
      if (staticIPAddress != null) 'static_i_p_address': staticIPAddress,
      if (staticPort != null) 'static_port': staticPort,
      if (ipPassword != null) 'ip_password': ipPassword,
    });
  }

  PanelCompanion copyWith({
    Value<int>? id,
    Value<String>? panelSimNumber,
    Value<int>? userId,
    Value<String>? siteName,
    Value<String>? panelName,
    Value<String>? adminCode,
    Value<String>? adminMobileNumber,
    Value<String>? panelType,
    Value<String>? address,
    Value<String>? mobileNumber1,
    Value<String>? mobileNumber2,
    Value<String>? mobileNumber3,
    Value<String>? mobileNumber4,
    Value<String>? mobileNumber5,
    Value<String>? mobileNumber6,
    Value<String>? mobileNumber7,
    Value<String>? mobileNumber8,
    Value<String>? mobileNumber9,
    Value<String>? mobileNumber10,
    Value<bool>? isIPPanel,
    Value<bool>? isIPGPRSPanel,
    Value<String>? ipAddress,
    Value<String>? port,
    Value<String>? staticIPAddress,
    Value<String>? staticPort,
    Value<String>? ipPassword,
  }) {
    return PanelCompanion(
      id: id ?? this.id,
      panelSimNumber: panelSimNumber ?? this.panelSimNumber,
      userId: userId ?? this.userId,
      siteName: siteName ?? this.siteName,
      panelName: panelName ?? this.panelName,
      adminCode: adminCode ?? this.adminCode,
      adminMobileNumber: adminMobileNumber ?? this.adminMobileNumber,
      panelType: panelType ?? this.panelType,
      address: address ?? this.address,
      mobileNumber1: mobileNumber1 ?? this.mobileNumber1,
      mobileNumber2: mobileNumber2 ?? this.mobileNumber2,
      mobileNumber3: mobileNumber3 ?? this.mobileNumber3,
      mobileNumber4: mobileNumber4 ?? this.mobileNumber4,
      mobileNumber5: mobileNumber5 ?? this.mobileNumber5,
      mobileNumber6: mobileNumber6 ?? this.mobileNumber6,
      mobileNumber7: mobileNumber7 ?? this.mobileNumber7,
      mobileNumber8: mobileNumber8 ?? this.mobileNumber8,
      mobileNumber9: mobileNumber9 ?? this.mobileNumber9,
      mobileNumber10: mobileNumber10 ?? this.mobileNumber10,
      isIPPanel: isIPPanel ?? this.isIPPanel,
      isIPGPRSPanel: isIPGPRSPanel ?? this.isIPGPRSPanel,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      staticIPAddress: staticIPAddress ?? this.staticIPAddress,
      staticPort: staticPort ?? this.staticPort,
      ipPassword: ipPassword ?? this.ipPassword,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (panelSimNumber.present) {
      map['panel_sim_number'] = Variable<String>(panelSimNumber.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (siteName.present) {
      map['site_name'] = Variable<String>(siteName.value);
    }
    if (panelName.present) {
      map['panel_name'] = Variable<String>(panelName.value);
    }
    if (adminCode.present) {
      map['admin_code'] = Variable<String>(adminCode.value);
    }
    if (adminMobileNumber.present) {
      map['admin_mobile_number'] = Variable<String>(adminMobileNumber.value);
    }
    if (panelType.present) {
      map['panel_type'] = Variable<String>(panelType.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (mobileNumber1.present) {
      map['mobile_number1'] = Variable<String>(mobileNumber1.value);
    }
    if (mobileNumber2.present) {
      map['mobile_number2'] = Variable<String>(mobileNumber2.value);
    }
    if (mobileNumber3.present) {
      map['mobile_number3'] = Variable<String>(mobileNumber3.value);
    }
    if (mobileNumber4.present) {
      map['mobile_number4'] = Variable<String>(mobileNumber4.value);
    }
    if (mobileNumber5.present) {
      map['mobile_number5'] = Variable<String>(mobileNumber5.value);
    }
    if (mobileNumber6.present) {
      map['mobile_number6'] = Variable<String>(mobileNumber6.value);
    }
    if (mobileNumber7.present) {
      map['mobile_number7'] = Variable<String>(mobileNumber7.value);
    }
    if (mobileNumber8.present) {
      map['mobile_number8'] = Variable<String>(mobileNumber8.value);
    }
    if (mobileNumber9.present) {
      map['mobile_number9'] = Variable<String>(mobileNumber9.value);
    }
    if (mobileNumber10.present) {
      map['mobile_number10'] = Variable<String>(mobileNumber10.value);
    }
    if (isIPPanel.present) {
      map['is_i_p_panel'] = Variable<bool>(isIPPanel.value);
    }
    if (isIPGPRSPanel.present) {
      map['is_i_p_g_p_r_s_panel'] = Variable<bool>(isIPGPRSPanel.value);
    }
    if (ipAddress.present) {
      map['ip_address'] = Variable<String>(ipAddress.value);
    }
    if (port.present) {
      map['port'] = Variable<String>(port.value);
    }
    if (staticIPAddress.present) {
      map['static_i_p_address'] = Variable<String>(staticIPAddress.value);
    }
    if (staticPort.present) {
      map['static_port'] = Variable<String>(staticPort.value);
    }
    if (ipPassword.present) {
      map['ip_password'] = Variable<String>(ipPassword.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PanelCompanion(')
          ..write('id: $id, ')
          ..write('panelSimNumber: $panelSimNumber, ')
          ..write('userId: $userId, ')
          ..write('siteName: $siteName, ')
          ..write('panelName: $panelName, ')
          ..write('adminCode: $adminCode, ')
          ..write('adminMobileNumber: $adminMobileNumber, ')
          ..write('panelType: $panelType, ')
          ..write('address: $address, ')
          ..write('mobileNumber1: $mobileNumber1, ')
          ..write('mobileNumber2: $mobileNumber2, ')
          ..write('mobileNumber3: $mobileNumber3, ')
          ..write('mobileNumber4: $mobileNumber4, ')
          ..write('mobileNumber5: $mobileNumber5, ')
          ..write('mobileNumber6: $mobileNumber6, ')
          ..write('mobileNumber7: $mobileNumber7, ')
          ..write('mobileNumber8: $mobileNumber8, ')
          ..write('mobileNumber9: $mobileNumber9, ')
          ..write('mobileNumber10: $mobileNumber10, ')
          ..write('isIPPanel: $isIPPanel, ')
          ..write('isIPGPRSPanel: $isIPGPRSPanel, ')
          ..write('ipAddress: $ipAddress, ')
          ..write('port: $port, ')
          ..write('staticIPAddress: $staticIPAddress, ')
          ..write('staticPort: $staticPort, ')
          ..write('ipPassword: $ipPassword')
          ..write(')'))
        .toString();
  }
}

class $VendorTable extends Vendor with TableInfo<$VendorTable, VendorData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VendorTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mobileNumberMeta = const VerificationMeta(
    'mobileNumber',
  );
  @override
  late final GeneratedColumn<String> mobileNumber = GeneratedColumn<String>(
    'mobile_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    email,
    userId,
    mobileNumber,
    address,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vendor';
  @override
  VerificationContext validateIntegrity(
    Insertable<VendorData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('mobile_number')) {
      context.handle(
        _mobileNumberMeta,
        mobileNumber.isAcceptableOrUnknown(
          data['mobile_number']!,
          _mobileNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mobileNumberMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VendorData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VendorData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      email:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}email'],
          )!,
      userId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}user_id'],
          )!,
      mobileNumber:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}mobile_number'],
          )!,
      address:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}address'],
          )!,
    );
  }

  @override
  $VendorTable createAlias(String alias) {
    return $VendorTable(attachedDatabase, alias);
  }
}

class VendorData extends DataClass implements Insertable<VendorData> {
  final int id;
  final String name;
  final String email;
  final int userId;
  final String mobileNumber;
  final String address;
  const VendorData({
    required this.id,
    required this.name,
    required this.email,
    required this.userId,
    required this.mobileNumber,
    required this.address,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['email'] = Variable<String>(email);
    map['user_id'] = Variable<int>(userId);
    map['mobile_number'] = Variable<String>(mobileNumber);
    map['address'] = Variable<String>(address);
    return map;
  }

  VendorCompanion toCompanion(bool nullToAbsent) {
    return VendorCompanion(
      id: Value(id),
      name: Value(name),
      email: Value(email),
      userId: Value(userId),
      mobileNumber: Value(mobileNumber),
      address: Value(address),
    );
  }

  factory VendorData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VendorData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String>(json['email']),
      userId: serializer.fromJson<int>(json['userId']),
      mobileNumber: serializer.fromJson<String>(json['mobileNumber']),
      address: serializer.fromJson<String>(json['address']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String>(email),
      'userId': serializer.toJson<int>(userId),
      'mobileNumber': serializer.toJson<String>(mobileNumber),
      'address': serializer.toJson<String>(address),
    };
  }

  VendorData copyWith({
    int? id,
    String? name,
    String? email,
    int? userId,
    String? mobileNumber,
    String? address,
  }) => VendorData(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    userId: userId ?? this.userId,
    mobileNumber: mobileNumber ?? this.mobileNumber,
    address: address ?? this.address,
  );
  VendorData copyWithCompanion(VendorCompanion data) {
    return VendorData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      userId: data.userId.present ? data.userId.value : this.userId,
      mobileNumber:
          data.mobileNumber.present
              ? data.mobileNumber.value
              : this.mobileNumber,
      address: data.address.present ? data.address.value : this.address,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VendorData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('userId: $userId, ')
          ..write('mobileNumber: $mobileNumber, ')
          ..write('address: $address')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, email, userId, mobileNumber, address);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VendorData &&
          other.id == this.id &&
          other.name == this.name &&
          other.email == this.email &&
          other.userId == this.userId &&
          other.mobileNumber == this.mobileNumber &&
          other.address == this.address);
}

class VendorCompanion extends UpdateCompanion<VendorData> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> email;
  final Value<int> userId;
  final Value<String> mobileNumber;
  final Value<String> address;
  const VendorCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.userId = const Value.absent(),
    this.mobileNumber = const Value.absent(),
    this.address = const Value.absent(),
  });
  VendorCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String email,
    required int userId,
    required String mobileNumber,
    required String address,
  }) : name = Value(name),
       email = Value(email),
       userId = Value(userId),
       mobileNumber = Value(mobileNumber),
       address = Value(address);
  static Insertable<VendorData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? email,
    Expression<int>? userId,
    Expression<String>? mobileNumber,
    Expression<String>? address,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (userId != null) 'user_id': userId,
      if (mobileNumber != null) 'mobile_number': mobileNumber,
      if (address != null) 'address': address,
    });
  }

  VendorCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? email,
    Value<int>? userId,
    Value<String>? mobileNumber,
    Value<String>? address,
  }) {
    return VendorCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      userId: userId ?? this.userId,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      address: address ?? this.address,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (mobileNumber.present) {
      map['mobile_number'] = Variable<String>(mobileNumber.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VendorCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('userId: $userId, ')
          ..write('mobileNumber: $mobileNumber, ')
          ..write('address: $address')
          ..write(')'))
        .toString();
  }
}

class $IntrusionNumbersTable extends IntrusionNumbers
    with TableInfo<$IntrusionNumbersTable, IntrusionNumber> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IntrusionNumbersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _panelSimNumberMeta = const VerificationMeta(
    'panelSimNumber',
  );
  @override
  late final GeneratedColumn<String> panelSimNumber = GeneratedColumn<String>(
    'panel_sim_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intrusionNumberMeta = const VerificationMeta(
    'intrusionNumber',
  );
  @override
  late final GeneratedColumn<String> intrusionNumber = GeneratedColumn<String>(
    'intrusion_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, panelSimNumber, intrusionNumber];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'intrusion_numbers';
  @override
  VerificationContext validateIntegrity(
    Insertable<IntrusionNumber> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('panel_sim_number')) {
      context.handle(
        _panelSimNumberMeta,
        panelSimNumber.isAcceptableOrUnknown(
          data['panel_sim_number']!,
          _panelSimNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_panelSimNumberMeta);
    }
    if (data.containsKey('intrusion_number')) {
      context.handle(
        _intrusionNumberMeta,
        intrusionNumber.isAcceptableOrUnknown(
          data['intrusion_number']!,
          _intrusionNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_intrusionNumberMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IntrusionNumber map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IntrusionNumber(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      panelSimNumber:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}panel_sim_number'],
          )!,
      intrusionNumber:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}intrusion_number'],
          )!,
    );
  }

  @override
  $IntrusionNumbersTable createAlias(String alias) {
    return $IntrusionNumbersTable(attachedDatabase, alias);
  }
}

class IntrusionNumber extends DataClass implements Insertable<IntrusionNumber> {
  final int id;
  final String panelSimNumber;
  final String intrusionNumber;
  const IntrusionNumber({
    required this.id,
    required this.panelSimNumber,
    required this.intrusionNumber,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['panel_sim_number'] = Variable<String>(panelSimNumber);
    map['intrusion_number'] = Variable<String>(intrusionNumber);
    return map;
  }

  IntrusionNumbersCompanion toCompanion(bool nullToAbsent) {
    return IntrusionNumbersCompanion(
      id: Value(id),
      panelSimNumber: Value(panelSimNumber),
      intrusionNumber: Value(intrusionNumber),
    );
  }

  factory IntrusionNumber.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IntrusionNumber(
      id: serializer.fromJson<int>(json['id']),
      panelSimNumber: serializer.fromJson<String>(json['panelSimNumber']),
      intrusionNumber: serializer.fromJson<String>(json['intrusionNumber']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'panelSimNumber': serializer.toJson<String>(panelSimNumber),
      'intrusionNumber': serializer.toJson<String>(intrusionNumber),
    };
  }

  IntrusionNumber copyWith({
    int? id,
    String? panelSimNumber,
    String? intrusionNumber,
  }) => IntrusionNumber(
    id: id ?? this.id,
    panelSimNumber: panelSimNumber ?? this.panelSimNumber,
    intrusionNumber: intrusionNumber ?? this.intrusionNumber,
  );
  IntrusionNumber copyWithCompanion(IntrusionNumbersCompanion data) {
    return IntrusionNumber(
      id: data.id.present ? data.id.value : this.id,
      panelSimNumber:
          data.panelSimNumber.present
              ? data.panelSimNumber.value
              : this.panelSimNumber,
      intrusionNumber:
          data.intrusionNumber.present
              ? data.intrusionNumber.value
              : this.intrusionNumber,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IntrusionNumber(')
          ..write('id: $id, ')
          ..write('panelSimNumber: $panelSimNumber, ')
          ..write('intrusionNumber: $intrusionNumber')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, panelSimNumber, intrusionNumber);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IntrusionNumber &&
          other.id == this.id &&
          other.panelSimNumber == this.panelSimNumber &&
          other.intrusionNumber == this.intrusionNumber);
}

class IntrusionNumbersCompanion extends UpdateCompanion<IntrusionNumber> {
  final Value<int> id;
  final Value<String> panelSimNumber;
  final Value<String> intrusionNumber;
  const IntrusionNumbersCompanion({
    this.id = const Value.absent(),
    this.panelSimNumber = const Value.absent(),
    this.intrusionNumber = const Value.absent(),
  });
  IntrusionNumbersCompanion.insert({
    this.id = const Value.absent(),
    required String panelSimNumber,
    required String intrusionNumber,
  }) : panelSimNumber = Value(panelSimNumber),
       intrusionNumber = Value(intrusionNumber);
  static Insertable<IntrusionNumber> custom({
    Expression<int>? id,
    Expression<String>? panelSimNumber,
    Expression<String>? intrusionNumber,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (panelSimNumber != null) 'panel_sim_number': panelSimNumber,
      if (intrusionNumber != null) 'intrusion_number': intrusionNumber,
    });
  }

  IntrusionNumbersCompanion copyWith({
    Value<int>? id,
    Value<String>? panelSimNumber,
    Value<String>? intrusionNumber,
  }) {
    return IntrusionNumbersCompanion(
      id: id ?? this.id,
      panelSimNumber: panelSimNumber ?? this.panelSimNumber,
      intrusionNumber: intrusionNumber ?? this.intrusionNumber,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (panelSimNumber.present) {
      map['panel_sim_number'] = Variable<String>(panelSimNumber.value);
    }
    if (intrusionNumber.present) {
      map['intrusion_number'] = Variable<String>(intrusionNumber.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IntrusionNumbersCompanion(')
          ..write('id: $id, ')
          ..write('panelSimNumber: $panelSimNumber, ')
          ..write('intrusionNumber: $intrusionNumber')
          ..write(')'))
        .toString();
  }
}

class $FireNumbersTable extends FireNumbers
    with TableInfo<$FireNumbersTable, FireNumber> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FireNumbersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _panelSimNumberMeta = const VerificationMeta(
    'panelSimNumber',
  );
  @override
  late final GeneratedColumn<String> panelSimNumber = GeneratedColumn<String>(
    'panel_sim_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fireNumberMeta = const VerificationMeta(
    'fireNumber',
  );
  @override
  late final GeneratedColumn<String> fireNumber = GeneratedColumn<String>(
    'fire_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, panelSimNumber, fireNumber];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fire_numbers';
  @override
  VerificationContext validateIntegrity(
    Insertable<FireNumber> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('panel_sim_number')) {
      context.handle(
        _panelSimNumberMeta,
        panelSimNumber.isAcceptableOrUnknown(
          data['panel_sim_number']!,
          _panelSimNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_panelSimNumberMeta);
    }
    if (data.containsKey('fire_number')) {
      context.handle(
        _fireNumberMeta,
        fireNumber.isAcceptableOrUnknown(data['fire_number']!, _fireNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_fireNumberMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FireNumber map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FireNumber(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      panelSimNumber:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}panel_sim_number'],
          )!,
      fireNumber:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}fire_number'],
          )!,
    );
  }

  @override
  $FireNumbersTable createAlias(String alias) {
    return $FireNumbersTable(attachedDatabase, alias);
  }
}

class FireNumber extends DataClass implements Insertable<FireNumber> {
  final int id;
  final String panelSimNumber;
  final String fireNumber;
  const FireNumber({
    required this.id,
    required this.panelSimNumber,
    required this.fireNumber,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['panel_sim_number'] = Variable<String>(panelSimNumber);
    map['fire_number'] = Variable<String>(fireNumber);
    return map;
  }

  FireNumbersCompanion toCompanion(bool nullToAbsent) {
    return FireNumbersCompanion(
      id: Value(id),
      panelSimNumber: Value(panelSimNumber),
      fireNumber: Value(fireNumber),
    );
  }

  factory FireNumber.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FireNumber(
      id: serializer.fromJson<int>(json['id']),
      panelSimNumber: serializer.fromJson<String>(json['panelSimNumber']),
      fireNumber: serializer.fromJson<String>(json['fireNumber']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'panelSimNumber': serializer.toJson<String>(panelSimNumber),
      'fireNumber': serializer.toJson<String>(fireNumber),
    };
  }

  FireNumber copyWith({int? id, String? panelSimNumber, String? fireNumber}) =>
      FireNumber(
        id: id ?? this.id,
        panelSimNumber: panelSimNumber ?? this.panelSimNumber,
        fireNumber: fireNumber ?? this.fireNumber,
      );
  FireNumber copyWithCompanion(FireNumbersCompanion data) {
    return FireNumber(
      id: data.id.present ? data.id.value : this.id,
      panelSimNumber:
          data.panelSimNumber.present
              ? data.panelSimNumber.value
              : this.panelSimNumber,
      fireNumber:
          data.fireNumber.present ? data.fireNumber.value : this.fireNumber,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FireNumber(')
          ..write('id: $id, ')
          ..write('panelSimNumber: $panelSimNumber, ')
          ..write('fireNumber: $fireNumber')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, panelSimNumber, fireNumber);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FireNumber &&
          other.id == this.id &&
          other.panelSimNumber == this.panelSimNumber &&
          other.fireNumber == this.fireNumber);
}

class FireNumbersCompanion extends UpdateCompanion<FireNumber> {
  final Value<int> id;
  final Value<String> panelSimNumber;
  final Value<String> fireNumber;
  const FireNumbersCompanion({
    this.id = const Value.absent(),
    this.panelSimNumber = const Value.absent(),
    this.fireNumber = const Value.absent(),
  });
  FireNumbersCompanion.insert({
    this.id = const Value.absent(),
    required String panelSimNumber,
    required String fireNumber,
  }) : panelSimNumber = Value(panelSimNumber),
       fireNumber = Value(fireNumber);
  static Insertable<FireNumber> custom({
    Expression<int>? id,
    Expression<String>? panelSimNumber,
    Expression<String>? fireNumber,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (panelSimNumber != null) 'panel_sim_number': panelSimNumber,
      if (fireNumber != null) 'fire_number': fireNumber,
    });
  }

  FireNumbersCompanion copyWith({
    Value<int>? id,
    Value<String>? panelSimNumber,
    Value<String>? fireNumber,
  }) {
    return FireNumbersCompanion(
      id: id ?? this.id,
      panelSimNumber: panelSimNumber ?? this.panelSimNumber,
      fireNumber: fireNumber ?? this.fireNumber,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (panelSimNumber.present) {
      map['panel_sim_number'] = Variable<String>(panelSimNumber.value);
    }
    if (fireNumber.present) {
      map['fire_number'] = Variable<String>(fireNumber.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FireNumbersCompanion(')
          ..write('id: $id, ')
          ..write('panelSimNumber: $panelSimNumber, ')
          ..write('fireNumber: $fireNumber')
          ..write(')'))
        .toString();
  }
}

class $TimerTableTable extends TimerTable
    with TableInfo<$TimerTableTable, TimerTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimerTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _panelSimNumberMeta = const VerificationMeta(
    'panelSimNumber',
  );
  @override
  late final GeneratedColumn<String> panelSimNumber = GeneratedColumn<String>(
    'panel_sim_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryTimeMeta = const VerificationMeta(
    'entryTime',
  );
  @override
  late final GeneratedColumn<String> entryTime = GeneratedColumn<String>(
    'entry_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exitTimeMeta = const VerificationMeta(
    'exitTime',
  );
  @override
  late final GeneratedColumn<String> exitTime = GeneratedColumn<String>(
    'exit_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sounderTimeMeta = const VerificationMeta(
    'sounderTime',
  );
  @override
  late final GeneratedColumn<String> sounderTime = GeneratedColumn<String>(
    'sounder_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    panelSimNumber,
    entryTime,
    exitTime,
    sounderTime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timer_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimerTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('panel_sim_number')) {
      context.handle(
        _panelSimNumberMeta,
        panelSimNumber.isAcceptableOrUnknown(
          data['panel_sim_number']!,
          _panelSimNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_panelSimNumberMeta);
    }
    if (data.containsKey('entry_time')) {
      context.handle(
        _entryTimeMeta,
        entryTime.isAcceptableOrUnknown(data['entry_time']!, _entryTimeMeta),
      );
    }
    if (data.containsKey('exit_time')) {
      context.handle(
        _exitTimeMeta,
        exitTime.isAcceptableOrUnknown(data['exit_time']!, _exitTimeMeta),
      );
    }
    if (data.containsKey('sounder_time')) {
      context.handle(
        _sounderTimeMeta,
        sounderTime.isAcceptableOrUnknown(
          data['sounder_time']!,
          _sounderTimeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimerTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimerTableData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      panelSimNumber:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}panel_sim_number'],
          )!,
      entryTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_time'],
      ),
      exitTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exit_time'],
      ),
      sounderTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sounder_time'],
      ),
    );
  }

  @override
  $TimerTableTable createAlias(String alias) {
    return $TimerTableTable(attachedDatabase, alias);
  }
}

class TimerTableData extends DataClass implements Insertable<TimerTableData> {
  final int id;
  final String panelSimNumber;
  final String? entryTime;
  final String? exitTime;
  final String? sounderTime;
  const TimerTableData({
    required this.id,
    required this.panelSimNumber,
    this.entryTime,
    this.exitTime,
    this.sounderTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['panel_sim_number'] = Variable<String>(panelSimNumber);
    if (!nullToAbsent || entryTime != null) {
      map['entry_time'] = Variable<String>(entryTime);
    }
    if (!nullToAbsent || exitTime != null) {
      map['exit_time'] = Variable<String>(exitTime);
    }
    if (!nullToAbsent || sounderTime != null) {
      map['sounder_time'] = Variable<String>(sounderTime);
    }
    return map;
  }

  TimerTableCompanion toCompanion(bool nullToAbsent) {
    return TimerTableCompanion(
      id: Value(id),
      panelSimNumber: Value(panelSimNumber),
      entryTime:
          entryTime == null && nullToAbsent
              ? const Value.absent()
              : Value(entryTime),
      exitTime:
          exitTime == null && nullToAbsent
              ? const Value.absent()
              : Value(exitTime),
      sounderTime:
          sounderTime == null && nullToAbsent
              ? const Value.absent()
              : Value(sounderTime),
    );
  }

  factory TimerTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimerTableData(
      id: serializer.fromJson<int>(json['id']),
      panelSimNumber: serializer.fromJson<String>(json['panelSimNumber']),
      entryTime: serializer.fromJson<String?>(json['entryTime']),
      exitTime: serializer.fromJson<String?>(json['exitTime']),
      sounderTime: serializer.fromJson<String?>(json['sounderTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'panelSimNumber': serializer.toJson<String>(panelSimNumber),
      'entryTime': serializer.toJson<String?>(entryTime),
      'exitTime': serializer.toJson<String?>(exitTime),
      'sounderTime': serializer.toJson<String?>(sounderTime),
    };
  }

  TimerTableData copyWith({
    int? id,
    String? panelSimNumber,
    Value<String?> entryTime = const Value.absent(),
    Value<String?> exitTime = const Value.absent(),
    Value<String?> sounderTime = const Value.absent(),
  }) => TimerTableData(
    id: id ?? this.id,
    panelSimNumber: panelSimNumber ?? this.panelSimNumber,
    entryTime: entryTime.present ? entryTime.value : this.entryTime,
    exitTime: exitTime.present ? exitTime.value : this.exitTime,
    sounderTime: sounderTime.present ? sounderTime.value : this.sounderTime,
  );
  TimerTableData copyWithCompanion(TimerTableCompanion data) {
    return TimerTableData(
      id: data.id.present ? data.id.value : this.id,
      panelSimNumber:
          data.panelSimNumber.present
              ? data.panelSimNumber.value
              : this.panelSimNumber,
      entryTime: data.entryTime.present ? data.entryTime.value : this.entryTime,
      exitTime: data.exitTime.present ? data.exitTime.value : this.exitTime,
      sounderTime:
          data.sounderTime.present ? data.sounderTime.value : this.sounderTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimerTableData(')
          ..write('id: $id, ')
          ..write('panelSimNumber: $panelSimNumber, ')
          ..write('entryTime: $entryTime, ')
          ..write('exitTime: $exitTime, ')
          ..write('sounderTime: $sounderTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, panelSimNumber, entryTime, exitTime, sounderTime);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimerTableData &&
          other.id == this.id &&
          other.panelSimNumber == this.panelSimNumber &&
          other.entryTime == this.entryTime &&
          other.exitTime == this.exitTime &&
          other.sounderTime == this.sounderTime);
}

class TimerTableCompanion extends UpdateCompanion<TimerTableData> {
  final Value<int> id;
  final Value<String> panelSimNumber;
  final Value<String?> entryTime;
  final Value<String?> exitTime;
  final Value<String?> sounderTime;
  const TimerTableCompanion({
    this.id = const Value.absent(),
    this.panelSimNumber = const Value.absent(),
    this.entryTime = const Value.absent(),
    this.exitTime = const Value.absent(),
    this.sounderTime = const Value.absent(),
  });
  TimerTableCompanion.insert({
    this.id = const Value.absent(),
    required String panelSimNumber,
    this.entryTime = const Value.absent(),
    this.exitTime = const Value.absent(),
    this.sounderTime = const Value.absent(),
  }) : panelSimNumber = Value(panelSimNumber);
  static Insertable<TimerTableData> custom({
    Expression<int>? id,
    Expression<String>? panelSimNumber,
    Expression<String>? entryTime,
    Expression<String>? exitTime,
    Expression<String>? sounderTime,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (panelSimNumber != null) 'panel_sim_number': panelSimNumber,
      if (entryTime != null) 'entry_time': entryTime,
      if (exitTime != null) 'exit_time': exitTime,
      if (sounderTime != null) 'sounder_time': sounderTime,
    });
  }

  TimerTableCompanion copyWith({
    Value<int>? id,
    Value<String>? panelSimNumber,
    Value<String?>? entryTime,
    Value<String?>? exitTime,
    Value<String?>? sounderTime,
  }) {
    return TimerTableCompanion(
      id: id ?? this.id,
      panelSimNumber: panelSimNumber ?? this.panelSimNumber,
      entryTime: entryTime ?? this.entryTime,
      exitTime: exitTime ?? this.exitTime,
      sounderTime: sounderTime ?? this.sounderTime,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (panelSimNumber.present) {
      map['panel_sim_number'] = Variable<String>(panelSimNumber.value);
    }
    if (entryTime.present) {
      map['entry_time'] = Variable<String>(entryTime.value);
    }
    if (exitTime.present) {
      map['exit_time'] = Variable<String>(exitTime.value);
    }
    if (sounderTime.present) {
      map['sounder_time'] = Variable<String>(sounderTime.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimerTableCompanion(')
          ..write('id: $id, ')
          ..write('panelSimNumber: $panelSimNumber, ')
          ..write('entryTime: $entryTime, ')
          ..write('exitTime: $exitTime, ')
          ..write('sounderTime: $sounderTime')
          ..write(')'))
        .toString();
  }
}

class $AutomationTableTable extends AutomationTable
    with TableInfo<$AutomationTableTable, AutomationTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AutomationTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _panelSimNumberMeta = const VerificationMeta(
    'panelSimNumber',
  );
  @override
  late final GeneratedColumn<String> panelSimNumber = GeneratedColumn<String>(
    'panel_sim_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _autoArmTimeMeta = const VerificationMeta(
    'autoArmTime',
  );
  @override
  late final GeneratedColumn<String> autoArmTime = GeneratedColumn<String>(
    'auto_arm_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _autoDisarmTimeMeta = const VerificationMeta(
    'autoDisarmTime',
  );
  @override
  late final GeneratedColumn<String> autoDisarmTime = GeneratedColumn<String>(
    'auto_disarm_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _holidayTimeMeta = const VerificationMeta(
    'holidayTime',
  );
  @override
  late final GeneratedColumn<String> holidayTime = GeneratedColumn<String>(
    'holiday_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isArmToggledMeta = const VerificationMeta(
    'isArmToggled',
  );
  @override
  late final GeneratedColumn<bool> isArmToggled = GeneratedColumn<bool>(
    'is_arm_toggled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_arm_toggled" IN (0, 1))',
    ),
    defaultValue: Constant(false),
  );
  static const VerificationMeta _isDisarmToggledMeta = const VerificationMeta(
    'isDisarmToggled',
  );
  @override
  late final GeneratedColumn<bool> isDisarmToggled = GeneratedColumn<bool>(
    'is_disarm_toggled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_disarm_toggled" IN (0, 1))',
    ),
    defaultValue: Constant(false),
  );
  static const VerificationMeta _isHolidayToggledMeta = const VerificationMeta(
    'isHolidayToggled',
  );
  @override
  late final GeneratedColumn<bool> isHolidayToggled = GeneratedColumn<bool>(
    'is_holiday_toggled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_holiday_toggled" IN (0, 1))',
    ),
    defaultValue: Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    panelSimNumber,
    autoArmTime,
    autoDisarmTime,
    holidayTime,
    isArmToggled,
    isDisarmToggled,
    isHolidayToggled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'automation_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<AutomationTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('panel_sim_number')) {
      context.handle(
        _panelSimNumberMeta,
        panelSimNumber.isAcceptableOrUnknown(
          data['panel_sim_number']!,
          _panelSimNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_panelSimNumberMeta);
    }
    if (data.containsKey('auto_arm_time')) {
      context.handle(
        _autoArmTimeMeta,
        autoArmTime.isAcceptableOrUnknown(
          data['auto_arm_time']!,
          _autoArmTimeMeta,
        ),
      );
    }
    if (data.containsKey('auto_disarm_time')) {
      context.handle(
        _autoDisarmTimeMeta,
        autoDisarmTime.isAcceptableOrUnknown(
          data['auto_disarm_time']!,
          _autoDisarmTimeMeta,
        ),
      );
    }
    if (data.containsKey('holiday_time')) {
      context.handle(
        _holidayTimeMeta,
        holidayTime.isAcceptableOrUnknown(
          data['holiday_time']!,
          _holidayTimeMeta,
        ),
      );
    }
    if (data.containsKey('is_arm_toggled')) {
      context.handle(
        _isArmToggledMeta,
        isArmToggled.isAcceptableOrUnknown(
          data['is_arm_toggled']!,
          _isArmToggledMeta,
        ),
      );
    }
    if (data.containsKey('is_disarm_toggled')) {
      context.handle(
        _isDisarmToggledMeta,
        isDisarmToggled.isAcceptableOrUnknown(
          data['is_disarm_toggled']!,
          _isDisarmToggledMeta,
        ),
      );
    }
    if (data.containsKey('is_holiday_toggled')) {
      context.handle(
        _isHolidayToggledMeta,
        isHolidayToggled.isAcceptableOrUnknown(
          data['is_holiday_toggled']!,
          _isHolidayToggledMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AutomationTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AutomationTableData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      panelSimNumber:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}panel_sim_number'],
          )!,
      autoArmTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auto_arm_time'],
      ),
      autoDisarmTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auto_disarm_time'],
      ),
      holidayTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}holiday_time'],
      ),
      isArmToggled:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_arm_toggled'],
          )!,
      isDisarmToggled:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_disarm_toggled'],
          )!,
      isHolidayToggled:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_holiday_toggled'],
          )!,
    );
  }

  @override
  $AutomationTableTable createAlias(String alias) {
    return $AutomationTableTable(attachedDatabase, alias);
  }
}

class AutomationTableData extends DataClass
    implements Insertable<AutomationTableData> {
  final int id;
  final String panelSimNumber;
  final String? autoArmTime;
  final String? autoDisarmTime;
  final String? holidayTime;
  final bool isArmToggled;
  final bool isDisarmToggled;
  final bool isHolidayToggled;
  const AutomationTableData({
    required this.id,
    required this.panelSimNumber,
    this.autoArmTime,
    this.autoDisarmTime,
    this.holidayTime,
    required this.isArmToggled,
    required this.isDisarmToggled,
    required this.isHolidayToggled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['panel_sim_number'] = Variable<String>(panelSimNumber);
    if (!nullToAbsent || autoArmTime != null) {
      map['auto_arm_time'] = Variable<String>(autoArmTime);
    }
    if (!nullToAbsent || autoDisarmTime != null) {
      map['auto_disarm_time'] = Variable<String>(autoDisarmTime);
    }
    if (!nullToAbsent || holidayTime != null) {
      map['holiday_time'] = Variable<String>(holidayTime);
    }
    map['is_arm_toggled'] = Variable<bool>(isArmToggled);
    map['is_disarm_toggled'] = Variable<bool>(isDisarmToggled);
    map['is_holiday_toggled'] = Variable<bool>(isHolidayToggled);
    return map;
  }

  AutomationTableCompanion toCompanion(bool nullToAbsent) {
    return AutomationTableCompanion(
      id: Value(id),
      panelSimNumber: Value(panelSimNumber),
      autoArmTime:
          autoArmTime == null && nullToAbsent
              ? const Value.absent()
              : Value(autoArmTime),
      autoDisarmTime:
          autoDisarmTime == null && nullToAbsent
              ? const Value.absent()
              : Value(autoDisarmTime),
      holidayTime:
          holidayTime == null && nullToAbsent
              ? const Value.absent()
              : Value(holidayTime),
      isArmToggled: Value(isArmToggled),
      isDisarmToggled: Value(isDisarmToggled),
      isHolidayToggled: Value(isHolidayToggled),
    );
  }

  factory AutomationTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AutomationTableData(
      id: serializer.fromJson<int>(json['id']),
      panelSimNumber: serializer.fromJson<String>(json['panelSimNumber']),
      autoArmTime: serializer.fromJson<String?>(json['autoArmTime']),
      autoDisarmTime: serializer.fromJson<String?>(json['autoDisarmTime']),
      holidayTime: serializer.fromJson<String?>(json['holidayTime']),
      isArmToggled: serializer.fromJson<bool>(json['isArmToggled']),
      isDisarmToggled: serializer.fromJson<bool>(json['isDisarmToggled']),
      isHolidayToggled: serializer.fromJson<bool>(json['isHolidayToggled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'panelSimNumber': serializer.toJson<String>(panelSimNumber),
      'autoArmTime': serializer.toJson<String?>(autoArmTime),
      'autoDisarmTime': serializer.toJson<String?>(autoDisarmTime),
      'holidayTime': serializer.toJson<String?>(holidayTime),
      'isArmToggled': serializer.toJson<bool>(isArmToggled),
      'isDisarmToggled': serializer.toJson<bool>(isDisarmToggled),
      'isHolidayToggled': serializer.toJson<bool>(isHolidayToggled),
    };
  }

  AutomationTableData copyWith({
    int? id,
    String? panelSimNumber,
    Value<String?> autoArmTime = const Value.absent(),
    Value<String?> autoDisarmTime = const Value.absent(),
    Value<String?> holidayTime = const Value.absent(),
    bool? isArmToggled,
    bool? isDisarmToggled,
    bool? isHolidayToggled,
  }) => AutomationTableData(
    id: id ?? this.id,
    panelSimNumber: panelSimNumber ?? this.panelSimNumber,
    autoArmTime: autoArmTime.present ? autoArmTime.value : this.autoArmTime,
    autoDisarmTime:
        autoDisarmTime.present ? autoDisarmTime.value : this.autoDisarmTime,
    holidayTime: holidayTime.present ? holidayTime.value : this.holidayTime,
    isArmToggled: isArmToggled ?? this.isArmToggled,
    isDisarmToggled: isDisarmToggled ?? this.isDisarmToggled,
    isHolidayToggled: isHolidayToggled ?? this.isHolidayToggled,
  );
  AutomationTableData copyWithCompanion(AutomationTableCompanion data) {
    return AutomationTableData(
      id: data.id.present ? data.id.value : this.id,
      panelSimNumber:
          data.panelSimNumber.present
              ? data.panelSimNumber.value
              : this.panelSimNumber,
      autoArmTime:
          data.autoArmTime.present ? data.autoArmTime.value : this.autoArmTime,
      autoDisarmTime:
          data.autoDisarmTime.present
              ? data.autoDisarmTime.value
              : this.autoDisarmTime,
      holidayTime:
          data.holidayTime.present ? data.holidayTime.value : this.holidayTime,
      isArmToggled:
          data.isArmToggled.present
              ? data.isArmToggled.value
              : this.isArmToggled,
      isDisarmToggled:
          data.isDisarmToggled.present
              ? data.isDisarmToggled.value
              : this.isDisarmToggled,
      isHolidayToggled:
          data.isHolidayToggled.present
              ? data.isHolidayToggled.value
              : this.isHolidayToggled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AutomationTableData(')
          ..write('id: $id, ')
          ..write('panelSimNumber: $panelSimNumber, ')
          ..write('autoArmTime: $autoArmTime, ')
          ..write('autoDisarmTime: $autoDisarmTime, ')
          ..write('holidayTime: $holidayTime, ')
          ..write('isArmToggled: $isArmToggled, ')
          ..write('isDisarmToggled: $isDisarmToggled, ')
          ..write('isHolidayToggled: $isHolidayToggled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    panelSimNumber,
    autoArmTime,
    autoDisarmTime,
    holidayTime,
    isArmToggled,
    isDisarmToggled,
    isHolidayToggled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AutomationTableData &&
          other.id == this.id &&
          other.panelSimNumber == this.panelSimNumber &&
          other.autoArmTime == this.autoArmTime &&
          other.autoDisarmTime == this.autoDisarmTime &&
          other.holidayTime == this.holidayTime &&
          other.isArmToggled == this.isArmToggled &&
          other.isDisarmToggled == this.isDisarmToggled &&
          other.isHolidayToggled == this.isHolidayToggled);
}

class AutomationTableCompanion extends UpdateCompanion<AutomationTableData> {
  final Value<int> id;
  final Value<String> panelSimNumber;
  final Value<String?> autoArmTime;
  final Value<String?> autoDisarmTime;
  final Value<String?> holidayTime;
  final Value<bool> isArmToggled;
  final Value<bool> isDisarmToggled;
  final Value<bool> isHolidayToggled;
  const AutomationTableCompanion({
    this.id = const Value.absent(),
    this.panelSimNumber = const Value.absent(),
    this.autoArmTime = const Value.absent(),
    this.autoDisarmTime = const Value.absent(),
    this.holidayTime = const Value.absent(),
    this.isArmToggled = const Value.absent(),
    this.isDisarmToggled = const Value.absent(),
    this.isHolidayToggled = const Value.absent(),
  });
  AutomationTableCompanion.insert({
    this.id = const Value.absent(),
    required String panelSimNumber,
    this.autoArmTime = const Value.absent(),
    this.autoDisarmTime = const Value.absent(),
    this.holidayTime = const Value.absent(),
    this.isArmToggled = const Value.absent(),
    this.isDisarmToggled = const Value.absent(),
    this.isHolidayToggled = const Value.absent(),
  }) : panelSimNumber = Value(panelSimNumber);
  static Insertable<AutomationTableData> custom({
    Expression<int>? id,
    Expression<String>? panelSimNumber,
    Expression<String>? autoArmTime,
    Expression<String>? autoDisarmTime,
    Expression<String>? holidayTime,
    Expression<bool>? isArmToggled,
    Expression<bool>? isDisarmToggled,
    Expression<bool>? isHolidayToggled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (panelSimNumber != null) 'panel_sim_number': panelSimNumber,
      if (autoArmTime != null) 'auto_arm_time': autoArmTime,
      if (autoDisarmTime != null) 'auto_disarm_time': autoDisarmTime,
      if (holidayTime != null) 'holiday_time': holidayTime,
      if (isArmToggled != null) 'is_arm_toggled': isArmToggled,
      if (isDisarmToggled != null) 'is_disarm_toggled': isDisarmToggled,
      if (isHolidayToggled != null) 'is_holiday_toggled': isHolidayToggled,
    });
  }

  AutomationTableCompanion copyWith({
    Value<int>? id,
    Value<String>? panelSimNumber,
    Value<String?>? autoArmTime,
    Value<String?>? autoDisarmTime,
    Value<String?>? holidayTime,
    Value<bool>? isArmToggled,
    Value<bool>? isDisarmToggled,
    Value<bool>? isHolidayToggled,
  }) {
    return AutomationTableCompanion(
      id: id ?? this.id,
      panelSimNumber: panelSimNumber ?? this.panelSimNumber,
      autoArmTime: autoArmTime ?? this.autoArmTime,
      autoDisarmTime: autoDisarmTime ?? this.autoDisarmTime,
      holidayTime: holidayTime ?? this.holidayTime,
      isArmToggled: isArmToggled ?? this.isArmToggled,
      isDisarmToggled: isDisarmToggled ?? this.isDisarmToggled,
      isHolidayToggled: isHolidayToggled ?? this.isHolidayToggled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (panelSimNumber.present) {
      map['panel_sim_number'] = Variable<String>(panelSimNumber.value);
    }
    if (autoArmTime.present) {
      map['auto_arm_time'] = Variable<String>(autoArmTime.value);
    }
    if (autoDisarmTime.present) {
      map['auto_disarm_time'] = Variable<String>(autoDisarmTime.value);
    }
    if (holidayTime.present) {
      map['holiday_time'] = Variable<String>(holidayTime.value);
    }
    if (isArmToggled.present) {
      map['is_arm_toggled'] = Variable<bool>(isArmToggled.value);
    }
    if (isDisarmToggled.present) {
      map['is_disarm_toggled'] = Variable<bool>(isDisarmToggled.value);
    }
    if (isHolidayToggled.present) {
      map['is_holiday_toggled'] = Variable<bool>(isHolidayToggled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AutomationTableCompanion(')
          ..write('id: $id, ')
          ..write('panelSimNumber: $panelSimNumber, ')
          ..write('autoArmTime: $autoArmTime, ')
          ..write('autoDisarmTime: $autoDisarmTime, ')
          ..write('holidayTime: $holidayTime, ')
          ..write('isArmToggled: $isArmToggled, ')
          ..write('isDisarmToggled: $isDisarmToggled, ')
          ..write('isHolidayToggled: $isHolidayToggled')
          ..write(')'))
        .toString();
  }
}

class $ComplaintTableTable extends ComplaintTable
    with TableInfo<$ComplaintTableTable, ComplaintTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ComplaintTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remarkMeta = const VerificationMeta('remark');
  @override
  late final GeneratedColumn<String> remark = GeneratedColumn<String>(
    'remark',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cOnMeta = const VerificationMeta('cOn');
  @override
  late final GeneratedColumn<String> cOn = GeneratedColumn<String>(
    'c_on',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _siteNameMeta = const VerificationMeta(
    'siteName',
  );
  @override
  late final GeneratedColumn<String> siteName = GeneratedColumn<String>(
    'site_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _image1PathMeta = const VerificationMeta(
    'image1Path',
  );
  @override
  late final GeneratedColumn<String> image1Path = GeneratedColumn<String>(
    'image1_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _image2PathMeta = const VerificationMeta(
    'image2Path',
  );
  @override
  late final GeneratedColumn<String> image2Path = GeneratedColumn<String>(
    'image2_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _image3PathMeta = const VerificationMeta(
    'image3Path',
  );
  @override
  late final GeneratedColumn<String> image3Path = GeneratedColumn<String>(
    'image3_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    subject,
    remark,
    cOn,
    siteName,
    userId,
    image1Path,
    image2Path,
    image3Path,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'complaint_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ComplaintTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('remark')) {
      context.handle(
        _remarkMeta,
        remark.isAcceptableOrUnknown(data['remark']!, _remarkMeta),
      );
    } else if (isInserting) {
      context.missing(_remarkMeta);
    }
    if (data.containsKey('c_on')) {
      context.handle(
        _cOnMeta,
        cOn.isAcceptableOrUnknown(data['c_on']!, _cOnMeta),
      );
    } else if (isInserting) {
      context.missing(_cOnMeta);
    }
    if (data.containsKey('site_name')) {
      context.handle(
        _siteNameMeta,
        siteName.isAcceptableOrUnknown(data['site_name']!, _siteNameMeta),
      );
    } else if (isInserting) {
      context.missing(_siteNameMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('image1_path')) {
      context.handle(
        _image1PathMeta,
        image1Path.isAcceptableOrUnknown(data['image1_path']!, _image1PathMeta),
      );
    }
    if (data.containsKey('image2_path')) {
      context.handle(
        _image2PathMeta,
        image2Path.isAcceptableOrUnknown(data['image2_path']!, _image2PathMeta),
      );
    }
    if (data.containsKey('image3_path')) {
      context.handle(
        _image3PathMeta,
        image3Path.isAcceptableOrUnknown(data['image3_path']!, _image3PathMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ComplaintTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ComplaintTableData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      subject:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}subject'],
          )!,
      remark:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}remark'],
          )!,
      cOn:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}c_on'],
          )!,
      siteName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}site_name'],
          )!,
      userId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}user_id'],
          )!,
      image1Path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image1_path'],
      ),
      image2Path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image2_path'],
      ),
      image3Path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image3_path'],
      ),
    );
  }

  @override
  $ComplaintTableTable createAlias(String alias) {
    return $ComplaintTableTable(attachedDatabase, alias);
  }
}

class ComplaintTableData extends DataClass
    implements Insertable<ComplaintTableData> {
  final int id;
  final String subject;
  final String remark;
  final String cOn;
  final String siteName;
  final String userId;
  final String? image1Path;
  final String? image2Path;
  final String? image3Path;
  const ComplaintTableData({
    required this.id,
    required this.subject,
    required this.remark,
    required this.cOn,
    required this.siteName,
    required this.userId,
    this.image1Path,
    this.image2Path,
    this.image3Path,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['subject'] = Variable<String>(subject);
    map['remark'] = Variable<String>(remark);
    map['c_on'] = Variable<String>(cOn);
    map['site_name'] = Variable<String>(siteName);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || image1Path != null) {
      map['image1_path'] = Variable<String>(image1Path);
    }
    if (!nullToAbsent || image2Path != null) {
      map['image2_path'] = Variable<String>(image2Path);
    }
    if (!nullToAbsent || image3Path != null) {
      map['image3_path'] = Variable<String>(image3Path);
    }
    return map;
  }

  ComplaintTableCompanion toCompanion(bool nullToAbsent) {
    return ComplaintTableCompanion(
      id: Value(id),
      subject: Value(subject),
      remark: Value(remark),
      cOn: Value(cOn),
      siteName: Value(siteName),
      userId: Value(userId),
      image1Path:
          image1Path == null && nullToAbsent
              ? const Value.absent()
              : Value(image1Path),
      image2Path:
          image2Path == null && nullToAbsent
              ? const Value.absent()
              : Value(image2Path),
      image3Path:
          image3Path == null && nullToAbsent
              ? const Value.absent()
              : Value(image3Path),
    );
  }

  factory ComplaintTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ComplaintTableData(
      id: serializer.fromJson<int>(json['id']),
      subject: serializer.fromJson<String>(json['subject']),
      remark: serializer.fromJson<String>(json['remark']),
      cOn: serializer.fromJson<String>(json['cOn']),
      siteName: serializer.fromJson<String>(json['siteName']),
      userId: serializer.fromJson<String>(json['userId']),
      image1Path: serializer.fromJson<String?>(json['image1Path']),
      image2Path: serializer.fromJson<String?>(json['image2Path']),
      image3Path: serializer.fromJson<String?>(json['image3Path']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'subject': serializer.toJson<String>(subject),
      'remark': serializer.toJson<String>(remark),
      'cOn': serializer.toJson<String>(cOn),
      'siteName': serializer.toJson<String>(siteName),
      'userId': serializer.toJson<String>(userId),
      'image1Path': serializer.toJson<String?>(image1Path),
      'image2Path': serializer.toJson<String?>(image2Path),
      'image3Path': serializer.toJson<String?>(image3Path),
    };
  }

  ComplaintTableData copyWith({
    int? id,
    String? subject,
    String? remark,
    String? cOn,
    String? siteName,
    String? userId,
    Value<String?> image1Path = const Value.absent(),
    Value<String?> image2Path = const Value.absent(),
    Value<String?> image3Path = const Value.absent(),
  }) => ComplaintTableData(
    id: id ?? this.id,
    subject: subject ?? this.subject,
    remark: remark ?? this.remark,
    cOn: cOn ?? this.cOn,
    siteName: siteName ?? this.siteName,
    userId: userId ?? this.userId,
    image1Path: image1Path.present ? image1Path.value : this.image1Path,
    image2Path: image2Path.present ? image2Path.value : this.image2Path,
    image3Path: image3Path.present ? image3Path.value : this.image3Path,
  );
  ComplaintTableData copyWithCompanion(ComplaintTableCompanion data) {
    return ComplaintTableData(
      id: data.id.present ? data.id.value : this.id,
      subject: data.subject.present ? data.subject.value : this.subject,
      remark: data.remark.present ? data.remark.value : this.remark,
      cOn: data.cOn.present ? data.cOn.value : this.cOn,
      siteName: data.siteName.present ? data.siteName.value : this.siteName,
      userId: data.userId.present ? data.userId.value : this.userId,
      image1Path:
          data.image1Path.present ? data.image1Path.value : this.image1Path,
      image2Path:
          data.image2Path.present ? data.image2Path.value : this.image2Path,
      image3Path:
          data.image3Path.present ? data.image3Path.value : this.image3Path,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ComplaintTableData(')
          ..write('id: $id, ')
          ..write('subject: $subject, ')
          ..write('remark: $remark, ')
          ..write('cOn: $cOn, ')
          ..write('siteName: $siteName, ')
          ..write('userId: $userId, ')
          ..write('image1Path: $image1Path, ')
          ..write('image2Path: $image2Path, ')
          ..write('image3Path: $image3Path')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    subject,
    remark,
    cOn,
    siteName,
    userId,
    image1Path,
    image2Path,
    image3Path,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ComplaintTableData &&
          other.id == this.id &&
          other.subject == this.subject &&
          other.remark == this.remark &&
          other.cOn == this.cOn &&
          other.siteName == this.siteName &&
          other.userId == this.userId &&
          other.image1Path == this.image1Path &&
          other.image2Path == this.image2Path &&
          other.image3Path == this.image3Path);
}

class ComplaintTableCompanion extends UpdateCompanion<ComplaintTableData> {
  final Value<int> id;
  final Value<String> subject;
  final Value<String> remark;
  final Value<String> cOn;
  final Value<String> siteName;
  final Value<String> userId;
  final Value<String?> image1Path;
  final Value<String?> image2Path;
  final Value<String?> image3Path;
  const ComplaintTableCompanion({
    this.id = const Value.absent(),
    this.subject = const Value.absent(),
    this.remark = const Value.absent(),
    this.cOn = const Value.absent(),
    this.siteName = const Value.absent(),
    this.userId = const Value.absent(),
    this.image1Path = const Value.absent(),
    this.image2Path = const Value.absent(),
    this.image3Path = const Value.absent(),
  });
  ComplaintTableCompanion.insert({
    this.id = const Value.absent(),
    required String subject,
    required String remark,
    required String cOn,
    required String siteName,
    required String userId,
    this.image1Path = const Value.absent(),
    this.image2Path = const Value.absent(),
    this.image3Path = const Value.absent(),
  }) : subject = Value(subject),
       remark = Value(remark),
       cOn = Value(cOn),
       siteName = Value(siteName),
       userId = Value(userId);
  static Insertable<ComplaintTableData> custom({
    Expression<int>? id,
    Expression<String>? subject,
    Expression<String>? remark,
    Expression<String>? cOn,
    Expression<String>? siteName,
    Expression<String>? userId,
    Expression<String>? image1Path,
    Expression<String>? image2Path,
    Expression<String>? image3Path,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subject != null) 'subject': subject,
      if (remark != null) 'remark': remark,
      if (cOn != null) 'c_on': cOn,
      if (siteName != null) 'site_name': siteName,
      if (userId != null) 'user_id': userId,
      if (image1Path != null) 'image1_path': image1Path,
      if (image2Path != null) 'image2_path': image2Path,
      if (image3Path != null) 'image3_path': image3Path,
    });
  }

  ComplaintTableCompanion copyWith({
    Value<int>? id,
    Value<String>? subject,
    Value<String>? remark,
    Value<String>? cOn,
    Value<String>? siteName,
    Value<String>? userId,
    Value<String?>? image1Path,
    Value<String?>? image2Path,
    Value<String?>? image3Path,
  }) {
    return ComplaintTableCompanion(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      remark: remark ?? this.remark,
      cOn: cOn ?? this.cOn,
      siteName: siteName ?? this.siteName,
      userId: userId ?? this.userId,
      image1Path: image1Path ?? this.image1Path,
      image2Path: image2Path ?? this.image2Path,
      image3Path: image3Path ?? this.image3Path,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (remark.present) {
      map['remark'] = Variable<String>(remark.value);
    }
    if (cOn.present) {
      map['c_on'] = Variable<String>(cOn.value);
    }
    if (siteName.present) {
      map['site_name'] = Variable<String>(siteName.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (image1Path.present) {
      map['image1_path'] = Variable<String>(image1Path.value);
    }
    if (image2Path.present) {
      map['image2_path'] = Variable<String>(image2Path.value);
    }
    if (image3Path.present) {
      map['image3_path'] = Variable<String>(image3Path.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ComplaintTableCompanion(')
          ..write('id: $id, ')
          ..write('subject: $subject, ')
          ..write('remark: $remark, ')
          ..write('cOn: $cOn, ')
          ..write('siteName: $siteName, ')
          ..write('userId: $userId, ')
          ..write('image1Path: $image1Path, ')
          ..write('image2Path: $image2Path, ')
          ..write('image3Path: $image3Path')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UserTable user = $UserTable(this);
  late final $PanelTable panel = $PanelTable(this);
  late final $VendorTable vendor = $VendorTable(this);
  late final $IntrusionNumbersTable intrusionNumbers = $IntrusionNumbersTable(
    this,
  );
  late final $FireNumbersTable fireNumbers = $FireNumbersTable(this);
  late final $TimerTableTable timerTable = $TimerTableTable(this);
  late final $AutomationTableTable automationTable = $AutomationTableTable(
    this,
  );
  late final $ComplaintTableTable complaintTable = $ComplaintTableTable(this);
  late final UserDao userDao = UserDao(this as AppDatabase);
  late final PanelDao panelDao = PanelDao(this as AppDatabase);
  late final VendorDao vendorDao = VendorDao(this as AppDatabase);
  late final IntrusionNumberDao intrusionNumberDao = IntrusionNumberDao(
    this as AppDatabase,
  );
  late final FireNumberDao fireNumberDao = FireNumberDao(this as AppDatabase);
  late final TimerDao timerDao = TimerDao(this as AppDatabase);
  late final AutomationDao automationDao = AutomationDao(this as AppDatabase);
  late final ComplaintDao complaintDao = ComplaintDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    user,
    panel,
    vendor,
    intrusionNumbers,
    fireNumbers,
    timerTable,
    automationTable,
    complaintTable,
  ];
}

typedef $$UserTableCreateCompanionBuilder =
    UserCompanion Function({
      Value<int> id,
      required String name,
      required String email,
      required String password,
      required String mobileNumber,
    });
typedef $$UserTableUpdateCompanionBuilder =
    UserCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> email,
      Value<String> password,
      Value<String> mobileNumber,
    });

class $$UserTableFilterComposer extends Composer<_$AppDatabase, $UserTable> {
  $$UserTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mobileNumber => $composableBuilder(
    column: $table.mobileNumber,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserTableOrderingComposer extends Composer<_$AppDatabase, $UserTable> {
  $$UserTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mobileNumber => $composableBuilder(
    column: $table.mobileNumber,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserTable> {
  $$UserTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => column);

  GeneratedColumn<String> get mobileNumber => $composableBuilder(
    column: $table.mobileNumber,
    builder: (column) => column,
  );
}

class $$UserTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserTable,
          UserData,
          $$UserTableFilterComposer,
          $$UserTableOrderingComposer,
          $$UserTableAnnotationComposer,
          $$UserTableCreateCompanionBuilder,
          $$UserTableUpdateCompanionBuilder,
          (UserData, BaseReferences<_$AppDatabase, $UserTable, UserData>),
          UserData,
          PrefetchHooks Function()
        > {
  $$UserTableTableManager(_$AppDatabase db, $UserTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$UserTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$UserTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$UserTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> password = const Value.absent(),
                Value<String> mobileNumber = const Value.absent(),
              }) => UserCompanion(
                id: id,
                name: name,
                email: email,
                password: password,
                mobileNumber: mobileNumber,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String email,
                required String password,
                required String mobileNumber,
              }) => UserCompanion.insert(
                id: id,
                name: name,
                email: email,
                password: password,
                mobileNumber: mobileNumber,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserTable,
      UserData,
      $$UserTableFilterComposer,
      $$UserTableOrderingComposer,
      $$UserTableAnnotationComposer,
      $$UserTableCreateCompanionBuilder,
      $$UserTableUpdateCompanionBuilder,
      (UserData, BaseReferences<_$AppDatabase, $UserTable, UserData>),
      UserData,
      PrefetchHooks Function()
    >;
typedef $$PanelTableCreateCompanionBuilder =
    PanelCompanion Function({
      Value<int> id,
      required String panelSimNumber,
      required int userId,
      required String siteName,
      required String panelName,
      required String adminCode,
      required String adminMobileNumber,
      required String panelType,
      required String address,
      Value<String> mobileNumber1,
      Value<String> mobileNumber2,
      Value<String> mobileNumber3,
      Value<String> mobileNumber4,
      Value<String> mobileNumber5,
      Value<String> mobileNumber6,
      Value<String> mobileNumber7,
      Value<String> mobileNumber8,
      Value<String> mobileNumber9,
      Value<String> mobileNumber10,
      required bool isIPPanel,
      required bool isIPGPRSPanel,
      required String ipAddress,
      required String port,
      required String staticIPAddress,
      required String staticPort,
      required String ipPassword,
    });
typedef $$PanelTableUpdateCompanionBuilder =
    PanelCompanion Function({
      Value<int> id,
      Value<String> panelSimNumber,
      Value<int> userId,
      Value<String> siteName,
      Value<String> panelName,
      Value<String> adminCode,
      Value<String> adminMobileNumber,
      Value<String> panelType,
      Value<String> address,
      Value<String> mobileNumber1,
      Value<String> mobileNumber2,
      Value<String> mobileNumber3,
      Value<String> mobileNumber4,
      Value<String> mobileNumber5,
      Value<String> mobileNumber6,
      Value<String> mobileNumber7,
      Value<String> mobileNumber8,
      Value<String> mobileNumber9,
      Value<String> mobileNumber10,
      Value<bool> isIPPanel,
      Value<bool> isIPGPRSPanel,
      Value<String> ipAddress,
      Value<String> port,
      Value<String> staticIPAddress,
      Value<String> staticPort,
      Value<String> ipPassword,
    });

class $$PanelTableFilterComposer extends Composer<_$AppDatabase, $PanelTable> {
  $$PanelTableFilterComposer({
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

  ColumnFilters<String> get panelSimNumber => $composableBuilder(
    column: $table.panelSimNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get siteName => $composableBuilder(
    column: $table.siteName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get panelName => $composableBuilder(
    column: $table.panelName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get adminCode => $composableBuilder(
    column: $table.adminCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get adminMobileNumber => $composableBuilder(
    column: $table.adminMobileNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get panelType => $composableBuilder(
    column: $table.panelType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mobileNumber1 => $composableBuilder(
    column: $table.mobileNumber1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mobileNumber2 => $composableBuilder(
    column: $table.mobileNumber2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mobileNumber3 => $composableBuilder(
    column: $table.mobileNumber3,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mobileNumber4 => $composableBuilder(
    column: $table.mobileNumber4,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mobileNumber5 => $composableBuilder(
    column: $table.mobileNumber5,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mobileNumber6 => $composableBuilder(
    column: $table.mobileNumber6,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mobileNumber7 => $composableBuilder(
    column: $table.mobileNumber7,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mobileNumber8 => $composableBuilder(
    column: $table.mobileNumber8,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mobileNumber9 => $composableBuilder(
    column: $table.mobileNumber9,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mobileNumber10 => $composableBuilder(
    column: $table.mobileNumber10,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isIPPanel => $composableBuilder(
    column: $table.isIPPanel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isIPGPRSPanel => $composableBuilder(
    column: $table.isIPGPRSPanel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ipAddress => $composableBuilder(
    column: $table.ipAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get staticIPAddress => $composableBuilder(
    column: $table.staticIPAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get staticPort => $composableBuilder(
    column: $table.staticPort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ipPassword => $composableBuilder(
    column: $table.ipPassword,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PanelTableOrderingComposer
    extends Composer<_$AppDatabase, $PanelTable> {
  $$PanelTableOrderingComposer({
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

  ColumnOrderings<String> get panelSimNumber => $composableBuilder(
    column: $table.panelSimNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get siteName => $composableBuilder(
    column: $table.siteName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get panelName => $composableBuilder(
    column: $table.panelName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get adminCode => $composableBuilder(
    column: $table.adminCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get adminMobileNumber => $composableBuilder(
    column: $table.adminMobileNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get panelType => $composableBuilder(
    column: $table.panelType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mobileNumber1 => $composableBuilder(
    column: $table.mobileNumber1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mobileNumber2 => $composableBuilder(
    column: $table.mobileNumber2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mobileNumber3 => $composableBuilder(
    column: $table.mobileNumber3,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mobileNumber4 => $composableBuilder(
    column: $table.mobileNumber4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mobileNumber5 => $composableBuilder(
    column: $table.mobileNumber5,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mobileNumber6 => $composableBuilder(
    column: $table.mobileNumber6,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mobileNumber7 => $composableBuilder(
    column: $table.mobileNumber7,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mobileNumber8 => $composableBuilder(
    column: $table.mobileNumber8,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mobileNumber9 => $composableBuilder(
    column: $table.mobileNumber9,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mobileNumber10 => $composableBuilder(
    column: $table.mobileNumber10,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isIPPanel => $composableBuilder(
    column: $table.isIPPanel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isIPGPRSPanel => $composableBuilder(
    column: $table.isIPGPRSPanel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ipAddress => $composableBuilder(
    column: $table.ipAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get staticIPAddress => $composableBuilder(
    column: $table.staticIPAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get staticPort => $composableBuilder(
    column: $table.staticPort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ipPassword => $composableBuilder(
    column: $table.ipPassword,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PanelTableAnnotationComposer
    extends Composer<_$AppDatabase, $PanelTable> {
  $$PanelTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get panelSimNumber => $composableBuilder(
    column: $table.panelSimNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get siteName =>
      $composableBuilder(column: $table.siteName, builder: (column) => column);

  GeneratedColumn<String> get panelName =>
      $composableBuilder(column: $table.panelName, builder: (column) => column);

  GeneratedColumn<String> get adminCode =>
      $composableBuilder(column: $table.adminCode, builder: (column) => column);

  GeneratedColumn<String> get adminMobileNumber => $composableBuilder(
    column: $table.adminMobileNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get panelType =>
      $composableBuilder(column: $table.panelType, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get mobileNumber1 => $composableBuilder(
    column: $table.mobileNumber1,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mobileNumber2 => $composableBuilder(
    column: $table.mobileNumber2,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mobileNumber3 => $composableBuilder(
    column: $table.mobileNumber3,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mobileNumber4 => $composableBuilder(
    column: $table.mobileNumber4,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mobileNumber5 => $composableBuilder(
    column: $table.mobileNumber5,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mobileNumber6 => $composableBuilder(
    column: $table.mobileNumber6,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mobileNumber7 => $composableBuilder(
    column: $table.mobileNumber7,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mobileNumber8 => $composableBuilder(
    column: $table.mobileNumber8,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mobileNumber9 => $composableBuilder(
    column: $table.mobileNumber9,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mobileNumber10 => $composableBuilder(
    column: $table.mobileNumber10,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isIPPanel =>
      $composableBuilder(column: $table.isIPPanel, builder: (column) => column);

  GeneratedColumn<bool> get isIPGPRSPanel => $composableBuilder(
    column: $table.isIPGPRSPanel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ipAddress =>
      $composableBuilder(column: $table.ipAddress, builder: (column) => column);

  GeneratedColumn<String> get port =>
      $composableBuilder(column: $table.port, builder: (column) => column);

  GeneratedColumn<String> get staticIPAddress => $composableBuilder(
    column: $table.staticIPAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get staticPort => $composableBuilder(
    column: $table.staticPort,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ipPassword => $composableBuilder(
    column: $table.ipPassword,
    builder: (column) => column,
  );
}

class $$PanelTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PanelTable,
          PanelData,
          $$PanelTableFilterComposer,
          $$PanelTableOrderingComposer,
          $$PanelTableAnnotationComposer,
          $$PanelTableCreateCompanionBuilder,
          $$PanelTableUpdateCompanionBuilder,
          (PanelData, BaseReferences<_$AppDatabase, $PanelTable, PanelData>),
          PanelData,
          PrefetchHooks Function()
        > {
  $$PanelTableTableManager(_$AppDatabase db, $PanelTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$PanelTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$PanelTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$PanelTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> panelSimNumber = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String> siteName = const Value.absent(),
                Value<String> panelName = const Value.absent(),
                Value<String> adminCode = const Value.absent(),
                Value<String> adminMobileNumber = const Value.absent(),
                Value<String> panelType = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<String> mobileNumber1 = const Value.absent(),
                Value<String> mobileNumber2 = const Value.absent(),
                Value<String> mobileNumber3 = const Value.absent(),
                Value<String> mobileNumber4 = const Value.absent(),
                Value<String> mobileNumber5 = const Value.absent(),
                Value<String> mobileNumber6 = const Value.absent(),
                Value<String> mobileNumber7 = const Value.absent(),
                Value<String> mobileNumber8 = const Value.absent(),
                Value<String> mobileNumber9 = const Value.absent(),
                Value<String> mobileNumber10 = const Value.absent(),
                Value<bool> isIPPanel = const Value.absent(),
                Value<bool> isIPGPRSPanel = const Value.absent(),
                Value<String> ipAddress = const Value.absent(),
                Value<String> port = const Value.absent(),
                Value<String> staticIPAddress = const Value.absent(),
                Value<String> staticPort = const Value.absent(),
                Value<String> ipPassword = const Value.absent(),
              }) => PanelCompanion(
                id: id,
                panelSimNumber: panelSimNumber,
                userId: userId,
                siteName: siteName,
                panelName: panelName,
                adminCode: adminCode,
                adminMobileNumber: adminMobileNumber,
                panelType: panelType,
                address: address,
                mobileNumber1: mobileNumber1,
                mobileNumber2: mobileNumber2,
                mobileNumber3: mobileNumber3,
                mobileNumber4: mobileNumber4,
                mobileNumber5: mobileNumber5,
                mobileNumber6: mobileNumber6,
                mobileNumber7: mobileNumber7,
                mobileNumber8: mobileNumber8,
                mobileNumber9: mobileNumber9,
                mobileNumber10: mobileNumber10,
                isIPPanel: isIPPanel,
                isIPGPRSPanel: isIPGPRSPanel,
                ipAddress: ipAddress,
                port: port,
                staticIPAddress: staticIPAddress,
                staticPort: staticPort,
                ipPassword: ipPassword,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String panelSimNumber,
                required int userId,
                required String siteName,
                required String panelName,
                required String adminCode,
                required String adminMobileNumber,
                required String panelType,
                required String address,
                Value<String> mobileNumber1 = const Value.absent(),
                Value<String> mobileNumber2 = const Value.absent(),
                Value<String> mobileNumber3 = const Value.absent(),
                Value<String> mobileNumber4 = const Value.absent(),
                Value<String> mobileNumber5 = const Value.absent(),
                Value<String> mobileNumber6 = const Value.absent(),
                Value<String> mobileNumber7 = const Value.absent(),
                Value<String> mobileNumber8 = const Value.absent(),
                Value<String> mobileNumber9 = const Value.absent(),
                Value<String> mobileNumber10 = const Value.absent(),
                required bool isIPPanel,
                required bool isIPGPRSPanel,
                required String ipAddress,
                required String port,
                required String staticIPAddress,
                required String staticPort,
                required String ipPassword,
              }) => PanelCompanion.insert(
                id: id,
                panelSimNumber: panelSimNumber,
                userId: userId,
                siteName: siteName,
                panelName: panelName,
                adminCode: adminCode,
                adminMobileNumber: adminMobileNumber,
                panelType: panelType,
                address: address,
                mobileNumber1: mobileNumber1,
                mobileNumber2: mobileNumber2,
                mobileNumber3: mobileNumber3,
                mobileNumber4: mobileNumber4,
                mobileNumber5: mobileNumber5,
                mobileNumber6: mobileNumber6,
                mobileNumber7: mobileNumber7,
                mobileNumber8: mobileNumber8,
                mobileNumber9: mobileNumber9,
                mobileNumber10: mobileNumber10,
                isIPPanel: isIPPanel,
                isIPGPRSPanel: isIPGPRSPanel,
                ipAddress: ipAddress,
                port: port,
                staticIPAddress: staticIPAddress,
                staticPort: staticPort,
                ipPassword: ipPassword,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PanelTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PanelTable,
      PanelData,
      $$PanelTableFilterComposer,
      $$PanelTableOrderingComposer,
      $$PanelTableAnnotationComposer,
      $$PanelTableCreateCompanionBuilder,
      $$PanelTableUpdateCompanionBuilder,
      (PanelData, BaseReferences<_$AppDatabase, $PanelTable, PanelData>),
      PanelData,
      PrefetchHooks Function()
    >;
typedef $$VendorTableCreateCompanionBuilder =
    VendorCompanion Function({
      Value<int> id,
      required String name,
      required String email,
      required int userId,
      required String mobileNumber,
      required String address,
    });
typedef $$VendorTableUpdateCompanionBuilder =
    VendorCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> email,
      Value<int> userId,
      Value<String> mobileNumber,
      Value<String> address,
    });

class $$VendorTableFilterComposer
    extends Composer<_$AppDatabase, $VendorTable> {
  $$VendorTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mobileNumber => $composableBuilder(
    column: $table.mobileNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VendorTableOrderingComposer
    extends Composer<_$AppDatabase, $VendorTable> {
  $$VendorTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mobileNumber => $composableBuilder(
    column: $table.mobileNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VendorTableAnnotationComposer
    extends Composer<_$AppDatabase, $VendorTable> {
  $$VendorTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get mobileNumber => $composableBuilder(
    column: $table.mobileNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);
}

class $$VendorTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VendorTable,
          VendorData,
          $$VendorTableFilterComposer,
          $$VendorTableOrderingComposer,
          $$VendorTableAnnotationComposer,
          $$VendorTableCreateCompanionBuilder,
          $$VendorTableUpdateCompanionBuilder,
          (VendorData, BaseReferences<_$AppDatabase, $VendorTable, VendorData>),
          VendorData,
          PrefetchHooks Function()
        > {
  $$VendorTableTableManager(_$AppDatabase db, $VendorTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$VendorTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$VendorTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$VendorTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String> mobileNumber = const Value.absent(),
                Value<String> address = const Value.absent(),
              }) => VendorCompanion(
                id: id,
                name: name,
                email: email,
                userId: userId,
                mobileNumber: mobileNumber,
                address: address,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String email,
                required int userId,
                required String mobileNumber,
                required String address,
              }) => VendorCompanion.insert(
                id: id,
                name: name,
                email: email,
                userId: userId,
                mobileNumber: mobileNumber,
                address: address,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VendorTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VendorTable,
      VendorData,
      $$VendorTableFilterComposer,
      $$VendorTableOrderingComposer,
      $$VendorTableAnnotationComposer,
      $$VendorTableCreateCompanionBuilder,
      $$VendorTableUpdateCompanionBuilder,
      (VendorData, BaseReferences<_$AppDatabase, $VendorTable, VendorData>),
      VendorData,
      PrefetchHooks Function()
    >;
typedef $$IntrusionNumbersTableCreateCompanionBuilder =
    IntrusionNumbersCompanion Function({
      Value<int> id,
      required String panelSimNumber,
      required String intrusionNumber,
    });
typedef $$IntrusionNumbersTableUpdateCompanionBuilder =
    IntrusionNumbersCompanion Function({
      Value<int> id,
      Value<String> panelSimNumber,
      Value<String> intrusionNumber,
    });

class $$IntrusionNumbersTableFilterComposer
    extends Composer<_$AppDatabase, $IntrusionNumbersTable> {
  $$IntrusionNumbersTableFilterComposer({
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

  ColumnFilters<String> get panelSimNumber => $composableBuilder(
    column: $table.panelSimNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get intrusionNumber => $composableBuilder(
    column: $table.intrusionNumber,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IntrusionNumbersTableOrderingComposer
    extends Composer<_$AppDatabase, $IntrusionNumbersTable> {
  $$IntrusionNumbersTableOrderingComposer({
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

  ColumnOrderings<String> get panelSimNumber => $composableBuilder(
    column: $table.panelSimNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get intrusionNumber => $composableBuilder(
    column: $table.intrusionNumber,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IntrusionNumbersTableAnnotationComposer
    extends Composer<_$AppDatabase, $IntrusionNumbersTable> {
  $$IntrusionNumbersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get panelSimNumber => $composableBuilder(
    column: $table.panelSimNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get intrusionNumber => $composableBuilder(
    column: $table.intrusionNumber,
    builder: (column) => column,
  );
}

class $$IntrusionNumbersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IntrusionNumbersTable,
          IntrusionNumber,
          $$IntrusionNumbersTableFilterComposer,
          $$IntrusionNumbersTableOrderingComposer,
          $$IntrusionNumbersTableAnnotationComposer,
          $$IntrusionNumbersTableCreateCompanionBuilder,
          $$IntrusionNumbersTableUpdateCompanionBuilder,
          (
            IntrusionNumber,
            BaseReferences<
              _$AppDatabase,
              $IntrusionNumbersTable,
              IntrusionNumber
            >,
          ),
          IntrusionNumber,
          PrefetchHooks Function()
        > {
  $$IntrusionNumbersTableTableManager(
    _$AppDatabase db,
    $IntrusionNumbersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$IntrusionNumbersTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$IntrusionNumbersTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$IntrusionNumbersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> panelSimNumber = const Value.absent(),
                Value<String> intrusionNumber = const Value.absent(),
              }) => IntrusionNumbersCompanion(
                id: id,
                panelSimNumber: panelSimNumber,
                intrusionNumber: intrusionNumber,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String panelSimNumber,
                required String intrusionNumber,
              }) => IntrusionNumbersCompanion.insert(
                id: id,
                panelSimNumber: panelSimNumber,
                intrusionNumber: intrusionNumber,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IntrusionNumbersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IntrusionNumbersTable,
      IntrusionNumber,
      $$IntrusionNumbersTableFilterComposer,
      $$IntrusionNumbersTableOrderingComposer,
      $$IntrusionNumbersTableAnnotationComposer,
      $$IntrusionNumbersTableCreateCompanionBuilder,
      $$IntrusionNumbersTableUpdateCompanionBuilder,
      (
        IntrusionNumber,
        BaseReferences<_$AppDatabase, $IntrusionNumbersTable, IntrusionNumber>,
      ),
      IntrusionNumber,
      PrefetchHooks Function()
    >;
typedef $$FireNumbersTableCreateCompanionBuilder =
    FireNumbersCompanion Function({
      Value<int> id,
      required String panelSimNumber,
      required String fireNumber,
    });
typedef $$FireNumbersTableUpdateCompanionBuilder =
    FireNumbersCompanion Function({
      Value<int> id,
      Value<String> panelSimNumber,
      Value<String> fireNumber,
    });

class $$FireNumbersTableFilterComposer
    extends Composer<_$AppDatabase, $FireNumbersTable> {
  $$FireNumbersTableFilterComposer({
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

  ColumnFilters<String> get panelSimNumber => $composableBuilder(
    column: $table.panelSimNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fireNumber => $composableBuilder(
    column: $table.fireNumber,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FireNumbersTableOrderingComposer
    extends Composer<_$AppDatabase, $FireNumbersTable> {
  $$FireNumbersTableOrderingComposer({
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

  ColumnOrderings<String> get panelSimNumber => $composableBuilder(
    column: $table.panelSimNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fireNumber => $composableBuilder(
    column: $table.fireNumber,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FireNumbersTableAnnotationComposer
    extends Composer<_$AppDatabase, $FireNumbersTable> {
  $$FireNumbersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get panelSimNumber => $composableBuilder(
    column: $table.panelSimNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fireNumber => $composableBuilder(
    column: $table.fireNumber,
    builder: (column) => column,
  );
}

class $$FireNumbersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FireNumbersTable,
          FireNumber,
          $$FireNumbersTableFilterComposer,
          $$FireNumbersTableOrderingComposer,
          $$FireNumbersTableAnnotationComposer,
          $$FireNumbersTableCreateCompanionBuilder,
          $$FireNumbersTableUpdateCompanionBuilder,
          (
            FireNumber,
            BaseReferences<_$AppDatabase, $FireNumbersTable, FireNumber>,
          ),
          FireNumber,
          PrefetchHooks Function()
        > {
  $$FireNumbersTableTableManager(_$AppDatabase db, $FireNumbersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$FireNumbersTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$FireNumbersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$FireNumbersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> panelSimNumber = const Value.absent(),
                Value<String> fireNumber = const Value.absent(),
              }) => FireNumbersCompanion(
                id: id,
                panelSimNumber: panelSimNumber,
                fireNumber: fireNumber,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String panelSimNumber,
                required String fireNumber,
              }) => FireNumbersCompanion.insert(
                id: id,
                panelSimNumber: panelSimNumber,
                fireNumber: fireNumber,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FireNumbersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FireNumbersTable,
      FireNumber,
      $$FireNumbersTableFilterComposer,
      $$FireNumbersTableOrderingComposer,
      $$FireNumbersTableAnnotationComposer,
      $$FireNumbersTableCreateCompanionBuilder,
      $$FireNumbersTableUpdateCompanionBuilder,
      (
        FireNumber,
        BaseReferences<_$AppDatabase, $FireNumbersTable, FireNumber>,
      ),
      FireNumber,
      PrefetchHooks Function()
    >;
typedef $$TimerTableTableCreateCompanionBuilder =
    TimerTableCompanion Function({
      Value<int> id,
      required String panelSimNumber,
      Value<String?> entryTime,
      Value<String?> exitTime,
      Value<String?> sounderTime,
    });
typedef $$TimerTableTableUpdateCompanionBuilder =
    TimerTableCompanion Function({
      Value<int> id,
      Value<String> panelSimNumber,
      Value<String?> entryTime,
      Value<String?> exitTime,
      Value<String?> sounderTime,
    });

class $$TimerTableTableFilterComposer
    extends Composer<_$AppDatabase, $TimerTableTable> {
  $$TimerTableTableFilterComposer({
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

  ColumnFilters<String> get panelSimNumber => $composableBuilder(
    column: $table.panelSimNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryTime => $composableBuilder(
    column: $table.entryTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exitTime => $composableBuilder(
    column: $table.exitTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sounderTime => $composableBuilder(
    column: $table.sounderTime,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TimerTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TimerTableTable> {
  $$TimerTableTableOrderingComposer({
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

  ColumnOrderings<String> get panelSimNumber => $composableBuilder(
    column: $table.panelSimNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryTime => $composableBuilder(
    column: $table.entryTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exitTime => $composableBuilder(
    column: $table.exitTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sounderTime => $composableBuilder(
    column: $table.sounderTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TimerTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimerTableTable> {
  $$TimerTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get panelSimNumber => $composableBuilder(
    column: $table.panelSimNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entryTime =>
      $composableBuilder(column: $table.entryTime, builder: (column) => column);

  GeneratedColumn<String> get exitTime =>
      $composableBuilder(column: $table.exitTime, builder: (column) => column);

  GeneratedColumn<String> get sounderTime => $composableBuilder(
    column: $table.sounderTime,
    builder: (column) => column,
  );
}

class $$TimerTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TimerTableTable,
          TimerTableData,
          $$TimerTableTableFilterComposer,
          $$TimerTableTableOrderingComposer,
          $$TimerTableTableAnnotationComposer,
          $$TimerTableTableCreateCompanionBuilder,
          $$TimerTableTableUpdateCompanionBuilder,
          (
            TimerTableData,
            BaseReferences<_$AppDatabase, $TimerTableTable, TimerTableData>,
          ),
          TimerTableData,
          PrefetchHooks Function()
        > {
  $$TimerTableTableTableManager(_$AppDatabase db, $TimerTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$TimerTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$TimerTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$TimerTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> panelSimNumber = const Value.absent(),
                Value<String?> entryTime = const Value.absent(),
                Value<String?> exitTime = const Value.absent(),
                Value<String?> sounderTime = const Value.absent(),
              }) => TimerTableCompanion(
                id: id,
                panelSimNumber: panelSimNumber,
                entryTime: entryTime,
                exitTime: exitTime,
                sounderTime: sounderTime,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String panelSimNumber,
                Value<String?> entryTime = const Value.absent(),
                Value<String?> exitTime = const Value.absent(),
                Value<String?> sounderTime = const Value.absent(),
              }) => TimerTableCompanion.insert(
                id: id,
                panelSimNumber: panelSimNumber,
                entryTime: entryTime,
                exitTime: exitTime,
                sounderTime: sounderTime,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TimerTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TimerTableTable,
      TimerTableData,
      $$TimerTableTableFilterComposer,
      $$TimerTableTableOrderingComposer,
      $$TimerTableTableAnnotationComposer,
      $$TimerTableTableCreateCompanionBuilder,
      $$TimerTableTableUpdateCompanionBuilder,
      (
        TimerTableData,
        BaseReferences<_$AppDatabase, $TimerTableTable, TimerTableData>,
      ),
      TimerTableData,
      PrefetchHooks Function()
    >;
typedef $$AutomationTableTableCreateCompanionBuilder =
    AutomationTableCompanion Function({
      Value<int> id,
      required String panelSimNumber,
      Value<String?> autoArmTime,
      Value<String?> autoDisarmTime,
      Value<String?> holidayTime,
      Value<bool> isArmToggled,
      Value<bool> isDisarmToggled,
      Value<bool> isHolidayToggled,
    });
typedef $$AutomationTableTableUpdateCompanionBuilder =
    AutomationTableCompanion Function({
      Value<int> id,
      Value<String> panelSimNumber,
      Value<String?> autoArmTime,
      Value<String?> autoDisarmTime,
      Value<String?> holidayTime,
      Value<bool> isArmToggled,
      Value<bool> isDisarmToggled,
      Value<bool> isHolidayToggled,
    });

class $$AutomationTableTableFilterComposer
    extends Composer<_$AppDatabase, $AutomationTableTable> {
  $$AutomationTableTableFilterComposer({
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

  ColumnFilters<String> get panelSimNumber => $composableBuilder(
    column: $table.panelSimNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get autoArmTime => $composableBuilder(
    column: $table.autoArmTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get autoDisarmTime => $composableBuilder(
    column: $table.autoDisarmTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get holidayTime => $composableBuilder(
    column: $table.holidayTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArmToggled => $composableBuilder(
    column: $table.isArmToggled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDisarmToggled => $composableBuilder(
    column: $table.isDisarmToggled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isHolidayToggled => $composableBuilder(
    column: $table.isHolidayToggled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AutomationTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AutomationTableTable> {
  $$AutomationTableTableOrderingComposer({
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

  ColumnOrderings<String> get panelSimNumber => $composableBuilder(
    column: $table.panelSimNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get autoArmTime => $composableBuilder(
    column: $table.autoArmTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get autoDisarmTime => $composableBuilder(
    column: $table.autoDisarmTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get holidayTime => $composableBuilder(
    column: $table.holidayTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArmToggled => $composableBuilder(
    column: $table.isArmToggled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDisarmToggled => $composableBuilder(
    column: $table.isDisarmToggled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isHolidayToggled => $composableBuilder(
    column: $table.isHolidayToggled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AutomationTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AutomationTableTable> {
  $$AutomationTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get panelSimNumber => $composableBuilder(
    column: $table.panelSimNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get autoArmTime => $composableBuilder(
    column: $table.autoArmTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get autoDisarmTime => $composableBuilder(
    column: $table.autoDisarmTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get holidayTime => $composableBuilder(
    column: $table.holidayTime,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isArmToggled => $composableBuilder(
    column: $table.isArmToggled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDisarmToggled => $composableBuilder(
    column: $table.isDisarmToggled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isHolidayToggled => $composableBuilder(
    column: $table.isHolidayToggled,
    builder: (column) => column,
  );
}

class $$AutomationTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AutomationTableTable,
          AutomationTableData,
          $$AutomationTableTableFilterComposer,
          $$AutomationTableTableOrderingComposer,
          $$AutomationTableTableAnnotationComposer,
          $$AutomationTableTableCreateCompanionBuilder,
          $$AutomationTableTableUpdateCompanionBuilder,
          (
            AutomationTableData,
            BaseReferences<
              _$AppDatabase,
              $AutomationTableTable,
              AutomationTableData
            >,
          ),
          AutomationTableData,
          PrefetchHooks Function()
        > {
  $$AutomationTableTableTableManager(
    _$AppDatabase db,
    $AutomationTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$AutomationTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$AutomationTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$AutomationTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> panelSimNumber = const Value.absent(),
                Value<String?> autoArmTime = const Value.absent(),
                Value<String?> autoDisarmTime = const Value.absent(),
                Value<String?> holidayTime = const Value.absent(),
                Value<bool> isArmToggled = const Value.absent(),
                Value<bool> isDisarmToggled = const Value.absent(),
                Value<bool> isHolidayToggled = const Value.absent(),
              }) => AutomationTableCompanion(
                id: id,
                panelSimNumber: panelSimNumber,
                autoArmTime: autoArmTime,
                autoDisarmTime: autoDisarmTime,
                holidayTime: holidayTime,
                isArmToggled: isArmToggled,
                isDisarmToggled: isDisarmToggled,
                isHolidayToggled: isHolidayToggled,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String panelSimNumber,
                Value<String?> autoArmTime = const Value.absent(),
                Value<String?> autoDisarmTime = const Value.absent(),
                Value<String?> holidayTime = const Value.absent(),
                Value<bool> isArmToggled = const Value.absent(),
                Value<bool> isDisarmToggled = const Value.absent(),
                Value<bool> isHolidayToggled = const Value.absent(),
              }) => AutomationTableCompanion.insert(
                id: id,
                panelSimNumber: panelSimNumber,
                autoArmTime: autoArmTime,
                autoDisarmTime: autoDisarmTime,
                holidayTime: holidayTime,
                isArmToggled: isArmToggled,
                isDisarmToggled: isDisarmToggled,
                isHolidayToggled: isHolidayToggled,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AutomationTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AutomationTableTable,
      AutomationTableData,
      $$AutomationTableTableFilterComposer,
      $$AutomationTableTableOrderingComposer,
      $$AutomationTableTableAnnotationComposer,
      $$AutomationTableTableCreateCompanionBuilder,
      $$AutomationTableTableUpdateCompanionBuilder,
      (
        AutomationTableData,
        BaseReferences<
          _$AppDatabase,
          $AutomationTableTable,
          AutomationTableData
        >,
      ),
      AutomationTableData,
      PrefetchHooks Function()
    >;
typedef $$ComplaintTableTableCreateCompanionBuilder =
    ComplaintTableCompanion Function({
      Value<int> id,
      required String subject,
      required String remark,
      required String cOn,
      required String siteName,
      required String userId,
      Value<String?> image1Path,
      Value<String?> image2Path,
      Value<String?> image3Path,
    });
typedef $$ComplaintTableTableUpdateCompanionBuilder =
    ComplaintTableCompanion Function({
      Value<int> id,
      Value<String> subject,
      Value<String> remark,
      Value<String> cOn,
      Value<String> siteName,
      Value<String> userId,
      Value<String?> image1Path,
      Value<String?> image2Path,
      Value<String?> image3Path,
    });

class $$ComplaintTableTableFilterComposer
    extends Composer<_$AppDatabase, $ComplaintTableTable> {
  $$ComplaintTableTableFilterComposer({
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

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remark => $composableBuilder(
    column: $table.remark,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cOn => $composableBuilder(
    column: $table.cOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get siteName => $composableBuilder(
    column: $table.siteName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get image1Path => $composableBuilder(
    column: $table.image1Path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get image2Path => $composableBuilder(
    column: $table.image2Path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get image3Path => $composableBuilder(
    column: $table.image3Path,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ComplaintTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ComplaintTableTable> {
  $$ComplaintTableTableOrderingComposer({
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

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remark => $composableBuilder(
    column: $table.remark,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cOn => $composableBuilder(
    column: $table.cOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get siteName => $composableBuilder(
    column: $table.siteName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get image1Path => $composableBuilder(
    column: $table.image1Path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get image2Path => $composableBuilder(
    column: $table.image2Path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get image3Path => $composableBuilder(
    column: $table.image3Path,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ComplaintTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ComplaintTableTable> {
  $$ComplaintTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get remark =>
      $composableBuilder(column: $table.remark, builder: (column) => column);

  GeneratedColumn<String> get cOn =>
      $composableBuilder(column: $table.cOn, builder: (column) => column);

  GeneratedColumn<String> get siteName =>
      $composableBuilder(column: $table.siteName, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get image1Path => $composableBuilder(
    column: $table.image1Path,
    builder: (column) => column,
  );

  GeneratedColumn<String> get image2Path => $composableBuilder(
    column: $table.image2Path,
    builder: (column) => column,
  );

  GeneratedColumn<String> get image3Path => $composableBuilder(
    column: $table.image3Path,
    builder: (column) => column,
  );
}

class $$ComplaintTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ComplaintTableTable,
          ComplaintTableData,
          $$ComplaintTableTableFilterComposer,
          $$ComplaintTableTableOrderingComposer,
          $$ComplaintTableTableAnnotationComposer,
          $$ComplaintTableTableCreateCompanionBuilder,
          $$ComplaintTableTableUpdateCompanionBuilder,
          (
            ComplaintTableData,
            BaseReferences<
              _$AppDatabase,
              $ComplaintTableTable,
              ComplaintTableData
            >,
          ),
          ComplaintTableData,
          PrefetchHooks Function()
        > {
  $$ComplaintTableTableTableManager(
    _$AppDatabase db,
    $ComplaintTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ComplaintTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$ComplaintTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$ComplaintTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String> remark = const Value.absent(),
                Value<String> cOn = const Value.absent(),
                Value<String> siteName = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> image1Path = const Value.absent(),
                Value<String?> image2Path = const Value.absent(),
                Value<String?> image3Path = const Value.absent(),
              }) => ComplaintTableCompanion(
                id: id,
                subject: subject,
                remark: remark,
                cOn: cOn,
                siteName: siteName,
                userId: userId,
                image1Path: image1Path,
                image2Path: image2Path,
                image3Path: image3Path,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String subject,
                required String remark,
                required String cOn,
                required String siteName,
                required String userId,
                Value<String?> image1Path = const Value.absent(),
                Value<String?> image2Path = const Value.absent(),
                Value<String?> image3Path = const Value.absent(),
              }) => ComplaintTableCompanion.insert(
                id: id,
                subject: subject,
                remark: remark,
                cOn: cOn,
                siteName: siteName,
                userId: userId,
                image1Path: image1Path,
                image2Path: image2Path,
                image3Path: image3Path,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ComplaintTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ComplaintTableTable,
      ComplaintTableData,
      $$ComplaintTableTableFilterComposer,
      $$ComplaintTableTableOrderingComposer,
      $$ComplaintTableTableAnnotationComposer,
      $$ComplaintTableTableCreateCompanionBuilder,
      $$ComplaintTableTableUpdateCompanionBuilder,
      (
        ComplaintTableData,
        BaseReferences<_$AppDatabase, $ComplaintTableTable, ComplaintTableData>,
      ),
      ComplaintTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UserTableTableManager get user => $$UserTableTableManager(_db, _db.user);
  $$PanelTableTableManager get panel =>
      $$PanelTableTableManager(_db, _db.panel);
  $$VendorTableTableManager get vendor =>
      $$VendorTableTableManager(_db, _db.vendor);
  $$IntrusionNumbersTableTableManager get intrusionNumbers =>
      $$IntrusionNumbersTableTableManager(_db, _db.intrusionNumbers);
  $$FireNumbersTableTableManager get fireNumbers =>
      $$FireNumbersTableTableManager(_db, _db.fireNumbers);
  $$TimerTableTableTableManager get timerTable =>
      $$TimerTableTableTableManager(_db, _db.timerTable);
  $$AutomationTableTableTableManager get automationTable =>
      $$AutomationTableTableTableManager(_db, _db.automationTable);
  $$ComplaintTableTableTableManager get complaintTable =>
      $$ComplaintTableTableTableManager(_db, _db.complaintTable);
}
