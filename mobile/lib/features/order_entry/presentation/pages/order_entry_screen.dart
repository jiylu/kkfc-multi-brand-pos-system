import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/routes.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/features/auth/providers/auth_profile_provider.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';
import 'package:mobile/features/order_entry/data/models/order_confirmed_view_data.dart';
import 'package:mobile/features/order_entry/data/models/order_entry_view_data.dart';
import 'package:mobile/features/order_entry/data/repositories/order_entry_repository.dart';
import 'package:mobile/shared/shared_layout.dart';
import 'package:mobile/shared/widgets/fade_slide_in.dart';
import 'package:mobile/shared/widgets/kkfc_scaffold.dart';
import 'package:mobile/shared/widgets/menu_header.dart';
import 'package:mobile/shared/widgets/menu_navigation.dart';
import 'package:mobile/shared/widgets/toast/kkfc_toaster.dart';

import 'order_confirmed_screen.dart';
import 'platform_reference_screen.dart';
import '../widgets/order_entry_action_bar.dart';
import '../widgets/order_entry_header.dart';
import '../widgets/order_context_card.dart';
import '../widgets/order_summary_card.dart';

class OrderEntryScreen extends ConsumerStatefulWidget {
  const OrderEntryScreen({
    super.key,
    this.data = OrderEntryViewData.checkBeforeSending,
  });

  final OrderEntryViewData data;

  static const double _twoColumnBreakpoint = 720;

  @override
  ConsumerState<OrderEntryScreen> createState() => _OrderEntryScreenState();
}

class _OrderEntryScreenState extends ConsumerState<OrderEntryScreen> {
  late final String _orderId = generateOrderId();
  bool _isSending = false;

