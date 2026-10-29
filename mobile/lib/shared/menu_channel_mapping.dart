import 'package:mobile/features/availability/data/models/availability_model.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';

MenuChannel menuChannelForPos(PosChannel channel) => switch (channel) {
  PosChannel.dineIn => MenuChannel.dineIn,
  PosChannel.takeaway => MenuChannel.takeaway,
  PosChannel.grabFood => MenuChannel.grabFood,
  PosChannel.foodpanda => MenuChannel.foodpanda,
};

PosChannel posChannelForMenu(MenuChannel channel) => switch (channel) {
  MenuChannel.dineIn => PosChannel.dineIn,
  MenuChannel.takeaway => PosChannel.takeaway,
  MenuChannel.grabFood => PosChannel.grabFood,
  MenuChannel.foodpanda => PosChannel.foodpanda,
};
