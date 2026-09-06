import '../datasources/experience_datasource.dart';
import '../models/experience_model.dart';

class ExperienceRepository {
  final ExperienceDataSource datasource = ExperienceDataSource();

  Future<String> createMeetup(Experience experience) =>
    datasource.createMeetup(experience);

  Future<List<Experience>> getAllMeetups() => datasource.getAllMeetups();

  Future<List<Experience>> getMeetupsByCreator(String uid) =>
      datasource.getMeetupsByCreator(uid);

  Future<Experience?> getMeetupById(String id) =>
      datasource.getMeetupById(id);

  /// Soft-cancels a meetup: marks it cancelled (with the organizer's
  /// reason) instead of deleting the document, so it can still appear
  /// in "Cancelled" views on both the app and the website.
  Future<void> cancelMeetup(String id, {required String reason}) =>
      datasource.updateMeetup(id, {
        'cancelled': true,
        'cancelReason': reason,
      });
}