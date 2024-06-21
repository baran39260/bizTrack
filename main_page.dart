import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:touchable/touchable.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom Line Chart',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final double _heightChart = 250.0;
  final _refreshChart$ = StreamController<Key>();

  @override
  void initState() {
    super.initState();
    _refreshChart$.add(UniqueKey());
  }

  @override
  void dispose() {
    _refreshChart$.close();
    super.dispose();
  }

  void _refreshChart() {
    _refreshChart$.add(UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales Chart"),
        actions: [
          IconButton(
            onPressed: _refreshChart,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          clipBehavior: Clip.hardEdge,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xffEBEBEB)),
            color: Colors.black12,
          ),
          child: StreamBuilder<Key>(
            stream: _refreshChart$.stream,
            builder: (context, snapshot) {
              if (snapshot.data == null) return const SizedBox.shrink();
              return SalesChartView(
                key: snapshot.data,
                heightChart: _heightChart,
              );
            },
          ),
        ),
      ),
    );
  }
}

class SalesChartView extends StatefulWidget {
  final double heightChart;

  const SalesChartView({
    super.key,
    required this.heightChart,
  });

  @override
  State<SalesChartView> createState() => _SalesChartViewState();
}

class _SalesChartViewState extends State<SalesChartView> with SingleTickerProviderStateMixin {
  late final List<DailySale> _salesDataGenerated = SalesController.generateRandomSalesData(30);
  var _salesDataAnim = <DailySale>[];

  double _maxSale = -double.maxFinite;
  double _minSale = double.maxFinite;

  late final _controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
  late final _animation = Tween<double>(begin: 0.0, end: 1.0);

  @override
  void initState() {
    super.initState();
    _calculateMinMax();
    _startListenAnimation();
    _controller.forward();
  }

