import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../connection/connection_indicator.dart';
import '../connection/heart_rate_indicator.dart';

/// The connection of the rower and the strap and the source as a compact group beside the
/// session button, so the live display needs no title bar. Disconnecting is on the start screen.
class LiveStatus extends StatelessWidget {
  const LiveStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('live-status'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const ConnectionIndicator(),
        // The strap, if any; it also keeps the strap connected while rowing (heart-rate, Design D7).
        const HeartRateIndicator(),
        const Padding(
          padding: EdgeInsets.only(left: AppSpacing.s),
          child: SourceBadge(),
        ),
      ],
    );
  }
}

/// The session button with [status] at its end; [status] shrinks rather than squeezing the button.
class LiveActionRow extends StatelessWidget {
  const LiveActionRow({super.key, required this.action, this.status});

  final Widget action;
  final Widget? status;

  @override
  Widget build(BuildContext context) {
    final status = this.status;
    if (status == null) return action;
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: action),
          const SizedBox(width: AppSpacing.xs),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.45),
            child: FittedBox(fit: BoxFit.scaleDown, child: status),
          ),
        ],
      ),
    );
  }
}
