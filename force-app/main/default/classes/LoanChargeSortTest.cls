@isTest
private class LoanChargeSortTest {
    @IsTest
    static void testCompare() {
        LoanChargeSort sorter = new LoanChargeSort();
        Loan_Charge__c c1 = new Loan_Charge__c(Date__c = Date.today(), Charge_Type__c = 'Admin Fee');
        Loan_Charge__c c2 = new Loan_Charge__c(Date__c = Date.today(), Charge_Type__c = 'Interest Charge');
        Loan_Charge__c c3 = new Loan_Charge__c(Date__c = Date.today(), Charge_Type__c = 'Other');
        Loan_Charge__c c4 = new Loan_Charge__c(Date__c = Date.today().addDays(1), Charge_Type__c = 'Admin Fee');
        Loan_Charge__c c5 = new Loan_Charge__c(Date__c = Date.today().addDays(1), Charge_Type__c = 'Interest Charge');
        Loan_Charge__c c6 = new Loan_Charge__c(Date__c = Date.today().addDays(1), Charge_Type__c = 'Other');

        System.assertEquals(0, sorter.compare(c1, c1), 'Admin Fee vs Admin Fee on same date');
        System.assertEquals(-1, sorter.compare(c1, c2), 'Admin Fee should come before Interest Charge on same date');
        System.assertEquals(-1, sorter.compare(c1, c3), 'Admin Fee should come before Other on same date');
        System.assertEquals(-1, sorter.compare(c1, c4), 'Earlier date should come before later');
        System.assertEquals(-1, sorter.compare(c1, c5), 'Earlier Admin Fee should come before later Interest Charge');
        System.assertEquals(-1, sorter.compare(c1, c6), 'Earlier Admin Fee should come before later Other');

        System.assertEquals(1, sorter.compare(c2, c1), 'Interest Charge should come after Admin Fee on same date');
        System.assertEquals(0, sorter.compare(c2, c2), 'Interest Charge vs Interest Charge on same date');
        System.assertEquals(-1, sorter.compare(c2, c3), 'Interest Charge should come before Other on same date');
        System.assertEquals(-1, sorter.compare(c2, c4), 'Earlier Interest Charge should come before later Admin Fee');
        System.assertEquals(-1, sorter.compare(c2, c5), 'Earlier Interest Charge should come before later Interest Charge');
        System.assertEquals(-1, sorter.compare(c2, c6), 'Earlier Interest Charge should come before later Other');

        System.assertEquals(1, sorter.compare(c3, c1), 'Other should come after Admin Fee on same date');
        System.assertEquals(1, sorter.compare(c3, c2), 'Other should come after Interest Charge on same date');
        System.assertEquals(0, sorter.compare(c3, c3), 'Other vs Other on same date');
        System.assertEquals(-1, sorter.compare(c3, c4), 'Earlier Other should come before later Admin Fee');
        System.assertEquals(-1, sorter.compare(c3, c5), 'Earlier Other should come before later Interest Charge');
        System.assertEquals(-1, sorter.compare(c3, c6), 'Earlier Other should come before later Other');

        System.assertEquals(1, sorter.compare(c4, c1), 'Later Admin Fee should come after earlier Admin Fee');
        System.assertEquals(1, sorter.compare(c4, c2), 'Later Admin Fee should come after earlier Interest Charge');
        System.assertEquals(1, sorter.compare(c4, c3), 'Later Admin Fee should come after earlier Other');
        System.assertEquals(0, sorter.compare(c4, c4), 'Admin Fee vs Admin Fee on same later date');
        System.assertEquals(-1, sorter.compare(c4, c5), 'Admin Fee should come before Interest Charge on same later date');
        System.assertEquals(-1, sorter.compare(c4, c6), 'Admin Fee should come before Other on same later date');

        System.assertEquals(1, sorter.compare(c5, c1), 'Later Interest Charge should come after earlier Admin Fee');
        System.assertEquals(1, sorter.compare(c5, c2), 'Later Interest Charge should come after earlier Interest Charge');
        System.assertEquals(1, sorter.compare(c5, c3), 'Later Interest Charge should come after earlier Other');
        System.assertEquals(1, sorter.compare(c5, c4), 'Interest Charge should come after Admin Fee on same later date');
        System.assertEquals(0, sorter.compare(c5, c5), 'Interest Charge vs Interest Charge on same later date');
        System.assertEquals(-1, sorter.compare(c5, c6), 'Interest Charge should come before Other on same later date');

        System.assertEquals(1, sorter.compare(c6, c1), 'Later Other should come after earlier Admin Fee');
        System.assertEquals(1, sorter.compare(c6, c2), 'Later Other should come after earlier Interest Charge');
        System.assertEquals(1, sorter.compare(c6, c3), 'Later Other should come after earlier Other');
        System.assertEquals(1, sorter.compare(c6, c4), 'Other should come after Admin Fee on same later date');
        System.assertEquals(1, sorter.compare(c6, c5), 'Other should come after Interest Charge on same later date');
        System.assertEquals(0, sorter.compare(c6, c6), 'Other vs Other on same later date');
    }

    @IsTest
    static void testGetPriority() {
        LoanChargeSort sorter = new LoanChargeSort();

        // Test for 'Admin Fee'
        System.assertEquals(0, sorter.getPriority('Admin Fee'), 'Expected priority for Admin Fee is 0');

        // Test for 'Interest Charge'
        System.assertEquals(1, sorter.getPriority('Interest Charge'), 'Expected priority for Interest Charge is 1');

        // Test for any other type
        System.assertEquals(2, sorter.getPriority('Other'), 'Expected priority for any other type is 2');
    }
}
