@isTest
private class LoanChargeTriggerHandler_Test {
    @testSetup
    static void setupBypassAndAccount() {
      // Bypass validation during test
      Validation_Bypass__c bypass = new Validation_Bypass__c(
          SetupOwnerId = UserInfo.getUserId(),
          Bypass_Validation__c = true
      );
      insert bypass;
    }

    @isTest
    static void testOnAfterInsertCreatesReleaseCharge() {
      Account acct = new Account(
          FirstName = 'Automated',
          LastName = 'Test User',
          RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId()
      );

      insert acct;

      Loan__c loan = new Loan__c(
          Name = 'Loan A',
          Account__c = acct.Id,
          Gross_Loan_Amount__c = 10000,
          Date_Loan_Issued__c = Date.today(),
          Term__c = 12
      );

      Test.startTest();
      insert loan;
      Test.stopTest();

      List<Loan_Charge__c> charges = [
          SELECT Charge_Type__c, Amount__c, Loan__c
          FROM Loan_Charge__c
          WHERE Loan__c = :loan.Id
      ];

      System.assertEquals(1, charges.size(), 'Should create one Release Charge');
      System.assertEquals('Release Charge', charges[0].Charge_Type__c, 'Expected a Release Charge to be created');
      System.assertEquals(500, charges[0].Amount__c, 'Expected Release Charge amount to be £500');
    }

    @isTest
    static void testOnAfterUpdateCreatesAdminFeeAndUpdatesReleaseCharge() {
        Account acct = new Account(
            FirstName = 'Automated',
            LastName = 'Test User',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId()
        );

        insert acct;

        Loan__c loan = new Loan__c(
            Name = 'Loan B',
            Account__c = acct.Id,
            Gross_Loan_Amount__c = 10000,
            Date_Loan_Issued__c = Date.today(),
            Term__c = 12
        );

        insert loan;

        Loan_Charge__c release = [
            SELECT Id, Date__c FROM Loan_Charge__c
            WHERE Loan__c = :loan.Id AND Charge_Type__c = 'Release Charge'
            LIMIT 1
        ];
        Date oldDate = release.Date__c;

        loan.Term__c = 24;

        Test.startTest();
        update loan;
        Test.stopTest();

        release = [
            SELECT Date__c FROM Loan_Charge__c
            WHERE Id = :release.Id
        ];
        System.assert(release.Date__c > oldDate, 'Release Charge date should be extended');

        List<Loan_Charge__c> adminFees = [
            SELECT Id FROM Loan_Charge__c
            WHERE Loan__c = :loan.Id AND Charge_Type__c = 'Admin Fee'
        ];
        System.assertEquals(1, adminFees.size(), 'Admin Fee should be created');
    }

    @isTest
    static void testBulkReleaseChargeCreation() {
        Account acct = new Account(
            FirstName = 'Automated',
            LastName = 'Test User',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId()
        );

        insert acct;

        List<Loan__c> loans = new List<Loan__c>();
        for (Integer i = 0; i < 200; i++) {
            loans.add(new Loan__c(
                Name = 'Loan ' + i,
                Account__c = acct.Id,
                Date_Loan_Issued__c = Date.today(),
                Term__c = 12,
                Gross_Loan_Amount__c = 5000
            ));
        }

        Test.startTest();
        insert loans;
        Test.stopTest();

        List<Loan_Charge__c> releaseCharges = [
            SELECT Id, Loan__c, Charge_Type__c
            FROM Loan_Charge__c
            WHERE Charge_Type__c = 'Release Charge' AND Loan__c IN :loans
        ];

        System.assertEquals(
            loans.size(),
            releaseCharges.size(),
            'Each loan should have exactly one Release Charge created'
        );

        for (Loan_Charge__c charge : releaseCharges) {
            System.assertEquals('Release Charge', charge.Charge_Type__c, 'Expected charge type to be Release Charge');
        }
    }
}