import 'package:flutter/material.dart';
import 'dart:async';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> {
  late List<ValueNotifier<int>> _flashNotifiers;
  Timer? _sequenceTimer;
  int _currentDot = 0;

  @override
  void initState() {
    super.initState();
    // Initialize a flash notifier for each dot
    _flashNotifiers = List.generate(3, (_) => ValueNotifier<int>(0));
    _startSequentialFlashing();
  }

  @override
  void dispose() {
    // Dispose all notifiers and the timer
    for (var notifier in _flashNotifiers) {
      notifier.dispose();
    }
    _sequenceTimer?.cancel();
    super.dispose();
  }

  void _startSequentialFlashing() {
    // Repeat the sequence of flashing from first to last dot
    _sequenceTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      // Turn off the previous dot
      if (_currentDot > 0) {
        _flashNotifiers[_currentDot - 1].value = 0;
      } else {
        _flashNotifiers[_flashNotifiers.length - 1].value = 0;
      }

      // Turn on the current dot
      _flashNotifiers[_currentDot].value = 1;

      // Move to the next dot in the sequence
      _currentDot = (_currentDot + 1) % _flashNotifiers.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(
          _flashNotifiers.length,
          (index) => FlashingCircle(flashNotifier: _flashNotifiers[index]),
        ),
      ),
    );
  }
}

// FlashingCircle Stateless Widget
class FlashingCircle extends StatelessWidget {
  const FlashingCircle({super.key, required this.flashNotifier});

  final ValueNotifier<int> flashNotifier;

  @override
  Widget build(BuildContext context) {
    final flashingCircleDarkColor = Colors.grey.shade500;
    final flashingCircleBrightColor = Colors.black;

    return ValueListenableBuilder<int>(
      valueListenable: flashNotifier,
      builder: (context, value, child) {
        final circleColorPercent = value == 1 ? 1.0 : 0.0;

        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(
              flashingCircleDarkColor,
              flashingCircleBrightColor,
              circleColorPercent,
            ),
          ),
        );
      },
    );
  }
}
