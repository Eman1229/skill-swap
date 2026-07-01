import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skill_swap/models/swap_model.dart';

class CertificateScreen extends StatelessWidget {
  final SwapModel swap;

  const CertificateScreen({Key? key, required this.swap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final completedDate = swap.completedAt ?? DateTime.now();
    final dateStr = DateFormat('MMMM dd, yyyy').format(completedDate);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Certificate',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            // Certificate Container
            AspectRatio(
              aspectRatio: 0.72,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 6), // Gold Border
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header Badge
                      Icon(Icons.stars_rounded, color: const Color(0xFFD4AF37), size: 50),
                      const SizedBox(height: 16),

                      // Certificate Title
                      const Text(
                        'Certificate of Completion',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Serif',
                          color: Color(0xFF1E293B),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Sub-title
                      Text(
                        'This is to certify that',
                        style: TextStyle(
                          fontFamily: 'Serif',
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Names
                      Text(
                        '${swap.mentorName} & ${swap.learnerName}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Serif',
                          color: Color(0xFF0F172A),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Explanation
                      Text(
                        'have successfully completed the swap for',
                        style: TextStyle(
                          fontFamily: 'Serif',
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Skill Title
                      Text(
                        swap.skillName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Serif',
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Footer with Seal and Date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  fontFamily: 'Serif',
                                  color: Color(0xFF1E293B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(width: 80, height: 1, color: Colors.grey[400]),
                              const SizedBox(height: 4),
                              Text(
                                'Date',
                                style: TextStyle(color: Colors.grey[500], fontSize: 9),
                              ),
                            ],
                          ),
                          // Seal
                          Image.network(
                            'https://cdn-icons-png.flaticon.com/512/3135/3135768.png',
                            width: 50,
                            height: 50,
                            color: const Color(0xFFD4AF37),
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.verified_user_rounded,
                              color: const Color(0xFFD4AF37),
                              size: 44,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'SKILL SWAP',
                                style: TextStyle(
                                  fontFamily: 'Serif',
                                  color: Color(0xFF1E293B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(width: 80, height: 1, color: Colors.grey[400]),
                              const SizedBox(height: 4),
                              Text(
                                'Authorized Sign',
                                style: TextStyle(color: Colors.grey[500], fontSize: 9),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ) == null
                      ? Container()
                      : Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TextButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Downloading certificate...')),
                              );
                            },
                            icon: const Icon(Icons.download_rounded, color: Colors.white),
                            label: const Text(
                              'Download',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.primary),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sharing certificate...')),
                        );
                      },
                      icon: Icon(Icons.share_rounded, color: Theme.of(context).colorScheme.primary),
                      label: Text(
                        'Share',
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
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
