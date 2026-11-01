/// User roles matching the backend Prisma UserRole enum.
enum UserRole {
  superadmin('SUPERADMIN'),
  manager('MANAGER'),
  recipeManager('RECIPE_MANAGER'),
  supervisor('SUPERVISOR'),
  kitchenHead('KITCHEN_HEAD'),
  inventoryStaff('INVENTORY_STAFF'),
  kitchenStaff('KITCHEN_STAFF'),
  cashierStaff('CASHIER_STAFF');

  const UserRole(this.apiValue);
  final String apiValue;

  /// Parses a role string from the API (case-insensitive, trimmed).
  static UserRole? fromApiValue(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toUpperCase();
    for (final role in UserRole.values) {
      if (role.apiValue == normalized) return role;
    }
    return null;
  }

  /// Whether this role is an authorized kitchen workspace role.
  bool get isKitchen =>
      this == UserRole.kitchenHead || this == UserRole.kitchenStaff;
}
