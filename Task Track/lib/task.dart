class Task {
  int? id;
  String name;
  String description;
  bool isCompleted;
  bool repeat; // Correct field name
  List<String>? repeatDays;

  Task({
    this.id,
    required this.name,
    required this.description,
    this.isCompleted = false,
    this.repeat = false, // Correct field name
    this.repeatDays,
  });

  // Method to convert the task to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isCompleted': isCompleted ? 1 : 0,
      'repeat': repeat ? 1 : 0, // Correct field name
      'repeatDays': repeatDays?.join(','),
    };
  }

  // Factory method to convert map to task
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      isCompleted: map['isCompleted'] == 1,
      repeat: map['repeat'] == 1, // Correct field name
      repeatDays: map['repeatDays']?.split(','),
    );
  }
}
