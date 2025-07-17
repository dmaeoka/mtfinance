trigger LoanTrigger on Loan__c (
	before insert,
	before update,
	after insert,
	after update)
{
  new LoanTriggerHandler(Trigger.new, Trigger.old).run();
}
