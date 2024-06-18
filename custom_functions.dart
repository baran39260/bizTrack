import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'lat_lng.dart';
import 'place.dart';
import 'uploaded_file.dart';
import '/backend/backend.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import '/auth/firebase_auth/auth_util.dart';

List<String>? getImagePath() {
  List<String> imageUrls = [
    "https://img.icons8.com/parakeet/48/road-worker.png",
    "https://img.icons8.com/3d-fluency/94/work.png",
    "https://img.icons8.com/external-others-phat-plus/64/external-job-skills-blue-others-phat-plus-7.png",
    "https://img.icons8.com/dusk/64/engineer.png",
    "https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/ez-bill-master-oz3h2x/assets/wieh3iu4tbc5/bank.png",
    "https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/ez-bill-master-oz3h2x/assets/o1tn5onw83ag/barber.png",
    "https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/ez-bill-master-oz3h2x/assets/jqlxgbx6cwuj/baseball-player.png",
    "https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/ez-bill-master-oz3h2x/assets/bcud9jpnq3kc/beach-umbrella.png",
    "https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/ez-bill-master-oz3h2x/assets/tirl3y4jzbqw/air-hockey.png",
    "https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/ez-bill-master-oz3h2x/assets/vpkibpylt5mu/anchor.png",
    "https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/ez-bill-master-oz3h2x/assets/znycf81oeqgz/antivirus.png",
    "https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/ez-bill-master-oz3h2x/assets/7owgicxsvfxz/apple.png",
    "https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/ez-bill-master-oz3h2x/assets/bvrttfubzprt/back-undo-arrow.png",
    "https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/ez-bill-master-oz3h2x/assets/8idih4ry1fog/ball.png",
    "https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/ez-bill-master-oz3h2x/assets/oq58tsxi76xb/balloons.png",
    "https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/ez-bill-master-oz3h2x/assets/ybuira15ro7w/icons8-coffee-maker-96.png",
    "https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/ez-bill-master-oz3h2x/assets/uw6wxrijk8a3/icons8-smartphone-64.png",
    "https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/ez-bill-master-oz3h2x/assets/xnzyycpfntk7/icons8-fitness-tracker-53.png",
    "https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/ez-bill-master-oz3h2x/assets/c0lbyddj24ge/icons8-airpods-pro-96.png",
    "https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/ez-bill-master-oz3h2x/assets/jyq6bwi8mvhm/icons8-laptop-96.png",
    "https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/biz-track-rrpi29/assets/qb6k7z60cs1u/womens-shirt-96.png",
    "https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/biz-track-rrpi29/assets/vin8a0hx2539/sock-96.png",
    "https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/biz-track-rrpi29/assets/rpnaa7x8gptp/pant-64.png",
  ];
  return imageUrls;
}

ItemPriceDataStruct calculateInvoiceItemPrices(
    InvoiceItemsDataStruct invoiceitemData) {
  // Check if discount and tax are within the valid range
  if (invoiceitemData.discount < 0 || invoiceitemData.discount > 1) {
    throw ArgumentError('Discount should be between 0 and 1');
  }
  if (invoiceitemData.tax < 0 || invoiceitemData.tax > 1) {
    throw ArgumentError('Tax should be between 0 and 1');
  }

  // Calculate the total price before applying discount or tax
  double priceBeforeDiscount = 0.0;
  if (invoiceitemData.status == 0) {
    // Purchase
    priceBeforeDiscount =
        invoiceitemData.purchasePrice * invoiceitemData.quantity;
  } else {
    // Sale
    priceBeforeDiscount = invoiceitemData.salesPrice * invoiceitemData.quantity;
  }

  // Calculate the discounted price
  double discountedPrice = priceBeforeDiscount * (1 - invoiceitemData.discount);

  // Calculate discount amount
  double discountAmount = priceBeforeDiscount * invoiceitemData.discount;

  // Calculate the tax amount
  double taxAmount = discountedPrice * invoiceitemData.tax;

  // Calculate the final price
  double finalPrice = discountedPrice + taxAmount;

  // Calculate the profit
  double profit;
  if (invoiceitemData.status == 0) {
    // Purchase
    profit =
        finalPrice - (invoiceitemData.purchasePrice * invoiceitemData.quantity);
  } else {
    // Sale
    profit =
        finalPrice - (invoiceitemData.purchasePrice * invoiceitemData.quantity);
  }

  return ItemPriceDataStruct(
    priceBeforeDiscount: priceBeforeDiscount,
    discountAmount: discountAmount,
    taxAmount: taxAmount,
    totalItemAmount: finalPrice,
    profit: profit,
  );
}

double removePercentage(String percentageValue) {
  // Remove the percent sign from the text and convert it to a decimal number
  return double.parse(percentageValue.replaceAll('%', '')) / 100;
}

PersonsDataResultStruct? personsResult(List<PersonsRecord> personDocList) {
  double totalInitialCreditorBalance = 0.0;
  double totalInitialDebtorBalance = 0.0;

  for (var record in personDocList) {
    totalInitialCreditorBalance += record.creditAmount;
    totalInitialDebtorBalance += record.debAmount;
  }

  return PersonsDataResultStruct(
    totalInitialCreditorBalance: totalInitialCreditorBalance,
    totalInitialDebtorBalance: totalInitialDebtorBalance,
  );
}

FinAccounDataResultStruct? fnAccountsResult(
    List<FinancialAccountsRecord> fnAccountDocList) {
  double totalInitialAmount = 0.0;

  // Calculate total initial inventory cost
  for (var account in fnAccountDocList) {
    // Calculate initial value for the item by multiplying its initial quantity with its unit price
    double accountInitialValue = account.accountInitialBalance;

    // Add the initial value of the item to the total initial value
    totalInitialAmount += accountInitialValue;
  }
  return FinAccounDataResultStruct(initialAmount: totalInitialAmount);
}

double removeNumberSeparators(String input) {
  // remove Number Separators
  return double.parse(input.replaceAll(RegExp(r'[^\d.-]+'), ''));
}

List<String>? unitList(List<ItemsRecord>? itemList) {
  if (itemList == null || itemList.isEmpty) {
    return null;
  }

  Set<String> unitSet = Set<String>();

  for (var item in itemList) {
    if (item.unit != null && item.unit.isNotEmpty) {
      unitSet.add(item.unit);
    }
  }

  List<String> result = unitSet.toList();
  result.sort(); // Optional: Sort the units alphabetically
  return result;
}

