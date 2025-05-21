class Problem {
  final String id;
  final String title;
  final String description;
  final String difficulty;
  final List<String> tags;
  final String constraints;
  final List<SampleIO> sampleIO;
  final List<TestCases> testCases;

  Problem({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.tags,
    required this.constraints,
    required this.sampleIO,
    required this.testCases,
  });

  factory Problem.fromJson(Map<String, dynamic> json) {
    return Problem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      difficulty: json['difficulty'],
      tags: List<String>.from(json['tags']),
      constraints: json['constraints'],
      sampleIO: (json['sampleIO'] as List)
          .map((item) => SampleIO.fromJson(item))
          .toList(),
      testCases: (json['testCases'] as List)
          .map((item) => TestCases.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'tags': tags,
      'constraints': constraints,
      'sampleIO': sampleIO.map((item) => item.toJson()).toList(),
      'testCases': testCases.map((item) => item.toJson()).toList(),
    };
  }
}

class SampleIO {
  final String input;
  final String inputDisplay;
  final String output;
  final String outputDisplay;

  SampleIO({
    required this.input,
    required this.output,
    this.inputDisplay = '',
    this.outputDisplay = '',
  });

  factory SampleIO.fromJson(Map<String, dynamic> json) {
    return SampleIO(
      input: json['input'],
      inputDisplay: json['inputDisplay'],
      output: json['output'],
      outputDisplay: json['outputDisplay'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'input': input,
      'inputDisplay': inputDisplay,
      'output': output,
      'outputDisplay': outputDisplay,
    };
  }
}

class TestCases {
  final String input;
  final String output;

  TestCases({required this.input, required this.output});

  factory TestCases.fromJson(Map<String, dynamic> json) {
    return TestCases(
      input: json['input'],
      output: json['output'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'input': input,
      'output': output,
    };
  }
}
