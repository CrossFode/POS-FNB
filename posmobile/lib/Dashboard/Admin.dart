import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:posmobile/Dashboard/HomeAdmin.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:posmobile/Pages/CreateOrderPage.dart';

import 'package:posmobile/Model/Model.dart';

class AdminPage extends StatefulWidget {
  final String token;
  const AdminPage({Key? key, required this.token}) : super(key: key);
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminPage> {
  late Future<OutletResponse> _outletFuture;
  @override
  void initState() {
    super.initState();
    _outletFuture = fetchOutletByLogin(widget.token);
  }

  final String baseUrl = dotenv.env['API_BASE_URL'] ??
      ''; // final String baseUrl = 'https://pos.lakesidefnb.group';
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
      appBar: AppBar(
        title: Text('Admin Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Don't take all vertical space
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Choose Outlet',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 400,
              child: FutureBuilder<OutletResponse>(
                future: _outletFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return GridView.builder(
                      padding: EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 columns
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 3 / 3, // Adjust card aspect ratio
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
                                ),
                              ),
                            );
                            // Handle outlet selection
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
                                    // Text(
                                    //   outlet.outlet_name,
                                    //   textAlign: TextAlign.center,
                                    //   style: TextStyle(
                                    //     fontSize: 16,
                                    //     fontWeight: FontWeight.w600,
                                    //   ),
                                    // ),
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
    );
  }
}
