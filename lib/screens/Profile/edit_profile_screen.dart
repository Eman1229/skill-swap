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
  final _supabase = Supabase.instance.client; // ✅ Supabase client

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

  // ✅ Upload to Supabase Storage instead of Firebase Storage
  Future<String?> _uploadImageToSupabase(File imageFile) async {
    try {
      final String fileName =
          'profile_${widget.swap.userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage
          .from('profile-images') // ← your bucket name
          .upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(upsert: true),
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
            backgroundColor: const Color(0xFFEF4444),
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

      // 1. Upload image to Supabase if changed
      if (_newImage != null) {
        final uploadedUrl = await _uploadImageToSupabase(_newImage!);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      }

      // 2. Update Firestore listing
      await _db.collection('swapListings').doc(widget.swap.id).update({
        'name': _nameController.text.trim(),
        if (imageUrl != null) 'imageUrl': imageUrl,
      });

      // 3. Update email if changed
      if (_emailController.text.trim() != _auth.currentUser?.email) {
        try {
          await _auth.currentUser
              ?.verifyBeforeUpdateEmail(_emailController.text.trim());
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Email update requires recent login. Please sign out and in again.'),
              ),
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully ✓'),
            backgroundColor: Color(0xFF00C2FF),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveChanges,
              child: const Text(
                'SAVE',
                style: TextStyle(
                  color: Color(0xFF00C2FF),
                  fontWeight: FontWeight.bold,
                ),
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
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF00C2FF).withAlpha(51),
                        width: 3,
                      ),
                      image: _newImage != null
                          ? DecorationImage(
                        image: FileImage(_newImage!),
                        fit: BoxFit.cover,
                      )
                          : (widget.swap.imageUrl != null
                          ? DecorationImage(
                        image: NetworkImage(widget.swap.imageUrl!),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      )
                          : null),
                    ),
                    child: _newImage == null && widget.swap.imageUrl == null
                        ? Center(
                      child: Text(
                        widget.swap.initials,
                        style: const TextStyle(
                          color: Colors.white,
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
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00C2FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            _buildEditField(
              label: 'FULL NAME',
              controller: _nameController,
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 24),
            _buildEditField(
              label: 'EMAIL ADDRESS',
              controller: _emailController,
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 32),
            const Text(
              'Your profile information is visible to other swappers so they can identify and connect with you.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12),
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
          style: const TextStyle(
            color: Color(0xFF00C2FF),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(13)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.white38, size: 20),
              border: InputBorder.none,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}