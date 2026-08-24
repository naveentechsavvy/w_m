import '../datasources/app_config_datasource.dart';

class AppConfigRepository {
  final AppConfigDataSource datasource = AppConfigDataSource();

  Stream<bool> streamPremiumEnabled() => datasource.streamPremiumEnabled();
}