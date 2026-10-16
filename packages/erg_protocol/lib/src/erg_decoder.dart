import 'erg_protocol.dart';
import 'ftms/ftms_decoder.dart';
import 'heart_rate/heart_rate_decoder.dart';
import 'pm5/pm5_decoder.dart';
import 'raw_packet.dart';
import 'rowing_event.dart';

/// Turns the raw notifications of one protocol into [RowingEvent]s.
///
/// Every protocol yields events of the same form and meaning, so everything
/// behind the decoder does not need to know where the data came from.
abstract interface class ErgDecoder {
  /// The decoder for [protocol], wrapped in a [HeartRateDecoder] so the
  /// packets of a directly connected chest strap are understood as well.
  /// [onWarning] receives a message for every packet that had to be dropped.
  factory ErgDecoder.forProtocol(ErgProtocol protocol, {void Function(String message)? onWarning}) =>
      HeartRateDecoder(
        switch (protocol) {
          ErgProtocol.pm5 => Pm5Decoder(onWarning: onWarning),
          ErgProtocol.ftms => FtmsDecoder(onWarning: onWarning),
        },
        onWarning: onWarning,
      );

  List<RowingEvent> decode(RawPacket packet);

  /// Emits what is still buffered, e.g. at the end of a replay.
  List<RowingEvent> flush();
}
