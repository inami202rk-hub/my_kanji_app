import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _CounterApp extends StatefulWidget {
  const _CounterApp();

  @override
  State<_CounterApp> createState() => _CounterAppState();
}

class _CounterAppState extends State<_CounterApp> {
  int _counter = 0;

  void _increment() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: _increment,
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
        body: Center(child: Text('$_counter')),
      ),
    );
  }
}

void main() {
  testWidgets('local counter increments', (tester) async {
    await tester.pumpWidget(const _CounterApp());

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
