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
  });
}