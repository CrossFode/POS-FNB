import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
// import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../model/Model.dart'; // Add this import

class OutletPage extends StatefulWidget {
  final String token;
  final String outletId;

  const OutletPage({
    Key? key,
    required this.token,
    required this.outletId,
  }) : super(key: key);

  @override
  _OutletPageState createState() => _OutletPageState();
}

class _OutletPageState extends State<OutletPage> {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
  bool isLoading = true;
  List<Outlet> outlets = []; // Changed from OutletData to Outlet

  @override
  void initState() {
    super.initState();
    fetchOutletData(widget.token, widget.outletId);
  }

  Future<void> fetchOutletData(token, outletId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/outlet'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final OutletResponse outletResponse =
            OutletResponse.fromJson(json.decode(response.body));
        setState(() {
          outlets = outletResponse.data;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading outlets: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleOutletStatus(Outlet outlet, bool newStatus) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/api/outlet/status/${outlet.id}'), // Changed from /status endpoint
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'is_active': newStatus,
      }),
    );

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      // Update local state immediately for better UX
      setState(() {
        outlet.isActive = newStatus ? 1 : 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Outlet status updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: ${response.body}')),
      );
    }
  } catch (e) {
    print('Error updating outlet status: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Outlets',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 53, 150, 105),
        elevation: 1,
      ),

            backgroundColor: const Color.fromARGB(255, 245, 244, 244),

      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: outlets
                      .map((outlet) => _buildOutletCard(outlet))
                      .toList(),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateOutletDialog(),
        backgroundColor: const Color.fromARGB(255, 53, 150, 105
),
        child: Icon(Icons.add, color: const Color.fromARGB(255, 255, 255, 255)),
      ),
    );
  }

  Widget _buildOutletCard(Outlet outlet) {
  return Card(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: Colors.grey[300]!, width: 1),
    ),
    margin: EdgeInsets.only(bottom: 16),
    child: Stack(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Outlet Image remains the same
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: outlet.image != null
                          ? DecorationImage(
                              image: NetworkImage(outlet.image!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: Colors.grey[300],
                    ),
                    child: outlet.image == null
                        ? Icon(Icons.store, color: Colors.grey[500], size: 40)
                        : null,
                  ),
                  SizedBox(width: 16),
                  // Outlet Details remain the same
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          outlet.outlet_name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          outlet.email,
                          style: TextStyle(color: Colors.blue[600]),
                        ),
                        SizedBox(height: 4),
                        Text(
                          outlet.latitude != null
                              ? 'Latitude: ${outlet.latitude}'
                              : 'Latitude: Not set',
                          style: TextStyle(color: const Color.fromARGB(255, 105, 105, 105))),
                        SizedBox(height: 4),
                        Text(
                          outlet.longitude != null
                              ? 'Longitude: ${outlet.longitude}'
                              : 'Longitude: Not set',
                          style: TextStyle(color: const Color.fromARGB(255, 105, 105, 105)),)
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Action Buttons remain the same
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _showEditOutletDialog(outlet),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color.fromARGB(255, 53, 150, 105),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _confirmDelete(outlet),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 14,
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
        // Updated Positioned widget with larger toggle button
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () async {
              await _toggleOutletStatus(outlet, outlet.isActive != 1);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Increased padding
              decoration: BoxDecoration(
                color: (outlet.isActive == 1 ? Colors.green : Colors.grey).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16), // Slightly larger border radius
                border: Border.all(
                  color: outlet.isActive == 1 ? Colors.green : Colors.grey,
                  width: 1.5, // Slightly thicker border
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    outlet.isActive == 1 ? Icons.check_circle : Icons.circle,
                    size: 18, // Slightly larger icon
                    color: outlet.isActive == 1 ? Colors.green : Colors.grey,
                  ),
                  SizedBox(width: 6), // Increased spacing
                  Text(
                    outlet.isActive == 1 ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      fontSize: 14, // Increased font size
                      fontWeight: FontWeight.bold,
                      color: outlet.isActive == 1 ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  // Add dialog implementations and other helper methods here
  Future<void> _showEditOutletDialog(Outlet outlet) async {
    final _formKey = GlobalKey<FormState>();
    TextEditingController nameController =
        TextEditingController(text: outlet.outlet_name);
    TextEditingController emailController =
        TextEditingController(text: outlet.email);
    TextEditingController longitudeController =
        TextEditingController(text: outlet.longitude ?? '');
    TextEditingController latitudeController =
        TextEditingController(text: outlet.latitude ?? '');
    // bool isDineIn = outlet.is_dinein ?? false;
    // bool isLabel = outlet.is_label ?? false;
    // bool isKitchen = outlet.is_kitchen ?? false;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('Edit Outlet'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Gambar dihapus
                    SizedBox(height: 0),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Outlet Name'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(labelText: 'Email'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: latitudeController,
                      decoration:
                          InputDecoration(labelText: 'Latitude (optional)'),
                      keyboardType: TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                    ),
                    TextFormField(
                      controller: longitudeController,
                      decoration:
                          InputDecoration(labelText: 'Longitude (optional)'),
                      keyboardType: TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                    ),
                    SizedBox(height: 16),
                    // CheckboxListTile untuk fitur lain jika ingin diaktifkan
                    // CheckboxListTile(
                    //   title: Text('DINE IN'),
                    //   value: isDineIn,
                    //   onChanged: (val) => setState(() => isDineIn = val ?? false),
                    // ),
                    // CheckboxListTile(
                    //   title: Text('PRINT LABEL'),
                    //   value: isLabel,
                    //   onChanged: (val) => setState(() => isLabel = val ?? false),
                    // ),
                    // CheckboxListTile(
                    //   title: Text('PRINT KITCHEN'),
                    //   value: isKitchen,
                    //   onChanged: (val) => setState(() => isKitchen = val ?? false),
                    // ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => isSubmitting = true);
                          try {
                            final response = await http.put(
                              Uri.parse('$baseUrl/api/outlet/${outlet.id}'),
                              headers: {
                                'Authorization': 'Bearer ${widget.token}',
                                'Accept': 'application/json',
                                'Content-Type': 'application/json',
                              },
                              body: json.encode({
                                'outlet_name': nameController.text,
                                'email': emailController.text,
                                // 'is_dinein': isDineIn,
                                // 'is_label': isLabel,
                                // 'is_kitchen': isKitchen,
                                if (latitudeController.text.isNotEmpty)
                                  'latitude': latitudeController.text,
                                if (longitudeController.text.isNotEmpty)
                                  'longitude': longitudeController.text,
                              }),
                            );

                            if (response.statusCode == 200) {
                              Navigator.pop(context);
                              fetchOutletData(widget.token, widget.outletId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Outlet updated successfully')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Failed to update outlet')),
                              );
                            }
                            print('Status: ${response.statusCode}');
                            print('Body: ${response.body}');
                            print('Headers: ${response.headers}');
                            print('Outleet: ${outlet.id}');
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          } finally {
                            setState(() => isSubmitting = false);
                          }
                        }
                      },
                child: isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Update Outlet'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(Outlet outlet) async {
    bool isDeleting = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('Delete Outlet'),
            content:
                Text('Are you sure you want to delete ${outlet.outlet_name}?'),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: isDeleting
                    ? null
                    : () async {
                        setState(() => isDeleting = true);
                        try {
                          final response = await http.delete(
                            Uri.parse('$baseUrl/api/outlet/${outlet.id}'),
                            headers: {
                              'Authorization': 'Bearer ${widget.token}',
                              'Accept': 'application/json',
                            },
                          );

                          if (response.statusCode == 200 ||
                              response.statusCode == 204) {
                            Navigator.pop(
                                context); // Tutup dialog setelah sukses
                            fetchOutletData(widget.token, widget.outletId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Outlet deleted successfully')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Failed to delete outlet')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      },
                child: isDeleting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('Delete'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCreateOutletDialog() async {
    final _formKey = GlobalKey<FormState>();
    TextEditingController nameController = TextEditingController();
    TextEditingController emailController = TextEditingController();
    TextEditingController longitudeController = TextEditingController(); // Tambahan
    TextEditingController latitudeController = TextEditingController();  // Tambahan
    // bool isDineIn = false;
    // bool isLabel = false;
    // bool isKitchen = false;
  
    File? imageFile;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (context) {
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      const Center(
                        child: Text(
                          'Create New Outlet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Image picker
                      Center(
                        child: GestureDetector(
                          onTap: () async {
                            // Implement image picker if needed
                          },
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                              image: imageFile != null
                                  ? DecorationImage(
                                      image: FileImage(imageFile!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: imageFile == null
                                ? Icon(Icons.add_a_photo,
                                    color: Colors.grey[600], size: 40)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Outlet Name
                      const Text(
                        "OUTLET NAME",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'Outlet Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 18),

                      // Email
                      const Text(
                        "EMAIL",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 18),

                      // Latitude
                      const Text(
                        "LATITUDE (OPTIONAL)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: latitudeController,
                        decoration: InputDecoration(
                          hintText: 'Latitude',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                      ),
                      const SizedBox(height: 18),

                      // Longitude
                      const Text(
                        "LONGITUDE (OPTIONAL)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: longitudeController,
                        decoration: InputDecoration(
                          hintText: 'Longitude',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                      ),
                      const SizedBox(height: 18),

                      // CheckboxListTile untuk fitur lain
                      // CheckboxListTile(
                      //   title: const Text('DINE IN'),
                      //   value: isDineIn,
                      //   onChanged: (val) => setState(() => isDineIn = val ?? false),
                      //   controlAffinity: ListTileControlAffinity.leading,
                      //   activeColor: const Color.fromARGB(255, 53, 150, 105),
                      //   contentPadding: EdgeInsets.zero,
                      // ),
                      // CheckboxListTile(
                      //   title: const Text('PRINT LABEL'),
                      //   value: isLabel,
                      //   onChanged: (val) => setState(() => isLabel = val ?? false),
                      //   controlAffinity: ListTileControlAffinity.leading,
                      //   activeColor: const Color.fromARGB(255, 53, 150, 105),
                      //   contentPadding: EdgeInsets.zero,
                      // ),
                      // CheckboxListTile(
                      //   title: const Text('PRINT KITCHEN'),
                      //   value: isKitchen,
                      //   onChanged: (val) => setState(() => isKitchen = val ?? false),
                      //   controlAffinity: ListTileControlAffinity.leading,
                      //   activeColor: const Color.fromARGB(255, 53, 150, 105),
                      //   contentPadding: EdgeInsets.zero,
                      // ),
                      // const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: isSubmitting ? null : () => Navigator.pop(context),
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
                                  color: Color.fromARGB(255, 53, 150, 105),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      if (_formKey.currentState!.validate()) {
                                        setState(() => isSubmitting = true);
                                        try {
                                          var request = http.MultipartRequest(
                                            'POST',
                                            Uri.parse('$baseUrl/api/outlet'),
                                          );
                                          request.headers.addAll({
                                            'Authorization': 'Bearer ${widget.token}',
                                            'Accept': 'application/json',
                                          });
                                          request.fields['outlet_name'] = nameController.text;
                                          request.fields['email'] = emailController.text;
                                          // request.fields['is_dinein'] = isDineIn ? '1' : '0';
                                          // request.fields['is_label'] = isLabel ? '1' : '0';
                                          // request.fields['is_kitchen'] = isKitchen ? '1' : '0';
                                          if (latitudeController.text.isNotEmpty) {
                                            request.fields['latitude'] = latitudeController.text;
                                          }
                                          if (longitudeController.text.isNotEmpty) {
                                            request.fields['longitude'] = longitudeController.text;
                                          }
                                          if (imageFile != null) {
                                            request.files.add(
                                                await http.MultipartFile.fromPath(
                                                    'image', imageFile!.path));
                                          }
                                          final streamedResponse = await request.send();
                                          final response = await http.Response.fromStream(streamedResponse);

                                          if (response.statusCode == 201 ||
                                              response.statusCode == 200) {
                                            Navigator.pop(context);
                                            fetchOutletData(widget.token, widget.outletId);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Outlet created successfully')),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Failed to create outlet')),
                                            );
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error: $e')),
                                          );
                                        } finally {
                                          setState(() => isSubmitting = false);
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 53, 150, 105),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text(
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
            ),
          ),
        );
      },
    );
  }
}
