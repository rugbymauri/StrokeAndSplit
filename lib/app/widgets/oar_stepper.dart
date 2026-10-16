import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../design_tokens.dart';

/// Size of an [OarStepper] (design D7).
enum OarStepperSize {
  /// 56 × 60 buttons for a single value across the full width, the unit beside the value.
  large(Size(56, 60), 56, 15),

  /// 44 × 47 buttons for fields side by side, the unit below the value.
  compact(Size(44, 47), 28, 13);

  const OarStepperSize(this.button, this.valueFontSize, this.unitFontSize);

  final Size button;
  final double valueFontSize;
  final double unitFontSize;
}

/// A whole number set with two oar blade buttons instead of typing: the blade
/// pointing up adds [step], the one pointing down takes it away.
///
/// A button is disabled when its step would leave [min] or [max]. Holding a
/// button repeats the step, faster after about a second.
class OarStepper extends StatelessWidget {
  const OarStepper({
    super.key,
    required this.value,
    required this.step,
    required this.stepLabel,
    required this.onChanged,
    this.min,
    this.max,
    this.format,
    this.unit,
    this.label,
    this.size = OarStepperSize.large,
  }) : assert(step > 0);

  final int value;
  final int step;

  /// The step in words for screen readers, e.g. "5 Sekunden" for "5 Sekunden mehr".
  final String stepLabel;

  final ValueChanged<int> onChanged;
  final int? min;
  final int? max;

  /// Shows a value, e.g. seconds as a pace; plain digits if not given.
  final String Function(int value)? format;

  final String? unit;

  /// Name of the field for screen readers.
  final String? label;

  final OarStepperSize size;

  bool get canIncrease => max == null || value + step <= max!;
  bool get canDecrease => min == null || value - step >= min!;

  String _show(int v) => format?.call(v) ?? '$v';

  String _spoken(int v) => unit == null ? _show(v) : '${_show(v)} $unit';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final increase = canIncrease ? () => onChanged(value + step) : null;
    final decrease = canDecrease ? () => onChanged(value - step) : null;
    final large = size == OarStepperSize.large;
    return Semantics(
      container: true,
      label: label,
      value: _spoken(value),
      increasedValue: canIncrease ? _spoken(value + step) : null,
      decreasedValue: canDecrease ? _spoken(value - step) : null,
      onIncrease: increase,
      onDecrease: decrease,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: large ? null : Border.all(color: AppColors.line),
        ),
        child: Padding(
          padding: large ? const EdgeInsets.symmetric(horizontal: 16, vertical: 6) : const EdgeInsets.all(4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _OarButton(up: false, size: size.button, label: l10n.oarStepperLess(stepLabel), onStep: decrease),
              Flexible(
                child: ExcludeSemantics(
                  child: FittedBox(fit: BoxFit.scaleDown, child: _display()),
                ),
              ),
              _OarButton(up: true, size: size.button, label: l10n.oarStepperMore(stepLabel), onStep: increase),
            ],
          ),
        ),
      ),
    );
  }

  Widget _display() {
    final value = Text(
      _show(this.value),
      style: TextStyle(
        fontSize: size.valueFontSize,
        fontWeight: FontWeight.w700,
        height: 1,
        color: AppColors.text,
      ),
    );
    final unit = this.unit;
    if (unit == null) return value;
    final unitText = Text(unit, style: TextStyle(fontSize: size.unitFontSize, height: 1, color: AppColors.textMuted));
    return switch (size) {
      OarStepperSize.large => Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [value, const SizedBox(width: 6), unitText],
        ),
      OarStepperSize.compact => Column(
          mainAxisSize: MainAxisSize.min,
          children: [value, const SizedBox(height: 2), unitText],
        ),
    };
  }
}

const _repeatDelay = Duration(milliseconds: 400);
const _slowInterval = Duration(milliseconds: 150);
const _fastAfter = Duration(seconds: 1);
const _fastInterval = Duration(milliseconds: 50);

/// One oar blade button; disabled without [onStep].
class _OarButton extends StatefulWidget {
  const _OarButton({required this.up, required this.size, required this.label, required this.onStep});

  final bool up;
  final Size size;
  final String label;
  final VoidCallback? onStep;

  @override
  State<_OarButton> createState() => _OarButtonState();
}

class _OarButtonState extends State<_OarButton> {
  Timer? _timer;
  Duration _held = Duration.zero;
  bool _pressed = false;
  bool _repeated = false;

  @override
  void didUpdateWidget(_OarButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The limit was reached while held.
    if (widget.onStep == null) {
      _timer?.cancel();
      _timer = null;
      _pressed = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _down(TapDownDetails _) {
    if (widget.onStep == null) return;
    setState(() => _pressed = true);
    _repeated = false;
    _held = _repeatDelay;
    _timer = Timer(_repeatDelay, _repeat);
  }

  void _repeat() {
    final onStep = widget.onStep;
    if (onStep == null) {
      _stop();
      return;
    }
    _repeated = true;
    onStep();
    final interval = _held >= _fastAfter ? _fastInterval : _slowInterval;
    _held += interval;
    _timer = Timer(interval, _repeat);
  }

  void _up(TapUpDetails _) {
    final repeated = _repeated;
    _stop();
    if (!repeated) widget.onStep?.call();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _repeated = false;
    if (mounted && _pressed) setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onStep != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      onTap: widget.onStep,
      child: GestureDetector(
        excludeFromSemantics: true,
        onTapDown: _down,
        onTapUp: _up,
        onTapCancel: _stop,
        child: Opacity(
          opacity: enabled ? 1 : 0.35,
          child: RotatedBox(
            quarterTurns: widget.up ? 0 : 2,
            child: CustomPaint(size: widget.size, painter: _OarBladePainter(pressed: _pressed && enabled)),
          ),
        ),
      ),
    );
  }
}

// Not in the token table of D1, only used for the blades.
const _bladeRim = Color(0xFF4A545E);
const _bladePressed = Color(0xFF1D3A55);

/// An oar blade pointing up, its arrow forming the loom; drawn on a 56 × 60 grid.
class _OarBladePainter extends CustomPainter {
  _OarBladePainter({required this.pressed});

  final bool pressed;

  static final _blade = Path()
    ..moveTo(14, 3)
    ..lineTo(42, 3)
    ..lineTo(42, 40)
    ..lineTo(32, 50)
    ..lineTo(24, 50)
    ..lineTo(14, 40)
    ..close();

  static final _arrow = Path()
    ..moveTo(28, 4)
    ..lineTo(28, 57)
    ..moveTo(15, 17)
    ..lineTo(28, 4)
    ..lineTo(41, 17);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 56, size.height / 60);
    canvas.drawPath(_blade, Paint()..color = pressed ? _bladePressed : AppColors.line);
    canvas.drawPath(
      _blade,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round
        ..color = pressed ? AppColors.zoneIn : _bladeRim,
    );
    canvas.drawPath(
      _arrow,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = pressed ? AppColors.zoneIn : AppColors.text,
    );
  }

  @override
  bool shouldRepaint(_OarBladePainter oldDelegate) => oldDelegate.pressed != pressed;
}
