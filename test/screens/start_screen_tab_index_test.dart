import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/screens/start/start_tab_index.dart';

void main() {
  group('remapStartScreenTabIndex', () {
    test('unchanged when admin status is stable', () {
      expect(
        remapStartScreenTabIndex(
          selectedIndex: 2,
          wasAdmin: false,
          isAdmin: false,
        ),
        2,
      );
      expect(
        remapStartScreenTabIndex(
          selectedIndex: 3,
          wasAdmin: true,
          isAdmin: true,
        ),
        3,
      );
    });

    test('promoting to admin keeps home/keywords/directory tabs', () {
      expect(
        remapStartScreenTabIndex(
          selectedIndex: 0,
          wasAdmin: false,
          isAdmin: true,
        ),
        0,
      );
      expect(
        remapStartScreenTabIndex(
          selectedIndex: 2,
          wasAdmin: false,
          isAdmin: true,
        ),
        2,
      );
    });

    test('promoting to admin moves About from index 3 to 4', () {
      expect(
        remapStartScreenTabIndex(
          selectedIndex: 3,
          wasAdmin: false,
          isAdmin: true,
        ),
        4,
      );
    });

    test('demoting from admin sends Admin tab to Home', () {
      expect(
        remapStartScreenTabIndex(
          selectedIndex: 3,
          wasAdmin: true,
          isAdmin: false,
        ),
        0,
      );
    });

    test('demoting from admin moves About from index 4 to 3', () {
      expect(
        remapStartScreenTabIndex(
          selectedIndex: 4,
          wasAdmin: true,
          isAdmin: false,
        ),
        3,
      );
    });

    test('clamps out-of-range indices', () {
      expect(
        remapStartScreenTabIndex(
          selectedIndex: 99,
          wasAdmin: true,
          isAdmin: false,
        ),
        0,
      );
    });
  });
}
