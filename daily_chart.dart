// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class DailyChart extends StatefulWidget {
  const DailyChart({
    super.key,
    this.width,
    this.height,
    required this.invoiceRecords,
    required this.inventoryRecords,
    required this.config,
  });

  final double? width;
  final double? height;
  final List<InvoicesRecord> invoiceRecords;
  final List<InventoryRecord> inventoryRecords;
  final ChartConfigStruct config;

  @override
  State<DailyChart> createState() => _DailyChartState();
}

class _DailyChartState extends State<DailyChart> {
  late List<SalesData> _salesData;
  late List<PurchaseData> _purchaseData;

  @override
  void initState() {
    super.initState();
    _salesData =
        calculateSalesData(widget.invoiceRecords, widget.inventoryRecords);
    _purchaseData =
        calculatePurchaseData(widget.invoiceRecords, widget.inventoryRecords);
    // Sort the data by date
    _salesData.sort((a, b) => a.date.compareTo(b.date));
    _purchaseData.sort((a, b) => a.date.compareTo(b.date));
  }

  List<SalesData> calculateSalesData(List<InvoicesRecord> invoiceRecords,
      List<InventoryRecord> inventoryRecords) {
    Map<DateTime, double?> dataMap = {};

    for (var invoice in invoiceRecords) {
      var result = invoiceListPricesResult(
          [invoice], inventoryRecords, InvoiceType.Sale);
      DateTime date = DateTime.now();

      if (invoice.invoiceType == 1) {
        DateTime? creationDate = invoice.generalInvoiceInfo?.creationDate;
        date = creationDate ?? DateTime.now();
      }
      double? value = result.netSalesRevenue;

      if (value != null) {
        dataMap.update(date, (existingValue) => existingValue! + value,
            ifAbsent: () => value);
      }
    }

    return dataMap.entries
        .map((entry) => SalesData(entry.key, entry.value))
        .toList();
  }

  List<PurchaseData> calculatePurchaseData(List<InvoicesRecord> invoiceRecords,
      List<InventoryRecord> inventoryRecords) {
    Map<DateTime, double?> dataMap = {};

    for (var invoice in invoiceRecords) {
      var result =
          invoiceListPricesResult([invoice], inventoryRecords, InvoiceType.Buy);
      DateTime date = DateTime.now();

      if (invoice.invoiceType == 0) {
        DateTime? creationDate = invoice.generalInvoiceInfo?.creationDate;
        date = creationDate ?? DateTime.now();
      }

      double? value = result.totalBuyingPrice;

      if (value != null) {
        dataMap.update(date, (existingValue) => existingValue! + value,
            ifAbsent: () => value);
      }
    }

    return dataMap.entries
        .map((entry) => PurchaseData(entry.key, entry.value))
        .toList();
  }

  List<CartesianSeries> _getChartSeries() {
    switch (widget.config.chartType) {
      case ChartType.line:
        return widget.config.lineType == LineType.broken
            ? _getBrokenLineSeries()
            : _getCurvedLineSeries();
      case ChartType.column:
        return _getColumnSeries();
      case ChartType.area:
        return _getAreaSeries();
      default:
        return _getBrokenLineSeries();
    }
  }

  List<CartesianSeries> _getBrokenLineSeries() {
    return <CartesianSeries>[
      LineSeries<SalesData, DateTime>(
        name: 'Sales',
        dataSource: _salesData,
        xValueMapper: (SalesData sales, _) => sales.date,
        yValueMapper: (SalesData sales, _) => sales.sales,
        markerSettings: MarkerSettings(isVisible: true),
        dataLabelSettings:
            DataLabelSettings(isVisible: widget.config.showLabels),
        color: widget.config.salesLineColor ?? Colors.blue,
        emptyPointSettings: EmptyPointSettings(
          color: Colors.grey,
          mode: EmptyPointMode.gap,
          borderColor: Colors.transparent,
          borderWidth: 2.0,
        ),
      ),
      LineSeries<PurchaseData, DateTime>(
        name: 'Purchases',
        dataSource: _purchaseData,
        xValueMapper: (PurchaseData purchases, _) => purchases.date,
        yValueMapper: (PurchaseData purchases, _) => purchases.purchases,
        markerSettings: MarkerSettings(isVisible: true),
        dataLabelSettings:
            DataLabelSettings(isVisible: widget.config.showLabels),
        color: widget.config.purchaseLineColor ?? Colors.red,
        emptyPointSettings: EmptyPointSettings(
          color: Colors.grey,
          mode: EmptyPointMode.gap,
          borderColor: Colors.transparent,
          borderWidth: 2.0,
        ),
      ),
    ];
  }