ItemsDataResultStruct? itemsResult(List<ItemsRecord> itemDocList) {
  double totalInitialCost = 0.0;

  // Calculate total initial inventory cost
  for (var item in itemDocList) {
    // Calculate initial value for the item by multiplying its initial quantity with its unit price
    double itemInitialValue = (item.initialInventory?.quantity ?? 0) *
        (item.initialInventory.buyPrice ?? 0);

    // Add the initial value of the item to the total initial value
    totalInitialCost += itemInitialValue;
  }
  return ItemsDataResultStruct(totalInitialCost: totalInitialCost);
}

String? formatCardNumber(String? cardNumber) {
  if (cardNumber == null || cardNumber.isEmpty) {
    // If the input is null or empty, return null
    return null;
  }

  // Remove any non-numeric characters from the input
  String cleanedNumber = cardNumber.replaceAll(RegExp(r'\D+'), '');

  // Check if the cleaned number has at least 4 digits
  if (cleanedNumber.length < 4) {
    // If not, return the original number
    return cardNumber;
  }

  // Take the last 4 digits of the cleaned number
  String lastFourDigits = cleanedNumber.substring(cleanedNumber.length - 4);

  // Format the number with spaces after every 4 characters
  String formattedNumber = '';
  for (int i = 0; i < cleanedNumber.length - 4; i += 4) {
    formattedNumber += cleanedNumber.substring(i, i + 4) + ' ';
  }
  formattedNumber += lastFourDigits;

  return formattedNumber;
}

InvoiceCalculationResultStruct invoiceLevelPricesResult(
  List<InvoiceItemsDataStruct> invoiceItems,
  InvoiceFinancialInfoStruct invoiceFinancialInfo,
  InvoiceType invoiceType,
) {
  double totalRevenue = 0; // کل درآمد حاصل از فروش
  double totalCostOfGoods = 0; // کل هزینه کالاهای فروخته شده
  double totalDiscountGiven = 0; // کل تخفیفات ارائه شده
  double totalTaxCollected = 0; // کل مالیات جمع‌آوری شده
  double totalSaleValue = 0; // ارزش کل فروش

  totalRevenue = returnItemLevelSalePrice(invoiceItems);
  totalCostOfGoods = returnItemLevelBuyPrice(invoiceItems);
  totalDiscountGiven = returnItemLevelDiscount(invoiceItems, invoiceType);
  totalTaxCollected = returnItemLevelTax(invoiceItems, invoiceType);
  totalSaleValue = returnItemFinalPrice(invoiceItems, invoiceType);

  double grossSaleTotal = totalSaleValue; // کل فروش ناخالص
  double invoiceDiscount =
      grossSaleTotal * invoiceFinancialInfo.discount; // تخفیف سطح فاکتور
  double totalDiscount = totalDiscountGiven + invoiceDiscount; // کل تخفیفات
  double taxableSaleTotal =
      grossSaleTotal - invoiceDiscount; // کل فروش قابل مالیات
  double invoiceTax =
      taxableSaleTotal * invoiceFinancialInfo.taxRate; // مالیات سطح فاکتور
  double totalTax = totalTaxCollected + invoiceTax; // کل مالیات
  double netSaleTotal = grossSaleTotal -
      totalDiscount +
      totalTax +
      invoiceFinancialInfo.shippingCost; // کل فروش خالص

  double netRevenue = 0; // درآمد خالص
  double grossMargin = 0; // حاشیه سود ناخالص
  double netMargin = 0; // حاشیه سود خالص

  if (invoiceType == InvoiceType.Sale) {
    netRevenue = totalRevenue - invoiceDiscount;
    grossMargin = netRevenue - totalCostOfGoods;
    netMargin =
        netSaleTotal - totalCostOfGoods - invoiceFinancialInfo.shippingCost;
  } else if (invoiceType == InvoiceType.Buy) {
    // محاسبات مربوط به فاکتور خرید
    netMargin =
        netSaleTotal - totalCostOfGoods - invoiceFinancialInfo.shippingCost;
  }

  int numberOfItems = invoiceItems.length; // تعداد کالاها

  return InvoiceCalculationResultStruct(
    itemCount: numberOfItems,
    finalItemListTotal: grossSaleTotal,
    finalInvoiceTotal: netSaleTotal,
    netSalesRevenue: netRevenue,
    grossProfit: grossMargin,
    netProfit: netMargin,
    totalItemDiscount: totalDiscountGiven,
    invoiceLevelDiscount: invoiceDiscount,
    totalDiscount: totalDiscount,
    totalItemTax: totalTaxCollected,
    invoiceLevelTax: invoiceTax,
    totalTax: totalTax,
    taxableAmount: taxableSaleTotal,
    shippingCosts: invoiceFinancialInfo.shippingCost,
    totalBuyingPrice: totalCostOfGoods,
  );
}

double returnItemFinalPrice(
  List<InvoiceItemsDataStruct> itemsList,
  InvoiceType invoiceType,
) {
  double totalFinalPrice = 0.0;
  for (var item in itemsList) {
    double itemPrice = (invoiceType == InvoiceType.Sale)
        ? item.salesPrice * item.quantity
        : item.purchasePrice * item.quantity;
    double itemDiscount = itemPrice * item.discount;
    double itemTax = (itemPrice - itemDiscount) * item.tax;
    double itemFinalPrice = itemPrice - itemDiscount + itemTax;
    totalFinalPrice += itemFinalPrice;
  }
  return totalFinalPrice;
}

double returnItemLevelBuyPrice(List<InvoiceItemsDataStruct> itemsList) {
  double totalBuyPrice = 0.0;
  for (var item in itemsList) {
    double itemPrice = item.purchasePrice * item.quantity;
    totalBuyPrice += itemPrice;
  }
  return totalBuyPrice;
}

double returnItemLevelTax(
  List<InvoiceItemsDataStruct> itemsList,
  InvoiceType invoiceType,
) {
  double totalItemTax = 0.0;
  for (var item in itemsList) {
    double itemPrice = (invoiceType == InvoiceType.Sale)
        ? item.salesPrice * item.quantity
        : item.purchasePrice * item.quantity;
    double itemDiscount = itemPrice * item.discount;
    double itemTax = (itemPrice - itemDiscount) * item.tax;
    totalItemTax += itemTax;
  }
  return totalItemTax;
}

double returnItemLevelDiscount(
  List<InvoiceItemsDataStruct> itemsList,
  InvoiceType invoiceType,
) {
  double totalItemDiscount = 0.0;
  for (var item in itemsList) {
    double itemPrice = (invoiceType == InvoiceType.Sale)
        ? item.salesPrice * item.quantity
        : item.purchasePrice * item.quantity;
    double itemDiscount = itemPrice * item.discount;
    totalItemDiscount += itemDiscount;
  }
  return totalItemDiscount;
}

