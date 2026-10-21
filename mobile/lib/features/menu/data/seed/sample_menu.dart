import 'package:mobile/features/menu/data/models/menu_models.dart';

// TODO: REMOVE WHEN CONNECTED TO BACKEND

const sampleMenu = <MenuItem>[
  MenuItem(
    id: 'paa-inasal',
    name: 'Paa Inasal',
    description: 'Grilled chicken leg quarter, with rice',
    pricesCentavos: {MenuChannel.dineIn: 17900, MenuChannel.grabFood: 20500},
  ),
  MenuItem(
    id: 'pecho-inasal',
    name: 'Pecho Inasal',
    description: 'Grilled chicken breast, with rice',
    pricesCentavos: {MenuChannel.dineIn: 18900, MenuChannel.grabFood: 21500},
  ),
  MenuItem(
    id: 'pork-inasal',
    name: 'Pork Inasal',
    description: 'Grilled pork belly, with rice',
    pricesCentavos: {MenuChannel.dineIn: 19900, MenuChannel.grabFood: 22900},
  ),
  MenuItem(
    id: 'halo-halo',
    name: 'Halo-halo',
    description: 'Shaved ice dessert',
    pricesCentavos: {MenuChannel.dineIn: 10900, MenuChannel.grabFood: 12900},
  ),
  MenuItem(
    id: 'batchoy-special',
    name: 'Batchoy Special',
    description: 'Noodle soup',
    pricesCentavos: {MenuChannel.dineIn: 16500},
    availability: {
      MenuChannel.dineIn: MenuAvailability.stockout,
      MenuChannel.takeaway: MenuAvailability.stockout,
      MenuChannel.grabFood: MenuAvailability.manualOff,
    },
  ),
];
