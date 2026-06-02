// FILE: lib/screens/patient/add_review_screen.dart
// PURPOSE: Patient rates a doctor (1–5 stars + comment) after a consultation.

import 'package:flutter/material.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../../theme/app_theme.dart';

class AddReviewScreen extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String patientId;
  final String patientName;
  final String consultationId;

  const AddReviewScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.patientId,
    required this.patientName,
    this.consultationId = '',
  });

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _reviewService = ReviewService();
  final _commentCtrl = TextEditingController();
  int _rating = 0;
  bool _saving = false;

  static const _accent = AppColors.doctor;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.consultationId.isNotEmpty) {
        final already = await _reviewService.hasReviewedConsultation(
            widget.patientId, widget.consultationId);
        if (already) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('You have already reviewed this consultation.'),
            backgroundColor: AppColors.warning,
          ));
          setState(() => _saving = false);
          return;
        }
      }

      await _reviewService.addReview(ReviewModel(
        id: '',
        doctorId: widget.doctorId,
        doctorName: widget.doctorName,
        patientId: widget.patientId,
        patientName: widget.patientName,
        rating: _rating,
        comment: _commentCtrl.text.trim(),
        consultationId: widget.consultationId,
        createdAt: DateTime.now(),
      ));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Thank you for your feedback!'),
        backgroundColor: AppColors.success,
      ));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to submit review: $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        title: const Text('Rate Doctor'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: _accent.withOpacity(0.12),
              child: Text(
                widget.doctorName.isNotEmpty
                    ? widget.doctorName[0].toUpperCase()
                    : 'D',
                style: const TextStyle(
                    fontSize: 32, fontWeight: FontWeight.bold, color: _accent),
              ),
            ),
            const SizedBox(height: 12),
            Text('Dr. ${widget.doctorName}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 24),
            const Text('How was your consultation?',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled = i < _rating;
                return IconButton(
                  iconSize: 40,
                  onPressed: () => setState(() => _rating = i + 1),
                  icon: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: filled ? AppColors.warning : AppColors.textHint,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Comment (optional)',
                hintText: 'Share your experience...',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.comment_outlined),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_outlined),
                label: Text(_saving ? 'Submitting...' : 'Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
