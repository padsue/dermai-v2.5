import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/conversation_model.dart';
import '../models/doctor_model.dart';
import '../models/message_model.dart';
import '../repositories/message_repository.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/app_colors.dart';
import '../widgets/profile_avatar.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ConversationInfoScreen extends StatefulWidget {
  final ConversationModel conversation;
  final bool isBottomSheet;
  final ScrollController? scrollController;

  const ConversationInfoScreen({
    Key? key,
    required this.conversation,
    this.isBottomSheet = false,
    this.scrollController,
  }) : super(key: key);

  @override
  State<ConversationInfoScreen> createState() => _ConversationInfoScreenState();
}

class _ConversationInfoScreenState extends State<ConversationInfoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DoctorModel? _doctor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDoctorInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorInfo() async {
    try {
      final doctorDoc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(widget.conversation.doctorId)
          .get();

      if (doctorDoc.exists && mounted) {
        setState(() {
          _doctor = DoctorModel.fromMap(doctorDoc.data()!, doctorDoc.id);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.isBottomSheet) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header styled like scan_drawer.dart
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Conversation Info',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'View details about this conversation.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primary,
                labelStyle: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Info'),
                  Tab(text: 'Media'),
                  Tab(text: 'Files'),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _InfoTabContent(
                          doctor: _doctor,
                          scrollController: widget.scrollController,
                        ),
                        _MediaTabContent(
                          conversationId: widget.conversation.id,
                          scrollController: widget.scrollController,
                        ),
                        _FilesTabContent(
                          conversationId: widget.conversation.id,
                          scrollController: widget.scrollController,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Conversation Info',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Info'),
            Tab(text: 'Media'),
            Tab(text: 'Files'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _InfoTabContent(doctor: _doctor),
                _MediaTabContent(conversationId: widget.conversation.id),
                _FilesTabContent(conversationId: widget.conversation.id),
              ],
            ),
    );
  }
}

// Separate widget for Info Tab with KeepAlive
class _InfoTabContent extends StatefulWidget {
  final DoctorModel? doctor;
  final ScrollController? scrollController;

  const _InfoTabContent({
    Key? key,
    required this.doctor,
    this.scrollController,
  }) : super(key: key);

  @override
  State<_InfoTabContent> createState() => _InfoTabContentState();
}

class _InfoTabContentState extends State<_InfoTabContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.doctor == null) {
      return const Center(child: Text('Doctor information not available'));
    }

    final theme = Theme.of(context);

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Profile Section
          ProfileAvatar(
            imageUrl: widget.doctor!.imageUrl,
            radius: 50,
            showBorder: true,
            autoLoadUserPhoto: false,
          ),
          const SizedBox(height: 16),
          Text(
            'Dr. ${widget.doctor!.displayName}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Doctor Information
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: Icons.person,
                  label: 'Name',
                  value: 'Dr. ${widget.doctor!.displayName}',
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  icon: Icons.email,
                  label: 'Email',
                  value: widget.doctor!.email,
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  icon: Icons.phone,
                  label: 'Contact Number',
                  value: widget.doctor!.phone,
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  icon: Icons.work,
                  label: 'Position',
                  value: widget.doctor!.position,
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  icon: Icons.local_hospital,
                  label: 'Clinic',
                  value: widget.doctor!.clinic,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 150,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Implement delete conversation functionality
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                minimumSize: Size.fromHeight(36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('Delete Conversation'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Separate widget for Media Tab with KeepAlive
class _MediaTabContent extends StatefulWidget {
  final String conversationId;
  final ScrollController? scrollController;

  const _MediaTabContent({
    Key? key,
    required this.conversationId,
    this.scrollController,
  }) : super(key: key);

  @override
  State<_MediaTabContent> createState() => _MediaTabContentState();
}

class _MediaTabContentState extends State<_MediaTabContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final Stream<List<MessageModel>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = context
        .read<MessageRepository>()
        .getMessagesStreamForConversation(widget.conversationId);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<List<MessageModel>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No media files'));
        }

        // Filter messages with image attachments
        final mediaMessages = snapshot.data!
            .where((msg) =>
                msg.attachments.any((att) => att.type.startsWith('image/')))
            .toList();

        if (mediaMessages.isEmpty) {
          return const Center(child: Text('No media files'));
        }

        // Extract all image attachments
        final imageAttachments = mediaMessages
            .expand((msg) => msg.attachments)
            .where((att) => att.type.startsWith('image/'))
            .toList();

        return GridView.builder(
          controller: widget.scrollController,
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: imageAttachments.length,
          itemBuilder: (context, index) {
            final attachment = imageAttachments[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: attachment.url,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Separate widget for Files Tab with KeepAlive
class _FilesTabContent extends StatefulWidget {
  final String conversationId;
  final ScrollController? scrollController;

  const _FilesTabContent({
    Key? key,
    required this.conversationId,
    this.scrollController,
  }) : super(key: key);

  @override
  State<_FilesTabContent> createState() => _FilesTabContentState();
}

class _FilesTabContentState extends State<_FilesTabContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final Stream<List<MessageModel>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = context
        .read<MessageRepository>()
        .getMessagesStreamForConversation(widget.conversationId);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return StreamBuilder<List<MessageModel>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No files'));
        }

        // Filter messages with non-image attachments
        final fileMessages = snapshot.data!
            .where((msg) =>
                msg.attachments.any((att) => !att.type.startsWith('image/')))
            .toList();

        if (fileMessages.isEmpty) {
          return const Center(child: Text('No files'));
        }

        // Extract all non-image attachments
        final fileAttachments = fileMessages
            .expand((msg) => msg.attachments)
            .where((att) => !att.type.startsWith('image/'))
            .toList();

        return ListView.builder(
          controller: widget.scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: fileAttachments.length,
          itemBuilder: (context, index) {
            final attachment = fileAttachments[index];
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(
                  _getFileIcon(attachment.type),
                  color: AppColors.primary,
                ),
                title: Text(
                  attachment.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(_formatFileSize(attachment.size)),
                trailing: Icon(
                  Icons.download,
                  color: AppColors.primary,
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getFileIcon(String type) {
    if (type.contains('pdf')) {
      return Icons.insert_drive_file;
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
}
