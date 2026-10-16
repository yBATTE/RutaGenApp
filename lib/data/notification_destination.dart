class NotificationDestination {
  const NotificationDestination({required this.action, this.giftId});
  final String action;
  final String? giftId;

  factory NotificationDestination.fromData(Map<String, dynamic> data) {
    final action = (data['destination'] ?? data['action'] ?? 'NOTIFICATIONS').toString().trim().toUpperCase();
    final id = data['giftId']?.toString().trim();
    return NotificationDestination(action: action.isEmpty ? 'NOTIFICATIONS' : action,
      giftId: id == null || id.isEmpty ? null : id);
  }
}
