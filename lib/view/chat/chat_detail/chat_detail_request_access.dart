part of '../chat_detail_page.dart';

abstract class _ChatDetailPageStateRequestAccess
    extends _ChatDetailPageStateBase {
  List<PartRequestBrief> _sharedProductsFromMessages(
    List<MessageModel> messages,
  ) {
    final products = <PartRequestBrief>[];
    final seenIds = <int>{};

    for (final message in messages.reversed) {
      final product = message.product;
      if (product == null || seenIds.contains(product.id)) {
        continue;
      }
      seenIds.add(product.id);
      products.add(product);
    }

    return products;
  }

  Future<void> _refreshSharedRequestContext(List<MessageModel> messages) async {
    final sharedProducts = _sharedProductsFromMessages(messages);
    final sharedIds = sharedProducts.map((product) => product.id).toSet();

    if (sharedIds.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedSharedRequestId = null;
        _isLoadingSharedRequestState = false;
        _sharedRequestsById.clear();
        _sharedAccessesByRequestId.clear();
      });
      return;
    }

    final nextSelectedId = sharedIds.contains(_selectedSharedRequestId)
        ? _selectedSharedRequestId
        : sharedProducts.first.id;
    final staleRequestIds = [
      for (final requestId in _sharedRequestsById.keys)
        if (!sharedIds.contains(requestId)) requestId,
    ];

    if (mounted) {
      setState(() {
        _selectedSharedRequestId = nextSelectedId;
        for (final requestId in staleRequestIds) {
          _sharedRequestsById.remove(requestId);
          _sharedAccessesByRequestId.remove(requestId);
        }
      });
    }

    if (nextSelectedId != null) {
      await _loadSharedRequestState(nextSelectedId);
    }
  }

  Future<void> _loadSharedRequestState(
    int requestId, {
    bool forceReload = false,
  }) async {
    final hasRequest = _sharedRequestsById.containsKey(requestId);
    final hasAccesses = _sharedAccessesByRequestId.containsKey(requestId);
    if (!forceReload && hasRequest && hasAccesses) {
      return;
    }

    if (mounted) {
      setState(() => _isLoadingSharedRequestState = true);
    }

    try {
      final requestApi = ref.read(requestApiProvider);
      final request = forceReload || !hasRequest
          ? await requestApi.getRequestById(requestId)
          : _sharedRequestsById[requestId]!;
      final accesses = forceReload || !hasAccesses
          ? await requestApi.getRequestAccesses(
              partRequestId: requestId,
              conversationId: widget.conversationId,
            )
          : _sharedAccessesByRequestId[requestId]!;
      ref.read(requestsNotifierProvider.notifier).upsertRequest(request);
      if (!mounted) {
        return;
      }
      setState(() {
        _sharedRequestsById[requestId] = request;
        _sharedAccessesByRequestId[requestId] = accesses;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingSharedRequestState = false);
      }
    }
  }

  Future<void> _selectSharedRequest(int requestId) async {
    if (_selectedSharedRequestId == requestId) {
      return;
    }

    setState(() => _selectedSharedRequestId = requestId);
    await _loadSharedRequestState(requestId);
  }

  Future<void> _requestManagementAccess(int requestId) async {
    if (_isUpdatingSharedRequestState) {
      return;
    }

    setState(() => _isUpdatingSharedRequestState = true);
    try {
      await ref
          .read(requestApiProvider)
          .requestManagementAccess(
            partRequestId: requestId,
            conversationId: widget.conversationId,
          );
      await _loadSharedRequestState(requestId, forceReload: true);
      await ref.read(requestsNotifierProvider.notifier).load();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.accessRequestSent)));
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotSendAccessRequest)),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingSharedRequestState = false);
      }
    }
  }

  Future<void> _approveSharedAccess(PartRequestAccess access) async {
    if (_isUpdatingSharedRequestState) {
      return;
    }

    setState(() => _isUpdatingSharedRequestState = true);
    try {
      await ref.read(requestApiProvider).approveRequestAccess(access.id);
      await _loadSharedRequestState(access.partRequest, forceReload: true);
      await ref.read(requestsNotifierProvider.notifier).load();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.accessRequestApproved)),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotApproveAccessRequest)),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingSharedRequestState = false);
      }
    }
  }

  Future<void> _rejectSharedAccess(PartRequestAccess access) async {
    if (_isUpdatingSharedRequestState) {
      return;
    }

    setState(() => _isUpdatingSharedRequestState = true);
    try {
      await ref.read(requestApiProvider).rejectRequestAccess(access.id);
      await _loadSharedRequestState(access.partRequest, forceReload: true);
      await ref.read(requestsNotifierProvider.notifier).load();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.accessRequestRejected)),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotRejectAccessRequest)),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingSharedRequestState = false);
      }
    }
  }
}
