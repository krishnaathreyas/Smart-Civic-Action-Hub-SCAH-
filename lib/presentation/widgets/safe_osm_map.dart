// presentation/widgets/safe_osm_map.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

class SafeOSMMap extends StatefulWidget {
  final ll.LatLng center;
  final double zoom;
  final List<Marker> markers;
  final void Function(MapController)? onMapReady;

  const SafeOSMMap({
    super.key,
    required this.center,
    this.zoom = 14,
    this.markers = const [],
    this.onMapReady,
  });

  @override
  State<SafeOSMMap> createState() => _SafeOSMMapState();
}

class _SafeOSMMapState extends State<SafeOSMMap> {
  final MapController _mapController = MapController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) return _buildError();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.center,
        initialZoom: widget.zoom,
      ),
      children: [
        // OpenStreetMap tile layer (no API key required)
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.scah',
          tileProvider: NetworkTileProvider(),
          errorImage: const AssetImage(
            'assets/images/placeholder_map_tile.png',
          ),
        ),
        MarkerLayer(markers: widget.markers),
        // Attribution overlay (replace nonRotatedChildren with a RichAttributionWidget)
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              '© OpenStreetMap contributors',
              prependCopyright: false,
              textStyle: TextStyle(fontSize: 10),
            ),
          ],
          alignment: AttributionAlignment.bottomRight,
          showFlutterMapAttribution: false,
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Map Unavailable',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'There was an issue loading the map. Please check your connection and try again.',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() => _error = null),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
