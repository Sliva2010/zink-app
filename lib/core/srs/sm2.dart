import '../../models/flash_card.dart';

/// Алгоритм интервального повторения SuperMemo SM-2.
///
/// quality:
///  - 0 — полный провал
///  - 1 — серьёзная ошибка
///  - 2 — почти не вспомнил
///  - 3 — вспомнил с трудом
///  - 4 — уверенно вспомнил
///  - 5 — идеально
class Sm2 {
  Sm2._();

  static FlashCard apply(FlashCard card, int quality) {
    assert(quality >= 0 && quality <= 5, 'quality must be 0..5');

    if (quality < 3) {
      // Сброс счётчика
      return card.copyWith(
        repetitions: 0,
        intervalDays: 1,
        easeFactor: _clampEf(card.easeFactor - 0.2),
        dueDate: DateTime.now().add(const Duration(days: 1)),
        lastReviewedAt: DateTime.now(),
      );
    }

    final newReps = card.repetitions + 1;
    final int newInterval;
    if (newReps == 1) {
      newInterval = 1;
    } else if (newReps == 2) {
      newInterval = 6;
    } else {
      newInterval = (card.intervalDays * card.easeFactor).round().clamp(1, 365);
    }

    final newEf = _clampEf(
      card.easeFactor +
          (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)),
    );

    return card.copyWith(
      repetitions: newReps,
      intervalDays: newInterval,
      easeFactor: newEf,
      dueDate: DateTime.now().add(Duration(days: newInterval)),
      lastReviewedAt: DateTime.now(),
    );
  }

  static double _clampEf(double ef) {
    if (ef < 1.3) return 1.3;
    if (ef > 3.0) return 3.0;
    return ef;
  }
}
