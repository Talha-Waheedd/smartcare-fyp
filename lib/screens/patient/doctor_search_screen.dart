// FILE: lib/screens/patient/doctor_search_screen.dart
// PURPOSE: Patient searches doctors by name, specialty, or location and books
//          an appointment. Reads active doctors via UserService.

import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import 'book_appointment_screen.dart';

class DoctorSearchScreen extends StatefulWidget {
  const DoctorSearchScreen({super.key});

  @override
  State<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends State<DoctorSearchScreen> {
  final _userService = UserService();
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _specialtyFilter = 'all';

  static const _accent = AppColors.doctor;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<UserModel> _filter(List<UserModel> doctors) {
    return doctors.where((d) {
      final spec = d.specialization.isEmpty
          ? 'General Physician'
          : d.specialization;
      if (_specialtyFilter != 'all' && spec != _specialtyFilter) return false;
      if (_query.isEmpty) return true;
      return d.name.toLowerCase().contains(_query) ||
          spec.toLowerCase().contains(_query) ||
          d.clinicLocation.toLowerCase().contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        title: const Text('Find Doctors'),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _userService.getActiveDoctors(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _accent));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: AppColors.error)));
          }

          final allDoctors = snapshot.data ?? [];
          final specialties = <String>{
            for (final d in allDoctors)
              d.specialization.isEmpty ? 'General Physician' : d.specialization
          }.toList()
            ..sort();

          final doctors = _filter(allDoctors);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search by name, specialty, or location...',
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.textSecondary),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: AppColors.textSecondary),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            })
                        : null,
                  ),
                ),
              ),
              if (specialties.isNotEmpty)
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: ['all', ...specialties].map((s) {
                      final selected = _specialtyFilter == s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(s == 'all' ? 'All' : s),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _specialtyFilter = s),
                          selectedColor: _accent.withOpacity(0.15),
                          checkmarkColor: _accent,
                          labelStyle: TextStyle(
                            color: selected ? _accent : AppColors.textSecondary,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              Expanded(
                child: doctors.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 56, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text('No doctors found',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: doctors.length,
                        itemBuilder: (_, i) => _DoctorSearchCard(
                          doctor: doctors[i],
                          onBook: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  BookAppointmentScreen(doctor: doctors[i]),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DoctorSearchCard extends StatelessWidget {
  final UserModel doctor;
  final VoidCallback onBook;
  const _DoctorSearchCard({required this.doctor, required this.onBook});

  static const _accent = AppColors.doctor;

  @override
  Widget build(BuildContext context) {
    final name = doctor.name.isEmpty ? 'Doctor' : doctor.name;
    final spec =
        doctor.specialization.isEmpty ? 'General Physician' : doctor.specialization;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'D';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: _accent.withOpacity(0.12),
                  child: Text(initial,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _accent)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dr. $name',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(spec,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _accent)),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 16, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            doctor.reviewCount > 0
                                ? '${doctor.avgRating.toStringAsFixed(1)} (${doctor.reviewCount})'
                                : 'No ratings yet',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      if (doctor.clinicLocation.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(doctor.clinicLocation,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (doctor.bio.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(doctor.bio,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onBook,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                ),
                icon: const Icon(Icons.calendar_month_outlined, size: 18),
                label: const Text('Book Appointment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
