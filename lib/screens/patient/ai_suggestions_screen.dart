// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/screens/patient/ai_suggestion_screen.dart
// PURPOSE: Displays AI-generated wellness suggestions for the patient.
//          Shows a disclaimer that these are wellness tips, not medical advice.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import '../../models/ai_suggestion_model.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class AiSuggestionScreen extends StatefulWidget {
  const AiSuggestionScreen({super.key});

  @override
  State<AiSuggestionScreen> createState() => _AiSuggestionScreenState();
}

class _AiSuggestionScreenState extends State<AiSuggestionScreen> {
  final AiService _aiService = AiService();
  List<AiSuggestionModel> _suggestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        }
        return;
      }
      final result = await _aiService.generateSuggestions(user.uid);
      setState(() {
        _suggestions = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Category → color mapping for cards
  Color _categoryColor(SuggestionCategory cat) {
    switch (cat) {
      case SuggestionCategory.diet:       return Colors.green;
      case SuggestionCategory.exercise:   return Colors.orange;
      case SuggestionCategory.sleep:      return Colors.indigo;
      case SuggestionCategory.hydration:  return Colors.blue;
      case SuggestionCategory.stress:     return Colors.teal;
      case SuggestionCategory.medication: return Colors.red.shade400;
      case SuggestionCategory.general:    return Colors.purple;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':   return Colors.red.shade400;
      case 'medium': return Colors.orange;
      default:       return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Personalized Wellness Tips'),
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppGradients.purpleHeader),
        ),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadSuggestions,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Medical Disclaimer Banner ───────────────────────────────────
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.warning, Color(0xFFFFB84D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppShadows.button(AppColors.warning),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Wellness tips only — generated from your profile, medications, '
                    'and health records using a rule-based expert system. '
                    'Not medical advice. Always consult your doctor.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? _buildShimmerList()
                : _suggestions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.psychology_outlined,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text('No suggestions available.',
                                style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _loadSuggestions,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSuggestions,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                          itemCount: _suggestions.length,
                          itemBuilder: (context, index) {
                            return FadeInUp(
                              delay: Duration(milliseconds: 50 * index),
                              duration: const Duration(milliseconds: 350),
                              from: 30,
                              child: _buildSuggestionCard(
                                  _suggestions[index]),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ── Shimmer loading placeholders ───────────────────────────────────────────
  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      itemCount: 5,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.border,
        highlightColor: AppColors.background,
        child: Container(
          height: 76,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        width: double.infinity,
                        height: 12,
                        color: Colors.white),
                    const SizedBox(height: 8),
                    Container(width: 120, height: 10, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(AiSuggestionModel suggestion) {
    final color = _categoryColor(suggestion.category);
    final priorityColor = _priorityColor(suggestion.priority);
    bool _expanded = false;

    return StatefulBuilder(
      builder: (context, setCardState) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: AppShadows.card,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left accent bar (category color)
                  Container(width: 5, color: color),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      onTap: () =>
                          setCardState(() => _expanded = !_expanded),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Card Header ───────────────────────────
                            Row(
                              children: [
                                // Category emoji in gradient circle
                                Container(
                                  width: 42,
                                  height: 42,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        color.withOpacity(0.85),
                                        color.withOpacity(0.5),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    suggestion.category.emoji,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                                const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              suggestion.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                // Category badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    suggestion.category.label,
                                    style: TextStyle(
                                        fontSize: 10, color: color),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Priority badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        priorityColor.withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    suggestion.priorityLabel,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: priorityColor),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Expand/collapse arrow
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey,
                      ),
                    ],
                  ),

                  // ── Expandable Description ──────────────────────────
                  if (_expanded) ...[
                    const Divider(height: 16),
                    Text(
                      suggestion.description,
                      style: const TextStyle(
                          fontSize: 13, height: 1.5),
                    ),
                    if (suggestion.triggerReason.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lightbulb_outline,
                                size: 14, color: Colors.purple.shade400),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Why: ${suggestion.triggerReason}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.purple.shade700,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.rule,
                            size: 12, color: Colors.purple.shade300),
                        const SizedBox(width: 4),
                        Text(
                          'Personalized · Rule-based · Not medical advice',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.purple.shade300),
                        ),
                      ],
                    ),
                  ],
                ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
      },
    );
  }
}