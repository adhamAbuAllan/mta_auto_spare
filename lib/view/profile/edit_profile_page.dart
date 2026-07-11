import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../api/api_exception.dart';
import '../../controllers/providers/api_provider.dart';
import '../../controllers/providers/auth_provider.dart';
import '../../controllers/providers/catalog_provider.dart';
import '../../localization/app_localizations_x.dart';
import '../../localization/language_selector.dart';
import '../../models/models.dart';
import '../../utils/phone_number.dart';
import '../common_widgets/app_error_card.dart';
import '../common_widgets/app_panel.dart';
import '../common_widgets/async_error_message.dart';
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
  final Set<int> _selectedCarMakeIds = <int>{};
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
        appBar: AppBar(
          title: Text(context.l10n.editProfile),
          actions: const [
            Padding(
              padding: EdgeInsetsDirectional.only(end: 12),
              child: Center(child: AppLanguageMenuButton()),
            ),
          ],
        ),
        body: Center(
          child: AppErrorCard(
            message: context.l10n.profileCouldNotBeLoadedRightNow,
          ),
        ),
      );
    }

    final updateState = ref.watch(updateProfileNotifierProvider);
    final isBusy = updateState.isLoading || _isDeletingAccount;
    final carCatalog = ref.watch(carCatalogProvider);
    final availableMakes = carCatalog.valueOrNull ?? const <CarMakeOption>[];
    final selectedMakes = _resolveSelectedCarMakes(
      profile: profile,
      catalog: availableMakes,
    );
    final selectableMakes = availableMakes
        .where((make) => !_selectedCarMakeIds.contains(make.id))
        .toList(growable: false);
    final selectedPickerMakeId =
        selectableMakes.any((make) => make.id == _selectedCarMakeId)
        ? _selectedCarMakeId
        : null;
    final isSupplierProfile = profile.role == 'supplier';
    final carCatalogErrorMessage = asyncErrorMessage(
      carCatalog.error,
      fallback: context.l10n.carCatalogCouldNotBeLoadedRightNow,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.editProfile),
        actions: const [
          Padding(
            padding: EdgeInsetsDirectional.only(end: 12),
            child: Center(child: AppLanguageMenuButton()),
          ),
        ],
      ),
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
                        context.l10n.keepYourProfileUpToDate,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isSupplierProfile
                            ? context.l10n.supplierProfileIntro
                            : context.l10n.buyerProfileIntro,
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
                        decoration: InputDecoration(
                          labelText: context.l10n.fullName,
                          hintText: context.l10n.fullNameHint,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.l10n.enterYourFullName;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneController,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: context.l10n.phone,
                          hintText: authPhoneHintText,
                        ),
                        validator: (value) {
                          return authPhoneInputError(value ?? '');
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _cityController,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: context.l10n.cityLabel,
                          hintText: context.l10n.cityOptionalHint,
                        ),
                      ),
                      if (isSupplierProfile) ...[
                        const SizedBox(height: 22),
                        Text(
                          context.l10n.carsIHavePartsFor,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.pickTheCarNamesYouSupplyPartsFor,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF6F6A63)),
                        ),
                        const SizedBox(height: 14),
                        if (selectedMakes.isEmpty)
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
                              context.l10n.noCarNamesSelectedYet,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: const Color(0xFF6F6A63)),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final make in selectedMakes)
                                _SelectedMakeChip(
                                  make: make,
                                  onRemove: () {
                                    setState(() {
                                      _selectedCarMakeIds.remove(make.id);
                                      if (_selectedCarMakeId == make.id) {
                                        _selectedCarMakeId = null;
                                      }
                                    });
                                  },
                                ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        if (carCatalog.isLoading)
                          const LinearProgressIndicator()
                        else if (carCatalog.hasError)
                          AppErrorCard(
                            message:
                                '${context.l10n.theCarCatalogCouldNotBeLoaded}\n$carCatalogErrorMessage',
                            onRetry: () => ref.invalidate(carCatalogProvider),
                          )
                        else ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  key: ValueKey(
                                    'profile-make-picker-${selectedPickerMakeId ?? 'none'}-${selectableMakes.length}',
                                  ),
                                  initialValue: selectedPickerMakeId,
                                  decoration: InputDecoration(
                                    labelText: context.l10n.carName,
                                  ),
                                  items: [
                                    for (final make in selectableMakes)
                                      DropdownMenuItem<int>(
                                        value: make.id,
                                        child: Text(make.name),
                                      ),
                                  ],
                                  onChanged: selectableMakes.isEmpty
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _selectedCarMakeId = value;
                                          });
                                        },
                                ),
                              ),
                              const SizedBox(width: 12),
                              FilledButton.tonalIcon(
                                onPressed: selectedPickerMakeId == null
                                    ? null
                                    : () {
                                        final selectedMakeId =
                                            selectedPickerMakeId;
                                        setState(() {
                                          _selectedCarMakeIds.add(
                                            selectedMakeId,
                                          );
                                          _selectedCarMakeId = null;
                                        });
                                      },
                                icon: const Icon(Icons.add_rounded),
                                label: Text(context.l10n.add),
                              ),
                            ],
                          ),
                          if (selectableMakes.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                context
                                    .l10n
                                    .allAvailableCarNamesAlreadySelected,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: const Color(0xFF6F6A63)),
                              ),
                            ),
                        ],
                      ],
                      const SizedBox(height: 20),
                      _PreferenceToggle(
                        title: context.l10n.chatPushNotifications,
                        subtitle: context.l10n.chatPushNotificationsDescription,
                        value: _chatPushEnabled,
                        onChanged: (value) {
                          setState(() => _chatPushEnabled = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      _PreferenceToggle(
                        title: context.l10n.showMessagePreview,
                        subtitle: context.l10n.showMessagePreviewDescription,
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
                                    ? context.l10n.saving
                                    : context.l10n.saveChanges,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _AccountActionsCard(isBusy: isBusy, onLogout: _logout),
                      const SizedBox(height: 16),
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
          phone: normalizePhoneForAuth(_phoneController.text),
          city: _cityController.text,
          chatPushEnabled: _chatPushEnabled,
          chatMessagePreviewEnabled: _chatMessagePreviewEnabled,
          supportedCarModelIds: profile.role == 'supplier'
              ? _resolveSelectedCarModelIdsFromMakes(
                  profile: profile,
                  catalog:
                      ref.read(carCatalogProvider).valueOrNull ??
                      const <CarMakeOption>[],
                )
              : null,
          avatarImage: _selectedAvatarImage,
        );

    if (updatedProfile == null || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.profileUpdatedSuccessfully)),
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

  Future<void> _logout() async {
    if (_isDeletingAccount) {
      return;
    }
    await ref.read(logoutNotifierProvider.notifier).logout();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmDeleteAccount() async {
    if (_isDeletingAccount) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.deleteAccountTitle),
          content: Text(context.l10n.deleteAccountPermanentMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB42318),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.l10n.deleteAccountTitle),
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
        SnackBar(content: Text(context.l10n.accountDeletedSuccessfully)),
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
        () =>
            _deleteAccountError = context.l10n.accountCouldNotBeDeletedRightNow,
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
    _selectedCarMakeIds
      ..clear()
      ..addAll(profile.supportedCarModels.map((item) => item.makeId));
    if (profile.supportedCarModels.isNotEmpty) {
      _selectedCarMakeId = null;
    }
  }

  List<CarMakeOption> _resolveSelectedCarMakes({
    required MeProfile profile,
    required List<CarMakeOption> catalog,
  }) {
    final profileMakesById = <int, CarMakeOption>{
      for (final model in profile.supportedCarModels)
        model.makeId: CarMakeOption(
          id: model.makeId,
          name: model.makeName,
          slug: '',
          models: profile.supportedCarModels
              .where((item) => item.makeId == model.makeId)
              .toList(growable: false),
        ),
    };

    final selectedMakes = <CarMakeOption>[];
    for (final makeId in _selectedCarMakeIds) {
      final resolvedMake = _findMakeById(catalog, makeId);
      if (resolvedMake != null) {
        selectedMakes.add(resolvedMake);
        continue;
      }
      final profileMake = profileMakesById[makeId];
      if (profileMake != null) {
        selectedMakes.add(profileMake);
      }
    }
    selectedMakes.sort((left, right) => left.name.compareTo(right.name));
    return selectedMakes;
  }

  CarMakeOption? _findMakeById(List<CarMakeOption> makes, int makeId) {
    for (final make in makes) {
      if (make.id == makeId) {
        return make;
      }
    }
    return null;
  }

  List<int> _resolveSelectedCarModelIdsFromMakes({
    required MeProfile profile,
    required List<CarMakeOption> catalog,
  }) {
    final modelIds = <int>{
      for (final make in catalog)
        if (_selectedCarMakeIds.contains(make.id))
          ...make.models.map((model) => model.id),
      for (final model in profile.supportedCarModels)
        if (_selectedCarMakeIds.contains(model.makeId)) model.id,
    };
    return modelIds.toList()..sort();
  }
}

