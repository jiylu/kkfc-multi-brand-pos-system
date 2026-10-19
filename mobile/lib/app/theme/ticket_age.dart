import 'semantic_colors.dart';
import 'tokens.dart';

enum TicketAgeLevel { normal, caution, overdue }

TicketAgeLevel ticketAgeLevel(Duration age) {
  if (age >= const Duration(minutes: KkfcKitchen.ageLateMin)) {
    return TicketAgeLevel.overdue;
  }
  if (age >= const Duration(minutes: KkfcKitchen.ageCautionMin)) {
    return TicketAgeLevel.caution;
  }
  return TicketAgeLevel.normal;
}

KkfcTone ageTone(KkfcSemanticColors colors, TicketAgeLevel level) =>
    switch (level) {
      TicketAgeLevel.normal => colors.ageNormal,
      TicketAgeLevel.caution => colors.ageCaution,
      TicketAgeLevel.overdue => colors.ageLate,
    };
