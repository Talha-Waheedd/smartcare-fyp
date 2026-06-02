// FILE: lib/screens/patient/health_record_screen.dart
// PURPOSE: Patient can upload PDFs/images as health records and view them.
//          Uses Firebase Storage for file storage + Firestore for metadata.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:io';
import '../../models/health_record_model.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class HealthRecordScreen extends StatefulWidget {
  const HealthRecordScreen({super.key});

  @override
  State<HealthRecordScreen> createState() => _HealthRecordScreenState();
}

class _HealthRecordScreenState extends State<HealthRecordScreen> {
  String? _uid;
  bool _isUploading = false;
  double _uploadProgress = 0;
  StreamSubscription<TaskSnapshot>? _uploadSub;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    if (_uid == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _redirectToLogin();
      });
    }
  }

  @override
  void dispose() {
    _uploadSub?.cancel();
    super.dispose();
  }

  void _redirectToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  String _uploadErrorMessage(Object e) {
    if (e is FirebaseException) {
      return 'Upload failed (${e.code}): ${e.message ?? e.toString()}';
    }
    return 'Upload failed: $e';
  }

  // ── Fetch records stream ───────────────────────────────────────────────────
  Stream<List<HealthRecordModel>> get _recordsStream {
    if (_uid == null) return Stream.value([]);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('healthRecords')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => HealthRecordModel.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return list;
    });
  }

  // ── Upload file ────────────────────────────────────────────────────────────
  Future<void> _uploadRecord() async {
    // Show type + title dialog first
    String selectedType = 'report';
    final titleCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Health Record'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Record Title *',
                    hintText: 'e.g. Blood Test Results',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Record Type',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'report',     child: Text('Medical Report')),
                    DropdownMenuItem(value: 'lab_result', child: Text('Lab Result')),
                    DropdownMenuItem(value: 'pdf',        child: Text('PDF Document')),
                    DropdownMenuItem(value: 'image',      child: Text('Image / Scan')),
                  ],
                  onChanged: (v) => setDialog(() => selectedType = v ?? 'report'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(100, 40)),
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('Choose File'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    if (_uid == null) return;

    // Pick file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;

    setState(() { _isUploading = true; _uploadProgress = 0; });

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final storagePath = 'healthRecords/$_uid/$fileName';
      final storageRef = FirebaseStorage.instance.ref(storagePath);

      final uploadTask = storageRef.putFile(File(file.path!));

      // Track progress
      _uploadSub?.cancel();
      _uploadSub = uploadTask.snapshotEvents.listen((snap) {
        if (!mounted) return;
        if (snap.totalBytes > 0) {
          setState(() {
            _uploadProgress = snap.bytesTransferred / snap.totalBytes;
          });
        }
      });

      final snapshot = await uploadTask;
      if (snapshot.state != TaskState.success) {
        throw FirebaseException(
          plugin: 'firebase_storage',
          code: 'upload-incomplete',
          message: 'Upload did not complete successfully',
        );
      }

      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Save metadata to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('healthRecords')
          .add({
        'userId': _uid,
        'title': titleCtrl.text.trim(),
        'type': selectedType,
        'fileUrl': downloadUrl,
        'storagePath': storagePath,
        'fileName': file.name,
        'notes': notesCtrl.text.trim(),
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Record uploaded successfully!'),
            backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_uploadErrorMessage(e)),
                backgroundColor: AppColors.error));
      }
    } finally {
      _uploadSub?.cancel();
      _uploadSub = null;
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ── Delete record ──────────────────────────────────────────────────────────
  Future<void> _deleteRecord(HealthRecordModel record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text('Remove "${record.title}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: const Size(80, 40)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (_uid == null) return;

    try {
      // Delete from Storage (ignore missing objects)
      if (record.storagePath.isNotEmpty) {
        try {
          await FirebaseStorage.instance.ref(record.storagePath).delete();
        } on FirebaseException catch (e) {
          if (e.code != 'object-not-found') rethrow;
        }
      } else if (record.fileUrl.isNotEmpty) {
        try {
          await FirebaseStorage.instance
              .refFromURL(record.fileUrl)
              .delete();
        } on FirebaseException catch (e) {
          if (e.code != 'object-not-found') rethrow;
        }
      }
      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('healthRecords')
          .doc(record.id)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Record deleted.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  // ── Open file in browser ───────────────────────────────────────────────────
  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open file.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Health Records'),
        backgroundColor: AppColors.success,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _uploadRecord,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload Record'),
        backgroundColor: AppColors.success,
      ),
      body: Column(
        children: [
          // Upload progress bar
          if (_isUploading) ...[
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.success),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Uploading... ${(_uploadProgress * 100).toInt()}%',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: AppColors.border,
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],

          // Records list
          Expanded(
            child: StreamBuilder<List<HealthRecordModel>>(
              stream: _recordsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading records: ${snapshot.error}'),
                  );
                }

                final records = snapshot.data ?? [];

                if (records.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.folder_open,
                              size: 48, color: AppColors.success),
                        ),
                        const SizedBox(height: 16),
                        const Text('No health records yet',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        const Text(
                          'Upload your medical reports, lab results,\nor scans to keep them organized.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: records.length,
                  itemBuilder: (_, i) => _RecordCard(
                    record: records[i],
                    onOpen: () => _openFile(records[i].fileUrl),
                    onDelete: () => _deleteRecord(records[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final HealthRecordModel record;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _RecordCard({
    required this.record,
    required this.onOpen,
    required this.onDelete,
  });

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: record.iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(record.icon, color: record.iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    Text(record.fileName,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(_formatDate(record.uploadedAt),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textHint)),
                    if (record.notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(record.notes,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.open_in_new,
                        color: AppColors.primary, size: 20),
                    onPressed: onOpen,
                    tooltip: 'Open',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.error, size: 20),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}