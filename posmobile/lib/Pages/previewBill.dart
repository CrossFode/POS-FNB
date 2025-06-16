import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:posmobile/Model/Category.dart';
import 'package:posmobile/Model/Model.dart';

class PreviewBill extends StatelessWidget {
  final String outletName;
  final String orderId;
  final String customerName;
  final String orderType;
  final int tableNumber;
  final List<Map<String, dynamic>> items;
  final int subtotal;
  final int discount;
  final int total;
  final String paymentMethod;
  final DateTime orderTime;
  final VoidCallback onPrint;

  const PreviewBill({
    Key? key,
    required this.outletName,
    required this.orderId,
    required this.customerName,
    required this.orderType,
    required this.tableNumber,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.orderTime,
    required this.onPrint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Struk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: onPrint,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header
            Text(
              outletName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const Divider(),

            // Order Info
            _buildRow('Order #', orderId),
            _buildRow(
                'Tanggal', DateFormat('dd/MM/yyyy HH:mm').format(orderTime)),
            _buildRow('Pelanggan', customerName),
            if (orderType.toLowerCase() != 'takeaway')
              _buildRow('Meja', tableNumber.toString()),
            const Divider(),

            // Items
            const Text(
              'ITEM',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(height: 8),

            ...items.map((item) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item['name']} x${item['quantity']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Rp ${NumberFormat("#,##0", "id_ID").format(item['total_price'])}',
                      ),
                    ],
                  ),

                  // Variants
                  if (item['variants'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Column(
                        children: item['variants'].map<Widget>((variant) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '- ${variant['name']}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  // Modifiers
                  if (item['modifier'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Column(
                        children: item['modifier'].map<Widget>((mod) {
                          final option = mod['modifier_options'];
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '+ ${option['name']} (Rp ${option['price']})',
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  // Notes
                  if (item['notes'] != null && item['notes'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        'Catatan: ${item['notes']}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),
                ],
              );
            }).toList(),

            const Divider(),

            // Totals
            _buildRow('Subtotal',
                'Rp ${NumberFormat("#,##0", "id_ID").format(subtotal)}'),
            if (discount > 0)
              _buildRow('Diskon',
                  '-Rp ${NumberFormat("#,##0", "id_ID").format(discount)}'),
            _buildRow(
              'TOTAL',
              'Rp ${NumberFormat("#,##0", "id_ID").format(total)}',
              isBold: true,
            ),

            const Divider(),

            // Payment
            _buildRow('Pembayaran', paymentMethod),

            // Footer
            const SizedBox(height: 16),
            const Text(
              'Terima kasih atas kunjungan Anda',
              style: TextStyle(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