double returnItemLevelSalePrice(List<InvoiceItemsDataStruct> itemsList) {
  double totalSalesPrice = 0.0;
  for (var item in itemsList) {
    double itemPrice = item.salesPrice * item.quantity;
    totalSalesPrice += itemPrice;
  }
  return totalSalesPrice;
}

DateTime generateDueDate(int daysToAdd) {
  // add number to currentDate and determin new date
  final currentDate = DateTime.now();
  final newDate = currentDate.add(Duration(days: daysToAdd));
  return newDate;
}

String generateInvoiceNumber(
  int? currentInvoiceNumber,
  String? prefix,
  bool? showDate,
  bool? showDash,
) {
  /// Generates a new invoice number based on the provided parameters.
  ///
  /// This function takes several optional parameters to customize the generated
  /// invoice number. If [showDate] is true, the formatted current date will be
  /// included in the invoice number. If [showDash] is true, a dash will be added
  /// between date and the invoice number. If [prefix] is provided and not empty,
  /// it will be added to the beginning of the invoice number.
  ///
  /// The [currentInvoiceNumber] parameter is used to track the current invoice
  /// number, and it defaults to 1000 if not provided. The generated invoice
  /// number is incremented by 1 from the [currentInvoiceNumber].
  ///
  /// In case of any errors during the generation process, this function catches
  /// the error, prints an error message, and returns a default string 'Error'.
  ///
  /// Example usage:
  /// ```dart
  /// String invoiceNumber = generateInvoiceNumber(500, 'INV', true, true);
  /// print(invoiceNumber); // Output: "INV-20220405-501"
  /// ```

  try {
    int _currentInvoiceNumber;

    // Check if currentInvoiceNumber is null, set it to 1000
    if (currentInvoiceNumber == null) {
      _currentInvoiceNumber = 1000;
    } else {
      // Use the provided currentInvoiceNumber as an integer
      _currentInvoiceNumber = currentInvoiceNumber;
    }

    // Increment the invoice number
    _currentInvoiceNumber++;

    // Format the date if showDate is true
    String formattedDate = showDate == true
        ? DateTime.now().toString().split(' ')[0].replaceAll('-', '')
        : '';

    // Check if prefix is null or empty, set it to an empty string
    String _prefix = (prefix != null && prefix.isNotEmpty) ? '$prefix' : '';

    // Use dash if showDash is true
    String dash = showDash == true ? '-' : '';

    // Add a space after the date if it is displayed
    String dateSeparator = showDate == true ? '' : '';
    String prefixSeparator = (prefix != null && prefix.isNotEmpty) ? '' : '';

    // Add a dash after the date if it is displayed and showDash is true
    String dateDash = showDate == true && showDash == true ? '-' : '';
    String prefixDash =
        (prefix != null && prefix.isNotEmpty) && showDash == true ? '-' : '';

    // Return the generated invoice number
    return "$_prefix$prefixSeparator$prefixDash$formattedDate$dateSeparator$dateDash$_currentInvoiceNumber";
  } catch (e) {
    // Handle the error (you can log it, print a message, or take appropriate action)
    print('Error generating invoice number: $e');
    // You may choose to throw an error or return a default value based on your application's logic
    return 'Error';
  }
}

int? calculateCurrentStock(
  ItemsRecord itemDoc,
  List<InventoryRecord> inventoryList,
  int type,
) {
  // Check if itemDoc is null
  if (itemDoc == null) {
    throw ArgumentError('Invalid input: itemDoc is null.');
  }

  // Initialize total quantity
  int totalQuantity = 0;
  int initialQuantity = itemDoc.initialInventory?.quantity ?? 0;

  if (inventoryList != null && inventoryList.isNotEmpty) {
    // Iterate through the inventory list and sum up the quantities based on the specified type
    for (var item in inventoryList) {
      // Check if the item reference matches the specified itemDoc
      if (item.itemData.itemRef == itemDoc.reference) {
        // Increment total quantity if the item is of the specified type
        if (type == 0 && item.itemData.status == 0) {
          totalQuantity += item.itemData.quantity;
        } else if (type == 1 && item.itemData.status == 1) {
          totalQuantity -= item.itemData.quantity;
        } else if (type == -1) {
          // Include both entered and out items for calculating total quantity
          if (item.itemData.status == 0) {
            totalQuantity += item.itemData.quantity;
          } else if (item.itemData.status == 1) {
            totalQuantity -= item.itemData.quantity;
          }
        }
      }
    }
    return totalQuantity + initialQuantity;
  } else {
    return initialQuantity;
  }
}

String formatDateForDisplay(DateTime dateTime) {
  final now = DateTime.now();
  final yesterday = DateTime(now.year, now.month, now.day - 1);

  if (dateTime.year == now.year &&
      dateTime.month == now.month &&
      dateTime.day == now.day) {
    return 'Today';
  } else if (dateTime.year == yesterday.year &&
      dateTime.month == yesterday.month &&
      dateTime.day == yesterday.day) {
    return 'Yesterday';
  } else {
    final formatter = DateFormat.yMMMMEEEEd();
    return formatter.format(dateTime);
  }
}

String? calculateDaysUntilDue(
  DateTime? creationDate,
  DateTime? dueDate,
) {
  // Calculate the number of days left or past until the due date
  if (creationDate == null || dueDate == null) {
    return null;
  }

  final now =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final creation =
      DateTime(creationDate.year, creationDate.month, creationDate.day);
  final due = DateTime(dueDate.year, dueDate.month, dueDate.day);

  if (now.isBefore(creation)) {
    return 'Not';
  }

  final daysPast = now.difference(creation).inDays;
  final daysLeft = due.difference(now).inDays;

  if (daysLeft < 0) {
    return '$daysLeft';
  } else if (daysLeft == 0) {
    return '0';
  } else if (daysLeft == 1) {
    return '1';
  } else {
    return ' $daysLeft';
  }
}

int generateRandomNumber() {
  int timestamp = DateTime.now().millisecondsSinceEpoch;
  int randomNumber = ((timestamp % 4) + 1) * 100;
  return randomNumber;
}

String? removeCharacter(String? input) {
  // remove last Character from input
  if (input == null || input.isEmpty) {
    return input;
  }
  return input.substring(0, input.length - 1);
}

