import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/routes.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';
import 'package:mobile/features/order_entry/data/models/order_entry_view_data.dart';
import 'package:mobile/shared/shared_layout.dart';
import 'package:mobile/shared/widgets/fade_slide_in.dart';
import 'package:mobile/shared/widgets/kkfc_scaffold.dart';
import 'package:mobile/shared/widgets/menu_header.dart';
import 'package:mobile/shared/widgets/menu_navigation.dart';
import 'package:mobile/features/order_entry/data/models/platform_reference_view_data.dart';

import '../widgets/order_entry_header.dart';
import '../widgets/order_entry_action_bar.dart';
import '../widgets/order_context_card.dart';
import '../widgets/platform_reference_card.dart';

class PlatformReferenceScreen extends ConsumerStatefulWidget {
  const PlatformReferenceScreen({
    super.key,
    this.data = PlatformReferenceViewData.sample,
    this.onEditReferences,
  });

  final PlatformReferenceViewData data;
  final VoidCallback? onEditReferences;

  static const double _twoColumnBreakpoint = 720;

  @override
  ConsumerState<PlatformReferenceScreen> createState() =>
      _PlatformReferenceScreenState();
}

class _PlatformReferenceScreenState
    extends ConsumerState<PlatformReferenceScreen> {
  late final TextEditingController _storeController;
  late final TextEditingController _externalReferenceController;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _storeController = TextEditingController(
      text: ref.read(storeReferenceProvider),
    );
    _externalReferenceController = TextEditingController(
      text: ref.read(orderReferenceProvider),
    );
  }

  @override
  void dispose() {
    _storeController.dispose();
    _externalReferenceController.dispose();
    super.dispose();
  }

  void _submitReferences() {
    final store = _storeController.text.trim();
    final externalReference = _externalReferenceController.text.trim();

    ref.read(storeReferenceProvider.notifier).set(store);
    ref.read(orderReferenceProvider.notifier).set(externalReference);

    if (store.isEmpty || externalReference.isEmpty) {
      setState(() => _submitted = true);
      return;
    }

    if (widget.onEditReferences != null) {
      widget.onEditReferences!();
      return;
    }

    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      router.pop();
    } else if (router != null) {
      router.go(AppRoutes.orderEntry);
    } else {
      Navigator.maybeOf(context)?.maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(storeReferenceProvider, (_, store) {
      if (_storeController.text != store) {
        _storeController.text = store;
      }
    });
    ref.listen<String>(orderReferenceProvider, (_, reference) {
      if (_externalReferenceController.text != reference) {
        _externalReferenceController.text = reference;
      }
    });

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
    final brand = ref.watch(activeBrandProvider);
    final channel = ref.watch(menuChannelProvider);
    final storeText = _storeController.text.trim();
    final externalRefText = _externalReferenceController.text.trim();

    final effectiveData = widget.data.withContext(
      brandName: brand.name,
      channelLabel: channel.label,
      storeErrorText: (_submitted && storeText.isEmpty)
          ? 'Store required'
          : null,
      externalReferenceErrorText: externalRefText.isEmpty
          ? 'External reference required'
          : null,
    );
    final channelLine = OrderEntryViewData.formatChannelLine(
      channel.label,
      externalRefText,
      storeText,
    );

    final referenceCard = PlatformReferenceCard(
      data: effectiveData,
      storeController: _storeController,
      externalReferenceController: _externalReferenceController,
      onStoreChanged: (value) {
        ref.read(storeReferenceProvider.notifier).set(value);
        setState(() {});
      },
      onExternalReferenceChanged: (value) {
        ref.read(orderReferenceProvider.notifier).set(value);
        setState(() {});
      },
    );
    final contextCard = OrderContextCard(
      brand: brand.name,
      channelLine: channelLine,
      orderStatus: 'Draft',
      paymentStatus: 'Unpaid',
      note: effectiveData.rightSubtitle,
    );

    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final wide =
                    c.maxWidth >= PlatformReferenceScreen._twoColumnBreakpoint;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(KkfcSpace.s32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: _Enter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FadeSlideIn(
                              index: 0,
                              child: OrderEntryHeader(
                                eyebrow: effectiveData.eyebrow,
                                title: effectiveData.title,
                                subtitle: effectiveData.subtitle,
                              ),
                            ),
                            const SizedBox(height: KkfcSpace.s32),
                            if (wide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: FadeSlideIn(
                                      index: 1,
                                      child: referenceCard,
                                    ),
                                  ),
                                  const SizedBox(width: KkfcSpace.s32),
                                  Expanded(
                                    flex: 2,
                                    child: FadeSlideIn(
                                      index: 2,
                                      child: contextCard,
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              FadeSlideIn(index: 1, child: referenceCard),
                              const SizedBox(height: KkfcSpace.s16),
                              FadeSlideIn(index: 2, child: contextCard),
                            ],
                          ],
                        ),
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
              secondaryLabel: '',
              primaryLabel: effectiveData.buttonLabel,
              isLoading: false,
              onSecondary: null,
              onPrimary: _submitReferences,
              sideBySide: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _Enter extends StatelessWidget {
  const _Enter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: KkfcMotion.base,
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
