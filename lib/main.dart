import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey[800],
        appBar: AppBar(
          title: const Text('PID Control Simulator'),
          backgroundColor: Colors.grey[700],
          foregroundColor: Colors.white.withOpacity(0.9),
        ),
        body: const PIDControlSimulator(),
      ),
    );
  }
}

class PIDControlSimulator extends StatefulWidget {
  const PIDControlSimulator({super.key});

  @override
  State<PIDControlSimulator> createState() => _PIDControlSimulatorState();
}

class _PIDControlSimulatorState extends State<PIDControlSimulator> {
  double _p = 0.0;
  double _i = 0.0;
  double _d = 0.0;
  double _a = 0.0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PIDKnobs(
              onPChanged: (value) => setState(() => _p = value),
              onIChanged: (value) => setState(() => _i = value),
              onDChanged: (value) => setState(() => _d = value),
              onAChanged: (value) => setState(() => _a = value),
            ),
            LeverActuator(p: _p, i: _i, d: _d, a: _a),
          ],
        ),
      ),
    );
  }
}

class Knob extends StatefulWidget {
  final String title;
  final ValueChanged<double> onValueChanged;
  final double min;
  final double max;
  final Color knobColor;

  const Knob({
    super.key,
    required this.title,
    required this.onValueChanged,
    this.min = 0.0,
    this.max = 1.0,
    required this.knobColor,
  });

  @override
  State<Knob> createState() => _KnobState();
}

class _KnobState extends State<Knob> {
  double _value = 0.0;

