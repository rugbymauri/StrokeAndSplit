import '../../data/sources/ble/ble_transport.dart';
import '../../l10n/l10n.dart';

/// Why the device is no rower, in words for the user (Design D4); null when
/// [error] does not say the device is no rower.
String? notARowerText(AppLocalizations l10n, RowerConnectError error) => switch (error) {
      RowerConnectError.skiErg => l10n.connectErrorSkiErg,
      RowerConnectError.bikeErg => l10n.connectErrorBikeErg,
      RowerConnectError.noRowerData => l10n.connectErrorNoRowerData,
      RowerConnectError.failed || RowerConnectError.noRowingService => null,
    };
