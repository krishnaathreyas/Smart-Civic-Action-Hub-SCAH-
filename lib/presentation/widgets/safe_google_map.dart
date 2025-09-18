// presentation/widgets/safe_google_map.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SafeGoogleMap extends StatefulWidget {
  final CameraPosition initialCameraPosition;
  final Set<Marker> markers;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool zoomControlsEnabled;
  final bool mapToolbarEnabled;
  final void Function(GoogleMapController)? onMapCreated;

  const SafeGoogleMap({
    Key? key,
    required this.initialCameraPosition,
    this.markers = const <Marker>{},
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = false,
    this.zoomControlsEnabled = true,
    this.mapToolbarEnabled = true,
    this.onMapCreated,
  }) : super(key: key);

  @override
  State<SafeGoogleMap> createState() => _SafeGoogleMapState();
}

class _SafeGoogleMapState extends State<SafeGoogleMap> {
  GoogleMapController? _controller;
  String? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorState();
    }

    return Container(
      child: GoogleMap(
        key: Key('google_map_${DateTime.now().millisecondsSinceEpoch}'),
        initialCameraPosition: widget.initialCameraPosition,
        markers: widget.markers,
        myLocationEnabled: widget.myLocationEnabled,
        myLocationButtonEnabled: widget.myLocationButtonEnabled,
        zoomControlsEnabled: widget.zoomControlsEnabled,
        mapToolbarEnabled: widget.mapToolbarEnabled,
        onMapCreated: (GoogleMapController controller) {
          try {
            _controller = controller;
            widget.onMapCreated?.call(controller);

            // Small delay to ensure DOM is fully ready
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                setState(() {}); // Trigger rebuild to update markers
              }
            });
          } catch (e) {
            print('Error creating Google Map: $e');
            setState(() {
              _error = 'Failed to initialize map: ${e.toString()}';
            });
          }
        },
      ),
    );
  }

  Widget _buildErrorState() {
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'There was an issue loading the map. Please check your internet connection and try again.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _error = null;
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
