import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../config.dart';

/// The base map, from the Nex Map tile server. Uses the dark style in dark mode and
/// double-resolution tiles on high-density screens.
Widget baseTileLayer(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return TileLayer(
    urlTemplate: AppConfig.tileUrl.replaceAll('{style}', dark ? 'dark' : 'light'),
    retinaMode: RetinaMode.isHighDensity(context),
    userAgentPackageName: AppConfig.packageName,
  );
}

/// Credit required by the map data licenses (ODbL).
const mapAttribution = RichAttributionWidget(
  attributions: [TextSourceAttribution('OpenStreetMap contributors'), TextSourceAttribution('Protomaps')],
);
