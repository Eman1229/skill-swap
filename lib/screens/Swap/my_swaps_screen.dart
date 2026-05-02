import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/screens/Home%20Screens/swapping%20Available.dart';
import 'package:skill_swap/screens/Profile/profile%20screen.dart';

class MySwapsScreen extends StatefulWidget {
  const MySwapsScreen({Key? key}) : super(key: key);

  @override
  State<MySwapsScreen> createState() => _MySwapsScreenState();
}

class _MySwapsScreenState extends State<MySwapsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Swaps',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: uid == null
          ? const Center(child: Text('Please login', style: TextStyle(color: Colors.white)))
          : StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('conversations')
                  .where('participants', arrayContains: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF00C2FF)));
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _SwapSessionCard(data: data);
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swap_horiz_rounded, color: Colors.white.withOpacity(0.1), size: 100),
          const SizedBox(height: 20),
          const Text('No active swaps yet',
              style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('Start a conversation to initiate a swap!',
              style: TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }
}

class _SwapSessionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _SwapSessionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final otherName = data['otherName'] ?? 'Mentor';
    final skill = data['skill'] ?? 'Skill';
    final progress = (data['progress'] as num?)?.toDouble() ?? 0.35; // Mock progress if not set
    final status = data['status'] ?? 'In Progress';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00C2FF).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF6B8AFF),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(otherName[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(otherName,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(skill, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C2FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(status,
                    style: const TextStyle(
                        color: Color(0xFF00C2FF), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Session Progress',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
              Text('${(progress * 100).toInt()}%',
                  style: const TextStyle(
                      color: Color(0xFF00C2FF), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.05),
              color: const Color(0xFF00C2FF),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, color: Colors.white38, size: 14),
              const SizedBox(width: 6),
              const Text('Next Session: tomorrow, 10:00 AM',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
              const Spacer(),
              _ActionBtn(label: 'Enter Session', onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF00C2FF), Color(0xFF6B8AFF)]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
