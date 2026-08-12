import 'package:flutter/material.dart';

enum MovementType {
  load,
  redemption,
}

class Customer {
  const Customer({
    required this.firstName,
    required this.lastName,
    required this.memberCode,
    required this.points,
  });

  final String firstName;
  final String lastName;
  final String memberCode;
  final int points;

  String get initials {
    final first = firstName.trim().isNotEmpty ? firstName.trim()[0] : '';

    final last = lastName.trim().isNotEmpty ? lastName.trim()[0] : '';

    return '$first$last'.toUpperCase();
  }
}

class TemporaryQr {
  const TemporaryQr({
    required this.qrToken,
    required this.expiresAt,
    required this.expiresInSeconds,
  });

  final String qrToken;
  final DateTime expiresAt;
  final int expiresInSeconds;
}

class Reward {
  const Reward({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.points,
    required this.stock,
    required this.icon,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String subtitle;
  final int points;
  final int stock;
  final IconData icon;
  final String? imageUrl;

  bool get hasStock => stock > 0;
}

class Movement {
  const Movement({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.points,
    required this.type,
    this.stationName,
    this.productName,
    this.liters,
    this.amount,
    this.pricePerLiter,
  });

  final String id;
  final String title;
  final String subtitle;
  final DateTime date;
  final int points;
  final MovementType type;

  final String? stationName;
  final String? productName;
  final double? liters;
  final double? amount;
  final double? pricePerLiter;
}

class NewsItem {
  const NewsItem({
    required this.id,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.title,
    this.description,
    this.publishedAt,
  });

  final String id;
  final String? title;
  final String? description;

  /*
   * Imagen original.
   * Se utiliza en la pantalla de detalle.
   */
  final String imageUrl;

  /*
   * Imagen reducida.
   * Se utiliza en las tarjetas del Home.
   */
  final String thumbnailUrl;

  final String status;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayTitle {
    final value = title?.trim() ?? '';

    return value.isEmpty ? 'Novedad Ruta Gen' : value;
  }

  bool get hasDescription {
    return description?.trim().isNotEmpty ?? false;
  }

  DateTime get displayDate {
    return publishedAt ?? createdAt;
  }
}

class Station {
  const Station({
    required this.name,
    required this.address,
    required this.distance,
    this.isFavorite = false,
  });

  final String name;
  final String address;
  final String distance;
  final bool isFavorite;
}
