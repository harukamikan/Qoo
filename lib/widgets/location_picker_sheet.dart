import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:http/http.dart' as http;
import '../theme/app_colors.dart';
import '../services/ui_translations.dart';

/// 場所選択ボトムシート。
/// ミニマップをタップして場所を選ぶ（検索は補助機能）。
/// 確定すると [onLocationSelected] に緯度経度を返す。
class LocationPickerSheet extends StatefulWidget {
  final ll.LatLng initialPosition;
  final void Function(ll.LatLng position, String placeName) onLocationSelected;

  const LocationPickerSheet({
    super.key,
    required this.initialPosition,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  late ll.LatLng _selectedPosition;
  late String _placeName;
  final _searchController = TextEditingController();
  final _mapController = MapController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
    _placeName = UiTranslations.t('選択した場所');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Nominatimで場所名を検索する
  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json&limit=5&countrycodes=jp',
      );
      final response = await http.get(uri, headers: {
        'Accept-Language': 'ja',
        'User-Agent': 'QooApp/1.0',
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _searchResults = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Nominatim search error: $e');
    } finally {
      setState(() => _searching = false);
    }
  }

  void _selectPosition(ll.LatLng position, String name) {
    setState(() {
      _selectedPosition = position;
      _placeName = name;
      _searchResults = [];
      _searchController.clear();
    });
    _mapController.move(position, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // ハンドル
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // タイトル
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                UiTranslations.t('場所を選択'),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            // 検索バー
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: UiTranslations.t('スポット名で絞り込み（任意）'),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) => _search(value),
              ),
            ),
            // 検索結果リスト
            if (_searchResults.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    final name = result['display_name'] as String;
                    final lat = double.parse(result['lat'] as String);
                    final lon = double.parse(result['lon'] as String);
                    return ListTile(
                      leading: const Icon(Icons.location_on,
                          color: AppColors.primary),
                      title: Text(name,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      onTap: () => _selectPosition(ll.LatLng(lat, lon), name),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            // ミニマップ
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _selectedPosition,
                      initialZoom: 15.0,
                      onTap: (tapPosition, point) {
                        _selectPosition(point, UiTranslations.t('選択した場所'));
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.qoo',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedPosition,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_pin,
                              color: AppColors.primary,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 選択中の場所表示
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '📍 $_placeName',
                style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            // 決定ボタン
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                      Navigator.pop(context);
                      widget.onLocationSelected(_selectedPosition, _placeName);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: Text(UiTranslations.t('この場所で決定')),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 場所選択ボトムシートを表示するヘルパー関数。
Future<void> showLocationPickerSheet(
  BuildContext context, {
  required ll.LatLng initialPosition,
  required void Function(ll.LatLng position, String placeName)
      onLocationSelected,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => LocationPickerSheet(
      initialPosition: initialPosition,
      onLocationSelected: onLocationSelected,
    ),
  );
}
