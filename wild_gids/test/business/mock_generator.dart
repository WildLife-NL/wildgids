// test/mocks/mock_api_data_service.dart

import 'package:mockito/annotations.dart';
import 'package:wildgids/interfaces/map/location_service_interface.dart';
import 'package:wildgids/interfaces/map/map_service_interface.dart';
import 'package:wildgids/interfaces/map/map_state_interface.dart';
import 'package:wildgids/interfaces/reporting/common_report_fields.dart';
import 'package:wildgids/interfaces/reporting/possesion_report_fields.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_interface.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/interfaces/data_apis/auth_api_interface.dart';
import 'package:wildgids/interfaces/data_apis/belonging_api_interface.dart';
import 'package:wildgids/interfaces/data_apis/interaction_api_interface.dart';
import 'package:wildgids/interfaces/data_apis/profile_api_interface.dart';
import 'package:wildgids/interfaces/data_apis/questionnaire_api_interface.dart';
import 'package:wildgids/interfaces/data_apis/response_api_interface.dart';
import 'package:wildgids/interfaces/data_apis/species_api_interface.dart';
import 'package:wildgids/interfaces/reporting/belonging_damage_report_interface.dart';
import 'package:wildgids/interfaces/other/belonging_manager_interface.dart';
import 'package:wildgids/interfaces/filters/dropdown_interface.dart';
import 'package:wildgids/interfaces/state/edit_state_interface.dart';
import 'package:wildgids/interfaces/filters/filter_interface.dart';
import 'package:wildgids/interfaces/reporting/interaction_interface.dart';
import 'package:wildgids/interfaces/location/living_lab_interface.dart';
import 'package:wildgids/interfaces/location/location_screen_interface.dart';
import 'package:wildgids/interfaces/other/login_interface.dart';
import 'package:wildgids/interfaces/reporting/reportable_interface.dart';
import 'package:wildgids/interfaces/other/overzicht_interface.dart';
import 'package:wildgids/interfaces/other/permission_interface.dart';
import 'package:wildgids/interfaces/reporting/questionnaire_interface.dart';
import 'package:wildgids/interfaces/reporting/response_interface.dart';
import 'package:wildgids/interfaces/state/screen_state_interface.dart';
import 'package:wildgids/models/animal_waarneming_models/view_count_model.dart';
import 'package:wildgids/models/api_models/experiment.dart';
import 'package:wildgids/models/api_models/interaction_type.dart';
import 'package:wildgids/models/api_models/question.dart';
import 'package:wildgids/models/beta_models/location_model.dart';
import 'package:wildgids/providers/app_state_provider.dart';
import 'package:wildgids/providers/map_provider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_sighting_model.dart';
import 'package:wildgids/models/api_models/questionaire.dart';
import 'package:wildgids/models/api_models/species.dart';
import 'package:wildgids/models/api_models/user.dart';
import 'package:wildgids/models/beta_models/belonging_model.dart';
import 'package:wildgids/models/beta_models/interaction_model.dart';
import 'package:wildgids/models/beta_models/possesion_model.dart';
import 'package:wildgids/models/beta_models/report_location_model.dart';
import 'package:wildgids/models/beta_models/response_model.dart';

// API interfaces Mocks
@GenerateMocks([AuthApiInterface])
@GenerateMocks([BelongingApiInterface])
@GenerateMocks([InteractionApiInterface])
@GenerateMocks([ProfileApiInterface])
@GenerateMocks([QuestionnaireApiInterface])
@GenerateMocks([ResponseApiInterface])
@GenerateMocks([SpeciesApiInterface])
// Map interfaces Mocks
@GenerateMocks([LocationServiceInterface])
@GenerateMocks([MapServiceInterface])
@GenerateMocks([MapStateInterface])
// Reporting interfaces Mocks
@GenerateMocks([CommonReportFields])
@GenerateMocks([PossesionReportFields])
@GenerateMocks([Reportable])
// Managers interfaces Mocks
@GenerateMocks([AnimalRepositoryInterface])
@GenerateMocks([AnimalSightingReportingInterface])
@GenerateMocks([BelongingDamageReportInterface])
@GenerateMocks([BelongingManagerInterface])
@GenerateMocks([DropdownInterface])
@GenerateMocks([EditStateInterface])
@GenerateMocks([CategoryInterface])
@GenerateMocks([FilterInterface])
@GenerateMocks([InteractionInterface])
@GenerateMocks([LivingLabInterface])
@GenerateMocks([LocationScreenInterface])
@GenerateMocks([LoginInterface])
@GenerateMocks([NavigationStateInterface])
@GenerateMocks([OverzichtInterface])
@GenerateMocks([PermissionInterface])
@GenerateMocks([QuestionnaireInterface])
@GenerateMocks([ResponseInterface])
@GenerateMocks([ScreenStateInterface])
//Provider Mocks
@GenerateMocks([AppStateProvider])
@GenerateMocks([MapProvider])
@GenerateMocks([AnimalManagerInterface])
// External dependencies
@GenerateMocks([BuildContext])
@GenerateMocks([SharedPreferences])
@GenerateMocks([Connectivity])
// Model Mocks
@GenerateMocks([AnimalModel])
@GenerateMocks([AnimalSightingModel])
@GenerateMocks([Questionnaire])
@GenerateMocks([Species])
@GenerateMocks([User])
@GenerateMocks([Belonging])
@GenerateMocks([Interaction])
@GenerateMocks([Possesion])
@GenerateMocks([ReportLocation])
@GenerateMocks([Response])
@GenerateMocks([InteractionType])
@GenerateMocks([Question])
@GenerateMocks([Experiment])
@GenerateMocks([ViewCountModel])
@GenerateMocks([LocationModel])
void main() {} // required for code generation

