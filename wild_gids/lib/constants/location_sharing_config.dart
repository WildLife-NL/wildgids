class LocationSharingConfig {
  LocationSharingConfig._();

  // Central place to configure how often location sharing pings are sent.
  // Update this value in future app versions if product requirements change.
  static const updateInterval = Duration(minutes: 10);
}

