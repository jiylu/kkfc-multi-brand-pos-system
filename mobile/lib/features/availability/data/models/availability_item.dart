enum PosChannel {
  dineIn('Dine-in'),
  takeaway('Takeaway'),
  grabFood('GrabFood'),
  foodpanda('foodpanda');

  const PosChannel(this.label);
  final String label;
}

class AvailabilityItem {
  const AvailabilityItem({
    required this.name,
    required this.channel,
    required this.available,
  });

  final String name;
  final PosChannel channel;
  final bool available;

  AvailabilityItem copyWith({bool? available}) => AvailabilityItem(
        name: name,
        channel: channel,
        available: available ?? this.available,
      );
}

// SAMPLE DATA copied from the Figma frames. Replace with API data later.
const sampleAvailability = <AvailabilityItem>[
  AvailabilityItem(
      name: 'Paa Inasal', channel: PosChannel.dineIn, available: true),
  AvailabilityItem(
      name: 'Paa Inasal', channel: PosChannel.grabFood, available: true),
  AvailabilityItem(
      name: 'Batchoy Special', channel: PosChannel.grabFood, available: false),
];