String formatCurrency(
  double number,
  CurrencyDataStruct currencyData,
) {
  // Check if the number is negative
  bool isNegative = number < 0;
  number = number.abs(); // Make the number positive for formatting

  String formattedNumber = number.toStringAsFixed(currencyData.digit);

  List<String> parts = formattedNumber.split('.');
  String integerPart = parts[0];
  String decimalPart =
      parts.length > 1 ? currencyData.decimalSeparator + parts[1] : '';

  // Add thousands separator to the integer part
  List<String> formattedIntegerParts = [];
  int start = integerPart.length % 3 == 0 ? 3 : integerPart.length % 3;
  formattedIntegerParts.add(integerPart.substring(0, start));
  for (int i = start; i < integerPart.length; i += 3) {
    formattedIntegerParts
        .add(currencyData.thousandsSeparator + integerPart.substring(i, i + 3));
  }
  String formattedIntegerPart = formattedIntegerParts.join('');

  // Concatenate integer and decimal parts with the separator
  String result = formattedIntegerPart + decimalPart;

  String symbolPart = '';
  if (currencyData.showSymbol && currencyData.symbol.isNotEmpty) {
    symbolPart = currencyData.symbol +
        (currencyData.spaceBetweenAmountAndSymbol ? ' ' : '');
  }

  // Add symbol based on configuration
  if (currencyData.symbolOnLeft) {
    result = symbolPart + result;
  } else {
    result = result + symbolPart;
  }

  // Add minus sign for negative numbers
  if (isNegative) {
    if (currencyData.useParenthesesForNegatives) {
      if (currencyData.symbolOnLeft) {
        result = symbolPart +
            '(' +
            result.replaceFirst(currencyData.symbol, '') +
            ')';
      } else {
        result = '(' +
            result.replaceFirst(currencyData.symbol, '') +
            ')' +
            symbolPart;
      }
    } else {
      result = '-' + result;
    }
  }

  return result;
}

double? transactionTotalAmount(
    List<TransactionItemDataStruct> transactionDataItem) {
  double totalAmount = 0.0;
  // Calculate the total amount from all transactionDataItem(s) in transactionDoc
  for (var dataItem in transactionDataItem) {
    totalAmount += dataItem.amount;
  }

  return totalAmount;
}

InvoiceSummaryInfoStruct? calculateInvoiceSummary(
  double invoiceTotalAmount,
  List<TransactionsRecord> transactionList,
  DateTime creationDate,
  DateTime dueDate,
) {
  // Check if transactionList or invoiceTotalAmount is null
  // if (transactionList.isEmpty || invoiceTotalAmount == 0) {
  //   print("Error: Transaction list is empty or invoice total amount is null.");
  //   // return null;
  // }

  // Initialize variables to store paid amount and remaining amount
  double totalPaidAmount = 0.0;
  double remainingAmount = 0.0;

  // Loop through transactionList to find transactions related to the given invoiceRef
  for (var transaction in transactionList) {
    // Check if transactionDataItem is null or empty
    if (transaction.transactionDataItem.isEmpty) {
      print(
          "Warning: Transaction data item is null or empty for a transaction.");
      continue;
    }

    // Accessing each transactionDataItem inside the transaction
    for (var transactionDataItem in transaction.transactionDataItem) {
      // Check if transactionDataItem.amount is null
      if (transactionDataItem.amount == null) {
        print("Warning: Transaction data item amount is null.");
        continue;
      }

      // Adding the payment amount from each transactionDataItem to the totalPaidAmount
      totalPaidAmount += transactionDataItem.amount!;
    }
  }

  // Calculate the remaining amount
  remainingAmount = invoiceTotalAmount - totalPaidAmount;

  // Calculate the difference between the current date and the due date
  Duration difference = dueDate.difference(DateTime.now());

  // Calculate the number of days until due date
  int daysUntilDue = difference.inDays;

  // Check if the due date has passed
  bool isOverdue = remainingAmount > 0 && daysUntilDue < 0;

  // Convert the number of days until due date to a human-readable string
  String stringDays;
  if (isOverdue) {
    stringDays = '${-daysUntilDue} days overdue';
  } else if (daysUntilDue == 0) {
    stringDays = 'Due today';
  } else if (daysUntilDue == 1) {
    stringDays = 'Due tomorrow';
  } else if (daysUntilDue == -1) {
    stringDays = 'Due yesterday';
  } else if (daysUntilDue < -1) {
    stringDays = '${-daysUntilDue} days overdue';
  } else {
    stringDays = '$daysUntilDue days until due';
  }

  // Determine the invoice status based on the remaining amount and overdue status
  int status;
  if (remainingAmount <= 0) {
    status = InvoicePaymentStatus.Paid.index;
  } else if (totalPaidAmount > 0 && totalPaidAmount < invoiceTotalAmount) {
    status = InvoicePaymentStatus.Installments.index;
  } else if (isOverdue) {
    status = InvoicePaymentStatus.Overdue.index;
  } else {
    status = InvoicePaymentStatus.Unpaid.index;
  }

  // Return an InvoiceSummaryInfoStruct instance
  return InvoiceSummaryInfoStruct(
    totalPaidAmount: totalPaidAmount,
    remainingAmount: remainingAmount,
    status: status,
    isOverdue: isOverdue,
    days: isOverdue ? -daysUntilDue : daysUntilDue,
    stringDays: stringDays,
  );
}

List<InvoiceItemsDataStruct>? generateInvoiceItemsDataList(
    List<InventoryRecord> inventoryList) {
  // Return an empty list if the inventory list is empty
  if (inventoryList.isEmpty) {
    return [];
  }

  // Create a list to hold the invoice items
  List<InvoiceItemsDataStruct> invoiceItems = [];

  // Loop through each inventory record and create an invoice item
  for (var inventoryItem in inventoryList) {
    InvoiceItemsDataStruct invoiceItem = InvoiceItemsDataStruct(
      itemRef: inventoryItem.itemData.itemRef,
      purchasePrice: inventoryItem.itemData.purchasePrice,
      salesPrice: inventoryItem.itemData.salesPrice,
      quantity: inventoryItem.itemData.quantity,
      discount: inventoryItem.itemData.discount,
      tax: inventoryItem.itemData.tax,
      name: inventoryItem.itemData.name,
      unit: inventoryItem.itemData.unit,
      status: inventoryItem.itemData.status,
      img: inventoryItem.itemData.img,
    );

    // Add the invoice item to the list
    invoiceItems.add(invoiceItem);
  }

  // Return the list of invoice items
  return invoiceItems;
}

List<DocumentReference> itemsRefList(
    List<InvoiceItemsDataStruct> invoiceItemsData) {
  final List<DocumentReference> itemsRefList = [];
  for (final item in invoiceItemsData) {
    if (item.itemRef != null) {
      itemsRefList.add(item.itemRef!);
    }
  }
  return itemsRefList;
}

int? getTransactionTypeIndex(TransactionType transactionType) {
  // get TransactionType enum Index
  return transactionType.index;
}

String? getDetailName(int accountType) {
  if (accountType < 0 || accountType >= DetailType.values.length) {
    return "null"; // Check for invalid index
  }
  return DetailType.values[accountType].toString().split('.').last;
}

