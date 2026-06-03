# Personalized Health Recommendation System

## Overview

SmartCare generates **personalized wellness suggestions** using a **rule-based expert system** on the client. The engine aggregates patient data from Firestore, evaluates conditional rules, ranks results by priority and relevance, and returns up to 8 tips.

This is **not** generative clinical AI — it does not diagnose, prescribe, or replace a doctor.

## Architecture

```
AiSuggestionScreen
    → AiService.generateSuggestions(uid)
        → HealthContextBuilder.build(uid)  [parallel Firestore reads]
        → RecommendationRules.evaluateAll(context)
        → SuggestionRanker.rankAndCap(candidates)
```

### Data sources

| Source | Collection | Fields used |
|--------|------------|-------------|
| Profile | `users/{uid}` | name, DOB, gender, blood group, allergies, `healthProfile` |
| Medications | `users/{uid}/medications` | name, instructions, times, frequency |
| Prescriptions | `prescriptions` | medicines[], notes |
| Consultations | `consultations` | diagnosis, notes |
| Appointments | `appointments` | reason |
| Adherence | `users/{uid}/medicationLogs` | 7-day log vs expected doses |

## Demo personas (for viva)

Create three Firebase test patients with different profiles:

### Persona A — Young healthy

- Age: 22, gender: Female, no chronic conditions
- No medications, profile 80%+ complete
- **Expected:** general hydration/sleep tips, few clinical rules

### Persona B — Elderly polypharmacy

- Age: 72, 4 active medications, meal-related instructions
- **Expected:** senior wellness, med consistency, polypharmacy, meal timing

### Persona C — Diabetic with allergies

- Chronic conditions: Diabetes
- Allergies: Penicillin
- Doctor consultation diagnosis containing "Type 2 diabetes"
- **Expected:** diabetes diet tip, allergy tip, no generic duplicate hydration

## Rule examples

| Rule ID | Trigger | Priority |
|---------|---------|----------|
| `profile_complete` | completeness < 40% | high |
| `condition_diabetes` | condition tag `diabetes` | high |
| `allergy_awareness` | allergies field set | high |
| `adherence_low` | < 70% doses logged in 7 days | high |
| `multi_med` | 3+ medications | high |

## Limitations

- Free-text diagnosis uses keyword matching (not NLP)
- No drug–drug interaction database
- Health record PDFs are not parsed
- Prescriptions and patient-entered meds are not auto-synced

## Files

- `lib/models/patient_health_context.dart`
- `lib/services/health_context_builder.dart`
- `lib/services/recommendation/recommendation_rules.dart`
- `lib/services/recommendation/suggestion_ranker.dart`
- `lib/services/ai_service.dart`
