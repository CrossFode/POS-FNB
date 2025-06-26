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
  child: Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Tombol Logout tetap di atas kanan
        Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    Padding(
      padding: const EdgeInsets.only(left: 24, top: 8, right: 16),
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
  ],
),
    
        // Bagian yang dipusatkan
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start, // top-align grid
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  "Hi, ${role}",
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: Text(
                  'Choose Outlet',
                  style: TextStyle(
                    fontSize: 30,
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
                                          : Icon(Icons.store, size: 40),
                                      SizedBox(height: 8),
                                      Text(
                                        outlet.outlet_name,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
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
        ),
    )],
    ),
  ),
),

    );
  }
}
