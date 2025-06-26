// NavbarStaff.dart
import 'package:flutter/material.dart';

class FlexibleNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isManager; // Parameter untuk menentukan role
  final VoidCallback? onMorePressed; // Tambahkan callback khusus untuk More

  const FlexibleNavbar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.isManager,
    this.onMorePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (isManager && index == 3 && onMorePressed != null) {
          onMorePressed!(); // Panggil callback khusus untuk More
        } else {
          onTap(index); // Untuk item navbar lainnya
        }
      },
      type: BottomNavigationBarType.fixed,
    backgroundColor: const Color.fromARGB(255, 255, 255, 255), // Navbar background
    selectedItemColor: Color.fromARGB(255, 53, 150, 105), // Selected icon/text color
    unselectedItemColor: const Color.fromARGB(179, 67, 67, 67), // Unselected icon/text color
    items: isManager ? _buildManagerItems() : _buildStaffItems(),
 );
  }

  List<BottomNavigationBarItem> _buildManagerItems() {
    return [
      BottomNavigationBarItem(
        icon: Icon(Icons.inventory_2),
        label: 'Products',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.add_shopping_cart),
        label: 'Create Order',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.category),
        label: 'Category',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.more_horiz),
        label: 'More',
      ),
    ];
  }

  List<BottomNavigationBarItem> _buildStaffItems() {
    return [
      BottomNavigationBarItem(
        icon: Icon(Icons.inventory_2),
        label: 'Products',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.add_shopping_cart),
        label: 'Create Order',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.category),
        label: 'Category',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'Modifier',
      ),
    ];
  }
}