EndStartDateStruct getDateRange(DateRange period) {
  DateTime now = DateTime.now();
  DateTime startDate;
  DateTime endDate = now;

  switch (period) {
    case DateRange.sinceLastYear:
      startDate = DateTime(now.year - 1, 1, 1);
      break;
    case DateRange.lastWeek:
      startDate = now.subtract(Duration(days: now.weekday + 6));
      endDate = now.subtract(Duration(days: now.weekday));
      break;
    case DateRange.lastMonth:
      startDate = DateTime(now.year, now.month - 1, 1);
      endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
      break;
    case DateRange.lastQuarter:
      int quarter = (now.month - 1) ~/ 3;
      startDate = DateTime(now.year, quarter * 3 - 2, 1);
      endDate = DateTime(now.year, quarter * 3 + 1, 0, 23, 59, 59);
      break;
    case DateRange.last30Days:
      startDate = now.subtract(Duration(days: 30));
      break;
    case DateRange.last28Days:
      startDate = now.subtract(Duration(days: 28));
      break;
    case DateRange.last14Days:
      startDate = now.subtract(Duration(days: 14));
      break;
    case DateRange.last7Days:
      startDate = now.subtract(Duration(days: 7));
      break;
    case DateRange.today:
      startDate = DateTime(now.year, now.month, now.day);
      endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      break;
    case DateRange.thisWeek:
      startDate = now.subtract(Duration(days: now.weekday - 1));
      break;
    case DateRange.lastTwoMonths:
      startDate = now.subtract(Duration(days: 60));
      break;
    case DateRange.thisQuarter:
      int currentQuarter = (now.month - 1) ~/ 3;
      startDate = DateTime(now.year, currentQuarter * 3 + 1, 1);
      break;
    case DateRange.thisYear:
      startDate = DateTime(now.year, 1, 1);
      endDate = DateTime(now.year, 12, 31, 23, 59, 59);
      break;
    case DateRange.all:
      startDate = DateTime(2000, 1, 1);
      endDate = DateTime(2100, 12, 31, 23, 59, 59);
      break;
    case DateRange.custom:
      // در این حالت، باید تاریخ‌های سفارشی به‌صورت دستی تعیین شوند
      startDate = DateTime(2000, 1, 1); // مقدار پیش‌فرض برای مثال
      endDate = DateTime(2100, 12, 31, 23, 59, 59); // مقدار پیش‌فرض برای مثال
      break;
  }

  return EndStartDateStruct(
    startDate: startDate,
    endDate: endDate,
  );
}

DateRange getDateRangeFromInt(int value) {
  switch (value) {
    case 0:
      return DateRange.sinceLastYear;
    case 1:
      return DateRange.lastWeek;
    case 2:
      return DateRange.lastMonth;
    case 3:
      return DateRange.lastQuarter;
    case 4:
      return DateRange.last30Days;
    case 5:
      return DateRange.last28Days;
    case 6:
      return DateRange.last14Days;
    case 7:
      return DateRange.last7Days;
    case 8:
      return DateRange.today;
    case 9:
      return DateRange.thisWeek;
    case 10:
      return DateRange.lastTwoMonths;
    case 11:
      return DateRange.thisQuarter;
    case 12:
      return DateRange.thisYear;
    case 13:
      return DateRange.all;
    case 14:
      return DateRange.custom;
    default:
      throw ArgumentError("Invalid value for DateRange enum: $value");
  }
}

List<InvoicesRecord> filterInvoices(
  List<InvoicesRecord> invoicesList,
  InvoiceFilterCriteriaDataStruct criteria,
  List<InventoryRecord> inventoryDocList,
  List<TransactionsRecord> transactionDocList,
) {
  return invoicesList.where((invoice) {
    // Filter based on start date
    if (criteria.startDate != null &&
        invoice.generalInvoiceInfo.creationDate != null &&
        invoice.generalInvoiceInfo.creationDate!
            .isBefore(criteria.startDate!)) {
      return false;
    }

    // Filter based on end date
    if (criteria.endDate != null &&
        invoice.generalInvoiceInfo.creationDate != null &&
        invoice.generalInvoiceInfo.creationDate!.isAfter(criteria.endDate!)) {
      return false;
    }

    // Filter based on invoice types
    if (criteria.invoiceTypes != null && criteria.invoiceTypes!.isNotEmpty) {
      if (!criteria.invoiceTypes!.contains(invoice.invoiceType)) {
        return false;
      }
    }

    // Filter based on invoice status
    if (criteria.statuses != null && criteria.statuses!.isNotEmpty) {
      if (!criteria.statuses!.contains(invoice.invoiceStatus)) {
        return false;
      }

      // Check due date if status is overdue
      if (criteria.statuses!.contains(2)) {
        // Assuming 2 represents overdue
        if (invoice.generalInvoiceInfo.dueDate != null &&
            invoice.generalInvoiceInfo.dueDate!.isAfter(DateTime.now())) {
          return false;
        }
      }
    }

    // Filter based on persons
    if (criteria.persons != null && criteria.persons!.isNotEmpty) {
      if (!criteria.persons!.contains(invoice.buyerRef)) {
        return false;
      }
    }

    // Filter based on items
    if (criteria.items != null && criteria.items!.isNotEmpty) {
      final invoiceItems = inventoryDocList
          .where((item) => item.invoiceRef == invoice.reference)
          .toList();
      final itemRefs =
          invoiceItems.map((item) => item.itemData.itemRef).toList();
      if (!criteria.items!.any((item) => itemRefs.contains(item))) {
        return false;
      }
    }

    // Filter based on financial accounts
    if (criteria.fnAccounts != null && criteria.fnAccounts!.isNotEmpty) {
      final invoiceTransactions = transactionDocList
          .where((transaction) => transaction.invoiceRef == invoice.reference)
          .toList();
      bool hasMatchingAccount = false;
      for (var transaction in invoiceTransactions) {
        if (transaction.transactionDataItem.any((dataItem) =>
            criteria.fnAccounts!.contains(dataItem.fnAccountRef))) {
          hasMatchingAccount = true;
          break;
        }
      }
      if (!hasMatchingAccount) {
        return false;
      }
    }

    // Filter based on search text
    if (criteria.searchTerm != null && criteria.searchTerm!.isNotEmpty) {
      final searchText = criteria.searchTerm!.toLowerCase();
      final generalInfo = invoice.generalInvoiceInfo;
      final financialInfo = invoice.invoiceFinancialInfo;
      final searchableText = [
        generalInfo.invoiceNumber,
        generalInfo.invoiceTitle,
        generalInfo.tc,
        generalInfo.pm,
        financialInfo.taxRate,
      ].join(' ').toLowerCase();

      if (!searchableText.contains(searchText)) {
        return false;
      }
    }

    // If none of the conditions match, include the invoice
    return true;
  }).toList();
}

