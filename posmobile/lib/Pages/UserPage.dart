import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../model/Model.dart';

class UserPage extends StatefulWidget {
  final String token;
  final String outletId;

  const UserPage({
    Key? key,
    required this.token,
    required this.outletId,
  }) : super(key: key);

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
  bool isLoading = true;
  List<User> users = [];
  List<Outlet> outletOptions = [];
  List<RoleModel> roleOptions = [];
  bool isOutletLoading = false;
  bool isRoleLoading = false;

  @override
  void initState() {
    super.initState();
    fetchUsers(widget.token, widget.outletId);
    fetchOutlets(widget.token);
    fetchRoles(widget.token);
  }

  Future<void> fetchUsers(token, outletId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/user'), headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final UserResponse outletResponse = UserResponse.fromJson(
          json.decode(response.body),
        );
        setState(() {
          users = outletResponse.data;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load users: ${response.statusCode}')),
        );
      }
    } catch (error) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users: $error')),
      );
    }
  }

  Future<void> fetchRoles(String token) async {
  setState(() => isRoleLoading = true);
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/roles'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body)['data'];
      setState(() {
        roleOptions = responseData.map((role) => RoleModel.fromJson(role)).toList();
        isRoleLoading = false;
      });
    } else {
      setState(() => isRoleLoading = false);
    }
  } catch (e) {
    setState(() => isRoleLoading = false);
  }
}

  Future<void> fetchOutlets(String token) async {
    setState(() => isOutletLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/outlet'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final OutletResponse outletResponse = OutletResponse.fromJson(json.decode(response.body));
        setState(() {
          outletOptions = outletResponse.data;
          isOutletLoading = false;
        });
      } else {
        setState(() => isOutletLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load outlets: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() => isOutletLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading outlets: $e')),
      );
    }
  }

  Future<void> _showEditUserDialog(User user) async {
    final _formKey = GlobalKey<FormState>();
    TextEditingController nameController = TextEditingController(text: user.name);
    TextEditingController emailController = TextEditingController(text: user.email);
    int selectedRoleId = user.roleId;
    String? selectedOutletId = user.outlets.isNotEmpty ? user.outlets.first.id : null;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('Edit User'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Name'),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(labelText: 'Email'),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    
                    SizedBox(height: 12),
                    Text('User Role', style: TextStyle(fontWeight: FontWeight.bold)),
                    isRoleLoading
                        ? CircularProgressIndicator()
                        : DropdownButtonFormField<int>(
                            value: selectedRoleId,
                            decoration: InputDecoration(labelText: 'Role'),
                            items: roleOptions.map((role) => DropdownMenuItem(
                              value: role.value,
                              child: Text(role.label),
                            )).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedRoleId = value ?? user.roleId;
                              });
                            },
                            validator: (value) => value == null ? 'Please select a role' : null,
                          ),

                    SizedBox(height: 12),
                    Text('Assign Outlet', style: TextStyle(fontWeight: FontWeight.bold)),
                    
                    DropdownButtonFormField<String>(
                      value: selectedOutletId,
                      decoration: InputDecoration(labelText: 'Outlet'),
                      items: outletOptions.map((outlet) => DropdownMenuItem(
                        value: outlet.id,
                        child: Text(outlet.outlet_name),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedOutletId = value;
                        });
                      },
                      validator: (value) => value == null ? 'Please select an outlet' : null,
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
                onPressed: isSubmitting ? null : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => isSubmitting = true);
                    try {
                      final response = await http.put(
                        Uri.parse('$baseUrl/api/user/${user.id}'),
                        headers: {
                          'Content-Type': 'application/json',
                          'Accept': 'application/json',
                          'Authorization': 'Bearer ${widget.token}',
                        },
                        body: json.encode({
                          'name': nameController.text,
                          'email': emailController.text,
                          'role_id': selectedRoleId,
                          'outlets_id': selectedOutletId != null ? [selectedOutletId] : [],
                        }),
                      );
                      if (response.statusCode == 200) {
                        Navigator.pop(context);
                        fetchUsers(widget.token, widget.outletId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('User updated successfully')),
                        );
                      } else {
                        final error = json.decode(response.body);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error['message'] ?? 'Failed to update user')),
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
                    ? CircularProgressIndicator()
                    : Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCreateUserDialog() async {
    final _formKey = GlobalKey<FormState>();
    TextEditingController nameController = TextEditingController();
    TextEditingController emailController = TextEditingController();
    TextEditingController passwordController = TextEditingController();
    int? selectedRoleId;
    String? selectedOutletId;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('Create User'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Name'),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(labelText: 'Email'),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: passwordController,
                      decoration: InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),

                    SizedBox(height: 12),
                    Text('User Role', style: TextStyle(fontWeight: FontWeight.bold)),
                    isRoleLoading
                        ? CircularProgressIndicator()
                        : DropdownButtonFormField<int>(
                            value: selectedRoleId,
                            decoration: InputDecoration(labelText: 'Role'),
                            items: roleOptions.map((role) => DropdownMenuItem<int>(
                              value: role.value,
                              child: Text(role.label),
                            )).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedRoleId = value!;
                              });
                            },
                            validator: (value) => value == null ? 'Please select a role' : null,
                          ),
                    
                    SizedBox(height: 12),
                    Text('Assign Outlet', style: TextStyle(fontWeight: FontWeight.bold)),
                    
                    DropdownButtonFormField<String>(
                      value: selectedOutletId,
                      decoration: InputDecoration(labelText: 'Outlet'),
                      items: outletOptions.map((outlet) => DropdownMenuItem(
                        value: outlet.id,
                        child: Text(outlet.outlet_name),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedOutletId = value;
                        });
                      },
                      validator: (value) => value == null ? 'Please select an outlet' : null,
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
                            final response = await http.post(
                              Uri.parse('$baseUrl/api/user'),
                              headers: {
                                'Content-Type': 'application/json',
                                'Accept': 'application/json',
                                'Authorization': 'Bearer ${widget.token}',
                              },
                              body: json.encode({
                                'name': nameController.text,
                                'email': emailController.text,
                                'password': passwordController.text,
                                'role_id': selectedRoleId,
                                'outlets_id': selectedOutletId != null ? [selectedOutletId] : [],
                              }),
                            );
                            if (response.statusCode == 201 || response.statusCode == 200) {
                              Navigator.pop(context);
                              fetchUsers(widget.token, widget.outletId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('User created successfully')),
                              );
                            } else {
                              final error = json.decode(response.body);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error['message'] ?? 'Failed to create user')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage User'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? Center(child: Text('No users found'))
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, idx) {
                    final user = users[idx];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            user.name.isNotEmpty ? user.name[0] : '?',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(user.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.email),
                            Text('Role: ${user.role}', style: TextStyle(fontSize: 12)),
                            if (user.outlets.isNotEmpty)
                              Text(
                                'Outlet: ${user.outlets.first.outletName}',
                                style: TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                        onTap: () => _showEditUserDialog(user),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateUserDialog,
        backgroundColor: Colors.white,
        child: Icon(Icons.add, color: Colors.grey[800]),
      ),
    );
  }
}