enum ReviewStatus {
  pending,
  approved,
  rejected;

  static ReviewStatus? fromString(String? s) => switch (s) {
    'pending' => pending,
    'approved' => approved,
    'rejected' => rejected,
    _ => null,
  };
}
