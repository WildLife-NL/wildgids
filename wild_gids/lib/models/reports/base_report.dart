abstract class BaseReport {
  final String type;
  final DateTime createdAt;
  final Map<String, dynamic> properties = {};

  BaseReport(this.type) : createdAt = DateTime.now();

  void updateProperty(String property, dynamic value) {
    properties[property] = value;
  }

  dynamic getProperty(String property) {
    return properties[property];
  }
}
