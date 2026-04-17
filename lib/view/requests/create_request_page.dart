import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../constants/api_constants.dart';
import '../../controllers/providers/catalog_provider.dart';
import '../../controllers/providers/request_provider.dart';
import '../../controllers/statuses/request_state.dart';
import '../../models/models.dart';
import '../common_widgets/app_error_card.dart';
import '../common_widgets/app_panel.dart';
import '../common_widgets/async_error_message.dart';
import '../common_widgets/car_model_card.dart';

class CreateRequestPage extends ConsumerStatefulWidget {
  const CreateRequestPage({super.key, this.initialRequest});

  final PartRequest? initialRequest;

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
  final ImagePicker _imagePicker = ImagePicker();

  List<PartImage> _existingImages = const [];
  List<RequestUploadImage> _selectedImages = const [];
  int? _selectedCarMakeId;
  int? _selectedCarModelId;
  String? _carSelectionError;

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Request updated successfully.'
                : 'Request created successfully.',
          ),
        ),
      );
      Navigator.of(context).pop();
    });

    final createState = ref.watch(createRequestNotifierProvider);
    final carCatalog = ref.watch(carCatalogProvider);
    final availableMakes = carCatalog.valueOrNull ?? const <CarMakeOption>[];
    final selectedMake =
        _selectedCarMakeId != null
        ? _findMakeById(availableMakes, _selectedCarMakeId!)
        : (availableMakes.isEmpty ? null : availableMakes.first);
    final visibleModels = selectedMake?.models ?? const <CarModelOption>[];
    final selectedCarModel =
        _selectedCarModelId == null
        ? null
        : _findModelById(availableMakes, _selectedCarModelId!);
    final currentUserId = ref.watch(currentUserIdProvider);
    final carCatalogErrorMessage = asyncErrorMessage(
      carCatalog.error,
      fallback: 'The car catalog could not be loaded right now.',
    );
    PartRequestStatus? selectedStatus;
    for (final status in createState.statuses) {
      if (status.id == createState.selectedStatusId) {
        selectedStatus = status;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Request' : 'Create Request'),
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
                        widget.isEditing
                            ? 'Update your request'
                            : 'Post a new request',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.isEditing
                            ? 'Refresh the request details and the photos you want buyers to see.'
                            : 'Create a request that buyers can browse and open chats from.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF6F6A63),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (createState.isLoadingStatuses)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: LinearProgressIndicator(),
                        ),
                      if (createState.blockedMessage != null) ...[
                        _StatusNotice(
                          title: 'Request creation is blocked',
                          message: createState.blockedMessage!,
                          tone: _NoticeTone.warning,
                        ),
                        const SizedBox(height: 16),
                      ] else if (selectedStatus != null) ...[
                        _StatusNotice(
                          title: widget.isEditing
                              ? 'Current status'
                              : 'Initial status',
                          message: widget.isEditing
                              ? 'This request is currently marked as "${selectedStatus.label}".'
                              : 'New requests will start as "${selectedStatus.label}".',
                          tone: _NoticeTone.info,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (createState.errorMessage != null) ...[
                        AppErrorCard(message: createState.errorMessage!),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _titleController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Request title',
                          hintText: 'Front bumper for Toyota Camry 2022',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter a request title.';
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
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText:
                              'Describe the condition, brand preference, or model details buyers should know.',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Add a short description.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Car model',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose the exact car model this request is for so only matching buyers get notified.',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: const Color(0xFF6F6A63)),
                      ),
                      const SizedBox(height: 14),
                      if (selectedCarModel != null) ...[
                        CarModelCard(
                          carModel: selectedCarModel,
                          compact: true,
                          isSelected: true,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_carSelectionError != null) ...[
                        AppErrorCard(message: _carSelectionError!),
                        const SizedBox(height: 12),
                      ],
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
                            labelText: 'Car make',
                          ),
                          items: [
                            for (final make in availableMakes)
                              DropdownMenuItem<int>(
                                value: make.id,
                                child: Text(make.name),
                              ),
                          ],
                          onChanged: (value) {
                            final nextMake =
                                value == null
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
                            return CarModelCard(
                              carModel: carModel,
                              isSelected: carModel.id == _selectedCarModelId,
                              onTap: () {
                                setState(() {
                                  _selectedCarModelId = carModel.id;
                                  _carSelectionError = null;
                                });
                              },
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _cityController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'City (Optional)',
                          hintText: 'Riyadh',
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
                                    ? 'Add Photos'
                                    : 'Add More Photos',
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
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _minPriceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Min price',
                                hintText: '150',
                              ),
                              validator: _validateOptionalNumber,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _maxPriceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Max price',
                                hintText: '350',
                              ),
                              validator: (value) {
                                final numberError = _validateOptionalNumber(
                                  value,
                                );
                                if (numberError != null) {
                                  return numberError;
                                }

                                final minValue = double.tryParse(
                                  _minPriceController.text.trim(),
                                );
                                final maxValue = double.tryParse(
                                  value?.trim() ?? '',
                                );
                                if (minValue != null &&
                                    maxValue != null &&
                                    maxValue < minValue) {
                                  return 'Max price must be greater than min price.';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
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
                                          ? 'Saving...'
                                          : 'Creating...'
                                    : widget.isEditing
                                    ? 'Save Changes'
                                    : 'Create Request',
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

  String? _validateOptionalNumber(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    return double.tryParse(trimmed) == null ? 'Enter a valid number.' : null;
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
    if (selectedCarModelId == null) {
      setState(() {
        _carSelectionError = 'Choose a car model before saving this request.';
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
        carModelId: selectedCarModelId,
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
      carModelId: selectedCarModelId,
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

enum _NoticeTone { info, warning }

class _StatusNotice extends StatelessWidget {
  const _StatusNotice({
    required this.title,
    required this.message,
    required this.tone,
  });

  final String title;
  final String message;
  final _NoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final isWarning = tone == _NoticeTone.warning;
    final background = isWarning
        ? const Color(0xFFFFF3E7)
        : const Color(0xFFF2F8F7);
    final border = isWarning
        ? const Color(0xFFF1C38B)
        : const Color(0xFFD5E8E4);
    final accent = isWarning
        ? const Color(0xFFB35B00)
        : const Color(0xFF0C4A63);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6F6A63)),
          ),
        ],
      ),
    );
  }
}

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
