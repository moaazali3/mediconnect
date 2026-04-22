class CreateSpecializationModel {
  final String name;
  final String description;

  CreateSpecializationModel({
    required this.name,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "description": description,
    };
  }
}
