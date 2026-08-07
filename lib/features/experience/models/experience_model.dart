class Experience {
  final String id;
  final String title;
  final String category;
  final String location;
  final String image;
  final DateTime date;
  final double price;
  final int joined;
  final int seats;
  final bool foodAvailable;

  // New fields for Sprint 3+
  final String description;
  final String organizerName;
  final bool isPrivate;
  final List<String> participants;
  final List<String> gallery;

  Experience({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.image,
    required this.date,
    required this.price,
    required this.joined,
    required this.seats,
    required this.foodAvailable,
    this.description = "",
    this.organizerName = "You",
    this.isPrivate = false,
    this.participants = const [],
    this.gallery = const [],
  });
}