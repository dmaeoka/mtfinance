trigger LoanChargeTrigger on Loan_Charge__c (
  before insert,
  before update,
  after insert,
  after update
) {
  new LoanChargeTriggerHandler(Trigger.new, Trigger.old).run();
}