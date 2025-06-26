import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:posmobile/Pages/Dashboard/Dashboard.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  final String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
  @override
  void initState() {
    super.initState();
    isLogin(); // panggil saat halaman baru dimuat
  }

  void isLogin() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? val = pref.getString("token");
    String? role = pref.getString("role");
    print("Token setelah logout: $val");
    print("Role setelah logout: $role");
    if (val != null && role != null) {
      if (role == 'Admin') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomePageSuperAdmin(token: val),
          ),
        );
      } else if (role == 'Manager') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Home(token: val, isManager: true),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Home(token: val, isManager: false),
          ),
        );
      }
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await http.post(
        // Uri.parse('https://pos.lakesidefnb.group/api/auth'),
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/auth'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      );
      if (response.statusCode == 200) {
        // If the server returns an OK response, parse the JSON
        final data = jsonDecode(response.body);
        print(data['token']);

        // Navigate to the Admin page
        SharedPreferences pref = await SharedPreferences.getInstance();
        await pref.setString('token', data['token']);
        await pref.setString('role', data['data']['role_name']); // Simpan role
        print("Token disimpan: ${data['token']}");
        print("Role disimpan: ${data['data']['role_name']}");

        if (data['data']['role_name'] == 'Admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => HomePageSuperAdmin(token: data['token'])),
          );
        } else if (data['data']['role_name'] == 'Manager') {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      Home(token: data['token'], isManager: true)));
        } else if (data['data']['role_name'] == 'Staff') {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Home(
                  token: data['token'],
                  isManager: false,
                ),
              ));
        }
      } else if (response.statusCode == 401) {
        _showMessage('Invalid email or Password');
      } else {
        // If the server did not return a 200 OK response,
        // throw an exception.
        _showMessage('Failed to load data');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Color(0xFF359669), // Primary color 1 - sudah sesuai
      body: Stack(
        children: [
          // Bagian logo dan judul di area hijau
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo dalam container accent color
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Color(0xFFC8F5E8), // Accent color 1 - light mint
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/LogoFix.png',
                            width: 105,
                            height: 105,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.receipt,
                                  size: 70,
                                  color: Color(0xFF5A6C7D)); // Primary color 3
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'POS.in',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Neutral color 1
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Point of Sale System',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(
                          0xFFF5F5F5), // Neutral color 2 - very light gray
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Card putih dengan form login
          Positioned(
            top: MediaQuery.of(context).size.height * 0.40,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Stack(
                children: [
                  // Background image
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/FixGaSihV2.png'),
                            fit: BoxFit.fill,
                            // alignment: Alignment.center, // Mengisi seluruh area
                            opacity: 0.16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Form content
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8),
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'Selamat Datang',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors
                                        .black, // Neutral color 3 - dark gray
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Silakan masuk untuk melanjutkan',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color.fromARGB(255, 62, 62,
                                        62), // Neutral color 4 - medium gray
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24),
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(
                                  color: Color(0xFF5A6C7D)), // Primary color 3
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                    color:
                                        Color(0xFF45A049)), // Primary color 2
                              ),
                              prefixIcon:
                                  Icon(Icons.email, color: Color(0xFF45A049)),
                              filled: true,
                              fillColor: Colors.white, // Primary color 2
                            ),
                            keyboardType: TextInputType.emailAddress,
                            controller: _emailController,
                          ),
                          SizedBox(height: 16),
                          TextField(
                            obscureText: _obscureText,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(
                                  color: Color(0xFF5A6C7D)), // Primary color 3
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                    color:
                                        Color(0xFF45A049)), // Primary color 2
                              ),
                              prefixIcon:
                                  Icon(Icons.lock, color: Color(0xFF45A049)),
                              filled: true,
                              fillColor: Colors.white, // Primary color 2
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Color(0xFF5A6C7D), // Primary color 3
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureText = !_obscureText;
                                  });
                                },
                              ),
                            ),
                            controller: _passwordController,
                          ),
                          SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: () {
                              String email = _emailController.text;
                              String password = _passwordController.text;
                              if (email.isEmpty || password.isEmpty) {
                                _showMessage('Please fill in all fields');
                                return;
                              }
                              login(email, password);
                            },
                            child:
                                Text('LOGIN', style: TextStyle(fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(
                                  255, 53, 150, 10), // Primary color 2
                              foregroundColor: Colors.white, // Neutral color 1
                              minimumSize: Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
<<<<<<< Fauzan
                ),
              ),
            ),
          ),

          Positioned(
            bottom: -25,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.5, // Nilai 0.0 (transparan) hingga 1.0 (solid)
              child: Image.asset(
                'assets/images/LogoBawah.png',
                height: 50,
=======
                ],
>>>>>>> main
              ),
            ),
          ),
        ],
      ),
    );
  }
}
