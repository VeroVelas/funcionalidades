import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorPlus extends StatefulWidget {
  const SensorPlus({super.key});

  @override
  _SensorPlusState createState() => _SensorPlusState();
}

class _SensorPlusState extends State<SensorPlus> {
  static const int _snakeRows = 20;
  static const int _snakeColumns = 20;
  static const double _snakeCellSize = 10.0;

  // Sensor events
  UserAccelerometerEvent? _userAccelerometerEvent;
  AccelerometerEvent? _accelerometerEvent;
  GyroscopeEvent? _gyroscopeEvent;
  MagnetometerEvent? _magnetometerEvent;
  BarometerEvent? _barometerEvent;

  DateTime? _userAccelerometerUpdateTime;
  DateTime? _accelerometerUpdateTime;
  DateTime? _gyroscopeUpdateTime;
  DateTime? _magnetometerUpdateTime;
  DateTime? _barometerUpdateTime;

  int? _userAccelerometerLastInterval;
  int? _accelerometerLastInterval;
  int? _gyroscopeLastInterval;
  int? _magnetometerLastInterval;
  int? _barometerLastInterval;

  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  Duration sensorInterval = SensorInterval.normalInterval;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensors Plus Example'),
        elevation: 4,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(width: 1.0, color: Colors.black38),
              ),
              child: SizedBox(
                height: _snakeRows * _snakeCellSize,
                width: _snakeColumns * _snakeCellSize,
                child: Snake(
                  rows: _snakeRows,
                  columns: _snakeColumns,
                  cellSize: _snakeCellSize,
                ),
              ),
            ),
          ),
          _buildSensorTables(),
          _buildSensorIntervalSelector(),
        ],
      ),
    );
  }

  Widget _buildSensorTables() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(4),
              4: FlexColumnWidth(2),
            },
            children: [
              const TableRow(
                children: [
                  SizedBox.shrink(),
                  Text('X'),
                  Text('Y'),
                  Text('Z'),
                  Text('Interval'),
                ],
              ),
              _buildSensorTableRow(
                'UserAccelerometer',
                _userAccelerometerEvent?.x,
                _userAccelerometerEvent?.y,
                _userAccelerometerEvent?.z,
                _userAccelerometerLastInterval,
              ),
              _buildSensorTableRow(
                'Accelerometer',
                _accelerometerEvent?.x,
                _accelerometerEvent?.y,
                _accelerometerEvent?.z,
                _accelerometerLastInterval,
              ),
              _buildSensorTableRow(
                'Gyroscope',
                _gyroscopeEvent?.x,
                _gyroscopeEvent?.y,
                _gyroscopeEvent?.z,
                _gyroscopeLastInterval,
              ),
              _buildSensorTableRow(
                'Magnetometer',
                _magnetometerEvent?.x,
                _magnetometerEvent?.y,
                _magnetometerEvent?.z,
                _magnetometerLastInterval,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(4),
              1: FlexColumnWidth(3),
              2: FlexColumnWidth(2),
            },
            children: [
              const TableRow(
                children: [
                  SizedBox.shrink(),
                  Text('Pressure'),
                  Text('Interval'),
                ],
              ),
              TableRow(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Barometer'),
                  ),
                  Text(
                      '${_barometerEvent?.pressure.toStringAsFixed(1) ?? '?'} hPa'),
                  Text('${_barometerLastInterval?.toString() ?? '?'} ms'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  TableRow _buildSensorTableRow(
    String label,
    double? x,
    double? y,
    double? z,
    int? interval,
  ) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(label),
        ),
        Text(x?.toStringAsFixed(1) ?? '?'),
        Text(y?.toStringAsFixed(1) ?? '?'),
        Text(z?.toStringAsFixed(1) ?? '?'),
        Text('${interval?.toString() ?? '?'} ms'),
      ],
    );
  }

  Widget _buildSensorIntervalSelector() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Update Interval:'),
        SegmentedButton(
          segments: [
            ButtonSegment(
              value: SensorInterval.gameInterval,
              label: Text('Game\n(${SensorInterval.gameInterval.inMilliseconds}ms)'),
            ),
            ButtonSegment(
              value: SensorInterval.uiInterval,
              label: Text('UI\n(${SensorInterval.uiInterval.inMilliseconds}ms)'),
            ),
            ButtonSegment(
              value: SensorInterval.normalInterval,
              label: Text('Normal\n(${SensorInterval.normalInterval.inMilliseconds}ms)'),
            ),
            const ButtonSegment(
              value: Duration(milliseconds: 500),
              label: Text('500ms'),
            ),
            const ButtonSegment(
              value: Duration(seconds: 1),
              label: Text('1s'),
            ),
          ],
          selected: {sensorInterval},
          showSelectedIcon: false,
          onSelectionChanged: (value) {
            setState(() {
              sensorInterval = value.first;
              userAccelerometerEventStream(samplingPeriod: sensorInterval);
              accelerometerEventStream(samplingPeriod: sensorInterval);
              gyroscopeEventStream(samplingPeriod: sensorInterval);
              magnetometerEventStream(samplingPeriod: sensorInterval);
              barometerEventStream(samplingPeriod: sensorInterval);
            });
          },
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _streamSubscriptions.add(
      userAccelerometerEventStream(samplingPeriod: sensorInterval).listen(
        (UserAccelerometerEvent event) {
          final now = event.timestamp;
          setState(() {
            _userAccelerometerEvent = event;
            if (_userAccelerometerUpdateTime != null) {
              final interval = now.difference(_userAccelerometerUpdateTime!);
              _userAccelerometerLastInterval = interval.inMilliseconds;
            }
            _userAccelerometerUpdateTime = now;
          });
        },
      ),
    );

    _streamSubscriptions.add(
      accelerometerEventStream(samplingPeriod: sensorInterval).listen(
        (AccelerometerEvent event) {
          final now = event.timestamp;
          setState(() {
            _accelerometerEvent = event;
            if (_accelerometerUpdateTime != null) {
              final interval = now.difference(_accelerometerUpdateTime!);
              _accelerometerLastInterval = interval.inMilliseconds;
            }
            _accelerometerUpdateTime = now;
          });
        },
      ),
    );

    _streamSubscriptions.add(
      gyroscopeEventStream(samplingPeriod: sensorInterval).listen(
        (GyroscopeEvent event) {
          final now = event.timestamp;
          setState(() {
            _gyroscopeEvent = event;
            if (_gyroscopeUpdateTime != null) {
              final interval = now.difference(_gyroscopeUpdateTime!);
              _gyroscopeLastInterval = interval.inMilliseconds;
            }
            _gyroscopeUpdateTime = now;
          });
        },
      ),
    );

    _streamSubscriptions.add(
      magnetometerEventStream(samplingPeriod: sensorInterval).listen(
        (MagnetometerEvent event) {
          final now = event.timestamp;
          setState(() {
            _magnetometerEvent = event;
            if (_magnetometerUpdateTime != null) {
              final interval = now.difference(_magnetometerUpdateTime!);
              _magnetometerLastInterval = interval.inMilliseconds;
            }
            _magnetometerUpdateTime = now;
          });
        },
      ),
    );

    _streamSubscriptions.add(
      barometerEventStream(samplingPeriod: sensorInterval).listen(
        (BarometerEvent event) {
          final now = event.timestamp;
          setState(() {
            _barometerEvent = event;
            if (_barometerUpdateTime != null) {
              final interval = now.difference(_barometerUpdateTime!);
              _barometerLastInterval = interval.inMilliseconds;
            }
            _barometerUpdateTime = now;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}

// The Snake game implementation
class Snake extends StatefulWidget {
  Snake({super.key, this.rows = 20, this.columns = 20, this.cellSize = 10.0}) {
    assert(10 <= rows);
    assert(10 <= columns);
    assert(5.0 <= cellSize);
  }

  final int rows;
  final int columns;
  final double cellSize;

  @override
  State<StatefulWidget> createState() => SnakeState(rows, columns, cellSize);
}

class SnakeBoardPainter extends CustomPainter {
  SnakeBoardPainter(this.state, this.cellSize);

  GameState? state;
  double cellSize;

  @override
  void paint(Canvas canvas, Size size) {
    final blackLine = Paint()..color = Colors.black;
    final blackFilled = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromPoints(Offset.zero, size.bottomLeft(Offset.zero)),
      blackLine,
    );
    for (final p in state!.body) {
      final a = Offset(cellSize * p.x, cellSize * p.y);
      final b = Offset(cellSize * (p.x + 1), cellSize * (p.y + 1));

      canvas.drawRect(Rect.fromPoints(a, b), blackFilled);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class SnakeState extends State<Snake> {
  SnakeState(int rows, int columns, this.cellSize) {
    state = GameState(rows, columns);
  }

  double cellSize;
  GameState? state;
  AccelerometerEvent? acceleration;
  late StreamSubscription<AccelerometerEvent> _streamSubscription;
  late Timer _timer;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: SnakeBoardPainter(state, cellSize));
  }

  @override
  void dispose() {
    super.dispose();
    _streamSubscription.cancel();
    _timer.cancel();
  }

  @override
  void initState() {
    super.initState();
    _streamSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        acceleration = event;
      });
    });

    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      setState(() {
        _step();
      });
    });
  }

  void _step() {
    final newDirection = acceleration == null
        ? null
        : acceleration!.x.abs() < 1.0 && acceleration!.y.abs() < 1.0
            ? null
            : (acceleration!.x.abs() < acceleration!.y.abs())
                ? math.Point<int>(0, acceleration!.y.sign.toInt())
                : math.Point<int>(-acceleration!.x.sign.toInt(), 0);
    state!.step(newDirection);
  }
}

class GameState {
  GameState(this.rows, this.columns) {
    snakeLength = math.min(rows, columns) - 5;
  }

  int rows;
  int columns;
  late int snakeLength;

  List<math.Point<int>> body = <math.Point<int>>[const math.Point<int>(0, 0)];
  math.Point<int> direction = const math.Point<int>(1, 0);

  void step(math.Point<int>? newDirection) {
    var next = body.last + direction;
    next = math.Point<int>(next.x % columns, next.y % rows);

    body.add(next);
    if (body.length > snakeLength) body.removeAt(0);
    direction = newDirection ?? direction;
  }
}
