import 'package:flutter/material.dart';

class UserPage extends StatelessWidget{
  const UserPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: const Text('This is the Manage User Page'),
      ),
    );
  }
}