  void _calculateMinMax() {
    for (var sale in _salesDataGenerated) {
      _minSale = sale.saleAmount < _minSale ? sale.saleAmount : _minSale;
      _maxSale = sale.saleAmount > _maxSale ? sale.saleAmount : _maxSale;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startListenAnimation() {
    _animation.animate(_controller).addListener(() {
      final result = <DailySale>[];
      for (var sale in _salesDataGenerated) {
        final diffSale = sale.saleAmount - _minSale;
        final newSale = DailySale(
          date: sale.date,
          saleAmount: _minSale + diffSale * _controller.value,
        );
        result.add(newSale);
      }
      setState(() {
        _salesDataAnim = result;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return CanvasTouchDetector(
      gesturesToOverride: const [GestureType.onTapDown],
      builder: (context) {
        return CustomPaint(
          painter: SalesChartPainter(
            salesData: _salesDataAnim,
            heightView: widget.heightChart,
            minSale: _minSale,
            maxSale: _maxSale,
            context: context,
            onPointClick: (sale) {
              for (var e in _salesDataAnim) {
                if (e == sale) {
                  e.isFocusing = !e.isFocusing;
                } else {
                  e.isFocusing = false;
                }
              }
              setState(() {
                _salesDataAnim = [..._salesDataAnim];
              });
            },
          ),
          size: Size(double.infinity, widget.heightChart),
        );
      },
    );
  }
}

class DailySale {
  final DateTime date;
  final double saleAmount;
  bool isFocusing;

  DailySale({required this.date, required this.saleAmount, this.isFocusing = false});
}

class SalesController {
  final List<DailySale> salesData;

  SalesController({required this.salesData});

  static List<DailySale> generateRandomSalesData(int days) {
    final random = Random();
    final salesData = <DailySale>[];
    for (int i = 0; i < days; i++) {
      final saleAmount = random.nextDouble() * 1000;
      final date = DateTime.now().subtract(Duration(days: i));
      salesData.add(DailySale(date: date, saleAmount: saleAmount));
    }
    return salesData;
  }

  double get maxSale => salesData.map((e) => e.saleAmount).reduce(max);

  double get minSale => salesData.map((e) => e.saleAmount).reduce(min);
}

class SalesChartPainter extends CustomPainter {
  final List<DailySale> salesData;
  final double heightView;
  final double minSale;
  final double maxSale;
  final BuildContext context;
  final Function(DailySale sale) onPointClick;

  SalesChartPainter({
    required this.salesData,
    required this.heightView,
    required this.minSale,
    required this.maxSale,
    required this.context,
    required this.onPointClick,
  });

  final _mainColor = const Color(0xff4259A4);
  final _backgroundColor = Colors.white;

  late final double ceilMax = maxSale.ceil() + 1.0;
  late final double floorMin = minSale.floor() - 1.0;
  final int qtyYLabels = 5;

  final double paddingTop = 30.0;
  final double paddingBottom = 30.0;
  final double paddingLeft = 30.0;
  final double paddingRight = 10.0;

  final tooltipLabelStyle = const TextStyle(color: Colors.white, fontSize: 12);
  final xAxisLabelStyle = const TextStyle(color: Color(0xff83808C), fontSize: 8);
  final yAxisLabelStyle = const TextStyle(color: Color(0xffAAA8B1), fontSize: 10);

  late final Paint pointInnerPaint = Paint()
    ..color = _mainColor
    ..style = PaintingStyle.fill;

  final Paint pointFocusingOuterPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  final Paint pointOuterPaint = Paint()
    ..color = Colors.white.withOpacity(0.5)
    ..style = PaintingStyle.fill;

  late final Paint tooltipPaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.fill;

  late final Paint connectPathPaint = Paint()
    ..color = _mainColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  late final Paint outlinePathPaint = Paint()
    ..style = PaintingStyle.fill
    ..shader = ui.Gradient.linear(
      Offset.zero,
      Offset(0, heightView),
      [
        _mainColor.withOpacity(0.32),
        _mainColor.withOpacity(0),
      ],
    );

  final Paint columnFocusingPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xffE6EAF6).withOpacity(0.5);

  final Paint tappableColumnPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.transparent;

  final Paint outlinePaint = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke
    ..color = const Color(0xffF4F4F4);

  final Paint dottedLinePaint = Paint()
    ..color = const Color(0xff83808C)
    ..strokeWidth = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final touchyCanvas = TouchyCanvas(context, canvas);

    final clipRRect = RRect.fromLTRBR(0, 0, size.width, size.height, const Radius.circular(4));
    canvas.clipRRect(clipRRect);

    final paint = Paint()..color = _backgroundColor;
    canvas.drawPaint(paint);

    final drawableHeight = size.height - paddingTop - paddingBottom;
    final drawableWidth = size.width - paddingLeft - paddingRight;
    final widthColumn = (drawableWidth / salesData.length).toDouble();
    final heightColumn = drawableHeight;

    if (heightColumn <= 0 || widthColumn <= 0) return;
    if (maxSale - minSale <= 0) return;

    final heightRatio = heightColumn / (ceilMax - floorMin);
    final center = Offset(paddingLeft + widthColumn / 2, paddingTop + heightColumn / 2);

    final points = _computePoints(center, widthColumn, heightColumn, heightRatio);

    final yPositions = _computeYPositions(
      paddingTop: paddingTop,
      heightRatio: heightColumn / (qtyYLabels - 1),
      qty: qtyYLabels,
    );

    _drawHorizontalOutline(canvas, yPositions, paddingLeft, size.width - paddingRight);
    _drawVerticalOutline(canvas, center, widthColumn, heightColumn);

    final connectPath = _computeConnectPath(
      points: points,
      paddingLeft: paddingLeft,
      widthColumn: widthColumn,
      maxDx: size.width - paddingRight - widthColumn / 2,
      maxDy: size.height,
    );
    canvas.drawPath(connectPath, connectPathPaint);

    final borderPath = _computeBorderPath(
      points: points,
      paddingLeft: paddingLeft,
      widthColumn: widthColumn,
      maxDy: size.height,
    );
    canvas.drawPath(borderPath, outlinePathPaint);

    final xLabels = _computeXLabels(salesData);
    _drawXAxisLabels(canvas, center, xLabels, points, widthColumn, drawableHeight + paddingTop + 8);

    final yLabels = _computeYLabels(qtyYLabels);
    _drawYAxisLabels(canvas, center, yLabels, yPositions, paddingLeft);

    _drawPoints(points, touchyCanvas, canvas, size.height, drawableHeight, widthColumn);

    final tooltipLabels = _computeTooltipLabels(salesData);
    _drawTooltip(canvas, center, tooltipLabels, points, 62);
  }

  void _drawHorizontalOutline(Canvas canvas, List<Offset> positions, double startDx, double endDx) {
    for (var position in positions) {
      final path = Path();
      path.moveTo(startDx, position.dy);
      path.lineTo(endDx, position.dy);
      canvas.drawPath(path, outlinePaint);
    }
  }

  void _drawVerticalOutline(Canvas canvas, Offset center, double width, double height) {
    for (var _ in salesData) {
      final rect = Rect.fromCenter(center: center, width: width, height: height);
      canvas.drawRect(rect, outlinePaint);
      center += Offset(width, 0);
    }
  }

  void _drawYAxisLabels(Canvas canvas, Offset center, List<String> labels, List<Offset> positions, double labelMaxWidth) {
    for (var i = 0; i < labels.length; i++) {
      final label = labels[i];
      final yPoint = positions[i];
      final textPainter = _getTextPainter(label, yAxisLabelStyle, labelMaxWidth);
      final position = Offset(0, yPoint.dy - textPainter.height / 2);
      textPainter.paint(canvas, position);
      center += Offset(labelMaxWidth, 0);
    }
  }

  void _drawXAxisLabels(Canvas canvas, Offset center, List<String> labels, List<Offset> points, double labelMaxWidth, double labelMarginTop) {
    for (var i = 0; i < labels.length; i++) {
      final label = labels[i];
      final point = points[i];
      final textPainter = _getTextPainter(label, xAxisLabelStyle, labelMaxWidth);
      final position = Offset(point.dx - textPainter.width / 2, labelMarginTop);
      textPainter.paint(canvas, position);
      center += Offset(labelMaxWidth, 0);
    }
  }

  void _drawTooltip(Canvas canvas, Offset center, List<String> labels, List<Offset> points, double labelMaxWidth) {
    for (var i = 0; i < labels.length; i++) {
      const spaceBetweenPointAndTooltip = 12.0;
      final label = labels[i];
      final point = points[i];

      final textPainter = _getTextPainter(label, tooltipLabelStyle, labelMaxWidth);
      final sale = salesData[i];
      final position = point + Offset(-textPainter.width / 2, -textPainter.height / 2) + const Offset(0, -12 - spaceBetweenPointAndTooltip);

      if (sale.isFocusing) {
        const widthTooltip = 63.0;
        const heightTooltip = 26.0;
        canvas.drawRRect(
          RRect.fromLTRBR(
            point.dx - widthTooltip / 2,
            point.dy - heightTooltip - spaceBetweenPointAndTooltip,
            point.dx + widthTooltip / 2,
            point.dy - spaceBetweenPointAndTooltip,
            const Radius.circular(12),
          ),
          tooltipPaint,
        );

        const triangleW = 10;
        const triangleH = 5;
        final Path trianglePath = Path()
          ..moveTo(point.dx - triangleW / 2, point.dy - spaceBetweenPointAndTooltip)
          ..lineTo(point.dx, point.dy - spaceBetweenPointAndTooltip + triangleH)
          ..lineTo(point.dx + triangleW / 2, point.dy - spaceBetweenPointAndTooltip)
          ..lineTo(point.dx - triangleW / 2, point.dy - spaceBetweenPointAndTooltip);
        canvas.drawPath(trianglePath, tooltipPaint);

        textPainter.paint(canvas, position);
      }
      center += Offset(labelMaxWidth, 0);
    }
  }

  void _drawPoints(List<Offset> points, TouchyCanvas touchyCanvas, Canvas canvas, double maxDy, double drawableHeight, double widthFocusingColumn) {
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final sale = salesData[i];
      const radiusOuterCircle = 8.0;
      const radiusInnerCircle = 4.0;

      final columnFocusing = RRect.fromLTRBR(
        point.dx - widthFocusingColumn / 2,
        paddingTop,
        point.dx + widthFocusingColumn / 2,
        maxDy,
        const Radius.circular(8),
      );
      touchyCanvas.drawRRect(
        columnFocusing,
        sale.isFocusing ? columnFocusingPaint : tappableColumnPaint,
        onTapDown: (_) => onPointClick(sale),
      );

      if (sale.isFocusing) {
        double startY = paddingTop;
        const dashHeight = 3, dashSpace = 3;
        while (startY < drawableHeight + paddingTop) {
          canvas.drawLine(Offset(point.dx, startY), Offset(point.dx, startY + 2), dottedLinePaint);
          startY += dashHeight + dashSpace;
        }
      }

      touchyCanvas.drawCircle(
        point,
        radiusOuterCircle,
        sale.isFocusing ? pointFocusingOuterPaint : pointOuterPaint,
        onTapDown: (_) => onPointClick(sale),
      );

      touchyCanvas.drawCircle(
        point,
        radiusInnerCircle,
        pointInnerPaint,
        onTapDown: (_) => onPointClick(sale),
      );
    }
  }

  TextPainter _getTextPainter(String text, TextStyle style, double maxWidth) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(text: textSpan, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    textPainter.layout(minWidth: 0, maxWidth: maxWidth);
    return textPainter;
  }

  List<String> _computeTooltipLabels(List<DailySale> salesData) {
    return salesData.map((e) => "${e.saleAmount.toStringAsFixed(1)} \$").toList();
  }

  List<String> _computeXLabels(List<DailySale> salesData) {
    return salesData
        .map((e) => "${DateFormat.d().format(e.date)}\n ${DateFormat.MMM().format(e.date)}")
        .toList();
  }

  List<String> _computeYLabels(int qty) {
    final result = <String>[];
    final ratio = (ceilMax - floorMin) / (qty - 1);
    var value = ceilMax;
    for (var i = 1; i <= qty; i++) {
      result.add(value.toStringAsFixed(1));
      value -= ratio;
    }
    return result;
  }

  List<Offset> _computeYPositions({required double paddingTop, required double heightRatio, required int qty}) {
    final points = <Offset>[];
    for (var i = 1; i <= qty; i++) {
      final dp = Offset(0, paddingTop);
      points.add(dp);
      paddingTop += heightRatio;
    }
    return points;
  }

  List<Offset> _computePoints(Offset center, double widthColumn, double heightColumn, double heightRatio) {
    final points = <Offset>[];
    for (var sale in salesData) {
      final yy = heightColumn - (sale.saleAmount - floorMin) * heightRatio;
      final dp = Offset(center.dx, center.dy - heightColumn / 2 + yy);
      points.add(dp);
      center += Offset(widthColumn, 0);
    }
    return points;
  }

  Path _computeConnectPath({
    required List<Offset> points,
    required double paddingLeft,
    required double widthColumn,
    required double maxDx,
    required double maxDy,
  }) {
    final path = Path();
    final segWidth = widthColumn / 3;
    for (var i = 0; i < points.length; i++) {
      final currentPoint = points[i];
      if (i == 0) {
        path.moveTo(currentPoint.dx, currentPoint.dy);
      } else {
        final previousPoint = points[i - 1];
        final initialPaddingLeft = paddingLeft + widthColumn / 2;
        path.cubicTo(
          initialPaddingLeft + (widthColumn * (i - 1)) + segWidth,
          previousPoint.dy,
          initialPaddingLeft + (widthColumn * (i - 1)) + segWidth * 2,
          currentPoint.dy,
          currentPoint.dx,
          currentPoint.dy,
        );
      }
    }
    return path;
  }

  Path _computeBorderPath({
    required List<Offset> points,
    required double paddingLeft,
    required double widthColumn,
    required double maxDy,
  }) {
    final path = Path();
    final segWidth = widthColumn / 3;
    for (var i = 0; i < points.length; i++) {
      final currentPoint = points[i];
      if (i == 0) {
        path.moveTo(currentPoint.dx, currentPoint.dy);
      } else {
        final previousPoint = points[i - 1];
        final initialPaddingLeft = paddingLeft + widthColumn / 2;
        path.cubicTo(
          initialPaddingLeft + (widthColumn * (i - 1)) + segWidth,
          previousPoint.dy,
          initialPaddingLeft + (widthColumn * (i - 1)) + segWidth * 2,
          currentPoint.dy,
          currentPoint.dx,
          currentPoint.dy,
        );
      }
    }

    if (points.isNotEmpty) {
      path.lineTo(points.last.dx, maxDy);
      path.lineTo(points.first.dx, maxDy);
      path.lineTo(points.first.dx, points.first.dy);
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
