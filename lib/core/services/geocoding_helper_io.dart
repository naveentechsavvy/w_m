import 'package:geocoding/geocoding.dart';

Future<String?> getPlacemarkLabel(double lat, double lng) async {
  final placemarks = await placemarkFromCoordinates(lat, lng);
  if (placemarks.isEmpty) return null;
  final p = placemarks.first;
  final parts = [p.subLocality, p.locality]
      .where((e) => e.isNotEmpty)
      .toList();
  return parts.isEmpty ? p.name : parts.join(", ");
}