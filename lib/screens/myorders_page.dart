import 'package:flutter/material.dart';

// ------------------ MODELS ------------------
class OrderModel {
  final String serviceName;
  final String date;
  final String time;
  final String address;
  final String status;
  final int amount;

  OrderModel({
    required this.serviceName,
    required this.date,
    required this.time,
    required this.address,
    required this.status,
    required this.amount,
  });
}

// ------------------ DUMMY DATA ------------------
final List<OrderModel> orders = [
  OrderModel(
    serviceName: 'Plumbing Service',
    date: '15 Dec 2025',
    time: '02:00 PM',
    address: 'Bandra West, Mumbai',
    status: 'Ongoing',
    amount: 599,
  ),
  OrderModel(
    serviceName: 'Home Cleaning',
    date: '18 Dec 2025',
    time: '09:00 AM',
    address: 'Powai, Mumbai',
    status: 'Cancelled',
    amount: 999,
  ),
  OrderModel(
    serviceName: 'Electrician Service',
    date: '12 Dec 2025',
    time: '10:00 AM',
    address: 'Andheri East, Mumbai',
    status: 'Completed',
    amount: 799,
  ),
];

// ------------------ PAGE ------------------
class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Make sure AppDrawer exists
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        title: const Text(
          'My Orders',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _orderCard(order);
        },
      ),
    );
  }

  Widget _orderCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  order.serviceName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _statusChip(order.status),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.calendar_today, order.date),
          _infoRow(Icons.access_time, order.time),
          _infoRow(Icons.location_on, order.address),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹ ${order.amount}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'Completed':
        color = Colors.green;
        break;
      case 'Cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
