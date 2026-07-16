import 'package:provider/provider.dart';
import 'package:skill_swap/providers/language_provider.dart';
import 'package:skill_swap/ui_helper/translation_helper.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skill_swap/screens/Home%20Screens/swapping%20Available.dart';

class EditProfileScreen extends StatefulWidget {
  final SwapListing swap;

  const EditProfileScreen({super.key, required this.swap});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _supabase = Supabase.instance.client;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  File? _newImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.swap.name);
    _emailController = TextEditingController(text: _auth.currentUser?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _newImage = File(picked.path));
    }
  }

  Future<String?> _uploadImageToSupabase(File imageFile) async {
    try {
      final String fileName =
          'profile_${widget.swap.userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage.from('profile-images').upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(upsert: true),
      );

      return _supabase.storage.from('profile-images').getPublicUrl(fileName);
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);

    try {
      String? imageUrl = widget.swap.imageUrl;
      if (_newImage != null) {
        final uploadedUrl = await _uploadImageToSupabase(_newImage!);
        if (uploadedUrl != null) {
          if (imageUrl != null && imageUrl.isNotEmpty) {
            await NetworkImage(imageUrl).evict();
          }
          imageUrl = uploadedUrl;
        }
      }

      final uid = _auth.currentUser?.uid;
      final newName = _nameController.text.trim();

      if (_auth.currentUser != null) {
        await _auth.currentUser!.updateDisplayName(newName);
        if (imageUrl != null) {
          await _auth.currentUser!.updatePhotoURL(imageUrl);
        }
      }

      final updateData = {
        'name': newName,
        'imageUrl': imageUrl,
      };

      if (uid != null) {
        final listingsQuery = await _db
            .collection('swapListings')
            .where('userId', isEqualTo: uid)
            .get();

        final batch = _db.batch();
        for (final doc in listingsQuery.docs) {
          batch.update(doc.reference, updateData);
        }
        await batch.commit();
      }

      final newEmail = _emailController.text.trim();
      if (newEmail.isNotEmpty && newEmail != _auth.currentUser?.email) {
        await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile_updated_success'.tr()),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${'error'.tr()}: $e"), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Edit Profile',
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isSaving)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
              ),
            )
          else
            TextButton(
              onPressed: _saveChanges,
              child: Text('save'.tr(),
                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ── Avatar Edit ──
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 110, height: 110,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 3),
                      image: _newImage != null
                          ? DecorationImage(image: FileImage(_newImage!), fit: BoxFit.cover)
                          : (widget.swap.imageUrl != null
                          ? DecorationImage(image: NetworkImage(widget.swap.imageUrl!), fit: BoxFit.cover)
                          : null),
                    ),
                    child: _newImage == null && widget.swap.imageUrl == null
                        ? Center(
                      child: Text(
                        widget.swap.initials,
                        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    )
                        : null,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                        child: Icon(Icons.camera_alt_rounded, color: theme.colorScheme.onSurface, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            _buildSectionTitle('ACCOUNT INFORMATION'),
            const SizedBox(height: 16),
            _buildEditField(
              label: 'FULL NAME',
              controller: _nameController,
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 20),
            _buildEditField(
              label: 'EMAIL ADDRESS',
              controller: _emailController,
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 40),
            Text(
              'Your profile information is visible to other swappers so they can identify and connect with you.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.65), fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4), fontSize: 13),
              prefixIcon: Icon(icon, color: theme.colorScheme.primary.withValues(alpha: 0.65), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
