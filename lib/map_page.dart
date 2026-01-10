import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatelessWidget {
  MapPage({super.key});

  // Center of Kolkata
  final LatLng kolkataCenter = const LatLng(22.5726, 88.3639);

  // Important locations in Kolkata
  final List<Map<String, dynamic>> kolkataLocations = [
    {
      'name': 'Victoria Memorial',
      'latLng': const LatLng(22.5448, 88.3426),
    },
    {
      'name': 'Howrah Bridge',
      'latLng': const LatLng(22.5851, 88.3468),
    },
    {
      'name': 'Dakshineswar Kali Temple',
      'latLng': const LatLng(22.6552, 88.3575),
    },
    {
      'name': 'Kalighat Temple',
      'latLng': const LatLng(22.5196, 88.3420),
    },
    {
      'name': 'Indian Museum',
      'latLng': const LatLng(22.5626, 88.3510),
    },
    {
      'name': 'Science City',
      'latLng': const LatLng(22.5403, 88.3953),
    },
    {
      'name': 'Eco Park',
      'latLng': const LatLng(22.6215, 88.4519),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        centerTitle: true,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: kolkataCenter,
          initialZoom: 12.5,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.tour_guide',
          ),
          MarkerLayer(
            markers: kolkataLocations.map((location) {
              return Marker(
                point: location['latLng'],
                width: 40,
                height: 40,
                child: Tooltip(
                  message: location['name'],
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 36,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