  List<CartesianSeries> _getCurvedLineSeries() {
    return <CartesianSeries>[
      SplineSeries<SalesData, DateTime>(
        name: 'Sales',
        dataSource: _salesData,
        xValueMapper: (SalesData sales, _) => sales.date,
        yValueMapper: (SalesData sales, _) => sales.sales,
        markerSettings: MarkerSettings(isVisible: true),
        dataLabelSettings:
            DataLabelSettings(isVisible: widget.config.showLabels),
        color: widget.config.salesLineColor ?? Colors.blue,
        dashArray: widget.config.fillBelowLine ? [5, 5] : null,
        emptyPointSettings: EmptyPointSettings(
          color: Colors.grey,
          mode: EmptyPointMode.gap,
          borderColor: Colors.transparent,
          borderWidth: 2.0,
        ),
      ),
      SplineSeries<PurchaseData, DateTime>(
        name: 'Purchases',
        dataSource: _purchaseData,
        xValueMapper: (PurchaseData purchases, _) => purchases.date,
        yValueMapper: (PurchaseData purchases, _) => purchases.purchases,
        markerSettings: MarkerSettings(isVisible: true),
        dataLabelSettings:
            DataLabelSettings(isVisible: widget.config.showLabels),
        color: widget.config.purchaseLineColor ?? Colors.red,
        dashArray: widget.config.fillBelowLine ? [5, 5] : null,
        emptyPointSettings: EmptyPointSettings(
          color: Colors.grey,
          mode: EmptyPointMode.gap,
          borderColor: Colors.transparent,
          borderWidth: 2.0,
        ),
      ),
    ];
  }

  List<CartesianSeries> _getColumnSeries() {
    return <CartesianSeries>[
      ColumnSeries<SalesData, DateTime>(
        name: 'Sales',
        dataSource: _salesData,
        xValueMapper: (SalesData sales, _) => sales.date,
        yValueMapper: (SalesData sales, _) => sales.sales,
        dataLabelSettings:
            DataLabelSettings(isVisible: widget.config.showLabels),
        color: widget.config.salesLineColor ?? Colors.blue,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
        emptyPointSettings: EmptyPointSettings(
          color: Colors.grey,
          mode: EmptyPointMode.gap,
          borderColor: Colors.transparent,
          borderWidth: 2.0,
        ),
      ),
      ColumnSeries<PurchaseData, DateTime>(
        name: 'Purchases',
        dataSource: _purchaseData,
        xValueMapper: (PurchaseData purchases, _) => purchases.date,
        yValueMapper: (PurchaseData purchases, _) => purchases.purchases,
        dataLabelSettings:
            DataLabelSettings(isVisible: widget.config.showLabels),
        color: widget.config.purchaseLineColor ?? Colors.red,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
        emptyPointSettings: EmptyPointSettings(
          color: Colors.grey,
          mode: EmptyPointMode.gap,
          borderColor: Colors.transparent,
          borderWidth: 2.0,
        ),
      ),
    ];
  }

  List<CartesianSeries> _getAreaSeries() {
    return <CartesianSeries>[
      SplineAreaSeries<SalesData, DateTime>(
        name: 'Sales',
        dataSource: _salesData,
        xValueMapper: (SalesData sales, _) => sales.date,
        yValueMapper: (SalesData sales, _) => sales.sales,
        dataLabelSettings:
            DataLabelSettings(isVisible: widget.config.showLabels),
        color: (widget.config.salesLineColor ?? Colors.blue).withOpacity(0.5),
        borderColor: widget.config.salesLineColor ?? Colors.blue,
        borderWidth: 2,
      ),
      SplineAreaSeries<PurchaseData, DateTime>(
        name: 'Purchases',
        dataSource: _purchaseData,
        xValueMapper: (PurchaseData purchases, _) => purchases.date,
        yValueMapper: (PurchaseData purchases, _) => purchases.purchases,
        dataLabelSettings:
            DataLabelSettings(isVisible: widget.config.showLabels),
        color: (widget.config.purchaseLineColor ?? Colors.red).withOpacity(0.5),
        borderColor: widget.config.purchaseLineColor ?? Colors.red,
        borderWidth: 2,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: widget.width,
        height: widget.height,
        child: SfCartesianChart(
          legend: Legend(isVisible: true, position: LegendPosition.bottom),
          primaryXAxis: DateTimeAxis(
            edgeLabelPlacement: EdgeLabelPlacement.shift,
            title: widget.config.showLabels
                ? AxisTitle(text: 'Date')
                : AxisTitle(),
            intervalType: DateTimeIntervalType.days,
            dateFormat: DateFormat('MM/dd'),
            majorGridLines: widget.config.showGridLines
                ? MajorGridLines(width: 1)
                : MajorGridLines(width: 0),
            labelStyle: TextStyle(fontSize: 10),
          ),
          primaryYAxis: widget.config.showYAxis
              ? NumericAxis(
                  labelFormat:
                      widget.config.showCurrency ? '\${value}' : '{value}',
                  numberFormat: NumberFormat.compact(),
                  title: widget.config.showLabels
                      ? AxisTitle(text: 'Amount')
                      : AxisTitle(),
                  majorGridLines: widget.config.showGridLines
                      ? MajorGridLines(width: 1)
                      : MajorGridLines(width: 0),
                  labelStyle: TextStyle(fontSize: 10),
                )
              : NumericAxis(
                  isVisible: false,
                ),
          zoomPanBehavior: ZoomPanBehavior(
            enablePanning: true,
            enablePinching: true,
            zoomMode: ZoomMode.x,
          ),
          series: _getChartSeries(),
          tooltipBehavior: TooltipBehavior(enable: true),
        ),
      ),
    );
  }
}

class SalesData {
  SalesData(this.date, this.sales);
  final DateTime date;
  final double? sales;
}

class PurchaseData {
  PurchaseData(this.date, this.purchases);
  final DateTime date;
  final double? purchases;
}
