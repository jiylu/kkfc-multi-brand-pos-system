import 'package:mobile/features/availability/data/models/availability_model.dart';

// SAMPLE DATA copied from the Figma frames. Replace with API data later.
const sampleAvailability = <AvailabilityItem>[
  AvailabilityItem(
    name: 'Paa Inasal',
    channel: PosChannel.dineIn,
    available: true,
  ),
  AvailabilityItem(
    name: 'Paa Inasal',
    channel: PosChannel.grabFood,
    available: true,
  ),
  AvailabilityItem(
    name: 'Batchoy Special',
    channel: PosChannel.grabFood,
    available: false,
  ),
];
