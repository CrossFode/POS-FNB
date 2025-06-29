import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:posmobile/Auth/login.dart';
import 'package:posmobile/Pages/Pages.dart';
import 'package:posmobile/Components/Navbar.dart';
import 'package:posmobile/Model/Model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  final String token;
  final bool isManager;
  final String? outletId;
  final int navIndex; // Indeks untuk item navbar yang aktif
  final Function(int)? onNavItemTap;
  const Home(
      {Key? key,
      required this.token,
      this.outletId,
      this.navIndex = 0,
      this.onNavItemTap,
      required this.isManager})
      : super(key: key);
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<Home> {
  String? token = "";
  String? role = "";
  late Future<OutletResponse> _outletFuture;
  @override
  void initState() {
    super.initState();
    _outletFuture = fetchOutletByLogin(widget.token);
    getCred();
  }

  void getCred() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      token = pref.getString("token");
      role = pref.getString('role');
      print("Token dari SharedPreferences: $token");
      print("Role dari SharedPreferences: $role");
    });
  }

  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
  Future<OutletResponse> fetchOutletByLogin(String token) async {
    final url = Uri.parse('$baseUrl/api/outlet/current/user');

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        return OutletResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load outlet: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load outlet: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              // Konten utama Home
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Tombol Logout tetap di atas kanan
                    // Row(
                    //   crossAxisAlignment: CrossAxisAlignment.center,
                    //   mainAxisAlignment: MainAxisAlignment.end,
                    //   children: [
                    //     Padding(
                    //       padding: const EdgeInsets.only(left: 24, top: 8, right: 16),
                    //       child: IconButton(
                    //         icon: const Icon(Icons.logout, color: Colors.red, size: 28),
                    //         tooltip: 'Logout',
                    //         onPressed: () async {
                    //           SharedPreferences pref = await SharedPreferences.getInstance();
                    //           pref.remove('token');
                    //           pref.remove('role');
                    //           Navigator.pushReplacement(
                    //             context,
                    //             MaterialPageRoute(builder: (context) => LoginPage()),
                    //           );
                    //         },
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // Bagian yang dipusatkan
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 237, 236, 236),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                          
                            // Tombol Logout di pojok kanan atas dalam Container
                            Positioned(
                              top: 8,
                              right: 16,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(
                                      color: Colors.red.withOpacity(0.15)),
                                ),
                                // child: SizedBox(
                                //   width: 44,
                                //   height: 44,
                                //   child: IconButton(
                                //     icon: const Icon(Icons.logout,
                                //         color: Colors.red, size: 28),
                                //     tooltip: 'Logout',
                                //     onPressed: () async {
                                //       SharedPreferences pref =
                                //           await SharedPreferences.getInstance();
                                //       pref.remove('token');
                                //       pref.remove('role');
                                //       Navigator.pushReplacement(
                                //         context,
                                //         MaterialPageRoute(
                                //             builder: (context) => LoginPage()),
                                //       );
                                //     },
                                //   ),
                                // ),
                              ),
                            ),
                            // Konten utama
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Spacer agar text "Hi, ..." tidak terlalu dekat dengan tombol logout
                                const SizedBox(
                                    height:
                                        48), // Tambahkan ini untuk memberi jarak
                                Padding(
                                  padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
                                  child: Text(
                                    "Hi, ${role}",
                                    style: TextStyle(fontSize: 46),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 8.0, bottom: 8.0),
                                  child: Text(
                                    'Choose Outlet',
                                    style: TextStyle(
                                      fontSize: 35,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                // Grid outlet
                                Expanded(
                                  child: FutureBuilder<OutletResponse>(
                                    future: _outletFuture,
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return GridView.builder(
                                          padding: EdgeInsets.all(16),
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 16,
                                            mainAxisSpacing: 16,
                                            childAspectRatio: 3 / 3,
                                          ),
                                          itemCount: snapshot.data!.data.length,
                                          itemBuilder: (context, index) {
                                            final outlet =
                                                snapshot.data!.data[index];
                                            return InkWell(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        CreateOrderPage(
                                                      token: widget.token,
                                                      outletId: outlet.id,
                                                      isManager:
                                                          widget.isManager,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Card(
                                                color: const Color.fromARGB(
                                                    255, 53, 150, 105),
                                                elevation: 6,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Center(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            12.0),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        outlet.image != null
                                                            ? Image(
                                                                width: 110,
                                                                height: 110,
                                                                image: NetworkImage(
                                                                    '${baseUrl}/storage/${outlet.image}'),
                                                              )
                                                            : Icon(Icons.store,
                                                                size: 40,
                                                                color: Colors
                                                                    .white),
                                                        SizedBox(height: 8),
                                                        Text(
                                                          outlet.outlet_name,
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: Colors.white,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                          maxLines: 2,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      } else if (snapshot.hasError) {
                                        return Center(
                                          child:
                                              Text('Error: ${snapshot.error}'),
                                        );
                                      }
                                      return Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildNavbar());
  }

  Widget _buildNavbar() {
    return FlexibleNavbar(
      currentIndex: widget.navIndex,
      isManager: widget.isManager,
      onTap: (index) {
        if (widget.outletId == null && index != 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please select an outlet first')),
          );
          return;
        }
        if (index != widget.navIndex) {
          print("Tapping on index: $index");
          _handleNavigation(index);
        }
      },
      onMorePressed: () {
        _showMoreOptions(context);
      },
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Menu untuk semua user (baik manager maupun staff)
              _buildMenuOption(
                icon: Icons.settings,
                color: Colors.grey,
                label: 'Modifier',
                onTap: () {
                  if (widget.outletId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please select an outlet first')),
                    );
                    return;
                  }
                  _navigateTo(ModifierPage(
                    token: widget.token,
                    outletId: widget.outletId!,
                    isManager: widget.isManager,
                  ));
                },
              ),
              Divider(),
              _buildMenuOption(
                icon: Icons.category,
                color: Colors.grey,
                label: 'Category',
                onTap: () {
                  if (widget.outletId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please select an outlet first')),
                    );
                    return;
                  }
                  _navigateTo(CategoryPage(
                    token: widget.token,
                    outletId: widget.outletId!,
                    isManager: widget.isManager,
                  ));
                },
              ),
              Divider(),

              // Menu tambahan khusus untuk manager
              if (widget.isManager) ...[
                _buildMenuOption(
                  icon: Icons.card_giftcard,
                  color: Colors.grey,
                  label: 'Referral Code',
                  onTap: () {
                    if (widget.outletId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Please select an outlet first')),
                      );
                      return;
                    }
                    _navigateTo(ReferralCodePage(
                      token: widget.token,
                      outletId: widget.outletId!,
                      isManager: widget.isManager,
                    ));
                  },
                ),
                Divider(),
                _buildMenuOption(
                  icon: Icons.discount,
                  color: Colors.grey,
                  label: 'Discount',
                  onTap: () {
                    if (widget.outletId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Please select an outlet first')),
                      );
                      return;
                    }
                    _navigateTo(DiscountPage(
                      token: widget.token,
                      userRoleId: 2,
                      outletId: widget.outletId!,
                      isManager: widget.isManager,
                      isOpened: true,
                    ));
                  },
                ),
                Divider(),
                _buildMenuOption(
                  icon: Icons.history,
                  color: Colors.grey,
                  label: 'History',
                  onTap: () {
                    if (widget.outletId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Please select an outlet first')),
                      );
                      return;
                    }
                    _navigateTo(HistoryPage(
                      token: widget.token,
                      outletId: widget.outletId!,
                      isManager: widget.isManager,
                    ));
                  },
                ),
                Divider(),
                _buildMenuOption(
                  icon: Icons.payment,
                  color: Colors.grey,
                  label: 'Payment',
                  onTap: () {
                    if (widget.outletId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Please select an outlet first')),
                      );
                      return;
                    }
                    _navigateTo(Payment(
                      token: widget.token,
                      outletId: widget.outletId!,
                      isManager: widget.isManager,
                    ));
                  },
                ),
                Divider(),
              ],

              // Menu logout untuk semua user
              _buildMenuOption(
                icon: Icons.logout,
                color: Colors.red,
                label: 'Logout',
                onTap: () async {
                  SharedPreferences pref =
                      await SharedPreferences.getInstance();
                  pref.remove('token');
                  pref.remove('role');
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required MaterialColor color,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _navigateTo(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  Future<void> _handleNavigation(int index) async {
    if (widget.isManager == true) {
      if (index == 0) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Home(
              token: widget.token,
              outletId: null,
              isManager: widget.isManager,
            ),
          ),
        );
      } else if (index == 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CreateOrderPage(
              token: widget.token,
              outletId: widget.outletId!,
              isManager: widget.isManager,
            ),
          ),
        );
      } else if (index == 2) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProductPage(
              token: widget.token,
              outletId: widget.outletId!,
              isManager: widget.isManager,
            ),
          ),
        );
      } else if (index == 3) {
        _showMoreOptions(context);
      }
    } else {
      if (index == 0) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Home(
              token: widget.token,
              outletId: null,
              isManager: widget.isManager,
            ),
          ),
        );
      } else if (index == 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CreateOrderPage(
              token: widget.token,
              outletId: widget.outletId!,
              isManager: widget.isManager,
            ),
          ),
        );
      } else if (index == 2) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProductPage(
              token: widget.token,
              outletId: widget.outletId!,
              isManager: widget.isManager,
            ),
          ),
        );
      } else if (index == 3) {
        _showMoreOptions(context);
        print('More options pressed');
      }
    }
  }
}
