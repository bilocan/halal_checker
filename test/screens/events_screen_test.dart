import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/screens/events_screen.dart';
import 'package:halal_checker/services/events_service.dart';

import '../helpers/test_app.dart';

void main() {
  tearDown(EventsService.resetTestOverrides);

  testWidgets('shows upcoming and past sections, hides drafts', (tester) async {
    final now = DateTime.now();
    EventsService.fakeFetchAll = () async => [
      AppEvent(
        id: 'u',
        title: 'Upcoming seminar',
        startsAt: now.add(const Duration(days: 3)),
        description: 'Online via Zoom',
        linkUrl: 'https://example.org',
      ),
      AppEvent(
        id: 'p',
        title: 'Old talk',
        startsAt: now.subtract(const Duration(days: 30)),
      ),
      AppEvent(
        id: 'd',
        title: 'Draft event',
        startsAt: now.add(const Duration(days: 5)),
        published: false,
      ),
    ];
    await tester.pumpWidget(wrapWithTestApp(const EventsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Past events'), findsOneWidget);
    expect(find.text('Upcoming seminar'), findsOneWidget);
    expect(find.text('Online via Zoom'), findsOneWidget);
    expect(find.text('Old talk'), findsOneWidget);
    expect(find.text('Draft event'), findsNothing);
    // Link button only for events with a link.
    expect(find.text('Details'), findsOneWidget);
  });

  testWidgets('empty state', (tester) async {
    EventsService.fakeFetchAll = () async => [];
    await tester.pumpWidget(wrapWithTestApp(const EventsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('No events yet'), findsOneWidget);
  });

  testWidgets('error state with retry', (tester) async {
    EventsService.fakeFetchAll = () async => null;
    await tester.pumpWidget(wrapWithTestApp(const EventsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Could not load events'), findsOneWidget);

    EventsService.fakeFetchAll = () async => [];
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('No events yet'), findsOneWidget);
  });
}
