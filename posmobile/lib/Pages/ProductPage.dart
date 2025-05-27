import 'package:flutter/material.dart';

class ProductPage extends StatelessWidget{
  const ProductPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: const Text('This is the Product Page'),
      ),
    );
  }
}