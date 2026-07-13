import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../constants/api_constants.dart';
import '../../controllers/providers/api_provider.dart';
import '../../controllers/providers/catalog_provider.dart';
import '../../controllers/providers/request_provider.dart';
import '../../controllers/statuses/request_state.dart';
import '../../localization/app_localizations_x.dart';
import '../../models/models.dart';
import '../common_widgets/app_error_card.dart';
import '../common_widgets/app_panel.dart';
import '../common_widgets/async_error_message.dart';
import '../common_widgets/car_model_card.dart';

class CreateRequestPage extends ConsumerStatefulWidget {
  const CreateRequestPage({
    super.key,
    this.initialRequest,
    this.onNavigateToMyRequests,
  });

  final PartRequest? initialRequest;
  final VoidCallback? onNavigateToMyRequests;

  bool get isEditing => initialRequest != null;

  @override
  ConsumerState<CreateRequestPage> createState() => _CreateRequestPageState();
}

class _CreateRequestPageState extends ConsumerState<CreateRequestPage> {
  static const int _requestImageQuality = 82;
  static const double _requestImageMaxDimension = 1600;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _customCarMakeController = TextEditingController();
  final _customCarModelController = TextEditingController();
  final _carModelSearchController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  List<PartImage> _existingImages = const [];
  List<RequestUploadImage> _selectedImages = const [];
  List<CarModelOption> _carModelSearchResults = const [];
  int? _selectedCarMakeId;
  int? _selectedCarModelId;
  String? _carSelectionError;
  String? _carModelSearchError;
  Timer? _carModelSearchTimer;
  int _carModelSearchGeneration = 0;
  bool _isCarModelSearchLoading = false;
  bool _useCustomCarEntry = false;

