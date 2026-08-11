import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../data/ruta_gen_repository.dart';

class StationsPage extends StatefulWidget {
  const StationsPage({
    super.key,
    required this.repository,
  });

  // Se conserva para no romper la navegación existente.
  // Las estaciones de esta pantalla se guardan localmente.
  final RutaGenRepository repository;

  @override
  State<StationsPage> createState() => _StationsPageState();
}

class _StationsPageState extends State<StationsPage> {
  final TextEditingController _searchController =
      TextEditingController();

  Position? _currentPosition;
  bool _loadingLocation = true;
  String _search = '';

  static const List<_LocalStation> _stations = [
    _LocalStation(
      name: 'Combustibles Canning 1',
      address: 'Canning, Buenos Aires',
      zone: 'Canning',
      latitude: -34.9322363,
      longitude: -58.4854614,
    ),
    _LocalStation(
      name: 'Catania Gen',
      address: 'Canning, Buenos Aires',
      zone: 'Canning',
      latitude: -34.8953817,
      longitude: -58.4344220,
    ),
    _LocalStation(
      name: 'Combustibles Canning 2',
      address: 'Canning, Buenos Aires',
      zone: 'Canning',
      latitude: -34.9614132,
      longitude: -58.4662893,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    if (mounted) {
      setState(() {
        _loadingLocation = true;
      });
    }

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        setState(() {
          _loadingLocation = false;
        });

        _showLocationMessage(
          message:
              'La ubicación está desactivada. Activala para calcular las distancias.',
          actionLabel: 'Activar',
          action: () {
            Geolocator.openLocationSettings();
          },
        );

        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;

        setState(() {
          _loadingLocation = false;
        });

        _showLocationMessage(
          message:
              'No se otorgó permiso para acceder a tu ubicación.',
        );

        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          _loadingLocation = false;
        });

