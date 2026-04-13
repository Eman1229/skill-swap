import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SwapListing {
  final String id;
  final String name;
  final String initials;
  final Color avatarColor;
  final String offering;
  final String wanting;
  final double rating;
  final int reviews;
  final String category;
  final bool isLive;
  final String skillLevel;
  final String description;
  final String experience;
  final String portfolioFile;

  const SwapListing({
    required this.id,
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.offering,
    required this.wanting,
    required this.rating,
    required this.reviews,
    required this.category,
    this.isLive = false,
    this.skillLevel = 'Intermediates',
    this.description = '',
    this.experience = '',
    this.portfolioFile = '',
  });

  factory SwapListing.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final String name = (d['name'] as String?) ?? 'Unknown';
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : parts[0][0].toUpperCase();
    final Color color = d['avatarColor'] != null
        ? Color(d['avatarColor'] as int)
        : const Color(0xFF6B8AFF);

    return SwapListing(
      id: doc.id,
      name: name,
      initials: initials,
      avatarColor: color,
      offering: (d['offering'] as String?) ?? '',
      wanting: (d['wanting'] as String?) ?? '',
      rating: (d['Rating'] as num?)?.toDouble() ?? 0.0,
      reviews: (d['Reviews'] as num?)?.toInt() ?? 0,
      category: (d['Category'] as String?) ?? 'All',
      isLive: (d['is Live'] as bool?) ?? false,
      skillLevel: (d['skillLevel'] as String?) ?? '',
      description: (d['description'] as String?) ?? '',
      experience: (d['experience'] as String?) ?? '',
      portfolioFile: (d['portfolioFile'] as String?) ?? '',
    );
  }
}