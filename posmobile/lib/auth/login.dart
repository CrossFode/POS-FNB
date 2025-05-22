import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('https://pos.lakesidefnb.group/api/auth'),
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
        print('Login successful: $data');
        _showMessage("Login Successful: $data");
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
      appBar: AppBar(
        title: Center(child: Text('Login')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              controller: _emailController,
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              controller: _passwordController,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                String email = _emailController.text;
                String password = _passwordController.text;
                if (email.isEmpty || password.isEmpty) {
                  _showMessage('Please fill in all fields');
                  return;
                }
                login(email, password);
                // Handle login logic here
              },
              child: Text('Login'),
            ),
            TextButton(
              onPressed: () {},
              child: Text('Don\'t have an account? Sign up'),
            ),
          ],
        ),
      ),
    );
  }
}
