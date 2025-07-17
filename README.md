# **Salesforce Technical Test**

## **Scenario: Loan Management System**

The Asset Management team at a finance firm utilizes Salesforce to manage their loan portfolio. To streamline this process, they have implemented two custom objects: Loan and Loan\_Charge\_\_c.

### **Loan Object (Loan\_\_c) \- (Custom Object)**

This object tracks individual loans and contains the following key fields:

* **Loan Name (Name)**: A descriptive name for the loan.
* **Account (Account\_\_c)**: A lookup relationship to the Account object (specifically Person Accounts), representing the individual holding the loan.
* **Security Address (Address\_\_c)**: The physical address of the asset securing the loan.
* **Gross Loan Amount (Gross\_Loan\_Amount\_\_c)**: The initial total amount of the loan issued.
* **Current Loan Balance (Balance\_of\_the\_Loan\_\_c)**: The sum of the Gross Loan Amount and all associated Loan Charges. This field must always reflect the accurate running total.
* **Loan Issue Date (Date\_Loan\_Issued\_\_c)**: The date the loan was initially issued.
* **Loan Term (Months) (Term\_\_c)**: The duration of the loan in months.
* **Total Charges on Loan (Total\_Charges\_on\_the\_Loan\_\_c)**: A summary of all charges applied to the loan. (Consider if this should be a Roll-Up Summary field, or a field maintained by Apex).

### **Loan Charge Object (Loan\_Charge\_\_c) \- (Custom Object)**

This object records various charges associated with each loan and contains the following fields:

* **Charge Date (Date\_\_c)**: The date the charge was applied.
* **Charge Type (Charge\_Type\_\_c)**: A picklist field with the following values: Release Charge, Interest Charge, Legal Fee, Admin Fee.
* **Amount (Amount\_\_c)**: The monetary value of the charge.
* **Loan (Loan\_\_c)**: A master-detail or lookup relationship to the Loan\_\_c object, associating the charge with its respective loan.

## **Requirements**

Please implement the following functionalities using Apex triggers, classes, and other Salesforce platform features as appropriate. Adhere to Salesforce best practices, including bulkification and robust error handling.

1. **Initial Loan Creation \- Release Charge Automation:**
   * Upon the creation of a new Loan\_\_c record, automatically generate a Loan\_Charge\_\_c record.
   * This initial charge must have:
     * Charge Type: Release Charge
     * Amount: £500
     * Charge Date: Calculated as the Loan Issue Date \+ Term (in months). This date represents the 'End of Loan Term' or 'Loan Completion Date'.
   * **Constraint:** A Loan\_\_c record can have **only one** Release Charge associated with it at any time. Prevent the creation of additional Release Charge records for the same loan.
2. **New Loan Charge Management:**
   * When a new Loan\_Charge\_\_c (of any type other than Release Charge) is added:
     * It must always be applied **before** the existing Release Charge. If the Charge Date of the new charge is **on or after** the Release Charge Date, the Release Charge Date must be automatically extended by **one month**.
     * The Current Loan Balance field on the associated Loan\_\_c record must be updated to reflect the addition of this new charge.
3. **Data Integrity:**
   * Ensure the Current Loan Balance field on the Loan\_\_c object consistently and accurately reflects the sum of the Gross Loan Amount and all associated Loan\_Charge\_\_c amounts. This should be a running total that updates with every charge addition or modification.
4. **Test Coverage:**
   * Write Apex tests to achieve a minimum of **75% code coverage** for all Apex triggers and classes. Strive for higher coverage where feasible and meaningful.

## **Bonus Requirements (Optional, but highly encouraged)**

Demonstrate advanced understanding by implementing the following:

1. **Loan Term Modification Impact:**
   * If the Term\_\_c field on a Loan\_\_c record is changed *after* the loan's initial creation, the Release Charge Date on the associated Release Charge record must be automatically updated to reflect the new loan term.
   * Simultaneously, when the Term\_\_c is changed, a new Loan\_Charge\_\_c record must be automatically added to the loan with the following details:
     * Charge Type: Admin Fee
     * Amount: £300
     * Charge Date: The date the Term\_\_c was modified (i.e., TODAY() or the date of the transaction).
   * **Order of Operations:** If the Admin Fee's Charge Date falls on the same day as an existing Interest Charge, the Admin Fee must always be processed and applied *before* the Interest Charge for calculation purposes.

## **Submission Guidelines**

Please provide the following:

* A link to a Git repository containing your Salesforce solution.
* Any necessary instructions for deploying the solution to a new Salesforce Developer Edition org using Salesforce CLI tools (e.g., sfdx force:source:deploy).
* The repository should be clean, well-organized, and demonstrate your understanding of version control.

## **Resources**

* Sign up for a free Salesforce Developer Edition: [https://developer.salesforce.com/signup](https://developer.salesforce.com/signup)

## **Hints & Tips**

* This exercise primarily assesses your Apex programming ability and understanding of Salesforce platform capabilities.
* Feel free to leverage custom fields, custom settings, formula fields, validation rules, or other declarative features where they simplify the solution or improve maintainability.
* Adhere to Salesforce best practices:
  * **"Skinny" Triggers:** Keep trigger logic minimal, delegating complex operations to Apex classes.
  * **Bulkified Code:** Ensure your Apex code can handle multiple record insertions, updates, or deletions efficiently without hitting governor limits.
  * **Robust Test Coverage:** Write comprehensive test classes that cover positive, negative, and bulk scenarios.
* Keep the solution focused and demonstrate core programming concepts. While production-readiness is always a goal, the primary aim here is to showcase your design choices and problem-solving approach. Be prepared to discuss your solution and design decisions during a follow-up discussion.
