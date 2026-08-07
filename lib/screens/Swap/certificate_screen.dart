import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skill_swap/models/swap_model.dart';
import 'package:skill_swap/providers/language_provider.dart';
import 'package:skill_swap/ui_helper/translation_helper.dart';

class CertificateScreen extends StatefulWidget {
  final SwapModel swap;

  const CertificateScreen({Key? key, required this.swap}) : super(key: key);

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isExporting = false;

  Future<String?> _captureAndSaveCertificate() async {
    try {
      final Uint8List? imageBytes = await _screenshotController.capture(pixelRatio: 3.0);
      if (imageBytes == null) return null;

      File? savedFile;
      final fileName = 'SkillSwapX_Certificate_${widget.swap.id}.png';

      if (Platform.isAndroid) {
        final publicDownloadDir = Directory('/storage/emulated/0/Download');
        if (await publicDownloadDir.exists()) {
          savedFile = File('${publicDownloadDir.path}/$fileName');
        } else {
          final extDir = await getExternalStorageDirectory();
          if (extDir != null) {
            savedFile = File('${extDir.path}/$fileName');
          }
        }
      } else {
        final downloadsDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        savedFile = File('${downloadsDir.path}/$fileName');
      }

      // Fallback if public save failed
      if (savedFile == null) {
        final tempDir = await getTemporaryDirectory();
        savedFile = File('${tempDir.path}/$fileName');
      }

      await savedFile.writeAsBytes(imageBytes);
      return savedFile.path;
    } catch (e) {
      debugPrint("Error saving certificate image: $e");
      return null;
    }
  }

