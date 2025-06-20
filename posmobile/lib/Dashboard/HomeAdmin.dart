import 'package:flutter/material.dart';
import 'package:posmobile/Components/Navbar.dart';
import 'package:posmobile/Pages/Pages.dart';

class HomePage extends StatefulWidget {
  final String token;
  final String outletId;

  const HomePage({Key? key, required this.token, required this.outletId})
      : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  void initState() {
    super.initState();
    _pages = [
      ProductPage(token: widget.token, outletId: widget.outletId),
      HistoryPage(token: widget.token, outletId: widget.outletId),
      CreateOrderPage(token: widget.token, outletId: widget.outletId),
      CategoryPage(),
      ModifierPage(),
      //DiscountPage(token: widget.token, userRoleId: 1),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
