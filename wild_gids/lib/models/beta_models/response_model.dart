class Response {
  String? answerID;
  String interactionID;
  String questionID;
  String? text;

  Response({
    this.answerID,
    required this.interactionID,
    required this.questionID,
    this.text,
  });

  factory Response.fromJson(Map<String, dynamic> json) => Response(
    answerID: json["answerID"],
    interactionID: json["interactionID"],
    questionID: json["questionID"],
    text: json["text"],
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['interactionID'] = interactionID;
    data['questionID'] = questionID;
    data['answerID'] = answerID;
    if (text != null) {
      data['text'] = text;
    }
    return data;
  }
    Response copyWith({
    String? answerID,
    String? interactionID,
    String? questionID,
    String? text,
  }) {
    return Response(
      answerID: answerID ?? this.answerID,
      interactionID: interactionID ?? this.interactionID,
      questionID: questionID ?? this.questionID,
      text: text ?? this.text,
    );
  }
}
