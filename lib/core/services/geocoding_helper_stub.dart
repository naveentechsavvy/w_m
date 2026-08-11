/// Web fallback — geocoding package has no web implementation, so this
/// stub is used instead via conditional import. Always returns null.
Future<String?> getPlacemarkLabel(double lat, double lng) async {
  return null;
}