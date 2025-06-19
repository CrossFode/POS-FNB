import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer.dart';
import 'package:intl/intl.dart';

class Previewbill extends StatefulWidget {
  final String outletName;
  final String orderId;
  final String customerName;
  final String orderType;
  final int tableNumber;
  final List<Map<String, dynamic>> items;
  final int subtotal;
  final int discountVoucher;
  final int discountRef;
  final int total;
  final String paymentMethod;
  final DateTime orderTime;

  const Previewbill({
    super.key,
    required this.outletName,
    required this.orderId,
    required this.customerName,
    required this.orderType,
    required this.tableNumber,
    required this.items,
    required this.subtotal,
    required this.discountVoucher,
    required this.discountRef,
    required this.total,
    required this.paymentMethod,
    required this.orderTime,
  });

  @override
  State<Previewbill> createState() => _PreviewBillState();
}

class _PreviewBillState extends State<Previewbill> {
  ReceiptController? controller;
  bool isPrinting = false;
  final double paperWidth = 58 * 3.78; // 58mm in pixels

  String _formatCurrency(int amount) {
    return NumberFormat("#,##0", "id_ID").format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Struk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              if (isPrinting || controller == null) return;
              setState(() => isPrinting = true);

              try {
                final device =
                    await FlutterBluetoothPrinter.selectDevice(context);
                if (device != null) {
                  await controller!.print(
                    address: device.address,
                    keepConnected: true,
                    addFeeds: 4,
                  );
                }
              } catch (e) {
                print('Print error: $e');
              }

              setState(() => isPrinting = false);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: paperWidth,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
            ),
            child: Receipt(
              builder: (context) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Center(
                      child: Text('=== STRUK PENJUALAN ===',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              height: 1.2),
                          textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        widget.outletName,
                        style: TextStyle(fontSize: 22, height: 1.2),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Order Info
                    Center(
                      child: Text(
                        widget.orderId,
                        style: TextStyle(fontSize: 18, height: 1.2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(widget.orderTime),
                        style: TextStyle(fontSize: 18, height: 1.2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        widget.customerName,
                        style: TextStyle(fontSize: 18, height: 1.2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Center(
                    //   child: Text(
                    //     widget.orderType,
                    //     style: TextStyle(fontSize: 18, height: 1.2),
                    //   ),
                    // ),
                    const SizedBox(height: 8),

                    // Table header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: paperWidth * 0.2,
                          child: Text('Qty',
                              style: TextStyle(fontSize: 22, height: 1.2)),
                        ),
                        SizedBox(
                          width: paperWidth * 0.65,
                          child: Text('Item',
                              style: TextStyle(fontSize: 22, height: 1.2)),
                        ),
                        SizedBox(
                          width: paperWidth * 0.6,
                          child: Text('Subtotal',
                              style: TextStyle(fontSize: 22, height: 1.2),
                              textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                    const Divider(thickness: 1, color: Colors.black),

                    // Product list
                    for (var item in widget.items) ...[
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: paperWidth * 0.02,
                                child: Text('${item['quantity']}',
                                    style:
                                        TextStyle(fontSize: 24, height: 1.2)),
                              ),
                              SizedBox(
                                width: paperWidth * 0.2,
                              ),
                              SizedBox(
                                width: paperWidth * 0.7,
                                child: Text('${item['name']}',
                                    style:
                                        TextStyle(fontSize: 24, height: 1.2)),
                              ),
                              SizedBox(
                                width: paperWidth * 0.6,
                                child: Text(
                                    '${_formatCurrency(item['total_price'])}',
                                    style: TextStyle(fontSize: 21, height: 1.2),
                                    textAlign: TextAlign.right),
                              ),
                            ],
                          ),
                          // Display variants if exists
                          if (item['variants'] != null &&
                              item['variants'].isNotEmpty)
                            Text(
                              'Varian: ${item['variants'][0]['name']}',
                              style: TextStyle(fontSize: 20, height: 1.2),
                              textAlign: TextAlign.start,
                            ),
                          // Display modifiers if exists
                          if (item['modifier'] != null &&
                              item['modifier'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 60.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (var mod in item['modifier'])
                                    Text(
                                      '${mod['name']}: ${mod['modifier_options']['name']}',
                                      style:
                                          TextStyle(fontSize: 20, height: 1.2),
                                    ),
                                ],
                              ),
                            ),
                          // Display notes if exists
                          if (item['notes'] != null && item['notes'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 40.0),
                              child: Text(
                                'Catatan: ${item['notes']}',
                                style: TextStyle(fontSize: 17, height: 1.2),
                              ),
                            ),
                          SizedBox(height: 4),
                        ],
                      ),
                    ],

                    const Divider(thickness: 1, color: Colors.black),
                    const SizedBox(height: 4),

                    // Summary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtotal:',
                            style: TextStyle(fontSize: 20, height: 1.2)),
                        Text('${_formatCurrency(widget.subtotal)}',
                            style: TextStyle(fontSize: 20, height: 1.2)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Diskon:',
                            style: TextStyle(fontSize: 20, height: 1.2)),
                        Text(
                            '${widget.discountVoucher}% + ${widget.discountRef}%',
                            style: TextStyle(fontSize: 20, height: 1.2)),
                      ],
                    ),
                    const Divider(thickness: 1, color: Colors.black),

                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('TOTAL:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                height: 1.2)),
                        Text('${_formatCurrency(widget.total)}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                height: 1.2)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Payment Method
                    Center(
                      child: Text(
                        'Pembayaran: ${widget.paymentMethod}',
                        style: TextStyle(fontSize: 20, height: 1.2),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Footer
                    Center(
                      child: Text(
                        'Terima kasih atas kunjungannya!',
                        style: TextStyle(fontSize: 20, height: 1.2),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                );
              },
              onInitialized: (controller) {
                this.controller = controller;
                controller.paperSize = PaperSize.mm58;
              },
            ),
          ),
        ),
      ),
    );
  }
}
