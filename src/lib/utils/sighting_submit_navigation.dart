import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/models/beta_models/interaction_response_model.dart';
import 'package:wildgids/screens/location/kaart_overview_screen.dart';
import 'package:wildgids/screens/questionnaire/questionnaire_screen.dart';
import 'package:wildgids/utils/toast_notification_handler.dart';
import 'package:wildgids/services/questionnaire_notifications.dart';

/// Na succesvol versturen van een waarneming: enquête tonen indien aanwezig, anders kaart.
Future<void> navigateAfterSightingSubmit(
  BuildContext context,
  InteractionResponse response, {
  bool showSuccessToast = true,
}) async {
  final nav = context.read<NavigationStateInterface>();
  final questions = response.questionnaire.questions;
  final hasQuestionnaire = questions != null && questions.isNotEmpty;

  final showImmediately =
      hasQuestionnaire &&
      await QuestionnaireNotifications.instance.receive(
        response.questionnaire,
        response.interactionID,
      );
  if (!context.mounted) return;

  if (showImmediately) {
    nav.pushAndRemoveUntil(
      context,
      QuestionnaireScreen(
        questionnaire: response.questionnaire,
        interactionID: response.interactionID,
      ),
    );
    return;
  }

  if (showSuccessToast) {
    ToastNotificationHandler.sendToastNotification(
      context,
      'Waarneming succesvol verstuurd',
    );
  }

  nav.pushAndRemoveUntil(context, const KaartOverviewScreen());
}
