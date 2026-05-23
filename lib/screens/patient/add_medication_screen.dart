// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/screens/patient/add_medication_screen.dart
// PURPOSE: Form screen to add a new medication or edit an existing one.
//          After saving, schedules local notification reminders.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/medication_model.dart';
import '../../services/medication_service.dart';
import '../../services/notification_service.dart';

class AddMedicationScreen extends StatefulWidget {
  // If existingMed is passed, we're in EDIT mode
  final MedicationModel? existingMed;

  const AddMedicationScreen({super.key, this.existingMed});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final dosageController = TextEditingController();
  final instructionsController = TextEditingController();

  // Frequency options
  final List<String> frequencies = [
    'Once a day',
    'Twice a day',
    'Three times a day',
    'Every 8 hours',
    'Every 12 hours',
    'As needed',
  ];
  String selectedFrequency = 'Once a day';

  // Time slots — user adds multiple times
  List<TimeOfDay> selectedTimes = [const TimeOfDay(hour: 8, minute: 0)];

  bool isLoading = false;
  bool get isEditMode => widget.existingMed != null;

  final _medicationService = MedicationService();
  final _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    // If editing, pre-fill the form
    if (isEditMode) {
      final med = widget.existingMed!;
      nameController.text = med.name;
      dosageController.text = med.dosage;
      instructionsController.text = med.instructions;
      selectedFrequency = med.frequency;
      // Parse stored "HH:mm" strings back to TimeOfDay
      selectedTimes = med.times.map((t) {
        final parts = t.split(':');
        return TimeOfDay(
            hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }).toList();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    instructionsController.dispose();
    super.dispose();
  }

  // ── Time picker ──────────────────────────────────────────────────────────
  Future<void> pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTimes[index],
    );
    if (picked != null) {
      setState(() => selectedTimes[index] = picked);
    }
  }

  void addTimeSlot() {
    setState(() => selectedTimes.add(const TimeOfDay(hour: 12, minute: 0)));
  }

  void removeTimeSlot(int index) {
    if (selectedTimes.length > 1) {
      setState(() => selectedTimes.removeAt(index));
    }
  }

  // ── Format TimeOfDay → "HH:mm" ──────────────────────────────────────────
  String formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<void> saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final timeStrings = selectedTimes.map(formatTime).toList();

    final med = MedicationModel(
      id: isEditMode ? widget.existingMed!.id : '',
      userId: uid,
      name: nameController.text.trim(),
      dosage: dosageController.text.trim(),
      frequency: selectedFrequency,
      times: timeStrings,
      instructions: instructionsController.text.trim(),
      isActive: true,
      createdAt: isEditMode ? widget.existingMed!.createdAt : DateTime.now(),
    );

    bool success;

    if (isEditMode) {
      success = await _medicationService.updateMedication(med);
    } else {
      final newId = await _medicationService.addMedication(med);
      success = newId != null;

      // Schedule notification reminders for each time slot
      if (success && newId != null) {
        final baseId = newId.hashCode.abs() % 100000;
        for (int i = 0; i < timeStrings.length; i++) {
          await _notificationService.scheduleMedicationReminder(
            notificationId: baseId + i,
            medicationName: med.name,
            dosage: med.dosage,
            timeString: timeStrings[i],
          );
        }
      }
    }

    setState(() => isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditMode
              ? '${med.name} updated successfully'
              : '${med.name} added! Reminders scheduled.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Medication' : 'Add Medication'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Medication Name ──────────────────────────────────────────
              TextFormField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Medication Name *',
                  hintText: 'e.g. Paracetamol',
                  prefixIcon: Icon(Icons.medication),
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Name is required' : null,
              ),

              const SizedBox(height: 16),

              // ── Dosage ───────────────────────────────────────────────────
              TextFormField(
                controller: dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage *',
                  hintText: 'e.g. 500mg, 1 tablet',
                  prefixIcon: Icon(Icons.scale),
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Dosage is required' : null,
              ),

              const SizedBox(height: 16),

              // ── Frequency Dropdown ───────────────────────────────────────
              DropdownButtonFormField<String>(
                value: selectedFrequency,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  prefixIcon: Icon(Icons.repeat),
                  border: OutlineInputBorder(),
                ),
                items: frequencies
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (val) =>
                    setState(() => selectedFrequency = val ?? frequencies[0]),
              ),

              const SizedBox(height: 20),

              // ── Time Slots ───────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reminder Times',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  TextButton.icon(
                    onPressed: addTimeSlot,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Time'),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Time slot list
              ...List.generate(selectedTimes.length, (index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.access_time, color: Colors.blue),
                    title: Text(
                      selectedTimes[index].format(context),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text('Reminder ${index + 1}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit time button
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => pickTime(index),
                        ),
                        // Remove button (only if more than 1 slot)
                        if (selectedTimes.length > 1)
                          IconButton(
                            icon: const Icon(Icons.close,
                                size: 20, color: Colors.red),
                            onPressed: () => removeTimeSlot(index),
                          ),
                      ],
                    ),
                    onTap: () => pickTime(index),
                  ),
                );
              }),

              const SizedBox(height: 16),

              // ── Instructions ─────────────────────────────────────────────
              TextFormField(
                controller: instructionsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Instructions (optional)',
                  hintText: 'e.g. Take after meal, avoid dairy',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 28),

              // ── Save Button ───────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : saveMedication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEditMode ? 'Update Medication' : 'Save & Set Reminder',
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
}