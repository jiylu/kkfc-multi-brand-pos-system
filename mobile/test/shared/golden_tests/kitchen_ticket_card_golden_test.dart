import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/core/models/brand_models.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_card.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart'; // verify path

import '../../support/golden_harness.dart';

const _component = 'kitchen_ticket_card';
const _cardMaxWidth = 320.0;

const _aurelias = AssignedBrand(
  id: 'brand-ai',
  code: 'AI',
  name: "Aurelia's Inasal",
);

const _kingKungs = AssignedBrand(
  id: 'brand-kk',
  code: 'KK',
  name: 'King Kungs Kafé Bonifacio Global City',
);

const _kitchenStatuses = [
  KkfcStatus.queued,
  KkfcStatus.acknowledged,
  KkfcStatus.preparing,
  KkfcStatus.checking,
  KkfcStatus.reworking,
  KkfcStatus.ready,
];

class _AgeCase {
  const _AgeCase(this.state, this.age, this.elapsed);

  final String state;
  final KitchenTicketAge age;
  final Duration elapsed;
}

const _ageCases = [
  _AgeCase('on_time', KitchenTicketAge.onTime, Duration(seconds: 45)),
  _AgeCase(
    'due_soon',
    KitchenTicketAge.dueSoon,
    Duration(minutes: 6, seconds: 12),
  ),
  _AgeCase('late', KitchenTicketAge.late, Duration(minutes: 9, seconds: 40)),
];

const _defaultItems = [
  KitchenTicketItem(quantity: 2, name: 'Paa Inasal', modifiers: ['EXTRA rice']),
  KitchenTicketItem(
    quantity: 1,
    name: 'Pecho Inasal',
    modifiers: ['NO onions'],
  ),
];

KitchenTicketData _ticket({
  required KitchenTicketAge age,
  required Duration elapsed,
  required KkfcStatus status,
  AssignedBrand brand = _aurelias,
  List<KitchenTicketItem> items = _defaultItems,
}) {
  return KitchenTicketData(
    ticketNumber: 'T-014',
    elapsed: elapsed,
    age: age,
    status: status,
    channel: 'GrabFood',
    reference: '#GF-1001',
    brand: brand,
    items: items,
  );
}

Widget _sheet(List<Widget> cards) {
  return SizedBox(
    width: double.infinity,
    child: Wrap(
      spacing: KkfcSpace.s24,
      runSpacing: KkfcSpace.s24,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        for (final card in cards)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _cardMaxWidth),
            child: card,
          ),
      ],
    ),
  );
}

void main() {
  for (final viewport in goldenViewports) {
    for (final textScale in goldenTextScales) {
      // One sheet per age state, all six kitchen statuses on each.
      for (final c in _ageCases) {
        goldenTest(
          '${c.state} statuses @ ${viewport.name}, text $textScale',
          fileName: goldenFileName(_component, c.state, viewport, textScale),
          textScaleFactor: textScale,
          constraints: goldenSheetConstraints(viewport),
          pumpBeforeTest: pumpOnce,
          builder: () => withDisabledAnimations(
            _sheet([
              for (final status in _kitchenStatuses)
                KitchenTicketCard(
                  ticket: _ticket(
                    age: c.age,
                    elapsed: c.elapsed,
                    status: status,
                  ),
                  onAction: () {},
                ),
            ]),
          ),
        );
      }

      // Loading, read-only, and long-content variants.
      goldenTest(
        'variants @ ${viewport.name}, text $textScale',
        fileName: goldenFileName(_component, 'variants', viewport, textScale),
        textScaleFactor: textScale,
        constraints: goldenSheetConstraints(viewport),
        pumpBeforeTest: pumpOnce,
        builder: () => withDisabledAnimations(
          _sheet([
            // Action button in its loading state.
            KitchenTicketCard(
              ticket: _ticket(
                age: KitchenTicketAge.dueSoon,
                elapsed: const Duration(minutes: 6, seconds: 12),
                status: KkfcStatus.preparing,
              ),
              onAction: () {},
              isActionLoading: true,
            ),
            // No action button (read-only board).
            KitchenTicketCard(
              ticket: _ticket(
                age: KitchenTicketAge.onTime,
                elapsed: const Duration(seconds: 45),
                status: KkfcStatus.queued,
              ),
            ),
            // Long brand name, many items and modifiers.
            KitchenTicketCard(
              ticket: _ticket(
                age: KitchenTicketAge.late,
                elapsed: const Duration(minutes: 12, seconds: 3),
                status: KkfcStatus.reworking,
                brand: _kingKungs,
                items: const [
                  KitchenTicketItem(
                    quantity: 12,
                    name: 'Extra Large Chicken Inasal Family Platter',
                    modifiers: ['EXTRA rice', 'NO onions', 'SAUCE on the side'],
                  ),
                  KitchenTicketItem(quantity: 1, name: 'Pecho Inasal'),
                  KitchenTicketItem(
                    quantity: 3,
                    name: 'Halo-halo',
                    modifiers: ['LESS sugar'],
                  ),
                ],
              ),
              onAction: () {},
            ),
          ]),
        ),
      );
    }
  }
}
