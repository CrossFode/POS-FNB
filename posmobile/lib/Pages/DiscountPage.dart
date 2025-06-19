// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import '../model/Diskon.dart';

// class DiscountPage extends StatefulWidget {
//   final String token;
//   final int userRoleId;

//   const DiscountPage({
//     Key? key,
//     required this.token,
//     required this.userRoleId,
//   }) : super(key: key);

//   @override
//   State<DiscountPage> createState() => _DiscountPageState();
// }

// class _DiscountPageState extends State<DiscountPage> {
//   List<Diskon> _discounts = [];
//   List<Outlet> _outlets = [];
//   bool _isLoading = true;
//   String _searchQuery = '';

//   String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';

//   Map<String, String> get headers => {
//         'Content-Type': 'application/json',
//         'Accept': 'application/json',
//         if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
//       };

//   @override
//   void initState() {
//     super.initState();
//     // Jangan panggil SnackBar di sini!
//     // _loadData(); // Jangan panggil di sini jika butuh context
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     if (_isLoading) {
//       if (widget.token?.isEmpty ?? true) {
//         // Tampilkan SnackBar setelah frame build selesai
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('API token is missing!')),
//             );
//           }
//         });
//         setState(() => _isLoading = false);
//       } else {
//         _loadData();
//       }
//     }
//   }

//   Future<void> _loadData() async {
//     final String? token = widget.token;
//     if (widget.token?.isEmpty ?? true) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('API token is missing!')),
//       );
//       return;
//     }

//     setState(() => _isLoading = true);
//     try {
//       final discounts = await _getDiscounts();
//       final outlets = await _getOutlets();
//       if (!mounted) return;
//       setState(() {
//         _discounts = discounts;
//         _outlets = outlets;
//         _isLoading = false;
//       });
//     } catch (e) {
//       debugPrint('Error loading data: $e');
//       if (!mounted) return;
//       setState(() => _isLoading = false);
//       _showErrorSnackBar('Error loading data: $e');
//     }
//   }

//   Future<List<Diskon>> _getDiscounts() async {
//     try {
//       final String apiUrl = '$baseUrl/api/discount';
//       final response = await http.get(
//         Uri.parse(apiUrl),
//         headers: {
//           'Authorization': 'Bearer ${widget.token}',
//         },
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final List<dynamic> discountList = data['data'] ?? [];
//         return discountList.map((json) => Diskon.fromJson(json)).toList();
//       } else {
//         debugPrint('Error: ${response.statusCode}');
//         debugPrint('Body: ${response.body}');
//         throw Exception('Failed to load discounts: ${response.statusCode}');
//       }
//     } catch (e) {
//       debugPrint('Error fetching discounts: $e');
//       throw Exception('Error fetching discounts: $e');
//     }
//   }

//   Future<List<Outlet>> _getOutlets() async {
//     try {
//       final endpoint =
//           widget.userRoleId == 1 ? 'api/outlet' : 'api/outlet/current/user';
//       final String apiUrl = '$baseUrl/$endpoint';
//       final response = await http.get(
//         Uri.parse(apiUrl),
//         headers: headers,
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final List<dynamic> outletList = data['data'] ?? [];
//         return outletList.map((json) => Outlet.fromJson(json)).toList();
//       } else {
//         debugPrint('Error: ${response.statusCode}');
//         debugPrint('Body: ${response.body}');
//         throw Exception('Failed to load outlets: ${response.statusCode}');
//       }
//     } catch (e) {
//       debugPrint('Error fetching outlets: $e');
//       throw Exception('Error fetching outlets: $e');
//     }
//   }

//   Future<bool> _createDiscount({
//     required String name,
//     required String type,
//     required double amount,
//     required List<int> outletIds,
//   }) async {
//     try {
//       final String apiUrl = '$baseUrl/api/discount';
//       final response = await http.post(
//         Uri.parse(apiUrl),
//         headers: headers,
//         body: json.encode({
//           'name': name,
//           'type': type,
//           'amount': amount,
//           'outlet_ids': outletIds,
//         }),
//       );

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return true;
//       } else {
//         debugPrint('Error creating discount: ${response.statusCode}');
//         debugPrint('Body: ${response.body}');
//         return false;
//       }
//     } catch (e) {
//       debugPrint('Error creating discount: $e');
//       throw Exception('Error creating discount: $e');
//     }
//   }

//   Future<bool> _updateDiscount({
//     required int id,
//     required String name,
//     required String type,
//     required double amount,
//     required List<int> outletIds,
//   }) async {
//     try {
//       final String apiUrl = '$baseUrl/api/discount/$id';
//       final response = await http.put(
//         Uri.parse(apiUrl),
//         headers: headers,
//         body: json.encode({
//           'name': name,
//           'type': type,
//           'amount': amount,
//           'outlet_ids': outletIds,
//         }),
//       );

