import 'package:cloud_firestore/cloud_firestore.dart';

/// Single source of truth for teaching/learning skills derived from marketplace listings.
class UserSkillsService {
  UserSkillsService._();

  static List<String> teachingSkillsFromListingDocs(
    Iterable<QueryDocumentSnapshot<Object?>> docs,
  ) {
    final skills = <String>{};
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final offering = data['offering']?.toString().trim() ?? '';
      if (offering.isNotEmpty) skills.add(offering);
    }
    return skills.toList()..sort();
  }

  static List<String> learningSkillsFromListingDocs(
    Iterable<QueryDocumentSnapshot<Object?>> docs,
  ) {
    final skills = <String>{};
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final wanting = data['wanting']?.toString().trim() ?? '';
      if (wanting.isNotEmpty) skills.add(wanting);
    }
    return skills.toList()..sort();
  }

  static List<String> teachingSkillsFromListingMaps(
    Iterable<Map<String, dynamic>> listingMaps,
  ) {
    final skills = <String>{};
    for (final data in listingMaps) {
      final offering = data['offering']?.toString().trim() ?? '';
      if (offering.isNotEmpty) skills.add(offering);
    }
    return skills.toList()..sort();
  }

  static List<String> learningSkillsFromListingMaps(
    Iterable<Map<String, dynamic>> listingMaps,
  ) {
    final skills = <String>{};
    for (final data in listingMaps) {
      final wanting = data['wanting']?.toString().trim() ?? '';
      if (wanting.isNotEmpty) skills.add(wanting);
    }
    return skills.toList()..sort();
  }

  /// Returns the sender's most recent listing for swap requests.
  static Future<Map<String, dynamic>?> fetchLatestListingForUser(String uid) async {
    if (uid.isEmpty) return null;

    final snap = await FirebaseFirestore.instance
        .collection('swapListings')
        .where('userId', isEqualTo: uid)
        .get();

    if (snap.docs.isEmpty) return null;

    final sorted = snap.docs.toList()
      ..sort((a, b) {
        final aData = a.data();
        final bData = b.data();
        final aTime = _timestampMillis(aData['updatedAt']) ??
            _timestampMillis(aData['createdAt']) ??
            0;
        final bTime = _timestampMillis(bData['updatedAt']) ??
            _timestampMillis(bData['createdAt']) ??
            0;
        return bTime.compareTo(aTime);
      });

    return sorted.first.data();
  }

  static int? _timestampMillis(dynamic value) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    return null;
  }
}
