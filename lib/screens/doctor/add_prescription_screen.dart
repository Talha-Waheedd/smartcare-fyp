// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/screens/doctor/add_prescription_screen.dart
// PURPOSE: Form for doctor to create a prescription with multiple medicines.
// ⚠️  MEDICAL CONSTRAINT: Only doctors can access this screen.
//     AI never creates prescriptions — this is enforced by routing (only
//     doctor role reaches this screen) and Firestore rules.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../models/prescription_model.dart';
import '../../services/doctor_service.dart';

class AddPrescriptionScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String consultationId;

  const AddPrescriptionScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    this.consultationId = '',
  });

  @override
  State<AddPrescriptionScreen> createState() => _AddPrescriptionScreenState();
}

class _AddPrescriptionScreenState extends State<AddPrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _validUntilController = TextEditingController();

  bool _isLoading = false;

  // List of medicine rows — doctor can add multiple
  final List<_MedicineEntry> _medicines = [_MedicineEntry()];

  final List<String> _frequencies = [
    'Once a day',
    'Twice a day',
    'Three times a day',
    'Every 8 hours',
    'Every 12 hours',
    'As needed (SOS)',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    _validUntilController.dispose();
    for (final m in _medicines) {
      m.dispose();
    }
    super.dispose();
  }

  Future<void> _pickValidUntil() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      _validUntilController.text =
          '${picked.day}/${picked.month}/${picked.year}';
    }
  }

  void _addMedicineRow() {
    setState(() => _medicines.add(_MedicineEntry()));
  }

  void _removeMedicineRow(int index) {
    if (_medicines.length > 1) {
      _medicines[index].dispose();
      setState(() => _medicines.removeAt(index));
    }
  }

  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate at least one medicine has a name
    final hasValidMedicine = _medicines.any(
        (m) => m.nameController.text.trim().isNotEmpty);
    if (!hasValidMedicine) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one medicine')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Build medicines list from form entries
    final medicines = _medicines
        .where((m) => m.nameController.text.trim().isNotEmpty)
        .map((m) => PrescribedMedicine(
              name: m.nameController.text.trim(),
              dosage: m.dosageController.text.trim(),
              frequency: m.selectedFrequency,
              duration: m.durationController.text.trim(),
              instructions: m.instructionsController.text.trim(),
            ))
        .toList();

    final prescription = PrescriptionModel(
      id: '',
      patientId: widget.patientId,
      patientName: widget.patientName,
      doctorId: widget.doctorId,
      doctorName: widget.doctorName,
      medicines: medicines,
      notes: _notesController.text.trim(),
      validUntil: _validUntilController.text.trim(),
      consultationId: widget.consultationId,
      createdAt: DateTime.now(),
    );

    try {
      await DoctorService().createPrescription(prescription);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prescription created successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save prescription: $e'),
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
        title: Text('Prescribe for ${widget.patientName}'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Doctor creates prescription badge ──────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_user,
                        color: Colors.green.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Prescription by Dr. ${widget.doctorName} for ${widget.patientName}',
                        style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w500,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Medicines section ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Medicines',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: _addMedicineRow,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Medicine'),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Medicine entry cards
              ...List.generate(_medicines.length, (index) {
                return _buildMedicineCard(index);
              }),

              const SizedBox(height: 16),

              // ── Valid Until date ───────────────────────────────────────
              TextFormField(
                controller: _validUntilController,
                readOnly: true,
                onTap: _pickValidUntil,
                decoration: const InputDecoration(
                  labelText: 'Valid Until (optional)',
                  prefixIcon: Icon(Icons.event_available),
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
              ),

              const SizedBox(height: 16),

              // ── General notes ──────────────────────────────────────────
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'General Notes (optional)',
                  hintText: 'Any additional instructions...',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 28),

              // ── Save button ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _savePrescription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.receipt_long),
                  label: Text(
                    _isLoading
                        ? 'Saving...'
                        : 'Create Prescription',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineCard(int index) {
    final entry = _medicines[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header
            Row(
              children: [
                Text('Medicine ${index + 1}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                if (_medicines.length > 1)
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.red, size: 18),
                    onPressed: () => _removeMedicineRow(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Medicine name
            TextFormField(
              controller: entry.nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Medicine Name *',
                hintText: 'e.g. Amoxicillin',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (val) => index == 0 && (val == null || val.isEmpty)
                  ? 'Required'
                  : null,
            ),
            const SizedBox(height: 10),

            // Dosage + Duration row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: entry.dosageController,
                    decoration: const InputDecoration(
                      labelText: 'Dosage',
                      hintText: '500mg',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: entry.durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration',
                      hintText: '7 days',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Frequency dropdown
            DropdownButtonFormField<String>(
              value: entry.selectedFrequency,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _frequencies
                  .map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (val) =>
                  setState(() => entry.selectedFrequency = val ?? _frequencies[0]),
            ),
            const SizedBox(height: 10),

            // Instructions
            TextFormField(
              controller: entry.instructionsController,
              decoration: const InputDecoration(
                labelText: 'Instructions',
                hintText: 'e.g. After meals, avoid alcohol',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class to hold controllers for each medicine row
class _MedicineEntry {
  final nameController = TextEditingController();
  final dosageController = TextEditingController();
  final durationController = TextEditingController();
  final instructionsController = TextEditingController();
  String selectedFrequency = 'Once a day';

  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    durationController.dispose();
    instructionsController.dispose();
  }
}