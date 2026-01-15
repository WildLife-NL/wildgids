class ImageListModel {
  final List<String> imagePaths;

  ImageListModel({required this.imagePaths});

  void addImage(String path) {
    imagePaths.add(path);
  }

  void removeImage(String path) {
    imagePaths.remove(path);
  }

  Map<String, dynamic> toJson() => {'imagePaths': imagePaths};

  factory ImageListModel.fromJson(Map<String, dynamic> json) =>
      ImageListModel(imagePaths: List<String>.from(json['imagePaths']));
}