        _showLocationMessage(
          message:
              'El permiso de ubicación está bloqueado. Podés habilitarlo desde la configuración.',
          actionLabel: 'Configurar',
          action: () {
            Geolocator.openAppSettings();
          },
        );

        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _loadingLocation = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingLocation = false;
      });

      _showLocationMessage(
        message:
            'No pudimos obtener tu ubicación en este momento.',
      );
    }
  }

  void _showLocationMessage({
    required String message,
    String? actionLabel,
    VoidCallback? action,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: actionLabel != null && action != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: action,
              )
            : null,
      ),
    );
  }

  Future<void> _openGoogleMaps(
    _LocalStation station,
  ) async {
    final uri = Uri.https(
      'www.google.com',
      '/maps/dir/',
      {
        'api': '1',
        'destination':
            '${station.latitude},${station.longitude}',
        'travelmode': 'driving',
      },
    );

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo abrir Google Maps.',
          ),
        ),
      );
    }
  }

  void _openFullMap() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullStationsMapPage(
          stations: _stations,
          currentPosition: _currentPosition,
          onStationPressed: _openGoogleMaps,
        ),
      ),
    );
  }

  double? _distanceToStation(
    _LocalStation station,
  ) {
    final position = _currentPosition;

    if (position == null) {
      return null;
    }

    return Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          station.latitude,
          station.longitude,
        ) /
        1000;
  }

  String _distanceText(
    _LocalStation station,
  ) {
    if (_loadingLocation) {
      return 'Calculando distancia...';
    }

    final distance = _distanceToStation(station);

    if (distance == null) {
      return 'Activá tu ubicación para calcular la distancia';
    }

    if (distance < 1) {
      return '${(distance * 1000).round()} m de distancia';
    }

    return '${distance.toStringAsFixed(1)} km de distancia';
  }

  List<_LocalStation> get _filteredStations {
    final query = _search.trim().toLowerCase();

    final stations = _stations.where((station) {
      if (query.isEmpty) {
        return true;
      }

      return station.name.toLowerCase().contains(query) ||
          station.address.toLowerCase().contains(query) ||
          station.zone.toLowerCase().contains(query);
    }).toList();

    if (_currentPosition != null) {
      stations.sort((first, second) {
        final firstDistance =
            _distanceToStation(first) ?? double.infinity;

        final secondDistance =
            _distanceToStation(second) ?? double.infinity;

        return firstDistance.compareTo(secondDistance);
      });
    }

    return stations;
  }

  @override
  Widget build(BuildContext context) {
    final stations = _filteredStations;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Estaciones',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar ubicación',
            onPressed:
                _loadingLocation ? null : _loadCurrentLocation,
            icon: _loadingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.my_location_rounded,
                  ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              18,
              6,
              18,
              14,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _search = value;
                });
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.search_rounded,
                ),
                hintText: 'Buscar por nombre o zona',
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        tooltip: 'Limpiar búsqueda',
                        onPressed: () {
                          _searchController.clear();

                          setState(() {
                            _search = '';
                          });
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          Container(
            height: 220,
            margin: const EdgeInsets.symmetric(
              horizontal: 18,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5FF),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: _StationsMap(
                    stations: _stations,
                    currentPosition: _currentPosition,
                    onStationPressed: _openGoogleMaps,
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Material(
                    color: AppColors.blue,
                    borderRadius: BorderRadius.circular(14),
                    elevation: 4,
                    child: InkWell(
                      onTap: _openFullMap,
                      borderRadius:
                          BorderRadius.circular(14),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.fullscreen_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Ver mapa completo',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: stations.isEmpty
                ? const _EmptyStations()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      0,
                      18,
                      30,
                    ),
                    itemCount: stations.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final station = stations[index];

                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () =>
                              _openGoogleMaps(station),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 25,
                                  backgroundColor:
                                      Color(0xFFE9F4FF),
                                  foregroundColor:
                                      AppColors.blue,
                                  child: Icon(
                                    Icons
                                        .local_gas_station_rounded,
                                  ),
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        station.name,
                                        style:
                                            const TextStyle(
                                          fontSize: 15,
                                          fontWeight:
                                              FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        station.address,
                                        style: const TextStyle(
                                          color:
                                              AppColors.muted,
                                          fontWeight:
                                              FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons
                                                .near_me_rounded,
                                            size: 15,
                                            color:
                                                AppColors.blue,
                                          ),
                                          const SizedBox(
                                            width: 4,
                                          ),
                                          Expanded(
                                            child: Text(
                                              _distanceText(
                                                station,
                                              ),
                                              style:
                                                  const TextStyle(
                                                color: AppColors
                                                    .blue,
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight
                                                        .w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppColors.blue,
                                    borderRadius:
                                        BorderRadius.circular(
                                      13,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons
                                        .directions_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StationsMap extends StatelessWidget {
  const _StationsMap({
    required this.stations,
    required this.currentPosition,
    required this.onStationPressed,
  });

  final List<_LocalStation> stations;
  final Position? currentPosition;
  final Future<void> Function(_LocalStation station)
      onStationPressed;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
options: const MapOptions(
  initialCenter: LatLng(
    -34.9285,
    -58.4620,
  ),
  initialZoom: 11.7,
  minZoom: 2,
  maxZoom: 19,
  interactionOptions: InteractionOptions(
    flags: InteractiveFlag.all,
  ),
),
      children: [
        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName:
              'com.grupogen.ruta_gen_app',
        ),
        MarkerLayer(
          markers: [
            ...stations.map(
              (station) => Marker(
                point: LatLng(
                  station.latitude,
                  station.longitude,
                ),
                width: 54,
                height: 54,
                child: GestureDetector(
                  onTap: () {
                    onStationPressed(station);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_gas_station_rounded,
                      color: Colors.white,
                      size: 27,
                    ),
                  ),
                ),
              ),
            ),
            if (currentPosition != null)
              Marker(
                point: LatLng(
                  currentPosition!.latitude,
                  currentPosition!.longitude,
                ),
                width: 30,
                height: 30,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1677FF),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withOpacity(0.25),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
            ),
          ],
        ),
      ],
    );
  }
}

class _FullStationsMapPage extends StatelessWidget {
  const _FullStationsMapPage({
    required this.stations,
    required this.currentPosition,
    required this.onStationPressed,
  });

  final List<_LocalStation> stations;
  final Position? currentPosition;
  final Future<void> Function(_LocalStation station)
      onStationPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mapa de estaciones',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _StationsMap(
              stations: stations,
              currentPosition: currentPosition,
              onStationPressed: onStationPressed,
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.touch_app_rounded,
                      color: AppColors.blue,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Tocá una estación para abrir la ruta en Google Maps.',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStations extends StatelessWidget {
  const _EmptyStations();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 54,
              color: AppColors.muted,
            ),
            SizedBox(height: 12),
            Text(
              'No encontramos estaciones con esa búsqueda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalStation {
  const _LocalStation({
    required this.name,
    required this.address,
    required this.zone,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String address;
  final String zone;
  final double latitude;
  final double longitude;
}