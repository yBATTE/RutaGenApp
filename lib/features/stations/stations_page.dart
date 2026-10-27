import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' show LatLng;
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
  final TextEditingController _searchController = TextEditingController();

  final MapController _mapController = MapController();
  final GlobalKey _mapKey = GlobalKey();
  final Map<_LocalStation, GlobalKey> _rowKeys = {};
  _LocalStation? _selectedStation;
  bool _mapReady = false;
  bool _centerOnLocation = false;
  Position? _currentPosition;
  bool _loadingLocation = true;
  String _search = '';

  static const List<_LocalStation> _stations = [
    _LocalStation(
      name: 'Combustibles Canning',
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
      name: 'Vision Canning',
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
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation({bool centerOnUser = false}) async {
    if (_loadingLocation && centerOnUser) return;
    _centerOnLocation = centerOnUser;
    if (mounted) {
      setState(() {
        _loadingLocation = true;
        _currentPosition = null;
      });
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

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
          message: 'No se otorgó permiso para acceder a tu ubicación.',
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
      if (_centerOnLocation && _mapReady) {
        _mapController.move(LatLng(position.latitude, position.longitude), 13);
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingLocation = false;
      });

      _showLocationMessage(
        message: 'No pudimos obtener tu ubicación en este momento.',
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
        'destination': '${station.latitude},${station.longitude}',
        'travelmode': 'driving',
      },
    );

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        _showLocationMessage(message: 'No se pudo abrir Google Maps.');
      }
    } catch (_) {
      if (!mounted) return;
      _showLocationMessage(message: 'No se pudo abrir Google Maps. Intentá nuevamente.');
    }
  }

  Future<void> _openFullMap() async {
    _LocalStation? lastSelection;
    final selected = await Navigator.of(context).push<_LocalStation>(
      MaterialPageRoute<_LocalStation>(
        builder: (_) => _FullStationsMapPage(
          stations: _filteredStations,
          currentPosition: _currentPosition,
          selectedStation: _selectedStation,
          onNavigate: _openGoogleMaps,
          onSelectionChanged: (station) => lastSelection = station,
        ),
      ),
    );
    final result = selected ?? lastSelection;
    if (!mounted || result == null) return;
    _selectStation(result, fromMap: true);
  }

  void _selectStation(_LocalStation station, {bool fromMap = false}) {
    FocusScope.of(context).unfocus();
    setState(() => _selectedStation = station);
    if (_mapReady) {
      _mapController.move(LatLng(station.latitude, station.longitude), 14);
    }
    final target = fromMap ? _rowKeys[station]?.currentContext : _mapKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(target,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero : const Duration(milliseconds: 280),
        alignment: fromMap ? 0.6 : 0,
      );
    }
  }

  _LocalStation? get _nearestStation {
    if (_currentPosition == null) return null;
    return _stations.reduce((a, b) =>
        _distanceToStation(a)! <= _distanceToStation(b)! ? a : b);
  }

  void _updateSearch(String value) {
    setState(() {
      _search = value;
      if (!_filteredStations.contains(_selectedStation)) _selectedStation = null;
    });
    if (_mapReady && _filteredStations.isNotEmpty) {
      _fitStations(_mapController, _filteredStations);
    }
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
      return 'Distancia no disponible';
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
        final firstDistance = _distanceToStation(first) ?? double.infinity;

        final secondDistance = _distanceToStation(second) ?? double.infinity;

        return firstDistance.compareTo(secondDistance);
      });
    }

    return stations;
  }

  @override
  Widget build(BuildContext context) {
    final stations = _filteredStations;
    final nearest = _nearestStation;
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFA),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverList.list(children: [
                Row(children: [
                  const Text('RUTA GEN', style: TextStyle(
                    color: AppColors.muted, fontSize: 11,
                    fontWeight: FontWeight.w700, letterSpacing: 3)),
                  const SizedBox(width: 12),
                  Container(width: 24, height: 3, color: const Color(0xFFFFD43B)),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  const Expanded(child: Text('Estaciones', style: TextStyle(
                    fontSize: 30, height: 1.2, letterSpacing: -0.8,
                    fontWeight: FontWeight.w800, color: AppColors.ink))),
                  IconButton.outlined(
                    tooltip: 'Centrar en mi ubicación',
                    onPressed: _loadingLocation ? null
                        : () => _loadCurrentLocation(centerOnUser: true),
                    icon: _loadingLocation
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location_rounded, size: 21),
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: AppColors.border)),
                  ),
                ]),
                const SizedBox(height: 18),
                TextField(
                  controller: _searchController,
                  onChanged: _updateSearch,
                  decoration: InputDecoration(
                    hintText: 'Buscar estación',
                    hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, size: 22),
                    suffixIcon: _search.isEmpty ? null : IconButton(
                      tooltip: 'Limpiar búsqueda',
                      onPressed: () { _searchController.clear(); _updateSearch(''); },
                      icon: const Icon(Icons.close_rounded, size: 20)),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  key: _mapKey,
                  height: 250,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(children: [
                      Positioned.fill(child: _StationsMap(
                        controller: _mapController,
                        stations: stations,
                        currentPosition: _currentPosition,
                        selectedStation: _selectedStation,
                        onReady: () {
                          _mapReady = true;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            _fitStations(_mapController, _filteredStations);
                            final position = _currentPosition;
                            if (_centerOnLocation && position != null) {
                              _mapController.move(
                                LatLng(position.latitude, position.longitude), 13);
                            }
                          });
                        },
                        onStationPressed: (s) => _selectStation(s, fromMap: true),
                      )),
                      Positioned(right: 12, bottom: 36,
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(13),
                          elevation: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(13),
                            onTap: stations.isEmpty ? null : _openFullMap,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.fullscreen_rounded, size: 20, color: AppColors.ink),
                                SizedBox(width: 6),
                                Text('Ampliar mapa', style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 14,
                  runSpacing: 6, children: [
                    Text(_currentPosition == null ? 'Nuestras estaciones' : 'Cerca tuyo',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                        letterSpacing: -0.5, color: AppColors.ink)),
                    Text('${stations.length} ${stations.length == 1 ? 'estación' : 'estaciones'}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                  ]),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
              ]),
            ),
            if (stations.isEmpty)
              const SliverToBoxAdapter(child: _EmptyStations())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverToBoxAdapter(
                  child: Column(children: stations.map((station) => _StationRow(
                      key: _rowKeys.putIfAbsent(station, () => GlobalKey()),
                      station: station,
                      distance: _distanceText(station),
                      nearest: station == nearest,
                      selected: station == _selectedStation,
                      onSelect: () => _selectStation(station),
                      onNavigate: () => _openGoogleMaps(station),
                    )).toList()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void _fitStations(MapController controller, List<_LocalStation> stations) {
  if (stations.isEmpty) return;
  if (stations.length == 1) {
    controller.move(LatLng(stations.first.latitude, stations.first.longitude), 14);
    return;
  }
  controller.fitCamera(CameraFit.bounds(
    bounds: LatLngBounds.fromPoints(stations.map((s) => LatLng(s.latitude, s.longitude)).toList()),
    padding: const EdgeInsets.fromLTRB(40, 35, 40, 65),
    maxZoom: 14,
  ));
}

class _StationRow extends StatelessWidget {
  const _StationRow({super.key, required this.station, required this.distance,
    required this.nearest, required this.selected,
    required this.onSelect, required this.onNavigate});

  final _LocalStation station;
  final String distance;
  final bool nearest;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFEDF5FF) : Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
          decoration: const BoxDecoration(border: Border(
            bottom: BorderSide(color: AppColors.border))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Icon(selected ? Icons.location_on : Icons.location_on_outlined,
              size: 29, color: AppColors.blue),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(station.name, style: const TextStyle(fontSize: 16,
                fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.25)),
              if (nearest) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFFFD43B),
                    borderRadius: BorderRadius.circular(6)),
                  child: const Text('MÁS CERCANA', style: TextStyle(
                    fontSize: 9, letterSpacing: 0.6, fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
                ),
              ],
              const SizedBox(height: 6),
              Text(station.address, style: const TextStyle(
                color: AppColors.muted, fontSize: 12, height: 1.4)),
              const SizedBox(height: 5),
              Row(children: [
                const Icon(Icons.near_me_rounded, size: 13, color: AppColors.blue),
                const SizedBox(width: 5),
                Expanded(child: Text(distance, style: const TextStyle(
                  color: AppColors.blue, fontSize: 12, fontWeight: FontWeight.w600))),
              ]),
            ])),
            const SizedBox(width: 8),
            IconButton.outlined(
              tooltip: 'Cómo llegar a ${station.name}',
              onPressed: onNavigate,
              icon: const Icon(Icons.near_me_outlined, size: 22),
              style: IconButton.styleFrom(
                minimumSize: const Size(48, 48), foregroundColor: AppColors.blue,
                side: const BorderSide(color: AppColors.blue, width: 1)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _StationsMap extends StatelessWidget {
  const _StationsMap({required this.controller, required this.stations,
    required this.currentPosition, required this.selectedStation,
    required this.onStationPressed, required this.onReady});

  final MapController controller;
  final List<_LocalStation> stations;
  final Position? currentPosition;
  final _LocalStation? selectedStation;
  final ValueChanged<_LocalStation> onStationPressed;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: const LatLng(-34.9285, -58.4620),
        initialZoom: 11.7, minZoom: 2, maxZoom: 19,
        onMapReady: onReady,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.grupogen.ruta_gen_app',
        ),
        MarkerLayer(markers: [
          ...stations.map((station) {
            final selected = station == selectedStation;
            return Marker(
              point: LatLng(station.latitude, station.longitude),
              width: 52, height: 52,
              child: Semantics(
                label: station.name, button: true, selected: selected,
                child: Tooltip(message: station.name,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onStationPressed(station),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: selected ? 52 : 48,
                        height: selected ? 52 : 48,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.navy : AppColors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x26000000),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.local_gas_station_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          if (currentPosition != null)
            Marker(
              point: LatLng(currentPosition!.latitude, currentPosition!.longitude),
              width: 22, height: 22,
              child: Semantics(label: 'Tu ubicación', child: Container(
                decoration: BoxDecoration(color: AppColors.blue, shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: const [BoxShadow(color: Color(0x330878F9), blurRadius: 8)]),
              )),
            ),
        ]),
        const RichAttributionWidget(attributions: [
          TextSourceAttribution('OpenStreetMap contributors'),
        ]),
      ],
    );
  }
}

class _FullStationsMapPage extends StatefulWidget {
  const _FullStationsMapPage({required this.stations, required this.currentPosition,
    required this.selectedStation, required this.onNavigate,
    required this.onSelectionChanged});
  final List<_LocalStation> stations;
  final Position? currentPosition;
  final _LocalStation? selectedStation;
  final Future<void> Function(_LocalStation) onNavigate;
  final ValueChanged<_LocalStation> onSelectionChanged;

  @override
  State<_FullStationsMapPage> createState() => _FullStationsMapPageState();
}

class _FullStationsMapPageState extends State<_FullStationsMapPage> {
  final MapController _controller = MapController();
  late _LocalStation? _selected = widget.selectedStation;

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop(_selected)),
        title: const Text('Mapa de estaciones'),
        actions: [IconButton(
          tooltip: 'Ver todas las estaciones',
          onPressed: () => _fitStations(_controller, widget.stations),
          icon: const Icon(Icons.zoom_out_map_rounded)),
        ],
      ),
      body: Stack(children: [
        Positioned.fill(child: _StationsMap(
          controller: _controller, stations: widget.stations,
          currentPosition: widget.currentPosition, selectedStation: selected,
          onReady: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _fitStations(_controller, widget.stations);
              if (_selected != null) {
                _controller.move(LatLng(_selected!.latitude, _selected!.longitude), 14);
              }
            });
          },
          onStationPressed: (station) {
            setState(() => _selected = station);
            widget.onSelectionChanged(station);
            _controller.move(LatLng(station.latitude, station.longitude), 14);
          },
        )),
        Positioned(top: 12, right: 12, child: FloatingActionButton.small(
          heroTag: null, backgroundColor: Colors.white,
          tooltip: 'Centrar en mi ubicación',
          onPressed: widget.currentPosition == null ? null : () {
            final p = widget.currentPosition!;
            _controller.move(LatLng(p.latitude, p.longitude), 13);
          },
          child: Icon(Icons.my_location_rounded,
            color: widget.currentPosition == null ? AppColors.muted : AppColors.blue),
        )),
        Positioned(left: 16, right: 16, bottom: 16, child: SafeArea(
          top: false,
          child: Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: selected == null
                ? const Text('Tocá una estación para ver cómo llegar.',
                    style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600))
                : Column(mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(selected.name, style: const TextStyle(fontSize: 18,
                        color: AppColors.ink, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(selected.address, style: const TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => widget.onNavigate(selected),
                        icon: const Icon(Icons.near_me_outlined),
                        label: const Text('Cómo llegar'),
                      ),
                    ]),
          )),
        )),
      ]),
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
