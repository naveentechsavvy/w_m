/// A manually-entered delivery address for a food order. Kept simple
/// on purpose — embedded directly into the order document rather than
/// stored as its own Firestore collection, since addresses aren't
/// reused across orders yet.
class DeliveryAddress {
  final String name;
  final String phone;
  final String addressLine;
  final String city;
  final String pincode;
  final String notes;

  DeliveryAddress({
    required this.name,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.pincode,
    this.notes = '',
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'addressLine': addressLine,
        'city': city,
        'pincode': pincode,
        'notes': notes,
      };
}
