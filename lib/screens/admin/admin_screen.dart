// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/screens/admin/admin_screen.dart
// PURPOSE: Full Admin Panel — Phase 4
//   - Stats (total users, doctors, patients)
//   - Full user list with role badges
//   - Change user roles via popup menu
//   - Activate / Deactivate users
//   - Add Doctor (uses secondary Firebase app so admin stays logged in)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterRole = 'all'; // 'all', 'patient', 'doctor', 'admin'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // ── Add Doctor using secondary Firebase app ────────────────────────────────
  // Critical: Using secondary app prevents admin from being logged out
  void _showAddDoctorDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (dialogCtx, setDialog) => AlertDialog(
            title: const Text('Add New Doctor'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: "Doctor's Full Name",
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Temporary Password',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        final email = emailCtrl.text.trim();
                        final pass = passCtrl.text.trim();

                        if (name.isEmpty || email.isEmpty || pass.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('All fields are required')),
                          );
                          return;
                        }
                        if (pass.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Password min 6 characters')),
                          );
                          return;
                        }

                        setDialog(() => isLoading = true);
                        FirebaseApp? secondaryApp;

                        try {
                          // Secondary app keeps admin session intact
                          secondaryApp = await Firebase.initializeApp(
                            name: 'secondaryApp',
                            options: Firebase.app().options,
                          );
                          final secondaryAuth =
                              FirebaseAuth.instanceFor(app: secondaryApp);

                          final cred = await secondaryAuth
                              .createUserWithEmailAndPassword(
                            email: email,
                            password: pass,
                          );

                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(cred.user!.uid)
                              .set({
                            'uid': cred.user!.uid,
                            'name': name,
                            'email': email,
                            'role': 'doctor',
                            'createdAt': FieldValue.serverTimestamp(),
                            'isActive': true,
                          });

                          await secondaryAuth.signOut();

                          if (dialogCtx.mounted) {
                            Navigator.pop(dialogCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Dr. $name added successfully!'),
                                  backgroundColor: Colors.green),
                            );
                          }
                        } on FirebaseAuthException catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    e.code == 'email-already-in-use'
                                        ? 'Email already registered'
                                        : 'Error: ${e.message}')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        } finally {
                          await secondaryApp?.delete();
                          setDialog(() => isLoading = false);
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Add Doctor'),
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDoctorDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Doctor'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data!.docs;
          final allUsers = allDocs
              .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
              .toList();

          // Count stats
          final totalDoctors =
              allUsers.where((u) => u['role'] == 'doctor').length;
          final totalPatients =
              allUsers.where((u) => u['role'] == 'patient').length;
          final totalAdmins =
              allUsers.where((u) => u['role'] == 'admin').length;

          // Apply role filter
          var filtered = _filterRole == 'all'
              ? allUsers
              : allUsers.where((u) => u['role'] == _filterRole).toList();

          // Apply search filter
          if (_searchQuery.isNotEmpty) {
            filtered = filtered.where((u) {
              final name = (u['name'] as String? ?? '').toLowerCase();
              final email = (u['email'] as String? ?? '').toLowerCase();
              return name.contains(_searchQuery) ||
                  email.contains(_searchQuery);
            }).toList();
          }

          return Column(
            children: [
              // ── Header ───────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: const BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('System Overview',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 12),
                    // Stats row
                    Row(
                      children: [
                        _statChip('${allUsers.length}', 'Total', Colors.white),
                        const SizedBox(width: 8),
                        _statChip('$totalDoctors', 'Doctors', Colors.blue.shade200),
                        const SizedBox(width: 8),
                        _statChip('$totalPatients', 'Patients', Colors.green.shade200),
                        const SizedBox(width: 8),
                        _statChip('$totalAdmins', 'Admins', Colors.orange.shade200),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Search + Filter ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            })
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Role filter chips
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['all', 'patient', 'doctor', 'admin']
                        .map((role) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(role == 'all'
                                    ? 'All'
                                    : role[0].toUpperCase() +
                                        role.substring(1)),
                                selected: _filterRole == role,
                                onSelected: (_) =>
                                    setState(() => _filterRole = role),
                                selectedColor:
                                    Colors.deepPurple.shade100,
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),

              // ── User List ────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text('No users found.',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(12, 4, 12, 100),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _buildUserCard(filtered[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final userId = user['id'] as String;
    final name = (user['name'] as String?) ?? 'Unknown';
    final email = (user['email'] as String?) ?? '';
    final role = (user['role'] as String?) ?? 'patient';
    final isActive = (user['isActive'] as bool?) ?? true;

    Color roleColor;
    if (role == 'admin') roleColor = Colors.deepPurple;
    else if (role == 'doctor') roleColor = Colors.blue;
    else roleColor = Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: roleColor.withOpacity(0.15),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
                color: roleColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email, style: const TextStyle(fontSize: 12)),
            if (!isActive)
              const Text('DEACTIVATED',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.red,
                      fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Role badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                role.toUpperCase(),
                style: TextStyle(
                    color: roleColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 4),
            // Options menu
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'activate' || value == 'deactivate') {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .update({'isActive': value == 'activate'});
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(value == 'activate'
                        ? '$name activated'
                        : '$name deactivated'),
                  ));
                } else {
                  // Role change
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .update({'role': value});
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('$name set as $value'),
                  ));
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'patient', child: Text('Set as Patient')),
                const PopupMenuItem(
                    value: 'doctor', child: Text('Set as Doctor')),
                const PopupMenuItem(
                    value: 'admin', child: Text('Set as Admin')),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: isActive ? 'deactivate' : 'activate',
                  child: Text(
                    isActive ? 'Deactivate User' : 'Activate User',
                    style: TextStyle(
                        color: isActive ? Colors.red : Colors.green),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
}