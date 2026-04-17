import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers/auth_provider.dart';
import '../../controllers/providers/catalog_provider.dart';
import '../../models/models.dart';
import '../common_widgets/app_error_card.dart';
import '../common_widgets/app_panel.dart';
import '../common_widgets/async_error_message.dart';
import '../common_widgets/car_model_card.dart';

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
