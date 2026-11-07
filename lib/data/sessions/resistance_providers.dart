import 'dart:async';

import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sources/erg_source.dart';
import '../sources/erg_source_providers.dart';
import '../sources/resistance_control.dart';
import 'resistance_director.dart';
import 'session_providers.dart';

/// The resistance level of the active rower as the live display shows it
/// (Change resistance-control, Design D4 to D6).
class ResistanceState {
  const ResistanceState({
    this.range,
    this.level,
    this.target,
    this.refused = false,
  });

  /// The levels that can be set; null when the rower cannot set its level.
  final ResistanceRange? range;

  /// The level the rower reports, in whole levels; null without one.
  final int? level;

  /// The level asked for; − and + step from it.
  final int? target;

  /// Whether the rower just refused a level; shown for a moment.
  final bool refused;

  bool get canSet => range != null && target != null;
  bool get canLower => canSet && range!.clamp(target! - range!.step) < target!;
  bool get canRaise => canSet && range!.clamp(target! + range!.step) > target!;

  ResistanceState copyWith({int? level, int? target, bool? refused}) =>
      ResistanceState(
        range: range,
        level: level ?? this.level,
        target: target ?? this.target,
        refused: refused ?? this.refused,
      );

  @override
  String toString() =>
      'ResistanceState($range, level $level, target $target, refused $refused)';
}

/// How long the live display shows that a level was refused.
const resistanceRefusedHintDuration = Duration(seconds: 2);

final resistanceProvider =
    NotifierProvider<ResistanceController, ResistanceState>(
      ResistanceController.new,
    );

/// Connects the [ResistanceDirector] with the active source, its levels, the
/// course of the session being recorded and the taps on − and +. Levels go
/// out one after the other; a newer one replaces one still waiting.
class ResistanceController extends Notifier<ResistanceState> {
  ResistanceDirector? _director;
  ResistanceControl? _control;
  int? _pending;
  var _sending = false;
  var _recording = false;
  (int, int)? _segment;
  Timer? _refusedTimer;

  @override
  ResistanceState build() {
    _director = null;
    _control = null;
    _pending = null;
    _sending = false;
    _recording = false;
    _segment = null;
    final source = ref.watch(activeErgSourceProvider);
    if (source == null) return const ResistanceState();

    final events = ref.watch(rowingEventsProvider).listen(_onEvent);
    final states = source.connectionStates.listen((s) {
      if (s == ErgConnectionState.connected) _attach(source);
    });
    ref.listen(
      sessionRecorderProvider,
      (_, recording) => _onRecording(recording),
    );
    // A session may already run when the live display asks for the level.
    scheduleMicrotask(() {
      if (ref.mounted) _onRecording(ref.read(sessionRecorderProvider));
    });
    ref.onDispose(() {
      events.cancel();
      states.cancel();
      _refusedTimer?.cancel();
    });
    final control = source.connectionState == ErgConnectionState.connected
        ? source.resistanceControl
        : null;
    if (control == null) return const ResistanceState();
    _control = control;
    _director = ResistanceDirector(range: control.range);
    return ResistanceState(range: control.range);
  }

  /// The user taps + (1) or − (-1).
  void step(int delta) => _send(_director?.step(delta));

  /// Takes the control of a freshly connected rower; after a reconnect the
  /// level asked for goes out again.
  void _attach(ErgSource source) {
    final control = source.resistanceControl;
    if (identical(control, _control)) return;
    _control = control;
    if (control == null) {
      _director = null;
      state = ResistanceState(level: state.level);
      return;
    }
    final director = _director;
    if (director == null) {
      _director = ResistanceDirector(range: control.range);
      state = ResistanceState(range: control.range, level: state.level);
      return;
    }
    director.range = control.range;
    state = ResistanceState(
      range: control.range,
      level: state.level,
      target: director.target,
    );
    _send(director.reconnected());
  }

  void _onEvent(RowingEvent event) {
    if (event is! StatusTick) return;
    final level = event.resistanceLevel;
    if (level == null) return;
    final director = _director;
    if (director == null) {
      if (level != state.level) state = state.copyWith(level: level);
      return;
    }
    final send = director.reported(level);
    final whole = state.range?.wholeLevel(level) ?? level;
    if (whole != state.level || director.target != state.target) {
      state = state.copyWith(level: whole, target: director.target);
    }
    _send(send);
  }

  void _onRecording(ActiveRecording? recording) {
    if (recording == null) {
      _recording = false;
      _segment = null;
      return;
    }
    if (!_recording) {
      _recording = true;
      _director?.sessionStarted();
    }
    final lap = recording.lap;
    if (lap == null) return;
    final segment = (lap.lap, lap.segmentIndex);
    if (segment == _segment) return;
    _segment = segment;
    _send(_director?.segmentStarted(lap.segment));
  }

  Future<void> _send(int? level) async {
    if (level == null) return;
    state = state.copyWith(target: _director?.target);
    if (_sending) {
      _pending = level;
      return;
    }
    _sending = true;
    int? next = level;
    while (next != null) {
      final control = _control;
      if (control == null) break;
      final sent = next;
      final result = await control.setLevel(sent);
      if (!ref.mounted) return;
      if (result != ResistanceResult.accepted) _refuse(sent);
      next = _pending;
      _pending = null;
    }
    _sending = false;
  }

  void _refuse(int level) {
    _director?.failed(level);
    state = state.copyWith(target: _director?.target, refused: true);
    _refusedTimer?.cancel();
    _refusedTimer = Timer(resistanceRefusedHintDuration, () {
      if (ref.mounted) state = state.copyWith(refused: false);
    });
  }
}
