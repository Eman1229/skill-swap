import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:skill_swap/screens/Home Screens/swapping Available.dart';
import 'package:skill_swap/screens/Add%20skill/no_skill_dialog.dart';
import 'package:skill_swap/screens/Swap/confirm_swap_screen.dart';
import 'package:skill_swap/screens/Chat/conversation_screen.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────
// GLOBAL PROFILE IMAGE NOTIFIER b
// (Put this in a shared file, e.g. lib/providers/profile_image_provider.dart)
// ─────────────────────────────────────────────────────────────────────
class ProfileImageNotifier extends ValueNotifier<File?> {
  ProfileImageNotifier() : super(null);

  static final ProfileImageNotifier instance = ProfileImageNotifier();
}

// ─────────────────────────────────────────────────────────────────────
// REUSABLE PROFILE AVATAR WIDGET
// Use this widget on EVERY page where the avatar should appear
// ─────────────────────────────────────────────────────────────────────
class ProfileAvatar extends StatefulWidget {
  final SwapListing swap;
  final double size;
  final bool allowEdit;
  final Color? borderColor;

  ProfileAvatar({
    Key? key,
    required this.swap,
    this.size = 100,
    this.allowEdit = true,
    this.borderColor,
  }) : super(key: key);

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImageSourceSheet(
        onCameraSelected: () async {
          Navigator.pop(context);
          await _pickImage(ImageSource.camera);
        },
        onGallerySelected: () async {
          Navigator.pop(context);
          await _pickImage(ImageSource.gallery);
        },
        onRemoveSelected: ProfileImageNotifier.instance.value != null
            ? () {
          Navigator.pop(context);
          ProfileImageNotifier.instance.value = null;
        }
            : null,
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 600,
        maxHeight: 600,
      );
      if (picked != null) {
        ProfileImageNotifier.instance.value = File(picked.path);
      }
    } catch (e) {
      // Permission denied or other error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              source == ImageSource.camera
                  ? 'Camera access denied. Please allow access in Settings.'
                  : 'Gallery access denied. Please allow access in Settings.',
            ),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.size;
    final double cameraIconSize = size * 0.28;

    return ValueListenableBuilder<File?>(
      valueListenable: ProfileImageNotifier.instance,
      builder: (context, imageFile, _) {
        return GestureDetector(
          onTap: widget.allowEdit ? _showImageSourceSheet : null,
          child: SizedBox(
            width: size + 8,
            height: size + 8,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ── Avatar Circle ──
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: imageFile == null ? widget.swap.avatarColor : null,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          widget.borderColor ?? Theme.of(context).scaffoldBackgroundColor,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.swap.avatarColor.withOpacity(0.4),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                    image: imageFile != null
                        ? DecorationImage(
                      image: FileImage(imageFile),
                      fit: BoxFit.cover,
                    )
                        : (widget.swap.imageUrl != null
                        ? DecorationImage(
                      image: NetworkImage(widget.swap.imageUrl!),
                      fit: BoxFit.cover,
                    )
                        : null),
                  ),
                  child: imageFile == null && widget.swap.imageUrl == null
                      ? Center(
                    child: Text(
                      widget.swap.initials,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: size * 0.32,
                      ),
                    ),
                  )
                      : null,
                ),

                // ── Camera Badge (edit indicator) ──
                if (widget.allowEdit)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: cameraIconSize + 6,
                      height: cameraIconSize + 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Theme.of(context).colorScheme.primary, Color(0xFF6B8AFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              widget.borderColor ?? Theme.of(context).scaffoldBackgroundColor,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: cameraIconSize,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// IMAGE SOURCE BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────
class _ImageSourceSheet extends StatelessWidget {
  final VoidCallback onCameraSelected;
  final VoidCallback onGallerySelected;
  final VoidCallback? onRemoveSelected;

  _ImageSourceSheet({
    required this.onCameraSelected,
    required this.onGallerySelected,
    this.onRemoveSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──
          Container(
            margin: EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Header ──
          Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Theme.of(context).colorScheme.primary, Color(0xFF6B8AFF)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.account_circle_rounded,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Update Profile Photo',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Choose how to upload your picture',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.07), height: 24),

          // ── Camera Option ──
          _SheetOption(
            icon: Icons.camera_alt_rounded,
            iconGradient: [Theme.of(context).colorScheme.primary, Color(0xFF0EA5E9)],
            label: 'Take a Photo',
            subtitle: 'Allow camera access to take a new picture',
            onTap: onCameraSelected,
          ),

          SizedBox(height: 4),

          // ── Gallery Option ──
          _SheetOption(
            icon: Icons.photo_library_rounded,
            iconGradient: [Color(0xFF6B8AFF), Color(0xFF8B5CF6)],
            label: 'Choose from Gallery',
            subtitle: 'Pick an existing photo from your device',
            onTap: onGallerySelected,
          ),

          // ── Remove Option (only if photo is set) ──
          if (onRemoveSelected != null) ...[
            SizedBox(height: 4),
            _SheetOption(
              icon: Icons.delete_outline_rounded,
              iconGradient: [Color(0xFFEF4444), Color(0xFFF97316)],
              label: 'Remove Photo',
              subtitle: 'Revert back to your initials avatar',
              onTap: onRemoveSelected!,
              isDestructive: true,
            ),
          ],

          SizedBox(height: 12),

          // ── Cancel ──
          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final List<Color> iconGradient;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  _SheetOption({
    required this.icon,
    required this.iconGradient,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDestructive
                    ? Color(0xFFEF4444).withOpacity(0.15)
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: iconGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 22),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: isDestructive
                              ? Color(0xFFEF4444)
                              : Theme.of(context).colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  final SwapListing swap;

  ProfileScreen({Key? key, required this.swap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Top gradient background ──
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Theme.of(context).colorScheme.primary, Color(0xFF6B8AFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.onSurface.withAlpha(51), // 0.2 * 255
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_back,
                                color: Theme.of(context).colorScheme.onSurface,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Avatar overlapping gradient ──
                Transform.translate(
                  offset: Offset(0, -60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Center(
                        child: Column(
                          children: [
                            ProfileAvatar(
                              swap: swap,
                              size: 100,
                              allowEdit: false,
                              borderColor: Theme.of(context).scaffoldBackgroundColor,
                            ),
                            SizedBox(height: 12),
                            Text(
                              swap.name,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.star_rounded,
                                    color: Color(0xFFFBBF24), size: 18),
                                SizedBox(width: 4),
                                Text(
                                  '${swap.rating.toStringAsFixed(1)}(${swap.reviews} Swaps)',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 28),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            _DetailRow(
                              label: 'Skill Title',
                              value: swap.offering,
                              isText: true,
                            ),
                            _Divider(),
                            _DetailRow(
                              label: 'Category',
                              value: swap.category,
                              isText: false,
                              icon: _categoryIcon(swap.category),
                            ),
                            _Divider(),
                            _DetailRow(
                              label: 'Skill Level',
                              value: swap.skillLevel,
                              isText: true,
                            ),
                            _Divider(),
                            _DetailRow(
                              label: 'No of swaps',
                              value: '${swap.reviews}',
                              isText: true,
                            ),
                            _Divider(),
                            _DetailRow(
                              label: 'Looking for',
                              value: swap.wanting,
                              isText: false,
                              isHighlight: true,
                            ),
                            _Divider(),
                            if (swap.portfolioFile.isNotEmpty) ...[
                              _DetailRow(
                                label: 'Portfolio',
                                value: _getPortfolioName(swap.portfolioFile),
                                isText: false,
                                isLink: true,
                                onTap: () => _openPortfolio(context, swap.portfolioFile),
                              ),
                              _Divider(),
                            ],
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Description',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              swap.description.isNotEmpty
                                  ? swap.description
                                  : 'No description provided.',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 13,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Experience',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              swap.experience.isNotEmpty
                                  ? swap.experience
                                  : 'No experience details provided.',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 13,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'the skill available',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Sticky Bottom Buttons ──
          if (FirebaseAuth.instance.currentUser?.uid != swap.userId)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 30),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.primary.withAlpha(26), // 0.1 * 255
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConversationScreen(swap: swap),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Theme.of(context).colorScheme.primary, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Message',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Theme.of(context).colorScheme.primary, Color(0xFF6B8AFF)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            if (uid == null) return;

                            // Check if current user has created any skill listing
                            final snap = await FirebaseFirestore.instance
                                .collection('swapListings')
                                .where('userId', isEqualTo: uid)
                                .limit(1)
                                .get();

                            if (!context.mounted) return;

                            if (snap.docs.isEmpty) {
                              showDialog(
                                context: context,
                                builder: (_) => NoSkillDialog(),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ConfirmSwapScreen(swap: swap),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: StadiumBorder(),
                            padding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Request Swap',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'design': return Icons.brush_rounded;
      case 'coding': return Icons.code_rounded;
      case 'ai': return Icons.auto_awesome_rounded;
      case 'music': return Icons.music_note_rounded;
      case 'drawing': return Icons.draw_rounded;
      case 'photos': return Icons.camera_alt_rounded;
      case 'data analysis': return Icons.bar_chart_rounded;
      default: return Icons.category_rounded;
    }
  }

  String _getPortfolioName(String url) {
    if (url.isEmpty) return '';
    final uri = Uri.tryParse(url);
    if (uri == null || uri.pathSegments.isEmpty) {
      return url;
    }

    String lastSegment = uri.pathSegments.last;
    try {
      lastSegment = Uri.decodeComponent(lastSegment);
    } catch (_) {}

    if (lastSegment.isEmpty && uri.pathSegments.length > 1) {
      lastSegment = uri.pathSegments[uri.pathSegments.length - 2];
      try {
        lastSegment = Uri.decodeComponent(lastSegment);
      } catch (_) {}
    }

    final parts = lastSegment.split('_');
    if (parts.length > 1 && RegExp(r'^\d+$').hasMatch(parts[0])) {
      return parts.sublist(1).join('_');
    }

    if (!lastSegment.contains('.')) {
      if (uri.host.isNotEmpty) {
        String hostAndPath = uri.host + uri.path;
        if (hostAndPath.endsWith('/')) {
          hostAndPath = hostAndPath.substring(0, hostAndPath.length - 1);
        }
        return hostAndPath;
      }
    }

    return lastSegment.isNotEmpty ? lastSegment : url;
  }

  void _viewImage(BuildContext context, String imageUrl, String fileName) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.transparent,
                  child: InteractiveViewer(
                    panEnabled: true,
                    boundaryMargin: EdgeInsets.all(20),
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.broken_image_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), size: 64),
                              SizedBox(height: 12),
                              Text(
                                'Failed to load image',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        fileName,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 16),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.onSurface, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openPortfolio(BuildContext context, String url) async {
    if (url.isEmpty) return;

    final fileName = _getPortfolioName(url);
    final isImage = url.toLowerCase().contains(RegExp(r'\.(jpg|jpeg|png|webp|gif|bmp)'));

    if (isImage) {
      _viewImage(context, url, fileName);
      return;
    }

    final Uri uri = Uri.parse(url);
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening $fileName...'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: Duration(seconds: 2),
        ),
      );

      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch URL';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open document: $e'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
// DETAIL ROW WIDGET (unchanged)
// ─────────────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isText;
  final IconData? icon;
  final bool isHighlight;
  final bool isLink;
  final VoidCallback? onTap;

  _DetailRow({
    required this.label,
    required this.value,
    this.isText = true,
    this.icon,
    this.isHighlight = false,
    this.isLink = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 13),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 14),
                  SizedBox(width: 6),
                ],
                Flexible(
                  child: GestureDetector(
                    onTap: isLink ? onTap : null,
                    child: Text(
                      value,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: isHighlight
                            ? Theme.of(context).colorScheme.primary
                            : isLink
                            ? Color(0xFF6B8AFF)
                            : Theme.of(context).colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        decoration: isLink ? TextDecoration.underline : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.07), height: 1);
  }
}
