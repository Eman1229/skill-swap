import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skill_swap/screens/Home%20Screens/swapping%20Available.dart';

class EditProfileScreen extends StatefulWidget {
  final SwapListing swap;

  EditProfileScreen({super.key, required this.swap});

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
    _emailController =
        TextEditingController(text: _auth.currentUser?.email ?? '');
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

      await _supabase.storage
          .from('profile-images')
          .upload(
        fileName,
        imageFile,
        fileOptions: FileOptions(upsert: true),
      );

      final String publicUrl = _supabase.storage
          .from('profile-images')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image upload failed: $e'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
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

      // Update in Firebase Auth
      if (_auth.currentUser != null) {
        await _auth.currentUser!.updateDisplayName(newName);
        if (imageUrl != null) {
          await _auth.currentUser!.updatePhotoURL(imageUrl);
        }
      }

      // Update all user's listings in swapListings collection
      if (uid != null) {
        final listingsQuery = await _db
            .collection('swapListings')
            .where('userId', isEqualTo: uid)
            .get();

        final batch = _db.batch();
        for (final doc in listingsQuery.docs) {
          batch.update(doc.reference, {
            'name': newName,
            'imageUrl': imageUrl,
          });
        }
        await batch.commit();
      } else {
        // Fallback for single document
        await _db.collection('swapListings').doc(widget.swap.id).update({
          'name': newName,
          'imageUrl': imageUrl,
        });
      }

      await _db
          .collection('swapListings')
          .doc(widget.swap.id)
          .get(GetOptions(source: Source.server));

      final currentEmail = _auth.currentUser?.email;
      final newEmail = _emailController.text.trim();

      if (newEmail.isNotEmpty && newEmail != currentEmail) {
        try {
          await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Email update requires recent login. Please sign out and sign in again.',
                ),
              ),
            );
          }
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully ✓'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Edit Profile',
          style:
          TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isSaving)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveChanges,
              child: Text(
                'SAVE',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            // ── Avatar Edit ──
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withAlpha(51),
                        width: 3,
                      ),
                      image: _newImage != null
                          ? DecorationImage(
                        image: FileImage(_newImage!),
                        fit: BoxFit.cover,
                      )
                          : (widget.swap.imageUrl != null
                          ? DecorationImage(
                        image: NetworkImage(
                            widget.swap.imageUrl!),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      )
                          : null),
                    ),
                    child:
                    _newImage == null && widget.swap.imageUrl == null
                        ? Center(
                      child: Text(
                        widget.swap.initials,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 40),

            _buildEditField(
              label: 'FULL NAME',
              controller: _nameController,
              icon: Icons.person_outline_rounded,
            ),
            SizedBox(height: 24),
            _buildEditField(
              label: 'EMAIL ADDRESS',
              controller: _emailController,
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
            ),

            SizedBox(height: 32),
            Text(
              'Your profile information is visible to other swappers so they can identify and connect with you.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withAlpha(13)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15),
            decoration: InputDecoration(
              prefixIcon:
              Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}