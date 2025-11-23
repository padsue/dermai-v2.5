import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dermai/models/conversation_model.dart';
import 'package:dermai/models/message_model.dart';
import 'package:dermai/repositories/message_repository.dart';
import 'package:dermai/utils/app_colors.dart';
import 'package:dermai/widgets/custom_app_bar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../services/notification_service.dart';
import '../widgets/profile_avatar.dart';
import 'conversation_info_screen.dart';

class MessagingScreen extends StatefulWidget {
  final ConversationModel conversation;

  const MessagingScreen({Key? key, required this.conversation})
      : super(key: key);

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Stream<List<MessageModel>>? _messagesStream;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;
  final List<AttachmentPreview> _pendingAttachments = [];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markConversationAsRead();
  }

  void _loadMessages() {
    setState(() {
      _messagesStream = context
          .read<MessageRepository>()
          .getMessagesStreamForConversation(widget.conversation.id);
    });
  }

  Future<void> _markConversationAsRead() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      // Mark all unread messages from doctor as read
      final unreadMessages = await _firestore
          .collection('messages')
          .where('conversationId', isEqualTo: widget.conversation.id)
          .where('read', isEqualTo: false)
          .where('senderType', isEqualTo: 'doctor')
          .get();

      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();

      // Update conversation to reflect read status (optional, since unreadCount is calculated dynamically)
      await _firestore
          .collection('conversations')
          .doc(widget.conversation.id)
          .update({
        'unreadByPatient': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error marking conversation as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final messageText = _messageController.text.trim();

    // Don't send if both message and attachments are empty
    if (messageText.isEmpty && _pendingAttachments.isEmpty) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final now = DateTime.now();
      final List<Map<String, dynamic>> uploadedAttachments = [];

      // Upload all pending attachments
      for (var preview in _pendingAttachments) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('messages')
            .child(widget.conversation.id)
            .child(
                '${DateTime.now().millisecondsSinceEpoch}_${preview.fileName}');

        final uploadTask = storageRef.putFile(preview.file);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        final fileSize = await preview.file.length();

        uploadedAttachments.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'name': preview.fileName,
          'type': preview.mimeType,
          'url': downloadUrl,
          'size': fileSize,
        });
      }

      // Add message to messages collection
      await _firestore.collection('messages').add({
        'conversationId': widget.conversation.id,
        'senderId': currentUserId,
        'senderType': 'patient',
        'message': messageText,
        'timestamp': Timestamp.fromDate(now),
        'read': false,
        'attachments': uploadedAttachments,
      });

      // Determine last message preview
      String lastMessagePreview = messageText;
      if (uploadedAttachments.isNotEmpty && messageText.isEmpty) {
        lastMessagePreview = uploadedAttachments
                .any((a) => a['type'].toString().startsWith('image/'))
            ? 'Image'
            : 'File';
      }

      // Update conversation with last message
      await _firestore
          .collection('conversations')
          .doc(widget.conversation.id)
          .update({
        'lastMessage': lastMessagePreview,
        'lastMessageTime': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'unreadByDoctor': true,
        'unreadByPatient': false,
      });

      // Clear input and pending attachments
      _messageController.clear();
      setState(() {
        _pendingAttachments.clear();
      });

      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _showAttachmentOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.insert_drive_file,
                      color: AppColors.primary),
                  title: const Text('Files'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile();
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.photo_library, color: AppColors.primary),
                  title: const Text('Images'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.camera_alt, color: AppColors.primary),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _pendingAttachments.add(AttachmentPreview(
            file: File(image.path),
            mimeType: 'image/${image.path.split('.').last}',
            fileName: image.name,
          ));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final fileExtension = result.files.single.extension ?? '';

        setState(() {
          _pendingAttachments.add(AttachmentPreview(
            file: file,
            mimeType: 'application/$fileExtension',
            fileName: fileName,
          ));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick file: $e')),
      );
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _pendingAttachments.removeAt(index);
    });
  }

  Future<void> _downloadFile(String url, String fileName) async {
    final notificationService = context.read<NotificationService>();

    // Show downloading notification
    await notificationService.showNotification(
      title: 'Downloading File',
      body: 'Your file is being downloaded...',
    );

    try {
      // Download the file
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to download file');
      }

      // Get the directory to save the file
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      // Write the file
      await file.writeAsBytes(response.bodyBytes);

      // Open the file
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        await notificationService.showNotification(
          title: 'File Download Failed',
          body: 'Could not open the downloaded file.',
        );
      } else {
        await notificationService.showNotification(
          title: 'File Downloaded',
          body: 'Your file has been downloaded successfully.',
        );
      }
    } catch (e) {
      await notificationService.showNotification(
        title: 'Download Failed',
        body: 'Failed to download the file. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: Row(
          children: [
            ProfileAvatar(
              imageUrl: widget.conversation.participantAvatar,
              radius: 20,
              showBorder: false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.conversation.participantName ?? 'Unknown',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        showBackButton: true,
        onMenuPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => ConversationInfoScreen(
              conversation: widget.conversation,
              isBottomSheet: true,
            ),
          );
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet. Start the conversation!',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                  );
                }

                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(messages[index]);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(theme),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('h:mm a');
    final currentUserId = _auth.currentUser?.uid;
    final isMe = message.senderId == currentUserId;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: isMe ? const Radius.circular(4) : null,
            bottomLeft: !isMe ? const Radius.circular(4) : null,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.message.isNotEmpty)
              Text(
                message.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isMe ? Colors.white : AppColors.textPrimary,
                ),
              ),
            const SizedBox(height: 4),
            if (message.attachments.isNotEmpty) ...[
              ...message.attachments.map((attachment) {
                if (attachment.type.startsWith('image/')) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: attachment.url,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 150,
                          color: Colors.grey[300],
                          child:
                              const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 150,
                          color: Colors.grey[300],
                          child: const Icon(Icons.error),
                        ),
                      ),
                    ),
                  );
                } else {
                  // Handle other file types (e.g., PDF, DOC)
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                      decoration: BoxDecoration(
                        color: isMe
                            ? AppColors.cherryBlossom.withOpacity(0.2)
                            : AppColors.cherryBlossom,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getFileIcon(attachment.type),
                            color: isMe
                                ? Colors.white.withOpacity(0.8)
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  attachment.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isMe ? Colors.white : Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _formatFileSize(attachment.size),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isMe
                                        ? Colors.white.withOpacity(0.7)
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.download,
                              color: isMe
                                  ? Colors.white.withOpacity(0.8)
                                  : AppColors.primary,
                            ),
                            onPressed: () =>
                                _downloadFile(attachment.url, attachment.name),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }).toList(),
            ],
            Text(
              timeFormat.format(message.timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: isMe ? Colors.white.withOpacity(0.7) : Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String type) {
    if (type.contains('pdf')) {
      return Icons.insert_drive_file; // Changed from Icons.article
    } else if (type.contains('doc') || type.contains('word')) {
      return Icons.description;
    } else {
      return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int size) {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Column(
      children: [
        if (_pendingAttachments.isNotEmpty) _buildAttachmentPreview(theme),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
          ),
          child: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppColors.primary, size: 24),
                  onPressed: _isUploading ? null : _showAttachmentOptions,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    minLines: 1,
                    maxLines: 5,
                    enabled: !_isUploading,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: _isUploading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send,
                              color: Colors.white, size: 24),
                          onPressed: _sendMessage,
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentPreview(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: SizedBox(
        height: 60,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _pendingAttachments.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final attachment = _pendingAttachments[index];
            final isImage = attachment.mimeType.startsWith('image/');

            return Container(
              width: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.champagne.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  // File icon or image thumbnail
                  Container(
                    width: 40,
                    height: 40, // Ensures 1:1 aspect ratio
                    decoration: BoxDecoration(
                      color: Colors.white,
                      // Removed borderRadius to remove radius from preview photo
                    ),
                    child: isImage
                        ? Image.file(
                            attachment.file,
                            fit: BoxFit.cover,
                          )
                        : Icon(
                            _getFileIcon(attachment.mimeType),
                            color: AppColors.primary,
                            size: 24,
                          ),
                  ),
                  const SizedBox(width: 12),
                  // File name and size
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          attachment.fileName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatFileSize(attachment.file.lengthSync()),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Close button
                  GestureDetector(
                    onTap: () => _removeAttachment(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class AttachmentPreview {
  final File file;
  final String mimeType;
  final String fileName;

  AttachmentPreview({
    required this.file,
    required this.mimeType,
    required this.fileName,
  });
}
