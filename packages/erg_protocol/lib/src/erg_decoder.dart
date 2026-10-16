import 'erg_protocol.dart';
import 'pm5/pm5_decoder.dart';
import 'raw_packet.dart';
import 'rowing_event.dart';

/// Turns the raw notifications of one protocol into [RowingEvent]s.
///
/// Every protocol yields events of the same form and meaning, so everything
/// behind the decoder does not need to know where the data came from.
abstract interface class ErgDecoder {
  /// The decoder for [protocol]. [onWarning] receives a message for every
  /// packet that had to be dropped.
  factory ErgDecoder.forProtocol(ErgProtocol protocol, {void Function(String message)? onWarning}) =>
      switch (protocol) {
        ErgProtocol.pm5 => Pm5Decoder(onWarning: onWarning),
        ErgProtocol.ftms => throw UnimplementedError('FTMS decoder'),
      };

  List<RowingEvent> decode(RawPacket packet);

  /// Emits what is still buffered, e.g. at the end of a replay.
  List<RowingEvent> flush();
}
