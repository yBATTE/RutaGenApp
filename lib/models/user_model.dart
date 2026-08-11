class UserModel {
  const UserModel({
    required this.id,
    required this.role,
    required this.status,
    required this.firstName,
    required this.lastName,
    required this.dni,
    required this.email,
    required this.pointsBalance,
    required this.lifetimePointsEarned,
    required this.lifetimePointsRedeemed,
    required this.emailVerified,
    required this.phoneVerified,
    this.phone,
    this.memberCode,
    this.stationSlug,
    this.stationName,
    this.qrVersion,
    this.qrCreatedAt,
    this.acceptedTermsAt,
    this.lastLoginAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String role;
  final String status;

  final String firstName;
  final String lastName;
  final String dni;
  final String email;
  final String? phone;

  final String? memberCode;
  final String? stationSlug;
  final String? stationName;

  final double pointsBalance;
  final double lifetimePointsEarned;
  final double lifetimePointsRedeemed;

  final int? qrVersion;

  final bool emailVerified;
  final bool phoneVerified;

  final DateTime? qrCreatedAt;
  final DateTime? acceptedTermsAt;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /* ============================================================
     DATOS CALCULADOS
  ============================================================ */

  String get fullName {
    return '$firstName $lastName'.trim();
  }

  String get initials {
    final firstInitial = firstName.trim().isNotEmpty
        ? firstName.trim()[0].toUpperCase()
        : '';

    final lastInitial = lastName.trim().isNotEmpty
        ? lastName.trim()[0].toUpperCase()
        : '';

    return '$firstInitial$lastInitial';
  }

  bool get isCustomer => role.toUpperCase() == 'CUSTOMER';

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  bool get isBlocked => status.toUpperCase() == 'BLOCKED';

  bool get isDisabled => status.toUpperCase() == 'DISABLED';

  bool get hasStation {
    return stationSlug != null && stationSlug!.trim().isNotEmpty;
  }

  bool get hasMemberCode {
    return memberCode != null && memberCode!.trim().isNotEmpty;
  }

  int get pointsBalanceAsInt => pointsBalance.round();

  int get lifetimePointsEarnedAsInt {
    return lifetimePointsEarned.round();
  }

  int get lifetimePointsRedeemedAsInt {
    return lifetimePointsRedeemed.round();
  }

  /* ============================================================
     CREAR MODELO DESDE LA RESPUESTA DEL BACKEND
  ============================================================ */

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _readId(json),
      role: _readString(
        json['role'],
        fallback: 'CUSTOMER',
      ),
      status: _readString(
        json['status'],
        fallback: 'ACTIVE',
      ),
      firstName: _readString(json['firstName']),
      lastName: _readString(json['lastName']),
      dni: _readString(json['dni']),
      email: _readString(json['email']),
      phone: _readNullableString(json['phone']),
      memberCode: _readNullableString(json['memberCode']),
      stationSlug: _readNullableString(json['stationSlug']),
      stationName: _readNullableString(json['stationName']),
      pointsBalance: _readDouble(json['pointsBalance']),
      lifetimePointsEarned: _readDouble(
        json['lifetimePointsEarned'],
      ),
      lifetimePointsRedeemed: _readDouble(
        json['lifetimePointsRedeemed'],
      ),
      qrVersion: _readNullableInt(json['qrVersion']),
      emailVerified: _readBool(json['emailVerified']),
      phoneVerified: _readBool(json['phoneVerified']),
      qrCreatedAt: _readDate(json['qrCreatedAt']),
      acceptedTermsAt: _readDate(json['acceptedTermsAt']),
      lastLoginAt: _readDate(json['lastLoginAt']),
      createdAt: _readDate(json['createdAt']),
      updatedAt: _readDate(json['updatedAt']),
    );
  }

  /* ============================================================
     CONVERTIR MODELO A MAPA
  ============================================================ */

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'status': status,
      'firstName': firstName,
      'lastName': lastName,
      'dni': dni,
      'email': email,
      'phone': phone,
      'memberCode': memberCode,
      'stationSlug': stationSlug,
      'stationName': stationName,
      'pointsBalance': pointsBalance,
      'lifetimePointsEarned': lifetimePointsEarned,
      'lifetimePointsRedeemed': lifetimePointsRedeemed,
      'qrVersion': qrVersion,
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'qrCreatedAt': qrCreatedAt?.toIso8601String(),
      'acceptedTermsAt': acceptedTermsAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /* ============================================================
     CREAR UNA COPIA CON CAMPOS MODIFICADOS
  ============================================================ */

  UserModel copyWith({
    String? id,
    String? role,
    String? status,
    String? firstName,
    String? lastName,
    String? dni,
    String? email,
    String? phone,
    String? memberCode,
    String? stationSlug,
    String? stationName,
    double? pointsBalance,
    double? lifetimePointsEarned,
    double? lifetimePointsRedeemed,
    int? qrVersion,
    bool? emailVerified,
    bool? phoneVerified,
    DateTime? qrCreatedAt,
    DateTime? acceptedTermsAt,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      role: role ?? this.role,
      status: status ?? this.status,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dni: dni ?? this.dni,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      memberCode: memberCode ?? this.memberCode,
      stationSlug: stationSlug ?? this.stationSlug,
      stationName: stationName ?? this.stationName,
      pointsBalance: pointsBalance ?? this.pointsBalance,
      lifetimePointsEarned:
          lifetimePointsEarned ?? this.lifetimePointsEarned,
      lifetimePointsRedeemed:
          lifetimePointsRedeemed ?? this.lifetimePointsRedeemed,
      qrVersion: qrVersion ?? this.qrVersion,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      qrCreatedAt: qrCreatedAt ?? this.qrCreatedAt,
      acceptedTermsAt:
          acceptedTermsAt ?? this.acceptedTermsAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /* ============================================================
     FUNCIONES INTERNAS DE CONVERSIÓN
  ============================================================ */

  static String _readId(Map<String, dynamic> json) {
    final value = json['id'] ?? json['_id'];

    if (value is String) {
      return value;
    }

    if (value is Map<String, dynamic>) {
      final oid = value[r'$oid'];

      if (oid is String) {
        return oid;
      }
    }

    return value?.toString() ?? '';
  }

  static String _readString(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    final result = value.toString().trim();

    return result.isEmpty ? fallback : result;
  }

  static String? _readNullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final result = value.toString().trim();

    return result.isEmpty ? null : result;
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(
            value.trim().replaceAll(',', '.'),
          ) ??
          0;
    }

    if (value is Map<String, dynamic>) {
      final decimalValue = value[r'$numberDecimal'];
      final intValue = value[r'$numberInt'];
      final longValue = value[r'$numberLong'];

      return double.tryParse(
            (decimalValue ?? intValue ?? longValue ?? '0')
                .toString(),
          ) ??
          0;
    }

    return 0;
  }

  static int? _readNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    if (value is Map<String, dynamic>) {
      final number =
          value[r'$numberInt'] ?? value[r'$numberLong'];

      return int.tryParse(number?.toString() ?? '');
    }

    return null;
  }

  static bool _readBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }

    return false;
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    if (value is Map<String, dynamic>) {
      final dateValue = value[r'$date'];

      if (dateValue is String) {
        return DateTime.tryParse(dateValue);
      }

      if (dateValue is int) {
        return DateTime.fromMillisecondsSinceEpoch(dateValue);
      }

      if (dateValue is Map<String, dynamic>) {
        final milliseconds = dateValue[r'$numberLong'];

        if (milliseconds != null) {
          final parsedMilliseconds = int.tryParse(
            milliseconds.toString(),
          );

          if (parsedMilliseconds != null) {
            return DateTime.fromMillisecondsSinceEpoch(
              parsedMilliseconds,
            );
          }
        }
      }
    }

    return null;
  }

  @override
  String toString() {
    return 'UserModel('
        'id: $id, '
        'fullName: $fullName, '
        'dni: $dni, '
        'role: $role, '
        'status: $status, '
        'pointsBalance: $pointsBalance'
        ')';
  }
}