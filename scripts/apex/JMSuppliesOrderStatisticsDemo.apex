        List<JMSuppliesOrder__c> records = JMSuppliesOrderStatistics.fetchOrders();
        System.debug('Total records fetched: ' + records.size());

        List<JMSuppliesOrderStatistics.ValidationError> errors = new List<JMSuppliesOrderStatistics.ValidationError>();
        List<JMSuppliesOrderStatistics.OrderRow> rows = JMSuppliesOrderStatistics.buildRows(records, errors);

        System.debug('Valid rows: ' + rows.size() + ' | Invalid rows: ' + errors.size());

        // Task 1 - Highest value order
        Object highestOrder = JMSuppliesOrderStatistics.getHighestValueOrder(rows);
        System.debug('Task 1 - Highest value order: ' + JSON.serialize(highestOrder));

        // Task 2 - Most valuable customer
        Object topCustomer = JMSuppliesOrderStatistics.getMostValuableCustomer(rows);
        System.debug('Task 2 - Most valuable customer: ' + JSON.serialize(topCustomer));

        // Task 3 - Validation failures
        Object validationReport = JMSuppliesOrderStatistics.getValidationReport(errors);
        System.debug('Task 3 - Validation report: ' + JSON.serialize(validationReport));

        // Task 4 - Busiest hour
        Object busiestHour = JMSuppliesOrderStatistics.getBusiestHour(rows);
        System.debug('Task 4 - Busiest hour: ' + JSON.serialize(busiestHour));
