import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:posmobile/Auth/login.dart';
// import 'package:posmobile/Components/NavbarSuperAdmin.dart';
import 'package:posmobile/Pages/Pages.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Model/Model.dart';

class HomePageSuperAdmin extends StatefulWidget {
  final String token;
  // final String outletId;

  const HomePageSuperAdmin({Key? key, required this.token}) : super(key: key);

  @override
  State<HomePageSuperAdmin> createState() => _HomePageSuperAdminState();
}

class _HomePageSuperAdminState extends State<HomePageSuperAdmin> {
  int _currentIndex = 0;
  late Future<OutletResponse> _outletFuture;
  String? token = "";
  String? role = "";
  late final List<Widget> _pages;
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
  // final String baseUrl = 'https://pos.lakesidefnb.group';
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
  void initState() {
    super.initState();
    _outletFuture = fetchOutletByLogin(widget.token);
    _pages = [
      // UserPage(), // Pass empty string for outletId
      // ManagerUserPage(token: widget.token, outletId: widget.outletId),
      // StatisticsPage(token: widget.token, outletId: widget.outletId),
      // You can add OutletPage to _pages if needed, but not as a Future
    ];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 255, 255, 255),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          // Background image di dalam Container
                       
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
                                border: Border.all(color: Colors.red.withOpacity(0.15)),
                              ),
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: IconButton(
                                  icon: const Icon(Icons.logout, color: Colors.red, size: 28),
                                  tooltip: 'Logout',
                                  onPressed: () async {
                                    SharedPreferences pref = await SharedPreferences.getInstance();
                                    pref.remove('token');
                                    pref.remove('role');
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => LoginPage()),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          // Konten utama
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 48),
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Text(
                                  "Hi, Admin",
                                  style: TextStyle(fontSize: 46),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                                child: Text(
                                  'Main Menu',
                                  style: TextStyle(
                                    fontSize: 35,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              // Grid menu
                              SizedBox(
                                height: 300,
                                child: GridView.count(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  shrinkWrap: true,
                                  children: [
                                    // Tombol ke OutletPage
                                    InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => OutletPage(
                                              token: widget.token,
                                              outletId: '',
                                            ),
                                          ),
                                        );
                                      },
                                      child: Card(
                                        color: const Color.fromARGB(255, 53, 150, 105
),
                                        elevation: 6,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.store, size: 40, color: const Color.fromARGB(255, 255, 255, 255)),
                                              SizedBox(height: 8),
                                              Text(
                                                'Outlet',
                                                style: TextStyle(
                                                    fontSize: 16, fontWeight: FontWeight.w600, color: const Color.fromARGB(255, 255, 255, 255)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Tombol ke UserPage
                                    InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => UserPage(
                                                    token: widget.token,
                                                    outletId: '',
                                                  )),
                                        );
                                      },
                                      child: Card(
                                        color: const Color.fromARGB(255, 53, 150, 105),
                                        elevation: 6,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.person, size: 40, color: const Color.fromARGB(255, 255, 255, 255)),
                                              SizedBox(height: 8),
                                              Text(
                                                'User',
                                                style: TextStyle(
                                                    fontSize: 16, fontWeight: FontWeight.w600, color: const Color.fromARGB(255, 255, 255, 255)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Tambahkan tombol menu lain di sini sesuai kebutuhan
                                  ],
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
    );
  }
}