InvoiceCalculationResultStruct invoiceListPricesResult(
  List<InvoicesRecord> invoicesList,
  List<InventoryRecord> inventoryList,
  InvoiceType status,
) {
  // فیلتر کردن لیست انبارداری بر اساس وضعیت
  List<InventoryRecord> filteredInventoryList =
      inventoryList.where((record) => record.status == status.index).toList();

  // متغیرهای جمع کل
  int totalItemCount = 0;
  double totalFinalItemList = 0;
  double totalFinalInvoice = 0;
  double totalNetSalesRevenue = 0;
  double totalGrossProfit = 0;
  double totalNetProfit = 0;
  double totalItemDiscount = 0;
  double totalInvoiceLevelDiscount = 0;
  double totalDiscount = 0;
  double totalItemTax = 0;
  double totalInvoiceLevelTax = 0;
  double totalTax = 0;
  double totalTaxableAmount = 0;
  double totalShippingCosts = 0;
  double totalBuyingPrice = 0;

  // حلقه برای هر فاکتور در لیست فاکتورها
  for (var invoice in invoicesList) {
    // ایجاد لیستی از آیتم‌های فاکتور بر اساس فاکتور و لیست انبارداری
    List<InvoiceItemsDataStruct> invoiceItems = filteredInventoryList
        .where((record) => record.invoiceRef == invoice.reference)
        .map((record) => InvoiceItemsDataStruct(
              itemRef: record.itemData.itemRef,
              purchasePrice: record.itemData.purchasePrice,
              salesPrice: record.itemData.salesPrice,
              quantity: record.itemData.quantity,
              discount: record.itemData.discount,
              tax: record.itemData.tax,
              name: record.itemData.name,
              unit: record.itemData.unit,
              status: record.itemData.status,
              img: record.itemData.img,
            ))
        .toList();

    // استفاده از تابع invoiceLevelPricesResult برای محاسبه نتایج فاکتور
    InvoiceCalculationResultStruct result = invoiceLevelPricesResult(
        invoiceItems, invoice.invoiceFinancialInfo, status);

    // جمع‌بندی نتایج فاکتورها
    totalItemCount += result.itemCount;
    totalFinalItemList += result.finalItemListTotal;
    totalFinalInvoice += result.finalInvoiceTotal;
    totalNetSalesRevenue += result.netSalesRevenue;
    totalGrossProfit += result.grossProfit;
    totalNetProfit += result.netProfit;
    totalItemDiscount += result.totalItemDiscount;
    totalInvoiceLevelDiscount += result.invoiceLevelDiscount;
    totalDiscount += result.totalDiscount;
    totalItemTax += result.totalItemTax;
    totalInvoiceLevelTax += result.invoiceLevelTax;
    totalTax += result.totalTax;
    totalTaxableAmount += result.taxableAmount;
    totalShippingCosts += result.shippingCosts;
    totalBuyingPrice += result.totalBuyingPrice;
  }

  // بازگرداندن نتیجه نهایی
  return InvoiceCalculationResultStruct(
    itemCount: totalItemCount,
    finalItemListTotal: totalFinalItemList,
    finalInvoiceTotal: totalFinalInvoice,
    netSalesRevenue: totalNetSalesRevenue,
    grossProfit: totalGrossProfit,
    netProfit: totalNetProfit,
    totalItemDiscount: totalItemDiscount,
    invoiceLevelDiscount: totalInvoiceLevelDiscount,
    totalDiscount: totalDiscount,
    totalItemTax: totalItemTax,
    invoiceLevelTax: totalInvoiceLevelTax,
    totalTax: totalTax,
    taxableAmount: totalTaxableAmount,
    shippingCosts: totalShippingCosts,
    totalBuyingPrice: totalBuyingPrice,
  );
}

PaymentStatusTotalsStruct calculatePaymentStatusTotals(
  List<InvoicesRecord> invoiceList,
  List<InventoryRecord> inventoryItemList,
) {
  double totalPaidInvoices = 0;
  double totalUnpaidInvoices = 0;
  double totalOverdueInvoices = 0;
  double totalInvoiceAmount = 0;

  for (var invoice in invoiceList) {
    // فیلتر کردن آیتم‌های مربوط به فاکتور از لیست انبارداری
    List<InvoiceItemsDataStruct> invoiceItems = inventoryItemList
        .where((record) => record.invoiceRef == invoice.reference)
        .map((record) => InvoiceItemsDataStruct(
              itemRef: record.itemData.itemRef,
              purchasePrice: record.itemData.purchasePrice,
              salesPrice: record.itemData.salesPrice,
              quantity: record.itemData.quantity,
              discount: record.itemData.discount,
              tax: record.itemData.tax,
              name: record.itemData.name,
              unit: record.itemData.unit,
              status: record.itemData.status,
              img: record.itemData.img,
            ))
        .toList();
    InvoiceType invoiceType = InvoiceType.values[invoice.invoiceType];

    // محاسبه مجموع فاکتور با استفاده از تابع invoiceLevelPricesResult
    InvoiceCalculationResultStruct invoiceCalculationSummary =
        invoiceLevelPricesResult(
            invoiceItems, invoice.invoiceFinancialInfo, invoiceType);

    totalInvoiceAmount += invoiceCalculationSummary.finalInvoiceTotal;

    // Updating totals based on the payment status of the invoice
    switch (InvoicePaymentStatus.values[invoice.invoiceStatus]) {
      case InvoicePaymentStatus.Paid:
        totalPaidInvoices += invoiceCalculationSummary.finalInvoiceTotal;
        break;
      case InvoicePaymentStatus.Unpaid:
        totalUnpaidInvoices += invoiceCalculationSummary.finalInvoiceTotal;
        break;
      case InvoicePaymentStatus.Overdue:
        // Checking if the due date has passed

        break;
      case InvoicePaymentStatus.Installments:
        // Implement any specific logic for installments if needed
        break;
      default:
        // Handle unexpected statuses gracefully if needed
        break;
    }

    if (invoice.generalInvoiceInfo.dueDate != null &&
        invoice.generalInvoiceInfo.dueDate!.isBefore(DateTime.now())) {
      totalOverdueInvoices += invoiceCalculationSummary.finalInvoiceTotal;
    }
  }

  return PaymentStatusTotalsStruct(
    paidInvoicesTotal: totalPaidInvoices,
    unpaidInvoicesTotal: totalUnpaidInvoices,
    overdueInvoicesTotal: totalOverdueInvoices,
    allInvoicesTotal: totalInvoiceAmount,
  );
}

