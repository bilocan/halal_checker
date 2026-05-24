/// Remaps the selected tab when admin access is granted or revoked.
int remapStartScreenTabIndex({
  required int selectedIndex,
  required bool wasAdmin,
  required bool isAdmin,
}) {
  if (wasAdmin == isAdmin) return selectedIndex;

  var newIndex = selectedIndex;
  if (!wasAdmin && isAdmin) {
    // About moves from index 3 → 4 when the admin tab is inserted.
    if (selectedIndex == 3) newIndex = 4;
  } else {
    // Admin tab removed; About moves from index 4 → 3.
    if (selectedIndex == 3) {
      newIndex = 0;
    } else if (selectedIndex == 4) {
      newIndex = 3;
    }
  }

  final tabCount = isAdmin ? 5 : 4;
  if (newIndex >= tabCount) newIndex = 0;
  return newIndex;
}
