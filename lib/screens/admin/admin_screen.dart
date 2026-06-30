import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'feedback_management_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _filterRole = 'all';

  static const _c1 = Color(0xFF7B5EA7);
  static const _c2 = Color(0xFF4A3580);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign out?'),
        content:
            const Text('You will be returned to the login screen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: const Size(80, 40)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false);
    }
  }

  void _showAddDoctorDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialog) {
          bool isLoading = false;
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Add New Doctor'),
            content: SingleChildScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                        controller: nameCtrl,
                        textCapitalization:
                            TextCapitalization.words,
                        decoration: const InputDecoration(
                            labelText: "Doctor's Full Name",
                            prefixIcon:
                                Icon(Icons.person_outline))),
                    const SizedBox(height: 12),
                    TextField(
                        controller: emailCtrl,
                        keyboardType:
                            TextInputType.emailAddress,
                        decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon:
                                Icon(Icons.email_outlined))),
                    const SizedBox(height: 12),
                    TextField(
                        controller: passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: 'Temporary Password',
                            prefixIcon:
                                Icon(Icons.lock_outline))),
                  ]),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _c1,
                    minimumSize: const Size(100, 40)),
                onPressed: isLoading
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        final email = emailCtrl.text.trim();
                        final pass = passCtrl.text.trim();
                        if (name.isEmpty ||
                            email.isEmpty ||
                            pass.isEmpty) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                                  content: Text(
                                      'All fields required')));
                          return;
                        }
                        if (pass.length < 6) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                                  content: Text(
                                      'Password min 6 chars')));
                          return;
                        }
                        setDialog(() => isLoading = true);
                        FirebaseApp? secondaryApp;
                        try {
                          secondaryApp =
                              await Firebase.initializeApp(
                                  name: 'secondaryApp',
                                  options:
                                      Firebase.app().options);
                          final auth =
                              FirebaseAuth.instanceFor(
                                  app: secondaryApp);
                          final cred = await auth
                              .createUserWithEmailAndPassword(
                                  email: email,
                                  password: pass);
                          try {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(cred.user!.uid)
                                .set({
                              'uid': cred.user!.uid,
                              'name': name,
                              'email': email,
                              'role': 'doctor',
                              'createdAt':
                                  FieldValue.serverTimestamp(),
                              'isActive': true,
                            });
                          } catch (e) {
                            await cred.user!.delete();
                            rethrow;
                          }
                          await auth.signOut();
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                                    content: Text(
                                        'Dr. $name added!'),
                                    backgroundColor:
                                        AppColors.success));
                          }
                        } on FirebaseAuthException catch (e) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                                  content: Text(
                                      e.code ==
                                              'email-already-in-use'
                                          ? 'Email already registered'
                                          : 'Error: ${e.message}'),
                                  backgroundColor:
                                      AppColors.error));
                        } catch (e) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor:
                                      AppColors.error));
                        } finally {
                          await secondaryApp?.delete();
                          setDialog(() => isLoading = false);
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2))
                    : const Text('Add Doctor',
                        style:
                            TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _c1,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppGradients.adminHeader),
        ),
        title: const Text('SmartCare Admin'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
              icon: const Icon(Icons.reviews_outlined),
              tooltip: 'Feedback Management',
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const FeedbackManagementScreen()))),
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.adminHeader,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.button(_c1),
        ),
        child: FloatingActionButton.extended(
          onPressed: _showAddDoctorDialog,
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Add Doctor'),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: _c1));
          }

          final allUsers = snapshot.data!.docs
              .map((d) => {
                    'id': d.id,
                    ...d.data() as Map<String, dynamic>
                  })
              .toList();

          final totalDoctors =
              allUsers.where((u) => u['role'] == 'doctor').length;
          final totalPatients =
              allUsers.where((u) => u['role'] == 'patient').length;
          final totalAdmins =
              allUsers.where((u) => u['role'] == 'admin').length;

          var filtered = _filterRole == 'all'
              ? allUsers
              : allUsers
                  .where((u) => u['role'] == _filterRole)
                  .toList();

          if (_searchQuery.isNotEmpty) {
            filtered = filtered.where((u) {
              final name =
                  (u['name'] as String? ?? '').toLowerCase();
              final email =
                  (u['email'] as String? ?? '').toLowerCase();
              return name.contains(_searchQuery) ||
                  email.contains(_searchQuery);
            }).toList();
          }

          return Column(children: [
            // Gradient header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [_c1, _c2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('System Overview',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    Row(children: [
                      _chip(
                          '${allUsers.length}', 'Total', Colors.white),
                      const SizedBox(width: 8),
                      _chip('$totalDoctors', 'Doctors',
                          const Color(0xFF7DD3F8)),
                      const SizedBox(width: 8),
                      _chip('$totalPatients', 'Patients',
                          const Color(0xFF6EE7B7)),
                      const SizedBox(width: 8),
                      _chip('$totalAdmins', 'Admins',
                          const Color(0xFFC4B5FD)),
                    ]),
                  ]),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppColors.textSecondary),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          })
                      : null,
                ),
              ),
            ),

            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['all', 'patient', 'doctor', 'admin']
                      .map((role) {
                    final selected = _filterRole == role;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(role == 'all'
                            ? 'All'
                            : role[0].toUpperCase() +
                                role.substring(1)),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _filterRole = role),
                        selectedColor: _c1.withOpacity(0.15),
                        checkmarkColor: _c1,
                        labelStyle: TextStyle(
                          color: selected
                              ? _c1
                              : AppColors.textSecondary,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 48,
                            color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text('No users found',
                            style: TextStyle(
                                color: AppColors.textSecondary)),
                      ],
                    ))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          16, 4, 16, 100),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final u = filtered[i];
                        final userId = u['id'] as String;
                        final name =
                            (u['name'] as String?) ?? 'Unknown';
                        final email =
                            (u['email'] as String?) ?? '';
                        final role =
                            (u['role'] as String?) ?? 'patient';
                        final isActive =
                            (u['isActive'] as bool?) ?? true;

                        Color roleColor;
                        if (role == 'admin') {
                          roleColor = _c1;
                        } else if (role == 'doctor') {
                          roleColor = const Color(0xFF0891B2);
                        } else {
                          roleColor = AppColors.success;
                        }

                        return Container(
                          margin:
                              const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(AppRadius.card),
                            boxShadow: AppShadows.card,
                            border: isActive
                                ? null
                                : Border.all(
                                    color: AppColors.error
                                        .withOpacity(0.4)),
                          ),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppRadius.card),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  // Left role accent bar
                                  Container(width: 5, color: roleColor),
                                  Expanded(
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                            leading: Container(
                              width: 46,
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    roleColor,
                                    roleColor.withOpacity(0.7),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Row(children: [
                              Expanded(
                                  child: Text(name,
                                      style: TextStyle(
                                          fontWeight:
                                              FontWeight.w600,
                                          decoration: isActive
                                              ? null
                                              : TextDecoration
                                                  .lineThrough))),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      roleColor,
                                      roleColor.withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(
                                    role.toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.white,
                                        fontWeight:
                                            FontWeight.w700)),
                              ),
                            ]),
                            subtitle: Text(email,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color:
                                        AppColors.textSecondary)),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert,
                                  color:
                                      AppColors.textSecondary),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
                              onSelected: (value) async {
                                if (value == 'activate' ||
                                    value == 'deactivate') {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(userId)
                                      .update({
                                    'isActive':
                                        value == 'activate'
                                  });
                                  if (mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                            content: Text(value ==
                                                    'activate'
                                                ? '$name activated'
                                                : '$name deactivated'),
                                            backgroundColor: value ==
                                                    'activate'
                                                ? AppColors.success
                                                : AppColors.error));
                                  }
                                } else {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(userId)
                                      .update({'role': value});
                                  if (mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                            content: Text(
                                                '$name set as $value'),
                                            backgroundColor:
                                                AppColors.success));
                                  }
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                    value: 'patient',
                                    child:
                                        Text('Set as Patient')),
                                const PopupMenuItem(
                                    value: 'doctor',
                                    child: Text('Set as Doctor')),
                                const PopupMenuItem(
                                    value: 'admin',
                                    child: Text('Set as Admin')),
                                const PopupMenuDivider(),
                                PopupMenuItem(
                                  value: isActive
                                      ? 'deactivate'
                                      : 'activate',
                                  child: Text(
                                    isActive
                                        ? 'Deactivate User'
                                        : 'Activate User',
                                    style: TextStyle(
                                        color: isActive
                                            ? AppColors.error
                                            : AppColors.success),
                                  ),
                                ),
                              ],
                            ),
                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _chip(String value, String label, Color textColor) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(children: [
              Text(value,
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20)),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 10)),
            ]),
          ),
        ),
      );
}