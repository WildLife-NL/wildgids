import 'package:widgets/models/beta_models/profile_model.dart';

abstract class ProfileApiInterface {
  Future<void> setProfileDataInDeviceStorage();

  Future<Profile> fetchMyProfile();
  
  Future<Profile> updateReportAppTerms(bool accepted);
}