//       if (response.statusCode == 200) {
//         return true;
//       } else {
//         debugPrint('Error updating discount: ${response.statusCode}');
//         debugPrint('Body: ${response.body}');
//         return false;
//       }
//     } catch (e) {
//       debugPrint('Error updating discount: $e');
//       throw Exception('Error updating discount: $e');
//     }
//   }

//   Future<bool> _deleteDiscount(int id) async {
//     try {
//       final String apiUrl = '$baseUrl/api/discount/$id';
//       final response = await http.delete(
//         Uri.parse(apiUrl),
//         headers: headers,
//       );

//       if (response.statusCode == 200) {
//         return true;
//       } else {
//         debugPrint('Error deleting discount: ${response.statusCode}');
//         debugPrint('Body: ${response.body}');
//         return false;
//       }
//     } catch (e) {
//       debugPrint('Error deleting discount: $e');
//       throw Exception('Error deleting discount: $e');
//     }
//   }

//   List<Diskon> get _filteredDiscounts {
//     if (_searchQuery.isEmpty) return _discounts;
//     return _discounts
//         .where((discount) =>
//             discount.name.toLowerCase().contains(_searchQuery.toLowerCase()))
//         .toList();
//   }

//   void _showErrorSnackBar(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }

//   void _showSuccessSnackBar(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   Future<void> _showCreateDialog() async {
//     await showDialog(
//       context: context,
//       builder: (context) => _DiscountFormDialog(
//         outlets: _outlets,
//         onSubmit: (name, type, amount, outletIds) async {
//           try {
//             final success = await _createDiscount(
//               name: name,
//               type: type,
//               amount: amount,
//               outletIds: outletIds,
//             );
//             if (success) {
//               _showSuccessSnackBar('Discount created successfully');
//               _loadData();
//               return true;
//             } else {
//               _showErrorSnackBar('Failed to create discount');
//               return false;
//             }
//           } catch (e) {
//             _showErrorSnackBar('Error creating discount: $e');
//             return false;
//           }
//         },
//       ),
//     );
//   }

//   Future<void> _showEditDialog(Diskon discount) async {
//     await showDialog(
//       context: context,
//       builder: (context) => _DiscountFormDialog(
//         discount: discount,
//         onSubmit: (name, type, amount) async {
//           try {
//             final success = await _updateDiscount(
//               id: discount.id!,
//               name: name,
//               type: type,
//               amount: amount,
//             );
//             if (success) {
//               _showSuccessSnackBar('Discount updated successfully');
//               _fetchDiscountsFromApi();
//               return true;
//             } else {
//               _showErrorSnackBar('Failed to update discount');
//               return false;
//             }
//           } catch (e) {
//             _showErrorSnackBar('Error updating discount: $e');
//             return false;
//           }
//         },
//       ),
//     );
//   }

