import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skill_swap/models/learning_asset.dart';
import 'package:skill_swap/models/swap_model.dart';
import 'package:skill_swap/services/learning_assets_service.dart';
import 'package:skill_swap/utils/user_display_name.dart';
import 'package:url_launcher/url_launcher.dart';

class CourseAssetsScreen extends StatelessWidget {
  final String courseId;
  final String? highlightedAssetId;
  final SwapModel? initialCourse;

  const CourseAssetsScreen({
    super.key,
    required this.courseId,
    this.highlightedAssetId,
    this.initialCourse,
  });

  @override
  Widget build(BuildContext context) {
    if (initialCourse != null) {
      return _CourseAssetsScaffold(
        course: initialCourse!,
        highlightedAssetId: highlightedAssetId,
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('swaps')
          .doc(courseId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(backgroundColor: Colors.transparent),
            body: Center(
              child: Text(
                'Course not found.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          );
        }
        return _CourseAssetsScaffold(
          course: SwapModel.fromDoc(snapshot.data!),
          highlightedAssetId: highlightedAssetId,
        );
      },
    );
  }
}

class _CourseAssetsScaffold extends StatelessWidget {
  final SwapModel course;
  final String? highlightedAssetId;

  const _CourseAssetsScaffold({required this.course, this.highlightedAssetId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Course Assets',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: CourseAssetsSection(
          course: course,
          highlightedAssetId: highlightedAssetId,
        ),
      ),
    );
  }
}

class CourseAssetsSection extends StatefulWidget {
  final SwapModel course;
  final String? highlightedAssetId;

  const CourseAssetsSection({
    super.key,
    required this.course,
    this.highlightedAssetId,
  });

  @override
  State<CourseAssetsSection> createState() => _CourseAssetsSectionState();
}

class _CourseAssetsSectionState extends State<CourseAssetsSection> {
  final LearningAssetsService _service = LearningAssetsService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool get _isTeacher => _auth.currentUser?.uid == widget.course.mentorId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Course Assets',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_isTeacher &&
                  widget.course.status != 'completed' &&
                  widget.course.status != 'Waiting for Learner Confirmation')
                TextButton.icon(
                  onPressed: _showUploadDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Material'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<LearningAsset>>(
            stream: _service.watchCourseAssets(widget.course.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              }

              final assets = snapshot.data ?? [];
              if (assets.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    _isTeacher
                        ? 'Upload files for your learner here.'
                        : 'No learning assets have been uploaded yet.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: assets.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final asset = assets[index];
                  return _AssetCard(
                    asset: asset,
                    highlighted: asset.id == widget.highlightedAssetId,
                    canManage:
                        _isTeacher &&
                        asset.teacherId == _auth.currentUser?.uid &&
                        widget.course.status != 'completed' &&
                        widget.course.status != 'Waiting for Learner Confirmation',
                    onOpen: () => _openAsset(asset),
                    onEdit: () => _showRenameDialog(asset),
                    onDelete: () => _confirmDelete(asset),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showUploadDialog() async {
    final titleController = TextEditingController();
    final courseController = TextEditingController(
      text: widget.course.skillName,
    );
    PlatformFile? selectedFile;
    var uploading = false;

    await showDialog(
      context: context,
      barrierDismissible: !uploading,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickFile() async {
              final result = await FilePicker.platform.pickFiles(
                withData: true,
                type: FileType.custom,
                allowedExtensions: const [
                  'pdf',
                  'doc',
                  'docx',
                  'ppt',
                  'pptx',
                  'png',
                  'jpg',
                  'jpeg',
                  'webp',
                  'txt',
                  'mp4',
                  'zip',
                ],
              );
              if (result != null && result.files.isNotEmpty) {
                setDialogState(() => selectedFile = result.files.single);
              }
            }

            Future<void> upload() async {
              final file = selectedFile;
              final title = titleController.text.trim();
              if (title.isEmpty || file == null || file.bytes == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a title and choose a file.'),
                  ),
                );
                return;
              }

              setDialogState(() => uploading = true);
              try {
                final uid = _auth.currentUser?.uid ?? '';
                final teacherName = await UserDisplayName.resolve(
                  _db,
                  uid,
                  fallback: UserDisplayName.isUsable(widget.course.mentorName)
                      ? widget.course.mentorName
                      : 'Teacher',
                  authDisplayName: _auth.currentUser?.displayName,
                );

                await _service.uploadAsset(
                  course: widget.course,
                  teacherId: uid,
                  teacherName: teacherName,
                  documentTitle: title,
                  fileName: file.name,
                  fileType: _extension(file.name),
                  fileBytes: file.bytes!,
                );

                if (mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Asset uploaded.')),
                  );
                }
              } catch (e) {
                setDialogState(() => uploading = false);
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
                }
              }
            }

            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text(
                'Add Learning Asset',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    enabled: !uploading,
                    decoration: const InputDecoration(
                      labelText: 'Document Title',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: courseController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Related Skill/Course Name',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: uploading ? null : pickFile,
                    icon: const Icon(Icons.attach_file_rounded),
                    label: Text(selectedFile?.name ?? 'Choose Document/File'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: uploading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: uploading ? null : upload,
                  child: uploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Upload'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showRenameDialog(LearningAsset asset) async {
    final controller = TextEditingController(text: asset.documentName);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Edit Asset',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Document Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              await _service.renameAsset(
                assetId: asset.id,
                documentName: controller.text,
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(LearningAsset asset) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Delete Asset?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          asset.documentName,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _service.deleteAsset(asset);
    }
  }

  Future<void> _openAsset(LearningAsset asset) async {
    final uri = Uri.tryParse(asset.fileUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _extension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot == -1 || dot == fileName.length - 1) return 'file';
    return fileName.substring(dot + 1).toLowerCase();
  }
}

class _AssetCard extends StatelessWidget {
  final LearningAsset asset;
  final bool highlighted;
  final bool canManage;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AssetCard({
    required this.asset,
    required this.highlighted,
    required this.canManage,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlighted
            ? primary.withOpacity(0.18)
            : Theme.of(context).scaffoldBackgroundColor.withOpacity(0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted ? primary : primary.withOpacity(0.12),
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(_iconFor(asset.fileType), color: primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.documentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'By ${asset.teacherName} • ${DateFormat('MMM d, h:mm a').format(asset.uploadedAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'View/Open',
            onPressed: onOpen,
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            color: primary,
          ),
          if (canManage)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
        ],
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.article_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'webp':
        return Icons.image_rounded;
      case 'mp4':
        return Icons.movie_rounded;
      case 'zip':
        return Icons.folder_zip_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }
}
