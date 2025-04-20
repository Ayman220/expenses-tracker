import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Loader extends StatelessWidget {
  const Loader({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current theme mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Set the loader color based on the theme mode
    final loaderColor = isDarkMode ? Colors.white : Colors.blue;
    return Material(
      color: isDarkMode ? Colors.black54 : Colors.white70,
      child: Center(child: SpinKitWaveSpinner(color: loaderColor, size: 100.0)),
    );
  }
}
