import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:posmobile/Components/Navbar.dart';
import 'package:posmobile/model/model.dart';
import 'package:posmobile/Pages/Pages.dart'; // Ganti import model

class ReferralCodePage extends StatefulWidget {
  final String token;
  final String outletId;
  final int navIndex;
  final Function(int)? onNavItemTap;
  final bool isManager;

  const ReferralCodePage({
    Key? key,
    required this.token,
    required this.outletId,
    this.navIndex = 3, // Default ke tab History (index 3)
    this.onNavItemTap,
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
        backgroundColor: Colors.white,
        title: const Center(
          child: Text(
            'Delete Referral Code',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
        ),
        content: const Text(
          'Apakah anda yakin ingin menghapus kode ini?',
          textAlign: TextAlign.center,
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                      color: Color.fromARGB(255, 145, 145, 145),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Delete',
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
          automaticallyImplyLeading: false,
          title: const Text(
            "Referal Code",
            style: TextStyle(fontSize: 30),
          ),
          backgroundColor: const Color.fromARGB(255, 53, 150, 105),
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
                TextEditingController quotasController =
                    TextEditingController();
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
                        color: Colors.white,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            const Center(
                              child: Text(
                                'Create Referral Code',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Referral Code
                            const Text(
                              "REFERRAL CODE",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: codeController,
                              decoration: InputDecoration(
                                hintText: 'Referral Code',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Description
                            const Text(
                              "DESCRIPTION",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: descController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: 'Description',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Discount & Quotas
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "DISCOUNT (%)",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: discountController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          hintText: 'Discount',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "QUOTAS",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: quotasController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          hintText: 'Quotas',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Date Picker
                            const Text(
                              "EXPIRED DATE",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () async {
                                final pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: expiredDate ??
                                      DateTime.now().add(
                                          const Duration(days: 30)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2101),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: Color.fromARGB(255, 53, 150, 105),
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
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Text(
                                  expiredDate != null
                                      ? DateFormat('dd/MM/yyyy').format(expiredDate!)
                                      : 'Select Expiry Date',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: expiredDate != null
                                        ? Colors.black87
                                        : Colors.grey[600],
                                  ),
                                ),
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
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
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
                                        color: Color.fromARGB(255, 53, 150, 105),
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
                                          quotas: int.tryParse(
                                                  quotasController.text) ??
                                              0,
                                          expiredDate: expiredDate!,
                                        );
                                        Navigator.pop(context);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(
                                          255, 53, 150, 105),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Create',
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
                 ) );
              },
            );
          },
          backgroundColor: const Color.fromARGB(255, 53, 150, 105),
          child: const Icon(Icons.add, color: Colors.white),
        ),

                backgroundColor: const Color.fromARGB(255, 245, 244, 244),

        body: Stack(
          children: [
            // Background image dengan opacity 0.5
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/FixGaSihV2.png'),
                    fit: BoxFit.cover,
                    opacity: 0.1,
                  ),
                ),
              ),
            ),

            // Konten asli
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : referralCodes.isEmpty
                    ? const Center(child: Text('No referral codes found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: referralCodes.length,
                        itemBuilder: (context, index) {
                          final code = referralCodes[index];
                          return Card(
                            color: Colors.white,
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
                                            color: Color.fromARGB(255, 53, 150, 105
),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                        ),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              TextEditingController
                                                  codeController =
                                                  TextEditingController(
                                                      text: code.code ?? '');
                                              TextEditingController
                                                  descController =
                                                  TextEditingController(
                                                      text: code.description ??
                                                          '');
                                              TextEditingController
                                                  discountController =
                                                  TextEditingController(
                                                      text: code.discount
                                                          .toString());
                                              TextEditingController
                                                  quotasController =
                                                  TextEditingController(
                                                      text: code.quotas
                                                          .toString());
                                              DateTime expiredDate =
                                                  code.expiredDate;

                                              return StatefulBuilder(
                                                  builder:
                                                      (context, setState) =>
                                                          Dialog(
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          20),
                                                            ),
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(24),
                                                              decoration:
                                                                  BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            20),
                                                                gradient:
                                                                    LinearGradient(
                                                                  begin: Alignment
                                                                      .topLeft,
                                                                  end: Alignment
                                                                      .bottomRight,
                                                                  colors: [
                                                                    Colors.grey[
                                                                        50]!,
                                                                    Colors.white
                                                                  ],
                                                                ),
                                                              ),
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  // Header
                                                                  Row(
                                                                    children: [
                                                                      Container(
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            12),
                                                                       
                                                                      
                                                                      ),
                                                                      const SizedBox(
                                                                          width:
                                                                              16),
                                                                      const Expanded(
                                                                        child:
                                                                            Text(
                                                                          'Edit Referral Code',
                                                                          style:
                                                                              TextStyle(
                                                                            fontSize:
                                                                                20,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color:
                                                                                Colors.black87,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  const SizedBox(
                                                                      height:
                                                                          24),

                                                                  // Form Fields (sama seperti add dialog tapi dengan data awal)
                                                                  SingleChildScrollView(
                                                                    child:
                                                                        Column(
                                                                      children: [
                                                                        // Code Field
                                                                        Container(
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color:
                                                                                Colors.white,
                                                                            borderRadius:
                                                                                BorderRadius.circular(12),
                                                                            boxShadow: [
                                                                              BoxShadow(
                                                                                color: Colors.grey.withOpacity(0.1),
                                                                                spreadRadius: 1,
                                                                                blurRadius: 4,
                                                                                offset: const Offset(0, 2),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                          child:
                                                                              TextField(
                                                                            controller:
                                                                                codeController,
                                                                            decoration:
                                                                                InputDecoration(
                                                                              labelText: 'Referral Code',
                                                                              border: OutlineInputBorder(
                                                                                borderRadius: BorderRadius.circular(12),
                                                                                borderSide: BorderSide.none,
                                                                              ),
                                                                              filled: true,
                                                                              fillColor: Colors.white,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            height:
                                                                                16),

                                                                        // Description Field
                                                                        Container(
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color:
                                                                                Colors.white,
                                                                            borderRadius:
                                                                                BorderRadius.circular(12),
                                                                            boxShadow: [
                                                                              BoxShadow(
                                                                                color: Colors.grey.withOpacity(0.1),
                                                                                spreadRadius: 1,
                                                                                blurRadius: 4,
                                                                                offset: const Offset(0, 2),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                          child:
                                                                              TextField(
                                                                            controller:
                                                                                descController,
                                                                            maxLines:
                                                                                2,
                                                                            decoration:
                                                                                InputDecoration(
                                                                              labelText: 'Description',
                                                                              border: OutlineInputBorder(
                                                                                borderRadius: BorderRadius.circular(12),
                                                                                borderSide: BorderSide.none,
                                                                              ),
                                                                              filled: true,
                                                                              fillColor: Colors.white,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            height:
                                                                                16),

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
                                                                                    border: OutlineInputBorder(
                                                                                      borderRadius: BorderRadius.circular(12),
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
                                                                                    border: OutlineInputBorder(
                                                                                      borderRadius: BorderRadius.circular(12),
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
                                                                        const SizedBox(
                                                                            height:
                                                                                16),

                                                                        // Date Picker
                                                                        GestureDetector(
                                                                          onTap:
                                                                              () async {
                                                                            final pickedDate =
                                                                                await showDatePicker(
                                                                              context: context,
                                                                              initialDate: expiredDate,
                                                                              firstDate: DateTime.now(),
                                                                              lastDate: DateTime(2101),
                                                                              builder: (context, child) {
                                                                                return Theme(
                                                                                  data: Theme.of(context).copyWith(
                                                                                    colorScheme: ColorScheme.light(
                                                                                      primary: Colors.orange[600]!,
                                                                                    ),
                                                                                  ),
                                                                                  child: child!,
                                                                                );
                                                                              },
                                                                            );
                                                                            if (pickedDate !=
                                                                                null) {
                                                                              setState(() {
                                                                                expiredDate = pickedDate;
                                                                              });
                                                                            }
                                                                          },
                                                                          child:
                                                                              Container(
                                                                            width:
                                                                                double.infinity,
                                                                            padding:
                                                                                const EdgeInsets.all(16),
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: Colors.white,
                                                                              borderRadius: BorderRadius.circular(12),
                                                                              border: Border.all(color: Colors.grey[300]!),
                                                                              boxShadow: [
                                                                                BoxShadow(
                                                                                  color: Colors.grey.withOpacity(0.1),
                                                                                  spreadRadius: 1,
                                                                                  blurRadius: 4,
                                                                                  offset: const Offset(0, 2),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                            child:
                                                                                Row(
                                                                              children: [
                                                                                const SizedBox(width: 12),
                                                                                Text(
                                                                                  'Expires: ${DateFormat('dd/MM/yyyy').format(expiredDate)}',
                                                                                  style: const TextStyle(
                                                                                    fontSize: 16,
                                                                                    color: Colors.black87,
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                      height:
                                                                          24),

                                                                  // Action Buttons
                                                                  Row(
                                                                    children: [
                                                                      Expanded(
                                                                        child:
                                                                            TextButton(
                                                                          onPressed: () =>
                                                                              Navigator.pop(context),
                                                                          style:
                                                                              TextButton.styleFrom(
                                                                            padding:
                                                                                const EdgeInsets.symmetric(vertical: 16),
                                                                            shape:
                                                                                RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(12),
                                                                              side: BorderSide(color: Colors.grey[300]!),
                                                                            ),
                                                                          ),
                                                                          child:
                                                                              const Text(
                                                                            'Cancel',
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: 16,
                                                                              fontWeight: FontWeight.w600,
                                                                              color: Color.fromARGB(255, 53, 150, 105),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                          width:
                                                                              12),
                                                                      Expanded(
                                                                        child:
                                                                            ElevatedButton(
                                                                          onPressed:
                                                                              () {
                                                                            editReferralCode(
                                                                              id: code.id,
                                                                              code: codeController.text,
                                                                              description: descController.text,
                                                                              discount: int.tryParse(discountController.text) ?? 0,
                                                                              quotas: int.tryParse(quotasController.text) ?? 0,
                                                                              expiredDate: expiredDate,
                                                                            );
                                                                            Navigator.pop(context);
                                                                          },
                                                                          style:
                                                                              ElevatedButton.styleFrom(
                                                                            backgroundColor: const Color.fromARGB(
                                                                                255,
                                                                                53,
                                                                                150,
                                                                                105),
                                                                            padding:
                                                                                const EdgeInsets.symmetric(vertical: 16),
                                                                            shape:
                                                                                RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(12),
                                                                            ),
                                                                          ),
                                                                          child:
                                                                              const Text(
                                                                            'Update Code',
                                                                            style:
                                                                                TextStyle(
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
                                                          ));
                                            },
                                          );
                                        },
                                        tooltip: 'Edit',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            deleteReferralCode(code.id),
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
                                        label:
                                            Text('Discount: ${code.discount}%'),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.timer,
                                              size: 16,
                                              color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Expired: ${DateFormat('dd/MM/yyyy HH:mm').format(code.expiredDate)}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today,
                                              size: 16,
                                              color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            code.createdAt != null
                                                ? 'Created: ${DateFormat('dd/MM/yyyy HH:mm').format(code.createdAt!)}'
                                                : 'Created: -',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey),
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
          ],
        ),
        bottomNavigationBar: _buildNavbar());
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
                onTap: () {},
              ),
              Divider(),
              _buildMenuOption(
                icon: Icons.discount,
                label: 'Discount',
                onTap: () => _navigateTo(DiscountPage(
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
                  isManager: widget.isManager,
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
    Navigator.pushReplacement(
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
