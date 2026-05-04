class Answer {
  String id;
  int index;
  String? nextQuestionId;
  String text;

  Answer({
    required this.id,
    required this.index,
    required this.text,
    this.nextQuestionId,
  });

  factory Answer.fromJson(Map<String, dynamic> json) => Answer(
    id: json["ID"],
    index: json["index"],
    nextQuestionId: json["nextQuestionID"],
    text: json["text"],
  );

  Map<String, dynamic> toJson() => {
    "ID": id,
    "index": index,
    "nextQuestionID": nextQuestionId,
    "text": text,
  };
}
