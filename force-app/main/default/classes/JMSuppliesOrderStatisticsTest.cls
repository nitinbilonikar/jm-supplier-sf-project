 @IsTest
  private class JMSuppliesOrderStatisticsTest {

      private static List<JMSuppliesOrderStatistics.OrderRow> saleRows;
      private static List<JMSuppliesOrderStatistics.OrderRow> customerRows;

      private static void setup() {
          JMSuppliesOrderStatistics.OrderRow r1 = new JMSuppliesOrderStatistics.OrderRow();
          r1.saleNumber   = 1;
          r1.customerId   = 'C001';
          r1.customerName = 'Alice';
          r1.totalValue   = 50.00;
          r1.orderedAt    = Datetime.newInstanceGmt(2024, 5, 22, 10, 0, 0);

          JMSuppliesOrderStatistics.OrderRow r2 = new JMSuppliesOrderStatistics.OrderRow();
          r2.saleNumber   = 2;
          r2.customerId   = 'C002';
          r2.customerName = 'Bob';
          r2.totalValue   = 200.00;
          r2.orderedAt    = Datetime.newInstanceGmt(2024, 5, 22, 11, 0, 0);

          JMSuppliesOrderStatistics.OrderRow r3 = new JMSuppliesOrderStatistics.OrderRow();
          r3.saleNumber   = 2;
          r3.customerId   = 'C002';
          r3.customerName = 'Bob';
          r3.totalValue   = 150.00;
          r3.orderedAt    = Datetime.newInstanceGmt(2024, 5, 22, 11, 30, 0);

          JMSuppliesOrderStatistics.OrderRow r4 = new JMSuppliesOrderStatistics.OrderRow();
          r4.saleNumber   = 3;
          r4.customerId   = 'C001';
          r4.customerName = 'Alice';
          r4.totalValue   = 100.00;
          r4.orderedAt    = Datetime.newInstanceGmt(2024, 5, 22, 12, 0, 0);

          // Sale 2 (Bob) total = £350 — highest sale
          saleRows = new List<JMSuppliesOrderStatistics.OrderRow>{ r1, r2, r3 };

          // Alice total = £150, Bob total = £100 — Alice wins
          customerRows = new List<JMSuppliesOrderStatistics.OrderRow>{ r1, r2, r4 };
      }

      // ── getHighestValueOrder ──────────────────────────────────────────────────

      @IsTest
      static void getHighestValueOrder_multipleRows_returnsCorrectSaleAndTotal() {
          setup();

          String result = JMSuppliesOrderStatistics.getHighestValueOrder(saleRows);

          System.assert(result.contains('Bob'),    'Result should name the winning customer');
          System.assert(result.contains('350.00'), 'Result should show the combined sale total');
      }

      @IsTest
      static void getHighestValueOrder_emptyList_returnsNoOrdersMessage() {
          String result = JMSuppliesOrderStatistics.getHighestValueOrder(
              new List<JMSuppliesOrderStatistics.OrderRow>()
          );

          System.assertEquals('No valid orders found.', result);
      }

      // ── getMostValuableCustomer ───────────────────────────────────────────────

      @IsTest
      static void getMostValuableCustomer_multipleCustomers_returnsHighestSpender() {
          setup();

          String result = JMSuppliesOrderStatistics.getMostValuableCustomer(customerRows);

          System.assert(result.contains('Alice'),  'Result should name the highest-spending customer');
          System.assert(result.contains('150.00'), 'Result should show the correct total spend');
      }

      @IsTest
      static void getMostValuableCustomer_emptyList_returnsNoOrdersMessage() {
          String result = JMSuppliesOrderStatistics.getMostValuableCustomer(
              new List<JMSuppliesOrderStatistics.OrderRow>()
          );

          System.assertEquals('No valid orders found.', result);
      }
  }