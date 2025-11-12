import 'package:flutter/material.dart';
import 'package:wildrapport/models/beta_models/response_model.dart';

class ResponseProvider extends ChangeNotifier {
  String? answerID;
  String? interactionID;
  String? questionID;
  String? text;
  Response? response;
  List<Response> responses = [];
  bool updatingResponse = false;

  final yellowLog = '\x1B[93m';

  void setResponse(Response value) {
    response = value;
  }

  void addResponse(Response value) {
    debugPrint("$yellowLog [ResponseProvider]: Adding Response");
    responses.add(value);
  }

  void removeResponse(Response value) {
    responses.remove(value);
  }

  void setUpdatingResponse(bool value){
    debugPrint("$yellowLog [ResponseProvider]: Updating Response");
    updatingResponse = value;
    notifyListeners();
  }
  void updateResponse(Response? value) {
    final index = responses.indexWhere((r) => r.questionID == value?.questionID);
    if (index != -1) {
      responses[index] = value!;
      notifyListeners();
    }
  }

  void setAnswerID(String value) {
    debugPrint("$yellowLog [ResponseProvider]: setting the answerID: $value");
    answerID = value;
    notifyListeners();
  }
  void clearAnswerID(){
    debugPrint("$yellowLog [ResponseProvider]: clearing the answerID");
    answerID = null;
    notifyListeners();
  }

  void setInteractionID(String value) {
    debugPrint(
      "$yellowLog [ResponseProvider]: setting the interactionID: $value",
    );
    interactionID = value;
    notifyListeners();
  }

  void setQuestionID(String value) {
    debugPrint("$yellowLog [ResponseProvider]: setting the questionID: $value");
    questionID = value;
    notifyListeners();
  }

  void setText(String value) {
    debugPrint("$yellowLog [ResponseProvider]: setting the text: $value");
    text = value;
    notifyListeners();
  }

  Response buildResponse() {
    return Response(
      answerID: answerID,
      interactionID: interactionID!,
      questionID: questionID!,
      text: text,
    );
  }

  void clearResponse() {
    response = null;
    answerID = null;
    interactionID = null;
    questionID = null;
    text = null;
    updatingResponse = false;
    notifyListeners();
  }
  void clearResponsesList(){
    responses = [];
  }
}
