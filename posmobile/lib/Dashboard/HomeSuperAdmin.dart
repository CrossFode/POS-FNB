import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// import 'package:posmobile/Components/NavbarSuperAdmin.dart';
import 'package:posmobile/Pages/Pages.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


import '../Model/Model.dart';

class HomePageSuperAdmin extends StatefulWidget {
  final String token;
  // final String outletId;

  const HomePageSuperAdmin(
      {Key? key, required this.token})
      : super(key: key);

  @override
  State<HomePageSuperAdmin> createState() => _HomePageSuperAdminState();
}

class _HomePageSuperAdminState extends State<HomePageSuperAdmin> {
  int _currentIndex = 0;
    late Future<OutletResponse> _outletFuture;

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
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Super Admin Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Main Menu',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
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
                            outletId: '', // Isi sesuai kebutuhan
                          ),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.store, size: 40),
                            SizedBox(height: 8),
                            Text(
                              'Outlet',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                          )
                        ),
                      );
                    },
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person, size: 40),
                            SizedBox(height: 8),
                            Text(
                              'User',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
      ),
    );
  }
}
