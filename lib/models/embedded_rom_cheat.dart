class EmbeddedRomCheat {
  const EmbeddedRomCheat({
    required this.id,
    required this.sortOrder,
    required this.description,
    required this.code,
    required this.enabled,
  });

  final int id;
  final int sortOrder;
  final String description;
  final String code;
  final bool enabled;

  static EmbeddedRomCheat fromRow(Map<String, Object?> row) {
    return EmbeddedRomCheat(
      id: row['id'] as int,
      sortOrder: row['sort_order'] as int? ?? 0,
      description: row['description']?.toString() ?? '',
      code: row['code']?.toString() ?? '',
      enabled: (row['enabled'] as int? ?? 0) != 0,
    );
  }
}
