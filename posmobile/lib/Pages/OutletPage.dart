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
    // Implementation for edit dialog
  }

  Future<void> _confirmDelete(Outlet outlet) async {
    // Implementation for delete confirmation
  }

  Future<void> _showCreateOutletDialog() async {
    // Show dialog for creating a new outlet
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create New Outlet'),
        content: Text('Create outlet dialog implementation here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }
}