class _SelectedMakeChip extends StatelessWidget {
  const _SelectedMakeChip({required this.make, required this.onRemove});

  final CarMakeOption make;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F8F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD5E8E4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.directions_car_filled_rounded,
            size: 18,
            color: Color(0xFF1F6FEB),
          ),
          const SizedBox(width: 8),
          Text(
            make.name,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: context.l10n.remove,
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _AccountActionsCard extends StatelessWidget {
  const _AccountActionsCard({required this.isBusy, required this.onLogout});

  final bool isBusy;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.accountActions,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.logoutDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF667085),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: isBusy
                ? null
                : () {
                    onLogout();
                  },
            icon: const Icon(Icons.logout_rounded),
            label: Text(context.l10n.logout),
          ),
        ],
      ),
    );
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
          _MetaPill(icon: Icons.phone_outlined, label: profile.phone ?? ''),
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
                  context.l10n.profilePhoto,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasPendingPhoto
                      ? context.l10n.newPhotoReadyMessage
                      : context.l10n.choosePhotoForRequestsAndChats,
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
                            ? context.l10n.chooseAnotherPhoto
                            : context.l10n.changePhoto,
                      ),
                    ),
                    if (hasPendingPhoto)
                      TextButton(
                        onPressed: onClearSelection,
                        child: Text(context.l10n.undoPhotoChange),
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
            context.l10n.deleteAccountTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFFB42318),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.deleteAccountDangerDescription,
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
            label: Text(
              isBusy
                  ? context.l10n.pleaseWait
                  : context.l10n.deleteAccountTitle,
            ),
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