  void _updateValue(Offset delta) {
    setState(() {
      _value += -delta.dy / (1 / widget.max * 200);
      if (_value < widget.min) _value = widget.min;
      if (_value > widget.max) _value = widget.max;
      widget.onValueChanged(_value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1 / 2,
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: GestureDetector(
              onPanUpdate: (details) {
                _updateValue(details.delta);
              },
              child: CustomPaint(
                size: Size.infinite,
                painter: _KnobPainter(
                    _value, widget.min, widget.max, widget.knobColor),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: FittedBox(
              child: Text(
                widget.title,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
          Expanded(
            child: FittedBox(
              child: Text(
                _value.toStringAsFixed(5),
                style: const TextStyle(color: Colors.white54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KnobPainter extends CustomPainter {
  final double value;
  final double minValue;
  final double maxValue;
  final Color knobColor;

  _KnobPainter(this.value, this.minValue, this.maxValue, this.knobColor);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white54
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width / 10
      ..strokeCap = StrokeCap.round;

    double radius = min(size.width, size.height) / 2;
    Offset center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, radius, paint);
    paint.color = knobColor.withOpacity(0.5);
    canvas.drawCircle(center, radius / 5, paint);

    double normalizedValue = (value - minValue) / (maxValue - minValue);
    double angle = normalizedValue * 2 * pi;
    Offset knobIndicator = Offset(
      center.dx + radius * cos(angle - pi / 2),
      center.dy + radius * sin(angle - pi / 2),
    );
    paint.color = Colors.white;
    paint.strokeWidth = size.width / 10;
    canvas.drawLine(center, knobIndicator, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class PIDKnobs extends StatelessWidget {
  final ValueChanged<double> onPChanged;
  final ValueChanged<double> onIChanged;
  final ValueChanged<double> onDChanged;
  final ValueChanged<double> onAChanged;

  const PIDKnobs({
    super.key,
    required this.onPChanged,
    required this.onIChanged,
    required this.onDChanged,
    required this.onAChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // double padding = constraints.maxWidth / 4;
        return AspectRatio(
          aspectRatio: 3 / 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Knob(
                title: 'P',
                onValueChanged: onPChanged,
                min: 0,
                max: 0.1,
                knobColor: Colors.red,
              ),
              Knob(
                title: 'I',
                onValueChanged: onIChanged,
                min: 0,
                max: 0.005,
                knobColor: Colors.green,
              ),
              Knob(
                title: 'D',
                onValueChanged: onDChanged,
                min: 0,
                max: 0.1,
                knobColor: Colors.blue,
              ),
              Knob(
                title: 'Angle',
                onValueChanged: onAChanged,
                min: 0,
                max: 2 * pi,
                knobColor: Colors.white38,
              ),
            ],
          ),
        );
      },
    );
  }
}

class LeverActuator extends StatefulWidget {
  final double p;
  final double i;
  final double d;
  final double a;

  const LeverActuator({
    super.key,
    required this.p,
    required this.i,
    required this.d,
    required this.a,
  });

  @override
  State<LeverActuator> createState() => _LeverActuatorState();
}

class _LeverActuatorState extends State<LeverActuator> {
  double _leverAngle = -pi / 2;
  double _leverSpeed = 0;
  double _leverAcceleration = 0;
  double _p = 0;
  double _i = 0;
  double _d = 0;
  double _integral = 0;
  double _previousError = 0;
  bool _isDragging = false;
  final double _mass = 1.0; // mass of the lever
  final double _friction = 0.01; // friction coefficient

  @override
  void initState() {
    super.initState();
    Timer.periodic(
        const Duration(milliseconds: 10), (timer) => _moveActuator());
    Timer.periodic(const Duration(milliseconds: 16), (timer) => _updateSpeed());
  }

  void _moveActuator() {
    if (!_isDragging) {
      setState(() {
        _leverSpeed += _leverAcceleration;
        _leverAngle += _leverSpeed;
        if (_leverAngle > pi) _leverAngle -= 2 * pi;
        if (_leverAngle < -pi) _leverAngle += 2 * pi;
        _leverSpeed *= (1 - _friction); // apply friction
      });
    }
  }

  void _updateSpeed() {
    if (!_isDragging) {
      double Kp = widget.p;
      double Ki = widget.i;
      double Kd = widget.d;
      setState(() {
        double targetAngle = widget.a - pi / 2;

        double error = _normalizeAngle(targetAngle - _leverAngle);
        double derivative = error - _previousError;
        _integral += error;

        _p = Kp * error;
        _i = Ki * _integral;
        _d = Kd * derivative;
        double control = _p + _i + _d;
        _previousError = error;

        _leverAcceleration = control / _mass; // calculate acceleration
      });
    }
  }

  double _normalizeAngle(double angle) {
    angle = angle % (2 * pi);
    if (angle > pi) {
      angle -= 2 * pi;
    } else if (angle < -pi) {
      angle += 2 * pi;
    }
    return angle;
  }

  void _updateAngle(DragUpdateDetails details) {
    setState(() {
      double dx = details.localPosition.dx - (context.size!.width / 2);
      double dy = details.localPosition.dy - (context.size!.height / 2);
      _leverAngle = atan2(dy, dx);
    });
  }

  void _onDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onPanStart: _onDragStart,
        onPanUpdate: _updateAngle,
        onPanEnd: _onDragEnd,
        child: CustomPaint(
          size: Size.infinite,
          painter: _LeverPainter(_leverAngle, _p, _i, _d, widget.a - pi / 2),
        ),
      ),
    );
  }
}

class _LeverPainter extends CustomPainter {
  final double leverAngle;
  final double _p;
  final double _i;
  final double _d;
  final double a;

  _LeverPainter(this.leverAngle, this._p, this._i, this._d, this.a);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width / 100
      ..strokeCap = StrokeCap.round;

    Paint fillPaint = Paint()..color = Colors.black.withOpacity(0.2);

    Offset center = Offset(size.width / 2, size.height / 2);
    double length = min(size.width, size.height) / 2.5;
    Offset angleEnd = Offset(
      center.dx + length * cos(a),
      center.dy + length * sin(a),
    );

    Offset leverEnd = Offset(
      center.dx + length * cos(leverAngle),
      center.dy + length * sin(leverAngle),
    );

    canvas.drawCircle(center, length * 1.1, fillPaint);
    canvas.drawCircle(center, length * 0.2, fillPaint);
    canvas.drawLine(center, leverEnd, paint);
    paint.color = Colors.white.withOpacity(0.3);
    canvas.drawLine(center, angleEnd, paint);

    fillPaint.color = Colors.red;
    canvas.drawCircle(leverEnd, size.width / 40, fillPaint);
    double rSize = length * 0.4;
    Rect rect = Rect.fromCenter(center: center, width: rSize, height: rSize);
    paint.color = Colors.red;
    canvas.drawArc(rect, a, _p * 100, false, paint);
    rSize += size.width / 30;
    Rect rect2 = Rect.fromCenter(center: center, width: rSize, height: rSize);
    paint.color = Colors.green;
    canvas.drawArc(rect2, a, _i * 100, false, paint);
    rSize += size.width / 30;
    Rect rect3 = Rect.fromCenter(center: center, width: rSize, height: rSize);
    paint.color = Colors.blue;
    canvas.drawArc(rect3, a, _d * 100, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
