import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/managers/state_managers/screen_state_manager.dart';
import 'package:wildrapport/providers/app_state_provider.dart';
import '../mock_generator.mocks.dart';

// Test widget
class TestScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onStateLoaded;
  final Function(Map<String, dynamic>)? onStateSaved;

  const TestScreen({super.key, this.onStateLoaded, this.onStateSaved});

  @override
  TestScreenState createState() => TestScreenState();
}

class TestScreenState extends ScreenStateManager<TestScreen> {
  Map<String, dynamic> state = {
    'counter': 0,
    'text': 'initial',
    'isEnabled': true,
  };

  @override
  String get screenName => 'test_screen';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.onStateLoaded != null) {
        widget.onStateLoaded!(state);
      }
    });
  }

  @override
  Map<String, dynamic> getInitialState() => {
        'counter': 0,
        'text': 'initial',
        'isEnabled': true,
      };

  @override
  Map<String, dynamic> getCurrentState() => state;

  @override
  void updateState(String key, dynamic value) {
    state[key] = value;
    safeSetState(() {});
  }

  @override
  void dispose() {
    if (widget.onStateSaved != null) {
      widget.onStateSaved!(state);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container();
}

class TestWrapper extends StatelessWidget {
  final Widget child;
  final AppStateProvider appStateProvider;

  const TestWrapper({
    super.key,
    required this.child,
    required this.appStateProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ChangeNotifierProvider<AppStateProvider>.value(
        value: appStateProvider,
        child: child,
      ),
    );
  }
}

void main() {
  late MockAppStateProvider mockAppStateProvider;

  setUp(() {
    mockAppStateProvider = MockAppStateProvider();

    // Default behavior for unsaved state
    when(mockAppStateProvider.getScreenState<dynamic>(any, any)).thenReturn(null);
  });

  group('ScreenStateManager', () {
    testWidgets('should load initial state on init', (tester) async {
      bool stateLoaded = false;

      await tester.pumpWidget(
        TestWrapper(
          appStateProvider: mockAppStateProvider,
          child: TestScreen(
            onStateLoaded: (_) => stateLoaded = true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(stateLoaded, true);
      verify(mockAppStateProvider.getScreenState<dynamic>('test_screen', 'counter')).called(1);
      verify(mockAppStateProvider.getScreenState<dynamic>('test_screen', 'text')).called(1);
      verify(mockAppStateProvider.getScreenState<dynamic>('test_screen', 'isEnabled')).called(1);
    });

    testWidgets('should save state on dispose', (tester) async {
      Map<String, dynamic>? savedState;

      await tester.pumpWidget(
        TestWrapper(
          appStateProvider: mockAppStateProvider,
          child: TestScreen(
            onStateSaved: (state) => savedState = Map.from(state),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.pumpWidget(Container());

      expect(savedState, isNotNull);
      expect(savedState!['counter'], 0);
      expect(savedState!['text'], 'initial');
      expect(savedState!['isEnabled'], true);

      verify(mockAppStateProvider.setScreenState('test_screen', 'counter', 0)).called(1);
      verify(mockAppStateProvider.setScreenState('test_screen', 'text', 'initial')).called(1);
      verify(mockAppStateProvider.setScreenState('test_screen', 'isEnabled', true)).called(1);
    });

    testWidgets('should update state with saved values', (tester) async {
      when(mockAppStateProvider.getScreenState<int>('test_screen', 'counter')).thenReturn(5);
      when(mockAppStateProvider.getScreenState<String>('test_screen', 'text')).thenReturn('saved');

      Map<String, dynamic>? loadedState;

      await tester.pumpWidget(
        TestWrapper(
          appStateProvider: mockAppStateProvider,
          child: TestScreen(
            onStateLoaded: (state) => loadedState = Map.from(state),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(loadedState!['counter'], 5);
      expect(loadedState!['text'], 'saved');
      expect(loadedState!['isEnabled'], true);
    });

    testWidgets('should not update state if current value equals saved value', (tester) async {
      when(mockAppStateProvider.getScreenState<int>('test_screen', 'counter')).thenReturn(0);

      Map<String, dynamic>? loadedState;

      await tester.pumpWidget(
        TestWrapper(
          appStateProvider: mockAppStateProvider,
          child: TestScreen(
            onStateLoaded: (state) => loadedState = Map.from(state),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(loadedState!['counter'], 0);
      verifyNever(mockAppStateProvider.setScreenState('test_screen', 'counter', any));
    });
  });
}
