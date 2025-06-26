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
  String? selectedRoleFilter;

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20),),
          backgroundColor: Colors.white,
          title: Center(
            child: Text(
              'Edit User',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "NAME",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 18),

                  // Email
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "EMAIL",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        fontSize: 13,
                        color: Colors.black54,
                      ),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 18),

                  // Role
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "USER ROLE",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  isRoleLoading
                      ? const CircularProgressIndicator()
                      : DropdownButtonFormField<int>(
                          value: selectedRoleId,
                          decoration: InputDecoration(
                            hintText: 'Role',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: roleOptions
                              .map((role) => DropdownMenuItem(
                                    value: role.value,
                                    child: Text(role.label),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedRoleId = value ?? user.roleId;
                            });
                          },
                          validator: (value) => value == null ? 'Please select a role' : null,
                        ),
                  const SizedBox(height: 18),

                  // Outlet
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "ASSIGN OUTLET",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  isOutletLoading
                      ? const CircularProgressIndicator()
                      : DropdownButtonFormField<String>(
                          value: selectedOutletId,
                          decoration: InputDecoration(
                            hintText: 'Outlet',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: outletOptions
                              .map((outlet) => DropdownMenuItem(
                                    value: outlet.id,
                                    child: Text(outlet.outlet_name),
                                  ))
                              .toList(),
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
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          actions: [
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
                                    const SnackBar(content: Text('User updated successfully')),
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
                            'Save',
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            title: const Center(
              child: Text(
                'Create User',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "NAME",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 18),

                    // Email
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "EMAIL",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          fontSize: 13,
                          color: Colors.black54,
                        ),
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 18),

                    // Password
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "PASSWORD",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 18),

                    // Role
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "USER ROLE",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    isRoleLoading
                        ? const CircularProgressIndicator()
                        : DropdownButtonFormField<int>(
                            value: selectedRoleId,
                            decoration: InputDecoration(
                              hintText: 'Role',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: roleOptions
                                .map((role) => DropdownMenuItem(
                                      value: role.value,
                                      child: Text(role.label),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedRoleId = value;
                              });
                            },
                            validator: (value) => value == null ? 'Please select a role' : null,
                          ),
                    const SizedBox(height: 18),

                    // Outlet
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "ASSIGN OUTLET",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    isOutletLoading
                        ? const CircularProgressIndicator()
                        : DropdownButtonFormField<String>(
                            value: selectedOutletId,
                            decoration: InputDecoration(
                              hintText: 'Outlet',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: outletOptions
                                .map((outlet) => DropdownMenuItem(
                                      value: outlet.id,
                                      child: Text(outlet.outlet_name),
                                    ))
                                .toList(),
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
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            actions: [
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
                                      const SnackBar(content: Text('User created successfully')),
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
        );
      },
    );
  }

  void _deleteUser(User user) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        title: const Center(
          child: Text(
            'Delete User',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
        ),
        content: Text(
          'Apakah anda yakin ingin menghapus user ${user.name}?',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
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
                  onPressed: () async {
                    Navigator.of(context).pop(); // Tutup dialog sebelum proses
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator()),
                    );
                    try {
                      final response = await http.delete(
                        Uri.parse('$baseUrl/api/user/${user.id}'),
                        headers: {
                          'Content-Type': 'application/json',
                          'Accept': 'application/json',
                          'Authorization': 'Bearer ${widget.token}',
                        },
                      );
                      if (!mounted) return;
                      Navigator.of(context).pop(); // Tutup loading
                      if (response.statusCode == 200) {
                        fetchUsers(widget.token, widget.outletId);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('User deleted successfully'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else {
                        final error = json.decode(response.body);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(error['message'] ?? 'Failed to delete user'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      if (!mounted) return;
                      Navigator.of(context).pop(); // Tutup loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
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
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage User', style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),  ),
        backgroundColor: const Color.fromARGB(255, 53, 150, 105
),
        elevation: 1,
      ),

                  backgroundColor: const Color.fromARGB(255, 245, 244, 244),

      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? Center(child: Text('No users found'))
              : Column(
                children: [
                  // Dropdown filter role
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        Text('Filter by Role: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(width: 12),
                        Expanded(
                          child: DropdownButton<String>(
                             dropdownColor: Colors.white,
                            value: selectedRoleFilter,
                            hint: Text('All Roles'),
                            isExpanded: true,
                            items: [
                              DropdownMenuItem<String>(
                                
                                value: null,
                                child: Text('All Roles'),
                              ),
                              ...roleOptions.map((role) => DropdownMenuItem<String>(
                                    value: role.label,
                                    child: Text(role.label),
                                  )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedRoleFilter = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: users
                          .where((u) => selectedRoleFilter == null || u.role == selectedRoleFilter)
                          .length,
                      itemBuilder: (context, idx) {
                        final filteredUsers = users
                            .where((u) => selectedRoleFilter == null || u.role == selectedRoleFilter)
                            .toList();
                        final user = filteredUsers[idx];
                        return Card(
                          color: Colors.white,
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
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: const Color.fromARGB(255, 101, 104, 106)),
                                  onPressed: () => _showEditUserDialog(user),
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteUser(user),
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateUserDialog,
        backgroundColor: const Color.fromARGB(255, 53, 150, 105
),
        child: Icon(Icons.add, color: const Color.fromARGB(255, 255, 255, 255)),
      ),
    );
  }
}