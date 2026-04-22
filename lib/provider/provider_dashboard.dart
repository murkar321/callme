import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessDashboardPage extends StatelessWidget {
  final String businessName;
  final String categoryRoute;

  const BusinessDashboardPage({
    super.key,
    required this.businessName,
    required this.categoryRoute,
  });

  /// 🔥 Firestore refs
  CollectionReference get requestRef =>
      FirebaseFirestore.instance.collection('requests');

  CollectionReference get notificationRef =>
      FirebaseFirestore.instance.collection('notifications');

  CollectionReference get categoryRef =>
      FirebaseFirestore.instance.collection('categories');

  /// 🔹 Requests for this provider category
  Stream<QuerySnapshot> getRequests() {
    return requestRef
        .where('service', isEqualTo: categoryRoute)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// 🔹 Services
  Stream<QuerySnapshot> getServices() {
    return categoryRef
        .doc(categoryRoute)
        .collection('services')
        .snapshots();
  }

  /// 🔹 Accept Request
  Future<void> acceptRequest(String id, String userName) async {
    await requestRef.doc(id).update({"status": "accepted"});

    await notificationRef.add({
      "message": "Your booking has been ACCEPTED ✅",
      "userName": userName,
      "service": categoryRoute,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  /// 🔹 Reject Request
  Future<void> rejectRequest(String id, String userName) async {
    await requestRef.doc(id).update({"status": "rejected"});

    await notificationRef.add({
      "message": "Your booking was REJECTED ❌",
      "userName": userName,
      "service": categoryRoute,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$categoryRoute Dashboard"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔹 Welcome
            _welcomeCard(),

            const SizedBox(height: 20),

            /// 🔥 INCOMING REQUESTS (MAIN FEATURE)
            const Text(
              "Incoming Requests",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: getRequests(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Text("No requests yet");
                }

                return Column(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(data['userName'] ?? 'User'),
                        subtitle: Text(
                          "Service: ${data['service']}\nStatus: ${data['status']}",
                        ),

                        /// 🔥 ACTION BUTTONS
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [

                            /// ACCEPT
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: data['status'] == 'pending'
                                  ? () => acceptRequest(
                                        doc.id,
                                        data['userName'],
                                      )
                                  : null,
                            ),

                            /// REJECT
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: data['status'] == 'pending'
                                  ? () => rejectRequest(
                                        doc.id,
                                        data['userName'],
                                      )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            /// 🔹 SERVICES LIST
            const Text(
              "Your Services",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: getServices(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final services = snapshot.data!.docs;

                if (services.isEmpty) {
                  return const Text("No services added");
                }

                return Column(
                  children: services.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.design_services),
                        title: Text(data['name'] ?? ''),
                        subtitle: Text("₹${data['price'] ?? 0}"),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 UI widgets
  Widget _welcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.blue.shade50,
      ),
      child: Text(
        "Welcome, $businessName 👋\nManage your bookings here.",
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}