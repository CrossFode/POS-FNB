import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:posmobile/Auth/login.dart';
import 'package:posmobile/Pages/CreateOrderPage.dart';

import 'package:posmobile/Model/Model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  final String token;
  final bool isManager;
  const Home({Key? key, required this.token, required this.isManager})
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
                        color: const Color.fromARGB(255, 255, 255, 255),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          // Background image di dalam Container
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage('assets/images/FixGaSihV2.png'),
                                  fit: BoxFit.cover,
                                  opacity: 0.1,
                                ),
                              ),
                            ),
                          ),
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
                              // Spacer agar text "Hi, ..." tidak terlalu dekat dengan tombol logout
                              const SizedBox(height: 48), // Tambahkan ini untuk memberi jarak
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Text(
                                  "Hi, ${role}",
                                  style: TextStyle(fontSize: 46),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
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
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 16,
                                          childAspectRatio: 3 / 3,
                                        ),
                                        itemCount: snapshot.data!.data.length,
                                        itemBuilder: (context, index) {
                                          final outlet = snapshot.data!.data[index];
                                          return InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => CreateOrderPage(
                                                    token: widget.token,
                                                    outletId: outlet.id,
                                                    isManager: widget.isManager,
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
                                                child: Padding(
                                                  padding: const EdgeInsets.all(12.0),
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      outlet.image != null
                                                          ? Image(
                                                              width: 110,
                                                              height: 110,
                                                              image: NetworkImage(
                                                                  '${baseUrl}/storage/${outlet.image}'),
                                                            )
                                                          : Icon(Icons.store, size: 40, color: Colors.white),
                                                      SizedBox(height: 8),
                                                      Text(
                                                        outlet.outlet_name,
                                                        textAlign: TextAlign.center,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600, color: Colors.white,
                                                        ),
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
                                        child: Text('Error: ${snapshot.error}'),
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
    );
  }
}
