import 'package:flutter/material.dart';

import 'package:mobile/shared/shared_layout.dart';
import 'package:mobile/shared/widgets/kkfc_scaffold.dart';
import 'package:mobile/shared/widgets/menu_header.dart';
import 'package:mobile/shared/widgets/menu_navigation.dart';

import 'cancel_action_bar.dart';

/// Material 3 boundary between the phone and tablet cancel-order layouts.
const double kCancelTabletBreakpoint = 840;

/// Shared chrome for the cancel-order workflow: top bar, navigation rail or
/// bottom nav, scrolling content and the pinned footer actions.
class CancelOrderShell extends StatelessWidget {
  const CancelOrderShell({
    super.key,
    required this.header,
    required this.bodyBuilder,
    required this.actions,
    this.staffName = 'Ana R.',
    this.staffRole = 'Order staff',
  });

  final Widget header;

  /// Cards for the current step. [isTablet] switches between the two-column
  /// layout and the stacked phone layout.
  final Widget Function(BuildContext context, bool isTablet) bodyBuilder;

  final List<CancelAction> actions;
  final String staffName;
  final String staffRole;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return KkfcScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= kCancelTabletBreakpoint;

          final topBar = MenuHeader(
            compact: !isTablet,
            staffName: staffName,
            staffRole: staffRole,
          );

          final content = ColoredBox(
            color: scheme.surface,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(
                isTablet ? MenuSpace.xl : MenuSpace.md,
              ),
              child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      header,
                      SizedBox(height: MenuSpace.xl),
                      bodyBuilder(context, isTablet),
                    ],
                  ),
                ),
              ),
            ),
          );

          final footer = _CancelFooter(
            actions: actions,
            expanded: !isTablet,
          );

          if (isTablet) {
            return Column(
              children: [
                topBar,
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const MenuRail(),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(child: content),
                            footer,
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              topBar,
              Expanded(child: content),
              footer,
              const MenuBottomNav(),
            ],
          );
        },
      ),
    );
  }
}

class _CancelFooter extends StatelessWidget {
  const _CancelFooter({required this.actions, required this.expanded});

  final List<CancelAction> actions;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: scheme.outlineVariant, width: MenuBorder.thin),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          expanded ? MenuSpace.md : MenuSpace.lg,
        ),
        child: CancelActionBar(actions: actions, expanded: expanded),
      ),
    );
  }
}
