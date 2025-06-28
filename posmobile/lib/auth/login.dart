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
  bool _isLoading = false;
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
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
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
        final data = jsonDecode(response.body);
        print(data['token']);

        SharedPreferences pref = await SharedPreferences.getInstance();
        await pref.setString('token', data['token']);
        await pref.setString('role', data['data']['role_name']);
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
        _showMessage('Failed to load data');
      }
    } catch (e) {
      print('Error: $e');
      _showMessage('Connection error');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
    // Mendapatkan informasi keyboard
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bool keyboardVisible = keyboardHeight > 0;

    // Offset untuk menggeser card ke atas ketika keyboard muncul
    final double topOffset = keyboardVisible
        ? MediaQuery.of(context).size.height *
            0.25 // Posisi lebih tinggi saat keyboard muncul
        : MediaQuery.of(context).size.height * 0.40;

    return Scaffold(
      // Penting: set ke true agar keyboard dapat mendorong konten
      resizeToAvoidBottomInset: false,
      backgroundColor: Color(0xFF359669),
      body: GestureDetector(
        onTap: () => FocusScope.of(context)
            .unfocus(), // Tutup keyboard saat tap area kosong
        child: Stack(
          children: [
            // Area header dengan logo (akan mengecil saat keyboard muncul)
            AnimatedPositioned(
              duration: Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              top: 0,
              left: 0,
              right: 0,
              height: keyboardVisible
                  ? MediaQuery.of(context).size.height *
                      0.30 // Area header mengecil
                  : MediaQuery.of(context).size.height * 0.45,
              child: AnimatedOpacity(
                duration: Duration(milliseconds: 250),
                opacity: keyboardVisible
                    ? 0.85
                    : 1.0, // Sedikit transparansi saat keyboard muncul
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo dalam container
                      AnimatedContainer(
                        duration: Duration(milliseconds: 250),
                        width: keyboardVisible ? 100 : 120,
                        height: keyboardVisible ? 100 : 120,
                        decoration: BoxDecoration(
                          color: Color(0xFFC8F5E8),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/LogoApkFixV2.png',
                            width: keyboardVisible ? 85 : 105,
                            height: keyboardVisible ? 85 : 105,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.receipt,
                                  size: keyboardVisible ? 60 : 70,
                                  color: Color(0xFF5A6C7D));
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: keyboardVisible ? 15 : 20),
                      Text(
                        'Kasir.in',
                        style: TextStyle(
                          fontSize: keyboardVisible ? 32 : 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      // Hilangkan subtitle saat keyboard muncul untuk memberi ruang lebih
                      if (!keyboardVisible) ...[
                        SizedBox(height: 2),
                        Text(
                          'Point of Sale System',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFF5F5F5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Card form login yang bergerak naik saat keyboard muncul
            AnimatedPositioned(
              duration: Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              top: topOffset, // Gunakan offset yang sudah dihitung
              left: 0,
              right: 0,
              bottom: keyboardVisible
                  ? keyboardHeight
                  : 0, // Sesuaikan dengan keyboard
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
                          // decoration: BoxDecoration(
                          //   image: DecorationImage(
                          //     image: AssetImage('assets/images/FixGaSihV2.png'),
                          //     fit: BoxFit.fill,
                          //     opacity: 0.16,
                          //   ),
                          // ),
                        ),
                      ),
                    ),
                    // Form content
                    SingleChildScrollView(
                      padding:
                          EdgeInsets.only(bottom: keyboardHeight > 0 ? 20 : 0),
                      physics: BouncingScrollPhysics(),
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
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Silakan masuk untuk melanjutkan',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color.fromARGB(255, 62, 62, 62),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24),
                            TextField(
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: TextStyle(color: Color(0xFF5A6C7D)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      BorderSide(color: Color(0xFF45A049)),
                                ),
                                prefixIcon:
                                    Icon(Icons.email, color: Color(0xFF45A049)),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              controller: _emailController,
                            ),
                            SizedBox(height: 16),
                            TextField(
                              obscureText: _obscureText,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(color: Color(0xFF5A6C7D)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      BorderSide(color: Color(0xFF45A049)),
                                ),
                                prefixIcon:
                                    Icon(Icons.lock, color: Color(0xFF45A049)),
                                filled: true,
                                fillColor: Colors.white,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureText
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Color(0xFF5A6C7D),
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
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      String email = _emailController.text;
                                      String password =
                                          _passwordController.text;
                                      if (email.isEmpty || password.isEmpty) {
                                        _showMessage(
                                            'Please fill in all fields');
                                        return;
                                      }
                                      login(email, password);
                                    },
                              child: _isLoading
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text('LOGIN',
                                      style: TextStyle(fontSize: 16)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Color.fromARGB(255, 53, 150, 10),
                                foregroundColor: Colors.white,
                                minimumSize: Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            // Jika keyboard tidak muncul, tambahkan space besar
                            SizedBox(height: keyboardVisible ? 20 : 120),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
