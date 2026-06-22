class InventoryTimestamp {
  InventoryTimestamp._();

  static DateTime? lastChangedAt;

  static void markChanged() => lastChangedAt = DateTime.now();
}
