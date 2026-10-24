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

enum PosDestination { menu, orders, audit }
