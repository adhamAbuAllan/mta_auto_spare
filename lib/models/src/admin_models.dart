import 'json_utils.dart';

class AdminDashboardSummary {
  const AdminDashboardSummary({
    required this.usersTotal,
    required this.usersActive,
    required this.usersBlocked,
    required this.suppliersTotal,
    required this.reportsOpen,
    required this.reportsTotal,
    required this.requestsTotal,
    required this.conversationsTotal,
    required this.messagesTotal,
    required this.sparePartsTotal,
    required this.carMakesTotal,
    required this.carModelsTotal,
    required this.subscriptionsActive,
    required this.paymentsPending,
  });

  final int usersTotal;
  final int usersActive;
  final int usersBlocked;
  final int suppliersTotal;
  final int reportsOpen;
  final int reportsTotal;
  final int requestsTotal;
  final int conversationsTotal;
  final int messagesTotal;
  final int sparePartsTotal;
  final int carMakesTotal;
  final int carModelsTotal;
  final int subscriptionsActive;
  final int paymentsPending;

  factory AdminDashboardSummary.fromJson(JsonMap json) {
    int count(String key) => intFromJson(json[key]) ?? 0;

    return AdminDashboardSummary(
      usersTotal: count('users_total'),
      usersActive: count('users_active'),
      usersBlocked: count('users_blocked'),
      suppliersTotal: count('suppliers_total'),
      reportsOpen: count('reports_open'),
      reportsTotal: count('reports_total'),
      requestsTotal: count('requests_total'),
      conversationsTotal: count('conversations_total'),
      messagesTotal: count('messages_total'),
      sparePartsTotal: count('spare_parts_total'),
      carMakesTotal: count('car_makes_total'),
      carModelsTotal: count('car_models_total'),
      subscriptionsActive: count('subscriptions_active'),
      paymentsPending: count('payments_pending'),
    );
  }
}
