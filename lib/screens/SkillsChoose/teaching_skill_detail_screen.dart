import 'package:provider/provider.dart';
import 'package:skill_swap/providers/language_provider.dart';
import 'package:skill_swap/ui_helper/translation_helper.dart';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

enum AssetType { pdf, video, link }

class CourseAsset {
  final String id;
  final String title;
  final String url;
  final AssetType type;

  final String? size;

  CourseAsset({
    required this.id,
    required this.title,
    required this.url,
    required this.type,
    this.size,
  });

  factory CourseAsset.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CourseAsset(
      id: doc.id,
      title: data['title'] ?? '',
      url: data['url'] ?? '',
      type: AssetType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => AssetType.link,
      ),
      size: data['size'],
    );
  }
}

class TeachingSkillDetailScreen extends StatefulWidget {
  final bool isTeacher; // Determines if the user is the teacher or learner
  final String skillId; // Unique identifier for the skill in Firestore
  final String skillTitle;
  final String skillDescription;

  const TeachingSkillDetailScreen({
    super.key,
    required this.isTeacher,
    required this.skillId,
    required this.skillTitle,
    required this.skillDescription,
  });

  @override
  State<TeachingSkillDetailScreen> createState() =>
      _TeachingSkillDetailScreenState();
}

class _TeachingSkillDetailScreenState extends State<TeachingSkillDetailScreen> {
  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'skill_detail_title'.tr(),
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skill Info Section
            Text(
              widget.skillTitle,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.skillDescription,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),

            // Course Assets Section Header
            _buildSectionHeader(context),
            const SizedBox(height: 16),

            // Assets List
            _buildAssetsList(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'course_assets'.tr().toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 2,
                width: 24,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (widget.isTeacher)
          TextButton.icon(
            onPressed: _onAddMaterial,
            icon: Icon(
              Icons.add_circle_outline_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: Text(
              'add_material'.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAssetsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('skills')
          .doc(widget.skillId)
          .collection('assets')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('error_loading_assets'.tr()));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'no_materials_available'.tr(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }

        final assets = snapshot.data!.docs
            .map((doc) => CourseAsset.fromFirestore(doc))
            .toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: assets.length,
          itemBuilder: (context, index) {
            return _buildAssetCard(assets[index]);
          },
        );
      },
    );
  }

  Widget _buildAssetCard(CourseAsset asset) {
    IconData mainIcon;
    IconData actionIcon;
    Color iconColor;

    switch (asset.type) {
      case AssetType.pdf:
        mainIcon = Icons.picture_as_pdf_rounded;
        actionIcon = Icons.download_rounded;
        iconColor = const Color(0xFFFF4B4B);
        break;
      case AssetType.video:
        mainIcon = Icons.play_circle_fill_rounded;
        actionIcon = Icons.play_arrow_rounded;
        iconColor = const Color(0xFF4B84FF);
        break;
      case AssetType.link:
        mainIcon = Icons.link_rounded;
        actionIcon = Icons.open_in_new_rounded;
        iconColor = const Color(0xFF2ECC71);
        break;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Theme.of(context).colorScheme.onSurface.withAlpha(10)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(mainIcon, color: iconColor, size: 20),
        ),
        title: Text(
          asset.title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: asset.size != null
            ? Text(
                asset.size!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                actionIcon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              onPressed: () => _handleAssetAction(asset),
            ),
            if (widget.isTeacher)
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: Theme.of(context).colorScheme.error.withOpacity(0.7),
                  size: 18,
                ),
                onPressed: () => _deleteAsset(asset),
              ),
          ],
        ),
        onTap: () => _handleAssetAction(asset),
      ),
    );
  }

  Future<void> _handleAssetAction(CourseAsset asset) async {
    final Uri url = Uri.parse(asset.url);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _deleteAsset(CourseAsset asset) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_material'.tr()),
        content: Text('confirm_delete_asset'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('delete'.tr(),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('skills')
          .doc(widget.skillId)
          .collection('assets')
          .doc(asset.id)
          .delete();
    }
  }

  void _onAddMaterial() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddMaterialSheet(),
    );
  }

  Widget _buildAddMaterialSheet() {
    String title = '';
    String url = '';
    AssetType selectedType = AssetType.pdf;
    bool isUploading = false;

    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'add_new_resource'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'asset_title'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (val) => title = val,
                ),
                const SizedBox(height: 16),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SegmentedButton<AssetType>(
                    segments: [
                      ButtonSegment(
                        value: AssetType.pdf,
                        label: Text('PDF'),
                        icon: Icon(Icons.picture_as_pdf),
                      ),
                      ButtonSegment(
                        value: AssetType.video,
                        label: Text('video'.tr()),
                        icon: Icon(Icons.movie),
                      ),
                      ButtonSegment(
                        value: AssetType.link,
                        label: Text('link'.tr()),
                        icon: Icon(Icons.link),
                      ),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (set) =>
                        setSheetState(() => selectedType = set.first),
                  ),
                ),
                const SizedBox(height: 16),
                if (selectedType == AssetType.link)
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'URL',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (val) => url = val,
                  )
                else
                  ElevatedButton.icon(
                    onPressed: isUploading
                        ? null
                        : () async {
                            FilePickerResult? result = await FilePicker.platform
                                .pickFiles(
                                  type: selectedType == AssetType.pdf
                                      ? FileType.custom
                                      : FileType.video,
                                  allowedExtensions: selectedType == AssetType.pdf
                                      ? ['pdf']
                                      : null,
                                );

                            if (result != null) {
                              setSheetState(() => isUploading = true);
                              try {
                                File file = File(result.files.single.path!);
                                String fileName =
                                    '${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}';
                                Reference ref = FirebaseStorage.instance
                                    .ref()
                                    .child(
                                      'skill_assets/${widget.skillId}/$fileName',
                                    );

                                UploadTask uploadTask = ref.putFile(file);
                                TaskSnapshot snapshot = await uploadTask;
                                String downloadUrl = await snapshot.ref
                                    .getDownloadURL();

                                url = downloadUrl;
                                String size = _formatBytes(
                                  result.files.single.size,
                                );

                                await FirebaseFirestore.instance
                                    .collection('skills')
                                    .doc(widget.skillId)
                                    .collection('assets')
                                    .add({
                                      'title': title.isEmpty
                                          ? result.files.single.name
                                          : title,
                                      'url': url,
                                      'type': selectedType.name,
                                      'size': size,
                                      'createdAt': FieldValue.serverTimestamp(),
                                    });

                                if (mounted) Navigator.pop(context);
                              } catch (e) {
                                debugPrint(e.toString());
                              } finally {
                                setSheetState(() => isUploading = false);
                              }
                            }
                          },
                    icon: isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file),
                    label: Text(
                      isUploading ? 'uploading'.tr() : 'select_and_upload'.tr(),
                    ),
                  ),
                const SizedBox(height: 16),
                if (selectedType == AssetType.link)
                  ElevatedButton(
                    onPressed: isUploading || title.isEmpty || url.isEmpty
                        ? null
                        : () async {
                            await FirebaseFirestore.instance
                                .collection('skills')
                                .doc(widget.skillId)
                                .collection('assets')
                                .add({
                                  'title': title,
                                  'url': url,
                                  'type': selectedType.name,
                                  'createdAt': FieldValue.serverTimestamp(),
                                });
                            Navigator.pop(context);
                          },
                    child: Text('save'.tr()),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (log(bytes) / log(1024)).floor();
    return ((bytes / pow(1024, i)).toStringAsFixed(2)) + ' ' + suffixes[i];
  }
}
