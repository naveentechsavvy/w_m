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

  Future<void> cancelMeetup(String id) => datasource.deleteMeetup(id);
}