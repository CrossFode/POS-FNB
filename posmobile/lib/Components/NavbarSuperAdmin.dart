import 'package:flutter/material.dart';

class NavbarSuperAdmin extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NavbarSuperAdmin({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'User',
        ),
        // BottomNavigationBarItem(
        //   icon: Icon(Icons.manage_accounts),
        //   label: 'Manager',
        // ),
        // BottomNavigationBarItem(
        //   icon: Icon(Icons.bar_chart),
        //   label: 'Statistics',
        // ),
        BottomNavigationBarItem(
          icon: Icon(Icons.store),
          label: 'Outlet',
        ),
      ],
    );
  }
}