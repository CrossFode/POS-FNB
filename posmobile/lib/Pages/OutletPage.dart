import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
// import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../model/Model.dart';  // Add this import

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
  List<Outlet> outlets = [];  // Changed from OutletData to Outlet

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
        final OutletResponse outletResponse = OutletResponse.fromJson(
          json.decode(response.body)
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Outlets'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: outlets.map((outlet) => _buildOutletCard(outlet)).toList(),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateOutletDialog(),
        backgroundColor: Colors.white,
        child: Icon(Icons.add, color: Colors.grey[800]),
      ),
    );
  }

  Widget _buildOutletCard(Outlet outlet) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Outlet Image
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
                // Outlet Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        outlet.outlet_name,  // Changed from name to outlet_name
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
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showEditOutletDialog(outlet),
                  icon: Icon(Icons.edit, size: 18),
                  label: Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue[600],
                  ),
                ),
                SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(outlet),
                  icon: Icon(Icons.delete, size: 18),
                  label: Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Add dialog implementations and other helper methods here
  Future<void> _showEditOutletDialog(Outlet outlet) async {
  final _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController(text: outlet.outlet_name);
  TextEditingController emailController = TextEditingController(text: outlet.email);

  // bool isDineIn = outlet.is_dinein == 1;
  // bool isLabel = outlet.is_label == 1;
  // bool isKitchen = outlet.is_kitchen == 1;
  File? imageFile;
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
                  // Image picker (aktifkan jika ingin upload gambar)
                  GestureDetector(
                    onTap: () async {
                      // Aktifkan jika ingin support image_picker
                      // final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                      // if (picked != null) {
                      //   setState(() => imageFile = File(picked.path));
                      // }
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
                            : (outlet.image != null
                                ? DecorationImage(
                                    image: NetworkImage(outlet.image!),
                                    fit: BoxFit.cover,
                                  )
                                : null),
                      ),
                      child: imageFile == null && outlet.image == null
                          ? Icon(Icons.add_a_photo, color: Colors.grey[600], size: 40)
                          : null,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Outlet Name'),
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  ),
                  SizedBox(height: 16),
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
                          var request = http.MultipartRequest(
                            'POST', // Laravel FormData update biasanya pakai POST + _method=PUT
                            Uri.parse('$baseUrl/api/outlet/${outlet.id}'),
                          );
                          request.headers.addAll({
                            'Authorization': 'Bearer ${widget.token}',
                            'Accept': 'application/json',
                          });
                          request.fields['_method'] = 'PUT';
                          request.fields['outlet_name'] = nameController.text;
                          request.fields['email'] = emailController.text;
                          // request.fields['is_dinein'] = isDineIn ? '1' : '0';
                          // request.fields['is_label'] = isLabel ? '1' : '0';
                          // request.fields['is_kitchen'] = isKitchen ? '1' : '0';
                          if (imageFile != null) {
                            request.files.add(await http.MultipartFile.fromPath('image', imageFile!.path));
                          }
                          final streamedResponse = await request.send();
                          final response = await http.Response.fromStream(streamedResponse);

                          if (response.statusCode == 200) {
                            Navigator.pop(context);
                            fetchOutletData(widget.token, widget.outletId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Outlet updated successfully')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to update outlet')),
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
              child: isSubmitting
                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Save'),
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
            content: Text('Are you sure you want to delete ${outlet.outlet_name}?'),
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

    if (response.statusCode == 200 || response.statusCode == 204) {
  Navigator.pop(context); // Tutup dialog setelah sukses
  fetchOutletData(widget.token, widget.outletId);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Outlet deleted successfully')),
  );
} else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete outlet')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
                      },
                child: isDeleting
                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
    bool isDineIn = false;
    bool isLabel = false;
    bool isKitchen = false;
    File? imageFile;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('Create New Outlet'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image picker
                    GestureDetector(
                      onTap: () async {
                        // Gunakan image_picker jika ingin upload gambar
                        // final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                        // if (picked != null) {
                        //   setState(() => imageFile = File(picked.path));
                        // }
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
                            ? Icon(Icons.add_a_photo, color: Colors.grey[600], size: 40)
                            : null,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Outlet Name'),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(labelText: 'Email'),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: 16),
                    CheckboxListTile(
                      title: Text('DINE IN'),
                      value: isDineIn,
                      onChanged: (val) => setState(() => isDineIn = val ?? false),
                    ),
                    CheckboxListTile(
                      title: Text('PRINT LABEL'),
                      value: isLabel,
                      onChanged: (val) => setState(() => isLabel = val ?? false),
                    ),
                    CheckboxListTile(
                      title: Text('PRINT KITCHEN'),
                      value: isKitchen,
                      onChanged: (val) => setState(() => isKitchen = val ?? false),
                    ),
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
                            request.fields['is_dinein'] = isDineIn ? '1' : '0';
                            request.fields['is_label'] = isLabel ? '1' : '0';
                            request.fields['is_kitchen'] = isKitchen ? '1' : '0';
                            if (imageFile != null) {
                              request.files.add(await http.MultipartFile.fromPath('image', imageFile!.path));
                            }
                            final streamedResponse = await request.send();
                            final response = await http.Response.fromStream(streamedResponse);

                            if (response.statusCode == 201 || response.statusCode == 200) {
                              Navigator.pop(context);
                              fetchOutletData(widget.token, widget.outletId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Outlet created successfully')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to create outlet')),
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
                child: isSubmitting
                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Create'),
              ),
            ],
          ),
        );
      },
    );
  }
}