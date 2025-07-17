public without sharing class LoanTriggerHandler {
  private final List<Loan__c> newLoans;
  private final Map<Id, Loan__c> oldLoansMap;

  /**
   * @description trigger context variables.
   * @param newRecords
   * @param oldRecords
   */
  public LoanTriggerHandler(List<Loan__c> newRecords, List<Loan__c> oldRecords) {
    this.newLoans = newRecords;
    this.oldLoansMap = oldRecords != null ? new Map<Id, Loan__c>(oldRecords) : new Map<Id, Loan__c>();
  }

  /**
   * @description run method to route trigger execution to the correct logic
   */
  public void run() {
    if (Trigger.isAfter) {
      if (Trigger.isInsert) {
        this.onAfterInsert();
      }
      if (Trigger.isUpdate) {
        this.onAfterUpdate();
      }
    }
  }

  /**
   * @description If it's a new loan then add a 500 charge to the loan.
   */
  private void onAfterInsert() {
    List<Loan_Charge__c> chargesToCreate = new List<Loan_Charge__c>();

    for (Loan__c loan : this.newLoans) {
      if (loan.Date_Loan_Issued__c != null && loan.Term__c != null) {
        Date releaseDate = loan.Date_Loan_Issued__c.addMonths(
          loan.Term__c.intValue()
        );

        chargesToCreate.add(
          new Loan_Charge__c(
            Loan__c = loan.Id,
            Charge_Type__c = 'Release Charge',
            Amount__c = 500,
            Date__c = releaseDate
          )
        );
      }
    }

    if (!chargesToCreate.isEmpty() && Schema.sObjectType.Loan_Charge__c.isCreateable()) {
      insert chargesToCreate;
    }
  }

  /**
   * @description Create the admin fee charge when the loan term is updated.
   */
  private void onAfterUpdate() {
    List<Loan_Charge__c> adminFeesToCreate = new List<Loan_Charge__c>();
    Set<Id> loansWithTermChangeIds = new Set<Id>();

    for (Loan__c newLoan : this.newLoans) {
      Loan__c oldLoan = this.oldLoansMap.get(newLoan.Id);

      // Check if the Term field has changed and isn't null.
      if (newLoan.Term__c != oldLoan.Term__c && newLoan.Term__c != null && newLoan.Date_Loan_Issued__c != null) {
        loansWithTermChangeIds.add(newLoan.Id);

        // Add the admin fee charge to the list.
        adminFeesToCreate.add(
          new Loan_Charge__c(
            Loan__c = newLoan.Id,
            Charge_Type__c = 'Admin Fee',
            Amount__c = 300,
            Date__c = Date.today()
          )
        );
      }
    }

    // If no terms were changed, exit early.
    if (loansWithTermChangeIds.isEmpty()) {
      return;
    }

    // Bulk update the 'Release Charge' dates for all affected loans.
    List<Loan_Charge__c> releaseChargesToUpdate = new List<Loan_Charge__c>();
    for (Loan_Charge__c releaseCharge : [
      SELECT Id, Loan__c, Loan__r.Date_Loan_Issued__c, Loan__r.Term__c
      FROM Loan_Charge__c
      WHERE Loan__c IN :loansWithTermChangeIds AND Charge_Type__c = 'Release Charge'
    ]) {
      releaseCharge.Date__c = releaseCharge.Loan__r.Date_Loan_Issued__c.addMonths((Integer)releaseCharge.Loan__r.Term__c);
      releaseChargesToUpdate.add(releaseCharge);
    }

    if (!releaseChargesToUpdate.isEmpty() && Schema.sObjectType.Loan_Charge__c.isUpdateable()) {
      update releaseChargesToUpdate;
    }

    if (!adminFeesToCreate.isEmpty() && Schema.sObjectType.Loan_Charge__c.isCreateable()) {
      insert adminFeesToCreate;
    }
  }
}