import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:posmobile/Model/Modifier.dart';

class ModifierPage extends StatefulWidget {
  final String token;
  final String outletId;

  const ModifierPage({
    Key? key,
    required this.token,
    required this.outletId,
  }) : super(key: key);

  @override
  State<ModifierPage> createState() => _ModifierPageState();
}

class _ModifierPageState extends State<ModifierPage> {
  late Future<ModifierResponse> _modifierFuture;
  final String baseUrl = 'http://10.0.2.2:8000';

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
                                  backgroundColor: Colors.blue,
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
                                  // Opsi Yes
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Checkbox(
                                        value: _isRequired == true,
                                        onChanged: (value) {
                                          setState(() {
                                            _isRequired = true;
                                          });
                                        },
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: const [
                                            Text('Yes'),
                                            Text(
                                              'Modifier selection is required',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Opsi No
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Checkbox(
                                        value: _isRequired == false,
                                        onChanged: (value) {
                                          setState(() {
                                            _isRequired = false;
                                          });
                                        },
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: const [
                                            Text('No'),
                                            Text(
                                              'Modifier is optional',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
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
                        TextButton(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Modifiers',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<ModifierResponse>(
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
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(
                    modifier.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showCreateModifierDialog();
        },
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
