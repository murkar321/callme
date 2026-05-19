import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'approve_providers_page.dart';
import 'orders_detail.dart';
import 'providers_details.dart';
import 'users_details.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() =>
      _AdminDashboardState();
}

class _AdminDashboardState
    extends State<AdminDashboard> {

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  bool isLoading = true;

  Map<String, dynamic> dashboardData = {

    "users": 0,
    "providers": 0,
    "orders": 0,
    "approvals": 0,

    "pending": 0,
    "accepted": 0,
    "completed": 0,
    "rejected": 0,
  };

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  /// ================= LOAD DASHBOARD =================
  Future<void> loadDashboard() async {

    try {

      setState(() {
        isLoading = true;
      });

      /// USERS COUNT
      final usersSnapshot =
          await firestore
              .collection("users")
              .count()
              .get();

      /// PROVIDERS COUNT
      final providersSnapshot =
          await firestore
              .collection("providers")
              .count()
              .get();

      /// APPROVALS COUNT
      final approvalsSnapshot =
          await firestore
              .collection("providers")
              .where(
                "status",
                isEqualTo: "pending",
              )
              .count()
              .get();

      /// ORDERS
      final ordersSnapshot =
          await firestore
              .collection("orders")
              .get();

      int pending = 0;
      int accepted = 0;
      int completed = 0;
      int rejected = 0;

      for (var doc in ordersSnapshot.docs) {

        final data = doc.data();

        final status =
            (data['status'] ?? "pending")
                .toString()
                .toLowerCase();

        switch (status) {

          case "accepted":
            accepted++;
            break;

          case "completed":
            completed++;
            break;

          case "rejected":
            rejected++;
            break;

          default:
            pending++;
        }
      }

      dashboardData = {

        "users":
            usersSnapshot.count ?? 0,

        "providers":
            providersSnapshot.count ?? 0,

        "orders":
            ordersSnapshot.docs.length,

        "approvals":
            approvalsSnapshot.count ?? 0,

        "pending": pending,
        "accepted": accepted,
        "completed": completed,
        "rejected": rejected,
      };

      if (mounted) {

        setState(() {
          isLoading = false;
        });
      }

    } catch (e) {

      if (mounted) {

        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(

          SnackBar(
            content: Text(
              "Error: $e",
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final size =
        MediaQuery.of(context).size;

    final bool isMobile =
        size.width < 700;

    final int pending =
        dashboardData['pending'];

    final int accepted =
        dashboardData['accepted'];

    final int completed =
        dashboardData['completed'];

    final int rejected =
        dashboardData['rejected'];

    final int maxValue = [

      pending,
      accepted,
      completed,
      rejected,

    ].reduce(
      (a, b) => a > b ? a : b,
    );

    return Scaffold(
      backgroundColor:
          const Color(0xfff5f7fb),

      body: SafeArea(

        child: isLoading

            ? const Center(
                child:
                    CircularProgressIndicator(),
              )

            : RefreshIndicator(
                onRefresh:
                    loadDashboard,

                child:
                    SingleChildScrollView(

                  physics:
                      const AlwaysScrollableScrollPhysics(),

                  padding:
                      const EdgeInsets.all(
                          16),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [

                      /// ================= HEADER =================
                      Container(
                        width:
                            double.infinity,

                        padding:
                            const EdgeInsets
                                .all(22),

                        decoration:
                            BoxDecoration(
                          gradient:
                              const LinearGradient(
                            colors: [

                              Color(
                                  0xff2563eb),

                              Color(
                                  0xff7c3aed),
                            ],
                          ),

                          borderRadius:
                              BorderRadius
                                  .circular(
                                      30),
                        ),

                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [

                            Row(
                              children: [

                                Container(
                                  padding:
                                      const EdgeInsets
                                          .all(
                                              14),

                                  decoration:
                                      BoxDecoration(
                                    color: Colors
                                        .white
                                        .withOpacity(
                                            .15),

                                    shape:
                                        BoxShape
                                            .circle,
                                  ),

                                  child:
                                      const Icon(

                                    Icons
                                        .admin_panel_settings_rounded,

                                    color:
                                        Colors
                                            .white,

                                    size: 30,
                                  ),
                                ),

                                const Spacer(),

                                GestureDetector(
                                  onTap:
                                      loadDashboard,

                                  child:
                                      Container(
                                    padding:
                                        const EdgeInsets
                                            .all(
                                                12),

                                    decoration:
                                        BoxDecoration(
                                      color: Colors
                                          .white
                                          .withOpacity(
                                              .15),

                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                                  16),
                                    ),

                                    child:
                                        const Icon(

                                      Icons
                                          .refresh_rounded,

                                      color:
                                          Colors
                                              .white,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                                height: 24),

                            Text(
                              "Admin Dashboard",

                              style:
                                  TextStyle(

                                color: Colors
                                    .white,

                                fontSize:
                                    isMobile
                                        ? 28
                                        : 36,

                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),

                            const SizedBox(
                                height: 8),

                            const Text(
                              "Manage users, providers and orders",

                              style:
                                  TextStyle(
                                color: Colors
                                    .white70,

                                fontSize: 15,
                              ),
                            ),

                            const SizedBox(
                                height: 24),

                            /// SEARCH
                            Container(
                              decoration:
                                  BoxDecoration(
                                color: Colors
                                    .white,

                                borderRadius:
                                    BorderRadius
                                        .circular(
                                            18),
                              ),

                              child:
                                  const TextField(

                                decoration:
                                    InputDecoration(

                                  hintText:
                                      "Search dashboard...",

                                  prefixIcon:
                                      Icon(
                                    Icons
                                        .search,
                                  ),

                                  border:
                                      InputBorder
                                          .none,

                                  contentPadding:
                                      EdgeInsets.symmetric(
                                    vertical:
                                        16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                          height: 30),

                      /// ================= QUICK ACCESS =================
                      const Text(
                        "Quick Access",

                        style: TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                          height: 18),

                      GridView(
                        shrinkWrap: true,

                        physics:
                            const NeverScrollableScrollPhysics(),

                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(

                          crossAxisCount:
                              isMobile
                                  ? 2
                                  : 4,

                          crossAxisSpacing:
                              14,

                          mainAxisSpacing:
                              14,

                          childAspectRatio:
                              isMobile
                                  ? 1.05
                                  : 1.2,
                        ),

                        children: [

                          _dashboardCard(
                            context,

                            title:
                                "Users",

                            icon:
                                Icons.people,

                            color:
                                Colors.blue,

                            count:
                                dashboardData[
                                    'users'],

                            page:
                                UsersPage(),
                          ),

                          _dashboardCard(
                            context,

                            title:
                                "Providers",

                            icon: Icons
                                .business_center_rounded,

                            color:
                                Colors.green,

                            count:
                                dashboardData[
                                    'providers'],

                            page:
                                ProvidersPage(),
                          ),

                          _dashboardCard(
                            context,

                            title:
                                "Orders",

                            icon: Icons
                                .shopping_bag_rounded,

                            color:
                                Colors.orange,

                            count:
                                dashboardData[
                                    'orders'],

                            page:
                                const AdminOrdersPage(),
                          ),

                          _dashboardCard(
                            context,

                            title:
                                "Approvals",

                            icon: Icons
                                .pending_actions_rounded,

                            color:
                                Colors.red,

                            count:
                                dashboardData[
                                    'approvals'],

                            page:
                                const ApproveProvidersPage(),
                          ),
                        ],
                      ),

                      const SizedBox(
                          height: 30),

                      /// ================= GRAPH =================
                      Container(
                        width:
                            double.infinity,

                        padding:
                            const EdgeInsets
                                .all(22),

                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white,

                          borderRadius:
                              BorderRadius
                                  .circular(
                                      28),

                          boxShadow: [

                            BoxShadow(
                              color: Colors
                                  .black
                                  .withOpacity(
                                      .04),

                              blurRadius:
                                  10,
                            ),
                          ],
                        ),

                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [

                            Row(
                              children: [

                                Container(
                                  padding:
                                      const EdgeInsets
                                          .all(
                                              12),

                                  decoration:
                                      BoxDecoration(
                                    color: Colors
                                        .blue
                                        .withOpacity(
                                            .1),

                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                                14),
                                  ),

                                  child:
                                      const Icon(

                                    Icons
                                        .bar_chart_rounded,

                                    color:
                                        Colors
                                            .blue,
                                  ),
                                ),

                                const SizedBox(
                                    width:
                                        14),

                                const Expanded(
                                  child:
                                      Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,

                                    children: [

                                      Text(
                                        "Orders Analytics",

                                        style:
                                            TextStyle(

                                          fontSize:
                                              18,

                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),

                                      SizedBox(
                                          height:
                                              4),

                                      Text(
                                        "Track all order activities visually",

                                        style:
                                            TextStyle(
                                          color:
                                              Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                                height: 28),

                            SizedBox(
                              height:
                                  isMobile
                                      ? 280
                                      : 340,

                              child:
                                  BarChart(

                                BarChartData(

                                  alignment:
                                      BarChartAlignment.spaceAround,

                                  maxY:
                                      (maxValue +
                                              2)
                                          .toDouble(),

                                  borderData:
                                      FlBorderData(
                                    show:
                                        false,
                                  ),

                                  gridData:
                                      FlGridData(
                                    show:
                                        true,

                                    drawVerticalLine:
                                        false,

                                    horizontalInterval:
                                        1,
                                  ),

                                  titlesData:
                                      FlTitlesData(

                                    topTitles:
                                        const AxisTitles(
                                      sideTitles:
                                          SideTitles(
                                        showTitles:
                                            false,
                                      ),
                                    ),

                                    rightTitles:
                                        const AxisTitles(
                                      sideTitles:
                                          SideTitles(
                                        showTitles:
                                            false,
                                      ),
                                    ),

                                    leftTitles:
                                        AxisTitles(
                                      sideTitles:
                                          SideTitles(
                                        showTitles:
                                            true,

                                        reservedSize:
                                            28,
                                      ),
                                    ),

                                    bottomTitles:
                                        AxisTitles(

                                      sideTitles:
                                          SideTitles(

                                        showTitles:
                                            true,

                                        getTitlesWidget:
                                            (
                                          value,
                                          meta,
                                        ) {

                                          final titles =
                                              [

                                            "Pending",
                                            "Accepted",
                                            "Completed",
                                            "Rejected",
                                          ];

                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(
                                              top:
                                                  10,
                                            ),

                                            child:
                                                Text(

                                              titles[
                                                  value
                                                      .toInt()],

                                              style:
                                                  TextStyle(

                                                fontSize:
                                                    isMobile
                                                        ? 10
                                                        : 12,

                                                fontWeight:
                                                    FontWeight.w600,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                  barGroups: [

                                    _bar(
                                      0,
                                      pending,
                                      Colors
                                          .orange,
                                    ),

                                    _bar(
                                      1,
                                      accepted,
                                      Colors
                                          .green,
                                    ),

                                    _bar(
                                      2,
                                      completed,
                                      Colors
                                          .blue,
                                    ),

                                    _bar(
                                      3,
                                      rejected,
                                      Colors.red,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(
                                height: 22),

                            Wrap(
                              spacing: 18,
                              runSpacing: 12,

                              children: [

                                _legend(
                                  Colors.orange,
                                  "Pending",
                                ),

                                _legend(
                                  Colors.green,
                                  "Accepted",
                                ),

                                _legend(
                                  Colors.blue,
                                  "Completed",
                                ),

                                _legend(
                                  Colors.red,
                                  "Rejected",
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                          height: 30),

                      /// ================= ALERT =================
                      if (pending > 0)

                        Container(
                          width:
                              double.infinity,

                          padding:
                              const EdgeInsets
                                  .all(18),

                          decoration:
                              BoxDecoration(

                            gradient:
                                LinearGradient(
                              colors: [

                                Colors.orange
                                    .shade400,

                                Colors.orange
                                    .shade600,
                              ],
                            ),

                            borderRadius:
                                BorderRadius
                                    .circular(
                                        24),
                          ),

                          child: Row(
                            children: [

                              Container(
                                padding:
                                    const EdgeInsets
                                        .all(
                                            12),

                                decoration:
                                    BoxDecoration(
                                  color: Colors
                                      .white
                                      .withOpacity(
                                          .2),

                                  shape:
                                      BoxShape
                                          .circle,
                                ),

                                child:
                                    const Icon(

                                  Icons
                                      .notifications_active_rounded,

                                  color:
                                      Colors
                                          .white,
                                ),
                              ),

                              const SizedBox(
                                  width:
                                      14),

                              Expanded(
                                child:
                                    Text(

                                  "$pending pending orders require your attention",

                                  style:
                                      const TextStyle(

                                    color:
                                        Colors
                                            .white,

                                    fontWeight:
                                        FontWeight
                                            .w600,

                                    fontSize:
                                        15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(
                          height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  /// ================= DASHBOARD CARD =================
  Widget _dashboardCard(
    BuildContext context, {

    required String title,
    required IconData icon,
    required Color color,
    required int count,
    required Widget page,
  }) {

    return GestureDetector(

      onTap: () {

        Navigator.push(
          context,

          MaterialPageRoute(
            builder: (_) => page,
          ),
        );
      },

      child: Container(
        padding:
            const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(
                  24),

          boxShadow: [

            BoxShadow(
              color: Colors.black
                  .withOpacity(.04),

              blurRadius: 10,
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,

          children: [

            Container(
              padding:
                  const EdgeInsets.all(
                      12),

              decoration: BoxDecoration(
                color:
                    color.withOpacity(.1),

                borderRadius:
                    BorderRadius.circular(
                        16),
              ),

              child: Icon(
                icon,
                color: color,
              ),
            ),

            Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [

                FittedBox(
                  child: Text(
                    "$count",

                    style: TextStyle(
                      fontSize: 28,
                      fontWeight:
                          FontWeight.bold,

                      color: color,
                    ),
                  ),
                ),

                const SizedBox(
                    height: 4),

                Text(
                  title,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ================= BAR =================
  BarChartGroupData _bar(
    int x,
    int value,
    Color color,
  ) {

    return BarChartGroupData(

      x: x,

      barRods: [

        BarChartRodData(
          toY:
              value.toDouble(),

          width: 24,

          borderRadius:
              BorderRadius.circular(
                  8),

          gradient:
              LinearGradient(
            colors: [

              color.withOpacity(.7),
              color,
            ],
          ),
        ),
      ],
    );
  }

  /// ================= LEGEND =================
  Widget _legend(
    Color color,
    String text,
  ) {

    return Row(
      mainAxisSize:
          MainAxisSize.min,

      children: [

        Container(
          width: 14,
          height: 14,

          decoration: BoxDecoration(
            color: color,

            borderRadius:
                BorderRadius.circular(
                    4),
          ),
        ),

        const SizedBox(width: 8),

        Text(text),
      ],
    );
  }
}