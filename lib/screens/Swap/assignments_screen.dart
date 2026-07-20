import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:skill_swap/models/swap_model.dart';
import 'package:skill_swap/models/assignment_model.dart';
import 'package:skill_swap/models/submission_model.dart';
import 'package:skill_swap/screens/Swap/create_assignment_screen.dart';
import 'package:skill_swap/services/notification_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AssignmentsScreen extends StatefulWidget {
  final SwapModel swap;
  const AssignmentsScreen({Key? key, required this.swap}) : super(key: key);

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool get _isMentor => _auth.currentUser?.uid == widget.swap.mentorId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Assignments - ${widget.swap.skillName}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('swaps')
            .doc(widget.swap.id)
            .collection('assignments')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final assignment = AssignmentModel.fromDoc(docs[index]);
              return _AssignmentTile(
                assignment: assignment,
                swap: widget.swap,
                isMentor: _isMentor,
              );
            },
          );
        },
      ),
      floatingActionButton: _isMentor
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateAssignmentScreen(
                      swapId: widget.swap.id,
                      learnerId: widget.swap.learnerId,
                      mentorName: widget.swap.mentorName,
                      skillName: widget.swap.skillName,
                    ),
                  ),
                );
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Assignment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Course Assignments Yet',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isMentor
                ? 'Create assignments to assign tasks to your learner.'
                : 'Assignments published by your mentor will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentTile extends StatelessWidget {
  final AssignmentModel assignment;
  final SwapModel swap;
  final bool isMentor;

  const _AssignmentTile({
    required this.assignment,
    required this.swap,
    required this.isMentor,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMM dd, yyyy').format(assignment.dueDate);
    final FirebaseFirestore db = FirebaseFirestore.instance;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.title,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Due: $formattedDate',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${assignment.xp} XP',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            assignment.description,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          // Submissions / Grading State stream
          StreamBuilder<QuerySnapshot>(
            stream: db
                .collection('swaps')
                .doc(swap.id)
                .collection('assignments')
                .doc(assignment.id)
                .collection('submissions')
                .snapshots(),
            builder: (context, snapshot) {
              final submissions = snapshot.data?.docs ?? [];
              if (isMentor) {
                // Mentor sees submission count and list
                if (submissions.isEmpty) {
                  return const Row(
                    children: [
                      Icon(Icons.pending_actions_rounded, color: Colors.orangeAccent, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Awaiting Submission',
                        style: TextStyle(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                }
                final sub = SubmissionModel.fromDoc(submissions.first);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          sub.status == 'graded' ? Icons.check_circle_rounded : Icons.mark_as_unread_rounded,
                          color: sub.status == 'graded' ? Colors.green : Colors.blueAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          sub.status == 'graded' ? 'Graded (${sub.grade})' : 'Submitted (Review Required)',
                          style: TextStyle(
                            color: sub.status == 'graded' ? Colors.green : Colors.blueAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => _openReviewDialog(context, sub),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Text(sub.status == 'graded' ? 'View Details' : 'Grade Submission'),
                    ),
                  ],
                );
              } else {
                // Learner status
                if (submissions.isEmpty) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Not Submitted Yet',
                        style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      ElevatedButton(
                        onPressed: () => _openSubmitDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text('Submit Homework'),
                      ),
                    ],
                  );
                }

                final sub = SubmissionModel.fromDoc(submissions.first);
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            sub.status == 'graded' ? Icons.verified : Icons.query_builder,
                            color: sub.status == 'graded' ? Colors.green : Colors.orangeAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            sub.status == 'graded' ? 'Graded: ${sub.grade}' : 'Submitted (Pending Review)',
                            style: TextStyle(
                              color: sub.status == 'graded' ? Colors.green : Colors.orangeAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (sub.feedback.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Feedback: ${sub.feedback}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _openSubmitDialog(BuildContext context) {
    final textController = TextEditingController();
    PlatformFile? selectedFile;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickFile() async {
              final result = await FilePicker.platform.pickFiles(withData: true);
              if (result != null && result.files.isNotEmpty) {
                setDialogState(() => selectedFile = result.files.single);
              }
            }

            Future<void> submit() async {
              if (textController.text.trim().isEmpty && selectedFile == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please add text feedback or upload a file.')),
                );
                return;
              }

              setDialogState(() => isUploading = true);
              try {
                String fileUrl = '';
                String fileName = '';

                if (selectedFile != null && selectedFile!.bytes != null) {
                  final safeName = selectedFile!.name.replaceAll(RegExp(r'[^\w.\-]+'), '_');
                  final filePath = 'submissions/${swap.id}/${assignment.id}_$safeName';
                  final supabase = Supabase.instance.client;
                  
                  await supabase.storage.from('learning-assets').uploadBinary(
                    filePath,
                    selectedFile!.bytes!,
                    fileOptions: const FileOptions(contentType: 'application/octet-stream'),
                  );
                  fileUrl = supabase.storage.from('learning-assets').getPublicUrl(filePath);
                  fileName = selectedFile!.name;
                }

                final submissionRef = FirebaseFirestore.instance
                    .collection('swaps')
                    .doc(swap.id)
                    .collection('assignments')
                    .doc(assignment.id)
                    .collection('submissions')
                    .doc();

                await submissionRef.set({
                  'submissionId': submissionRef.id,
                  'assignmentId': assignment.id,
                  'learnerId': swap.learnerId,
                  'learnerName': swap.learnerName,
                  'fileUrl': fileUrl,
                  'fileName': fileName,
                  'submissionText': textController.text.trim(),
                  'submittedAt': FieldValue.serverTimestamp(),
                  'feedback': '',
                  'grade': '',
                  'status': 'pending',
                });

                // Notify mentor
                await NotificationService().sendNotification(
                  receiverId: swap.mentorId,
                  type: 'assignment',
                  title: 'New Assignment Submission',
                  body: '${swap.learnerName} submitted homework for "${assignment.title}".',
                  actionRoute: '/skill_detail',
                  actionId: swap.id,
                  data: {
                    'swapId': swap.id,
                    'assignmentId': assignment.id,
                    'type': 'assignment_submitted',
                  },
                );

                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Homework submitted successfully!'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                setDialogState(() => isUploading = false);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Submission failed: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            }

            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text('Submit Assignment', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    maxLines: 3,
                    enabled: !isUploading,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: const InputDecoration(
                      labelText: 'Comments / Written Answer',
                      hintText: 'Enter your message here...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: isUploading ? null : pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: Text(selectedFile?.name ?? 'Attach File (optional)'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isUploading ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isUploading ? null : submit,
                  child: isUploading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openReviewDialog(BuildContext context, SubmissionModel submission) {
    final gradeController = TextEditingController(text: submission.grade);
    final feedbackController = TextEditingController(text: submission.feedback);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> saveGrade() async {
              if (gradeController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a grade.')),
                );
                return;
              }

              setDialogState(() => isSaving = true);
              try {
                final submissionRef = FirebaseFirestore.instance
                    .collection('swaps')
                    .doc(swap.id)
                    .collection('assignments')
                    .doc(assignment.id)
                    .collection('submissions')
                    .doc(submission.id);

                await submissionRef.update({
                  'grade': gradeController.text.trim(),
                  'feedback': feedbackController.text.trim(),
                  'status': 'graded',
                });

                // Award XP to learner activities list
                final activityId = 'assignment_graded_${swap.id}_${assignment.id}';
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(swap.learnerId)
                    .collection('activities')
                    .doc(activityId)
                    .set({
                  'type': 'assignment_completed',
                  'role': 'learner',
                  'timestamp': FieldValue.serverTimestamp(),
                  'xp': assignment.xp,
                  'skillName': swap.skillName,
                  'swapId': swap.id,
                  'details': 'Passed assignment: ${assignment.title}',
                  'createdAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                // Send notification
                await NotificationService().sendNotification(
                  receiverId: swap.learnerId,
                  type: 'assignment',
                  title: 'Assignment Graded!',
                  body: '${swap.mentorName} graded "${assignment.title}": ${gradeController.text.trim()}.',
                  actionRoute: '/skill_detail',
                  actionId: swap.id,
                  data: {
                    'swapId': swap.id,
                    'assignmentId': assignment.id,
                    'type': 'assignment_graded',
                  },
                );

                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Submission graded successfully!'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                setDialogState(() => isSaving = false);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Grading failed: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            }

            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: const Text('Review Homework Submission'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Submitted By: ${submission.learnerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (submission.submissionText.isNotEmpty) ...[
                      const Text('Written Answer:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(submission.submissionText),
                      const SizedBox(height: 12),
                    ],
                    if (submission.fileUrl.isNotEmpty) ...[
                      const Text('Attached File:', style: TextStyle(fontWeight: FontWeight.w600)),
                      InkWell(
                        onTap: () async {
                          final uri = Uri.tryParse(submission.fileUrl);
                          if (uri != null) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Text(
                          submission.fileName,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Divider(),
                    const SizedBox(height: 8),
                    TextField(
                      controller: gradeController,
                      enabled: !isSaving,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: const InputDecoration(
                        labelText: 'Grade / Status (e.g. A+, Passed)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: feedbackController,
                      maxLines: 3,
                      enabled: !isSaving,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: const InputDecoration(
                        labelText: 'Feedback Comments',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : saveGrade,
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Submit Grade'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
