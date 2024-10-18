import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class GeolocatorView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geolocalización'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const <Widget>[
              ServiceEnabledWidget(),
              PermissionStatusWidget(),
              GetLocationWidget(),
              ListenLocationWidget(),
              EnableInBackgroundWidget(),
              ChangeSettings(),
              ChangeNotificationWidget(),
            ],
          ),
        ),
      ),
    );
  }
}

class ServiceEnabledWidget extends StatefulWidget {
  const ServiceEnabledWidget({super.key});

  @override
  _ServiceEnabledState createState() => _ServiceEnabledState();
}

class _ServiceEnabledState extends State<ServiceEnabledWidget> {
  final Location location = Location();

  bool? _serviceEnabled;

  Future<void> _checkService() async {
    final serviceEnabledResult = await location.serviceEnabled();
    setState(() {
      _serviceEnabled = serviceEnabledResult;
    });
  }

  Future<void> _requestService() async {
    if (_serviceEnabled ?? false) {
      return;
    }

    final serviceRequestedResult = await location.requestService();
    setState(() {
      _serviceEnabled = serviceRequestedResult;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Service enabled: ${_serviceEnabled ?? "unknown"}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Row(
          children: <Widget>[
            ElevatedButton(
              onPressed: _checkService,
              child: const Text('Check'),
            ),
            ElevatedButton(
              onPressed: (_serviceEnabled ?? false) ? null : _requestService,
              child: const Text('Request'),
            ),
          ],
        ),
      ],
    );
  }
}

class PermissionStatusWidget extends StatefulWidget {
  const PermissionStatusWidget({super.key});

  @override
  _PermissionStatusState createState() => _PermissionStatusState();
}

class _PermissionStatusState extends State<PermissionStatusWidget> {
  final Location location = Location();

  PermissionStatus? _permissionGranted;

  Future<void> _checkPermissions() async {
    final permissionGrantedResult = await location.hasPermission();
    setState(() {
      _permissionGranted = permissionGrantedResult;
    });
  }

  Future<void> _requestPermission() async {
    if (_permissionGranted != PermissionStatus.granted) {
      final permissionRequestedResult = await location.requestPermission();
      setState(() {
        _permissionGranted = permissionRequestedResult;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Permission status: ${_permissionGranted ?? "unknown"}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Row(
          children: <Widget>[
            ElevatedButton(
              onPressed: _checkPermissions,
              child: const Text('Check'),
            ),
            ElevatedButton(
              onPressed: _permissionGranted == PermissionStatus.granted
                  ? null
                  : _requestPermission,
              child: const Text('Request'),
            ),
          ],
        ),
      ],
    );
  }
}

class GetLocationWidget extends StatefulWidget {
  const GetLocationWidget({super.key});

  @override
  _GetLocationState createState() => _GetLocationState();
}

class _GetLocationState extends State<GetLocationWidget> {
  final Location location = Location();

  bool _loading = false;
  LocationData? _location;
  String? _error;

  Future<void> _getLocation() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final locationResult = await location.getLocation();
      setState(() {
        _location = locationResult;
        _loading = false;
      });
    } on PlatformException catch (err) {
      setState(() {
        _error = err.code;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Location: ${_error ?? '${_location ?? "unknown"}'}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        ElevatedButton(
          onPressed: _getLocation,
          child: _loading
              ? const CircularProgressIndicator(
                  color: Colors.white,
                )
              : const Text('Get'),
        ),
      ],
    );
  }
}

class ListenLocationWidget extends StatefulWidget {
  const ListenLocationWidget({super.key});

  @override
  _ListenLocationState createState() => _ListenLocationState();
}

class _ListenLocationState extends State<ListenLocationWidget> {
  final Location location = Location();

  LocationData? _location;
  StreamSubscription<LocationData>? _locationSubscription;
  String? _error;

  Future<void> _listenLocation() async {
    _locationSubscription =
        location.onLocationChanged.handleError((dynamic err) {
      if (err is PlatformException) {
        setState(() {
          _error = err.code;
        });
      }
      _locationSubscription?.cancel();
      setState(() {
        _locationSubscription = null;
      });
    }).listen((currentLocation) {
      setState(() {
        _error = null;
        _location = currentLocation;
      });
    });
    setState(() {});
  }

