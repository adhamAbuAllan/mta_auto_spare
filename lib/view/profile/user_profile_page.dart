import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_exception.dart';
import '../../constants/api_constants.dart';
import '../../controllers/providers/api_provider.dart';
import '../../controllers/providers/auth_provider.dart';
import '../../controllers/providers/chat_provider.dart';
import '../../localization/app_localizations_x.dart';
import '../../models/models.dart';
import '../chat/chat_detail_page.dart';
import '../chat/chat_formatters.dart';
import '../common_widgets/app_error_card.dart';
import '../common_widgets/app_panel.dart';
import '../common_widgets/time_formatter.dart';
import '../common_widgets/user_avatar.dart';
import '../common_widgets/zoomable_network_gallery_page.dart';
import 'edit_profile_page.dart';

class UserProfilePage extends ConsumerStatefulWidget {
  const UserProfilePage({super.key, required this.userId});

  final int userId;

  @override
  ConsumerState<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends ConsumerState<UserProfilePage> {
  late Future<PublicUserProfile> _profileFuture = _loadProfile();
  bool _isOpeningChat = false;
  bool _isOpeningWhatsApp = false;

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentSessionProvider).profile?.id;
    final isCurrentUser = currentUserId == widget.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (isCurrentUser)
            IconButton(
              tooltip: 'Edit profile',
              onPressed: _openEditProfile,
              icon: const Icon(Icons.manage_accounts_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<PublicUserProfile>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                snapshot.data == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError && snapshot.data == null) {
              return RefreshIndicator(
                onRefresh: _refreshProfile,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    const SizedBox(height: 120),
                    AppErrorCard(
                      message: 'This profile could not be loaded right now.',
                      onRetry: _refreshProfile,
                    ),
                  ],
                ),
              );
            }

            final profile = snapshot.data;
            if (profile == null) {
              return const Center(
                child: AppErrorCard(
                  message: 'This profile could not be loaded right now.',
                ),
              );
            }

            final isSupplier = profile.role.trim().toLowerCase() == 'supplier';
            final supportedCarMakes = _supportedCarMakes(profile);
            final hasContactDetails =
                profile.email?.trim().isNotEmpty == true ||
                profile.phone?.trim().isNotEmpty == true;

            return RefreshIndicator(
              onRefresh: _refreshProfile,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    UserAvatar(
                                      label: profile.name,
                                      imageUrl: profile.avatar,
                                      radius: 36,
                                      onTap:
                                          profile.avatar?.trim().isNotEmpty ==
                                              true
                                          ? () => _openAvatarViewer(profile)
                                          : null,
                                    ),
                                    const SizedBox(width: 18),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            profile.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w900,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _roleLabel(profile.role),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color: const Color(
                                                    0xFF116466,
                                                  ),
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            conversationPresenceLabel(
                                              isOnline: profile.isOnline,
                                              lastSeenAt: profile.lastSeenAt,
                                              l10n: context.l10n,
                                            ),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: const Color(
                                                    0xFF6F6A63,
                                                  ),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    if (profile.city?.trim().isNotEmpty == true)
                                      _ProfileMetaChip(
                                        icon: Icons.location_on_outlined,
                                        label: profile.city!.trim(),
                                      ),
                                    if (profile.rating?.trim().isNotEmpty ==
                                        true)
                                      _ProfileMetaChip(
                                        icon: Icons.star_outline_rounded,
                                        label: 'Rating ${profile.rating}',
                                      ),
                                    _ProfileMetaChip(
                                      icon: Icons.schedule_outlined,
                                      label:
                                          'Joined ${formatRelativeTime(profile.createdAt, context.l10n)}',
                                    ),
                                  ],
                                ),
                                if (isCurrentUser) ...[
                                  const SizedBox(height: 18),
                                  FilledButton.tonalIcon(
                                    onPressed: _openEditProfile,
                                    icon: const Icon(
                                      Icons.manage_accounts_outlined,
                                    ),
                                    label: const Text('Edit Profile'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isSupplier && hasContactDetails) ...[
                            const SizedBox(height: 18),
                            AppPanel(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Contact Details',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 14),
                                  if (profile.email?.trim().isNotEmpty == true)
                                    _ProfileInfoRow(
                                      icon: Icons.email_outlined,
                                      title: 'Email',
                                      value: profile.email!.trim(),
                                    ),
                                  if (profile.email?.trim().isNotEmpty ==
                                          true &&
                                      profile.phone?.trim().isNotEmpty == true)
                                    const SizedBox(height: 12),
                                  if (profile.phone?.trim().isNotEmpty == true)
                                    _ProfileInfoRow(
                                      icon: Icons.phone_outlined,
                                      title: 'Phone',
                                      value: profile.phone!.trim(),
                                    ),
                                ],
                              ),
                            ),
                          ],
                          if (isSupplier && !isCurrentUser) ...[
                            const SizedBox(height: 18),
                            AppPanel(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quick Actions',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Start a direct conversation or open WhatsApp using the supplier phone number.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: const Color(0xFF6F6A63),
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      FilledButton.icon(
                                        onPressed: _isOpeningChat
                                            ? null
                                            : () => _openChat(profile),
                                        icon: Icon(
                                          _isOpeningChat
                                              ? Icons.hourglass_top_rounded
                                              : Icons
                                                    .chat_bubble_outline_rounded,
                                        ),
                                        label: Text(
                                          _isOpeningChat
                                              ? 'Opening chat...'
                                              : 'Chat',
                                        ),
                                      ),
                                      if (profile.phone?.trim().isNotEmpty ==
                                          true)
                                        OutlinedButton.icon(
                                          onPressed: _isOpeningWhatsApp
                                              ? null
                                              : () => _openWhatsApp(profile),
                                          icon: Icon(
                                            _isOpeningWhatsApp
                                                ? Icons.hourglass_top_rounded
                                                : Icons.phone_in_talk_outlined,
                                          ),
                                          label: Text(
                                            _isOpeningWhatsApp
                                                ? 'Opening WhatsApp...'
                                                : 'WhatsApp',
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (isSupplier && supportedCarMakes.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            AppPanel(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cars This Supplier Works With',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'These are the car brands selected on the supplier profile.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: const Color(0xFF6F6A63),
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      for (final makeName in supportedCarMakes)
                                        _CarMakeChip(label: makeName),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
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

  Future<PublicUserProfile> _loadProfile() {
    return ref.read(userApiProvider).getUserById(widget.userId);
  }

  Future<void> _refreshProfile() async {
    final nextFuture = _loadProfile();
    setState(() => _profileFuture = nextFuture);
    await nextFuture;
  }

  Future<void> _openEditProfile() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const EditProfilePage()));
    if (!mounted) {
      return;
    }
    await _refreshProfile();
  }

  void _openAvatarViewer(PublicUserProfile profile) {
    final avatarUrl = profile.avatar?.trim() ?? '';
    if (avatarUrl.isEmpty) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ZoomableNetworkGalleryPage(
          imageUrls: [ApiConstants.resolveUrl(avatarUrl)],
          initialIndex: 0,
          headers: const {
            ApiConstants.ngrokHeaderKey: ApiConstants.ngrokHeaderValue,
          },
          heroTagBuilder: (_) => 'user-profile-avatar-${profile.id}',
        ),
      ),
    );
  }

  List<String> _supportedCarMakes(PublicUserProfile profile) {
    final seenKeys = <String>{};
    final makes = <String>[];

    for (final carModel in profile.supportedCarModels) {
      final makeName = carModel.makeName.trim();
      final makeKey = makeName.toLowerCase();
      if (makeName.isEmpty || seenKeys.contains(makeKey)) {
        continue;
      }
      seenKeys.add(makeKey);
      makes.add(makeName);
    }

    return makes;
  }

  Future<void> _openChat(PublicUserProfile profile) async {
    if (_isOpeningChat) {
      return;
    }

    final currentUserId = ref.read(currentSessionProvider).profile?.id;
    if (currentUserId == null || currentUserId == profile.id) {
      return;
    }

    setState(() => _isOpeningChat = true);

    try {
      final conversationId = await ref
          .read(ensureConversationNotifierProvider.notifier)
          .ensureConversation(
            currentUserId: currentUserId,
            ownerUserId: profile.id,
            requestTitle: profile.name,
            currentConversations: ref
                .read(conversationsNotifierProvider)
                .conversations,
          );

      if (!mounted) {
        return;
      }

      final ensureState = ref.read(ensureConversationNotifierProvider);
      if (conversationId == null) {
        _showSnackBar(
          ensureState.errorMessage ?? 'Could not open the chat right now.',
        );
        return;
      }

      if (ensureState.wasCreated) {
        await ref
            .read(conversationsNotifierProvider.notifier)
            .load(forceRefresh: true);
      }

      if (!mounted) {
        return;
      }

      setState(() => _isOpeningChat = false);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatDetailPage(conversationId: conversationId),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnackBar('Could not open the chat right now.');
    } finally {
      if (mounted && _isOpeningChat) {
        setState(() => _isOpeningChat = false);
      }
    }
  }

  Future<void> _openWhatsApp(PublicUserProfile profile) async {
    if (_isOpeningWhatsApp) {
      return;
    }

    final normalizedPhone = _normalizeWhatsAppPhone(profile.phone);
    if (normalizedPhone == null) {
      _showSnackBar('This supplier phone number is not ready for WhatsApp.');
      return;
    }

    setState(() => _isOpeningWhatsApp = true);

    try {
      final uri = Uri(
        scheme: 'https',
        host: 'wa.me',
        path: '/$normalizedPhone',
        queryParameters: {'text': 'Hello ${profile.name}'},
      );
      final didLaunch = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!didLaunch && mounted) {
        _showSnackBar('Could not open WhatsApp right now.');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnackBar('Could not open WhatsApp right now.');
    } finally {
      if (mounted) {
        setState(() => _isOpeningWhatsApp = false);
      }
    }
  }

  String? _normalizeWhatsAppPhone(String? rawPhone) {
    final trimmed = rawPhone?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    var normalized = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (normalized.startsWith('00')) {
      normalized = normalized.substring(2);
    }

    if (normalized.length < 8) {
      return null;
    }

    return normalized;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _roleLabel(String role) {
    final trimmed = role.trim();
    if (trimmed.isEmpty) {
      return 'Member';
    }
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF6F1EA),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF0C4A63)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF6F6A63),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileMetaChip extends StatelessWidget {
  const _ProfileMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F1EA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0C4A63)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: const Color(0xFF5F5A54)),
          ),
        ],
      ),
    );
  }
}

class _CarMakeChip extends StatelessWidget {
  const _CarMakeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4F1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD1E7E0)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: const Color(0xFF116466),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
