import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../api/api_exception.dart';
import '../../controllers/providers/api_provider.dart';
import '../../controllers/providers/auth_provider.dart';
import '../../controllers/providers/catalog_provider.dart';
import '../../models/models.dart';
import '../common_widgets/app_error_card.dart';
import '../common_widgets/app_panel.dart';
import '../common_widgets/async_error_message.dart';
import '../common_widgets/car_model_card.dart';
import '../common_widgets/user_avatar.dart';

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
  final ImagePicker _imagePicker = ImagePicker();

  bool _chatPushEnabled = true;
  bool _chatMessagePreviewEnabled = true;
  bool _isDeletingAccount = false;
  String? _deleteAccountError;
  RequestUploadImage? _selectedAvatarImage;
  final Set<int> _selectedCarModelIds = <int>{};
  int? _selectedCarMakeId;

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
    final isBusy = updateState.isLoading || _isDeletingAccount;
    final carCatalog = ref.watch(carCatalogProvider);
    final availableMakes = carCatalog.valueOrNull ?? const <CarMakeOption>[];
    final selectedMake = _selectedCarMakeId != null
        ? _findMakeById(availableMakes, _selectedCarMakeId!)
        : (availableMakes.isEmpty ? null : availableMakes.first);
    final selectedModels = _resolveSelectedCarModels(
      profile: profile,
      catalog: availableMakes,
    );
    final selectedModelIds = selectedModels.map((item) => item.id).toSet();
    final visibleModels = selectedMake?.models ?? const <CarModelOption>[];
    final isSupplierProfile = profile.role == 'supplier';
    final carCatalogErrorMessage = asyncErrorMessage(
      carCatalog.error,
      fallback: 'The car catalog could not be loaded right now.',
    );

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
                        'Keep your profile up to date',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isSupplierProfile
                            ? 'Update the details buyers see, tune chat notifications, and choose the car models you already stock parts for.'
                            : 'Update the details suppliers see and tune how chat notifications reach you.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF6F6A63),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _AvatarEditorSection(
                        profile: profile,
                        selectedAvatarImage: _selectedAvatarImage,
                        onPickAvatar: isBusy ? null : _pickAvatar,
                        onClearSelection: _selectedAvatarImage == null || isBusy
                            ? null
                            : () {
                                setState(() => _selectedAvatarImage = null);
                              },
                      ),
                      const SizedBox(height: 16),
                      _ReadOnlyProfileMeta(profile: profile),
                      const SizedBox(height: 16),
                      if (updateState.errorMessage != null) ...[
                        AppErrorCard(message: updateState.errorMessage!),
                        const SizedBox(height: 16),
                      ],
                      if (_deleteAccountError != null) ...[
                        AppErrorCard(message: _deleteAccountError!),
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
                      if (isSupplierProfile) ...[
                        const SizedBox(height: 22),
                        Text(
                          'Cars I Have Parts For',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose every car model you can supply so new matching requests notify you.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF6F6A63)),
                        ),
                        const SizedBox(height: 14),
                        if (selectedModels.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F3EC),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFE7DCCE),
                              ),
                            ),
                            child: Text(
                              'No car models selected yet. Pick the models you support from the catalog below.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: const Color(0xFF6F6A63)),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final carModel in selectedModels)
                                SizedBox(
                                  width: 240,
                                  child: CarModelCard(
                                    carModel: carModel,
                                    compact: true,
                                    onRemove: () {
                                      setState(() {
                                        _selectedCarModelIds.remove(
                                          carModel.id,
                                        );
                                      });
                                    },
                                  ),
                                ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        if (carCatalog.isLoading)
                          const LinearProgressIndicator()
                        else if (carCatalog.hasError)
                          AppErrorCard(
                            message:
                                'The car catalog could not be loaded.\n$carCatalogErrorMessage',
                            onRetry: () => ref.invalidate(carCatalogProvider),
                          )
                        else ...[
                          DropdownButtonFormField<int>(
                            initialValue: selectedMake?.id,
                            decoration: const InputDecoration(
                              labelText: 'Filter by car make',
                            ),
                            items: [
                              for (final make in availableMakes)
                                DropdownMenuItem<int>(
                                  value: make.id,
                                  child: Text(make.name),
                                ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCarMakeId = value;
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: visibleModels.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.82,
                                ),
                            itemBuilder: (context, index) {
                              final carModel = visibleModels[index];
                              final isSelected = selectedModelIds.contains(
                                carModel.id,
                              );
                              return CarModelCard(
                                carModel: carModel,
                                isSelected: isSelected,
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedCarModelIds.remove(carModel.id);
                                    } else {
                                      _selectedCarModelIds.add(carModel.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ],
                      ],
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
                              onPressed: isBusy ? null : _submit,
                              child: Text(
                                updateState.isLoading
                                    ? 'Saving...'
                                    : 'Save Profile',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _DangerZoneCard(
                        isBusy: isBusy,
                        onDeleteAccount: _confirmDeleteAccount,
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

    if (_deleteAccountError != null) {
      setState(() => _deleteAccountError = null);
    }

    final profile = ref.read(currentSessionProvider).profile;
    if (profile == null) {
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
          supportedCarModelIds: profile.role == 'supplier'
              ? (_selectedCarModelIds.toList()..sort())
              : null,
          avatarImage: _selectedAvatarImage,
        );

    if (updatedProfile == null || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully.')),
    );
    setState(() => _selectedAvatarImage = null);
    Navigator.of(context).pop();
  }

  Future<void> _pickAvatar() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1600,
      maxHeight: 1600,
      requestFullMetadata: false,
    );
    if (!mounted || pickedFile == null) {
      return;
    }

    setState(() {
      _selectedAvatarImage = RequestUploadImage(
        path: pickedFile.path,
        fileName: pickedFile.name,
        contentType: lookupMimeType(pickedFile.path) ?? 'image/jpeg',
      );
    });
  }

  Future<void> _confirmDeleteAccount() async {
    if (_isDeletingAccount) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'This permanently deletes your account, your request posts, your chat history, and your registered devices. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB42318),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete Account'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    setState(() {
      _isDeletingAccount = true;
      _deleteAccountError = null;
    });

    try {
      await ref.read(authApiProvider).deleteAccount();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account has been deleted.')),
      );
      await ref.read(logoutNotifierProvider.notifier).logout();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _deleteAccountError = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(
        () => _deleteAccountError =
            'Your account could not be deleted right now.',
      );
    } finally {
      if (mounted) {
        setState(() => _isDeletingAccount = false);
      }
    }
  }

  void _seedForm(MeProfile profile) {
    _nameController.text = profile.name;
    _phoneController.text = profile.phone ?? '';
    _cityController.text = profile.city ?? '';
    _chatPushEnabled = profile.chatPushEnabled;
    _chatMessagePreviewEnabled = profile.chatMessagePreviewEnabled;
    _selectedCarModelIds
      ..clear()
      ..addAll(profile.supportedCarModels.map((item) => item.id));
    if (profile.supportedCarModels.isNotEmpty) {
      _selectedCarMakeId = profile.supportedCarModels.first.makeId;
    }
  }

  List<CarModelOption> _resolveSelectedCarModels({
    required MeProfile profile,
    required List<CarMakeOption> catalog,
  }) {
    final catalogById = <int, CarModelOption>{
      for (final make in catalog)
        for (final model in make.models) model.id: model,
    };

    final selectedModels = <CarModelOption>[];
    for (final modelId in _selectedCarModelIds) {
      final resolvedModel =
          catalogById[modelId] ?? _findProfileCarModel(profile, modelId);
      if (resolvedModel != null) {
        selectedModels.add(resolvedModel);
      }
    }
    selectedModels.sort((left, right) {
      final makeCompare = left.makeName.compareTo(right.makeName);
      if (makeCompare != 0) {
        return makeCompare;
      }
      return left.name.compareTo(right.name);
    });
    return selectedModels;
  }

  CarMakeOption? _findMakeById(List<CarMakeOption> makes, int makeId) {
    for (final make in makes) {
      if (make.id == makeId) {
        return make;
      }
    }
    return null;
  }

  CarModelOption? _findProfileCarModel(MeProfile profile, int modelId) {
    for (final carModel in profile.supportedCarModels) {
      if (carModel.id == modelId) {
        return carModel;
      }
    }
    return null;
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

class _AvatarEditorSection extends StatelessWidget {
  const _AvatarEditorSection({
    required this.profile,
    required this.selectedAvatarImage,
    required this.onPickAvatar,
    this.onClearSelection,
  });

  final MeProfile profile;
  final RequestUploadImage? selectedAvatarImage;
  final Future<void> Function()? onPickAvatar;
  final VoidCallback? onClearSelection;

  @override
  Widget build(BuildContext context) {
    final hasPendingPhoto = selectedAvatarImage != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3EC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7DCCE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            label: profile.name,
            imageUrl: profile.avatar,
            imageProvider: selectedAvatarImage == null
                ? null
                : FileImage(File(selectedAvatarImage!.path)),
            radius: 34,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Photo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasPendingPhoto
                      ? 'A new photo is ready. Save your profile to apply it.'
                      : 'Choose a photo so your name is easier to recognize in requests and chats.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6F6A63),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: onPickAvatar == null
                          ? null
                          : () {
                              onPickAvatar!();
                            },
                      icon: const Icon(Icons.photo_camera_back_outlined),
                      label: Text(
                        hasPendingPhoto
                            ? 'Choose Another Photo'
                            : 'Change Photo',
                      ),
                    ),
                    if (hasPendingPhoto)
                      TextButton(
                        onPressed: onClearSelection,
                        child: const Text('Undo Photo Change'),
                      ),
                  ],
                ),
              ],
            ),
          ),
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

class _DangerZoneCard extends StatelessWidget {
  const _DangerZoneCard({required this.isBusy, required this.onDeleteAccount});

  final bool isBusy;
  final Future<void> Function() onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF3C1C1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delete Account',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFFB42318),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Remove your profile and permanently delete the data that belongs to your account if you no longer want to use the app.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF7A271A)),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: isBusy
                ? null
                : () {
                    onDeleteAccount();
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB42318),
              side: const BorderSide(color: Color(0xFFF0A7A7)),
            ),
            icon: const Icon(Icons.delete_forever_outlined),
            label: Text(isBusy ? 'Please wait...' : 'Delete Account'),
          ),
        ],
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