ItemSummaryDataStruct? calculateItemSummaryResult(
  List<InventoryRecord> inventoryRecords,
  ItemsRecord itemDetails,
  List<InvoicesRecord> invoiceRecords,
) {
  // Financial variables for sales calculations.
  double totalSalesValue = 0; // Total sales value.
  double totalSalesDiscountsGiven = 0; // Total discounts given on sales.
  double totalSalesVATCollected = 0; // Total VAT collected from sales.
  int unitsSold = 0; // Total number of units sold.
  double averageSalesPrice = 0.0; // Average sales price per unit.

  // Financial variables for purchase calculations.
  double totalCostOfGoodsPurchased = 0; // Total cost of purchased goods.
  double totalPurchaseDiscountsReceived =
      0; // Total discounts received on purchases.
  double totalPurchaseVATPaid = 0; // Total VAT paid on purchases.
  int unitsPurchased = 0; // Total number of units purchased.
  double averagePurchasePrice = 0.0; // Average purchase price per unit.

  // A set to keep track of processed invoices to avoid duplication.
  Set<DocumentReference> reviewedInvoiceRefs = {};

  // Loop through each inventory record to calculate totals and quantities for sales and purchases.
  for (var record in inventoryRecords) {
    // Check if the record belongs to the item in question.
    if (record.itemData.itemRef == itemDetails.reference) {
      // Determine the price per unit based on the transaction type (purchase/sale).
      double pricePerUnit = record.status == 0
          ? record.itemData.purchasePrice
          : record.itemData.salesPrice;
      // Calculate the total value of the transaction.
      double totalTransactionValue = pricePerUnit * record.itemData.quantity;

      // Accumulate totals based on the transaction type.
      if (record.status == 0) {
        // Purchase
        totalCostOfGoodsPurchased += totalTransactionValue;
        totalPurchaseDiscountsReceived +=
            record.itemData.discount * totalTransactionValue;
        totalPurchaseVATPaid += record.itemData.tax * totalTransactionValue;
        unitsPurchased += record.itemData.quantity;
      } else if (record.status == 1) {
        // Sale
        totalSalesValue += totalTransactionValue;
        totalSalesDiscountsGiven +=
            record.itemData.discount * totalTransactionValue;
        totalSalesVATCollected += record.itemData.tax * totalTransactionValue;
        unitsSold += record.itemData.quantity;
      }
    }
  }

  // Process each invoice to calculate invoice-level financials for sales and purchases.
  for (var invoice in invoiceRecords) {
    // Skip already processed invoices.
    if (!reviewedInvoiceRefs.contains(invoice.reference)) {
      // Calculate the total sales and purchases from the invoice.
      double invoiceTotalSales = 0;
      double invoiceTotalPurchases = 0;

      // Filter the inventory records by the invoice reference.
      var relatedRecords = inventoryRecords
          .where((record) => record.invoiceRef == invoice.reference);

      // Sum up the sales and purchases values from the related inventory records.
      for (var record in relatedRecords) {
        double pricePerUnit = record.status == 0
            ? record.itemData.purchasePrice
            : record.itemData.salesPrice;
        double totalTransactionValue = pricePerUnit * record.itemData.quantity;

        if (record.status == 0) {
          // Purchase
          invoiceTotalPurchases += totalTransactionValue;
        } else if (record.status == 1) {
          // Sale
          invoiceTotalSales += totalTransactionValue;
        }
      }

      // Calculate the discount and tax amounts for the invoice.
      double invoiceDiscountAmount =
          invoiceTotalSales * invoice.invoiceFinancialInfo.discount;
      double invoiceTaxAmount = (invoiceTotalSales - invoiceDiscountAmount) *
          invoice.invoiceFinancialInfo.taxRate;

      // Update the totals with the invoice-level financials.
      totalSalesValue += invoiceTotalSales;
      totalSalesDiscountsGiven += invoiceDiscountAmount;
      totalSalesVATCollected += invoiceTaxAmount;
      totalCostOfGoodsPurchased += invoiceTotalPurchases;

      // Mark the invoice as processed.
      reviewedInvoiceRefs.add(invoice.reference);
    }
  }

  // Calculate net sales revenue and gross margin for sales.
  double netSalesRevenue = totalSalesValue - totalSalesDiscountsGiven;
  double salesGrossMargin = netSalesRevenue - totalCostOfGoodsPurchased;

  // Calculate net purchase cost and gross margin for purchases.
  double netPurchaseCost =
      totalCostOfGoodsPurchased - totalPurchaseDiscountsReceived;
  double purchaseGrossMargin = netPurchaseCost - totalPurchaseVATPaid;

  // Calculate the average prices.
  averagePurchasePrice =
      unitsPurchased > 0 ? netPurchaseCost / unitsPurchased : 0;
  averageSalesPrice = unitsSold > 0 ? netSalesRevenue / unitsSold : 0;

  // Calculate the net margin for sales.
  double salesNetMargin = salesGrossMargin - totalSalesVATCollected;

  // Calculate the current inventory level.
  int currentInventoryLevel = unitsPurchased - unitsSold;

  // Return the structured data summary of the item.
  return ItemSummaryDataStruct(
    itemName: itemDetails.productName, // Name of the item.
    averagePurchasePrice:
        averagePurchasePrice, // Calculated average purchase price.
    averageSalesPrice: averageSalesPrice, // Calculated average sales price.
    netSalesRevenue: netSalesRevenue, // Net sales revenue after discounts.
    salesGrossMargin: salesGrossMargin, // Gross profit margin for sales.
    purchaseGrossMargin:
        purchaseGrossMargin, // Gross profit margin for purchases.
    salesNetMargin: salesNetMargin, // Net profit margin after VAT for sales.
    totalRevenue: totalSalesValue, // Total revenue from sales.
    totalExpenditure: netPurchaseCost, // Total expenditure on purchases.
    unitsSold: unitsSold, // Total units sold.
    unitsPurchased: unitsPurchased, // Total units purchased.
    totalVATCollected:
        totalSalesVATCollected, // Total VAT collected from sales.
    totalDiscountsGiven:
        totalSalesDiscountsGiven, // Total discounts given on sales.
    currentInventoryLevel: currentInventoryLevel, // Current stock level.
  );
}

