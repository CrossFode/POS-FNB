import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:posmobile/Components/Navbar.dart';
import 'package:posmobile/Pages/Pages.dart';
import 'package:posmobile/model/Model.dart';

class ModifierPage extends StatefulWidget {
  final String token;
  final String outletId;
  final int navIndex; // Index navbar saat ini
  final Function(int)? onNavItemTap; // Callback untuk navigasi
  final bool isManager;

  const ModifierPage(
      {Key? key,
      required this.token,
      required this.outletId,
      this.navIndex = 3, // Default index
      this.onNavItemTap,
      required this.isManager})
      : super(key: key);

  @override
  State<ModifierPage> createState() => _ModifierPageState();
}

class _ModifierPageState extends State<ModifierPage> {
  late Future<ModifierResponse> _modifierFuture;
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  @override
  void initState() {
    super.initState();
    _modifierFuture = fetchModifiers();
  }

  Future<ModifierResponse> fetchModifiers() async {
    final url =
        Uri.parse('$baseUrl/api/modifier/ext/outlet/${widget.outletId}');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return ModifierResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load modifiers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load modifiers: $e');
    }
  }

  Future<void> createModifier({
    required String name,
    required bool isRequired,
    required List<Map<String, dynamic>> options,
  }) async {
    final url = Uri.parse('$baseUrl/api/modifier');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'is_required': isRequired ? 1 : 0,
          'min_selected': isRequired ? 1 : 0,
          'max_selected': options.length,
          'outlet_id': widget.outletId,
          'modifier_options': options
              .map((option) => {
                    'name': option['name'],
                    'price': option['price'],
                  })
              .toList(),
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modifier created successfully')),
        );
        setState(() {
          _modifierFuture = fetchModifiers(); // Refresh the list
        });
      } else {
        final errorResponse = jsonDecode(response.body);
        throw Exception(
            errorResponse['message'] ?? 'Failed to create modifier');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      rethrow;
    }
  }

  Future<void> updateModifier({
    required int modifierId,
    required String name,
    required bool isRequired,
    required List<Map<String, dynamic>> options,
  }) async {
    final url = Uri.parse('$baseUrl/api/modifier/$modifierId');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'is_required': isRequired ? 1 : 0,
        'min_selected': isRequired ? 1 : 0,
        'max_selected': options.length,
        'outlet_id': widget.outletId,
        'modifier_options': options
            .map((option) => {
                  'id': option['id'], // include id if exists for update
                  'name': option['name'],
                  'price': option['price'],
                })
            .toList(),
      }),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modifier updated successfully')),
      );
      setState(() {
        _modifierFuture = fetchModifiers();
      });
    } else {
      final errorResponse = jsonDecode(response.body);
      throw Exception(errorResponse['message'] ?? 'Failed to update modifier');
    }
  }

  // List<TextEditingController> _priceControllers = [];

  void showCreateModifierDialog() {
    final _formKey = GlobalKey<FormState>();
    String _name = '';
    bool _isRequired = false;
    List<Map<String, dynamic>> _options = [];
    List<TextEditingController> _priceControllers = [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.65,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Create Modifier',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'MODIFIER GROUP',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 66, 66, 66),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Divider(color: Colors.grey, thickness: 1),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Modifier Name',
                                  border: OutlineInputBorder(),
                                ),
                                onSaved: (value) => _name = value ?? '',
                              ),
                              const SizedBox(height: 16),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'MODIFIER OPTIONS',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 66, 66, 66),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Divider(color: Colors.grey, thickness: 1),
                              ..._options.asMap().entries.map((entry) {
                                int index = entry.key;
                                var option = entry.value;

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: option['name'],
                                          decoration: const InputDecoration(
                                            hintText: 'Option Name',
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (val) {
                                            setState(
                                                () => option['name'] = val);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _priceControllers[index],
                                          decoration: const InputDecoration(
                                            hintText: 'Price',
                                            prefixText: 'Rp ',
                                            border: OutlineInputBorder(),
                                          ),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly
                                          ],
                                          onChanged: (val) {
                                            final cleaned = val.replaceFirst(
                                                RegExp(r'^0+(?=\d)'), '');
                                            if (val != cleaned) {
                                              _priceControllers[index].text =
                                                  cleaned;
                                              _priceControllers[index]
                                                      .selection =
                                                  TextSelection.fromPosition(
                                                TextPosition(
                                                    offset: cleaned.length),
                                              );
                                            }
                                            setState(() {
                                              _options[index]['price'] =
                                                  int.tryParse(cleaned) ?? 0;
                                            });
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            _options.removeAt(index);
                                            _priceControllers.removeAt(index);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _options.add({'name': '', 'price': 0});
                                    _priceControllers
                                        .add(TextEditingController(text: ''));
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                ),
                                child: const Text(
                                  'ADD MODIFIER OPTION',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'MODIFIER LIMIT',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 66, 66, 66),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Divider(color: Colors.grey, thickness: 1),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'REQUIRED?',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: _isRequired == true,
                                            onChanged: (value) {
                                              setState(() {
                                                _isRequired = true;
                                              });
                                            },
                                          ),
                                          const Text('Yes'),
                                        ],
                                      ),
                                      const SizedBox(width: 24),
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: _isRequired == false,
                                            onChanged: (value) {
                                              setState(() {
                                                _isRequired = false;
                                              });
                                            },
                                          ),
                                          const Text('No'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(style: TextButton.styleFrom(foregroundColor: Colors.black),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();

                              // Validate all options have names and valid prices
                              bool hasInvalidOptions = _options.any((option) =>
                                  (option['name']?.toString().trim().isEmpty ??
                                      true) ||
                                  (option['price'] == null ||
                                      option['price'] < 0));

                              if (_options.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Please add at least one modifier option')),
                                );
                                return;
                              }

                              if (hasInvalidOptions) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Please fill all option names and provide valid prices')),
                                );
                                return;
                              }

                              try {
                                await createModifier(
                                  name: _name,
                                  isRequired: _isRequired,
                                  options: _options,
                                );
                                Navigator.of(context).pop();
                              } catch (e) {
                                // Error is already handled in createModifier
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                          ),
                          child: const Text(
                            'Create',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void showEditModifierDialog(Modifier modifier) {
    final _formKey = GlobalKey<FormState>();
    String _name = modifier.name;
    bool _isRequired = modifier.is_required == 1;
    List<Map<String, dynamic>> _options = modifier.modifier_options
        .map((opt) => {
              'id': opt.id,
              'name': opt.name,
              'price': opt.price,
            })
        .toList();
    List<TextEditingController> _priceControllers = _options
        .map((opt) => TextEditingController(text: (opt['price'] ?? '').toString()))
        .toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.65,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Edit Modifier',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'MODIFIER GROUP',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 66, 66, 66),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Divider(color: Colors.grey, thickness: 1),
                              TextFormField(
                                initialValue: _name,
                                decoration: const InputDecoration(
                                  labelText: 'Modifier Name',
                                  border: OutlineInputBorder(),
                                ),
                                onSaved: (value) => _name = value ?? '',
                              ),
                              const SizedBox(height: 16),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'MODIFIER OPTIONS',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 66, 66, 66),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Divider(color: Colors.grey, thickness: 1),
                              ..._options.asMap().entries.map((entry) {
                                int index = entry.key;
                                var option = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: option['name'],
                                          decoration: const InputDecoration(
                                            hintText: 'Option Name',
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (val) {
                                            setState(() => option['name'] = val);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _priceControllers[index],
                                          decoration: const InputDecoration(
                                            hintText: 'Price',
                                            prefixText: 'Rp ',
                                            border: OutlineInputBorder(),
                                          ),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly
                                          ],
                                          onChanged: (val) {
                                            final cleaned = val.replaceFirst(
                                                RegExp(r'^0+(?=\d)'), '');
                                            if (val != cleaned) {
                                              _priceControllers[index].text =
                                                  cleaned;
                                              _priceControllers[index].selection =
                                                  TextSelection.fromPosition(
                                                TextPosition(offset: cleaned.length),
                                              );
                                            }
                                            setState(() {
                                              _options[index]['price'] =
                                                  int.tryParse(cleaned) ?? 0;
                                            });
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            _options.removeAt(index);
                                            _priceControllers.removeAt(index);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _options.add({'name': '', 'price': 0});
                                    _priceControllers.add(TextEditingController(text: ''));
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                ),
                                child: const Text(
                                  'ADD MODIFIER OPTION',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'MODIFIER LIMIT',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 66, 66, 66),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Divider(color: Colors.grey, thickness: 1),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'REQUIRED?',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: _isRequired == true,
                                            onChanged: (value) {
                                              setState(() {
                                                _isRequired = true;
                                              });
                                            },
                                          ),
                                          const Text('Yes'),
                                        ],
                                      ),
                                      const SizedBox(width: 24),
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: _isRequired == false,
                                            onChanged: (value) {
                                              setState(() {
                                                _isRequired = false;
                                              });
                                            },
                                          ),
                                          const Text('No'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(style: TextButton.styleFrom(foregroundColor: Colors.black),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();

                              bool hasInvalidOptions = _options.any((option) =>
                                  (option['name']?.toString().trim().isEmpty ?? true) ||
                                  (option['price'] == null || option['price'] < 0));

                              if (_options.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Please add at least one modifier option')),
                                );
                                return;
                              }

                              if (hasInvalidOptions) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Please fill all option names and provide valid prices')),
                                );
                                return;
                              }

                              try {
                                await updateModifier(
                                  modifierId: modifier.id,
                                  name: _name,
                                  isRequired: _isRequired,
                                  options: _options,
                                );
                                Navigator.of(context).pop();
                              } catch (e) {
                                // Error is already handled in updateModifier
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void showApplyModifierDialog(Modifier modifier) async {
    // Fetch all products for this outlet
    final url = Uri.parse('$baseUrl/api/product/ext/outlet/${widget.outletId}');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load products')),
      );
      return;
    }

    final productResponse = ProductResponse.fromJson(jsonDecode(response.body));
    // Get product IDs that already have this modifier
    final Set<int> appliedProductIds = {};
    for (var product in productResponse.data) {
      if (product.modifiers.any((m) => m.id == modifier.id)) {
        appliedProductIds.add(product.id);
      }
    }

    // Track selection state
    final Map<int, bool> selected = {
      for (var product in productResponse.data)
        product.id: appliedProductIds.contains(product.id)
    };

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Apply \"${modifier.name}\" to Products"),
          content: SizedBox(
            width: 350,
            height: 400,
            child: ListView(
              children: productResponse.data.map((product) {
                return CheckboxListTile(
                  value: selected[product.id] ?? false,
                  title: Text(product.name),
                  onChanged: (val) {
                    selected[product.id] = val ?? false;
                    (context as Element).markNeedsBuild();
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                // For each product, update its modifiers
                for (var product in productResponse.data) {
                  final shouldApply = selected[product.id] ?? false;
                  final hasModifier = product.modifiers.any((m) => m.id == modifier.id);

                  if (shouldApply && !hasModifier) {
                    // Add modifier
                    final updatedModifierIds = [
                      ...product.modifiers.map((m) => m.id),
                      modifier.id
                    ];
                    await http.put(
                      Uri.parse('$baseUrl/api/product/${product.id}'),
                      headers: {
                        'Authorization': 'Bearer ${widget.token}',
                        'Content-Type': 'application/json',
                      },
                      body: jsonEncode({
                        'name': product.name,
                        'category_id': product.category_id,
                        'description': product.description,
                        'price': product.variants.isNotEmpty ? product.variants.first.price : 0,
                        'is_active': product.is_active,
                        'outlet_id': product.outlet_id,
                        'modifiers': updatedModifierIds,
                      }),
                    );
                  } else if (!shouldApply && hasModifier) {
                    // Remove modifier
                    final updatedModifierIds = product.modifiers
                        .where((m) => m.id != modifier.id)
                        .map((m) => m.id)
                        .toList();
                    await http.put(
                      Uri.parse('$baseUrl/api/product/${product.id}'),
                      headers: {
                        'Authorization': 'Bearer ${widget.token}',
                        'Content-Type': 'application/json',
                      },
                      body: jsonEncode({
                        'name': product.name,
                        'category_id': product.category_id,
                        'description': product.description,
                        'price': product.variants.isNotEmpty ? product.variants.first.price : 0,
                        'is_active': product.is_active,
                        'outlet_id': product.outlet_id,
                        'modifiers': updatedModifierIds,
                      }),
                    );
                  }
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Modifier applied to products')),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Column(
      children: [
        const Padding(
        padding: EdgeInsets.only(top: 32, left: 16, right: 16, bottom: 8),
        child: Align(
          alignment: Alignment.center,
          child: Text(
          'Modifiers',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            letterSpacing: 1.2,
          ),
          ),
        ),
        ),
        Expanded(
        child: FutureBuilder<ModifierResponse>(
          future: _modifierFuture,
          builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
            return const Center(child: Text('No modifiers available'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.data.length,
            itemBuilder: (context, index) {
            final modifier = snapshot.data!.data[index];
            return Card(
              shadowColor: const Color.fromARGB(255, 125, 125, 125),
              color: Colors.white,
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
              title: Text(
                modifier.name,
                style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 23,
                ),
              ),
              subtitle: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const SizedBox(height: 4),
    Text(
      'Required: ${modifier.is_required == 1 ? "Yes" : "No"}',
      style: const TextStyle(fontSize: 14),
    ),
    Text(
      'Selection: Min ${modifier.min_selected}, Max ${modifier.max_selected}',
      style: const TextStyle(fontSize: 14),
    ),
  ],
),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Color.fromARGB(255, 106, 106, 106)),
                  tooltip: 'Edit',
                  onPressed: () {
                  showEditModifierDialog(modifier);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Color.fromARGB(255, 100, 101, 101)),
                  tooltip: 'Apply to Product',
                  onPressed: () {
                  showApplyModifierDialog(modifier);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete',
                  onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                    title: const Center(child: Text('Delete Modifier')),
                    content: const Text('Apakah anda yakin ingin menghapus modifier ini?'),
                    actions: [
                      TextButton(style: TextButton.styleFrom(foregroundColor: Colors.black),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                      ),
                      TextButton(style: TextButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete', style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
                      ),
                    ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                    final url = Uri.parse('$baseUrl/api/modifier/${modifier.id}');
                    final response = await http.delete(
                      url,
                      headers: {
                      'Authorization': 'Bearer ${widget.token}',
                      'Content-Type': 'application/json',
                      },
                    );
                    if (response.statusCode == 200) {
                      ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Modifier deleted successfully')),
                      );
                      setState(() {
                      _modifierFuture = fetchModifiers();
                      });
                    } else {
                      final errorResponse = jsonDecode(response.body);
                      ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(errorResponse['message'] ?? 'Failed to delete modifier')),
                      );
                    }
                    } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                    }
                  }
                  },
                ),
                ],
              ),
              children: [
  ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: modifier.modifier_options.length,
    itemBuilder: (context, optionIndex) {
      final option = modifier.modifier_options[optionIndex];
      return ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -3),
        title: Text(
          option.name ?? '',
          style: const TextStyle(fontSize: 14),
        ),
        trailing: Text(
          'Rp ${option.price ?? 0}',
          style: const TextStyle(fontSize: 14),
        ),
      );
    },
  ),
],
              ),
            );
            },
          );
          },
        ),
        ),
      ],
      ),
      floatingActionButton: FloatingActionButton(
      onPressed: () {
        showCreateModifierDialog();
      },
      backgroundColor: Colors.black,
      child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: _buildNavbar(),
    );
  }

  Widget _buildNavbar() {
    // Anda bisa membuat navbar khusus atau menggunakan yang sudah ada
    // Contoh dengan NavbarManager:
    return FlexibleNavbar(
      currentIndex: widget.navIndex,
      isManager: widget.isManager,
      onTap: (index) {
        if (index != widget.navIndex) {
          if (widget.onNavItemTap != null) {
            widget.onNavItemTap!(index);
          } else {
            // Default navigation behavior
            _handleNavigation(index);
          }
        }
      },
      onMorePressed: () {
        _showMoreOptions(context);
      },
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMenuOption(
                icon: Icons.settings,
                label: 'Modifier',
                onTap: () => _navigateTo(ModifierPage(
                  token: widget.token,
                  outletId: widget.outletId,
                  isManager: widget.isManager,
                )),
              ),
              Divider(),
              _buildMenuOption(
                icon: Icons.card_giftcard,
                label: 'Referral Code',
                onTap: () => _navigateTo(ModifierPage(
                  token: widget.token,
                  outletId: widget.outletId,
                  isManager: widget.isManager,
                )),
              ),
              Divider(),
              _buildMenuOption(
                icon: Icons.discount,
                label: 'Discount',
                onTap: () => _navigateTo(ModifierPage(
                  token: widget.token,
                  outletId: widget.outletId,
                  isManager: widget.isManager,
                )),
              ),
              Divider(),
              _buildMenuOption(
                icon: Icons.history,
                label: 'History',
                onTap: () => _navigateTo(HistoryPage(
                  token: widget.token,
                  outletId: widget.outletId,
                  // isManager: widget.isManager,
                )),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.pop(context); // Tutup bottom sheet
        onTap();
      },
    );
  }

  void _navigateTo(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _handleNavigation(int index) {
    // Implementasi navigasi berdasarkan index
    if (widget.isManager == true) {
      if (index == 0) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProductPage(
              token: widget.token,
              outletId: widget.outletId,
              isManager: widget.isManager,
              // isManager: widget.isManager,
            ),
          ),
        );
      } else if (index == 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CreateOrderPage(
              token: widget.token,
              outletId: widget.outletId,
              isManager: widget.isManager,
            ),
          ),
        );
      } else if (index == 2) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryPage(
              token: widget.token,
              outletId: widget.outletId,
              isManager: widget.isManager,
            ),
          ),
        );
      } else if (index == 3) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ModifierPage(
                token: widget.token,
                outletId: widget.outletId,
                isManager: widget.isManager),
          ),
        );
      }
    } else {
      if (index == 0) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProductPage(
              token: widget.token,
              outletId: widget.outletId,
              isManager: widget.isManager,
            ),
          ),
        );
      } else if (index == 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CreateOrderPage(
              token: widget.token,
              outletId: widget.outletId,
              isManager: widget.isManager,
            ),
          ),
        );
      } else if (index == 2) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryPage(
                token: widget.token,
                outletId: widget.outletId,
                isManager: widget.isManager),
          ),
        );
      } else if (index == 3) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ModifierPage(
                token: widget.token,
                outletId: widget.outletId,
                isManager: widget.isManager),
          ),
        );
      }
    }
    // Tambahkan case lainnya sesuai kebutuhan
  }
}
