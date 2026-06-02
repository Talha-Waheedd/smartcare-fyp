// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/screens/doctor/add_consultation_screen.dart
// PURPOSE: Form for doctor to write consultation notes for a patient.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../models/consultation_model.dart';
import '../../services/doctor_service.dart';

class AddConsultationScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;

  const AddConsultationScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
  });

  @override
  State<AddConsultationScreen> createState() => _AddConsultationScreenState();
}

class _AddConsultationScreenState extends State<AddConsultationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _followUpController = TextEditingController();

  bool _isLoading = false;
  DateTime? _selectedFollowUp;

  @override
  void dispose() {
    _notesController.dispose();
    _diagnosisController.dispose();
    _followUpController.dispose();
    super.dispose();
  }

  Future<void> _pickFollowUpDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedFollowUp = picked;
        _followUpController.text =
            '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final now = DateTime.now();
    final consultation = ConsultationModel(
      id: '',
      patientId: widget.patientId,
      patientName: widget.patientName,
      doctorId: widget.doctorId,
      doctorName: widget.doctorName,
      consultationDate: now,
      status: ConsultationStatus.completed,
      notes: _notesController.text.trim(),
      diagnosis: _diagnosisController.text.trim(),
      followUpDate: _followUpController.text.trim(),
      createdAt: now,
    );

    try {
      await DoctorService().addConsultation(consultation);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Consultation note saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Note for ${widget.patientName}'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Patient info banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    Text('Patient: ${widget.patientName}',
                        style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Diagnosis field
              TextFormField(
                controller: _diagnosisController,
                decoration: const InputDecoration(
                  labelText: 'Diagnosis / Condition',
                  hintText: 'e.g. Hypertension, Flu, Diabetes',
                  prefixIcon: Icon(Icons.medical_information),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Clinical notes
              TextFormField(
                controller: _notesController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Consultation Notes *',
                  hintText:
                      'Write your clinical observations, symptoms discussed, treatment plan...',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Notes are required'
                    : null,
              ),

              const SizedBox(height: 16),

              // Follow-up date picker
              TextFormField(
                controller: _followUpController,
                readOnly: true,
                onTap: _pickFollowUpDate,
                decoration: const InputDecoration(
                  labelText: 'Follow-up Date (optional)',
                  hintText: 'Tap to select a date',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
              ),

              const SizedBox(height: 28),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Consultation Note',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}