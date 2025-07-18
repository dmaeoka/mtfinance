public without sharing class LoanChargeTriggerHandler {
  private final List<Loan_Charge__c> newCharges;
  private final Map<Id, Loan_Charge__c> oldChargesMap;
  public static final String RELEASE_CHARGE = 'Release Charge';

  /**
   * @description Constructor that accepts the trigger context variables.
   * @param newRecords `Trigger.new`
   * @param oldRecords `Trigger.old`
   */
  public LoanChargeTriggerHandler(
    List<Loan_Charge__c> newRecords,
    List<Loan_Charge__c> oldRecords
  ) {
    this.newCharges = newRecords;
    this.oldChargesMap = oldRecords != null
      ? new Map<Id, Loan_Charge__c>(oldRecords)
      : new Map<Id, Loan_Charge__c>();
  }

  /**
   * @description Central method to route trigger execution to the correct logic.
   */
  public void run() {
    if (Trigger.isBefore) {
      if (Trigger.isInsert) {
        this.onBeforeInsert();
      }
    }
    if (Trigger.isAfter) {
      if (Trigger.isInsert) {
        this.onAfterInsert();
      }
      if (Trigger.isUpdate) {
        this.onAfterUpdate();
      }
      if (Trigger.isDelete) {
        this.onAfterDelete();
      }
    }
  }

  /**
   * @description Handles logic for the 'before insert' event.
   * A Loan can only have one 'Release Charge'.
   */
  private void onBeforeInsert() {
    Set<Id> loanIdsToCheck = new Set<Id>();

    // Collect Loan ids for new charges that are of type 'Release Charge'.'
    for (Loan_Charge__c newCharge : this.newCharges) {
      if (newCharge.Charge_Type__c == RELEASE_CHARGE && newCharge.Loan__c != null) {
        loanIdsToCheck.add(newCharge.Loan__c);
      }
    }

    // No 'Release Charges' to validate, return.
    if (loanIdsToCheck.isEmpty()) {
      System.debug('loanIdsToCheck is empty.');
      return;
    }

    System.debug('loanIdsToCheck.size(): ' + loanIdsToCheck.size());

    // Test if Loan Charge object is accessible.
    if(Schema.sObjectType.Loan_Charge__c.isAccessible()){
      // Query for existing 'Release Charge' records on those specific loans.
      // By adding the query results to a Set, we get an efficient way to check for existence.
      Set<Id> loansWithExistingReleaseCharge = new Map<Id, SObject>([
          SELECT Loan__c FROM Loan_Charge__c
          WHERE Loan__c IN :loanIdsToCheck
          AND Charge_Type__c = :RELEASE_CHARGE
      ]).keySet();

      // If there is a any new 'Release Charge', throw an error
      for (Loan_Charge__c newCharge : this.newCharges) {
        if (newCharge.Charge_Type__c == RELEASE_CHARGE && loansWithExistingReleaseCharge.contains(newCharge.Loan__c)) {
          newCharge.addError('Cannot create a second Release Charge. This loan already has one.');
        }
      }
    }
  }

  /**
   * @description Extend the release charge date if needed and update balances.
   */
  private void onAfterInsert() {
    Set<Id> loanIds = new Set<Id>();
    for (Loan_Charge__c charge : this.newCharges) {
      loanIds.add(charge.Loan__c);
    }

    // First: Extend the 'Release Charge' date.
    this.extendReleaseChargeDate(loanIds);

    // Second: Update balances on the parent loans.
    this.updateLoanBalances(loanIds);
  }

  /**
   * @description Handles logic for 'after update' of existing charges.
   * If a charge is reparented, we need to update both old and new parent loans.
   */
  private void onAfterUpdate() {
    Set<Id> loanIds = new Set<Id>();
    for (Loan_Charge__c charge : this.newCharges) {
      loanIds.add(charge.Loan__c);
    }
    // Fetch the old loan Ids from the oldChargesMap.
    for (Loan_Charge__c oldCharge : this.oldChargesMap.values()) {
      loanIds.add(oldCharge.Loan__c);
    }
    this.updateLoanBalances(loanIds);
  }

  /**
   * @description If a charge is deleted, we need to update the balance on the parent loan.
   */
  private void onAfterDelete() {
    Set<Id> loanIds = new Set<Id>();
    // Fetch the old loan Ids from the oldChargesMap.
    if (this.oldChargesMap == null) {
      System.debug('oldChargesMap is empty.');
      return;
    }
    // In 'after delete', the records are in Trigger.old, which populates oldChargesMap.
    for (Loan_Charge__c charge : this.oldChargesMap.values()) {
      loanIds.add(charge.Loan__c);
    }
    this.updateLoanBalances(loanIds);
  }

  /**
   * @description Extends the 'Release Charge' date by one month if a new charge is added on or after the current release date.
   * @param loanIds The set of Loan Ids to check.
   */
  private void extendReleaseChargeDate(Set<Id> loanIds) {

    // Create a map of id and loan charge to update.
    Map<Id, Loan_Charge__c> releaseChargesToUpdate = new Map<Id, Loan_Charge__c>();

    // Create a list of charges to check.
    List<Loan_Charge__c> chargesToCheck = new List<Loan_Charge__c>();
    for (Loan_Charge__c newCharge : this.newCharges) {
      if (newCharge.Charge_Type__c != RELEASE_CHARGE) {
        chargesToCheck.add(newCharge);
      }
    }

    // If there are no charges to check, exit.
    if (chargesToCheck.isEmpty()) {
      System.debug('chargesToCheck is empty.');
      return;
    }

    // Get the existing 'Release Charge' for the affected loans.
    Map<Id, Loan_Charge__c> existingReleaseCharges = new Map<Id, Loan_Charge__c>();
    for (Loan_Charge__c rc : [
      SELECT Id, Loan__c, Date__c
      FROM Loan_Charge__c
      WHERE Loan__c IN :loanIds
      AND Charge_Type__c = :RELEASE_CHARGE
    ]) {
      existingReleaseCharges.put(rc.Loan__c, rc);
    }

    // For each new charge, check if its date requires the corresponding Release Charge to be moved.
    for (Loan_Charge__c newCharge : chargesToCheck) {
      if (existingReleaseCharges.containsKey(newCharge.Loan__c)) {
        Loan_Charge__c releaseCharge = existingReleaseCharges.get(newCharge.Loan__c);

        // If the new charge date is on or after the release charge date...
        if (newCharge.Date__c >= releaseCharge.Date__c) {
          // ...prepare the release charge to be updated.
          releaseCharge.Date__c = releaseCharge.Date__c.addMonths(1);
          releaseChargesToUpdate.put(releaseCharge.Id, releaseCharge);
        }
      }
    }

    if (!releaseChargesToUpdate.isEmpty()) {
      System.debug('Updating the Loan_Charge__c values');
      update releaseChargesToUpdate.values();
    }
  }

  /**
   * @description Re-calculates and updates the total balance and charges on parent loans.
   * This method is the core of Requirement #3 (Data Integrity).
   * @param loanIds The set of Loan Ids to update.
   */
  private void updateLoanBalances(Set<Id> loanIds) {
      if (loanIds == null || loanIds.isEmpty()) {
        System.debug('loanIds is empty.');
        return;
      }

      loanIds.remove(null);

      Map<Id, Decimal> totalChargesMap = getTotalChargesByLoan(loanIds);

      if (!Schema.sObjectType.Loan__c.isUpdateable()) {
        System.debug('Loan__c is not updatable');
        return;
      }

      List<Loan__c> loansToUpdate = prepareLoanUpdates(loanIds, totalChargesMap);

      if (!loansToUpdate.isEmpty()) {
          System.debug('Updating loansToUpdate values');
          update loansToUpdate;
      }
  }

  /**
   * @description Queries the total charges for the given loans.
   * @param loanIds The set of Loan Ids to query.
   * @return A map of Loan Ids to their total charges.
   */
  private Map<Id, Decimal> getTotalChargesByLoan(Set<Id> loanIds) {
      System.debug('Returning the total charge by loan');
      Map<Id, Decimal> result = new Map<Id, Decimal>();
      for (AggregateResult ar : [
          SELECT Loan__c, SUM(Amount__c) totalAmount
          FROM Loan_Charge__c
          WHERE Loan__c IN :loanIds
          GROUP BY Loan__c
      ]) {
          result.put(
            (Id) ar.get('Loan__c'),
            ((Decimal) ar.get('totalAmount')) != null ? (Decimal) ar.get('totalAmount') : 0
          );
      }
      return result;
  }

  /**
   * @description Prepares the Loan__c records to be updated.
   * @param loanIds The set of Loan Ids to update.
   * @param totalChargesMap A map of Loan Ids to their total charges.
   * @return A list of Loan__c records to be updated.
   */
  private List<Loan__c> prepareLoanUpdates(Set<Id> loanIds, Map<Id, Decimal> totalChargesMap) {
      List<Loan__c> updates = new List<Loan__c>();
      System.debug('List of loanIds to update:');

      for (Loan__c loan : [
          SELECT Id, Gross_Loan_Amount__c
          FROM Loan__c
          WHERE Id IN :loanIds
      ]) {
          Decimal totalCharges = totalChargesMap.get(loan.Id) != null ? totalChargesMap.get(loan.Id) : 0;
          Decimal grossAmount = loan.Gross_Loan_Amount__c != null ? loan.Gross_Loan_Amount__c : 0;

          updates.add(new Loan__c(
              Id = loan.Id,
              Total_Charges_on_the_Loan__c = totalCharges,
              Balance_of_the_Loan__c = grossAmount + totalCharges
          ));
      }
      return updates;
  }
}
