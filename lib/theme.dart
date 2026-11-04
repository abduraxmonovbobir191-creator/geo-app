import 'package:flutter/material.dart';

const nexBlue = Color(0xFF2F6BFF);

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: nexBlue, brightness: brightness);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(backgroundColor: scheme.surface, scrolledUnderElevation: 0, centerTitle: false),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
  );
}

/// The Nex Map mark: a map pin with an "N".
class NexLogo extends StatelessWidget {
  const NexLogo({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.location_on, size: size, color: nexBlue),
          Padding(
            padding: EdgeInsets.only(bottom: size * 0.18),
            child: Text(
              'N',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: size * 0.32),
            ),
          ),
        ],
      ),
    );
  }
}
