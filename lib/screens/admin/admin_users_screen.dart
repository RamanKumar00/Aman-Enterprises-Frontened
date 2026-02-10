import 'package:flutter/material.dart';
import 'package:aman_enterprises/services/api_service.dart';
import 'package:aman_enterprises/services/user_service.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final token = UserService().authToken;
    if (token == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getAllUsersAdmin(token);
      if (response.success && response.data != null) {
        setState(() {
          _users = response.data!['users'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateRole(String userId, String currentRole, String newRole) async {
    if (currentRole == newRole) return;

    final token = UserService().authToken;
    if (token == null) return;

    // Optimistic update or wait? Let's wait.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Updating role...')),
    );

    final response = await ApiService.updateUserRole(token, userId, newRole);
    if (!mounted) return;

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Role updated to $newRole'), backgroundColor: Colors.green),
      );
      _fetchUsers(); // Refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text('Manage Users', style: AppTextStyles.headingMedium),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final String role = user['role'] ?? 'Customer';
                    final String userId = user['_id'];
                    final String phone = user['phone'] ?? 'N/A';
                    final String email = user['email'] ?? 'N/A';
                    final String shopName = user['shopName'] ?? 'No Shop Name';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    shopName,
                                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(role).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _getRoleColor(role)),
                                  ),
                                  child: Text(
                                    role,
                                    style: TextStyle(color: _getRoleColor(role), fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Phone: $phone', style: AppTextStyles.bodyMedium),
                            Text('Email: $email', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600])),
                            const SizedBox(height: 12),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Change Role: "),
                                DropdownButton<String>(
                                  value: role,
                                  underline: Container(),
                                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
                                  items: const [
                                    DropdownMenuItem(value: 'Customer', child: Text('Customer')),
                                    DropdownMenuItem(value: 'RetailUser', child: Text('Retailer')),
                                    DropdownMenuItem(value: 'Admin', child: Text('Admin')), // Careful with allowing Admin creation
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                       _updateRole(userId, role, val);
                                    }
                                  },
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin': return Colors.red;
      case 'RetailUser': return Colors.blue;
      case 'Customer': return Colors.green;
      default: return Colors.grey;
    }
  }
}
