import '../datasources/join_request_datasource.dart';
import '../models/experience_model.dart';
import '../models/join_request_model.dart';

class JoinRequestRepository {
  final JoinRequestDataSource datasource = JoinRequestDataSource();

  Future<void> sendRequest(Experience meetup) => datasource.sendRequest(meetup);
  Future<void> approve(String id) => datasource.approve(id);
  Future<void> reject(String id) => datasource.reject(id);
  Future<void> cancel(String id) => datasource.cancel(id);
  Future<List<JoinRequest>> getMyRequests() => datasource.getMyRequests();
  Future<List<JoinRequest>> getRequestsForMeetup(Experience meetup) =>
      datasource.getRequestsForMeetup(meetup);
}