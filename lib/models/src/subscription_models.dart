import 'json_utils.dart';

class PlanModel {
  const PlanModel({
    this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.interval,
    required this.isActive,
    this.createdAt,
  });

  final int? id;
  final String name;
  final String price;
  final String currency;
  final String interval;
  final bool isActive;
  final DateTime? createdAt;

  factory PlanModel.fromJson(JsonMap json) {
    return PlanModel(
      id: intFromJson(json['id']),
      name: stringFromJson(json['name']) ?? '',
      price: stringFromJson(json['price']) ?? '',
      currency: stringFromJson(json['currency']) ?? '',
      interval: stringFromJson(json['interval']) ?? '',
      isActive: boolFromJson(json['is_active']) ?? false,
      createdAt: dateTimeFromJson(json['created_at']),
    );
  }

  JsonMap toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'currency': currency,
      'interval': interval,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class SubscriptionModel {
  const SubscriptionModel({
    this.id,
    required this.user,
    required this.plan,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.autoRenew,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int user;
  final int plan;
  final String status;
  final DateTime startDate;
  final DateTime? endDate;
  final bool autoRenew;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SubscriptionModel.fromJson(JsonMap json) {
    return SubscriptionModel(
      id: intFromJson(json['id']),
      user: intFromJson(json['user']) ?? 0,
      plan: intFromJson(json['plan']) ?? 0,
      status: stringFromJson(json['status']) ?? '',
      startDate: dateTimeFromJson(json['start_date']) ?? DateTime.now(),
      endDate: dateTimeFromJson(json['end_date']),
      autoRenew: boolFromJson(json['auto_renew']) ?? false,
      createdAt: dateTimeFromJson(json['created_at']),
      updatedAt: dateTimeFromJson(json['updated_at']),
    );
  }

  JsonMap toJson() {
    return {
      'id': id,
      'user': user,
      'plan': plan,
      'status': status,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'auto_renew': autoRenew,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class PaymentModel {
  const PaymentModel({
    this.id,
    required this.subscription,
    required this.amount,
    required this.currency,
    required this.status,
    this.provider,
    this.transactionId,
    this.paidAt,
    this.createdAt,
  });

  final int? id;
  final int subscription;
  final String amount;
  final String currency;
  final String status;
  final String? provider;
  final String? transactionId;
  final DateTime? paidAt;
  final DateTime? createdAt;

  factory PaymentModel.fromJson(JsonMap json) {
    return PaymentModel(
      id: intFromJson(json['id']),
      subscription: intFromJson(json['subscription']) ?? 0,
      amount: stringFromJson(json['amount']) ?? '',
      currency: stringFromJson(json['currency']) ?? '',
      status: stringFromJson(json['status']) ?? '',
      provider: stringFromJson(json['provider']),
      transactionId: stringFromJson(json['transaction_id']),
      paidAt: dateTimeFromJson(json['paid_at']),
      createdAt: dateTimeFromJson(json['created_at']),
    );
  }

  JsonMap toJson() {
    return {
      'id': id,
      'subscription': subscription,
      'amount': amount,
      'currency': currency,
      'status': status,
      'provider': provider,
      'transaction_id': transactionId,
      'paid_at': paidAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
