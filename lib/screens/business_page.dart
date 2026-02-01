import 'package:flutter/material.dart';
import 'package:callme/models/order_model.dart';
import 'package:callme/data/orders_data.dart';

class BusinessPage extends StatefulWidget {
  const BusinessPage({super.key});

  @override
  State<BusinessPage> createState() => _BusinessPageState();
}

class _BusinessPageState extends State<BusinessPage> {
  String selectedFilter = "All"; // ✅ default view

  @override
  Widget build(BuildContext context) {
    final allOrders = [...OrdersData.orders];

    final totalOrders = allOrders.length;
    final completedOrders =
        allOrders.where((o) => o.status == 'Completed').toList();

    // ✅ Include both Pending and Ongoing orders as Active
    final activeOrders = allOrders
        .where((o) => o.status == 'Pending' || o.status == 'Ongoing')
        .toList();

    final totalRevenue =
        allOrders.fold<double>(0, (sum, o) => sum + o.totalAmount);

    // ✅ filter logic
    List<OrderModel> filteredOrders;
    switch (selectedFilter) {
      case 'Completed':
        filteredOrders = completedOrders;
        break;
      case 'Active':
        filteredOrders = activeOrders;
        break;
      default:
        filteredOrders = allOrders;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Business"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF5F7FB),
      body: allOrders.isEmpty
          ? const Center(
              child: Text(
                'No customer orders yet',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : Column(
              children: [
                // ✅ Clickable summary dashboard
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _summaryCard(
                        title: 'Total Orders',
                        value: totalOrders.toString(),
                        color: Colors.blue,
                        filter: 'All',
                      ),
                      _summaryCard(
                        title: 'Completed',
                        value: completedOrders.length.toString(),
                        color: Colors.green,
                        filter: 'Completed',
                      ),
                      _summaryCard(
                        title: 'Active',
                        value: activeOrders.length.toString(),
                        color: Colors.orange,
                        filter: 'Active',
                      ),
                      _summaryCard(
                        title: 'Revenue',
                        value: '₹${totalRevenue.toStringAsFixed(0)}',
                        color: Colors.purple,
                        filter: 'All',
                      ),
                    ],
                  ),
                ),

                Divider(thickness: 1, color: Colors.grey.shade300),

                // ✅ Display filtered orders
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return _businessOrderCard(order);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  /// ✅ Summary card now clickable
  Widget _summaryCard({
    required String title,
    required String value,
    required Color color,
    required String filter,
  }) {
    final isSelected = selectedFilter == filter;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedFilter = filter;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _businessOrderCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.services.join(', '),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Customer Address: ${order.address}'),
          Text('Date: ${order.date.day}/${order.date.month}/${order.date.year}'),
          Text('Time: ${order.time}'),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statusBadge(order.status),
              DropdownButton<String>(
                value: _validStatus(order.status),
                underline: const SizedBox(),
                icon: const Icon(Icons.edit, color: Colors.blue),
                onChanged: (newStatus) {
                  setState(() {
                    order.status = newStatus!;
                  });
                },
                items: const [
                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'Ongoing', child: Text('Ongoing')),
                  DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Amount: ₹${order.totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _validStatus(String status) {
    const validStatuses = ['Pending', 'Ongoing', 'Completed', 'Cancelled'];
    if (validStatuses.contains(status)) return status;
    return 'Pending';
  }

  Widget _statusBadge(String status) {
    Color bgColor;
    switch (status) {
      case 'Completed':
        bgColor = Colors.green;
        break;
      case 'Ongoing':
        bgColor = Colors.blue;
        break;
      case 'Pending':
        bgColor = Colors.orange;
        break;
      case 'Cancelled':
        bgColor = Colors.red;
        break;
      default:
        bgColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}
