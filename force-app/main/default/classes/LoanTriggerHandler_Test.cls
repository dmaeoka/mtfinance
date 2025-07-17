@isTest
private class LoanTriggerHandler_Test {

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
  /**
   * @description Test onAfterInsert()
   */
  static void testOnAfterInsertCreatesReleaseCharge() {
      Account acct = new Account(
          FirstName = 'Automated',
          LastName = 'Test User',
          RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId()
      );

      insert acct;

      // Insert loan
      Loan__c loan = new Loan__c(
          Name = 'Loan Insert Test',
          Account__c = acct.Id,
          Date_Loan_Issued__c = Date.today(),
          Term__c = 12,
          Gross_Loan_Amount__c = 10000
      );

      Test.startTest();
      insert loan;
      Test.stopTest();

      List<Loan_Charge__c> charges = [
          SELECT Id, Loan__c, Charge_Type__c, Amount__c, Date__c
          FROM Loan_Charge__c
          WHERE Loan__c = :loan.Id
      ];

      System.assertEquals(1, charges.size(), 'Should create one Release Charge');
      System.assertEquals('Release Charge', charges[0].Charge_Type__c, 'Expected a Release Charge to be created');
      System.assertEquals(500, charges[0].Amount__c, 'Expected Release Charge amount to be £500');
  }

  @isTest
  /**
   * @description Test onAfterUpdate()
   */
  static void testOnAfterUpdateCreatesAdminFeeUpdatesReleaseCharge() {
      Account acct = new Account(
          FirstName = 'Automated',
          LastName = 'Test User',
          RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId()
      );

      insert acct;

      // Insert loan
      Loan__c loan = new Loan__c(
          Name = 'Loan Update Test',
          Account__c = acct.Id,
          Date_Loan_Issued__c = Date.today(),
          Term__c = 12,
          Gross_Loan_Amount__c = 10000
      );
      insert loan;

      // Get Release Charge
      Loan_Charge__c releaseBefore = [
          SELECT Id, Date__c
          FROM Loan_Charge__c
          WHERE Loan__c = :loan.Id AND Charge_Type__c = 'Release Charge'
          LIMIT 1
      ];
      Date oldDate = releaseBefore.Date__c;

      // Update term
      loan.Term__c = 18;

      Test.startTest();
      update loan;
      Test.stopTest();

      // Assert admin fee added
      List<Loan_Charge__c> adminFees = [
          SELECT Id
          FROM Loan_Charge__c
          WHERE Loan__c = :loan.Id AND Charge_Type__c = 'Admin Fee'
      ];
      System.assertEquals(1, adminFees.size(), 'Should create one Admin Fee charge');

      // Assert release charge date updated
      Loan_Charge__c releaseAfter = [
          SELECT Id, Date__c
          FROM Loan_Charge__c
          WHERE Id = :releaseBefore.Id
      ];
      System.assert(releaseAfter.Date__c > oldDate, 'Release Charge date should be updated');
  }
}