List<InvoicesRecord> filterInvoiceListByRefsList(
  List<InvoicesRecord> invoiceList,
  List<DocumentReference> invoiceRefs,
  InvoiceType? invoiceType,
) {
  // ابتدا فاکتورهایی که در invoiceRefs هستند را فیلتر می‌کنیم.
  var filteredList = invoiceList
      .where((invoice) => invoiceRefs.contains(invoice.reference))
      .toList();

  // سپس بر اساس invoiceType فیلتر می‌کنیم.
  switch (invoiceType) {
    case InvoiceType.Buy:
      // فیلتر کردن برای فاکتورهای خرید
      filteredList = filteredList
          .where((invoice) => invoice.invoiceType == InvoiceType.Buy.index)
          .toList();
      break;
    case InvoiceType.Sale:
      // فیلتر کردن برای فاکتورهای فروش
      filteredList = filteredList
          .where((invoice) => invoice.invoiceType == InvoiceType.Sale.index)
          .toList();
      break;
    default:
      filteredList;
      break;
  }

  return filteredList;
}

List<ItemSummaryDataStruct> createItemSummaryData(
  List<InventoryRecord> inventoryRecords,
  List<ItemsRecord> itemsRecords,
  List<InvoicesRecord> invoicesRecords,
) {
  List<ItemSummaryDataStruct> itemSummaryData = [];

  for (var itemRecord in itemsRecords) {
    // فیلتر کردن رکوردهای موجودی برای آیتم جاری
    var filteredInventory = inventoryRecords.where(
        (inventory) => inventory.itemData.itemRef == itemRecord.reference);

    // فیلتر کردن فاکتورها برای آیتم جاری
    var filteredInvoices = invoicesRecords.where((invoice) => filteredInventory
        .any((inventory) => inventory.invoiceRef == invoice.reference));

    // محاسبه خلاصه داده‌ها برای آیتم جاری
    var summary = calculateItemSummaryResult(
      filteredInventory.toList(),
      itemRecord,
      filteredInvoices.toList(),
    );

    // اضافه کردن خلاصه داده‌ها به لیست
    if (summary != null) {
      itemSummaryData.add(summary);
    }
  }

  return itemSummaryData;
}

List<ItemsRecord>? getItemsDocsByInventoryList(
  List<InventoryRecord> inventoryList,
  List<ItemsRecord> itemsListDoc,
  InventoryStatus? status,
) {
  // Initialize an empty list to store filtered items
  List<ItemsRecord> filteredItems = [];

  // Determine the status index based on the invoice type
  int? statusIndex;
  if (status != null) {
    if (status == InventoryStatus.Received) {
      statusIndex = 0;
    } else if (status == InventoryStatus.Dispatched) {
      statusIndex = 1;
    }
  }

  // Determine if filtering by status is required
  bool filterByStatus = status != null;

  // Iterate over each item in the items list
  for (var item in itemsListDoc) {
    // Check if any inventory contains the current item and matches the status (if filtering by status)
    bool itemExistsInInventory = inventoryList.any((inventoryRecord) =>
        inventoryRecord.itemData.itemRef == item.reference &&
        (!filterByStatus || inventoryRecord.itemData.status == statusIndex));

    // If the item exists in any inventory and matches the status, add it to the filtered list
    if (itemExistsInInventory) {
      filteredItems.add(item);
    }
  }

  return filteredItems.isEmpty ? null : filteredItems;
}

List<InvoicesRecord> sortInvoices(
  List<InvoicesRecord> invoiceRecords,
  SortOrder sortOrder,
) {
  invoiceRecords.sort((a, b) {
    // Use the null-aware operator `?.` to handle potential nulls.
    // Provide a default value using `??` in case the date is null.
    DateTime dateA = a.generalInvoiceInfo.creationDate ?? DateTime(0);
    DateTime dateB = b.generalInvoiceInfo.creationDate ?? DateTime(0);

    if (sortOrder == SortOrder.oldest) {
      return dateA.compareTo(dateB);
    } else {
      return dateB.compareTo(dateA);
    }
  });
  return invoiceRecords;
}

List<ItemsRecord> searchItems(
  List<ItemsRecord>? itemsRecords,
  String? searchTerm,
) {
  if (itemsRecords == null || searchTerm == null || searchTerm.isEmpty) {
    return [];
  }

  final lowerCaseTerm = searchTerm.toLowerCase();
  final numericTerm = double.tryParse(searchTerm);

  bool isMatch(ItemsRecord item) {
    final textFields = [
      item.productName,
      item.sku,
      item.unit,
      item.note,
    ].where((field) => field != null).map((field) => field!.toLowerCase());

    final isTextMatch =
        textFields.any((field) => field.contains(lowerCaseTerm));
    final isNumericMatch = numericTerm != null &&
        ((item.buyPrice != null && item.buyPrice == numericTerm) ||
            (item.salePrice != null && item.salePrice == numericTerm));

    return isTextMatch || isNumericMatch;
  }

  return itemsRecords.where(isMatch).toList();
}

List<PersonsRecord> searchPersons(
  List<PersonsRecord>? personsRecords,
  String? searchTerm,
) {
  if (personsRecords == null || searchTerm == null || searchTerm.isEmpty) {
    return personsRecords ?? [];
  }

  final lowerCaseTerm = searchTerm.toLowerCase();

  return personsRecords.where((person) {
    final mainData = person.mainData;
    final contactData = person.contact;
    final addressData = person.address;

    final fullName = '${mainData.firstName} ${mainData.lastName}'.toLowerCase();
    final companyName = mainData.company?.toLowerCase() ?? '';
    final nickname = mainData.nikname?.toLowerCase() ?? '';
    final title = mainData.title?.toLowerCase() ?? '';

    final phone = contactData.phone?.toLowerCase() ?? '';
    final mobile = contactData.mobile?.toLowerCase() ?? '';
    final email = contactData.email?.toLowerCase() ?? '';
    final website = contactData.website?.toLowerCase() ?? '';

    final country = addressData.country?.toLowerCase() ?? '';
    final state = addressData.state?.toLowerCase() ?? '';
    final city = addressData.city?.toLowerCase() ?? '';
    final postalCode = addressData.postalCode?.toLowerCase() ?? '';
    final fullAddress = addressData.address?.toLowerCase() ?? '';

    return fullName.contains(lowerCaseTerm) ||
        companyName.contains(lowerCaseTerm) ||
        nickname.contains(lowerCaseTerm) ||
        title.contains(lowerCaseTerm) ||
        phone.contains(lowerCaseTerm) ||
        mobile.contains(lowerCaseTerm) ||
        email.contains(lowerCaseTerm) ||
        website.contains(lowerCaseTerm) ||
        country.contains(lowerCaseTerm) ||
        state.contains(lowerCaseTerm) ||
        city.contains(lowerCaseTerm) ||
        postalCode.contains(lowerCaseTerm) ||
        fullAddress.contains(lowerCaseTerm);
  }).toList();
}
