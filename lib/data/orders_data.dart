import 'package:callme/models/order_model.dart';

class OrdersData {
  // ✅ Global list to store all orders (including booked ones)
  static final List<OrderModel> orders = [
    // Optional: Add a few dummy example orders for testing
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
      services: ['Home Cleaning'],
      date: DateTime(2025, 12, 18),
      time: '09:00 AM',
      address: 'Powai, Mumbai',
      note: 'Cancelled by user due to schedule clash.',
      status: 'Cancelled',
      totalAmount: 999.0,
    ),
    OrderModel(
      id: 'ORD004',
      services: ['Electrician Service', 'Fan Installation'],
      date: DateTime(2025, 12, 12),
      time: '10:00 AM',
      address: 'Andheri East, Mumbai',
      note: 'Customer prefers morning slot.',
      status: 'Completed',
      totalAmount: 799.0,
    ),
    OrderModel(
      id: 'ORD005',
      services: ['Plumbing Service'],
      date: DateTime(2025, 12, 15),
      time: '02:00 PM',
      address: 'Bandra West, Mumbai',
      note: 'Fix kitchen sink leak.',
      status: 'Ongoing',
      totalAmount: 599.0,
    ),
    OrderModel(
      id: 'ORD006',
      services: ['Home Cleaning'],
      date: DateTime(2025, 12, 18),
      time: '09:00 AM',
      address: 'Powai, Mumbai',
      note: 'Cancelled by user due to schedule clash.',
      status: 'Cancelled',
      totalAmount: 999.0,
    ),
  ];
}
