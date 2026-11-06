import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erg_protocol/erg_protocol.dart';

import 'erg_source.dart';

/// The data source currently in use, or null when none is selected.
final activeErgSourceProvider = NotifierProvider<ActiveErgSource, ErgSource?>(
  ActiveErgSource.new,
);

class ActiveErgSource extends Notifier<ErgSource?> {
  @override
  ErgSource? build() => null;

  /// Stops the previous source and starts [source].
  Future<void> use(ErgSource source) async {
    await state?.stop();
    state = source;
    await source.start();
  }

  Future<void> clear() async {
    await state?.stop();
    state = null;
  }
}

/// Decoded events of the active source as a broadcast stream, so the live
/// display and the session recorder each see every event.
final rowingEventsProvider = Provider<Stream<RowingEvent>>((ref) {
  final source = ref.watch(activeErgSourceProvider);
  if (source == null) return const Stream.empty();

  final decoder = ErgDecoder.forProtocol(
    source.protocol,
    onWarning: (message) => debugPrint('${source.protocol.name}: $message'),
  );
  final controller = StreamController<RowingEvent>.broadcast();
  final subscription = source.packets.listen(
    (packet) => decoder.decode(packet).forEach(controller.add),
    onDone: () {
      decoder.flush().forEach(controller.add);
      controller.close();
    },
  );
  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });
  return controller.stream;
});

/// Connection state of the active source.
final ergConnectionStateProvider = StreamProvider<ErgConnectionState>((
  ref,
) async* {
  final source = ref.watch(activeErgSourceProvider);
  if (source == null) {
    yield ErgConnectionState.disconnected;
    return;
  }
  yield source.connectionState;
  yield* source.connectionStates;
});
