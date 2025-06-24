import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../model/Referral.dart'; // Ganti import model

class ReferralCodePage extends StatefulWidget {
  final String token;
  final String outletId;
  final bool isManager;

  const ReferralCodePage({
    Key? key,
    required this.token,
    required this.outletId,
    this.isManager = false,
  }) : super(key: key);

  @override
  State<ReferralCodePage> createState() => _ReferralCodePageState();
}

class _ReferralCodePageState extends State<ReferralCodePage> {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
  bool isLoading = true;
  List<ReferralCode> referralCodes = [];

  @override
  void initState() {
    super.initState();
    fetchReferralCodes();
  }

  Future<void> fetchReferralCodes() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/referralcode'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final dataList = jsonData['data'];
        print(dataList);
        setState(() {
          referralCodes = (dataList is List)
              ? dataList.map((item) => ReferralCode.fromJson(item)).toList()
              : [];
        });
      } else {
        _showErrorDialog('Failed to fetch referral codes');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteReferralCode(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Referral Code'),
        content: Text('Are you sure you want to delete this code?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final response = await http.delete(
          Uri.parse('$baseUrl/api/referralcode/$id'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Accept': 'application/json',
          },
        );
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == true) {
          _showSuccessDialog('Referral code deleted');
          fetchReferralCodes();
        } else {
          _showErrorDialog(
              jsonData['message'] ?? 'Failed to delete referral code');
        }
      } catch (e) {
        _showErrorDialog('Error: $e');
      }
    }
  }

  Future<void> editReferralCode({
    required int id,
    required String code,
    String? description,
    required int discount,
    required int quotas,
    required DateTime expiredDate,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/referralcode/$id'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'code': code,
          'description': description,
          'discount': discount,
          'quotas': quotas,
          'expired_date': expiredDate.toIso8601String(),
        }),
      );
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == true) {
        _showSuccessDialog('Referral Code Has Been Updated');
        fetchReferralCodes();
      } else {
        _showErrorDialog(
            jsonData['message'] ?? 'Failed to update referral code');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    }
  }

  Future<void> addReferralCode({
    required String code,
    String? description,
    required int discount,
    required int quotas,
    required DateTime expiredDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/referralcode'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'code': code,
          'description': description,
          'discount': discount,
          'quotas': quotas,
          'expired_date': expiredDate.toIso8601String(),
        }),
      );
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == true) {
        _showSuccessDialog('Success On Creating new Referral Code');
        fetchReferralCodes();
      } else {
        _showErrorDialog(
            jsonData['message'] ?? 'Failed to create referral code');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Referral Code'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              TextEditingController codeController = TextEditingController();
              TextEditingController descController = TextEditingController();
              TextEditingController discountController =
                  TextEditingController();
              TextEditingController quotasController = TextEditingController();
              DateTime? expiredDate;

              return StatefulBuilder(
                builder: (context, setState) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.blue[50]!, Colors.white],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[600],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.add_business,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                'Create New Referral Code',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Form Fields
                        SingleChildScrollView(
                          child: Column(
                            children: [
                              // Code Field
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: codeController,
                                  decoration: InputDecoration(
                                    labelText: 'Referral Code',
                                    prefixIcon: const Icon(Icons.code,
                                        color: Colors.blue),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Description Field
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: descController,
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    labelText: 'Description',
                                    prefixIcon: const Icon(Icons.description,
                                        color: Colors.green),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Discount and Quotas Row
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.1),
                                            spreadRadius: 1,
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: TextField(
                                        controller: discountController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: 'Discount (%)',
                                          prefixIcon: const Icon(Icons.percent,
                                              color: Colors.orange),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.1),
                                            spreadRadius: 1,
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: TextField(
                                        controller: quotasController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: 'Quotas',
                                          prefixIcon: const Icon(Icons.people,
                                              color: Colors.purple),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Date Picker
                              GestureDetector(
                                onTap: () async {
                                  final pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: expiredDate ??
                                        DateTime.now()
                                            .add(const Duration(days: 30)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2101),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: Colors.blue[600]!,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (pickedDate != null) {
                                    setState(() {
                                      expiredDate = pickedDate;
                                    });
                                  }
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        spreadRadius: 1,
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today,
                                          color: Colors.red[400]),
                                      const SizedBox(width: 12),
                                      Text(
                                        expiredDate != null
                                            ? 'Expires: ${DateFormat('dd/MM/yyyy').format(expiredDate!)}'
                                            : 'Select Expiry Date',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: expiredDate != null
                                              ? Colors.black87
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (codeController.text.isNotEmpty &&
                                      expiredDate != null &&
                                      discountController.text.isNotEmpty &&
                                      quotasController.text.isNotEmpty) {
                                    addReferralCode(
                                      code: codeController.text,
                                      description: descController.text,
                                      discount: int.tryParse(
                                              discountController.text) ??
                                          0,
                                      quotas:
                                          int.tryParse(quotasController.text) ??
                                              0,
                                      expiredDate: expiredDate!,
                                    );
                                    Navigator.pop(context);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[600],
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Create Code',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        backgroundColor: Colors.blue[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : referralCodes.isEmpty
              ? const Center(child: Text('No referral codes found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: referralCodes.length,
                  itemBuilder: (context, index) {
                    final code = referralCodes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    code.code ?? '-',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        TextEditingController codeController =
                                            TextEditingController(
                                                text: code.code ?? '');
                                        TextEditingController descController =
                                            TextEditingController(
                                                text: code.description ?? '');
                                        TextEditingController
                                            discountController =
                                            TextEditingController(
                                                text: code.discount.toString());
                                        TextEditingController quotasController =
                                            TextEditingController(
                                                text: code.quotas.toString());
                                        DateTime expiredDate = code.expiredDate;

                                        return StatefulBuilder(
                                          builder: (context, setState) =>
                                              Dialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(24),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Colors.grey[50]!,
                                                    Colors.white
                                                  ],
                                                ),
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // Header
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(12),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors
                                                              .orange[600],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: const Icon(
                                                          Icons.edit_note,
                                                          color: Colors.white,
                                                          size: 24,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      const Expanded(
                                                        child: Text(
                                                          'Edit Referral Code',
                                                          style: TextStyle(
                                                            fontSize: 20,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                Colors.black87,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 24),

                                                  // Form Fields (sama seperti add dialog tapi dengan data awal)
                                                  SingleChildScrollView(
                                                    child: Column(
                                                      children: [
                                                        // Code Field
                                                        Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .grey
                                                                    .withOpacity(
                                                                        0.1),
                                                                spreadRadius: 1,
                                                                blurRadius: 4,
                                                                offset:
                                                                    const Offset(
                                                                        0, 2),
                                                              ),
                                                            ],
                                                          ),
                                                          child: TextField(
                                                            controller:
                                                                codeController,
                                                            decoration:
                                                                InputDecoration(
                                                              labelText:
                                                                  'Referral Code',
                                                              prefixIcon:
                                                                  const Icon(
                                                                      Icons
                                                                          .code,
                                                                      color: Colors
                                                                          .blue),
                                                              border:
                                                                  OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12),
                                                                borderSide:
                                                                    BorderSide
                                                                        .none,
                                                              ),
                                                              filled: true,
                                                              fillColor:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 16),

                                                        // Description Field
                                                        Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .grey
                                                                    .withOpacity(
                                                                        0.1),
                                                                spreadRadius: 1,
                                                                blurRadius: 4,
                                                                offset:
                                                                    const Offset(
                                                                        0, 2),
                                                              ),
                                                            ],
                                                          ),
                                                          child: TextField(
                                                            controller:
                                                                descController,
                                                            maxLines: 2,
                                                            decoration:
                                                                InputDecoration(
                                                              labelText:
                                                                  'Description',
                                                              prefixIcon: const Icon(
                                                                  Icons
                                                                      .description,
                                                                  color: Colors
                                                                      .green),
                                                              border:
                                                                  OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12),
                                                                borderSide:
                                                                    BorderSide
                                                                        .none,
                                                              ),
                                                              filled: true,
                                                              fillColor:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 16),

                                                        // Discount and Quotas Row
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: Container(
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .white,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              12),
                                                                  boxShadow: [
                                                                    BoxShadow(
                                                                      color: Colors
                                                                          .grey
                                                                          .withOpacity(
                                                                              0.1),
                                                                      spreadRadius:
                                                                          1,
                                                                      blurRadius:
                                                                          4,
                                                                      offset:
                                                                          const Offset(
                                                                              0,
                                                                              2),
                                                                    ),
                                                                  ],
                                                                ),
                                                                child:
                                                                    TextField(
                                                                  controller:
                                                                      discountController,
                                                                  keyboardType:
                                                                      TextInputType
                                                                          .number,
                                                                  decoration:
                                                                      InputDecoration(
                                                                    labelText:
                                                                        'Discount (%)',
                                                                    prefixIcon: const Icon(
                                                                        Icons
                                                                            .percent,
                                                                        color: Colors
                                                                            .orange),
                                                                    border:
                                                                        OutlineInputBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              12),
                                                                      borderSide:
                                                                          BorderSide
                                                                              .none,
                                                                    ),
                                                                    filled:
                                                                        true,
                                                                    fillColor:
                                                                        Colors
                                                                            .white,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 12),
                                                            Expanded(
                                                              child: Container(
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .white,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              12),
                                                                  boxShadow: [
                                                                    BoxShadow(
                                                                      color: Colors
                                                                          .grey
                                                                          .withOpacity(
                                                                              0.1),
                                                                      spreadRadius:
                                                                          1,
                                                                      blurRadius:
                                                                          4,
                                                                      offset:
                                                                          const Offset(
                                                                              0,
                                                                              2),
                                                                    ),
                                                                  ],
                                                                ),
                                                                child:
                                                                    TextField(
                                                                  controller:
                                                                      quotasController,
                                                                  keyboardType:
                                                                      TextInputType
                                                                          .number,
                                                                  decoration:
                                                                      InputDecoration(
                                                                    labelText:
                                                                        'Quotas',
                                                                    prefixIcon: const Icon(
                                                                        Icons
                                                                            .people,
                                                                        color: Colors
                                                                            .purple),
                                                                    border:
                                                                        OutlineInputBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              12),
                                                                      borderSide:
                                                                          BorderSide
                                                                              .none,
                                                                    ),
                                                                    filled:
                                                                        true,
                                                                    fillColor:
                                                                        Colors
                                                                            .white,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 16),

                                                        // Date Picker
                                                        GestureDetector(
                                                          onTap: () async {
                                                            final pickedDate =
                                                                await showDatePicker(
                                                              context: context,
                                                              initialDate:
                                                                  expiredDate,
                                                              firstDate:
                                                                  DateTime
                                                                      .now(),
                                                              lastDate:
                                                                  DateTime(
                                                                      2101),
                                                              builder: (context,
                                                                  child) {
                                                                return Theme(
                                                                  data: Theme.of(
                                                                          context)
                                                                      .copyWith(
                                                                    colorScheme:
                                                                        ColorScheme
                                                                            .light(
                                                                      primary: Colors
                                                                              .orange[
                                                                          600]!,
                                                                    ),
                                                                  ),
                                                                  child: child!,
                                                                );
                                                              },
                                                            );
                                                            if (pickedDate !=
                                                                null) {
                                                              setState(() {
                                                                expiredDate =
                                                                    pickedDate;
                                                              });
                                                            }
                                                          },
                                                          child: Container(
                                                            width:
                                                                double.infinity,
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(16),
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  Colors.white,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                              border: Border.all(
                                                                  color: Colors
                                                                          .grey[
                                                                      300]!),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: Colors
                                                                      .grey
                                                                      .withOpacity(
                                                                          0.1),
                                                                  spreadRadius:
                                                                      1,
                                                                  blurRadius: 4,
                                                                  offset:
                                                                      const Offset(
                                                                          0, 2),
                                                                ),
                                                              ],
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                Icon(
                                                                    Icons
                                                                        .calendar_today,
                                                                    color: Colors
                                                                            .red[
                                                                        400]),
                                                                const SizedBox(
                                                                    width: 12),
                                                                Text(
                                                                  'Expires: ${DateFormat('dd/MM/yyyy').format(expiredDate)}',
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    color: Colors
                                                                        .black87,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 24),

                                                  // Action Buttons
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context),
                                                          style: TextButton
                                                              .styleFrom(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    vertical:
                                                                        16),
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                              side: BorderSide(
                                                                  color: Colors
                                                                          .grey[
                                                                      300]!),
                                                            ),
                                                          ),
                                                          child: const Text(
                                                            'Cancel',
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: ElevatedButton(
                                                          onPressed: () {
                                                            editReferralCode(
                                                              id: code.id,
                                                              code:
                                                                  codeController
                                                                      .text,
                                                              description:
                                                                  descController
                                                                      .text,
                                                              discount: int.tryParse(
                                                                      discountController
                                                                          .text) ??
                                                                  0,
                                                              quotas: int.tryParse(
                                                                      quotasController
                                                                          .text) ??
                                                                  0,
                                                              expiredDate:
                                                                  expiredDate,
                                                            );
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                const Color.fromARGB(255, 92, 89, 85),
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    vertical:
                                                                        16),
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                            ),
                                                          ),
                                                          child: const Text(
                                                            'Update Code',
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => deleteReferralCode(code.id),
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              code.description ?? '-',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black87),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Chip(
                                  label: Text('Discount: ${code.discount}%'),
                                  backgroundColor: Colors.blue[50],
                                ),
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text(
                                      'Quota: ${code.usaged ?? 0} / ${code.quotas}'),
                                  backgroundColor: Colors.green[50],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.timer,
                                        size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Expired: ${DateFormat('dd/MM/yyyy HH:mm').format(code.expiredDate)}',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 4),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      code.createdAt != null
                                          ? 'Created: ${DateFormat('dd/MM/yyyy HH:mm').format(code.createdAt!)}'
                                          : 'Created: -',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
