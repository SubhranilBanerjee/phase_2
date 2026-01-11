import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();

  final LatLng kolkataCenter = const LatLng(22.5726, 88.3639);

  String selectedCategory = 'All';

  final List<Map<String, dynamic>> locations = [
    {
      'name': 'Victoria Memorial',
      'category': 'Monument',
      'latLng': const LatLng(22.5448, 88.3426),
      'description': 'Iconic marble monument',
    },
    {
      'name': 'Howrah Bridge',
      'category': 'Monument',
      'latLng': const LatLng(22.5851, 88.3468),
      'description': 'Famous cantilever bridge',
    },
    {
      'name': 'Dakshineswar Kali Temple',
      'category': 'Temple',
      'latLng': const LatLng(22.6552, 88.3575),
      'description': 'Sacred riverside temple',
    },
    {
      'name': 'Eco Park',
      'category': 'Park',
      'latLng': const LatLng(22.6215, 88.4519),
      'description': 'Largest urban park in India',
    },
  ];

  List<Map<String, dynamic>> get filteredLocations {
    if (selectedCategory == 'All') return locations;
    return locations.where((l) => l['category'] == selectedCategory).toList();
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Temple':
        return Icons.temple_hindu;
      case 'Park':
        return Icons.park;
      case 'Monument':
        return Icons.account_balance;
      default:
        return Icons.location_on;
    }
  }

  void _moveTo(LatLng point) {
    _mapController.move(point, 15);
  }

  Future<void> _goToUserLocation() async {
    final pos = await Geolocator.getCurrentPosition();
    _moveTo(LatLng(pos.latitude, pos.longitude));
  }

  void _showDetails(Map<String, dynamic> location) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              location['name'],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(location['description']),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _moveTo(location['latLng']),
              icon: const Icon(Icons.map),
              label: const Text('View on Map'),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Kolkata'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToUserLocation,
        child: const Icon(Icons.my_location),
      ),
      body: Column(
        children: [
          // 🔍 Search
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search places...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                final match = locations.firstWhere(
                  (l) => l['name'].toLowerCase().contains(value.toLowerCase()),
                  orElse: () => {},
                );
                if (match.isNotEmpty) {
                  _moveTo(match['latLng']);
                }
              },
            ),
          ),

          // 🏷️ Filters
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['All', 'Temple', 'Park', 'Monument']
                  .map(
                    (c) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: FilterChip(
                        label: Text(c),
                        selected: selectedCategory == c,
                        onSelected: (_) {
                          setState(() => selectedCategory = c);
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // 🗺️ Map
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: kolkataCenter,
                initialZoom: 12.5,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: 45,
                    size: const Size(40, 40),
                    markers: filteredLocations.map((location) {
                      return Marker(
                        point: location['latLng'],
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => _showDetails(location),
                          child: Icon(
                            _iconForCategory(location['category']),
                            size: 36,
                            color: Colors.red,
                          ),
                        ),
                      );
                    }).toList(),
                    builder: (context, markers) {
                      return Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue,
                        ),
                        child: Center(
                          child: Text(
                            markers.length.toString(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
