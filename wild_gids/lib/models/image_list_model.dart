class ImageListModel {
  final List<String>? imagePaths;

  ImageListModel({
    this.imagePaths,
  });

  Map<String, dynamic> toJson() {
    return {
      'imagePaths': imagePaths,
    };
  }

  factory ImageListModel.fromJson(Map<String, dynamic> json) {
    return ImageListModel(
      imagePaths: json['imagePaths'] != null
          ? List<String>.from(json['imagePaths'])
          : null,
    );
  }

  ImageListModel copyWith({
    List<String>? imagePaths,
  }) {
    return ImageListModel(
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }
}
