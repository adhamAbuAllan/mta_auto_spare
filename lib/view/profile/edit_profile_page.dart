import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers/auth_provider.dart';
import '../../models/models.dart';
import '../common_widgets/app_error_card.dart';
import '../common_widgets/app_panel.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();

  bool _chatPushEnabled = true;
  bool _chatMessagePreviewEnabled = true;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentSessionProvider).profile;
    if (profile != null) {
      _seedForm(profile);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentSessionProvider).profile;
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(
          child: AppErrorCard(
            message: 'Your profile could not be loaded right now.',
          ),
        ),
      );
    }

    final updateState = ref.watch(updateProfileNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: AppPanel(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keep your seller profile up to date',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Update the details buyers see and tune how chat notifications reach you.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF6F6A63),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _ReadOnlyProfileMeta(profile: profile),
                      const SizedBox(height: 16),
                      if (updateState.errorMessage != null) ...[
                        AppErrorCard(message: updateState.errorMessage!),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Display name',
                          hintText: 'Your name',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your name.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneController,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          hintText: '+201000000000',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _cityController,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          hintText: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 20),
                      _PreferenceToggle(
                        title: 'Chat push notifications',
                        subtitle:
                            'Receive a notification when someone sends a chat message.',
                        value: _chatPushEnabled,
                        onChanged: (value) {
                          setState(() => _chatPushEnabled = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      _PreferenceToggle(
                        title: 'Show message preview',
                        subtitle:
                            'Include part of the chat message inside notifications.',
                        value: _chatMessagePreviewEnabled,
                        onChanged: (value) {
                          setState(() => _chatMessagePreviewEnabled = value);
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: updateState.isLoading ? null : _submit,
                              child: Text(
                                updateState.isLoading
                                    ? 'Saving...'
                                    : 'Save Profile',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final updatedProfile = await ref
        .read(updateProfileNotifierProvider.notifier)
        .update(
          name: _nameController.text,
          phone: _phoneController.text,
          city: _cityController.text,
          chatPushEnabled: _chatPushEnabled,
          chatMessagePreviewEnabled: _chatMessagePreviewEnabled,
        );

    if (updatedProfile == null || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully.')),
    );
    Navigator.of(context).pop();
  }

  void _seedForm(MeProfile profile) {
    _nameController.text = profile.name;
    _phoneController.text = profile.phone ?? '';
    _cityController.text = profile.city ?? '';
    _chatPushEnabled = profile.chatPushEnabled;
    _chatMessagePreviewEnabled = profile.chatMessagePreviewEnabled;
  }
}

class _ReadOnlyProfileMeta extends StatelessWidget {
  const _ReadOnlyProfileMeta({required this.profile});

  final MeProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F8F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD5E8E4)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _MetaPill(icon: Icons.email_outlined, label: profile.email),
          _MetaPill(
            icon: Icons.alternate_email_rounded,
            label: profile.username,
          ),
          _MetaPill(icon: Icons.badge_outlined, label: profile.role),
        ],
      ),
    );
  }
}

class _PreferenceToggle extends StatelessWidget {
  const _PreferenceToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3EC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7DCCE)),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6F6A63)),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
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