  void _goBackToMenu() {
    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      router.pop();
    } else if (router != null) {
      router.go(AppRoutes.menu);
    } else {
      Navigator.maybeOf(context)?.maybePop();
    }
  }

  Future<String> _resolveBrandId() async {
    final activeId = ref.read(activeBrandProvider).id;
    if (_isUuid(activeId)) return activeId;
    return ref.read(authenticatedBrandIdProvider.future);
  }

  static bool _isUuid(String value) => RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);

  String _extractErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) return message;
        if (message is List && message.isNotEmpty) {
          return message.first.toString();
        }
      }
      return 'Could not send order. Please check your connection and try again.';
    }
    if (error is StateError) {
      return error.message;
    }
    return 'Could not send order. Please try again.';
  }

  void _showError(String message) {
    if (!mounted) return;
    if (Overlay.maybeOf(context, rootOverlay: true) != null) {
      KkfcToaster.error(context, message: message);
    } else {
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    if (Overlay.maybeOf(context, rootOverlay: true) != null) {
      KkfcToaster.success(context, message: message);
    } else {
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _openPlatformReference() {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.push(AppRoutes.platformReference);
    } else {
      Navigator.maybeOf(context)?.push(
        MaterialPageRoute<void>(
          builder: (_) => const PlatformReferenceScreen(),
        ),
      );
    }
  }

  Future<void> _sendOrder() async {
    if (_isSending) return;

    final lines = ref.read(cartProvider);
    final channel = ref.read(menuChannelProvider);
    final reference = ref.read(orderReferenceProvider);
    final storeReference = ref.read(storeReferenceProvider);
    final brand = ref.read(activeBrandProvider);

    if (lines.isEmpty) {
      _showError('Add at least one item before sending the order.');
      return;
    }

    if (channel.isPlatform &&
        (reference.trim().isEmpty || storeReference.trim().isEmpty)) {
      _showError('Add a reference label before sending the order.');
      _openPlatformReference();
      return;
    }

    if (!channel.isPlatform && reference.trim().isEmpty) {
      _showError(
        'Add a ${channel.referenceLabel.toLowerCase()} before sending the order.',
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      final brandId = await _resolveBrandId();
      final created = await ref
          .read(orderEntryRepositoryProvider)
          .createOrder(
            brandId: brandId,
            orderId: _orderId,
            channel: channel,
            lines: lines,
            reference: reference,
            merchantStoreReference: storeReference.trim().isNotEmpty
                ? storeReference.trim()
                : brand.code,
          );
      final confirmedData = OrderConfirmedViewData.fromOrder(
        brand: brand.name,
        channel: channel.label,
        isPlatform: channel.isPlatform,
        reference: reference,
        orderStatus: created['status'] as String?,
        paymentStatus: created['payment_status'] as String?,
      );

      ref.read(cartProvider.notifier).clear();
      ref.read(orderReferenceProvider.notifier).clear();
      ref.read(storeReferenceProvider.notifier).clear();

      if (!mounted) return;
      _showSuccess('Order sent to kitchen.');
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        router.go(AppRoutes.orderConfirmed, extra: confirmedData);
      } else {
        Navigator.maybeOf(context)?.pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => OrderConfirmedScreen(data: confirmedData),
          ),
        );
      }
    } catch (error) {
      _showError(_extractErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KkfcScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final showRail = constraints.maxWidth >= MenuLayout.compactMax;

          return Column(
            children: [
              const MenuHeader(),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showRail) const MenuRail(),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(child: _buildContent(context)),
                          if (!showRail) const MenuBottomNav(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final lines = ref.watch(cartProvider);
    final channel = ref.watch(menuChannelProvider);
    final reference = ref.watch(orderReferenceProvider);
    final storeReference = ref.watch(storeReferenceProvider);
    final brand = ref.watch(activeBrandProvider);
    final count = ref.watch(cartCountProvider);
    final total = ref.watch(cartTotalProvider);

    final hasDynamicDetails =
        lines.isNotEmpty ||
        reference.trim().isNotEmpty ||
        storeReference.trim().isNotEmpty;

    final data = !hasDynamicDetails
        ? widget.data
        : widget.data.withOrderDetails(
            brandName: brand.name,
            channel: channel.label,
            reference: reference,
            storeReference: storeReference,
            itemCount: lines.isEmpty ? null : count,
            items: lines.isEmpty
                ? null
                : [
                    for (final line in lines)
                      OrderEntryItem(
                        name: line.item.name,
                        quantity: line.quantity,
                        total: formatPeso(line.totalCentavos(channel)),
                        modifiers: line.modifierSummary,
                      ),
                  ],
            total: lines.isEmpty ? null : formatPeso(total),
          );

    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final wide =
                    c.maxWidth >= OrderEntryScreen._twoColumnBreakpoint;
                final summary = FadeSlideIn(
                  index: 1,
                  child: OrderSummaryCard(data: data),
                );
                final status = FadeSlideIn(
                  index: 2,
                  child: OrderContextCard(
                    brand: data.brandName,
                    channelLine: data.channelLine,
                    orderStatus: 'Draft',
                    paymentStatus: 'Unpaid',
                    note: 'Verify quantities, prices and modifiers. No kitchen ticket yet.',
                  ),
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(KkfcSpace.s32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeSlideIn(
                            child: OrderEntryHeader(
                              eyebrow: data.eyebrow,
                              title: data.title,
                              subtitle: data.subtitle,
                            ),
                          ),
                          const SizedBox(height: KkfcSpace.s32),
                          if (wide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: summary),
                                const SizedBox(width: KkfcSpace.s32),
                                Expanded(flex: 2, child: status),
                              ],
                            )
                          else ...[
                            summary,
                            const SizedBox(height: KkfcSpace.s16),
                            status,
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          FadeSlideIn(
            index: 3,
            child: OrderEntryActionBar(
              secondaryLabel: data.secondaryLabel,
              primaryLabel: data.primaryLabel,
              isLoading: _isSending,
              onSecondary: _goBackToMenu,
              onPrimary: _sendOrder,
            ),
          ),
        ],
      ),
    );
  }
}
