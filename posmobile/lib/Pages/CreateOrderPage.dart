import 'package:flutter/material.dart';

class CreateOrderPage extends StatefulWidget {
  @override
  _CreateOrderPageState createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final List<Map<String, dynamic>> menuItems = const [
    {'name': 'Salted Caramel latte', 'price': '24000', 'category': 'Coffee'},
    {'name': 'Vanilla Bean latte', 'price': '22000', 'category': 'Coffee'},
    {'name': 'Hazelnut Mocha', 'price': '25000', 'category': 'Coffee'},
  ];

  final List<Map<String, dynamic>> _cartItems = [];
  String _orderType = 'Take Away'; // Default order type

  // Tambahkan state kategori
  List<String> categories = ['All', 'Coffee', 'Food', 'Tea'];
  String selectedCategory = 'All';

  // Function untuk menghitung total harga
  int _calculateTotal() {
    int total = 0;
    for (var item in _cartItems) {
      int price = int.parse(item['price']);
      int quantity = item['quantity'];
      total += price * quantity;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    // Filter menu berdasarkan kategori
    final filteredMenu = selectedCategory == 'All'
        ? menuItems
        : menuItems
            .where((item) => item['category'] == selectedCategory)
            .toList();

    return Scaffold(
      body: Column(
        children: [
          // Pilihan kategori
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories
                  .map((cat) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: selectedCategory == cat,
                          onSelected: (selected) {
                            setState(() {
                              selectedCategory = cat;
                            });
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredMenu.length,
              itemBuilder: (context, index) {
                final item = filteredMenu[index];
                return _buildMenuItem(
                  name: item['name'],
                  price: item['price'],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _cartItems.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showCart,
              backgroundColor: Colors.black,
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              label: Text(
                '${_cartItems.length} item(s)',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildMenuItem({required String name, required String price}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rp $price',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown)),
              SizedBox(
                width: 50,
                height: 47,
                child: ElevatedButton(
                  onPressed: () {
                    _showOrderOptions(context, name, price);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 46, 44, 43),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOrderOptions(BuildContext context, String name, String price) {
    int quantity = 1;
    String selectedModifier = 'Less Ice';
    TextEditingController noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 16,
              left: 16,
              right: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("CANCEL",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                    ),
                    Text(
                      '$name - Rp $price',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _cartItems.add({
                            'name': name,
                            'price': price,
                            'modifier': selectedModifier,
                            'quantity': quantity,
                            'notes': noteController.text,
                          });
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Save",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                const Divider(),

                // Modifier
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Ice | Required",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: ['Less Ice', 'No Ice']
                      .map(
                        (mod) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: OutlinedButton(
                              onPressed: () =>
                                  setModalState(() => selectedModifier = mod),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: selectedModifier == mod
                                    ? Colors.black
                                    : Colors.white,
                                foregroundColor: selectedModifier == mod
                                    ? Colors.white
                                    : Colors.black,
                                side: const BorderSide(color: Colors.black),
                              ),
                              child: Text(mod),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),

                const SizedBox(height: 16),

                // Quantity
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Quantity",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (quantity > 1) setModalState(() => quantity--);
                      },
                      icon: const Icon(Icons.remove),
                    ),
                    Text('$quantity', style: const TextStyle(fontSize: 18)),
                    IconButton(
                      onPressed: () => setModalState(() => quantity++),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Notes
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Notes",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    hintText: 'Add notes here',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        });
      },
    );
  }

  final TextEditingController _customerNameController = TextEditingController();

  void _showCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Order Type",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ["Take Away", "Dine In"]
                        .map(
                          (type) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: OutlinedButton(
                                onPressed: () =>
                                    setModalState(() => _orderType = type),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: _orderType == type
                                      ? Colors.black
                                      : Colors.white,
                                  foregroundColor: _orderType == type
                                      ? Colors.white
                                      : Colors.black,
                                  side: const BorderSide(color: Colors.black),
                                ),
                                child: Text(type),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 16),

                  // Input Nama Customer
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Customer Name",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _customerNameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter customer name',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Cart items
                  SizedBox(
                    height: 200, // Fixed height to prevent overflow
                    child: ListView(
                      children: _cartItems.map((item) {
                        return ListTile(
                          title: Text('${item['name']} x${item['quantity']}'),
                          subtitle: Text(
                              '${item['modifier']} — ${item['notes'].isNotEmpty ? item['notes'] : 'No notes'}'),

                          trailing: Text(
                              'Rp ${int.parse(item['price']) * item['quantity']}'),

                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),


                  // Total dan Checkout button dengan layout baru
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Total harga di kiri
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Total:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "Rp ${_calculateTotal()}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      // Tombol checkout di kanan
                      ElevatedButton(
                        onPressed: () {
                          print("Order Type: $_orderType");
                          print(
                              "Customer Name: ${_customerNameController.text}");
                          print("Items: $_cartItems");
                          print("Total: ${_calculateTotal()}");
                          // Tambahkan logika checkout sesuai kebutuhan
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "CHECKOUT",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