  @override
  void initState() {
    super.initState();
    final initialRequest = widget.initialRequest;
    if (initialRequest != null) {
      _titleController.text = initialRequest.title;
      _descriptionController.text = initialRequest.description;
      _cityController.text = initialRequest.city ?? '';
      _minPriceController.text = initialRequest.minPrice ?? '';
      _maxPriceController.text = initialRequest.maxPrice ?? '';
      _existingImages = List<PartImage>.from(initialRequest.images);
      _selectedCarMakeId = initialRequest.carModel?.makeId;
      _selectedCarModelId = initialRequest.carModelId;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(carCatalogProvider);
      ref
          .read(createRequestNotifierProvider.notifier)
          .loadStatuses(preferredStatusId: initialRequest?.status);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _customCarMakeController.dispose();
    _customCarModelController.dispose();
    _carModelSearchTimer?.cancel();
    _carModelSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CreateRequestState>(createRequestNotifierProvider, (
      previous,
      next,
    ) {
      final request = next.createdRequest;
      if (request == null || previous?.createdRequest?.id == request.id) {
        return;
      }

      if (widget.isEditing) {
        ref.read(requestsNotifierProvider.notifier).replaceRequest(request);
      } else {
        ref.read(requestsNotifierProvider.notifier).prependRequest(request);
      }
      ref
          .read(requestsNotifierProvider.notifier)
          .setSegment(RequestSegment.mine);
      ref.read(createRequestNotifierProvider.notifier).clearCreatedRequest();

      _showTopBanner(
        message: widget.isEditing
            ? context.l10n.requestUpdatedSuccessfully
            : context.l10n.requestCreatedSuccessfully,
        isSuccess: true,
        showMyRequestsAction: !widget.isEditing,
      );

      if (widget.isEditing || widget.onNavigateToMyRequests == null) {
        Navigator.of(context).pop();
        return;
      }

      _resetCreateForm();
    });

    ref.listen<CreateRequestState>(createRequestNotifierProvider, (
      previous,
      next,
    ) {
      final errorMessage = next.errorMessage;
      if (errorMessage == null ||
          errorMessage == previous?.errorMessage ||
          next.isSubmitting) {
        return;
      }

      _showTopBanner(message: errorMessage, isSuccess: false);
    });

    final createState = ref.watch(createRequestNotifierProvider);
    final l10n = context.l10n;
    final carCatalog = ref.watch(carCatalogProvider);
    final availableMakes = carCatalog.valueOrNull ?? const <CarMakeOption>[];
    final selectedMake = _selectedCarMakeId != null
        ? _findMakeById(availableMakes, _selectedCarMakeId!)
        : (availableMakes.isEmpty ? null : availableMakes.first);
    final selectedCarModel = _selectedCarModelId == null
        ? null
        : _findModelById(availableMakes, _selectedCarModelId!);
    final carModelSearchQuery = _carModelSearchController.text.trim();
    final isSearchingCarModels = carModelSearchQuery.length >= 2;
    final visibleModels = isSearchingCarModels
        ? _carModelSearchResults
        : selectedMake?.models ?? const <CarModelOption>[];
    final currentUserId = ref.watch(currentUserIdProvider);
    final carCatalogErrorMessage = asyncErrorMessage(
      carCatalog.error,
      fallback: l10n.carCatalogCouldNotBeLoadedRightNow,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? l10n.editRequestTitle : l10n.createRequestTitle,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: AppPanel(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.isEditing
                            ? l10n.updateYourRequest
                            : l10n.postNewRequest,

                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF111827),
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.isEditing
                            ? l10n.editRequestDescription
                            : l10n.createRequestDescription,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF667085),
                          height: 1.35,
                        ),
                      ),
                      if (!widget.isEditing) ...[
                        const SizedBox(height: 16),
                        _RequestExpiryNotice(
                          message: l10n.requestExpiresAfter48Hours,
                        ),
                      ],
                      const SizedBox(height: 16),
                      _RequestStepHeader(
                        icon: Icons.build_circle_outlined,
                        title: l10n.requestTitleLabel,
                        message: l10n.createRequestDescription,
                      ),
                      const SizedBox(height: 16),
                      if (createState.errorMessage != null) ...[
                        AppErrorCard(message: createState.errorMessage!),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _titleController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.requestTitleLabel,
                          hintText: l10n.requestTitleHint,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.enterRequestTitle;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _descriptionController,
                        textInputAction: TextInputAction.newline,
                        minLines: 4,
                        maxLines: 6,
                        decoration: InputDecoration(
                          labelText: l10n.requestDescriptionLabel,
                          hintText: l10n.requestDescriptionHint,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.addShortDescription;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      Text(
                        l10n.carModelLabel,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.carModelDescription,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF667085),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (!_useCustomCarEntry &&
                          !carCatalog.isLoading &&
                          !carCatalog.hasError) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF0FE),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 1.4,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.manage_search_rounded,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.carModelSearchLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _carModelSearchController,
                                textInputAction: TextInputAction.search,
                                decoration: InputDecoration(
                                  labelText: l10n.carModelSearchLabel,
                                  hintText: l10n.carModelSearchHint,
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: carModelSearchQuery.isEmpty
                                      ? null
                                      : IconButton(
                                          tooltip: l10n.clearCarModelSearch,
                                          onPressed: _clearCarModelSearch,
                                          icon: const Icon(Icons.close_rounded),
                                        ),
                                ),
                                onChanged: _scheduleCarModelSearch,
                                onFieldSubmitted: (value) =>
                                    _runCarModelSearch(value.trim()),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF1C38B)),
                        ),
                        child: SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _useCustomCarEntry,
                          title: Text(l10n.addCarManually),
                          subtitle: Text(l10n.addCarManuallyDescription),
                          onChanged: (value) {
                            setState(() {
                              _useCustomCarEntry = value;
                              _carSelectionError = null;
                              if (value) {
                                _selectedCarMakeId = null;
                                _selectedCarModelId = null;
                                _carModelSearchController.clear();
                                _carModelSearchResults = const [];
                                _isCarModelSearchLoading = false;
                                _carModelSearchError = null;
                              } else {
                                _customCarMakeController.clear();
                                _customCarModelController.clear();
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (!_useCustomCarEntry && selectedCarModel != null) ...[
                        CarModelCard(
                          carModel: selectedCarModel,
                          compact: true,
                          isSelected: true,
                          showImage: false,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_carSelectionError != null) ...[
                        AppErrorCard(message: _carSelectionError!),
                        const SizedBox(height: 12),
                      ],
                      if (_useCustomCarEntry) ...[
                        TextFormField(
                          controller: _customCarMakeController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l10n.newCarMakeLabel,
                            hintText: l10n.newCarMakeHint,
                          ),
                          validator: (value) {
                            if (!_useCustomCarEntry) {
                              return null;
                            }
                            if (value == null || value.trim().isEmpty) {
                              return l10n.enterCarMake;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _customCarModelController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l10n.newCarModelLabel,
                            hintText: l10n.newCarModelHint,
                          ),
                          validator: (value) {
                            if (!_useCustomCarEntry) {
                              return null;
                            }
                            if (value == null || value.trim().isEmpty) {
                              return l10n.enterCarModel;
                            }
                            return null;
                          },
                        ),
                      ] else if (carCatalog.isLoading)
                        const LinearProgressIndicator()
                      else if (carCatalog.hasError)
                        AppErrorCard(
                          message:
                              '${l10n.theCarCatalogCouldNotBeLoaded}\n$carCatalogErrorMessage',
                          onRetry: () => ref.invalidate(carCatalogProvider),
                        )
                      else ...[
                        if (_isCarModelSearchLoading) ...[
                          const LinearProgressIndicator(),
                          const SizedBox(height: 10),
                        ],
                        if (_carModelSearchError != null) ...[
                          const SizedBox(height: 10),
                          AppErrorCard(message: _carModelSearchError!),
                        ],
                        const SizedBox(height: 14),
                        DropdownButtonFormField<int>(
                          initialValue: selectedMake?.id,
                          isExpanded: true,
                          itemHeight: _dropdownItemHeight(context),
                          decoration: InputDecoration(
                            labelText: l10n.carMakeLabel,
                            contentPadding: _dropdownContentPadding(context),
                          ),
                          items: [
                            for (final make in availableMakes)
                              DropdownMenuItem<int>(
                                value: make.id,
                                child: Text(
                                  make.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) {
                            final nextMake = value == null
                                ? null
                                : _findMakeById(availableMakes, value);
                            setState(() {
                              _selectedCarMakeId = value;
                              _carSelectionError = null;
                              if (nextMake == null ||
                                  !nextMake.models.any(
                                    (model) => model.id == _selectedCarModelId,
                                  )) {
                                _selectedCarModelId = null;
                              }
                            });
                            if (_carModelSearchController.text.trim().length >=
                                2) {
                              _scheduleCarModelSearch(
                                _carModelSearchController.text,
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        if (isSearchingCarModels &&
                            !_isCarModelSearchLoading &&
                            visibleModels.isEmpty)
                          const _CarModelSearchEmptyState()
                        else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = _carGridCrossAxisCount();
                              final cardWidth =
                                  (constraints.maxWidth -
                                      ((crossAxisCount - 1) * 12)) /
                                  crossAxisCount;

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: visibleModels.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      mainAxisExtent: _carCardMainAxisExtent(
                                        context,
                                        cardWidth,
                                        showImage: false,
                                      ),
                                    ),
                                itemBuilder: (context, index) {
                                  final carModel = visibleModels[index];
                                  return CarModelCard(
                                    carModel: carModel,
                                    isSelected:
                                        carModel.id == _selectedCarModelId,
                                    showImage: false,
                                    onTap: () => _selectCarModel(carModel),
                                  );
                                },
                              );
                            },
                          ),
                      ],
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _cityController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.cityOptionalLabel,
                          hintText: l10n.cityOptionalHint,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: createState.isSubmitting
                                  ? null
                                  : _pickImages,
                              icon: const Icon(Icons.photo_library_outlined),
                              label: Text(
                                _selectedImages.isEmpty
                                    ? l10n.addPhotos
                                    : l10n.addMorePhotos,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_existingImages.isNotEmpty ||
                          _selectedImages.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 92,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount:
                                _existingImages.length + _selectedImages.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              if (index < _existingImages.length) {
                                final image = _existingImages[index];
                                return _ExistingRequestImageCard(
                                  image: image,
                                  onRemove: () => _removeExistingImage(image),
                                );
                              }

                              final image =
                                  _selectedImages[index -
                                      _existingImages.length];
                              return _SelectedRequestImageCard(
                                image: image,
                                onRemove: () => _removeSelectedImage(image),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      // Row(
                      //   children: [
                      //     Expanded(
                      //       child: TextFormField(
                      //         controller: _minPriceController,
                      //         keyboardType:
                      //             const TextInputType.numberWithOptions(
                      //               decimal: true,
                      //             ),
                      //         decoration: InputDecoration(
                      //           labelText: l10n.minPriceLabel,
                      //           hintText: '150',
                      //         ),
                      //         validator: _validateOptionalNumber,
                      //       ),
                      //     ),
                      //     const SizedBox(width: 14),
                      //     Expanded(
                      //       child: TextFormField(
                      //         controller: _maxPriceController,
                      //         keyboardType:
                      //             const TextInputType.numberWithOptions(
                      //               decimal: true,
                      //             ),
                      //         decoration: InputDecoration(
                      //           labelText: l10n.maxPriceLabel,
                      //           hintText: '350',
                      //         ),
                      //         validator: (value) {
                      //           final numberError = _validateOptionalNumber(
                      //             value,
                      //           );
                      //           if (numberError != null) {
                      //             return numberError;
                      //           }
                      //
                      //           final minValue = double.tryParse(
                      //             _minPriceController.text.trim(),
                      //           );
                      //           final maxValue = double.tryParse(
                      //             value?.trim() ?? '',
                      //           );
                      //           if (minValue != null &&
                      //               maxValue != null &&
                      //               maxValue < minValue) {
                      //             return l10n.maxPriceMustBeGreaterThanMinPrice;
                      //           }
                      //           return null;
                      //         },
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed:
                                  createState.canSubmit &&
                                      currentUserId != null &&
                                      !createState.isSubmitting
                                  ? _submit
                                  : null,
                              child: Text(
                                createState.isSubmitting
                                    ? widget.isEditing
                                          ? l10n.saving
                                          : l10n.creating
                                    : widget.isEditing
                                    ? l10n.saveChanges
                                    : l10n.createRequest,
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

  // String? _validateOptionalNumber(String? value) {
  //   final trimmed = value?.trim() ?? '';
  //   if (trimmed.isEmpty) {
  //     return null;
  //   }
  //   return double.tryParse(trimmed) == null
  //       ? context.l10n.enterValidNumber
  //       : null;
  // }

  static int _carGridCrossAxisCount() => 2;

  double _carCardMainAxisExtent(
    BuildContext context,
    double cardWidth, {
    required bool showImage,
  }) {
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1);
    final scaledTextAllowance = (textScaleFactor - 1).clamp(0.0, 1.0) * 48;
    if (!showImage) {
      return (92 + scaledTextAllowance).clamp(92.0, 140.0);
    }
    return (cardWidth * 1.22 + scaledTextAllowance).clamp(218.0, 300.0);
  }

  double _dropdownItemHeight(BuildContext context) {
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1);
    return (56 * textScaleFactor).clamp(56.0, 72.0);
  }

  EdgeInsets _dropdownContentPadding(BuildContext context) {
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1);
    final verticalPadding = (16 * textScaleFactor).clamp(16.0, 22.0);
    return EdgeInsets.symmetric(horizontal: 12, vertical: verticalPadding);
  }

  void _showTopBanner({
    required String message,
    required bool isSuccess,
    bool showMyRequestsAction = false,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentMaterialBanner();
    messenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor: isSuccess
            ? const Color(0xFFE8F4EA)
            : const Color(0xFFFCE8E5),
        content: Text(
          message,
          style: TextStyle(
            color: isSuccess
                ? const Color(0xFF1E5E33)
                : const Color(0xFF8A2D1F),
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: Icon(
          isSuccess ? Icons.check_circle_outline : Icons.error_outline,
          color: isSuccess ? const Color(0xFF1E5E33) : const Color(0xFF8A2D1F),
        ),
        actions: [
          if (showMyRequestsAction && widget.onNavigateToMyRequests != null)
            TextButton(
              onPressed: () {
                messenger.hideCurrentMaterialBanner();
                widget.onNavigateToMyRequests?.call();
              },
              child: Text(context.l10n.viewMyRequests),
            ),
          TextButton(
            onPressed: messenger.hideCurrentMaterialBanner,
            child: Text(context.l10n.dismiss),
          ),
        ],
      ),
    );
  }

  void _resetCreateForm() {
    _titleController.clear();
    _descriptionController.clear();
    _cityController.clear();
    _minPriceController.clear();
    _maxPriceController.clear();
    final notifier = ref.read(createRequestNotifierProvider.notifier);

    setState(() {
      _existingImages = const [];
      _selectedImages = const [];
      _carSelectionError = null;
      _selectedCarMakeId = null;
      _selectedCarModelId = null;
      _useCustomCarEntry = false;
      _carModelSearchResults = const [];
      _isCarModelSearchLoading = false;
      _carModelSearchError = null;
    });
    _customCarMakeController.clear();
    _customCarModelController.clear();
    _carModelSearchController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.invalidate(carCatalogProvider);
      notifier.loadStatuses();
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final requesterId = ref.read(currentUserIdProvider);
    if (requesterId == null) {
      return;
    }
    final selectedCarModelId = _selectedCarModelId;
    final customCarMake = _customCarMakeController.text.trim();
    final customCarModel = _customCarModelController.text.trim();
    final hasCustomCarEntry = _useCustomCarEntry;

    if (!hasCustomCarEntry && selectedCarModelId == null) {
      setState(() {
        _carSelectionError = context.l10n.chooseCarModelBeforeSaving;
      });
      return;
    }
    if (hasCustomCarEntry &&
        (customCarMake.isEmpty || customCarModel.isEmpty)) {
      setState(() {
        _carSelectionError = context.l10n.enterCarMakeAndModelBeforeSaving;
      });
      return;
    }

    final notifier = ref.read(createRequestNotifierProvider.notifier);
    final initialRequest = widget.initialRequest;
    if (initialRequest != null && initialRequest.id != null) {
      notifier.update(
        requestId: initialRequest.id!,
        requesterId: requesterId,
        title: _titleController.text,
        description: _descriptionController.text,
        carModelId: hasCustomCarEntry ? null : selectedCarModelId,
        customCarMake: hasCustomCarEntry ? customCarMake : null,
        customCarModel: hasCustomCarEntry ? customCarModel : null,
        city: _cityController.text,
        minPrice: _minPriceController.text,
        maxPrice: _maxPriceController.text,
        keepImageIds: _existingImages
            .map((image) => image.id)
            .whereType<int>()
            .toList(growable: false),
        newImages: _selectedImages,
      );
      return;
    }

    notifier.create(
      requesterId: requesterId,
      title: _titleController.text,
      description: _descriptionController.text,
      carModelId: hasCustomCarEntry ? null : selectedCarModelId,
      customCarMake: hasCustomCarEntry ? customCarMake : null,
      customCarModel: hasCustomCarEntry ? customCarModel : null,
      city: _cityController.text,
      minPrice: _minPriceController.text,
      maxPrice: _maxPriceController.text,
      images: _selectedImages,
    );
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _imagePicker.pickMultiImage(
      imageQuality: _requestImageQuality,
      maxWidth: _requestImageMaxDimension,
      maxHeight: _requestImageMaxDimension,
    );
    if (!mounted || pickedFiles.isEmpty) {
      return;
    }

    final nextImages = <RequestUploadImage>[
      ..._selectedImages,
      for (final file in pickedFiles)
        RequestUploadImage(
          path: file.path,
          fileName: file.name,
          contentType: lookupMimeType(file.path) ?? 'image/jpeg',
        ),
    ];

    setState(() => _selectedImages = nextImages);
  }

  void _removeSelectedImage(RequestUploadImage image) {
    setState(() {
      _selectedImages = _selectedImages
          .where((item) => item.path != image.path)
          .toList(growable: false);
    });
  }

  void _removeExistingImage(PartImage image) {
    setState(() {
      _existingImages = _existingImages
          .where((item) => item.id != image.id)
          .toList(growable: false);
    });
  }

  void _selectCarModel(CarModelOption carModel) {
    setState(() {
      _selectedCarMakeId = carModel.makeId;
      _selectedCarModelId = carModel.id;
      _carSelectionError = null;
    });
  }

  void _clearCarModelSearch() {
    _carModelSearchTimer?.cancel();
    _carModelSearchGeneration++;
    setState(() {
      _carModelSearchController.clear();
      _carModelSearchResults = const [];
      _isCarModelSearchLoading = false;
      _carModelSearchError = null;
    });
  }

  void _scheduleCarModelSearch(String value) {
    _carModelSearchTimer?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      _carModelSearchGeneration++;
      setState(() {
        _carModelSearchResults = const [];
        _isCarModelSearchLoading = false;
        _carModelSearchError = null;
      });
      return;
    }

    _carModelSearchTimer = Timer(
      const Duration(seconds: 1),
      () => _runCarModelSearch(query),
    );
  }

  Future<void> _runCarModelSearch(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.length < 2) {
      return;
    }

    final generation = ++_carModelSearchGeneration;
    final detectedMakeId = _detectMakeIdFromSearch(normalizedQuery);
    final makeId = detectedMakeId ?? _selectedCarMakeId;
    setState(() {
      _isCarModelSearchLoading = true;
      _carModelSearchError = null;
      if (detectedMakeId != null) {
        _selectedCarMakeId = detectedMakeId;
      }
    });

    try {
      final results = await ref
          .read(catalogApiProvider)
          .searchCarModels(query: normalizedQuery, makeId: makeId);
      if (!mounted || generation != _carModelSearchGeneration) {
        return;
      }
      setState(() {
        _carModelSearchResults = results;
        _isCarModelSearchLoading = false;
      });
    } catch (_) {
      if (!mounted || generation != _carModelSearchGeneration) {
        return;
      }
      setState(() {
        _isCarModelSearchLoading = false;
        _carModelSearchError = context.l10n.carModelSearchFailed;
      });
    }
  }

  int? _detectMakeIdFromSearch(String query) {
    final normalizedQuery = _normalizeSearchText(query);
    final makes = ref.read(carCatalogProvider).valueOrNull ?? const [];
    for (final make in makes) {
      final normalizedMakeName = _normalizeSearchText(make.name);
      final normalizedMakeSlug = _normalizeSearchText(make.slug);
      if (normalizedMakeName.isNotEmpty &&
          normalizedQuery.contains(normalizedMakeName)) {
        return make.id;
      }
      if (normalizedMakeSlug.isNotEmpty &&
          normalizedQuery.contains(normalizedMakeSlug)) {
        return make.id;
      }
    }
    return null;
  }

  String _normalizeSearchText(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  CarMakeOption? _findMakeById(List<CarMakeOption> makes, int makeId) {
    for (final make in makes) {
      if (make.id == makeId) {
        return make;
      }
    }
    return null;
  }

  CarModelOption? _findModelById(List<CarMakeOption> makes, int modelId) {
    for (final make in makes) {
      for (final model in make.models) {
        if (model.id == modelId) {
          return model;
        }
      }
    }
    return null;
  }
}

class _RequestExpiryNotice extends StatelessWidget {
  const _RequestExpiryNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.schedule_outlined, color: Color(0xFF1D4ED8)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF1E3A8A),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarModelSearchEmptyState extends StatelessWidget {
  const _CarModelSearchEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7DFD2)),
      ),
      child: Text(
        context.l10n.noMatchingCarModelsFound,
        style: const TextStyle(
          color: Color(0xFF6F6A63),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RequestStepHeader extends StatelessWidget {
  const _RequestStepHeader({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC7D7FE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF1F6FEB)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF475467),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// enum _NoticeTone { info, warning }

// class _StatusNotice extends StatelessWidget {
//   const _StatusNotice({
//     required this.title,
//     required this.message,
//     required this.tone,
//   });
//
//   final String title;
//   final String message;
//   final _NoticeTone tone;
//
//   @override
//   Widget build(BuildContext context) {
//     final isWarning = tone == _NoticeTone.warning;
//     final background = isWarning
//         ? const Color(0xFFFFF3E7)
//         : const Color(0xFFF2F8F7);
//     final border = isWarning
//         ? const Color(0xFFF1C38B)
//         : const Color(0xFFD5E8E4);
//     final accent = isWarning
//         ? const Color(0xFFB35B00)
//         : const Color(0xFF0C4A63);
//
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: background,
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: border),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: Theme.of(context).textTheme.titleMedium?.copyWith(
//               fontWeight: FontWeight.w800,
//               color: accent,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             message,
//             style: Theme.of(
//               context,
//             ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6F6A63)),
//           ),
//         ],
//       ),
//     );
//   }
// }

class _SelectedRequestImageCard extends StatelessWidget {
  const _SelectedRequestImageCard({
    required this.image,
    required this.onRemove,
  });

  final RequestUploadImage image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 92,
            height: 92,
            child: Image.file(File(image.path), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.54),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExistingRequestImageCard extends StatelessWidget {
  const _ExistingRequestImageCard({
    required this.image,
    required this.onRemove,
  });

  final PartImage image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 92,
            height: 92,
            child: Image.network(
              ApiConstants.resolveUrl(image.image),
              fit: BoxFit.cover,
              headers: const {
                ApiConstants.ngrokHeaderKey: ApiConstants.ngrokHeaderValue,
              },
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.54),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
