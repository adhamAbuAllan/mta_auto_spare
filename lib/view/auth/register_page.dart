import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers/auth_provider.dart';
import '../../controllers/providers/catalog_provider.dart';
import '../../localization/app_localizations_x.dart';
import '../../localization/language_selector.dart';
import '../../models/models.dart';
import '../../utils/phone_number.dart';
import '../common_widgets/app_error_card.dart';
import '../common_widgets/async_error_message.dart';
import '../common_widgets/privacy_policy_link.dart';
import 'phone_otp_page.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = 'user';
  final Set<int> _selectedCarMakeIds = <int>{};
  int? _selectedCarMakeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(registerNotifierProvider.notifier).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final phoneController = ref.watch(registerPhoneControllerProvider);
    final nameController = ref.watch(registerNameControllerProvider);
    final passwordController = ref.watch(registerPasswordControllerProvider);
    final carCatalog = ref.watch(carCatalogProvider);
    final availableMakes = carCatalog.valueOrNull ?? const <CarMakeOption>[];
    final selectedMakes = _resolveSelectedCarMakes(catalog: availableMakes);
    final selectableMakes = availableMakes
        .where((make) => !_selectedCarMakeIds.contains(make.id))
        .toList(growable: false);
    final carCatalogErrorMessage = asyncErrorMessage(
      carCatalog.error,
      fallback: context.l10n.carCatalogCouldNotBeLoadedRightNow,
    );
    final showCarSelection = _selectedRole == 'supplier';

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.createAccount),
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
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.setUpMarketplaceProfile,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF111827),
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.l10n.suppliersCanPostRequests,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF667085),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      context.l10n.accountRole,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment<String>(
                          value: 'user',
                          label: Text(context.l10n.userRole),
                          icon: Icon(Icons.person_search_outlined),
                        ),
                        ButtonSegment<String>(
                          value: 'supplier',
                          label: Text(context.l10n.supplierRole),
                          icon: Icon(Icons.handyman_outlined),
                        ),
                      ],
                      selected: {_selectedRole},
                      onSelectionChanged: (selection) {
                        setState(() => _selectedRole = selection.first);
                      },
                    ),
                    const SizedBox(height: 18),
                    if (showCarSelection) ...[
                      Text(
                        context.l10n.carsIHavePartsFor,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.pickTheCarNamesYouSupplyPartsFor,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF667085),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (selectedMakes.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F3EC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE4E7EC)),
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
                        SizedBox(
                          height: 120,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  key: ValueKey(
                                    'make-picker-${_selectedCarMakeId ?? 'none'}-${selectableMakes.length}',
                                  ),
                                  initialValue: _selectedCarMakeId,
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
                                onPressed: _selectedCarMakeId == null
                                    ? null
                                    : () {
                                        final selectedMakeId =
                                            _selectedCarMakeId;
                                        if (selectedMakeId == null) {
                                          return;
                                        }
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
                        ),
                        if (selectableMakes.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              context.l10n.allAvailableCarNamesAlreadySelected,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: const Color(0xFF6F6A63)),
                            ),
                          ),
                      ],
                      const SizedBox(height: 18),
                    ],
                    TextFormField(
                      controller: nameController,
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
                      controller: phoneController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.telephoneNumber],
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
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: context.l10n.password,
                        hintText: context.l10n.passwordMinHint,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.l10n.enterPassword;
                        }
                        if (value.length < 6) {
                          return context.l10n.useAtLeastSixCharacters;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: _submit,
                            child: Text(context.l10n.createAccount),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const PrivacyPolicyLink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final phone = normalizePhoneForAuth(
      ref.read(registerPhoneControllerProvider).text,
    );
    final draft = PhoneRegistrationDraft(
      phone: phone,
      name: ref.read(registerNameControllerProvider).text.trim(),
      password: ref.read(registerPasswordControllerProvider).text,
      role: _selectedRole,
      supportedCarModelIds: _selectedRole == 'supplier'
          ? _resolveSelectedCarModelIdsFromMakes(
              catalog:
                  ref.read(carCatalogProvider).valueOrNull ??
                  const <CarMakeOption>[],
            )
          : null,
    );

    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => PhoneOtpPage(draft: draft)));
  }

  CarMakeOption? _findMakeById(List<CarMakeOption> makes, int makeId) {
    for (final make in makes) {
      if (make.id == makeId) {
        return make;
      }
    }
    return null;
  }

  List<CarMakeOption> _resolveSelectedCarMakes({
    required List<CarMakeOption> catalog,
  }) {
    final selectedMakes = <CarMakeOption>[];
    for (final makeId in _selectedCarMakeIds) {
      final resolvedMake = _findMakeById(catalog, makeId);
      if (resolvedMake != null) {
        selectedMakes.add(resolvedMake);
      }
    }
    selectedMakes.sort((left, right) => left.name.compareTo(right.name));
    return selectedMakes;
  }

  List<int> _resolveSelectedCarModelIdsFromMakes({
    required List<CarMakeOption> catalog,
  }) {
    final modelIds = <int>{
      for (final make in catalog)
        if (_selectedCarMakeIds.contains(make.id))
          ...make.models.map((model) => model.id),
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
            color: Color(0xFF027A48),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                make.name,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
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
