public with sharing class JMSuppliesOrderStatistics {

    private static final Date ORDER_DATE = Date.newInstance(2024, 5, 22);

    private static final Map<String, Decimal> UNIT_PRICE_BY_PRODUCT = new Map<String, Decimal>{
        'A123A' => 99.99,
        'LB11A' => 19.99,
        'LB12B' => 9.99,
        'OB22A' => 5.50,
        'CG55D' => 0.95,
        'JL01A' => 25.50,
        'DC01A' => 10.50
    };

    public class OrderRow {
        public String recordName;
        public Datetime orderedAt;
        public String customerId;
        public String customerName;
        public String favouriteColour;
        public Integer saleNumber;
        public Integer quantity;
        public String productCode;
        public Decimal discountPercent;
        public Decimal totalValue;
    }

    public class ValidationError {
        public String recordName;
        public String reason;

        public ValidationError(String recordName, String reason) {
            this.recordName = recordName;
            this.reason = reason;
        }

        public override String toString() {
            return 'Record ' + recordName + ': ' + reason;
        }
    }

    public static List<JMSuppliesOrder__c> fetchOrders() {
        return [
            SELECT Name,
                   JM_Order_Date_Time__c,
                   Customer_Id__c,
                   Customer__c,
                   Favourite_Colour__c,
                   Sale_No__c,
                   Qty__c,
                   Product__c,
                   Discount__c
            FROM JMSuppliesOrder__c
            ORDER BY JM_Order_Date_Time__c ASC NULLS LAST
        ];
    }

    public static List<OrderRow> buildRows(
        List<JMSuppliesOrder__c> sourceOrders,
        List<ValidationError> validationErrors
    ) {
        List<OrderRow> rows = new List<OrderRow>();

        for (JMSuppliesOrder__c sourceOrder : sourceOrders) {
            List<String> problems = new List<String>();
            OrderRow row = new OrderRow();
            row.recordName = sourceOrder.Name;
            row.customerId = sourceOrder.Customer_Id__c;
            row.customerName = sourceOrder.Customer__c;
            row.favouriteColour = sourceOrder.Favourite_Colour__c;
            row.productCode = sourceOrder.Product__c;

            if (sourceOrder.JM_Order_Date_Time__c == null) {
                problems.add('Order date/time is missing');
            } else {
                row.orderedAt = sourceOrder.JM_Order_Date_Time__c;
                if (row.orderedAt.dateGmt() != ORDER_DATE) {
                    problems.add('Date is not 22/05/2024: ' + row.orderedAt.dateGmt());
                }
            }

            if (String.isBlank(row.customerId)) {
                problems.add('Customer ID is blank');
            }

            if (String.isBlank(row.customerName)) {
                problems.add('Customer name is blank');
            }

            if (sourceOrder.Sale_No__c == null) {
                problems.add('Sale No is missing');
            } else {
                row.saleNumber = Integer.valueOf(sourceOrder.Sale_No__c);
            }

            if (sourceOrder.Qty__c == null) {
                problems.add('Qty is missing');
            } else {
                row.quantity = Integer.valueOf(sourceOrder.Qty__c);
                if (row.quantity <= 0) {
                    problems.add('Qty must be greater than zero: ' + row.quantity);
                }
            }

            if (!UNIT_PRICE_BY_PRODUCT.containsKey(row.productCode)) {
                problems.add('Unknown product ID: "' + row.productCode + '"');
            }

            Decimal parsedDiscount = parseDiscount(sourceOrder.Discount__c);
            if (parsedDiscount == null) {
                problems.add('Invalid discount value: "' + sourceOrder.Discount__c + '"');
            } else if (parsedDiscount < 0 || parsedDiscount > 100) {
                problems.add('Discount out of range (0-100%): ' + parsedDiscount + '%');
            } else {
                row.discountPercent = parsedDiscount;
            }

            if (!problems.isEmpty()) {
                for (String problem : problems) {
                    validationErrors.add(new ValidationError(sourceOrder.Name, problem));
                }
                continue;
            }

            Decimal unitPrice = UNIT_PRICE_BY_PRODUCT.get(row.productCode);
            Decimal discountedAmount = row.quantity * unitPrice * (1 - (row.discountPercent / 100));
            row.totalValue = discountedAmount.setScale(2, RoundingMode.HALF_UP);
            rows.add(row);
        }

        return rows;
    }

    public static String getHighestValueOrder(List<OrderRow> rows) {
        Map<Integer, Decimal> totalsBySale = new Map<Integer, Decimal>();
        Map<Integer, String> customerBySale = new Map<Integer, String>();
        Map<Integer, Datetime> timeBySale = new Map<Integer, Datetime>();

        for (OrderRow row : rows) {
            Decimal runningTotal = totalsBySale.containsKey(row.saleNumber)
                ? totalsBySale.get(row.saleNumber)
                : 0;

            totalsBySale.put(row.saleNumber, runningTotal + row.totalValue);
            customerBySale.put(row.saleNumber, row.customerName);
            timeBySale.put(row.saleNumber, row.orderedAt);
        }

        Integer highestSaleNumber;
        Decimal highestTotal = -1;

        for (Integer saleNumber : totalsBySale.keySet()) {
            Decimal saleTotal = totalsBySale.get(saleNumber);
            if (saleTotal > highestTotal) {
                highestTotal = saleTotal;
                highestSaleNumber = saleNumber;
            }
        }

        if (highestSaleNumber == null) {
            return 'No valid orders found.';
        }

        return 'Highest value order:\n'
            + '  Customer : ' + customerBySale.get(highestSaleNumber) + '\n'
            + '  Value    : £' + highestTotal.setScale(2) + '\n'
            + '  Date/Time: ' + formatDateTime(timeBySale.get(highestSaleNumber));
    }

    public static String getMostValuableCustomer(List<OrderRow> rows) {
        Map<String, Decimal> spendByCustomerId = new Map<String, Decimal>();
        Map<String, String> customerNameById = new Map<String, String>();

        for (OrderRow row : rows) {
            Decimal runningTotal = spendByCustomerId.containsKey(row.customerId)
                ? spendByCustomerId.get(row.customerId)
                : 0;

            spendByCustomerId.put(row.customerId, runningTotal + row.totalValue);
            customerNameById.put(row.customerId, row.customerName);
        }

        String bestCustomerId;
        Decimal bestSpend = -1;

        for (String customerId : spendByCustomerId.keySet()) {
            Decimal totalSpend = spendByCustomerId.get(customerId);
            if (totalSpend > bestSpend) {
                bestSpend = totalSpend;
                bestCustomerId = customerId;
            }
        }

        if (bestCustomerId == null) {
            return 'No valid orders found.';
        }

        return 'Most valuable customer:\n'
            + '  Customer    : ' + customerNameById.get(bestCustomerId) + '\n'
            + '  Total Spend : £' + bestSpend.setScale(2);
    }

    public static String getValidationReport(List<ValidationError> errors) {
        if (errors.isEmpty()) {
            return 'No validation errors found.';
        }

        List<String> lines = new List<String>();
        lines.add('Validation failures (' + errors.size() + '):');

        for (ValidationError error : errors) {
            lines.add('  ' + error.toString());
        }

        return String.join(lines, '\n');
    }

    public static String getBusiestHour(List<OrderRow> rows) {
        Map<Integer, Integer> quantityByHour = new Map<Integer, Integer>();

        for (OrderRow row : rows) {
            Integer hour = row.orderedAt.hourGmt();
            Integer runningQty = quantityByHour.containsKey(hour)
                ? quantityByHour.get(hour)
                : 0;

            quantityByHour.put(hour, runningQty + row.quantity);
        }

        if (quantityByHour.isEmpty()) {
            return 'No valid orders found.';
        }

        Integer busiestQuantity = 0;
        for (Integer quantity : quantityByHour.values()) {
            if (quantity > busiestQuantity) {
                busiestQuantity = quantity;
            }
        }

        List<Integer> busiestHours = new List<Integer>();
        for (Integer hour : quantityByHour.keySet()) {
            if (quantityByHour.get(hour) == busiestQuantity) {
                busiestHours.add(hour);
            }
        }
        busiestHours.sort();

        List<String> hourLabels = new List<String>();
        for (Integer hour : busiestHours) {
            hourLabels.add(String.valueOf(hour).leftPad(2, '0') + ':00');
        }

        return 'Busiest hour(s) by items ordered (qty = ' + busiestQuantity + '):\n'
            + '  ' + String.join(hourLabels, ', ');
    }

    @TestVisible
    private static Decimal parseDiscount(String rawValue) {
        if (rawValue == null) {
            return null;
        }

        String cleanedValue = rawValue.trim().toUpperCase();
        if (cleanedValue == 'NONE') {
            return null;
        }

        if (!cleanedValue.endsWith('%')) {
            return null;
        }

        cleanedValue = cleanedValue.removeEnd('%');
        if (cleanedValue.contains('%')) {
            return null;
        }

        try {
            return Decimal.valueOf(cleanedValue);
        } catch (Exception ex) {
            return null;
        }
    }

    @TestVisible
    private static String formatDateTime(Datetime value) {
        List<String> monthNames = new List<String>{
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December'
        };

        return monthNames[value.monthGmt() - 1]
            + ' ' + value.dayGmt()
            + ', ' + value.yearGmt()
            + ' ' + String.valueOf(value.hourGmt()).leftPad(2, '0')
            + ':' + String.valueOf(value.minuteGmt()).leftPad(2, '0');
    }
}