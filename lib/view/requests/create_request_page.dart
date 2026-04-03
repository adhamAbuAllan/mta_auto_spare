import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../controllers/providers/request_provider.dart';
import '../../controllers/statuses/request_state.dart';
import '../../models/models.dart';
import '../common_widgets/app_error_card.dart';
import '../common_widgets/app_panel.dart';

class CreateRequestPage extends ConsumerStatefulWidget {
  const CreateRequestPage({super.key});

  @override
  ConsumerState<CreateRequestPage> createState() => _CreateRequestPageState();
}

class _CreateRequestPageState extends ConsumerState<CreateRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  List<RequestUploadImage> _selectedImages = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(createRequestNotifierProvider.notifier).loadStatuses();
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

      ref.read(requestsNotifierProvider.notifier).prependRequest(request);
      ref
          .read(requestsNotifierProvider.notifier)
          .setSegment(RequestSegment.mine);
      ref.read(createRequestNotifierProvider.notifier).clearCreatedRequest();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request created successfully.')),
      );
      Navigator.of(context).pop();
    });

    final createState = ref.watch(createRequestNotifierProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    PartRequestStatus? selectedStatus;
    for (final status in createState.statuses) {
      if (status.id == createState.selectedStatusId) {
        selectedStatus = status;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Create Request')),
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
                        'Post a new request',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Create a request that buyers can browse and open chats from.',
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
                          title: 'Initial status',
                          message:
                              'New requests will start as "${selectedStatus.label}".',
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
                      if (_selectedImages.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 92,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final image = _selectedImages[index];
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
                                    ? 'Creating...'
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

    ref
        .read(createRequestNotifierProvider.notifier)
        .create(
          requesterId: requesterId,
          title: _titleController.text,
          description: _descriptionController.text,
          city: _cityController.text,
          minPrice: _minPriceController.text,
          maxPrice: _maxPriceController.text,
          images: _selectedImages,
        );
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _imagePicker.pickMultiImage();
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