  Future<void> _stopListen() async {
    await _locationSubscription?.cancel();
    setState(() {
      _locationSubscription = null;
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    setState(() {
      _locationSubscription = null;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Listen location: ${_error ?? '${_location ?? "unknown"}'}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Row(
          children: <Widget>[
            ElevatedButton(
              onPressed:
                  _locationSubscription == null ? _listenLocation : null,
              child: const Text('Listen'),
            ),
            ElevatedButton(
              onPressed: _locationSubscription != null ? _stopListen : null,
              child: const Text('Stop'),
            ),
          ],
        ),
      ],
    );
  }
}

class EnableInBackgroundWidget extends StatefulWidget {
  const EnableInBackgroundWidget({super.key});

  @override
  _EnableInBackgroundState createState() => _EnableInBackgroundState();
}

class _EnableInBackgroundState extends State<EnableInBackgroundWidget> {
  final Location location = Location();

  bool? _enabled;
  String? _error;

  @override
  void initState() {
    _checkBackgroundMode();
    super.initState();
  }

  Future<void> _checkBackgroundMode() async {
    setState(() {
      _error = null;
    });
    final result = await location.isBackgroundModeEnabled();
    setState(() {
      _enabled = result;
    });
  }

  Future<void> _toggleBackgroundMode() async {
    setState(() {
      _error = null;
    });
    try {
      final result =
          await location.enableBackgroundMode(enable: !(_enabled ?? false));
      setState(() {
        _enabled = result;
      });
    } on PlatformException catch (err) {
      setState(() {
        _error = err.code;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const Text('Enable in background not available on the web');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Enabled in background: ${_error ?? '${_enabled ?? false}'}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Row(
          children: <Widget>[
            ElevatedButton(
              onPressed: _checkBackgroundMode,
              child: const Text('Check'),
            ),
            ElevatedButton(
              onPressed: _enabled == null ? null : _toggleBackgroundMode,
              child: Text(_enabled ?? false ? 'Disable' : 'Enable'),
            ),
          ],
        ),
      ],
    );
  }
}

class ChangeSettings extends StatefulWidget {
  const ChangeSettings({super.key});

  @override
  _ChangeSettingsState createState() => _ChangeSettingsState();
}

class _ChangeSettingsState extends State<ChangeSettings> {
  final Location _location = Location();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _intervalController = TextEditingController(
    text: '5000',
  );
  final TextEditingController _distanceFilterController = TextEditingController(
    text: '0',
  );

  LocationAccuracy _locationAccuracy = LocationAccuracy.high;

  @override
  void dispose() {
    _intervalController.dispose();
    _distanceFilterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Change settings',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          TextFormField(
            keyboardType: TextInputType.number,
            controller: _intervalController,
            decoration: const InputDecoration(
              labelText: 'Interval',
            ),
          ),
          TextFormField(
            keyboardType: TextInputType.number,
            controller: _distanceFilterController,
            decoration: const InputDecoration(
              labelText: 'DistanceFilter',
            ),
          ),
          DropdownButtonFormField<LocationAccuracy>(
            value: _locationAccuracy,
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _locationAccuracy = value;
              });
            },
            items: const <DropdownMenuItem<LocationAccuracy>>[
              DropdownMenuItem(
                value: LocationAccuracy.high,
                child: Text('High'),
              ),
              DropdownMenuItem(
                value: LocationAccuracy.balanced,
                child: Text('Balanced'),
              ),
              DropdownMenuItem(
                value: LocationAccuracy.low,
                child: Text('Low'),
              ),
              DropdownMenuItem(
                value: LocationAccuracy.powerSave,
                child: Text('Powersave'),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              _location.changeSettings(
                accuracy: _locationAccuracy,
                interval: int.parse(_intervalController.text),
                distanceFilter: double.parse(_distanceFilterController.text),
              );
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}

class ChangeNotificationWidget extends StatefulWidget {
  const ChangeNotificationWidget({super.key});

  @override
  _ChangeNotificationWidgetState createState() =>
      _ChangeNotificationWidgetState();
}

class _ChangeNotificationWidgetState extends State<ChangeNotificationWidget> {
  final Location _location = Location();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _channelController = TextEditingController(
    text: 'Location background service',
  );
  final TextEditingController _titleController = TextEditingController(
    text: 'Location background service running',
  );

  String? _iconName = 'navigation_empty_icon';

  @override
  void dispose() {
    _channelController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !Platform.isAndroid) {
      return const Text(
        'Change notification settings not available on this platform',
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Android Notification Settings',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          TextFormField(
            controller: _channelController,
            decoration: const InputDecoration(
              labelText: 'Channel Name',
            ),
          ),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Notification Title',
            ),
          ),
          DropdownButtonFormField<String>(
            value: _iconName,
            onChanged: (value) {
              setState(() {
                _iconName = value;
              });
            },
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(
                value: 'navigation_empty_icon',
                child: Text('Empty'),
              ),
              DropdownMenuItem<String>(
                value: 'circle',
                child: Text('Circle'),
              ),
              DropdownMenuItem<String>(
                value: 'square',
                child: Text('Square'),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              _location.changeNotificationOptions(
                channelName: _channelController.text,
                title: _titleController.text,
                iconName: _iconName,
              );
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}
