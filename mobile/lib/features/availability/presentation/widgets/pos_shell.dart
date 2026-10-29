import 'package:flutter/material.dart';
import 'package:mobile/shared/shared_layout.dart';
import 'package:mobile/shared/widgets/kkfc_scaffold.dart';

import 'package:mobile/features/availability/data/models/availability_model.dart';
import 'package:mobile/shared/widgets/menu_navigation.dart';
import 'package:mobile/shared/widgets/menu_header.dart';
import 'package:mobile/shared/widgets/fade_slide_in.dart';
import 'package:mobile/shared/widgets/kkfc_loading_button.dart';

/// Material 3 window-size boundary between "medium" and "expanded".
const double kTabletBreakpoint = 840;

class PosShell extends StatefulWidget {
  const PosShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.staffName,
    required this.staffRole,
    required this.sectionsBuilder,
    required this.actionLabel,
    required this.onAction,
    this.sideCard,
  });

  final String title;
  final String subtitle;
  final String staffName;
  final String staffRole;
  final List<Widget> Function(
    BuildContext context,
    bool isTablet,
    PosChannel channel,
  )
  sectionsBuilder;
  final String actionLabel;
  final VoidCallback onAction;

  /// Right column on tablet, appended below the sections on phone.
  final Widget? sideCard;

  @override
  State<PosShell> createState() => _PosShellState();
}

class _PosShellState extends State<PosShell> {
  PosChannel _channel = PosChannel.dineIn;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return KkfcScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= kTabletBreakpoint;

          final topBar = MenuHeader(
            compact: !isTablet,
            channel: _channel,
            onChannelChanged: (c) => setState(() => _channel = c),
            staffName: widget.staffName,
            staffRole: widget.staffRole,
          );

          final content = ColoredBox(
            color: scheme.surfaceContainerLow,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isTablet ? MenuSpace.xl : MenuSpace.md),
              child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: _body(context, isTablet),
                ),
              ),
            ),
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
                      Expanded(child: content),
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
              _PinnedAction(
                label: widget.actionLabel,
                onPressed: widget.onAction,
              ),
              const MenuBottomNav(),
            ],
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, bool isTablet) {
    final sections = widget.sectionsBuilder(context, isTablet, _channel);

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeSlideIn(
          child: _PageHeader(title: widget.title, subtitle: widget.subtitle),
        ),
        SizedBox(height: MenuSpace.lg),
        for (var i = 0; i < sections.length; i++) ...[
          FadeSlideIn(index: i + 1, child: sections[i]),
          SizedBox(height: MenuSpace.sm),
        ],
        if (!isTablet && widget.sideCard != null)
          FadeSlideIn(index: sections.length + 1, child: widget.sideCard!),
        if (isTablet) ...[
          SizedBox(height: MenuSpace.md),
          FadeSlideIn(
            index: sections.length + 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: SizedBox(
                  width: double.infinity,
                  child: KkfcLoadingButton(
                    label: widget.actionLabel,
                    loadingLabel: 'Loading…',
                    isLoading: false, // TODO: wire to the real sending state once the backend exists.
                    onPressed: widget.onAction,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );

    if (isTablet && widget.sideCard != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: left),
          SizedBox(width: MenuSpace.xl),
          Expanded(
            flex: 2,
            child: FadeSlideIn(index: 2, child: widget.sideCard!),
          ),
        ],
      );
    }
    return left;
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: text.headlineLarge),
        SizedBox(height: MenuSpace.xs),
        Text(subtitle, style: text.bodySmall),
      ],
    );
  }
}

class _PinnedAction extends StatelessWidget {
  const _PinnedAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

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
        padding: EdgeInsets.all(MenuSpace.md),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: onPressed, child: Text(label)),
        ),
      ),
    );
  }
}
