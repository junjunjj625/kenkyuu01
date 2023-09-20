import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';

//現在位置を表示する
enum LocationSettingResult {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  enabled,
}

final logger = Logger();
// 位置情報に関するパーミションを確認
Future<LocationSettingResult> checkLocationSetting() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    logger.w('Location services are disabled.');
    return Future.value(LocationSettingResult.serviceDisabled);
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      logger.w('Location permissions are denied.');
      return Future.value(LocationSettingResult.permissionDenied);
    }
  }

  if (permission == LocationPermission.deniedForever) {
    logger.w('Location permissions are permanently denied.');
    return Future.value(LocationSettingResult.permissionDeniedForever);
  }
  return Future.value(LocationSettingResult.enabled);
}

Future<void> recoverLocationSettings(
    BuildContext context, LocationSettingResult locationResult) async {
  if (locationResult == LocationSettingResult.enabled) {
    return;
  }
  final result = await showOkCancelAlertDialog(
    context: context,
    okLabel: 'OK',
    cancelLabel: 'キャンセル',
    title: 'xxxxxxx',
    message: 'xxxxxxxxxxxx',
  );
  if (result == OkCancelResult.cancel) {
    logger.w('Cancel recover location settings.');
  } else {
    locationResult == LocationSettingResult.serviceDisabled
        ? await Geolocator.openLocationSettings()
        : await Geolocator.openAppSettings();
  }
}
Future<LatLng> getCurrentLocation() async {
  final position = await Geolocator.getCurrentPosition();
  return LatLng(position.latitude, position.longitude);
}

//mapを表示する
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'kadai kenkyu',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  const MapSample({Key? key}) : super(key: key);

  @override
  State<MapSample> createState() => MapSampleState();
}

//現在位置を表示
final defaultLocation = LatLng(37.42796133580664, -122.085749655962); // Google本社
class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller = Completer();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  static const CameraPosition _kLake = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(37.43296265331129, -122.08832357078792),
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);

  BitmapDescriptor? _markerIcon;

  Future<LatLng> _initAsync(BuildContext context) async {
    await _loadPinAsset();

    final result = await checkLocationSetting();
    if (result != LocationSettingResult.enabled) {
      await recoverLocationSettings(context, result);
    }
    return await getCurrentLocation();
  }

  Future<void> _loadPinAsset() async {
    _markerIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/icons/ic_marker.png');
  }

  Marker _createMarker() {
    return Marker(
      markerId: const MarkerId('marker'),
      position: const LatLng(40.786658, 140.759692),
      icon: _markerIcon ?? BitmapDescriptor.defaultMarker,
      infoWindow: const InfoWindow(title: 'title'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LatLng>(
      future: _initAsync(context),
      builder: (BuildContext context, AsyncSnapshot<LatLng> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(
              target: snapshot.data ?? defaultLocation, zoom: 17.0),
          myLocationEnabled: true,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
          markers: Set<Marker>.of(<Marker>{_createMarker()}),
        );
      },
    );
  }
}