//   Future<void> _showDeleteDialog(Diskon discount) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete Discount'),
//         content: Text(
//             'Are you sure you want to delete "${discount.name}"?\nYou won\'t be able to revert this!'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(false),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             onPressed: () => Navigator.of(context).pop(true),
//             child: const Text('Yes, delete it!'),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       try {
//         final success = await _deleteDiscount(discount.id!);
//         if (success) {
//           _showSuccessSnackBar('Deleted! Discount has been deleted.');
//           _fetchDiscountsFromApi();
//         } else {
//           _showErrorSnackBar('Failed! Something went wrong.');
//         }
//       } catch (e) {
//         _showErrorSnackBar('Failed! ${e.toString()}');
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Discount'),
//         backgroundColor: Colors.blue[600],
//         foregroundColor: Colors.white,
//       ),
//       body: Column(
//         children: [
//           // Search and Create Button
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     decoration: const InputDecoration(
//                       hintText: 'Search discounts...',
//                       prefixIcon: Icon(Icons.search),
//                       border: OutlineInputBorder(),
//                     ),
//                     onChanged: (value) {
//                       setState(() => _searchQuery = value);
//                     },
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 ElevatedButton.icon(
//                   onPressed: _showCreateDialog,
//                   icon: const Icon(Icons.add),
//                   label: const Text('Create Discount'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue[600],
//                     foregroundColor: Colors.white,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // Data Table
//           Expanded(
//             child: _isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : _filteredDiscounts.isEmpty
//                     ? const Center(
//                         child: Text(
//                           'No discounts found',
//                           style: TextStyle(fontSize: 16, color: Colors.grey),
//                         ),
//                       )
//                     : SingleChildScrollView(
//                         scrollDirection: Axis.horizontal,
//                         child: SingleChildScrollView(
//                           child: DataTable(
//                             headingRowColor:
//                                 MaterialStateProperty.all(Colors.grey[100]),
//                             columns: const [
//                               DataColumn(
//                                   label: Text('Name',
//                                       style: TextStyle(
//                                           fontWeight: FontWeight.bold))),
//                               DataColumn(
//                                   label: Text('Type',
//                                       style: TextStyle(
//                                           fontWeight: FontWeight.bold))),
//                               DataColumn(
//                                   label: Text('Amount',
//                                       style: TextStyle(
//                                           fontWeight: FontWeight.bold))),
//                               DataColumn(
//                                   label: Text('Created',
//                                       style: TextStyle(
//                                           fontWeight: FontWeight.bold))),
//                               DataColumn(
//                                   label: Text('Actions',
//                                       style: TextStyle(
//                                           fontWeight: FontWeight.bold))),
//                             ],
//                             rows: _filteredDiscounts.map((discount) {
//                               return DataRow(
//                                 cells: [
//                                   DataCell(Text(discount.name)),
//                                   DataCell(Text(discount.type)),
//                                   DataCell(Text(discount.amount.toString())),
//                                   DataCell(Text(
//                                     discount.created_at != null
//                                         ? DateFormat('dd/MM/yyyy HH:mm')
//                                             .format(discount.created_at!)
//                                         : '-',
//                                   )),
//                                   DataCell(
//                                     Row(
//                                       mainAxisSize: MainAxisSize.min,
//                                       children: [
//                                         IconButton(
//                                           icon: const Icon(Icons.edit,
//                                               color: Colors.blue),
//                                           onPressed: () =>
//                                               _showEditDialog(discount),
//                                           tooltip: 'Edit',
//                                         ),
//                                         IconButton(
//                                           icon: const Icon(Icons.delete,
//                                               color: Colors.red),
//                                           onPressed: () =>
//                                               _showDeleteDialog(discount),
//                                           tooltip: 'Delete',
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               );
//                             }).toList(),
//                           ),
//                         ),
//                       ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _DiscountFormDialog extends StatefulWidget {
//   final Diskon? discount;
//   final Future<bool> Function(String name, String type, int amount) onSubmit;

//   const _DiscountFormDialog({
//     this.discount,
//     required this.onSubmit,
//   });

//   @override
//   State<_DiscountFormDialog> createState() => _DiscountFormDialogState();
// }

// class _DiscountFormDialogState extends State<_DiscountFormDialog> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _amountController = TextEditingController();
//   String _selectedType = 'percent';
//   bool _isSubmitting = false;

//   @override
//   void initState() {
//     super.initState();
//     if (widget.discount != null) {
//       _nameController.text = widget.discount!.name;
//       _amountController.text = widget.discount!.amount.toString();
//       _selectedType = widget.discount!.type;
//     }
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _amountController.dispose();
//     super.dispose();
//   }

//   Future<void> _handleSubmit() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _isSubmitting = true);

//     try {
//       final success = await widget.onSubmit(
//         _nameController.text.trim(),
//         _selectedType,
//         int.parse(_amountController.text),
//       );

//       if (success && mounted) {
//         Navigator.of(context).pop(true);
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isSubmitting = false);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: Text(
//         widget.discount != null ? 'Edit Discount' : 'Create Discount',
//         textAlign: TextAlign.center,
//         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
//       ),
//       content: SizedBox(
//         width: MediaQuery.of(context).size.width * 0.9,
//         child: Form(
//           key: _formKey,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextFormField(
//                 controller: _nameController,
//                 decoration: const InputDecoration(
//                   labelText: 'Name',
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return 'Name is required';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
//               DropdownButtonFormField<String>(
//                 value: _selectedType,
//                 decoration: const InputDecoration(
//                   labelText: 'Type',
//                   border: OutlineInputBorder(),
//                 ),
//                 items: const [
//                   DropdownMenuItem(
//                       value: 'percent', child: Text('Percent (%)')),
//                   DropdownMenuItem(value: 'fixed', child: Text('Fixed Price')),
//                 ],
//                 onChanged: (value) {
//                   setState(() {
//                     _selectedType = value!;
//                   });
//                 },
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: _amountController,
//                 decoration: InputDecoration(
//                   labelText: 'Amount',
//                   border: const OutlineInputBorder(),
//                   suffixText: _selectedType == 'percent' ? '%' : 'Rp',
//                 ),
//                 keyboardType: TextInputType.number,
//                 validator: (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return 'Amount is required';
//                   }
//                   final amount = int.tryParse(value);
//                   if (amount == null) {
//                     return 'Please enter a valid number';
//                   }
//                   if (amount <= 0) {
//                     return 'Amount must be greater than 0';
//                   }
//                   if (_selectedType == 'percent' && amount > 100) {
//                     return 'Percentage cannot exceed 100%';
//                   }
//                   return null;
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed:
//               _isSubmitting ? null : () => Navigator.of(context).pop(false),
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: _isSubmitting ? null : _handleSubmit,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.blue[600],
//             foregroundColor: Colors.white,
//           ),
//           child: _isSubmitting
//               ? const SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(
//                       strokeWidth: 2, color: Colors.white),
//                 )
//               : const Text('Save'),
//         ),
//       ],
//     );
//   }
// }
