import 'package:flutter/material.dart'; 
import 'package:posmobile/Components/Navbar.dart';
import 'package:posmobile/Pages/CategoryPage.dart';
import 'package:posmobile/Pages/CreateOrderPage.dart';
import 'package:posmobile/Pages/ModifierPage.dart';
import 'package:posmobile/Pages/ProductPage.dart';
import 'package:posmobile/Pages/HistoryPage.dart';

class HomePage extends StatefulWidget {
  final String token;

  const HomePage({Key? key, required this.token}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // Define your pages here (replace with your actual pages)
  final List<Widget> _pages = [
    ProductPage(),
    HistoryPage(),
    CreateOrderPage(),
    CategoryPage(),
    ModifierPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: Navbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
