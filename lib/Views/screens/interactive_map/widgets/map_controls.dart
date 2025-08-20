// lib/Views/screens/interactive_map/widgets/map_controls.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map; // Prefix the flutter_map import
import 'package:covid19_tracker_flutter/Controllers/map_controller.dart';
import 'package:covid19_tracker_flutter/Controllers/geolocation_controller.dart';
import 'package:covid19_tracker_flutter/Utils/colors.dart';
import 'package:latlong2/latlong.dart';

class MapControls extends StatelessWidget {
  final MapController mapController;
  final GeolocationController geoController;
  final flutter_map.MapController flutterMapController; // Use the prefixed name

  const MapControls({
    super.key,
    required this.mapController,
    required this.geoController,
    required this.flutterMapController,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Zoom Controls
        _buildControlGroup(
          isDark,
          children: [
            _buildControlButton(
              icon: Icons.add_rounded,
              onPressed: () {
                HapticFeedback.lightImpact();
                mapController.zoomIn();
                _animateToCurrentView();
              },
              isDark: isDark,
            ),
            Container(
              width: 48,
              height: 1,
              color: Colors.grey.withOpacity(0.3),
            ),
            _buildControlButton(
              icon: Icons.remove_rounded,
              onPressed: () {
                HapticFeedback.lightImpact();
                mapController.zoomOut();
                _animateToCurrentView();
              },
              isDark: isDark,
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Location Controls
        _buildControlGroup(
          isDark,
          children: [
            Obx(() => _buildControlButton(
              icon: geoController.isTracking.value 
                  ? Icons.gps_fixed_rounded 
                  : Icons.my_location_rounded,
              onPressed: () async {
                HapticFeedback.mediumImpact();
                await _handleLocationAction();
              },
              isDark: isDark,
              isActive: geoController.isTracking.value,
              isLoading: geoController.loading.value,
            )),
            Container(
              width: 48,
              height: 1,
              color: Colors.grey.withOpacity(0.3),
            ),
            _buildControlButton(
              icon: Icons.center_focus_strong_rounded,
              onPressed: () {
                HapticFeedback.lightImpact();
                mapController.fitToAllCountries();
                _animateToCurrentView();
              },
              isDark: isDark,
              tooltip: 'Fit to all countries',
            ),
          ],
        ),

        const SizedBox(height: 12),

        // View Controls
        _buildControlGroup(
          isDark,
          children: [
            Obx(() => _buildControlButton(
              icon: mapController.showHeatmap.value 
                  ? Icons.heat_pump_rounded 
                  : Icons.heat_pump_outlined,
              onPressed: () {
                HapticFeedback.lightImpact();
                mapController.toggleHeatmap();
              },
              isDark: isDark,
              isActive: mapController.showHeatmap.value,
              tooltip: 'Toggle heatmap',
            )),
            Container(
              width: 48,
              height: 1,
              color: Colors.grey.withOpacity(0.3),
            ),
            Obx(() => _buildControlButton(
              icon: mapController.showLegend.value 
                  ? Icons.legend_toggle_rounded 
                  : Icons.legend_toggle_rounded,
              onPressed: () {
                HapticFeedback.lightImpact();
                mapController.toggleLegend();
              },
              isDark: isDark,
              isActive: mapController.showLegend.value,
              tooltip: 'Toggle legend',
            )),
          ],
        ),

        const SizedBox(height: 12),

        // Additional Controls
        _buildControlGroup(
          isDark,
          children: [
            _buildControlButton(
              icon: Icons.refresh_rounded,
              onPressed: () {
                HapticFeedback.mediumImpact();
                mapController.refreshMapData();
              },
              isDark: isDark,
              tooltip: 'Refresh data',
            ),
            Container(
              width: 48,
              height: 1,
              color: Colors.grey.withOpacity(0.3),
            ),
            _buildControlButton(
              icon: Icons.layers_rounded,
              onPressed: () {
                HapticFeedback.lightImpact();
                _showMapTypeSelector(context, isDark);
              },
              isDark: isDark,
              tooltip: 'Map layers',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlGroup(bool isDark, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
    bool isActive = false,
    bool isLoading = false,
    String? tooltip,
  }) {
    Widget buttonChild = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isActive 
            ? AppColors.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: isLoading 
          ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            )
          : Icon(
              icon,
              color: isActive 
                  ? AppColors.primary 
                  : (isDark ? Colors.white : Colors.black),
              size: 20,
            ),
    );

    Widget button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: buttonChild,
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        preferBelow: false,
        child: button,
      );
    }

    return button;
  }

  Future<void> _handleLocationAction() async {
    if (geoController.isTracking.value) {
      // Stop tracking
      geoController.stopLocationTracking();
    } else {
      // Start location process
      try {
        final location = await geoController.getCurrentLocation();
        if (location != null) {
          // Center map on user location
          mapController.setMapCenter(
            LatLng(location.latitude, location.longitude),
            zoom: 8.0,
          );
          _animateToCurrentView();
          
          // Show success message
          Get.snackbar(
            'Location Found',
            location.displayName,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.accent,
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            borderRadius: 8,
            duration: const Duration(seconds: 3),
          );
        }
      } catch (e) {
        // Handle location errors
        String errorMessage = 'Failed to get location';
        
        if (e.toString().contains('permission')) {
          errorMessage = 'Location permission required';
          
          // Show permission dialog
          _showLocationPermissionDialog();
        } else if (e.toString().contains('service')) {
          errorMessage = 'Please enable location services';
        }

        Get.snackbar(
          'Location Error',
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.danger,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  void _animateToCurrentView() {
    flutterMapController.move(
      mapController.currentCenter.value,
      mapController.currentZoom.value,
    );
  }

  void _showMapTypeSelector(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              'Map Type',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            
            const SizedBox(height: 16),
            
            ...mapController.mapTypes.map((type) => Obx(() => ListTile(
              leading: Icon(
                _getMapTypeIcon(type),
                color: mapController.currentMapType.value == type
                    ? AppColors.primary
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              title: Text(
                type.capitalize!,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: mapController.currentMapType.value == type
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              trailing: mapController.currentMapType.value == type
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                HapticFeedback.selectionClick();
                mapController.changeMapType(type);
                Navigator.pop(context);
              },
            ))).toList(),
            
            const SizedBox(height: 8),
            
            // Additional options
            const Divider(),
            
            ListTile(
              leading: Icon(
                mapController.showClusters.value 
                    ? Icons.scatter_plot_rounded 
                    : Icons.scatter_plot_outlined,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              title: Text(
                'Clustering',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              trailing: Obx(() => Switch(
                value: mapController.showClusters.value,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  mapController.toggleClustering();
                },
                activeColor: AppColors.primary,
              )),
            ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _showLocationPermissionDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Get.isDarkMode ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.location_on_rounded,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Location Permission',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Get.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        content: Text(
          'This app needs location permission to show your position on the map and provide location-based COVID data.',
          style: TextStyle(
            fontSize: 14,
            color: Get.isDarkMode ? Colors.grey[300] : Colors.grey[700],
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final granted = await geoController.requestLocationPermission();
              if (granted) {
                _handleLocationAction();
              } else {
                // Show settings dialog
                _showLocationSettingsDialog();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Allow',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationSettingsDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Get.isDarkMode ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.settings_rounded,
              color: AppColors.warning,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Enable Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Get.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        content: Text(
          'Location permission was denied. Please enable it in Settings to use location features.',
          style: TextStyle(
            fontSize: 14,
            color: Get.isDarkMode ? Colors.grey[300] : Colors.grey[700],
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await geoController.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Open Settings',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMapTypeIcon(String type) {
    switch (type) {
      case 'satellite':
        return Icons.satellite_alt_rounded;
      case 'terrain':
        return Icons.terrain_rounded;
      default:
        return Icons.map_rounded;
    }
  }
}