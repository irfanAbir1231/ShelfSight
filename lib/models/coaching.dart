import 'package:flutter/foundation.dart';

class CoachingModule {
  const CoachingModule({
    required this.id,
    required this.title,
    required this.seconds,
    required this.summary,
    this.topPerformer = false,
  });
  final String id;
  final String title;
  final int seconds;
  final String summary;
  final bool topPerformer;

  String get durationLabel => seconds >= 60
      ? '${(seconds / 60).round()} min'
      : '$seconds sec';
}

const coachingModules = [
  CoachingModule(
    id: 'm1',
    title: 'Improving Soap Shelf Visibility',
    seconds: 180,
    summary: 'Win a better position for Square soap with a low-risk offer.',
    topPerformer: true,
  ),
  CoachingModule(
    id: 'm2',
    title: 'Starting a shopkeeper conversation',
    seconds: 150,
    summary: 'Open warmly and ask about what sells well.',
  ),
  CoachingModule(
    id: 'm3',
    title: 'Handling limited shelf-space objections',
    seconds: 250,
    summary: 'Offer a swap plan instead of asking for more space.',
  ),
  CoachingModule(
    id: 'm4',
    title: 'Explaining product movement',
    seconds: 200,
    summary: 'Use simple sell-through examples the shopkeeper can check.',
  ),
  CoachingModule(
    id: 'm5',
    title: 'Asking for an additional order',
    seconds: 165,
    summary: 'Close with a small, easy next order.',
  ),
];

/// 0..1 listening progress per module id. Demo starting state.
final ValueNotifier<Map<String, double>> coachingProgress = ValueNotifier({
  'm1': .35,
  'm2': 1.0,
});

void setCoachingProgress(String id, double value) {
  coachingProgress.value = {...coachingProgress.value, id: value};
}

CoachingModule moduleById(String id) =>
    coachingModules.firstWhere((m) => m.id == id);

class TranscriptLine {
  const TranscriptLine({
    required this.speaker,
    required this.text,
    required this.stage,
    required this.startFraction,
  });
  final String speaker;
  final String text;

  /// Opening / Product value / Low-risk proposal / Closing question.
  final String stage;
  final double startFraction;
}

const soapVisibilityTranscript = [
  TranscriptLine(
    speaker: 'Sales Officer',
    text: 'আসসালামু আলাইকুম ভাই, আজ আপনার soap shelf-এর অবস্থা দেখতে এসেছি।',
    stage: 'Opening',
    startFraction: 0,
  ),
  TranscriptLine(
    speaker: 'Shopkeeper',
    text: 'Square-এর soap রাখলে আমার কী সুবিধা?',
    stage: 'Opening',
    startFraction: .18,
  ),
  TranscriptLine(
    speaker: 'Sales Officer',
    text:
        'Meril ও Sepnil-এর নিয়মিত customer demand আছে। আপনার shelf-এ visible '
        'placement রাখলে repeat purchase এবং product movement বাড়তে পারে।',
    stage: 'Product value',
    startFraction: .3,
  ),
  TranscriptLine(
    speaker: 'Sales Officer',
    text: 'প্রথমে limited quantity দিয়ে শুরু করতে পারেন।',
    stage: 'Low-risk proposal',
    startFraction: .62,
  ),
  TranscriptLine(
    speaker: 'Sales Officer',
    text: 'আপনি কি এই সপ্তাহে ছোট একটি অর্ডার দিয়ে শুরু করতে চান?',
    stage: 'Closing question',
    startFraction: .82,
  ),
];
