// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/screens/patient/ai_suggestion_screen.dart
// PURPOSE: Displays AI-generated wellness suggestions for the patient.
//          Shows a disclaimer that these are wellness tips, not medical advice.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/ai_suggestion_model.dart';
import '../../services/ai_service.dart';
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('AI Wellness Suggestions'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    color: Colors.amber.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⚠️ These are general wellness suggestions only. '
                    'They do not replace professional medical advice. '
                    'Always consult your doctor for medical decisions.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.purple),
                        SizedBox(height: 16),
                        Text('Analyzing your health profile...',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
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
                            return _buildSuggestionCard(
                                _suggestions[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(AiSuggestionModel suggestion) {
    final color = _categoryColor(suggestion.category);
    final priorityColor = _priorityColor(suggestion.priority);
    bool _expanded = false;

    return StatefulBuilder(
      builder: (context, setCardState) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setCardState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Card Header ─────────────────────────────────────
                  Row(
                    children: [
                      // Category icon circle
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
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
                    const SizedBox(height: 8),
                    // AI generated label
                    Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 12, color: Colors.purple.shade300),
                        const SizedBox(width: 4),
                        Text(
                          'AI Generated · Not medical advice',
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
        );
      },
    );
  }
}