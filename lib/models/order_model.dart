class OrderModel {
  final String id;
  final List<String> services;
  final DateTime date;
  final String time;
  final String address;
  final String note;
  String status;
  final double totalAmount;

  OrderModel({
    required this.id,
    required this.services,
    required this.date,
    required this.time,
    required this.address,
    required this.note,
    required this.status,
    required this.totalAmount,
  });
}


/* ------------------ Dummy Orders ------------------
final List<OrderModel> dummyOrders = [
  OrderModel(
    id: 'ORD001',
    services: ['Electrician Service', 'Fan Installation'],
    date: DateTime(2025, 12, 12),
    time: '10:00 AM',
    address: 'Andheri East, Mumbai',
    note: 'Customer prefers morning slot.',
    status: 'Completed',
    totalAmount: 799.0,
  ),
  OrderModel(
    id: 'ORD002',
    services: ['Plumbing Service'],
    date: DateTime(2025, 12, 15),
    time: '02:00 PM',
    address: 'Bandra West, Mumbai',
    note: 'Fix kitchen sink leak.',
    status: 'Ongoing',
    totalAmount: 599.0,
  ),
  OrderModel(
    id: 'ORD003',
    services: ['Home Cleaning', 'Bathroom Sanitization'],
    date: DateTime(2025, 12, 18),
    time: '09:00 AM',
    address: 'Powai, Mumbai',
    note: 'Cancelled due to scheduling issue.',
    status: 'Cancelled',
    totalAmount: 999.0,
  ),
];*/
