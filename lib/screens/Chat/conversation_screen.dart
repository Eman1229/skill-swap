import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/screens/Home Screens/swapping Available.dart';
import 'package:skill_swap/services/chat_user_service.dart';
import 'package:skill_swap/services/chat_repository.dart';
import 'package:skill_swap/screens/Chat/widgets/swap_request_card.dart';
import 'package:skill_swap/screens/Chat/widgets/session_invite_card.dart';
import 'package:skill_swap/services/fcm_service.dart';
import 'package:skill_swap/screens/widgets/report_user_dialog.dart';

class ConversationScreen extends StatefulWidget {
  final SwapListing swap;
  const ConversationScreen({Key? key, required this.swap}) : super(key: key);

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final ChatRepository _chatRepo = ChatRepository();
  final ChatUserService _chatUserService = ChatUserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _conversationId;
  Stream<List<QueryDocumentSnapshot>>? _messagesStream;
  Stream<ChatUserProfile>? _profileStream;

  // Pagination parameters
  int _limit = 20;
  bool _loadingMore = false;
  bool _shouldScrollToBottom = true;

  Timer? _typingTimer;
  bool _isTyping = false;
  bool _otherTyping = false;
  StreamSubscription? _typingSubscription;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _initConversation();
    // Listen for other user typing status
    _listenTypingStatus();
  }

  void _listenTypingStatus() {
    final convoId = _conversationId;
    final otherId = widget.swap.userId ?? '';
    if (convoId == null || convoId.isEmpty || otherId.isEmpty) return;

    _typingSubscription?.cancel();
    _typingSubscription = FirebaseFirestore.instance
        .collection('conversations')
        .doc(convoId)
        .snapshots()
        .listen((snap) {
      if (snap.exists) {
        final data = snap.data();
        final typingMap = data?['typing'] as Map? ?? {};
        final bool isOtherTyping = typingMap[otherId] == true;
        if (mounted && _otherTyping != isOtherTyping) {
          setState(() {
            _otherTyping = isOtherTyping;
          });
        }
      }
    });
  }

  void _onMessageChanged(String v) {
    if (v.trim().isEmpty) {
      if (_isTyping) {
        _setTypingStatus(false);
      }
      return;
    }

    if (!_isTyping) {
      _setTypingStatus(true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _setTypingStatus(false);
      }
    });
  }

  Future<void> _setTypingStatus(bool typing) async {
    final uid = _auth.currentUser?.uid;
    final convoId = _conversationId;
    if (uid == null || convoId == null || convoId.isEmpty) return;

    setState(() {
      _isTyping = typing;
    });

    try {
      await FirebaseFirestore.instance.collection('conversations').doc(convoId).set({
        'typing': {uid: typing},
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error setting typing status: $e");
    }
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final pos = _scrollController.position;
      
      // When scrolled near the top, load more messages
      if (pos.pixels <= 100 && !_loadingMore && _conversationId != null && _conversationId!.isNotEmpty) {
        _loadMoreMessages();
      }

      // If user scrolls near the bottom, enable auto-scroll for new messages
      if (pos.pixels >= pos.maxScrollExtent - 100) {
        _shouldScrollToBottom = true;
      } else {
        _shouldScrollToBottom = false;
      }
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_loadingMore || _conversationId == null || _conversationId!.isEmpty) return;
    
    setState(() {
      _loadingMore = true;
      _shouldScrollToBottom = false;
    });

    final double prevMaxScroll = _scrollController.position.maxScrollExtent;

    setState(() {
      _limit += 20;
    });
    _updateMessagesStream();

    // Give it a brief delay to build new widgets and then keep scrolling natural
    await Future.delayed(const Duration(milliseconds: 400));

    if (mounted) {
      setState(() {
        _loadingMore = false;
      });
      // Adjust scroll to keep user in place
      if (_scrollController.hasClients) {
        final double newMaxScroll = _scrollController.position.maxScrollExtent;
        final double delta = newMaxScroll - prevMaxScroll;
        if (delta > 0) {
          _scrollController.jumpTo(_scrollController.offset + delta);
        }
      }
    }
  }

  void _updateMessagesStream() {
    final convoId = _conversationId;
    if (convoId == null || convoId.isEmpty) return;

    // Mute foreground alerts for this active conversation
    FcmService().currentActiveConvoId = convoId;
    debugPrint("ConversationScreen: Muted foreground notifications for $convoId");

    // Listen for typing status once convoId is available
    _listenTypingStatus();

    setState(() {
      _messagesStream = FirebaseFirestore.instance
          .collection('conversations')
          .doc(convoId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(_limit)
          .snapshots()
          .map((snap) {
            final docs = snap.docs;
            // Mark incoming messages as read dynamically in background
            _markMessagesAsReadInStream(docs);
            // Reverse list to display chronological ascending order
            return docs.reversed.toList();
          });
    });
  }

  Future<void> _markMessagesAsReadInStream(List<QueryDocumentSnapshot> docs) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final batch = FirebaseFirestore.instance.batch();
    int count = 0;

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final senderId = data['senderId'] as String? ?? '';
      final status = data['status'] as String? ?? 'sent';

      if (senderId != uid && status != 'read') {
        batch.update(doc.reference, {'status': 'read'});
        count++;
      }
    }

    if (count > 0) {
      try {
        await batch.commit();
        debugPrint("Marked $count messages as read in conversation $_conversationId");
        _chatRepo.markAllAsRead(_conversationId!);
      } catch (e) {
        debugPrint("Error marking messages as read in stream: $e");
      }
    }
  }

  Future<void> _initConversation() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final otherId = widget.swap.userId ?? '';
    
    // Set up profile details stream for header in real-time
    setState(() {
      _profileStream = _chatUserService.getUserProfile(otherId);
    });

    // Step 1: Check if widget.swap.id is a valid conversationId!
    if (widget.swap.id.isNotEmpty && otherId.isNotEmpty) {
      final directDoc = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.swap.id)
          .get();
      if (directDoc.exists) {
        final participants = List<String>.from(directDoc.data()?['participants'] ?? []);
        if (participants.contains(uid) && participants.contains(otherId)) {
          setState(() {
            _conversationId = directDoc.id;
          });
          _updateMessagesStream();
          _chatRepo.markAllAsRead(directDoc.id);
          return;
        }
      }
    }

    // Step 2: Fall back to finding ANY conversation between these two users
    if (otherId.isNotEmpty) {
      final query = await FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: uid)
          .get();

      for (final doc in query.docs) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(otherId)) {
          setState(() {
            _conversationId = doc.id;
          });
          _updateMessagesStream();
          _chatRepo.markAllAsRead(doc.id);
          return;
        }
      }
    }

    setState(() {
      _conversationId = '';
    });
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final otherId = widget.swap.userId ?? '';
    String convoId = _conversationId ?? '';

    // If it is the first message in the conversation, dynamically create the conversation doc
    if (convoId.isEmpty) {
      if (otherId.isEmpty) return;

      final newConvoRef = FirebaseFirestore.instance.collection('conversations').doc();
      convoId = newConvoRef.id;

      await newConvoRef.set({
        'participants': [uid, otherId],
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'skill': widget.swap.offering,
        'wanting': widget.swap.wanting,
        'unreadCount': {
          uid: 0,
          otherId: 1,
        },
      });

      setState(() {
        _conversationId = convoId;
      });
      _updateMessagesStream();
    } 

    await _chatRepo.sendMessage(
      conversationId: convoId,
      text: text.trim(),
      type: 'text',
    );

    _msgController.clear();
    if (_shouldScrollToBottom) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _navigateBack() => Navigator.pop(context);

  @override
  void dispose() {
    // Unmute foreground alerts
    if (FcmService().currentActiveConvoId == _conversationId) {
      FcmService().currentActiveConvoId = null;
    }
    _msgController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _typingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Dynamic Header listening to real-time user presence
            _profileStream != null
                ? StreamBuilder<ChatUserProfile>(
                    stream: _profileStream,
                    builder: (context, snap) {
                      final profile = snap.data ??
                          ChatUserProfile(
                            userId: widget.swap.userId ?? '',
                            name: widget.swap.name,
                            imageUrl: widget.swap.imageUrl,
                            isOnline: false,
                          );
                      return _buildHeader(profile);
                    },
                  )
                : _buildHeader(ChatUserProfile(
                    userId: widget.swap.userId ?? '',
                    name: widget.swap.name,
                    imageUrl: widget.swap.imageUrl,
                    isOnline: false,
                  )),

            Expanded(
              child: _conversationId == null
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C2FF)))
                  : _conversationId!.isEmpty
                      ? _buildEmptyChat()
                      : _messagesStream != null 
                        ? StreamBuilder<List<QueryDocumentSnapshot>>(
                            stream: _messagesStream,
                            builder: (context, snap) {
                              if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                                return const Center(child: CircularProgressIndicator(color: Color(0xFF00C2FF)));
                              }

                              final docs = snap.data ?? [];
                              if (docs.isEmpty) {
                                return _buildEmptyChat();
                              }

                              // Auto scroll on frame render if needed
                              if (_shouldScrollToBottom) {
                                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                              }

                              return ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                itemCount: docs.length + 1,
                                itemBuilder: (_, i) {
                                  if (i == 0) {
                                    return const _DateChip(label: 'TODAY');
                                  }
                                  final d = docs[i - 1].data() as Map<String, dynamic>;
                                  final isMine = d['senderId'] == uid;
                                  final type = d['type'] as String? ?? 'text';

                                  if (type == 'swap_request') {
                                    return SwapRequestCard(
                                      requestId: d['requestId'] ?? '',
                                      isMine: isMine,
                                    );
                                  }

                                  if (type == 'session_invite') {
                                    debugPrint("=== SESSION INVITE FOUND ===");
                                    debugPrint("sessionId = ${d['sessionId']}");
                                    debugPrint("swapId = ${d['swapId']}");
                                    return SessionInviteCard(
                                      sessionId: d['sessionId'] ?? '',
                                      swapId: d['swapId'] ?? '',
                                      isMine: isMine,
                                    );
                                  }

                                  return _MessageBubble(
                                    text: d['text'] as String? ?? '',
                                    isMine: isMine,
                                    timestamp: d['timestamp'] as Timestamp?,
                                    status: d['status'] as String? ?? 'sent',
                                  );
                                },
                              );
                            },
                          )
                        : _buildEmptyChat(),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ChatUserProfile profile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: const Color(0xFF00C2FF).withOpacity(0.1))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _navigateBack,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          _AvatarCircle(name: profile.name, initials: profile.initials, imageUrl: profile.imageUrl, isOnline: profile.isOnline, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(profile.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 15)),
              if (_otherTyping)
                Text('Typing...', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontStyle: FontStyle.italic)),
              if (!_otherTyping)
                Row(children: [
                  Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 5), decoration: BoxDecoration(color: profile.isOnline ? const Color(0xFF22C55E) : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), shape: BoxShape.circle)),
                  Text(profile.isOnline ? 'Online' : profile.relativeLastSeen, style: TextStyle(color: profile.isOnline ? const Color(0xFF22C55E) : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 11)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(widget.swap.offering, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 11), overflow: TextOverflow.ellipsis)),
                ]),
            ]),
          ),
          // ── Options Menu ──
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 22),
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (val) {
              if (val == 'report') {
                showDialog(
                  context: context,
                  builder: (_) => ReportUserDialog(
                    reportedUserId: widget.swap.userId ?? '',
                    reportedUserName: widget.swap.name,
                    source: 'chat',
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report_gmailerrorred_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 12),
                    Text('Report User', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 70, height: 70, decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.surface, border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2))), child: Icon(Icons.chat_bubble_outline_rounded, color: Theme.of(context).colorScheme.primary, size: 30)),
        const SizedBox(height: 14),
        Text('Start chatting with ${widget.swap.name}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
      ]),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2))),
              child: TextField(
                controller: _msgController,
                onChanged: _onMessageChanged,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                decoration: InputDecoration(hintText: 'Type a message...', hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 13), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                onSubmitted: sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => sendMessage(_msgController.text),
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, const Color(0xFF6B8AFF)], begin: Alignment.topLeft, end: Alignment.bottomRight), shape: BoxShape.circle),
              child: Icon(Icons.send_rounded, color: Theme.of(context).colorScheme.onSurface, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  const _DateChip({required this.label});
  @override
  Widget build(BuildContext context) {
    return Center(child: Container(margin: const EdgeInsets.symmetric(vertical: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.15))), child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5))));
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMine;
  final Timestamp? timestamp;
  final String status;

  const _MessageBubble({required this.text, required this.isMine, this.timestamp, required this.status});

  @override
  Widget build(BuildContext context) {
    final timeStr = timestamp != null ? "${timestamp!.toDate().hour}:${timestamp!.toDate().minute.toString().padLeft(2, '0')}" : '';

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              gradient: isMine ? LinearGradient(colors: [Theme.of(context).colorScheme.primary, const Color(0xFF6B8AFF)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
              color: isMine ? null : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: Radius.circular(isMine ? 18 : 4), bottomRight: Radius.circular(isMine ? 4 : 18)),
              border: isMine ? null : Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
            ),
            child: Text(text, style: TextStyle(color: isMine ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13, height: 1.5)),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(timeStr, style: TextStyle(color: Theme.of(context).colorScheme.outlineVariant, fontSize: 10)),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  _buildStatusTick(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTick() {
    if (status == 'read') {
      return const Icon(Icons.done_all_rounded, color: Color(0xFF00C2FF), size: 13);
    } else if (status == 'delivered') {
      return const Icon(Icons.done_all_rounded, color: Colors.grey, size: 13);
    } else {
      return const Icon(Icons.done_rounded, color: Colors.grey, size: 13);
    }
  }
}

class _AvatarCircle extends StatelessWidget {
  final String name;
  final String initials;
  final String? imageUrl;
  final bool isOnline;
  final double size;
  const _AvatarCircle({required this.name, required this.initials, this.imageUrl, required this.isOnline, required this.size});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Container(
          width: size, height: size,
          decoration: BoxDecoration(color: isDark ? const Color(0xFF2E3E5C) : Colors.grey[200], shape: BoxShape.circle, border: Border.all(color: isOnline ? const Color(0xFF22C55E) : const Color(0xFF00C2FF).withOpacity(0.2), width: isOnline ? 2 : 1.5)),
          child: ClipOval(child: imageUrl != null && imageUrl!.isNotEmpty ? Image.network(imageUrl!, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildInitials(), loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : _buildInitials()) : _buildInitials()),
        ),
        if (isOnline)
          Positioned(bottom: 1, right: 1, child: Container(width: size * 0.24, height: size * 0.24, decoration: BoxDecoration(color: const Color(0xFF22C55E), shape: BoxShape.circle, border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5)))),
      ],
    );
  }

  Widget _buildInitials() {
    return Center(child: Text(initials, style: TextStyle(color: const Color(0xFF00C2FF), fontWeight: FontWeight.bold, fontSize: size * 0.35)));
  }
}
