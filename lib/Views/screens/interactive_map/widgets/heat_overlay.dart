// heat_overlay.dart

import 'dart:async';
import 'dart:ui' as ui; // Renamed to 'ui' for clarity

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:covid19_tracker_flutter/Models/MapDataModel.dart';
import 'dart:math' as math;

class HeatOverlay extends StatelessWidget {
  final List<MapDataModel> countries;
  final String selectedMetric;

  const HeatOverlay({
    super.key,
    required this.countries,
    required this.selectedMetric,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OverlayImage>>(
      future: _generateHeatmapOverlays(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return OverlayImageLayer(
            overlayImages: snapshot.data!,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Future<List<OverlayImage>> _generateHeatmapOverlays() async {
    if (countries.isEmpty) return [];

    final overlays = <OverlayImage>[];

    // Calculate global min/max values for normalization
    final values = countries.map((c) => _getValueForMetric(c)).toList();
    final minValue = values.fold<num>(values.first, math.min);
    final maxValue = values.fold<num>(values.first, math.max);

    if (maxValue <= minValue) return [];

    for (final country in countries) {
      final value = _getValueForMetric(country);
      final normalizedValue = (value - minValue) / (maxValue - minValue);

      // Skip countries with very low values to reduce clutter
      if (normalizedValue < 0.1) continue;

      final overlay = await _createHeatmapOverlay(
        country,
        normalizedValue,
      );

      if (overlay != null) {
        overlays.add(overlay);
      }
    }

    return overlays;
  }

  Future<OverlayImage?> _createHeatmapOverlay(MapDataModel country, double intensity) async {
    // Calculate radius based on intensity and zoom-independent scaling
    final baseRadius = 0.5; // Base radius in degrees
    final radius = baseRadius + (intensity * 2.0);

    // Create bounds around the country
    final bounds = LatLngBounds(
      LatLng(
        country.latitude - radius,
        country.longitude - radius,
      ),
      LatLng(
        country.latitude + radius,
        country.longitude + radius,
      ),
    );

    // Create a CustomPaint widget that draws the heatmap circle
    final painter = _HeatmapCirclePainter(
      intensity: intensity,
      radius: radius * 100, // Scale for widget size
    );
    
    // Create an ImageProvider from the CustomPaint painter
    final image = await _buildImageFromPainter(painter, 200, 200);

    // Correctly get byte data from ui.Image and create MemoryImage
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return OverlayImage(
      bounds: bounds,
      imageProvider: MemoryImage(byteData!.buffer.asUint8List()),
      opacity: 0.6,
      gaplessPlayback: true,
    );
  }

  // Helper function to create a ui.Image from a CustomPainter
  Future<ui.Image> _buildImageFromPainter(
      CustomPainter painter, int width, int height) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    painter.paint(canvas, Size(width.toDouble(), height.toDouble()));
    final picture = pictureRecorder.endRecording();
    return await picture.toImage(width, height);
  }

  num _getValueForMetric(MapDataModel country) {
    switch (selectedMetric) {
      case 'deaths':
        return country.totalDeaths;
      case 'recovered':
        return country.recovered;
      case 'active':
        return country.active;
      default: // cases
        return country.totalCases;
    }
  }
}

class _HeatmapCirclePainter extends CustomPainter {
  final double intensity;
  final double radius;

  _HeatmapCirclePainter({
    required this.intensity,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint();

    // Create radial gradient based on intensity
    // Use the RadialGradient from the Material library
    final gradient = RadialGradient(
      center: Alignment.center,
      colors: _getHeatmapColors(intensity),
      stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
    );

    paint.shader = gradient.createShader(
      Rect.fromCircle(center: center, radius: radius.clamp(20.0, 100.0)),
    );

    // Draw the heatmap circle
    canvas.drawCircle(
      center,
      radius.clamp(20.0, 100.0),
      paint,
    );
  }

  List<Color> _getHeatmapColors(double intensity) {
    if (intensity < 0.2) {
      // Very low intensity - green to blue
      return [
        const Color(0xFF10B981).withOpacity(0.8),
        const Color(0xFF10B981).withOpacity(0.4),
        const Color(0xFF3B82F6).withOpacity(0.2),
        const Color(0xFF3B82F6).withOpacity(0.1),
        Colors.transparent,
      ];
    } else if (intensity < 0.4) {
      // Low intensity - blue to yellow
      return [
        const Color(0xFF3B82F6).withOpacity(0.8),
        const Color(0xFF3B82F6).withOpacity(0.6),
        const Color(0xFF3B82F6).withOpacity(0.3),
        const Color(0xFF3B82F6).withOpacity(0.1),
        Colors.transparent,
      ];
    } else if (intensity < 0.6) {
      // Medium intensity - yellow
      return [
        const Color(0xFFF59E0B).withOpacity(0.9),
        const Color(0xFFF59E0B).withOpacity(0.7),
        const Color(0xFFF59E0B).withOpacity(0.4),
        const Color(0xFFF59E0B).withOpacity(0.2),
        Colors.transparent,
      ];
    } else if (intensity < 0.8) {
      // High intensity - orange to red
      return [
        const Color(0xFFEF4444).withOpacity(0.9),
        const Color(0xFFEF4444).withOpacity(0.7),
        const Color(0xFFF59E0B).withOpacity(0.5),
        const Color(0xFFF59E0B).withOpacity(0.2),
        Colors.transparent,
      ];
    } else {
      // Very high intensity - red to dark red
      return [
        const Color(0xFFDC2626).withOpacity(1.0),
        const Color(0xFFEF4444).withOpacity(0.8),
        const Color(0xFFEF4444).withOpacity(0.5),
        const Color(0xFFEF4444).withOpacity(0.2),
        Colors.transparent,
      ];
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is _HeatmapCirclePainter) {
      return oldDelegate.intensity != intensity || oldDelegate.radius != radius;
    }
    return true;
  }
}