import 'package:flutter/material.dart';

enum MovementType {
  load,
  redemption,
  gift,
  visitBonus,
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

class GiftReward {
  const GiftReward({
    required this.id,
    required this.giftCode,
    required this.source,
    required this.status,
    required this.rewardName,
    required this.rewardDescription,
    required this.issuedAt,
    this.qrToken,
    this.rewardImageUrl,
    this.campaignName,
    this.reservationStationName,
    this.expiresAt,
    this.redeemedAt,
    this.redeemedStationName,
  });

  final String id;
  final String giftCode;
  final String? qrToken;
  final String source;
  final String status;
  final String rewardName;
  final String rewardDescription;
  final String? rewardImageUrl;
  final String? campaignName;
  final String? reservationStationName;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final DateTime? redeemedAt;
  final String? redeemedStationName;

  bool get isAvailable => status.toUpperCase() == 'AVAILABLE';
  bool get isRedeemed => status.toUpperCase() == 'REDEEMED';
  bool get isExpired => status.toUpperCase() == 'EXPIRED';
  bool get isCancelled => status.toUpperCase() == 'CANCELLED';

  bool get canShowQr =>
      isAvailable && qrToken != null && qrToken!.trim().isNotEmpty;

  String get sourceLabel {
    switch (source.toUpperCase()) {
      case 'VISIT_BONUS':
        return 'Beneficio por visitas';
      case 'WELCOME':
        return 'Premio de bienvenida';
      case 'RANDOM':
        return campaignName?.trim().isNotEmpty == true
            ? campaignName!.trim()
            : 'Premio sorpresa';
      case 'MANUAL_ADMIN':
        return 'Regalo Ruta GEN';
      case 'SYSTEM':
        return 'Beneficio Ruta GEN';
      default:
        return 'Premio regalado';
    }
  }

  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return 'Disponible';
      case 'REDEEMED':
        return 'Canjeado';
      case 'EXPIRED':
        return 'Vencido';
      case 'CANCELLED':
        return 'Cancelado';
      default:
        return status;
    }
  }
}

class VisitStation {
  const VisitStation({
    required this.slug,
    required this.name,
  });

  final String slug;
  final String name;
}

class VisitProgress {
  const VisitProgress({
    required this.monthKey,
    required this.visitedStations,
    required this.stationCount,
    required this.enabled,
    required this.secondStationStatus,
    required this.thirdStationStatus,
    required this.remainingForBreakfast,
    required this.remainingForMeal,
    this.secondStationRewardName,
    this.thirdStationRewardName,
  });

  final String monthKey;
  final List<VisitStation> visitedStations;
  final int stationCount;
  final bool enabled;
  final String secondStationStatus;
  final String thirdStationStatus;
  final int remainingForBreakfast;
  final int remainingForMeal;
  final String? secondStationRewardName;
  final String? thirdStationRewardName;

  bool get breakfastUnlocked =>
      secondStationStatus.toUpperCase() == 'ISSUED';

  bool get mealUnlocked =>
      thirdStationStatus.toUpperCase() == 'ISSUED';
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

  bool get isGift =>
      type == MovementType.gift || type == MovementType.visitBonus;
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

  final String imageUrl;
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
