import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/entities/shop_models.dart';

class LocationFailure implements Exception {
  LocationFailure(this.message, {this.openSettings = false});

  final String message;
  final bool openSettings;
}

abstract class DeviceLocation {
  Future<CustomerPlace> current();

  Future<void> openSettings();
}

class GeolocatorDeviceLocation implements DeviceLocation {
  const GeolocatorDeviceLocation();

  @override
  Future<void> openSettings() => Geolocator.openAppSettings();

  @override
  Future<CustomerPlace> current() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw LocationFailure('Turn on location services, or enter your area.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw LocationFailure('Location permission was denied.',
          openSettings: true);
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationFailure(
          'Location permission is blocked. Enable it in settings.',
          openSettings: true);
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 15),
      ),
    );

    try {
      final marks = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (marks.isNotEmpty) return _fromPlacemark(marks.first, position);
    } catch (_) {
      // Coordinates are still a usable place when reverse geocoding fails.
    }
    return _coordinates(position);
  }

  CustomerPlace _fromPlacemark(Placemark mark, Position position) {
    final area = _first([
      mark.subLocality,
      mark.thoroughfare,
      mark.street,
      mark.name,
    ]);
    final city = _first([
      mark.locality,
      mark.subAdministrativeArea,
      mark.administrativeArea,
    ]);
    if (area == null && city == null) return _coordinates(position);
    return CustomerPlace(area: area ?? '', city: city ?? '', fromDevice: true);
  }

  CustomerPlace _coordinates(Position position) {
    return CustomerPlace(
      area:
          '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
      city: '',
      fromDevice: true,
    );
  }

  String? _first(List<String?> values) {
    for (final value in values) {
      final text = value?.trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return null;
  }
}
