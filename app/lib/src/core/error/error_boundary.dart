import 'package:flutter/material.dart';

class GlobalErrorBoundary extends StatelessWidget {
  final Widget child;

  const GlobalErrorBoundary({super.key, required this.child});

  static void init() {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'Oops! Something went wrong.',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'We encountered an unexpected error. Our team has been notified.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () {
                    // In a real app, maybe trigger a restart
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
