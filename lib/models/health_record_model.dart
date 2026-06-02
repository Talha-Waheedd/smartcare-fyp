// FILE: lib/models/health_record_model.dart
import 'package:flutter/material.dart';

class HealthRecordModel {
  final String id;
  final String userId;
  final String title;
  final String type;       // 'pdf', 'image', 'lab_result', 'report'
  final String fileUrl;    // Firebase Storage download URL
  final String storagePath; // Firebase Storage path for delete
  final String fileName;
  final String notes;
  final DateTime uploadedAt;

  const HealthRecordModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.type,
    required this.fileUrl,
    this.storagePath = '',
    required this.fileName,
    required this.notes,
    required this.uploadedAt,
  });

  factory HealthRecordModel.fromMap(Map<String, dynamic> map, String id) {
    return HealthRecordModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      type: map['type'] ?? 'report',
      fileUrl: map['fileUrl'] ?? '',
      storagePath: map['storagePath'] ?? '',
      fileName: map['fileName'] ?? '',
      notes: map['notes'] ?? '',
      uploadedAt: (map['uploadedAt'])?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'title': title,
    'type': type,
    'fileUrl': fileUrl,
    'storagePath': storagePath,
    'fileName': fileName,
    'notes': notes,
    'uploadedAt': uploadedAt,
  };

  IconData get icon {
    switch (type) {
      case 'pdf':        return Icons.picture_as_pdf;
      case 'image':      return Icons.image_outlined;
      case 'lab_result': return Icons.science_outlined;
      default:           return Icons.description_outlined;
    }
  }

  Color get iconColor {
    switch (type) {
      case 'pdf':        return const Color(0xFFDC2626);
      case 'image':      return const Color(0xFF2563EB);
      case 'lab_result': return const Color(0xFF7C3AED);
      default:           return const Color(0xFF16A34A);
    }
  }
}