  Future<void> _handleDownload() async {
    setState(() => _isExporting = true);
    final filePath = await _captureAndSaveCertificate();
    setState(() => _isExporting = false);

    if (mounted) {
      if (filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Certificate downloaded successfully!\nSaved to: $filePath'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to generate certificate image.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleShare() async {
    setState(() => _isExporting = true);
    final filePath = await _captureAndSaveCertificate();
    setState(() => _isExporting = false);

    if (filePath != null && mounted) {
      final xFile = XFile(filePath);
      await Share.shareXFiles(
        [xFile],
        text: 'My SkillSwapX Certificate for ${widget.swap.skillName}!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'certificate'.tr(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // Screenshot wrapper around certificate card
            Screenshot(
              controller: _screenshotController,
              child: CertificateCardWidget(swap: widget.swap),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextButton.icon(
                      onPressed: _isExporting ? null : _handleDownload,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.download_rounded, color: Colors.white),
                      label: Text(
                        'download'.tr(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextButton.icon(
                      onPressed: _isExporting ? null : _handleShare,
                      icon: Icon(Icons.share_rounded, color: Theme.of(context).colorScheme.primary),
                      label: Text(
                        'share'.tr(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CertificateCardWidget extends StatelessWidget {
  final SwapModel swap;
  final bool isCompact;

  const CertificateCardWidget({
    Key? key,
    required this.swap,
    this.isCompact = false,
  }) : super(key: key);

  Future<Map<String, String>> _resolveNames() async {
    String learner = swap.learnerName.trim();
    String mentor = swap.mentorName.trim();

    final invalidNames = {'', 'user', 'your teacher', 'teacher', 'learner', 'null'};

    final db = FirebaseFirestore.instance;

    if (invalidNames.contains(learner.toLowerCase()) && swap.learnerId.isNotEmpty) {
      try {
        final doc = await db.collection('users').doc(swap.learnerId).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final name = (data['name'] ?? data['fullName'] ?? data['username'] ?? '').toString().trim();
          if (name.isNotEmpty) learner = name;
        }
      } catch (_) {}
    }
    if (invalidNames.contains(mentor.toLowerCase()) && swap.mentorId.isNotEmpty) {
      try {
        final doc = await db.collection('users').doc(swap.mentorId).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final name = (data['name'] ?? data['fullName'] ?? data['username'] ?? '').toString().trim();
          if (name.isNotEmpty) mentor = name;
        }
      } catch (_) {}
    }

    // Attempt to fallback to FirebaseAuth current user if names are still invalid
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        if (invalidNames.contains(learner.toLowerCase()) && swap.learnerId == currentUser.uid) {
          if (currentUser.displayName != null && currentUser.displayName!.isNotEmpty) {
            learner = currentUser.displayName!;
          }
        }
        if (invalidNames.contains(mentor.toLowerCase()) && swap.mentorId == currentUser.uid) {
          if (currentUser.displayName != null && currentUser.displayName!.isNotEmpty) {
            mentor = currentUser.displayName!;
          }
        }
      }
    } catch (_) {}

    return {
      'learner': invalidNames.contains(learner.toLowerCase()) ? 'Learner' : learner.toUpperCase(),
      'mentor': invalidNames.contains(mentor.toLowerCase()) ? 'Teacher' : mentor,
    };
  }

  @override
  Widget build(BuildContext context) {
    final completedDate = swap.completedAt ?? DateTime.now();
    final dateStr = DateFormat('MMMM dd, yyyy').format(completedDate);
    final skillDisplayName = swap.skillName.trim().isEmpty ? 'SKILL SWAP' : swap.skillName.trim().toUpperCase();

    return AspectRatio(
      aspectRatio: 0.72,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3B82F6), // Vibrant Blue
              Color(0xFF6366F1), // Indigo
              Color(0xFF8B5CF6), // Vibrant Purple
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(5.5), // Gradient border thickness
        child: Container(
          padding: EdgeInsets.all(isCompact ? 12 : 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(19.5),
          ),
          child: FutureBuilder<Map<String, String>>(
            future: _resolveNames(),
            builder: (context, snapshot) {
              final names = snapshot.data ?? {
                'learner': swap.learnerName.trim().isEmpty ? 'LEARNER' : swap.learnerName.trim().toUpperCase(),
                'mentor': swap.mentorName.trim().isEmpty ? 'Teacher' : swap.mentorName.trim(),
              };

              final learnerDisplayName = names['learner']!;
              final teacherDisplayName = names['mentor']!;

              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: SizedBox(
                  width: isCompact ? 300 : 360,
                  height: isCompact ? 415 : 500,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Brand Header (Icon only - SkillSwapX text removed as requested)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Image.asset(
                          'assets/Images/logo.png',
                          height: isCompact ? 36 : 48,
                          width: isCompact ? 36 : 48,
                          fit: BoxFit.contain,
                        ),
                      ),

                      // Title & Custom Gradient Divider
                      Column(
                        children: [
                          Text(
                            'certificate_of_completion'.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              color: const Color(0xFF0F172A),
                              fontSize: isCompact ? 15 : 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: isCompact ? 6 : 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: isCompact ? 45 : 70,
                                height: 1.5,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: isCompact ? 4 : 6,
                                height: isCompact ? 4 : 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF8B5CF6),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: isCompact ? 45 : 70,
                                height: 1.5,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Recipient & Details
                      Column(
                        children: [
                          Text(
                            'this_is_to_certify'.tr(),
                            style: TextStyle(
                              color: const Color(0xFF64748B),
                              fontSize: isCompact ? 11 : 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          SizedBox(height: isCompact ? 6 : 10),
                          // Learner Full Name
                          Text(
                            learnerDisplayName,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              color: const Color(0xFF0F172A),
                              fontSize: isCompact ? 17 : 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: isCompact ? 6 : 10),
                          Text(
                            'has_successfully_completed_swap'.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF64748B),
                              fontSize: isCompact ? 11 : 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          SizedBox(height: isCompact ? 6 : 10),
                          // Skill Name
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                            ).createShader(bounds),
                            child: Text(
                              skillDisplayName,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                color: Colors.white,
                                fontSize: isCompact ? 16 : 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(height: isCompact ? 6 : 10),
                          // Teacher Name Placeholder
                          Text(
                            '${'taught_by'.tr()} $teacherDisplayName',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              color: const Color(0xFF475569),
                              fontSize: isCompact ? 11 : 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      // Bottom Footer: Date | Seal Badge | Authorized
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Left Date Field
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    color: const Color(0xFF0F172A),
                                    fontSize: isCompact ? 9 : 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: isCompact ? 55 : 85,
                                  height: 1.5,
                                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'date'.tr(),
                                  style: TextStyle(
                                    color: const Color(0xFF64748B),
                                    fontSize: isCompact ? 8 : 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),

                            // Center Seal Badge
                            Container(
                              width: isCompact ? 50 : 60,
                              height: isCompact ? 50 : 60,
                              child: Image.asset(
                                'assets/Images/badge.png',
                                fit: BoxFit.contain,
                              ),
                            ),

                            // Right Authorized Sign Field
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'SkillSwapX',
                                  style: TextStyle(
                                    color: const Color(0xFF0F172A),
                                    fontSize: isCompact ? 9 : 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: isCompact ? 55 : 85,
                                  height: 1.5,
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.6),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'authorized'.tr(),
                                  style: TextStyle(
                                    color: const Color(0xFF64748B),
                                    fontSize: isCompact ? 8 : 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
