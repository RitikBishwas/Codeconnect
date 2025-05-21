import 'package:cloud_functions/cloud_functions.dart';

class SecretsManager {
  static final SecretsManager _instance = SecretsManager._internal();

  factory SecretsManager() => _instance;

  SecretsManager._internal();

  Map<String, dynamic>? _secrets;

  Future<void> loadSecrets() async {
    if (_secrets == null) {
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('getSecrets');
      final result = await callable();
      _secrets = Map<String, dynamic>.from(result.data);
    }
  }

  String? get(String key) => _secrets?[key];
}
