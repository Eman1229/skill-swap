import 'package:cloud_firestore/cloud_firestore.dart';

class UserDisplayName {
  static const Set<String> _genericNames = {
    'user',
    'mentor',
    'learner',
    'teacher',
    'student',
    'someone',
    'your instructor',
    'your student',
    'your mentor',
  };

  static bool isUsable(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return false;
    return !_genericNames.contains(trimmed.toLowerCase());
  }

  static String clean(String? value) => value?.trim() ?? '';

  static String fromMap(Map<String, dynamic>? data, {String fallback = ''}) {
    if (data == null) return fallback;

    for (final field in const [
      'name',
      'displayName',
      'fullName',
      'username',
      'userName',
    ]) {
      final value = clean(data[field]?.toString());
      if (isUsable(value)) {
        return field.toLowerCase().contains('username')
            ? value.replaceFirst(RegExp(r'^@+'), '')
            : value;
      }
    }

    return fallback;
  }

  static Future<String> resolve(
    FirebaseFirestore db,
    String uid, {
    String fallback = '',
    String? authDisplayName,
  }) async {
    try {
      final doc = await db.collection('users').doc(uid).get();
      final profileName = fromMap(doc.data());
      if (isUsable(profileName)) return profileName;
    } catch (_) {}

    if (isUsable(authDisplayName)) return clean(authDisplayName);
    return fallback;
  }
}
