public without sharing class LoanChargeSort implements Comparator<Loan_Charge__c> {
    public Integer compare(Object a, Object b) {
        Loan_Charge__c c1 = (Loan_Charge__c)a;
        Loan_Charge__c c2 = (Loan_Charge__c)b;

        // First sort by Date__c
        if (c1.Date__c != null && c2.Date__c != null && c1.Date__c != c2.Date__c) {
            return c1.Date__c < c2.Date__c ? -1 : 1;
        }

        // Compare priority
        Integer p1 = getPriority(c1.Charge_Type__c);
        Integer p2 = getPriority(c2.Charge_Type__c);

        if (p1 < p2) {
          return -1;
        }
        if (p1 > p2) {
          return 1;
        }
        return 0;
    }

    public Integer getPriority(String type) {
        if (type == 'Admin Fee') {
          return 0;
        } else if (type == 'Interest Charge') {
          return 1;
        }

        return 2;
    }
}
