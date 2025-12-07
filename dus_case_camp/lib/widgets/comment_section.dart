import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';

class CommentSection extends ConsumerStatefulWidget {
  final String caseId;

  const CommentSection({super.key, required this.caseId});

  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  final _commentController = TextEditingController();
  bool _isPosting = false;

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;

    setState(() => _isPosting = true);

    try {
      // Fetch user name (optional, can be optimized by storing in auth profile or provider)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userName =
          userDoc.exists ? (userDoc.data()?['fullName'] ?? 'User') : 'User';
      final role =
          userDoc.exists ? (userDoc.data()?['role'] ?? 'student') : 'student';

      await FirebaseFirestore.instance
          .collection('cases')
          .doc(widget.caseId)
          .collection('comments')
          .add({
        'userId': user.uid,
        'userName': userName,
        'userRole': role,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _commentController.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('cases')
          .doc(widget.caseId)
          .collection('comments')
          .doc(commentId)
          .delete();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(firebaseAuthProvider).currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('Discussion',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),

        // Comment List
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('cases')
              .doc(widget.caseId)
              .collection('comments')
              .orderBy('createdAt', descending: true)
              .limit(50)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: ${snapshot.error}'));
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());

            final comments = snapshot.data!.docs;

            if (comments.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No comments yet. Start the discussion!',
                    style: TextStyle(color: Colors.grey)),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(), // Managed by parent scroll
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final data = comments[index].data() as Map<String, dynamic>;
                final commentId = comments[index].id;
                final isOwner = user?.uid == data['userId'];
                final date = (data['createdAt'] as Timestamp?)?.toDate();
                final dateStr = date != null
                    ? DateFormat('MMM d, HH:mm').format(date)
                    : 'Just now';
                final isTeacher = data['userRole'] == 'teacher' ||
                    data['userRole'] == 'admin';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isTeacher ? Colors.orange[100] : Colors.blue[100],
                    child: Text(
                      (data['userName'] as String? ?? 'U')[0].toUpperCase(),
                      style: TextStyle(
                          color: isTeacher
                              ? Colors.orange[800]
                              : Colors.blue[800]),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(data['userName'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (isTeacher) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified,
                            size: 14, color: Colors.blue),
                      ],
                      const SizedBox(width: 8),
                      Text(dateStr,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  subtitle: Text(data['content'] ?? ''),
                  trailing: isOwner
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => _deleteComment(commentId),
                        )
                      : null,
                );
              },
            );
          },
        ),

        const Divider(),

        // Input Area
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Add a comment...',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isPosting ? null : _postComment,
                icon: _isPosting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send, color: Colors.teal),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
