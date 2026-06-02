// FILE: lib/screens/admin/feedback_management_screen.dart
// PURPOSE: Admin views all patient feedback/reviews, filterable by doctor.

import 'package:flutter/material.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../../theme/app_theme.dart';

class FeedbackManagementScreen extends StatefulWidget {
  const FeedbackManagementScreen({super.key});

  @override
  State<FeedbackManagementScreen> createState() =>
      _FeedbackManagementScreenState();
}

class _FeedbackManagementScreenState extends State<FeedbackManagementScreen> {
  final _reviewService = ReviewService();
  String _doctorFilter = 'all';

  static const _c1 = AppColors.admin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _c1,
        foregroundColor: Colors.white,
        title: const Text('Feedback Management'),
      ),
      body: StreamBuilder<List<ReviewModel>>(
        stream: _reviewService.getAllReviews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _c1));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: AppColors.error)));
          }

          final allReviews = snapshot.data ?? [];
          final doctors = <String, String>{
            for (final r in allReviews) r.doctorId: r.doctorName
          };

          final reviews = _doctorFilter == 'all'
              ? allReviews
              : allReviews.where((r) => r.doctorId == _doctorFilter).toList();

          final avg = reviews.isEmpty
              ? 0.0
              : reviews.map((r) => r.rating).reduce((a, b) => a + b) /
                  reviews.length;

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                color: _c1.withOpacity(0.06),
                child: Row(
                  children: [
                    _summaryBox('${reviews.length}', 'Reviews'),
                    const SizedBox(width: 16),
                    _summaryBox(
                        reviews.isEmpty ? '—' : avg.toStringAsFixed(1),
                        'Avg Rating'),
                  ],
                ),
              ),
              if (doctors.isNotEmpty)
                SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    children: [
                      _chip('all', 'All Doctors'),
                      ...doctors.entries
                          .map((e) => _chip(e.key, 'Dr. ${e.value}')),
                    ],
                  ),
                ),
              Expanded(
                child: reviews.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.reviews_outlined,
                                size: 56, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text('No feedback yet',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: reviews.length,
                        itemBuilder: (_, i) => _ReviewCard(review: reviews[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String id, String label) {
    final selected = _doctorFilter == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _doctorFilter = id),
        selectedColor: _c1.withOpacity(0.15),
        checkmarkColor: _c1,
        labelStyle: TextStyle(
          color: selected ? _c1 : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _summaryBox(String value, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _c1)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dr. ${review.doctorName}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textPrimary)),
                      Text('by ${review.patientName}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      i < review.rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 18,
                      color: AppColors.warning,
                    );
                  }),
                ),
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(review.comment,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
            ],
            const SizedBox(height: 8),
            Text(_fmt(review.createdAt),
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }
}
