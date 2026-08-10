import 'package:geocoding/geocoding.dart';

Future<String?> getPlacemarkLabel(double lat, double lng) async {
  final geocoding = Geocoding();

  final placemarks = await geocoding.placemarkFromCoordinates(
    lat,
    lng,
  );

  if (placemarks.isEmpty) return null;

  final p = placemarks.first;

  final parts = <String>[
    if (p.subLocality != null && p.subLocality!.isNotEmpty)
      p.subLocality!,
    if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
  ];

  return parts.isEmpty ? p.name : parts.join(', ');
}