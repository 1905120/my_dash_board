* @ValidationCode : MjozNjUzNjY1MDI6Q3AxMjUyOjE3Njc3MDQyMzQwODk6ci50aGlydW1hbGFpc2VsdmFuOjE3MDowOjA6MTpmYWxzZTpOL0E6REVWXzIwMjUwOS4wOjUwODA6MzkxMw==
* @ValidationInfo : Timestamp         : 06 Jan 2026 18:27:14
* @ValidationInfo : Encoding          : Cp1252
* @ValidationInfo : User Name         : r.thirumalaiselvan
* @ValidationInfo : Nb tests success  : 170
* @ValidationInfo : Nb tests failure  : 0
* @ValidationInfo : Rating            : N/A
* @ValidationInfo : Coverage          : 3913/5080 (77.0%)
* @ValidationInfo : Strict flag       : true
* @ValidationInfo : Bypass GateKeeper : false
* @ValidationInfo : Compiler Version  : DEV_202509.0
* @ValidationInfo : Copyright Temenos Headquarters SA 1993-2026. All rights reserved.
*-----------------------------------------------------------------------------
$PACKAGE AA.PaymentSchedule
 
SUBROUTINE AA.PROJECT.PAYMENT.SCHEDULE.SCHEDULES(SCHEDULE.INFO, REQD.END.DATE, NO.CYCLES, ADJUST.FINAL.AMOUNT, PAYMENT.DATES, PAYMENT.TYPES, PAYMENT.METHODS, PAYMENT.AMOUNTS, PAYMENT.PROPERTIES,  PAYMENT.PROPERTIES.AMT, TAX.DETAILS, OUTSTANDING.AMOUNT, FINAL.PRINCIPAL.POS, PAYMENT.PERCENTAGES, PAYMENT.MIN.AMOUNTS, PAYMENT.DEFER.DATES, PAYMENT.BILL.TYPES, CHARGE.CALC.INFO, PARTICIPANTS.DETAILS, PART.PAYMENT.PROPERTIES, PARTICIPANT.PROPERTIES.AMT, PARTICIPANT.TAX.DETAILS, PARTICIPANT.OUTSTANDING.AMT, PARTICIPANT.PARTICIPATION.TYPES, PARTICIPANTS.ACCT.MODE, PAY.FIN.DATES, RET.ERROR)

*** <region name= Description>
*** <desc>Task of the sub-routine</desc>
* Program Description
*
** This routine builds the payment dates for the payment schedule with the payment
** amounts split between the properties defined in Payment Schedule record.
** It calcualtes the property amount based on the calculation type defined in
** AA.PAYMENT.TYPE,
** Manual - Amount defined in Payment schedule is returned
** Calculated - Interest is calculated using AA.CALC.INTEREST based on its own conditions
**              Charge is calculated using AA.CALC.CHARGE based on its own conditions
**              Tax is calculated using AA.CALC.TAX based on its own conditions
**              Amount is calculated based on the calculation type
**                 - Constant - Difference between the payment amount defined in Payment Schedule record
**                              and the asscoiated properties except Account
**                 - Linear - Amount defined in Payment schedule is returned
**                 - Actual - If percentage is specified percentage of CURACCOUNT balance is returned
**
** The amounts are not signed, but this routine can handle both assets and liabilities.
** It handles different types of payment methods - Due, Pay, Expected due and capitalise
** Capitalisation always increases the outstanding amount (CURACCOUNT) amount.
*
** Payment Dates can also be passed to this routine along with
** Payment Types, Payment Properties associated for the payment date
*
** Outstanding amount can also be passed, if not passed it calcualtes the amount as on the
** current activity date either from CURACCOUNT balance (after disbursement of the loan or
** deposit funds receipt) or CURTERM.AMOUNT balance (if CURACCOUNT is zero) or from
** Term Amount AMOUNT field (for New arrangement activity).
*
*-----------------------------------------------------------------------------
* @uses I_AA.APP.COMMON
* @package retaillending.AA
* @class AA.PaymentSchedule
* @stereotype subroutine
* @link AA.BUILD.PAYMENT.SCHEDULE.RECORD AA.GET.PROPERTY.RECORD
* @link AA.GET.BASE.DATE AA.BUILD.PAYMENT.SCHEDULE.DATES
* @link AA.GET.PROPERTY.CLASS AA.CALC.INTEREST
* @author ramkeshav@temenos.com
*-----------------------------------------------------------------------------
*
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Arguments>
*** <desc>Input and out arguments required for the sub-routine</desc>
* Arguments
*
* Input
*
* @param  ScheduleInfo<1>  Arrangement id   Arrangement contract id
* @param  ScheduleInfo<2>  Property date    Repayment property effective date
* @param  ScheduleInfo<3>  Property         Repayment property for which schedule dates are required
* @param  ScheduleInfo<4>  Property record  Property record, if property and property date are not passed
* @param  ScheduleInfo<7>  Flag setted only if called from ITERATE/PROJECTOR routines
* @param  ScheduleInfo<17> Flag              Pass Calculate types if so only payment types belonging to this calculate type will be cycled
* @param  ScheduleInfo<18> Flag              Available amounts upto which projection should happen. Used only in AA.BUILD.PAYMENT.SCHEDULE.SCHEDULES
* @param  ScheduleInfo<22> Flag              Flag will be set to ADJUST.CAP/ADJUST.DUE activity to get last payment date as effective date
* @param  ScheduleInfo<30> Flag             This incoming flag indicates that if DUE.AND.CAP payments are defined in schedule definition, then routine will need to
*                                           calculate and return the details of the capitalised portion of interest/charge in the case of a partial/full capitalisation
*                                           under a seperate duplicate payment type.
*
* @param  ScheduleInfo<31> Flag             This new incoming flag indicates that the schedules need to be projected after ignoring any ACTUAL.AMT defined in the payment schedule.
* @param  ScheduleInfo<32> Flag             This new incoming flag indicates that the current process is a term recalculation.
* @param  ScheduleInfo<35>                  This new incoming flag indicates to call CalcCharge routine with Dummy Arrangement Id to get the charge amounts from charge condition cached.
*                                           This will be set from ArrangementScheduleProjector routine
* @param  ScheduleInfo<44> Flag             This new incoming flag contains the participant record.
*                                           This has set from Project Payment Schedule Dates routine.
* @param ScheduleInfo<74> Flag              To skip final schedule processing in accrue interest during LENDING prepayment as it is like partial prepayment not a payoff.
* @param  RequiredEndDate                   End date up to which schedules are required
* @param  NoOfCycles                        Number of payment dates to build
* @param  AdjustFinalAmount                 Adjust final payment amount to make oustanding amount zero
*
* @param  ScheduleInfo<79> Flag             Contract with advance interest and actual amount defined cases - During Principal decrease activity, the principal balance is decreased so that (Actual amount greater than the current outstanding amount error is raised)
*                                           in PPSS routine and interest also not calculated in the PPSS routine for the new principal balances, So that we are handling to caluate the interest in PPSS rtn itself with this flag
*
* Output
*
* @return PaymentDates                      Returned cycled payment dates
* @return PaymentTypes                      Returned payment types
* @return PaymentAmounts                    Returned payment amounts for each type
* @return PaymentProperties                 Returned properties due for the cycled dates
* @return PaymentPropertiesAmount           Returned due amounts for each property
* @return Tax Details                       Returned  Base Properties , Tax Properties & Tax amounts for each property
* @return OutstandingAmount                 Loan outstanding amount for each payment date
* @return FinalPrincipalPos                 Returns the mv position where outstanding becomes zero
* @return ParticipantsDetails               Returns list of Participants, if defined for Borrower arrangement. Separated by '*' for each Payment Date.
* @return ParticipantPaymentProperties      Returns properties due for the cycled dates for each participant separated by '*' for each Payment Date.
* @return ParticipantPropertiesAmt          Returns due amount for each property, for each participant. Separated by '*' for each Payment Date.
* @return ParticipantTaxDetails             Returns Tax properties and tax amount for each property, for each participant. Separated by '*' for each Payment Date.
* @return ParticipantOutstandingAmt         Returns Outstanding amount for each participant separated by '*'.
* @return ReturnError                       Error messages, if any, during processing
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Modification History>
*** <desc>Modifications done in the sub-routine</desc>
* Modification History
*
* For previous modification history refere to older revision 1.23
*
* 29/12/07 - BG_100016449
*              Ref : TTS0754838
*              Ensure constant payment is maintained if Payment Type is constant
*              this is true for interest only payments.
*
* 17/03/08 - BG_100017747
*            Ref: TTS0605128
*            Sum of actual amount should not be greater than outstanding amount
*
* 24/03/08 - BG_100017315
*            Adjustment amount problem for Linear payment type
*            Ref: TTS0807820
*
* 11/04/08 - BG_100018096
*            Ref : TTS0706699
*            To calculate charge pass payment date and not the effective date
*            schedules should be based on payment date.
*
* 09/05/08 - BG_100018223
*            Ref : TTS0801399
*            Add the capitalised amount to the outstanding amount
*
* 16/05/08 - BG_100018434
*            Ref : TTS0801814
*            Include an extra argument PAYMENT.METHODS to denote the
*            payment methods for each payment type in the routine
*            AA.BUILD.PAYMENT.SCHEDULE.SCHEDULES
*
* 07/08/08 - BG_100019398
*            Ref : TTS0802647
*            Include the new argument PROPERTY in the routine AA.GET.LAST.PAYMENT.DATE
*            to return the last payment date of the required property
*
* 16/07/08 - EN_10003728
*            Ref : SAR-2008-02-18-0008
*            Field name of DRAWDOWN.DATE is changed to START.DATE in AA.ACCOUNT.DETAILS.
*
* 19/08/08 - EN_10003795
*            Call local routine, to calculate account amount, attached to payment type
*            record. Ref: SAR-2008-05-30-0001
*
* 20/08/08 - BG_100019571
*            Ref : SAR-2008-02-18-0008
*            Removing the call to the Routine AA.GET.BASE.DATE.
*
* 17/09/08 - EN_10003849
*            Ref : SAR-2008-05-22-0045
*            Modified to pass outstanding amount, if the outstanding amount is not from
*            ACCT.ACTIVITY or TERM.AMOUNT it can be passed through.
*
* 05/11/08 - BG_100020712
*            No need to pass the RECORD.START.DATE value into the routine AA.CALC.INTEREST.
*            The Value for RECORD.START.DATE will be populated in the routine AA.ACCRUE.INTEREST.
*
* 07/11/08 - BG_100020750
*            Ref : TTS0803877
*            Incorrect Annuity amt when there is multiple payment type
*
* 23/12/08 - BG_100021411
*            Ref : TTS0804843
*            The accrued amount to adjust is picked from AA.INTEREST.ACCRUALS. Current interest accrued
*
* 08/01/09 - BG_100021538
*            Ref : TTS0805009
*            Only include data Which belongs to corresponding period in R$PROJECTED.ACCRUALS
*
* 26/12/08 - BG_100021149
*            Ref : TTS0707043
*            If the balance is not present in ACCT.ACTIVITY for CURRACCOUNT ,then don't get the balance amount from TERM.AMOUNT.
*            This is done to stop the bill generation ,if Disburement is not done.
*
* 25/01/09 - BG_100021764
*            When term amount is calculated during loan modelling there will not be outstanding amount in term amount balance type
*            if schedules are projected from simulation overview. Get the term amount directly from term amount property record.
*
* 06/02/09 - CI_10060460
*            Ref : HD0901087
*            When multiple Payment types defined for ACCOUNT property, and any of two payments falls on the same date
*            (Payment End Date) consider the last Account Property to find final amount.
*
* 30/01/09 - BG_100021773 & BG_100021895
*            Past accruals should also include NAU movements.
*
* 12/02/09 - BG_100022107
*            Get the correct ACCOUNT.FINAL.POS from the PAYMENT.PROPERTIES array.
*
* 13/02/09 - BG_100022038
*           When % is set on Principal, Principal amt is made to calculateby adding the capitalised interest  to the Outstanding balance.
*
* 23/02/09 - CI_10060868
*            Ref : HD0901894
*            Interest payment is required as of payment end date or on maturity date when the frequency of interest payments do not
*            have a interest scheduled on payment end date
*
* 12/03/09 - BG_100022665
*            Replace direct access to large arrays with a remove process through
*            the payment arrays to improve performance for long term loans
*
* 12/05/09 - BG_100023585
*            Ref : TTS0907296
*            Performance fixes
*
* 28/05/09 - BG_100023832
*            Ref : TTS0907604
*            calc amount is not updated correctly for linear contracts
*
* 04/07/09 - BG_100024271
*            Ref : TTS0908001, TTS0908262
*            The outstanding amount is zero in Account schedules, the interest or charge schedules which are present
*            after the Account schedules projected correctly.
*            The term is set then the schedules are stopped when the outstading amount is zero.
*
* 07/07/09 - BG_100024398
*            Ref : TTS0908001
*            Variable wrongly used for extend cycles
*
* 29/06/09 - BG_100023996
*            Ref : TTS0906019
*            Get the last payment date by passing the Payment Properties.
*
* 19/08/09  - EN_10004282
*            Ref : SAR-2008-11-06-0018
*            Tax calculation  in AA.
*
* 09/11/09 - BG_100025585
*            Ref: TTS0909962
*            New argument CURRENT.INT.AMT add in AA.CALC.INTEREST routine.
*
* 25/09/09 - CI_10066335
*            Ref : HD0937020
*            Last payment type is fetched for the corresponding payment type which is getting processed.
*
* 09/11/09 - EN_10004396
*            Ref : SAR-2008-11-06-0019
*            Store tax local currency amount also in TAX.DETAILS
*
* 10/11/09 - EN_10004425
*            Ref : SAR-2008-11-06-0013
*            Introduced a new payment method MAINTAIN for deposits. As the name suggests, the actual amt
*            mentioned for the ACCOUNT property will be maintained.
*
* 27/11/09 - BG_100025852
*            Ref : TTS0910675,TTS0910799
*            Take the base balance as the EXP<Account> instead of CUR<TermAmount> incase of
*            Deposits product line.
*
* 28/11/09 - BG_100025949
*            For SAVINGS productline always take the user defined amount for the
*            property
*            For the enquiry , take  the balance  from exp account also
*
* 01/12/09 - BG_100025985
*            Payment method is assigned for payment type and not for every property
*
* 04/12/09 - BG_100026059
*            Ref : TTS0910870
*            Take the capitalised amount on the payment end date also for correct outstanding
*            amount incase of deposits.
*
* 12/11/09 - CI_10068129
*            LOC Accrued interests are not capitalised on the scheduled payment date after
*            the LOC balance went to zero
*
* 12/01/10 - Task: 13430; Defect: 12656
*            Uninitialized variables during cob.
*
* 19/01/10 - Ref : Def-12154, Task-14204
*            INT.AMOUNT should be addition of INT.AMOUNT, CURR.INT.AMOUNT, ADJUSTMENT.AMOUNT.
*
* 22/01/10 - Task : 16719 , Defect : 12041
*            For Deposists, EXPACCOUNT sign is changed to update the AA$CONTRACT.DETAILS
*            with Positive Amount.
*
* 02/02/10 - Task: 18850
*            Defect: 18425
*            If LAST.PAYMENT.DATE is not found, then assign period start date to Base date
*            to cater multiple interest properties on scheduled on different dates.
*            Reverting the fix done in Task 14204.
*
* 24/02/10 - Task - 24550
*            Defect - 21634
*            Varialbles PAYMENT.METHODS.NEW and INTEREST.ACC.PRESENT  are initialised with null.
* 26/04/10 - Enhancement Id - 19298
*            Task Id - 42379
*            Opening fields MATURITY.DATE/TERM for CALL contracts.
*
* 07/06/10 - Task 56186
*            Defect : 55380
*            Caching the LAST.ACCRUAL.DATE creates problem while appending NULL dates.
*
* 27/07/10 - Enhancement # 19158
*            Task # 22821
*            Payment End date field was moved from the AA.ARR.PAYMENT.SCHEDULE to
*            AA.ACCOUNT.DETAILS file.
*
* 17/08/10 - Task:68638 // Enhancement:63652
*            Accounts product line is enhanced to allow creation of savings/current
*            account and to do some basic activities on it.
*
* 23/08/10 - Task No: 79038 & Defect No: 77046 & Ref No: HD1027754
*            Last payment schedule oustanding amount will not goes to zero.
*
* 10/09/10 - Task : 85708
*            Schedule projection should continue for one more cycle to check if there are any accrued interest to be billed,
*            only if the activity effective date or bank date goes beyond payment end date.
*            Ref: 84825
*
* 25/08/10 - Task : 38558
*            Enhancement : 26802
*            Changes to improve performance.
*
* 07/09/10 - Task 83386
*            Defect 74404
*            Store Last accrual date even for fixed interest amount.
*
* 23/09/10 - Task 91389
*            Defect 77815/ HD 1031503
*            1. Support for penalty interest calculation, even after oustanding principal becomes zero
*            2. Parameter added to return the mv postion where outstanding became zero
*            3. Check made for same payment type in Process Forward Schedules
*
* 08/10/10 - Task No: 83384 & Defect No: 73825 & Ref No: HD1031818
*            Projected Schedule Enquiry has incorrect figures for Deposits Product Line.
*
* 27/07/10 - E-26687 T-52782
*    Payment method to be set to DUE when interest amount is negative and balance type
*            of the interest property is CREDIT/BOTH
*
* 30/10/10 - Enhancement - 73497
*            Task - 73501
*            Update COMPOUND.YIELD data in accrual details.
*
* 01/12/10 - Task 114349
*            Ref : Defect 59533
*            NAU Movements will be skipped in COB fro ISSUE Bill , Make Due & Accrue- when FT  Disbursement is in INAU.
*
* 01/12/10 - Enhancement - 73414
*            Task - 109806
*            New validations added for the progressive payment type
*
* 11/12/10 - Test Task - 117239; Enhancement - 73414
*            Task 115155
*            Take the Progressive Percentage from the correct multi-value set.
*
* 16/12/10 - 119363
*            Ref : 118452
*            Rounding should applied for user defined payment amount also.
*
* 25/12/10 - 100934
*            Ref : 91009
*            Raise Residual bill only if residual amount exists.
*
* 27/12/10 - Task: 122009
*            Ref: 117951
*            While processing Account property class PRESENT.VALUE is not considered.
*
* 21/12/10 - Enhancement - 73427
*            Task - 73430
*            Principle and Interest amount calculation changed for Deferred Interest/Principle Progressivity
*
* 2/2/2011 - Defect - 134171
*            Scheduled bills has generated even before disbursement wrongly
*
* 16/02/11 - 77535
*            Ref: 56308
*            New arguments included for AA.CALC.CHARGE routine
*
* 14/2/11  - Enhancement 56317
*            Task 106424
*            Arrangement Id stored in AA.CONTRACT.DETAILS
*
*
* 24/02/11 - EN : 56307
*            Task: 136334
*            New Argument added in AA.GET.LAST.PAYMENT.DATE
*
* 11/03/11 - Task 109026
*            Getting RES balance is alright for Residual processing which will
*            be used to pass the amount to local routine. However we should pass
*            CURRENT.ONLY to get current period's accrued amount and the ADJUSTMENT.AMOUNT
*            should be sum of RES & CURRENT.ONLY amounts
*
* 19/02/11 - CI_10072678
*           Defect - 153637
*           When interest amount is less than zero after adjustment ,assign zero to interest amount
*
* 19/10/10 - Task # 98871
*            Defect # 98755
*            Round the amount if percentage is specified in Payment Schedule
*
* 24/02/11 - Task : 180168
*    Ref : 90673
*            Match Deposits to product line and check the Payment Method before deciding
*            if the Balance amount should be increased or decreased for deposits and savings.
*
* 30/03/11 - Task: 181568
*            Code has been changed for When changes(like rate, PS) are done in the mid-way of an interest period, then projection is wrong
*
* 04/04/11 - Task: 175975 / Defect : 174626
*            For interest calculation, RECORD.START.DATE should always be from the New arrangement effective date.
*
* 08/04/11 - Task 188690 / Defect : 52292
*            Variable IGNORE.INT.PROP.UPDATE is  Initialised
*
* 06/04/11 - Defect 35659
*            Task: 186644
*            When PAYMENT.METHOD is MAINTAIN then relax checking actual amount is greater than outstanding amount
*            And avoid assigning null to PROCESS.SCHEDULE.
*
* 04/05/11 - Task 202450
*            Defect 194783
*            If bill issued the amount for the property should be taken from the corresponding bill proeprty amount
*
* 03/05/11 - Task - 200288
*            Defect - 100319
*            If the Actual amount is greater than the Remainting amount (current outstanding) then raise error message.
*
* 17/05/11 - Task - 211170
*            Defect - 100319
*            Schedules are projected wrongly for Last payment if the payment calculation is manual.
*
* 28/07/11 - Task - 252948
*            Defect : 249829
*            For manual interest payment type, the user defined actual amount is assigned correctly.
*
* 12/11/11 - Task : 307438
*            Ref : 305548
*            Code changed to stop generating bills before disbursement. Generate the bill ,only if disbursement is done.
*
* 08/11/11 - Task - 279394
*            Defect - 277482
*            If interest amount is negative then payment method should be changed to "PAY" and amount should be absolute.
*
* 14/11/11 - Task : 307589
*            Ref : Defect 306818
*            When multiple payment type exist, the progress rate has made to get from the corresponding
*            payment type.
*
* 01/12/11 - Task - 279394
*            Defect - 277482
*            If interest amount is negative then payment method should be changed to "PAY" and amount should be absolute.
*
* 10/11/11 - Task : 306487
*            Ref : Defect 302213
*            When residual amount is present, enquiry AA.SCHEDULES.FULL has been made to project
*            the interest amount calculated with the base balance including residual amount.
*
* 30/11/11 - Task 22911
*            Ref : Enhancement 19308
*            Allow multiple expected amounts (increases) for deposits
*
* 03/11/11 - 247217
*            For Credit charge type raise only CREDIT entries and need to reduce this amount from outstanding amounts for lending
*            For deposits and savings need to add amount to outstanding amount
*
* 21/12/11 - Task : 328439
*            Ref : Defect 327017
*            Variables "ACCOUNT.AMOUNT.CHECK","REMAIN.AMOUNT","BILL.INTEREST.AMOUNT" and "OUTSTANDING.AMOUNT" has been initialised
*
* 28/12/11 - Task : 346429
*            Defect : 344517
*            Need to pass correct period start date end date to AA.CALC.INTEREST to get correct
*            interest amounts in the system
*
* 25/01/12 - Task 345351
*            Ref : 196006
*            Allow negative rate with Capitalisation
*
* 10/03/12 - Task : 369770
*            Defect : 369766
*            If there is only one PERIOD.START.DATE multy value set in the Interest Accrual record then only assign PERIOD.STARTD.DATE
*            from the Interest accrual record for interest calculation. Otherwise take it as Payment schedule Base Date.
*
* 07/05/12 - Task 410610
*            Ref : 267298
*            Consider Residual amount to avoid excess principal schedule.
*
* 22/06/12 - Task 427692
*            Ref : Defect 425760
*            Residual processing should not be applied for commitment type deposit contracts
*
* 13/08/12 - Task: 462582
*            Refe: 439351
*            The Last Payment Date should now be updated based on the Property passed.
*            And Forward Patch the changes done under the tasks 441709 and 442784.
*
*
* 04/08/12 - Task : 424421
*            Defect : 422133
*            Get the outstanding amount as on effective date.
*
* 15/10/12 - Enhancement : 352104 / Task : 395784
*            Automatic Scheduled Disbursements
*            New argument added to store percentages defined for each payment type
*
* 10/10/12 - Task : 498576
*            Ref : Defect 487015
*            For enquiry, when disbusement had happened then we should not consider EXP balances as an outstanding amount
*            and proceed with interest or charge calculation.
*
* 17/10/12 - Task : 502821
*            Ref : Defect 498059
*            When residual amount defined in payment shedules, system should project residual amount on payment end date as an outstanding amount
*            when system has not crossed payment end date.
*
* 22/01/13 - Task : 558253
*            Ref : Defect 554115
*            Residual amount defined in future dated payment schedule records are taken from SCHEDULE.INFO<9>.
*            Hence the residual amount is fetched from effective payment dates.
*
* 24/04/13 - Task : 659660
*            Ref : 575787
*            Variable uninitialised error.
*
* 24/04/13 - Task : 659660
*            Ref : 630248
*            Ensure that Account amount doesn't exceed the available amount even if local routine returns wrongly.
*
* 19/06/13 - Defect: 690335
*            Task 708615
*            Calc routine for Interest Property to Support Rule 78 and Linear Accrual
*
* 20/08/13 - Task : 758406
*            Defect : 749012
*            Initialise the END.DATE,PAYMENT.DATE & PROPERTY.ID variable.
*
* 11/10/13 - Task : 778244
*     Enhancement: 778236
*     Multiple Charge Entries
*     New argument added to AA.CALCULATE.TAX
*
* 26/09/13 - Task : 729076
*            Enhancement : 717657
*            Routine AA.CALC.CHARGE was incorporated as part of AA_Fees componentisation enhancement.
*
* 12/11/13 - Task : 834005
*            Defect : 749012
*            TO Initialise PAYMENT.PROPERTY variable
*
* 06/01/14 - Task : 878787
*            Defect : 877333
*            For Deposits do not check for residual process on last payment date
*
* 06/11/13 - Task : 805820
*             Ref : Enhancement 708838
*             Handling of tax for lending
*
* 26/12/13 - 873061
*            Ref: 801896
*            When disbursement amount defined in schedule is greater than comimtment amount then do not project disbursement
*            schedule beyond that.
*
* 30/01/14 - Defect 895871
*            Task 901636
*            When disbursement amount defined in future schedule it will display in projector
*            enquiry.
*
* 15/02/14 - Task: 916232
*            Defect: 836462 & Ref: PACS00323445
*            System move the loan principal balance amount as positive, when repayment process between issue bill and make due
*            with repayment amount as such that principal amount as bring less than bill principal property amount.
*
* 19/02/14 - Task : 919963
*            Defect : 919955
*            Variable R.PAYMENT.TYPE is wrongly assigned with null in wrong position.
*
* 20/02/14 - Task : 909756
*            Defect : 463107 & Ref: PACS00209988
*            Spill over interest should be made due on payment end date itself, It should not get cycled beyond maturity date.
*
* 27/02/14 - Task : 927364
*            Defect : 836462
*            Coding Reversal for 919963 task
*
* 28/02/14 - Task : 927856
*            Defect : 463107
*            Coding Reversal for 909756
*
* 28/02/14 - Task  928402
*            Defect 896289
*            Initialise variable before usage.
*
* 07/03/14 - Ref 480649
*            Task 741288
*            Enabling local routine returned amount for Interest only
*
* 12/03/14 - Task: 938921
*            Defect: 836462 & Ref: PACS00323445
*            System move the loan principal balance amount as positive, when repayment process between issue bill and make due
*            with repayment amount as such that principal amount as bring less than bill principal property amount.
*
* 14/12/13  - Enhancement : 713743 / Task : 719999
*             Account Analysis - Deferment of PaymentSchedule
*
* 19/03/14 - Task 722434/Enhancement 713833
*            Minimum Payment Changes
*
* 26/03/14 - Task : 854907
*            SI : 713833
*            Calculate Interest from correct Period start date in case bills are generated in advance and settled.
*
* 23/03/14 - Task : 931571
*            Enhancement : 874095
*            Interest Upfront changes
*
* 08/05/14 - Task 990865
*            Defect 976084
*            During settlement of advance bills we have modified to get the period start date to find interest accruals, period start will be the last value of the period Start date,
*            Ex: Before settlement of advance bills the period start and period end dates are 01st Jan and 01 feb, after settling advance bills the period start and end dates are 01 jan and 01 mar.
*            Now we are considering the period start date is 01 Mar to calculate interest
*            But for backdated reversal delete on previous interest, period start date took the wrong date,
*            If i'm doing backdated activity on 10 Feb then my period start date should be an 01 jan, But system blindly taken the last multi value of period end date which is 01 mar it's a future date, so system returning 0 accrual amount which is incorrect.
*            In this case we have future dates also in interest accruals record, so we have to locate the last payment date in period start date, and get the corresponding period start date to calculate a interest.
*
* 12/05/14  - Enhancement : 713751
*             Task : 722474
*             Loan Charge-off. Get details for the required chargeoff type.
*
* 23/07/14 - Defect : 1064199 / Task :1067350
*            CURACCOUNT asset type has positive balance
*
* 01/07/14 - Task : 1043161
*            Defect : 1043104
*            Interest Upfront changes when cooling period is defined Calculated Interest amount is wrong, though new Interest Request Type CURRENT.ACCRUE Introduced to get the accrual interest amount till Cooling Period.
*
* 01/08/14 - Task : 1075170
*            Defect : 1073879
*            Interest with actual amount bill is not raised.
*
* 30/07/14 - Task : 1072762
*            Defect : 1069627
*            Comparing system bill type and not the one defined in Payment Schedule
*
* 07/08/14 - Task : 1080228
*            Defect : 1069627
*            OS.PROP.AMT was not populated in bill details.
*
* 08/08/14 - Task : 1081871
*            Defect : 1069627
*            In enquiry projection, outstanding amount calculated by reducing the calc amount instead of reducing the property amount.
*
* 23/08/14 - Task : 1095295
*            Defect : 1094971
*            Schedule projection does not include the residual interest at the payment end date.
*
* 18/08/14 - Task : 1089037
*            Def  : 1051468 (Ref : 769918)
*            Removal of code duplication done under the task 1067350
*
* 03/05/14 - Enhancement : 1057428 / Task : 1100839
*            Interim Capitalisation for AR
*
* 03/09/14  - Defect : 1092457
*             Task : 1098439
*             System has to raise expected bill based on the actual amount defined in the payment schedule for entire schedule
*
* 09/09/14 - Task: 1109177
*            Defect: 1104681 & Ref: PACS00392079
*            Stop update the AA$CONTRACT.DETAILS when the start date not present in account details and it was called under project purpose.
*
* 12/09/14 - Enhancement:- 1110147
*            Task:- 1110153
*            Loan next due date - escrow enhancement
*            For advance payment, Schedule projection should also include the past bill payment and the future schedule payment amount.
*
* 10/10/14 - Task : 1135947
*            Defect : 1135506
*            Initialisation of Uninitialised variables.
*
* 21/10/14 - Task : 1144143
*            Def  : 1141836
*            System should not throw the schedule amount exceeds related overrides in a deposit arrangement when a expected account scheduled.
*
* 21/11/14 - Task : 1176118
*            Def  : 1164970
*            During accounts capitalize with multiple payment types on same day, system capitalize interest amount was not match with accrued interest for the second processed capitalize interest property
*
* 27/11/14 - Task : 1193887
*            Ref : 1182470
*            Enable settlement of Linear + Interest when the bill is in Issued status
*            Though belonging to different payment types, any change in Interest should
*            be adjusted to principal as we do for annuity.
*
* 19/12/14 : Task : 1204467
*            Ref : 1204167
*            Exclude Tax amount from CALC.AMOUNT obtained from a bill if TAX.INCLUSIVE is set to NO
*
* 24/02/15 - Task : 1264663
*            Defect : 1258892
*            Charge amount appearing only for the next one cycle in the schedule after princial becomes zero.
*
* 25/03/15 - Task : 1295461
*            Def  : 1273905
*            System should get the calc amount by getting the repayment amount from the respective payment type properties when the bills are settled in advance.
*
* 28/03/15 - Task : 1299142
*            Defect : 1299141
*            Override message raised wrongly while processing the actual amount.
*
* 27/03/15 - Enhancement : 1114260 / Task : 1114266
*            New parameter SOURCE.BALANCE is initialised and added to the
*            AA.CALC.CHARGE routine.
*
* 27/03/15 - Task : 1250791
*            Enhancement : 1115547
*            Introduced new calculation type ACCELERATED.
*
* 11/05/15 - Task: 1341513
*            Defect: 1331405 & Ref: PACS00449031
*            System exclude the cooling period accrual amount while processing the upfront interest collection.
*
* 11/05/15 - Task : 1342161
*            Defect : 1342139
*            For -ve interest system not raising the PAY bill.
*
* 15/06/15 - Enhancement - 1277976
*            Task - 1300622
*            For fixed type of interest, update AA$FIXED.INTEREST<4> with the processed dates of interest amounts.
*            So that on final date, it is easy to fetch past profit amounts.
*
* 13/05/15 - Task 1300704
*            Enhancement 1277985
*            Islamic Enhancement - step-up and step-down processing
*
* 17/08/15 - Task 1440283
*            Enhancement 1277976
*            The common variable should be set even during advance payment hence check for SCHEDULE.INFO<17>.
*
* 09/09/15 - Task : 1447056
*            Enhancement : 1434821
*            Pass Customer details to calculate Tax routine for Split tax calculation.
*
* 30/10/15 - Task 1507913
*            Enhancement 1427498
*            No need to pass payment type to get the last payment date for the interest property
*
* 22/02/16 - Task : 1649927
*            Enhancement : 1033356
*            Added a new argument (CHARGE.ADJUST.INFO) in AA.BUILD.PAYMENT.SCHEDULE.SCHEDULES routine.
*
* 04/03/16 - Task: 1652449
*            Defect: 1569654 & Ref: PACS00482270
*            Contract details and present value variable was updated at the end based on the payment date
*            once after entire payment type properties get processed on date.
*
* 11/03/16 - Task: 1660109
*            Defect: 1569654 & Ref: PACS00482270
*            Regression failure fix.
*
* 13/05/15 - Task   : 1373568
*            Defect : 1336108
*            System should process the negative interest of Lending and Deposit as PAY/DUE payment method respectively.
*
* 12/04/16 - Task : 1694882
*            Def  : 1678192
*            Debit Charge property amount added with principal in schedule projection instead of deducting from principal.
*
* 12/04/16 - Task : 1695927
*            Defect : 1197270
*            Payment schedule charge is not calculated correctly when the charge is setup to be calculated based on Min CR. balance
*
* 25/05/16 - 1730438
*            Ref: 1649704
*            For credit property with negative rate tax should not be calculated and for the rest of the combinations tax should be
*            calculated. If there is negative rate then interest amount will be stored with a negative sign in interest accruals
*            and hence interest returned to this routine will be a signed balance. AA.CALCULATE.TAX already has logic to not calculate
*            tax if base amount is less than zero, so pass the amount with the sign to calculate tax routine but for futher processing
*            in this routine make interest amount as positive.
*
* 07/06/16 - Task   : 1729412
*            Defect : 1692808
*            Arrangement value date to be considered as period start date in interest
*            calculation for restroed arrangement, if last repayment date is less than value date of arrangement.
*
* 17/08/16 - Task: 1826027
*            Defect: 1820531 & Ref: PACS00532631
*            System project the entire outstanding amount as last period payment amount even
*            though actual amount was defined in payment schedule.
*
* 22/09/16 - Task : 1867776, 1875520
*            Def  : 1864731
*            For a back dated non-funded deposit contract, interest amount should be projected from arrangement date.
*
* 23/10/16 - Task : 1901305
*            Defect : 1891715
*            If payment end date is null then take the Renewal date as payment end date for Roll over deposit contracts. Other wise current period accrued interest
*            will be carryforward to all future periods as Residual Interest amount.  Interest adjustment amount will not become zero.
*
* 07/11/16 - Task : 1903362
*            SI  : 1773815
*            For Proportional TAX calculation we pass PERIOD.START.DATE, PERIOD.END.DATE  R.ACCRUAL.DATA
*            calculated from AA.Interest.CalcInterest  into AA.Tax.CalculateTax argument Additional.Info<3> & Additional.Info<4>
*
* 25/01/17 - Task : 1984435 / Defect : 1980542
*            Do the rounding based on MIN.ROUND.AMOUNT of CURRENCY record.
*
* 13/02/17 - Task : 2019568
*            Defect :  1814394
*            DEV-Coding- TAX.INCLUSIVE should be effective only to Lending Product Line
*
* 16/03/17 - Task : 2052762
*            Defect 1991823
*            While calculating interest amount for ADVANCE payment type, system should consider effective date as period start date.
*
* 10/04/17 - Task : 2082214
*            Defect 2079818
*            System updates ADVANCE property position only with payment type position and compare this position with subsequent payment dates processing while leads to mismatch
*            and hence no interest accruals calculated.
*
*
* 2/05/17 -  Task : 2108237
*            Def  : 2088551
*            In case an Actual.AMT is given in the payment schedule, then skip residual process on the last payment date only if
*            that date is also the renewal date of the arr.
*
* 23/05/17 - Task : 2132555
*            Enhancement : 2132552
*            Recalculate Maturity and then Payment & Activity ProcessingRecalculate Maturity and then Payment & Activity Processing
*
* 21/06/17 - Task : 2168556
*            Defect : 2154397
*            Introduce new position SCHEDULE.INFO<24> , if this position have the value then don't initialise the AA$CONTRACT.DETAILS common in AA.BUILD.PAYMENT.SCHEDULE.SCHEDULES routine.
*
* 04/07/17 - Task : 2180265
*            Enhancement : 2132552
*            Scope change:Recalculate Maturity and then Payment & Activity Processing
*
* 03/07/17 - Task : 2172273
*            Enhancement : 2068057
*            For calculating tax separately for negative and positive interest pass the total positive and negative accrued amount
*            into ARRANGEMENT.INFO so that it can be used in AA.CALCULATE.TAX
*
* 29/08/17 - Defect : 2248962
*            Task : 2252219
*            CMB-476 - Flexible Repayment
*
* 06/09/17 -Task :  2299307
*            Def  : 2237237
*            Raise an override when repayment amount exceeds outstanding principal
*
* 19/10/17 - Task : 2311551
*            Def  : 2265996
*            interest amount capitalised for negative principal amount is added to the principal without changing to negative sign,
*            and shows wrong principal amount in enquiry AA.INTEREST.DETS.
*
* 02/11/17 - Enhancement : 1948428
*            Task        : 2316509
*            To get last payment date with respect to the effective date, set a flag for ADJUST.DUE/ADJUST.CAP activity.
*
* 01/02/18 - Defect : 2420966
*            Task : 2444209
*            Correct holiday amount to be calculated when multiple payment types are defined
*
* 09/02/18 - Task : 2455869
*            Defect: 2455305
*            Fix for currency not picked up when tax is included.
*
* 02/05/18 - Task : 2571216
*            Enhancement : 2571213
*            Determine whether MIC required for the property
*            Take Minimum amount when calculated amount is greater the GroupMinAmount for the property
*
* 08/06/18 - Task : 2627572
*            Enhancement  : 2627569
*            Flexible Repayment Holiday Excess Payment Activity
*
* 16/05/18 - Task : 2592004
*            Defect : 2591119
*            For FER type while doing term calculation calculated interest amount to be deducted from the actual amount like constant, not only deduct principal amount.
*
* 23/06/18 - Task : 2646679
*            Def  : 2645973
*            There is some rounding difference while projecting schedule on/after change schedule activity.
*
* 13/6/18 - Task:2634693
*           Def:2616038
*           Base balance of Highest debit charge is wrong
*
* 25/07/18 - Task 2692466
*            Defect 2687573
*            Schedule projection shows incorrect interest amount for INTEREST.ADVANCE payment type.
*
* 05/04/18 - Task         : 2435155
*            Enhancement : 2226661
*            Changes has been done to support the user exit calls through java interface.
*
* 20/08/18 - Task: 2731027
*            Defect: 2715106
*            When pay-account and capitalised-interest falls on same date then the outstanding amount in schedule projection should be calculated accordingly
*
* 30/08/18 - Defect : 2725076
*            Task : 2746515
*            Check holiday payment for all the payment types. Else system will retain amount from previous loop.
*
* 16/01/2019 - Enhancement: 2822515
*              Task :  2860311
*              Componentisation changes.
*
* 21/02/19 - Defect : 2984696
*            Task : 3001568
*            Period start date is got from the interest accruas if the last payment date is null.
*
* 24/04/19 - Task : 3100342
*            Defect : 3079166
*            Rule 78 interest is not projected as expected.
*
* 29/05/19 - Task   : 3137542
*            Defect : 3122874
*            Period start date for advance type bill has been assigned from last payment date.
*
*
* 05/25/19 - Defect - 3135350
*            Task   - 3146412
*            Projection of interest after redeem within the cooling period should be zero
*
*
* 10/06/19 - Task : 3172297
*            Defect : 3111462
*            When Date convention set as "FORWARD or FORWARD SAME MONTH" with date adjustment as "VALUE",
*            then system considers already made due bill amount for interest calculation during projection
*            which falls in subsequent holiday but before next working day.
*
* 24/8/19 - Task : 3302898
*           Defect : 3299034
*           Duplicate Bills getting generated for same date.
*
*
* 30/07/19 - Task : 3189513
*            Enhancement : 3189510
*            New constant CdIncludePrinAmounts in  AA$CONTRACT.DETAILS introduced and considered for interest amount calculation based on disbursement amount.
*
* 05/09/19 - Enhancement : 3189510
*            Task : 3318710
*            Resetting the Payment.Percentage pointer to calculate percentage amount and calc amount correctly
*
* 17/9/19- Task  : 3340830
*          Defect: 3326147
*          System should consider the capitalised amount when loan amount not disbursed
*
* 10/10/19 - Enhancement  : 3282228
*            Task : 3282231
*            Changes have been done to calculate due amount for the Downpayment Payment type scheduled in payment schedule.
*
* 24/10/19 - Task :  3403723
*            Def  : 3395011
*            System bill type should be fetched where we are getting PAY.BILL.TYPE from schedule record
*            PAY.BILL.TYPE to be considered only for DISBURSEMENT, EXPECTED and PAYMENT types
*
* 28/10/19 - Task : 3407388
*            Defect : 3395088
*            Period balances for forward dated entries should be returned for the schedule projection.
*
* 14/12/19  - Task  : 3488934
*             Defect : 3476987
*             When payment method defined for the interest property was mismatched with its source type, change the payment method to respective value.
*
* 10/01/20 - Task        : 3462726
*            Enhancement : 3462723
*            ScheduleInfo<22> position is changed to ScheduleInfo<24> to restrict the initialisation of CONTRACT.DETAILS.
*
* 11/12/19 - Enhancement: 3250633
*            Task: 3250636
*            Full chargeoff charge calculation
*
* 27/02/20 - Enhancement : 3582773
*            Task : 3582776
*            Existing logic moved to a new routine called AA.PROJECT.PAYMENT.SCHEDULE.SCHEDULES to handle Participants PS
*
*
* 23/03/20 - Task   :3704226
*            Defect :3546775
*            After performing the respite payment, The final schedule has a huge upfront interest amount
*            when we compare the final interest amount to the previous schedule upfront interest amount.
*
* 24/04/20 - Enhancement : 3635319
*            Task : 3674244
*            Properties amount not updated from Tot and Cur termAmount balances for Participants during Auto-Disbursement
*
* 25/04/20 - Enhancement : 3635319
*            Task : 3713110
*            Tot and Cur termAmount balances not modified when Participants not defined
*
* 25/04/20 - Enhancement : 3635319
*            Task : 3716219
*            Calculate Disbursement amount using PaymentAmountList returned from Dated routine for Borrower during Auto-Disbursement.
*
* 22/04/20 - Enhancement : 3709570
*            Task : 3709573
*            Fetch positive and negative interest amounts to be updated on bills
*
* 27/04/20 - Enhancement : 3529690
*            Task : 3634841
*            to invoke GET.PARTICIPANT.CHARGE.AMOUNT for Charge Calculation
*
* 24/05/20 - Task   : 3762776
*            Defect : 3758613
*            When update payment holiday is triggered for interest only payment skipped due is not added to subsequent due.
*
* 11/05/20 - Enhancement : 3696943
*            Task : 3696946
*            Update payment properties of participants along with skim if defined.
*
* 19/5/20 - Task        :3786278
*           Enhancement :3714424
*           Multi schedule disbursement-Schedule logic
*
* 09/06/20 - Task        :3751424
*           Enhancement  :3649880
*           Capitalisation of profit-Schedule logic
*
* 10/6/20 - Task  :3798711
*           Defect:3792170
*           When we have future dated disbursement defined and then we do a adhoc FT the recalculation of payment amounts is incorrect

* 17/06/20 - Enhancement : 3696963
*            Task : 3696960
*            Update participant amounts along with skim property amounts if skim properties are defined
*
* 18/06/20 - Task : 3814460
*            Enhancement : 3649880
*            Changes done to reset the variables since the amount is being updated to the principal
*
* 22/06/20 - Defect:3792170
*            Task:3807000
*            When we have future dated disbursement defined and then we do a adhoc FT the recalculation ...
*
* 25/06/20 - Task : 3820664
*            Def  : 3808964
*            For fixed interest, during term recalculation process, to arrive at the correct end date(new term) we need to ensure that
*            the projected profit amount with the existing conditions dose not exceed the current RECPROFIT amount.
*
* 10/07/20 - Enhancement : 3806722
*            Task : 3811484
*            Projected accrual details are split for participants.
*
* 23/07/20 - Defect : 3763511
*            Task   : 3872450
*            During Change Term activity, calc amout is incorrect
*
* 23/07/20 - Defect : 3769424
*            Task   : 3873083
*            Interest amount displayed wrongly in schedule projection for the holiday schedule when bill is in
*            Finalise status for that holiday schedule date.
*            Regression Fix - System has to carry forward the skipped holiday interest amount
*
* 31/07/20 - Task        : 3877778
*            Defect      : 3873384
*            Enhancement : 3653394
*            While calculating interest for the period where holiday has been defined, then split the period and do accruals to avoid mismatch in the accrual amount.
*
* 26/07/20 - Task   : 3877877
*            Defect : 3857612
*            Incorrect interest projected for call contracts as current period accruals are not reset for subsequent periods
*
* 17/08/20 - Task        : 3911275
*            Enhancement : 3890273
*            ArrangementScheduleProjector Routine will set  SCHEDULE.INFO<35> to indicate to call CalcCharge Rotuine with dummy
*            arrangement id to get charge amounts from charge condition cached.
*
* 10/09/20 - Task : 3960475
*            Enhancement : 3911272
*            ArrangementScheduleProjector Routine will set  SCHEDULE.INFO<38> to indicate to call CalcCharge Rotuine with dummy
*            arrangement id to get charge amounts from charge condition cached.
*
* 06/10/20 - Enhancement : 3984627
*            Task : 4007500
*            SKIM is appended to the accrual property when skim flag is true for getRProjectedAccrualCommon
*
* 02/11/2020 - Task   :3827665
*             Defect :3793395
*             System should return the negative amount when calcualted interest amount is in negative during payoff capitalise
*
* 04/11/20 - Task : 3997320
*            Enhancement : 3646036
*            Last payment is set as period start date for subsequent cycle however, during respite last payment date should set to respite end date.
*            Donot add previous period adjustment amounts to current period if within respite period.
*
* 05/11/20 - Task : 4064542
*            Defect : 3982308
*            Outstanding amount is not updated correctly after the update payment holiday when
*            arrangement is having Constant payment type and bill in Issued status.
*            Though there is no Principal amount exists for Issue bill date, Outstanding amount is displayed by considering the Holiday
*            Amount which is sufficient for Interest amount alone.
*
* 05/11/20 - Enhancement : 4051905
*            Task        : 4060815
*            For new offer arrangement, fetch the outstanding amount for both borrower and participants
*
* 14/08/20 - Task : 4120730
*            Def  : 4113424
*            PAY.BILL.TYPE to be considered only for DISBURSEMENT, EXPECTED and PAYMENT types
*            System bill type should be fetched where we are getting PAY.BILL.TYPE from schedule record
*
*
* 15/12/20 - Defect : 4133553
*            Task   : 4133648
*            Update capitalised amount for borrower and participant separately.
*
* 16/12/20 - Enhancement  : 4061948
*            Task         : 4127231
*            Wrong APRC/TAEG value calculated when the disbursement is scheduled.
* 07/12/20 - Enhancement : 4007847
*            Task : 4007850
*            When called for BANK Subtype, Borrower,participants and BOOK should be processed for CUST type.
*            Additionaly build PaymentSchedule for BOOK-BANK type.
*
* 23/11/20- Task        : 4062905
*           Enhancement : 3685096
*           System should display the Residual amount in the last principal
*
* 22/12/20- Task        : 4145381
*           Enhancement : 4062919
*           Unblocker - System should display the Residual amount in the last principal
*
* 17/12/20 - Enhancement : 4140521
*            Task : 4140524
*            Send FWD flag in GetPeriodBalances if Forward Accounting is enabled in TermAmount
*
* 05/02/21 - Defect : 4169999
*            Task   : 4198408
*            Changes to consider the future dated condition's payment types for schedule projection.
*
* 22/02/2021 - Defect : 4227146
*              Task : 4238677
*              ChargeOff Bnk Amount updated for CHARGE property during Partial chargeoff
*
* 08/03/2021 - Defect : 4272328
*              Task : 4266492
*              Incorrect period balance returned for Participants during AutoDisbursement when IncludePrinAmounts is set.
*
* 09/03/21 - Enhancement : 4219096
*            Task        : 4268217
*            Performance Improvement changes
*
* 31/03/21 - Enhancement : 4203362
*            Task : 4315798
*            Get Participant Record from ScheduleInfo<44>
*
* 28/04/21 - Enhancement : 4339835
*            Task        : 4339864
*            Allow advance payment for Periodic Charges bill
*
* 15/07/21 - Defect  : 4455284
*            Task    : 4477398
*            Passing user inputted interest amount to AA.CALC.INTEREST routine
*
* 01/09/21 - Defect  : 4548177
*            Task    : 4549195
*            Check if interest projection is needed when the outstanding balances zero and the Actual amount is defined for interest payment type
*
* 05/09/21 - Defect : 4552624
*            Task : 4557340
*            new field called ONLY.NON.CUSTOMER introduced in schedules enquiry to include only NON.CUSTOMER bills and future projection
*
* 17/09/21 - Defect  : 4548177
*            Task    : 4571720
*            Perform Actual Amount check for Interest property only when arrangement is disbursed.
*
* 27/10/21 - Enhancement : 4282133
*            Task : 4629680
*            Don't calculate the Interest accruals if the Arrangement is not disbursed for Rule 78 Contract during Issue Bill and Make Due activities.
*
* 28/10/21 - Defect :4623456
*            Task :4631573
*            TSR-144093 Var BALANCE.NAME , Line 82 , Source AA.PROPERTY.GET.BALANCE.NAME.b
*
* 09/10/19 - Task : 4620137
*            Defect : 3373097
*            Scheduled charge which has the advance as the property type should not calculate the charge.
*
* 09/11/21 - Enhancement : 4173708
*            Task : 4645951
*            New Arguments added for Risk Participants processing
*
* 25/11/21 - Task   : 4647348
*            Defect : 4607700
*            Dont update the account balance for EXPECTED bills on maturity date
*
* 08/12/21 - Task   : 4690060
*            Enhancement : 4173708
*            Regression Fix: Read Book accrual record for non Customer interest in club loans
*
* 09/12/21 - Task   : 4690558
*            Defect : 4670776
*            System is generating bill for charge without considering the actual amount defined in payment schedule condition.
*
* 30/12/21 - Enhancement - 4674956
*            Task - 4709950
*            Act charges bills raised for risk participants when no borrower bill is defined
*
* 18/12/21 - Enhancement : 4674954
*            Task : 4744220
*            Interim interest capitalisation of Risk margin properties
*
* 20/05/21 - Defect: 4302392
*            Task: 4355272
*            Get Charge amounts from GetParticipantChargeAmount using Participant condition for enquiry processing
*
* 31/01/22 -  Defect : 4766192
*             Task   : 4759212
*             Incorrect bill update - After chargeoff with risk participants.
*
* 30/09/21 - Defect: 3604641
*            Task  : 4590014
*            If base date type of the arrangement is "START" and the period start date for interest calculation
*            is lesser than the arrangement start date then system should pass arrangement start date as period start date.
*
* 09/12/21 - Task :  4691575
*            Defect: 4090723
*            Even though we have scheduled record as null for future dated scheduled date, we should update the
*            Principal and interest amount in the ScheduleProjection.
*
* 29/12/21 - Task   : 4722472
*            Defect : 2170174
*            If advanced bill exists then reduce the repayment amount against bill installment amount so that projection will happend for the
*            remaining payment amount.
*
* 02/02/22 - Task   : 4722472
*            Defect : 2963570
*            When multiple Advance partial repayment to advance bill, system is increasing advance payment amount on projection.
*
* 03/02/22 - Task:4764044
*            Defect:4756466
*            System updates EB.CASHFLOW with the Actual amount
*
* 25/02/2022 - Defect : 4672134
*              Task :   4793443
*              DEV : Coding : OB - Performance Fix-AA_PaymentSchedule
*
*
* 15/02/22 - Task   : 4781933
*            Defect : 4773265
*            System should not include transaction inputted during cob for issuing bill
*
* 14/03/22 - Task : 4814783
*            Defect : 4343647
*            Assign postive and negative property amount for advance payment method
*
* 29/03/22 - Defect: 4822890
*            Task: 4824492
*            During Guarantees processing, set forward accounting flag to fetch corresponding charges
*
* 21/03/22 - Task   : 4830256
*            Defect : 4796984
*            System should consider amount posted during  COB during capitalisation
*
* 1/04/2022 - Defect : 4793599
*              Task :   4846963
*              Actual amount for disbursement payment type should preceed the term amount definition.
*
* 06/04/2022 -  Defect : 4670609
*               Task   : 4852831
*               Fix for Incorrect outstanding amount in projection for club loans.
*
* 24/05/22 - Task   : 4919772
*            Defect : 4863302
*            Request Payment Holidays for specific Schedule date with NEW PAYMENT AMOUNT and RECALCULATE Term does not impact the schedule
*
* 21/03/22 - Task   : 4921647
*            Defect : 4796984
*            System should consider amount posted during  COB during capitalisation
*
* 15/06/22 -  Defect: 4942297
*            Task: 4947514
*            Final Amount is getting adjusted for Account because Payment End Date was taking as Renewal date.So take payment end date from account details while setting flag ADJUST.FINAL.AMOUNT
*
* 26/06/22 - Defect : 4939574
*            Task   : 4959972
*            Difference in captured interest and total amount in schedule projection
*
* 03/08/22 - Defect    : 4975034
*             Task     : 5003154
*             AVL Balance has to be considered for calc amount calculation when disbursement is scheduled but settlement is off.
*
* 12/08/22 - Defect : 5011250
*            Task : 5011740
*            Uninitialised variable warnings in Dev TAFC runs - Corporate Lending routines
*
* 26/10/22 - Task        : CORP-3713
*            Defect      : CORP-4338
*            Period Start&End updates for participants when multiple Interest is made due on same date
*
* 04/11/22 - Task        : CORP-4508
*            Defect      : CORP-4338
*            Update Period Start and End date for Participant skim properties
*
* 13/10/22 -  Task : RET-6972
*             Defect : RET-5979
*             Avoid / Reduce READ on AA.PRD.CAT.DATED.XREF during AA.SERVICE.PROCESS
*
* 01/12/22 - Task : RET-11399
*            Enhancement : RET-6584
*            Skip tax calculation and return previous payment types and dates if the SCHEDULE.INFO<55> flag is set
*
* 06/12/22 - Enhancement : CORP-1395
*            Task : CORP-3751
*            Offline Participant processing changes
*
** 18/11/22 - Defect    : RET-9549
*            Task      : RET-10759
*            Updates contract details to store the amount to be maintained for further schedules when payment method is maintain.
*
* 07/12/22 -  Defect   : RET-8884
*             Task     : RET-10638
*             When we have multiple payment schedules PAYMENT.MODES should update from latest payment schedule.
*
* 29/11/22 - Enhancement : BB-141
*            Task: BB-440
*            During Asset Finance processing, set BaseProperty to TermAmount property
*
* 01/12/2022 - Enhancement : CORP-1364
*              Task        : CORP-5066
*              Calculate payment amounts and property amount based on curcommitment for facility when account schedule is defined.
*
*
* 14/12/22 - Task : RET-11699
*            Enhancement : RET-6584
*            Skip tax calculation if the SCHEDULE.INFO<55> flag is set
*
* 09/12/22 - Enhancement : RET-9606
*            Task : RET-12179
*            Avoid Call to Payment schedule date in Update cashflow by reusing the dates
*
* 06/12/22 - Enhancement : CORP-1303
*            Task        : CORP-5850
*            Code changes for Portfolios processing
*
* 20/12/22 - Task        : CORP-5738
*            Enhancement : CORP-1365
*            FLR - Facility Level repayment schedule - Commitment reduction
*
* 04/01/23 - Task   : CORP-6300
*            Defect : CORP-6410
*            Get the Participants amount from getParticipantcommitmentbalances API
*
* 08/12/22 - Defect : RET-6025
*            Task : RET-12377
*            Calc amount wrongly calculated for HOLIDAY.INTEREST when end dated defined of format D_20100122
*
* 26/12/22 - Enhancement : BB-142
*            Task        : BB-649
*            Balance name with suffix should be addedn if the flag is to set
*
* 04/01/23 -  Task : RET-14714
*             Defect  : RET-9606
*             Avoid Read in EB.GET.ACCT.ACTIVITY file from GetPeriodBalances routine for Cashflow
*
* 10/01/23 -  Task : RET-15328
*             Defect  : RET-9616
*             Avoid  read in AA.GET.BALANCE.CALC.BASIS repeatedly for penalty interest property for cashflow
*
* 15/12/22 - Defect    : RET-12073
*            Task      : RET-12977
*            Update contract details to store the amount to be maintained for further schedules when balance is increasing for maintain.
*
* 01/02/23 - Defect  : RET-13776
*            Task    : RET-16561
*            Profit Amount projected wrongly after Instalment deferment process
*
* 16/02/23 - Enhancement : CORP-1305
*            Task : CORP-6963
*            Portfolios Repayment processing changes
*
* 02/03/23 - Enhancement : RET-9615
*            Task : RET-17477
*            Set the common variable cache data if the call is from repayment calculator enquiry.
*
*28/02/23 -  Defect   : RET-17801
*            Task     : RET-19171
*            Issued Bill is not settled while repaying multiple delinquent and overdue bills
*
* 20/01/23 -  Task    : RET-15911
*             Defect  : RET-15337
*             During Projection When REQD.END.DATE is Greater than Payment End Date,Include Residual Amount on last schedule
*
* 14/02/23 -  Defect      : CORP-3100
*             Task        : CORP-8165
*             Calculate cap charge amt for participants when outstanding is 0 and account schedule is defined with charge captalisation
*
* 27/02/23 - Defect : CORP-1305
*            Task   : CORP-8675
*            FLR - Fix for Issue in commitment schedule enquiry - incorrect final schedule amount

* 16/03/23 - Enhancement : CORP-1318
*            Task - CORP-9298
*            Skim processing with portfolios
*
* 17/03/23 - Task        : RET-18923
*            Enhancement : RET-16308
*            Performance Fix - Invoke GetBill and ChargeOffDetails if ArrangementId is valid and skip BuildPaymentScheduleRecord call when schedule record is available in SCHEDULE.INFO<59>
*            Skip GetPropertyDetailsPaySchedule and DetermineMinimumInvoiceComponent if the values are already available in the newly introduced variable
*
* 22/11/22 - Task : RET-21428
*            Defect : RET-9730
*            Effective date has to be appended in the array to update in the contract details for AVLACCOUNT.
*
* 06/04/23 - Enhancement : CORP-9305
*            Task        : CORP-10290
*            Enable Tax for Bank Role Participant
*            Tax for Sub Participant is calculated and stored in Own Book.
*
* 27/03/23 - Enhancement : BB-1219
*            Task        : BB-1494
*            Update the payment schedule projection for Multiple fixed typr Interest for Asset Finance product line
*
* 03/04/23 - Task : CORP-1332
*            Enhancement : CORP-10161
*            Changing Field from Skim.portfolio to Primary.Portfolio
*
*
* 04/05/23 - Task  : RET-22832
*            Defect: RET-21126
*            To restrict bill generations for Advance type of interest when there is no change to the schedules
*
* 27/04/23 - Task   : RET-24220
*            Defect : RET-22421
*            Eb cashflow and the projection are not in sync after crossing holiday date (202008 : RET-20237)
*            During simulation consider today date as current system date for FORWARD.RECALCULATE activity (202008 : RET-21153)
*            Consider adjustment interest of "CAPTURE.BALANCE" activity only for prior schedules of current processing schedule (202008 : RET-22990)
*            Consider CURR.INT.AMT with ADJSUTMENT.AMOUNT during FORWARD.RECALCULATE activity (202008 : RET-23129)
*
* 04/05/23 - Enhancement : BB-1222
*            Task        : BB-1527
*            Processing changes for Downpayment bill for Asset Finance product line.
*
* 08/05/23  - Enhancement : CORP-9837
*             Task : CORP-11103
*             Portfolio Tax Posting Code Changes
*
* 12/05/23 - Task : CORP-1334
*            Enhancement : CORP-11740
*            Portfolio Chargeoff processing
*
* 15/05/23 - Task : CORP-9832
*            Enhancement : CORP-11823
*            Reg-fix if portfolio defined, then take the portfolio cust amount
*
* 17/05/23 - Task   : RET-25896
*            Defect : RET-19312
*            During simulation consider today date as current system date for FORWARD.RECALCULATE activity
*
* 18/05/23 - Enhancement   : CORP-9832
*            Task : CORP-11902
*            If valid participants exists, Initalise Participants related variables
*
* 22/05/23 - Defect : RET-24945
*            Task   : RET-26247
*            Changes done to update allt the properties in the advance bill once the partial advance repayment it done over the issued bill.
*
* 08/06/23 - Enhancement : BB-1482
*            Task        : BB-1610
*            Raise the tax amount in bill for whole total amount instead of particular property in case of transaction tax processing
*
* 08/06/23 - Enhancement : BB-1482
*            Task        : BB-1981
*            Regression fix for not raising tax for interest or charge properties in bill
*
* 21/06/23 - Enhancement : BB-1482
*            Task        : BB-1611
*            Tax schedule projection for the transaction taxes
*
* 23/06/2023 -Task            : RET-29400
*             Enhancement     : RET-22738
*             Regression fix.
*
* 03/07/23 - Enhancement : CORP-9834
*            Task: CORP-13107
*            Non Customer - RiskParticipant processing for risk participants linked to portfolios
*
* 07/07/23 - Enhancement : BB-1484
*            Task        : BB-2057
*            Regression fix - Add transaction details in the respective position
* 13/07/23 - Enhancement : BB-1863
*            Task        : BB-2209
*            For Asset Finance Operating Lease contract, Residual amount should be shown in outstanding at end of contract
*
* 20/07/23 - Enhancement : RET-29182
*            Task        : RET-31081
*            Pass projection flag to refer current account inf balances when participation is set for sub participant property
*
* 13/07/23  - Enhancement : CORP-9954
*             Task        : CORP-14026
*             Enable Reporting PC for Club Loans, Pass Own Bank in Valid Participant if SCHEDULE.INFO<28> & SCHEDULE.INFO<42> is set
*
* 20/07/23 - Defect : BB-2314
*            Task: BB-2318
*            Negate the sign value for takeover of asset finance contracts in order to update the outstanding amounts correctly
*
* 21/07/23 -  Enhancement : BB-1863
*            Task : BB-2365
*            Remove operating lease check to address regression issues done with task BB-2209
*
* 27/07/23 - Enhancement : BB-1863
*            Task        : BB-2470
*            For Asset Finance Operating Lease contract, Residual amount should be shown in outstanding at end of contract
*
* 08/08/23 - Enhancement : RET-29182
*            Task        : RET-33949
*            Get share transfer date if balance treatment was not set during arrangement creation
*
* 09/08/23  - Enhancement : CORP-14565
*             Task        : CORP-15001
*             Enable Reporting PC for Club Loans, Pass Own Bank in Valid Participant if SCHEDULE.INFO<28>, SCHEDULE.INFO<42> is set and SCHEDULE.INFO<62> is not set
*             If SCHEDULE.INFO<28>,SCHEDULE.INFO<42> and SCHEDULE.INFO<62> is set Pass All Participant in Valid Participant.
*
* 25/08/23 -  Enhancement : BB-2679
*             Task        : BB-2755
*             Outstanding amount must be updated with residual amount in case of Finance lease as Return
*
* 22/06/23 - Defect : RET-23463
*            Task   : RET-29178
*            Bills are not settled properly and still in issued status when there is a bill amount along with delinquent bills and payment schedule is incorrect.
*
* 08/09/23 - Enhancement   : CORP-15491
*            Task          : CORP-15950
*            Capitalisation of accrued interest portion during user capitalise activity.
*
* 23/08/23 - Defect : RET-32737
*            Task   : RET-34571
*            Set due.and.cap flag if .schedules routine is called from AA.PAYMENT.SCHEDULE.ITERATE routine
*
* 12/10/23 - Enhancement : BB-3064
*            Task        : BB-3535
*            For Pricng Grid product system to fetch the calculated charges when call is from enquiry also
*
* 30/10/23 - Task   : RET-36740
*            Defect : RET-35248
*            If only Residual amount defined in payment schedule, then pass the PRESENT.VALUE as RESIDUAL.AMOUNT
*            and PROCESS.RESIDUAL flag is not set to null.
*
* 18/10/23 - Defect : RET-32738
*            Task   : RET-41277
*            Build the schedule projection correctly during payment holday activity when holiday restriction is defined for 'Account' property
*
* 11/11/23 - Task : RET-41176
*            Defect : RET-31615
*            If it is a sepcial processing and not advance payment Reset the calc.amount for other payment type properties in the advance bill once the partial advance repayment is done over the issued bill.
*
* 09/11/23 - Enhancement : BB-3767
*            Task        : BB-4000
*            Holiday Interest Inf balance update for Operating lease contracts
*
* 14/11/23 -  Enhancement : BB-1863
*             Task        : BB-3099
*             For operating lease contracts, when payment end date and effective date are equal, interest amount should be subtracted from actual amount
*
* 30/11/23 -  Task   :  RET-43655
*             Defect :  RET-41457
*             Schedule projection is wrong after repaying more than the due bill amount when we have issued and due bills
*
* 17/01/24 -  Task        :  CORP-19482
*             Enhancement :  CORP-19016
*             Fix for incorrect commitment taken for prorata calculation when commitment fully utilised before conversion.
*
* 02/02/24 - Task        : RET-48336
*            Defect      : RET-47947
*            we need to adjust Penalty Interest amount to Account similar to MAkedue Activity during projection also.
*
* 18/02/24 - Defect : RET-48827
*            Task   : RET-51549
*            Code change to Build contDtls with includeprinamounts only if disbursement is scheduled in payment schedule.
*
* 05/03/24 - Task :RET-51400
*            Defect:RET-50060
*            For IncludePrinAmounts set to "YES", When we have future dated disbursement defined and then we do a adhoc FT the recalculation of payment amounts is incorrect
*
* 05/03/2024 - Defect : RET-48115
*              Task   : RET-51390
*              Schedule falls on the same future disbursement date.
*
* 12/03/24 - Task        : CORP-20909
*            Enhancement : CORP-20746
*            Fix for issue with residual amount update for participants.
*
* 19/03/24 - Defect : RET-44311
*            Task   : RET-52369
*            System should avoid to adding the ADJUSTMENT.AMOUNT into the INTEREST.AMOUNT.
*            When PAYMENT.DATE EQ PAYMENT.END.DATE and it have fixed interest.
*
* 11/03/24 - Defect : RET-48217
*            Task   : RET-51729
*            Performance fix to avoid unnessary reads on ACCT.BALANCE.ACTIVITY
*
* 21/03/24 - Defect - BB-5444
*            Task - BB-5467
*            During capture balance for asset finance get the balance from term amount record
*
* 21/03/24 - Task :RET-52909
*            Defect:RET-50060
*            For IncludePrinAmounts set to "YES", When we have future dated disbursement defined and then we do a adhoc FT the recalculation of payment amounts is incorrect
*
* 08/03/24 - Defect  : RET-46393
*            Task    : BB-5761
*            when "Forward" as date convention and "value" as date adjustment and schedule falling on holiday - Always set forward date(next working date) as effective date for cashflow handoff
*
* 10/04/24 - Defect  : RET-54144
*            Task    : RET-47819
*            During Interest advance payment type, its Pos and neg value is getting misplaced with its payment prop amount.
*
* 30/04/24 - Defect  : BB-5575
*            Task    : BB-6118
*            When operating lease contract created with few charges defined, there is a schedule mismatch between AA projections and EB.CASHFLOW.
*
*
* 17/05/24 - Defect : RET-56826
*            Task   : RET-57352
*            when Cashflow ,don't add the adjustment amount with past profit amount for final period. Hence, CONTRACT.ID<28> - new position enabled to Pass the update EB.CASHFLOW flag.
*
* 08/05/24 - Defect : RET-52827
*            Task   : RET-57289
*            Debit Type of Interest is Calculated in the place of Credit Interest when the interest is capitalised using an UNCACCOUNT source balance, which has a positive balance.
*
* 30/05/24 - Defect : RET-58653
*            Task   : RET-59808
*            Payment holiday-System posts more amount than available HOL balance
*
* 04/06/24 - Defect : CORP-21735
*            Task   : CORP-23488
*            Fix for Issue in commitment schedule projection with upfront profit - incorrect final schedule amount
*
* 06/06/24 - Defect : BB-6536
*            Task   : BB-6663
*            To enable Rule 78 payment Calculation based on calc type and calc routine instead of Payment Type ID
*
* 29/05/24 - Defect : RET-57816
*            Task   : RET-59730
*            Interest amount not calculated for backdated contract with single authoriser version.
*
* 21/06/24 - Enhancement : RET-54370
*            Task        : RET-60648
*            Transaction tax processing extended for LENDING/ACCOUNTS/DEPOSITS along with ASSET.FINANCE .
*
* 25/06/24 - Defect : BB-6684
*            Task   : BB-6824
*            Residual value to be available only under new cashflow types
*
* 03/07/24 - Task : RET-63259
*            Enhancement : RET-58941
*            Return Transaction Tax Details based on defined PaymentTypes in Transaction Activity of Transaction Property
*            Introduced Tax for Account property
*
* 19/07/24 - Task : RET-64485
*            Enhancement : RET-58941
*            For "ACCOUNT" property class invoke AA.CALCULATE.TAX only if it is defined in Tax property condition
*
* 24/07/24 - Task : RET-64923
*            Enhancement : RET-58943
*            Removal of Tax calculation for Account property class
*
* 11/07/24 - Defect : RET-62652
*            Task   : RET-63438
*            Incorrect principal in bill after advance repayment.
*
* 30/07/24 - Task : RET-64966
*            Enhancement : RET-58941
*            Changes to calculate payment property amount based on passed TAX.CALC.METHOD in AAA.
*
* 06/08/24 - Task : RET-66144
*            Enhancement : RET-58943
*            Removal of Tax calculation for Account property class
*
* 11/08/24 - Task : RET-65850
*            Enhancement : RET-58943
*            Tax for Account property class
*
* 30/07/24 - Enhancement : RET-58943
*            Task        : RET-65144
*            For ISSUEBILL and MAKEDUE activity with DUE type ACCOUNT property with GROSS TAX.CALC.METHOD being passed, skip tax calculation.
*
* 08/08/24 - Defect : RET-66175
*            Task: RET-66293
*            If we don't have the CALC.AMOUNT,Then system should assign the PRESENT.VALUE to RESIDUAL.AMOUNT.
*
* 20/08/24 - Defect : RET-58242
*            Task   : RET-67084
*            System should add TAX amount during Make due for the pay type bill.
*
* 27/08/23 - Task    : RET-67833
*            Defect  : RET-44141
*            Fixed interest amount has to be set in common for each period processed during split holiday interest calculation
*
* 13/09/24 - Enhancement : RET-67912
*            Task        : RET-69291
*            GROSS ACCOUNT PAY type of tax calcualtion should add the tax amount to the account property even if the tax is a transaction tax.
*
* 11/09/2024 - Enhancement : CORP-25089
*              Task        : CORP-25394
*              Code Fix for Auto Disbursement without Disbursement Percent and with Participant Offline Setup
*
* 22/08/24 - Defect : RET-57693
*            Task   : RET-60431
*            System will process with payment schedule record of Forward Recalcualte activity
*            when FORWARD.RECALC.DATE is present and lessthan START DATE which is in the triggered activity's payment scheuled record.
*
* 22/08/24 - Task        : RET-67694
*            Defect      : RET-38790
*            For special processing, bill outstanding amount should not be moved to negative
*
* 17/09/24 - Defect : BB-5893
*            Task   : BB-7991
*            When multiple residual amount were defined incase of extend term, pick the correct residual amount for the future schedules
*
* 01/10/24 - Task        : CORP-26259
*            Defect      : CORP-21511
*            Tax details are wrongly calculated and updated in EB.CASHFLOW
*
* 08/10/24 - Task   : BB-8016
*            Enhancement : BB-8069
*            For restructured contracts, the past accrued amounts prior to the restructure date should not be included in the FixedInterest common.
*
* 10/10/2024 - Defect : RET-70454
*              Task   : RET-71841
*              After advance repayment towards principal amount, schedule changed principal repayment despite user has defined fixed principal repayment.
*
* 16/10/24 - Defect : RET-71282 / Task : RET-72307
*            Payment.holiday profit calculation issue
*
* 06/11/24- Task   : RET-74819
*           Defect : RET-49780
*           For the loans with INTEREST.ONLY payments, the schedule projection doesnt have the principal amount
*           for the future dated schedules
*
* 19/11/2024 - Enhancement : RET-74245
*              Task   : RET-74827
*              Payment Holiday Dev - Changes to get correct property values for the payment date after PH when PH defined with Holiday property amounts.
*
*
* 28/11/24- Task   : RET-75982
*           Defect : RET-74222
*           Reduce the payment.property.amount from HOLIDAY.DEF.AMOUNT even when forward recalculate falls on
*           a date which is already made due if the date is made as holiday
*
* 22/11/24 - Task   : RET-75346
*            Defect : RET-73156
*            The residual interest is not projected on the final payment date for payment types with the "OTHER" calculation type
*
* 27/11/2024 - Enhancement : RET-75393 \ Task : RET-75904
*              Payment type Holiday account processing is added to handle round off values and variables changed for the same.
*
* 05/12/24 - Enhancement : RET-76450 \ Task : RET-76301
*            During RR do not check HOLIDAY.ACCOUNT property for residual process.
*            Do not consider bill amount for processing defer.all holiday calc.amount.
*            Forward PS record required to check for holiday deferred amount from account details to round off remaining balances.
*
* 05/12/24 - Enhancement : RET-76450 \ Task : RET-77366
*            Do not process TMP.EFF.AMT for past schedules during forward.recalculate activity
*
* 24/12/24 - Defect : RETAIL-1929
*            Task   : RETAIL-2293
*            CHECK.CLOSURE.ACTIVITY flag introduced to avoid calling DetermineClosureActivity for all periods.
*
* 17/12/24 - Enhancement : RET-76590 \ Task : RET-77440 \ RET-77490
*            Tax to be calulated for holiday amount if defined during issue.bill.
*            Do not process TMP.EFF.AMT for past schedules during forward.recalculate activity for defer.all
*            Skip holiday amount in AA.PROJECT.PAYMENT.SCHEDULE.SCHEDULES routine for DeferAll when it is called from iterate routine.
*
* 10/12/2024 - Defect : RET-75487
*              Task   : RET-76837
*              While processing interest system should allow to call the calculateinterest even if outstanding becomes zero.
*
* 01/01/2025 - US   : RET-77691
*              Task : RET-78389
*              Account details update wrong after Update PH and interest accruals ECB mismatch error.
*
* 03/01/25 - US   : RET-77691
*            Task : RET-78625
*            Needs to update latest amount in schedule projection based on rate change happens in between issue.bill and make.due activity
*
* 06/01/25 - US   : RET-77691
*            Task : RET-79045
*            Add Payment amount in AA.PROJECT.PAYMENT.SCHEDULE.SCHEDULES routine for DeferAll when it is called from iterate routine. If any backdated or forwarded interest or schedule change occurs between the Update Payment holiday and FORWARD.RECALCULATE activity
*
* 15/01/25 - US   : RET-77692
*            Task : RET-79357
*            Handle tax inclusive calculation for payment holiday based on holiday amount or holiday property amount. Calc amount to be subtracted with tax calculated on original interest amount.
*            For holiday calculation, reduce the holiday amount. Reduce holiday amount with calculated interest amount even when holiday property amount is given as it maybe be given as null for the other property like account
*
* 21/01/25 - US   : RET-77692
*            Task : RET-79616
*            Projection and account details and AA.ARR.PS are updated wrongly while triggering PH with Finalize and bill produced setup for MTP recalculation
*
* 23/01/25 - Defect : BB-6671
*            Task   : BB-8965
*            Pass the payment type individually each time when calling the calculate tax to ensure accurate transaction tax calculations.
*
* 23/01/25 - Defect : BB-6671
*            Task   : BB-9057
*            Refer the current payment type instead of reffering from payment schedule record for transaction tax calculation, as disbursment payment type will not be processed
*
* 07/02/25 -  Defect  : RET-79523
*             Task    : RET-80079
*             Amount projected in payment schedule for an interest property for which SUPPRESS.ACCRUAL has been set to INFO.ONLY is incorrect and changes on daily basiS.
*
* 11/02/25 - Defect : RET-79777
*            Task   : RET-81397
*            EB.CASHFLOW is corrupted for holiday cases when account date concention is forward/value.
*
* 25/02/25 - US   : RETAIL-4591
*            Task : RETAIL-4844
*            Accounting Entries Changes for Charge property class During make-due on holiday and post payment holiday period
*
* 27/02/25 - Enhancement : RETAIL-3988
*            Task        : RETAIL-4335
*            Update the fixedInterest common with the latest int amount when tax inclusive is set and the amount exceeds the actual calc amount.
*
*
* 21/02/25 - Defect : BB-7498
*            Task   : BB-9087
*            For Interest only payment with Residual value system is displaying the incorrect cashflow value for the last schedule.
*
* 18/03/25 - Enhancement : RETAIL-4738
*            Task        : RETAIL-5780
*            Tax inclusive calc amount reduction for charge when holiday is defined
*
* 24/03/25 - Enhancement : RETAIL-5950
*            Task        : RETAIL-5951
*            Pass payment date to calculate transaction tax when it is called for projection
*
* 28/03/25 - Defect  : RETAIL-6454
*            Task    : RETAIL-6114
*            Adjustment amount to be fecthed only for current interest period.
*
* 23/04/25 - Defect : RET-84039
*            Task   : RET-84905
*            Incorrect Interest amount observed in the schedule projection after 2nd payment holiday.
*
* 26/02/25 - Task        : CORPORATE-3810
*            Enhancement : CORPORATE-3284
*            When More than one portfolio is present then process the other portfolios tax amount and add it with the primary portfolio tax amount in case of participant bankrole
*
* 11/04/2025 - Defect : RET-82925
*              Task   : RET-84602
*              For INFO bill type,system should add the account property amount in residual amount.
*
* 09/05/25 - Task        : CORPORATE-5252
*            Enhancement : CORPORATE-3326
*            Fix to raise tax bill for book or portfolio when sub participants shares are zero for participant bank role
*
* 15/05/2025 - Enhancement : RETAIL-5855
*              Task        : RETAIL-7374
*              SCHEDULE.INFO<74> is now used during LENDING prepayment scenario with partial payoff condition. We should not process the final schedule logic in accrue interest like a normal payoff scenario.
*
* 22/05/2025 - Enhancement : RETAIL-5869
*              Task        : RETAIL-7584
*              For Lending products with Upfront tax, do not calculate the tax by considering the rate in tax application. Instead, take the upfront tax rate from the interest accruals and calculate the tax amount.
*
* 31/05/2025 - Enhancement : RETAIL-7383
*              Task        : RETAIL-7797
*              For Disbursement, Expected BillTypes tax should be calculated only if Funding.Tax set in Tax.Condition
*
* 30/05/25 - Task : RETAIL-7652
*            Enhancement : RET-7383
*            Handling ALLOW.TRANSACTION.TAX
*
* 23/05/2025 - Enhancement : RETAIL-7609
*              Task        : RETAIL-7610
*              Restrict the projection of transaction type charges as that will be calculated only during bill
*              issue process similar to periodic charges
*              Processing changes for scheduled transactional charge.
*
* 12/06/25 - Enhancement : RETAIL-7859
*            Task        : RETAIL-7827
*            Apply date convention for payment start date if it falls on holiday
*
* 17/06/2025 - Enhancement : RETAIL-7625
*              Task        : RETAIL-7626
*              Last payment date +1C only when the previous activity is on EOD.
*
* 16/06/25 - Defect : ENTERPRISE-17876
*            Task  : ENTERPRISE-18070
*            Changes done to calculate charge per unit of the activity for Enterprise products.
*
* 01/07/2025 - Enhancement : RETAIL-5331
*              Task        : RETAIL-7856
*              Code changes to update Cache date when UpdateScheduleConcat is set in parameter
*
* 07/07/25 - Defect : RET-86208
*            Task :   RET-88121
*            The bill repaid amount should not be considered for the subsequent schedules.
*
* 15/04/25 - Defect : RET-84603
*            Task   : RET-84699
*            During Delete-Rev of applypayment consider the balance from Activity balances which was update during reversal
*
* 11/07/25 - Task   : RET-84845
*            Defect : RET-84334
*            fix for Schedule Projector Utility
*
* 04/07/2025 - Defect : RET-87770
*              Task   : RET-87944
*              AA-ACT.AMT.GT.CUR.OUTSTAND.AMOUNT override should not be raised for the INFO bill type.
*
*11/07/25 -  Task   : RET-88296
*            Defect : RET-86604
*            For the loans with INTEREST.ONLY payments, the schedule projection doesnt have the principal amount
*            for the future dated schedules
*
* 24/06/25 - Task   : RET-88236
*            Defect : RET-83711
*            Performance fix to avoid call from the CORE routines AA.GET.BILL.TYPE, AA.GET.BILL during make due process
*
* 17/07/25 - Task   : CCCRT-1448
*            Enhancement : CCCRT-430
*            Changes made to support non prorate calculation when FLR transaction is processed
*
*17/07/25 -  Task   : CORP-30180
*            Defect : CORP-30075
*            Regression Fix - System is not updating the LI.CASHFLOW for fwd dated drawing
*
* 17/07/25 - Task   : CCCRT-3351
*            Enhancement : CCCRT-3154
*            Changes made to the existing formula to support non prorate calculation when FLR transaction is processed
*
* 07/08/2025 - Task   : RET-87122
*              Defect : RET-84170
*              System should project the payment schedule correctly after the 2nd update payment holiday.
*
* 11/07/25 - Defect : RET-83158
*            Task   : RET-93337
*            Performance fix to avoid unnessary reads on ACCT.BALANCE.ACTIVITY during MakeDue activity
*
* 17/11/25 - Task   : RET-93630
*            Defect : RET-49948
*            Schedule projection is wrong after repaying more than the due bill amount when we have issued and due bills
*
* 22/11/25 - Defect : RET-92920
*            Task   : RET-93876
*            Restore calcamount for each participant,so that calc amount will not be less than interest amount
*
* 27/11/2025 - Enhancement : CCCRT-6751
*              Task        : CCCRT-6752
*              Restructuring the upfront tax code.
*
* 05/12/25 - Enhancement : CCCRT-4085
*            Task        : CCCRT-7636
*            When the payment type is Interest-Only and the payment method is Capitalise for an asset finance arrangement contract,
*            The interest amount is deducted from the outstanding amount instead of being added.
*
* 08/12/2025 - Enhancement : CCCRT-7395
*              Task        : CCCRT-7667
*              Performance fix for upfront tax
*
* 30/10/25 - Task   : RET-92718
*            Defect : RET-90668
*            Principal decrease on discounted loan refunds full interest amount to customer
*
* 05/01/26  - Defect  : RET-93504
*             Task    : RET-95239
*             When there is already a linear payment schedule for previous month and when user trigger another linear payment type for same account property as future dated system should consider amount which is shceduled
*
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Inserts>
*** <desc>File inserts and common variables used in the sub-routine</desc>

    $USING AC.Fees
    $USING AC.BalanceUpdates
    $USING AA.PaymentSchedule
    $USING AA.TermAmount
    $USING AA.Interest
    $USING AA.ProductFramework
    $USING AA.Tax
    $USING EB.API
    $USING AA.Fees
    $USING AA.Framework
    $USING EB.SystemTables
    $USING AF.Framework
    $USING AA.ChargeOff
    $USING AA.Participant
    $USING AA.Customer
    $USING EB.ErrorProcessing
    $USING EB.Service
    $USING AA.MarketingCatalogue
    $USING AA.ShareTransfer
    $USING AA.Account
    $USING EB.Utility
    $USING ST.Config
    $USING AA.ActivityCharges

*** </region>
*-----------------------------------------------------------------------------

*** <region name= Main control>
*** <desc>main control logic in the sub-routine</desc>

    GOSUB INITIALISE
    
    GOSUB GET.PAYMENT.SCHEDULE          ;* Load payment schedule record

    IF NOT(ERROR.FLAG) THEN
        GOSUB BUILD.BASIC.DATA
    END

    IF NOT(ERROR.FLAG) THEN
      
        GOSUB BUILD.PAYMENT.DATES       ;* Get the full dates
        GOSUB GET.OUTSTANDING.AMOUNT    ;* Get current outstanding amount
        GOSUB PROCESS.PARTICIPANTS      ;* Get Participant details
        GOSUB BUILD.FORWARD.SCHEDULES   ;* Calculate payment amounts for each property
        GOSUB SET.CACHE.DETAILS
    END
    
RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Initialise>
*** <desc>File variables and local variables</desc>
INITIALISE:

** It is possible to pass in payment dates, payment types, payment amounts
** and payment properties by the calling routine, do not initialise
** those variables
    
    GET.BILL.REQUIRED = SCHEDULE.INFO<7>          ;* Should contain value only called this routine from ITERATE and PROJECTOR
    STORE.SCHD.TYPE = ""
    BILL.DETAILS = ""
    BILL.DETAIL = ""
    BILL.PROPERTY.AMOUNT = ""
    BILL.INTEREST.AMOUNT = ""
    BILL.REPAY.AMOUNT = ""
    OUTSTANDING.AMOUNT = ""
    PAYMENT.PROPERTY = ""
** Initialise return variables
    PAYMENT.PROPERTIES.AMT = ""         ;* Payment amount calculated for each property by payment type and payment date (sub-value)
    TAX.DETAILS = ""          ;* Tax amount calcualted for each property amount (sub-value)
    IF UNASSIGNED(PAYMENT.DATES) THEN
        PAYMENT.DATES = ""
    END
** Reset error flags
    ERROR.FLAG = "" ;* On errors this variable would be set and no further processing is done
    RET.ERROR = ""  ;* Error messages encountered when calling other utiltity routines from this routine
    CHARGE.CALC.INFO = "" ;* Adjusted charge amount and the reason from the Adjustment API to record in AA.CHARGE.DETAILS
    
** Initialise processing details
    
*** When schedule projector called from marketing catalogue for Loan Schedule component calculation, user would set the Outstanding
*** balance details in CONTRACT.DETAILS common. So don't clear if SCHEDULE.INFO<24> set. It will be set only when it calls from MC.

    IF SCHEDULE.INFO<41> THEN
        FWD.ACC.FLAG = SCHEDULE.INFO<41>
        SCHEDULE.INFO<41> = ""
    END
    
    CASHFLOW.LIMIT.CHECK = SCHEDULE.INFO<76> ;*Flag to indicate that the projector routine is called from Cashflow Limit check
    
    IF NOT(SCHEDULE.INFO<24>) THEN
        AA.Framework.setContractDetails("");* Holds balance amounts projected by balance name, payment dates for properties
    END
    
    EFFECTIVE.DATE = AF.Framework.getActivityEffDate()         ;* Current activity effective date
    IF NOT(EFFECTIVE.DATE) THEN
        EFFECTIVE.DATE = EB.SystemTables.getToday() ;*Else take today(processing date)
    END

    DATE.CMP = EFFECTIVE.DATE

    PAYMENT.METHOD = ""

    PROPERTY.ACCRUAL.DATA = ""

    INTEREST.PROPERTIES.RESIDUAL.AMOUNT = ""      ;* Residual interest amounts for each interest period
    BALANCE.AMOUNT = ""

    INTEREST.PROPERTIES = ""
    TAX.DETAILS.LIST = ""
    TAX.LIST = ""
    INTEREST.PROCESSED = ""   ;* Flag to indicate if we have processed interest atleast once - so that ACC can be made-due without any os amount

    PAYMENT.METHODS.NEW = ""  ;* Payment methods

    COND.DATE = ""              ;*From enquiry - project taking conditions till maturity date
    TEMP.PS.PROPERTY.RECORDS = ""       ;*Payment schedule record
    PS.EFFECTIVE.DATES = ""             ;* Effective dates for payment schedule records
    PS.PROPERTY.RECORDS = ""            ;* Property records corresponding to payment schedule records

    MASTER.ACT.CLASS = FIELD(AA.Framework.getAaMasterActivity()<1,4>, AA.Framework.Sep, 2,2) ;* get the master activity class
    ACTIVE.PRODUCT = AA.Framework.getRArrangement()<AA.Framework.Arrangement.ArrActiveProduct>
    IF SCHEDULE.INFO<75> THEN ;* When called from service to update AA.SCHEDULE.DETAILS reinitialise commons.
        AA.Framework.GetArrangement(SCHEDULE.INFO<1>, R.ARRANGEMENT, ARR.ERROR)
        AA.Framework.setRArrangement(R.ARRANGEMENT);* Update common
        AA.Interest.setInterestCacheDetails("")
        AA.PaymentSchedule.ProcessAccountDetails(ARRANGEMENT.ID, "INITIALISE", "", "", "")
    END
** Product commons may updated wrongly in enquiry projection if arrangement product is changed. So reset the common values.
    IF (EB.SystemTables.getApplication() EQ "ENQUIRY.SELECT" AND AF.Framework.getArrProductId() NE ACTIVE.PRODUCT) OR SCHEDULE.INFO<75> THEN
        AA.Framework.setAaPropertyClassList("")
        AA.ProductFramework.GetPublishedRecord("PRODUCT", "", ACTIVE.PRODUCT, "", PRODUCT.RECORD, "")
        AF.Framework.setArrProductId(ACTIVE.PRODUCT)
        AF.Framework.setProductRecord(PRODUCT.RECORD)
    END ELSE
        PRODUCT.RECORD = AF.Framework.getProductRecord()
    END
    AA.ProductFramework.GetPropertyName(PRODUCT.RECORD, "INTEREST", INTEREST.PROPERTIES)  ;* get all the interest properies for the product
    TAX.PROPERTIES = ""
    AA.ProductFramework.GetPropertyName(PRODUCT.RECORD, "TAX", TAX.PROPERTIES)

    CONVERT @FM TO @VM IN INTEREST.PROPERTIES

    LAST.ACCRUAL.DATE = ''
    PROGRESSIVE.PAYMENT  = "" ;*Variable to store the progressive payment amount
    LAST.PAY.DATE = ''        ;* Variable to hold the last progressive type date
    DEF.INT.DETAIL = ''       ;* Variable to hold the residual interest amount for the current period
    PAYMENT.PROPERTY.AMOUNTS = ''       ;* Variable to hold the payment amount for the current payment date
    PAYMENT.PROPERTIES.LIST = ''        ;* Variable to hold the payment properties for the current payment date
    LAST.ACC.DATE = ''        ;* Variable to hold the last accrual date
    RESIDUAL.PROCESS.REQD = ""          ;* Variable used to specify the value if RES alance need to be calculated for the property
    IGNORE.INT.PROP.UPDATE = ""
    PROPERTY.ID = ""
    PAYMENT.DATE = ""
    NO.MORE.DISB.SCH = 0      ;* Flag to indicate if disbursement schedule should be further processed
    REMAIN.DISB.AMT = 0       ;* Maintains the disbursement amount as of previous schedule date
    TOT.DIS.AMT = 0 ;*Maintains the total disbursement amount scheduled.
    ADV.SETTLED.INT.AMT = 0
    CALCULATE.TYPES = SCHEDULE.INFO<17> ;*projection required for the calculated types passed in alone
    PROJECT.END.AMOUNT = SCHEDULE.INFO<18>        ;*Projection should happen till repayment amount crosses this value. This can minimise places where we dont require full projection
    EXTENSION.NAME = SCHEDULE.INFO<19>  ;*Check if any extension (say due to charge off) is passed in
    R.ACCRUAL.DETAILS = ""
    BORROWER.EXTENSION.NAME = EXTENSION.NAME     ;*Store Borrower ExtensionName
    OS.LAST.VALUE= "" ;* Holds the value of the outstanding amount for the final schedule
    
    FULL.CHARGEOFF.STATUS = ""
    
    IF SCHEDULE.INFO<1> NE 'DUMMY' THEN  ;* Invoke GetChargeoffDetails if it is a valid ArrangementId
        GOSUB GET.CHARGEOFF.DETAILS
    END
    
    PARTICIPANT.PRESENT.VALUE = ''
    TEMP.ARRID = ''
    TEMP.BASE.BAL = ''
    TEMP.BAL.EFF = ''
    TEMP.BAL.AMT = ''
    IS.PARTICIPANT = 0
    PART.POS = 1
    SAVE.TOT.TERM.AMT = ''
    SAVE.CUR.TERM.AMT = ''
    SAVE.AVAILABLE.COMMIT.AMT = ''
    PARTICIPATION.TYPE = ''
            
    ACTUAL.CALC.AMOUNT = ""
    CONSTANT.PRIN.AMOUNT = ""
        
    POS.NEG.FLAG = ADJUST.FINAL.AMOUNT<2> ;* indicates whether to fetch pos and neg amounts
    ADJUST.FINAL.AMOUNT = ADJUST.FINAL.AMOUNT<1>
        
    AA.Framework.GetSystemDate(CURRENT.SYS.DATE)     ;*Get current system date
        
**If this flag is set and if DUE.AND.CAP payment types are defined in the payment schedule then the routine will return the details of the capitalised portion Interest/Charge
**along with DUE details when partial/full capitalisation
    RET.PARTIAL.CAP.DETAIL = ""           ;* flag to return the DUE.AND.CAP details.
    IF SCHEDULE.INFO<30> THEN
        RET.PARTIAL.CAP.DETAIL = 1
    END
        
    AA.SIM.REF=  AA.Framework.getAasimref()
    QUOTATION.REF= ''  ;* initialise to null
    IF AA.SIM.REF THEN    ;* Is it for simulated projection
        SIM.ERR.RUN = ''
        R.SIM.RUNNER = AA.Framework.SimulationRunner.Read(AA.SIM.REF, SIM.ERR.RUN)    ;* Read the runner record
        QUOTATION.REF= R.SIM.RUNNER<AA.Framework.SimulationRunner.SimQuotationReference>  ;* get the quotation reference
        
    END
    
    BILL.TYPE.ARRAY = ""
    PAYMENT.TYPE.ARRAY = ""
    SOURCE.BAL.TYPE.ARRAY = ""
    
    CURRENT.ACTIVITY = ""
    
    IF SCHEDULE.INFO<8> ELSE
        CURRENT.ACTIVITY = AF.Framework.getActivityId()<AA.Framework.ActActivity>      ;* Current activity being performed
    END
    IF MASTER.ACT.CLASS EQ "FORWARD.RECALCULATE-PAYMENT.SCHEDULE" THEN
        GOSUB GET.ACTUAL.MASTER.ACTIVITY.CLASS
    END
    ACTIVITY.ACTION = AF.Framework.getCurrAction()    ;* Activity Action
    INITIATION.TYPE = AF.Framework.getC_arractivityrec()<AA.Framework.ArrangementActivity.ArrActInitiationType>      ;* Initiation Type
    INITIATION.TYPE.STAGE = INITIATION.TYPE["*",2,1] ;*Get the EOD/SOD stage
            
    ASF.OPERATING.LEASE = ''
    IF AA.Framework.getRArrangement()<AA.Framework.Arrangement.ArrLeaseType> EQ "OPERATING" THEN
        ASF.OPERATING.LEASE = "1"   ;*Set the flag if the asset finance lease type is operating
    END
                           
    MIC.ARRAY = ''  ;* Intitialise MIC.ARRAY
    PROPERTY.DETAILS = ''   ;*Initialise PROPERTY.DETAILS
             
    FORWARD.RECALCULATE = ''
    IF AA.Framework.getAasimref() AND MASTER.ACT.CLASS EQ "FORWARD.RECALCULATE-PAYMENT.SCHEDULE" OR FIELD(AF.Framework.getCurrActivity(), AF.Framework.Sep, 2) EQ "FORWARD.RECALCULATE" THEN
        FORWARD.RECALCULATE = 1
    END
    
** During simulation consider today date as current system date for FORWARD.RECALCULATE activity
** Else take activity effective date as current system date
    IF FORWARD.RECALCULATE AND (EFFECTIVE.DATE EQ CURRENT.SYS.DATE) THEN
        IF EB.SystemTables.getToday() LE AA.Framework.getAarr_aaamasteractrec()<1,AA.Framework.ArrangementActivity.ArrActEffectiveDate> AND FIELD(AA.Framework.getAarr_aaamasteractrec()<1,AA.Framework.ArrangementActivity.ArrActActivityClass>,AF.Framework.Sep,2) NE "FORWARD.RECALCULATE" THEN ;* if master activity date is greater then today take activity effective date as current system date
            CURRENT.SYS.DATE = AA.Framework.getAarr_aaamasteractrec()<1,AA.Framework.ArrangementActivity.ArrActEffectiveDate>
        END ELSE
            CURRENT.SYS.DATE = EB.SystemTables.getToday()  ;* Consider Today date as CurrentSystemDate
        END
    END
    
    ACTBAL.READ = '' ;* Flag to indicate GetActivityBalances read
   
    IF AA.Framework.getRArrangement()<AA.Framework.Arrangement.ArrProductLine> MATCHES "ACCOUNTS":@VM:"ASSET.FINANCE":@VM:"LENDING":@VM:"DEPOSITS" THEN       ;* If the lease type was set, then add the tax in container and transaction property list
        ARR.ID = SCHEDULE.INFO<1>
        TAX.PROPERTY.COUNT = DCOUNT(TAX.PROPERTIES, @FM)
        FOR TAX.CNT = 1 TO  TAX.PROPERTY.COUNT
            AA.Framework.LoadStaticData('F.AA.PROPERTY', TAX.PROPERTIES<TAX.CNT>, R.TAX.PROPERTY, RET.ERROR)     ;* Load tax records
            IF "CONTAINER" MATCHES R.TAX.PROPERTY<AA.ProductFramework.Property.PropPropertyType> THEN
                CONTAINER.TAX.PROPERTIES<1,-1> = TAX.PROPERTIES<TAX.CNT>         ;* Add the tax into container properties list if container property type is present
                AA.ProductFramework.GetPropertyRecord("", ARR.ID, TAX.PROPERTIES<TAX.CNT>, EFFECTIVE.DATE, "", "", R.TAX.PROPERTY.RECORD, RET.ERROR) ;* Get the term amount record
                IF R.TAX.PROPERTY.RECORD<AA.Tax.Tax.TaxProperty> THEN
                    TRANS.TAX.PROPERTY.LIST<1,-1> = R.TAX.PROPERTY.RECORD<AA.Tax.Tax.TaxProperty>       ;* Add the tax into transaction property list if the transaction property type is present
                END
            END
        NEXT TAX.CNT
    END
    
    CASHFLOW.EFFECTIVE.DATE = "" ;*initialise the cashflow effective date
    
    ENTERPRISE.LEVEL = ""
    AA.ProductFramework.IsProductManagedByEnterpriseLevel("ARRANGEMENT", "", ENTERPRISE.LEVEL, "")  ;* check whether the product is created through TPM
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= PROCESS.PARTICIPANTS>
PROCESS.PARTICIPANTS:
*** <desc> </desc>

** Process only if ParticipantIds returned from Dates routine. Get Participant Property and Get OutStanding amount for each participant separately.
** Update Contract Details also for each participant.

    IF PROCESS.PARTICIPANTS THEN
        
        GOSUB GET.CUSTOMER.NUMBER ;* To get GL customer to get the BOOK balances!!
   
        IS.PARTICIPANT = 1
        PARTICIPANT.TYPE = ''
        TEMP.PARTICIPANT.REC = ''
        SKIM.PORTFOLIO = ''
        
        IF R.PARTICIPANT THEN
            TEMP.PARTICIPANT.REC = R.PARTICIPANT
            PARTICIPANT.TYPE = 'FUNDED.PARTICIPANT'
            GOSUB GET.PARTICIPANT.OUTSTANDING.AMOUNT            ;* populate funded participants Present value details
        END
        IF R.RISK.PARTICIPANT THEN
            TEMP.PARTICIPANT.REC = R.RISK.PARTICIPANT
            PARTICIPANT.TYPE = 'RISK.PARTICIPANT'
            GOSUB GET.PARTICIPANT.OUTSTANDING.AMOUNT             ;* populate risk participants Present value details
        END
                  
        PART.ACCT.MODE = R.PARTICIPANT<AA.Participant.Participant.PrtAcctngType>    ;*Get AccountingMode for Participant
        ACCOUNT.ID = SAVE.ACCOUNT.ID            ;* reassign Account Id
        SAVE.BORROWER.OUT.AMT = PRESENT.VALUE               ;* Store Initial Present value of Borrower to calculate ProRata Outstanding amount for future dates
        SAVE.PART.OUT.AMT= PARTICIPANT.PRESENT.VALUE        ;* Store Initial Present value of Participants to calculate ProRata Outstanding amount for future dates
    END
    
    IF NOT(SCHEDULE.INFO<60>) AND NOT(SCHEDULE.INFO<8>) AND (R.ARRANGEMENT<AA.Framework.Arrangement.ArrBalanceTreatment> EQ "PARTICIPATION") AND DCOUNT(R.ARRANGEMENT<AA.Framework.Arrangement.ArrProduct>,@VM) GT 1 THEN  ;* Make sure its not enquiry projection
        GOSUB GET.SHARE.TRANSFER.DATE   ;* Get share transfer activity date
    END
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= GET.PARTICIPANT.OUTSTANDING.AMOUNT>
GET.PARTICIPANT.OUTSTANDING.AMOUNT:
*** <desc>populate Present value details</desc>
    
    VALID.PARTICIPANTS = TEMP.PARTICIPANT.REC<AA.Participant.Participant.PrtParticipant>       ;* List of vaild participants
    IF SCHEDULE.INFO<28> AND SCHEDULE.INFO<42> AND SCHEDULE.INFO<62> EQ ''  THEN  ;* When CashFlow,Participant Flag is set and Participant Skim Flag is not set, Pass Book details alone in Valid Participant
        VALID.PARTICIPANTS = ''
    END
    IF PARTICIPANT.TYPE NE 'RISK.PARTICIPANT' THEN          ;* BOOK details not needed when processing Risk Participants
        IF TEMP.PARTICIPANT.REC<AA.Participant.Participant.PrtPortfolioId> THEN
            FOR PF.CNT = 1 TO DCOUNT(TEMP.PARTICIPANT.REC<AA.Participant.Participant.PrtPortfolioId>, @VM)
                VALID.PARTICIPANTS<1,-1> = 'BOOK-':TEMP.PARTICIPANT.REC<AA.Participant.Participant.PrtPortfolioId,PF.CNT>
                IF BORROWER.EXTENSION.NAME EQ 'BANK' THEN
                    VALID.PARTICIPANTS<1,-1> = 'BOOK-':TEMP.PARTICIPANT.REC<AA.Participant.Participant.PrtPortfolioId,PF.CNT>:'-BANK'
                END
            NEXT PF.CNT
        END ELSE
            VALID.PARTICIPANTS<1,-1> = 'BOOK'       ;* Without having own commitement balance also please add book for processing!! For Agent only option we requires to raise bill for TAX processing!!
        END
        SKIM.PORTFOLIO = TEMP.PARTICIPANT.REC<AA.Participant.Participant.PrtPrimaryPortfolio>
    END ELSE
        RP.LIST = TEMP.PARTICIPANT.REC<AA.Participant.Participant.PrtParticipant>           ;* Risk participants list
        LINKED.PORTFOLIO.LIST = TEMP.PARTICIPANT.REC<AA.Participant.Participant.PrtLinkedPortfolio> ;* Linked portfolios list
    END
* When SUB.TYPE called with BANK, Borrower and Participants will have no BANK balance and BOOK need to be populated with BANK balance.
* To arrive at BOOK-BANK properties amt and outstanding amounts, borrower should be processed with CUST balances and OWN bank should be processed with 2 options, one with OWN cust another one with OWN bank.
* so append BOOK-BANK to Participants list when called for SubType BANK
    IF BORROWER.EXTENSION.NAME EQ 'BANK' AND PARTICIPANT.TYPE NE 'RISK.PARTICIPANT' THEN
        IF TEMP.PARTICIPANT.REC<AA.Participant.Participant.PrtPortfolioId,1> ELSE
            VALID.PARTICIPANTS<1,-1> = 'BOOK-BANK'
        END
    END
    
    NO.VALID.PARTICIPANTS = DCOUNT(VALID.PARTICIPANTS,@VM)
    PART.ACCT.MODE = TEMP.PARTICIPANT.REC<AA.Participant.Participant.PrtAcctngType>    ;*Get AccountingMode for Participant
    VALID.PARTICIPATION.TYPE = TEMP.PARTICIPANT.REC<AA.Participant.Participant.PrtParticipationType>          ;* Get Participation type for risk participants processing
    PF.CNT = 0
    FOR PART.POS = 1 TO NO.VALID.PARTICIPANTS
        IS.PORTFOLIO = ''
        ACCOUNT.ID = SAVE.ACCOUNT.ID            ;* reassign Account Id
        PARTICIPANT = VALID.PARTICIPANTS<1,PART.POS>
        PARTICIPATION.TYPE = VALID.PARTICIPATION.TYPE<1,PART.POS>
        PART.SUB.TYPE = ''              ;* SubType will be null by default for all participants
        IF FIELD(PARTICIPANT,'-',1) EQ 'BOOK' AND FIELD(PARTICIPANT,'-', 2) AND FIELD(PARTICIPANT,'-', 2) NE 'BANK' THEN
            IS.PORTFOLIO = 1
        END
        IF IS.PORTFOLIO THEN
            PF.CNT += 1
            PART.SUB.TYPE = FIELD(PARTICIPANT,'-',3)            ;* Populate Portfolio Subtype
            PART.ACCT.MODE = "REAL"
            PARTICIPANT = GlCustomer:'*':FIELD(PARTICIPANT,'-', 2)
        END ELSE
            IF PARTICIPANT MATCHES "BOOK":@VM:'BOOK-BANK' THEN
                PART.SUB.TYPE = FIELD(PARTICIPANT,'-',2)            ;* Populate BOOK Subtype
                PART.ACCT.MODE = "REAL"
                PARTICIPANT = GlCustomer
            END
        END
        GOSUB GET.OUTSTANDING.AMOUNT                ;* Populate Outstanding amount for each participant and update the same in ContractDetails
    NEXT PART.POS
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= GET.CUSTOMER.NUMBER>
GET.CUSTOMER.NUMBER:
*** <desc>To get GL customer to get the BOOK balances </desc>

    GlCustomer = ""
    RetError = ""
    AA.Customer.GetArrangementCustomer(ARRANGEMENT.ID, PROPERTY.DATE, '', '', '', GlCustomer, RetError)

RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= Get payment schedule record>
*** <desc>Check if record is passed or be loaded from disk</desc>
GET.PAYMENT.SCHEDULE:
  
** Check if payment schedule is passed into the routine or needs to
** loaded
    ARRANGEMENT.ID = ""       ;* Passed in Schedule Info
    PROPERTY.DATE = ""        ;* Passed in Scehdule Info
    PROPERTY = ""   ;* Multiple properties cannot be defined for Payment Schedule for a product / arrangement
    INTEREST.DATA = ""

    R.PAYMENT.SCHEDULE = ""
    DISBURSE.PROGRESSIVE.UPTO.DATE = ""
    INCLUDE.DISBURSE.SCHEDULE = ""
** Check if the details are already known, if not try and load the required details
    
    IF AA.MarketingCatalogue.getPrdScheduleProjector() AND SCHEDULE.INFO<59> AND SCHEDULE.INFO<1> EQ 'DUMMY' THEN   ;* Get ScheduleRecord from SCHEDULE.INFO<59> if it is passed
        ARRANGEMENT.ID = 'DUMMY'
        PROPERTY.DATE = SCHEDULE.INFO<2>
        PROPERTY = SCHEDULE.INFO<3>
        R.PAYMENT.SCHEDULE = RAISE(RAISE(SCHEDULE.INFO<59>))
    END ELSE
        AA.PaymentSchedule.BuildPaymentScheduleRecord(SCHEDULE.INFO, ARRANGEMENT.ID, PROPERTY.DATE, PROPERTY, R.PAYMENT.SCHEDULE, RET.ERROR)
    END
    
    IF RET.ERROR THEN         ;* Payment schedule is the key information, if not present there is no point in proceeding further
        ERROR.FLAG = "1"
    END

** Get calculation and process types for the payment schedule record
    PROCESS.TYPES = ""        ;* Can be Manual or Calculated
    CALCULATION.TYPES = ""    ;*  Can be Constant, Linear, Actual
    EXTEND.CYCLES = ""        ;* Flag to indicate if the payment type needs to be projected even after maturity
    EXTEND.CYCLE = ""
    AA.PaymentSchedule.GetCalcType(R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsPaymentType>, CALCULATION.TYPES, PROCESS.TYPES, EXTEND.CYCLES)
    GOSUB GET.PAYMENT.MODES
** Get the property class for the properties
    PROPERTIES.CLASS = ""
    PAYMENT.END.DATE = AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdPaymentEndDate>
        
*** In case of Deposit Roll over contract Renewal date would be the Payment End date. So let take next roll over date as PAYMENT.END.DATE if PAYMENT.END.DATE is null.
    
    IF PAYMENT.END.DATE EQ '' THEN
        PAYMENT.END.DATE = AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdRenewalDate>                             ;* It is next roll over date
    END
    
    FINAL.PAYMENT.DATE = PAYMENT.END.DATE
    PROPERTIES = R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsProperty>
    CONVERT @SM TO @VM IN PROPERTIES

    AA.ProductFramework.GetPropertyClass(PROPERTIES, PROPERTIES.CLASS)


** Check for disbursement schedule


    IF SCHEDULE.INFO<8> OR SCHEDULE.INFO<17> THEN   ;* During projection as well as during advance payment, find out the fixed type of interest for the contract if any
        FIXED.INTEREST.PROPERTIES = INTEREST.PROPERTIES
        GOSUB GET.FIXED.INTEREST.DETAILS
    END

** Logic for intialising the <4> position of getFixedInterest is moved under GOSUB GET.FIXED.INTEREST.DETAILS

    DISBURSE.PROGRESSIVE.UPTO.DATE = SCHEDULE.INFO<25>
    IF R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsIncludePrinAmounts> EQ "PROGRESSIVE" AND NOT(DISBURSE.PROGRESSIVE.UPTO.DATE) THEN  ;* If IncludePrinAmounts field is set to PROGRESSIVE in PS, then set the CdIncludePrinAmounts to PROGRESSIVE in ContractDetails
        DISBURSE.PROGRESSIVE.UPTO.DATE = "99991231"
    END
    IF DISBURSE.PROGRESSIVE.UPTO.DATE NE '' THEN
        INCLUDE.DISBURSE.SCHEDULE = 1
    END

    IF R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsIncludePrinAmounts> MATCHES "YES":@VM:"PROGRESSIVE" THEN  ;* If IncludePrinAmounts field is set in PS, then set the CdIncludePrinAmounts to YES in ContractDetails
        GOSUB SET.CONTRACT.DETS ;***To build contDtls with includeprinamounts
        AA.Framework.setContractDetails(ContDtls)
    END

RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= SET.CONTRACT.DETS>
****<desc>Build contract details when include prin amounts is set<desc>
SET.CONTRACT.DETS:
    
***Loop through the bill types of payment schedule and see if any disbursed is scheduled
***Set the CdIncludePrinAmounts to YES in ContractDetails only if IncludePrinAmounts field is set in PS and disbursement is scheduled.
    BILL.TYPE.CNT = DCOUNT(R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsBillType>, @VM)
    FOR BILL.CNT = 1 TO BILL.TYPE.CNT
        LOCATE R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsBillType, BILL.CNT> IN BILL.TYPE.ARRAY<1,1> SETTING SCHED.BILL.TYPE.POS THEN
            ORG.SYS.BILL.TYPE = BILL.TYPE.ARRAY<2, SCHED.BILL.TYPE.POS>
        END ELSE
            AA.PaymentSchedule.GetSysBillType(R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsBillType, BILL.CNT>, ORG.SYS.BILL.TYPE, "")   ;* check for system bill type
            BILL.TYPE.ARRAY<1,-1> = R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsBillType, BILL.CNT>
            BILL.TYPE.ARRAY<2,-1> = ORG.SYS.BILL.TYPE
        END
    
        IF ORG.SYS.BILL.TYPE EQ "DISBURSEMENT" THEN
            ContDtls = AA.Framework.getContractDetails()
            ContDtls<AA.Framework.CdIncludePrinAmounts> = R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsIncludePrinAmounts>
            AA.Framework.setContractDetails(ContDtls)
            BILL.CNT = BILL.TYPE.CNT
        END
    NEXT BILL.CNT

RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= Get Payment Modes>
GET.PAYMENT.MODES:
    
** Get Payment Modes from PAYMENT.TYPE Records for all Payment types
    PAYMENT.MODES = ""
    AA.PaymentSchedule.GetAdvancePaymentType(R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsPaymentType>, PAYMENT.MODES)

RETURN
*** </region>
*---------------------------------------------------------------------------------
*** <region name= Get Fixed Interest details>
*** <desc>Get Fixed interest details</desc>
GET.FIXED.INTEREST.DETAILS:

    FIXED.INT.FOUND = '0'
    LOOP
        REMOVE INT.PROPERTY FROM FIXED.INTEREST.PROPERTIES SETTING INT.POS
    WHILE INT.PROPERTY AND NOT(FIXED.INT.FOUND)
        GOSUB GET.INTEREST.ACCRUALS.RECORD
    REPEAT

RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= Get Interest Property record>
*** <desc>Get interest property record</desc>
GET.INTEREST.ACCRUALS.RECORD:

* During projection, assign the common variable AA$FIXED.INTEREST as this has been reused in AA.ACCRUE.INTEREST for final accrual purpose

    INT.PAYMENT.PROPERTY = INT.PROPERTY
    LOCATE INT.PAYMENT.PROPERTY IN INTEREST.DATA<1,1> SETTING PropPos ELSE
        GOSUB GET.ACCRUALS.RECORD
    END
    IF R.ACCRUAL.DETAILS<AA.Interest.InterestAccrualsWork.IntAccFinalSchedule> THEN
***Multiple interest properties are applicable only for Asset Finance product line
***Hence only for Asset Finance product line we need to loop in order to get the correct fixed interest
        IF NOT(AA.Framework.getRArrangement()<AA.Framework.Arrangement.ArrLeaseType>) THEN
            FIXED.INT.FOUND = '1'
        END
        
        tmp.INT = AA.Framework.getFixedInterest()
        tmp.INT<1,-1> = INT.PAYMENT.PROPERTY
        tmp.INT<4,-1> = '' ;*Initialise the 4th position of common variable AA$FIXED.INTEREST, since it will hold the past profit amounts.
        AA.Framework.setFixedInterest(tmp.INT)
    END

RETURN

*** </region>
*-----------------------------------------------------------------------------

*** <region name= Build basic data>
*** <desc>Build basic data</desc>
BUILD.BASIC.DATA:

    GOSUB LOAD.ARRANGEMENT.RECORD       ;** Load arrangement key details - product line, currency, value date

    RECORD.START.DATE = ARR.START.DATE

    GOSUB SET.PRODUCT.TYPE    ;** Handles, Loans, Deposits, Savings {Asset/Liabilities} sign

    tmp.AA$ACCOUNT.DETAILS = AA.Framework.getAccountDetails()
    IF ARRANGEMENT.ID AND NOT(tmp.AA$ACCOUNT.DETAILS) THEN
        AA.PaymentSchedule.ProcessAccountDetails(ARRANGEMENT.ID, "INITIALISE", "", "", "")         ;* Loads AA$ACCOUNT.DETAILS
    END

    IF NOT(AA.Framework.getLinkedAccount()) OR  SCHEDULE.INFO<75> THEN      ;* Possibly from outside Arrangement framework, enquiry?
        LOCATE "ACCOUNT" IN AA.Framework.getRArrangement()<AA.Framework.Arrangement.ArrLinkedAppl,1> SETTING POS THEN
            AA.Framework.setLinkedAccount(AA.Framework.getRArrangement()<AA.Framework.Arrangement.ArrLinkedApplId,POS>);* Assign the common to get account id
        END
    END

    ACCOUNT.ID = AA.Framework.getLinkedAccount()      ;* Just to make sure the common variable is not lost
    SAVE.ACCOUNT.ID = ACCOUNT.ID

    REPAY.OPTION = tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolRepayOption>
    CONVERT @VM TO "" IN REPAY.OPTION


RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name=LOAD.ARRANGEMENT.RECORD>
*** <desc>Loan arrangement record</desc>
LOAD.ARRANGEMENT.RECORD:

    R.ARRANGEMENT = ""
    IF AA.Framework.getRArrangement() THEN  ;* Already loaded, use it
        R.ARRANGEMENT = AA.Framework.getRArrangement()
    END ELSE
        AA.Framework.GetArrangement(ARRANGEMENT.ID, R.ARRANGEMENT, ARR.ERROR)       ;* Load Arrangement record
        IF ARR.ERROR THEN
            RET.ERROR = "AA.PS.MISSING.ARRANGEMENT.REC"
            ERROR.FLAG = 1
        END ELSE
            AA.Framework.setRArrangement(R.ARRANGEMENT);* Update common
        END
    END

    ARR.CCY = R.ARRANGEMENT<AA.Framework.Arrangement.ArrCurrency>      ;* Arrangement currency, used for rounding and charge calculations
    
    IF NOT(ARR.CCY) THEN ;* if not defined, then try to find out it is caused by non-financial arrangement
        STAGE = AA.Framework.AaArrangement
        FINANCIAL.TYPE = ''
    
        AA.ProductFramework.GetFinancialType(STAGE, '', FINANCIAL.TYPE)
        IF FINANCIAL.TYPE EQ 'NONFINANCIAL' THEN ;* if it is non-financial arrangement, then apply the local currency
            ARR.CCY = EB.SystemTables.getLccy() ;* fetch the local currency
        END
    END
    
    ARR.START.DATE = R.ARRANGEMENT<AA.Framework.Arrangement.ArrStartDate>       ;* Date from when all calculations are required
    PRODUCT.LINE   = R.ARRANGEMENT<AA.Framework.Arrangement.ArrProductLine>     ;* Type of Arrangement, asset or liability

    IF FWD.ACC.FLAG THEN
        tmp=AA.Framework.getContractDetails(); tmp<AA.Framework.CdFwdActg>=FWD.ACC.FLAG; AA.Framework.setContractDetails(tmp) ;* Set Forward Accounting flag
    END
    
    
RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Product Line conditions>
*** <desc>Set characteristics for different product lines</desc>
SET.PRODUCT.TYPE:

** Set the following based on the product type
** 1. Sign
** 2. Whether projection is required until maturity date (end date) or based on outstanding balance
** 3.

    OUTSTANDING.AMOUNT.REQD = ""        ;* Don't bother amount present value project until end of maturity (Default setting)
    TERM.AMOUNT.REQD = 1      ;* Flag to indicate if TermAmount is required for calculating outstanding amount
    DUE.AMOUNT.SIGN = 1       ;* Flag to indicate if due amount increase present value or decreases present value
    INCLUDE.PAY.END.DATE = "" ;* Flag to indicate whether to include payment end date or not for capitalisation
    SIGN = 1        ;* Flag to indicate

    BEGIN CASE
        CASE PRODUCT.LINE = "LENDING"       ;* Asset (Loans)
            SIGN = -1
            OUTSTANDING.AMOUNT.REQD = "1"   ;* Based on outstanding balance
        CASE PRODUCT.LINE  = "DEPOSITS"     ;* Liability (Deposits, Savings Plan, Current Account, Savings Account, etc)
            DUE.AMOUNT.SIGN = -1  ;* Expected due should add to outstanding principal
            OUTSTANDING.AMOUNT.REQD = ""    ;* Based on the funding balance, or can be commitment type deposits
            INCLUDE.PAY.END.DATE = "1"      ;* Do capitalise on payment end date
        CASE PRODUCT.LINE = "SAVINGS"
            DUE.AMOUNT.SIGN = -1
            ADJUST.FINAL.AMOUNT = ""        ;* Do not adjust final principal based on present value
            TERM.AMOUNT.REQD = "" ;* Term Amount amount does not mean anything for Savings plans
            INCLUDE.PAY.END.DATE = "1"      ;* Do capitalise on payment end date
*** While doing capture balance activity for asset finance to calculate real balances we will not have any account balaces , take that account balances from Term amount property record
        CASE PRODUCT.LINE EQ 'ASSET.FINANCE' AND (FIELD(MASTER.ACT.CLASS,AA.Framework.Sep,1) EQ 'TAKEOVER' OR AA.Interest.getCalculateLiveBalance())
            SIGN = -1                     ;* negate the sign for an asset finance takeover contract
            ASSET.FINANCE.TAKEOVER = 1    ;* enabled to indicate that Term amount should be considered as the outstanding  amount
    END CASE

RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Outstanding amount>
*** <desc>Get current outstanding princpal amount</desc>
GET.OUTSTANDING.AMOUNT:

** Get the current oustanding loan amount. Payment amounts will be calculated
** on the notional principal (commitment amount) until the first disbursement.
** If the loan is disbursed payment amounts would be calculated on the disbursed
** amounts
    PROCESS.DATE = EFFECTIVE.DATE
    GOSUB GET.UPDATE.FIELD.NO       ;* Populate ContractDetails field positions
    GOSUB LOAD.CONTRACT.DETAILS     ;* Get updated Values from ContractDetails common

    GOSUB GET.TERM.ACCOUNT.PROPERTIES   ;* Account and Term Amount property names - either balance needs to be taken as outstanding amount

    GOSUB GET.ACCOUNT.PROPERTY.RECORD   ;*Load the account property record and store them for subsequent use during projection
    ARRANGEMENT.INFO = ""
    ARRANGEMENT.INFO<1> = LOWER(R.ACCOUNT)

    GOSUB GET.CUSTOMER.PROPERTY.RECORD    ;* Get the customer property record it would need during Tax calculation
    ARRANGEMENT.INFO<2> = LOWER(R.CUSTOMER)

    BALANCE.TO.CHECK = ""
    LIFECYCLE.STATUS = "CUR"

    IF AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdStartDate> OR AA.Framework.getContractDetails()<AA.Framework.CdIncludePrinAmounts> MATCHES "YES":@VM:"PROGRESSIVE" THEN  ;* Disbursement/Deposit receipt processed
        BALANCE.PROPERTY = ACCOUNT.PROPERTY       ;* Account balance to be used when IncludePrinAmounts is set.
    END ELSE
        GOSUB CHECK.BASE.BALANCE        ;* Check if Term amount balance needs to be taken for projection purposes!
    END

    GOSUB GET.BALANCE.TO.CHECK
    
* When Balance to check is Account property and current processing is for a risk participant,
* contract details need not be updated for RP participant
    RISK.ACCOUNT.PROCESS = ''
    IF PROCESS.PARTICIPANTS AND IS.PARTICIPANT AND PARTICIPATION.TYPE AND BALANCE.PROPERTY<1,1> EQ ACCOUNT.PROPERTY THEN
        RISK.ACCOUNT.PROCESS = 1
    END
    GOSUB STORE.BALANCE.TO.CHECK

    IF PROCESS.PARTICIPANTS AND BORROWER.EXTENSION.NAME EQ 'BANK' THEN          ;* Reset EXTENSION.NAME when called for BANK Subtype
        GOSUB CHECK.EXTENSION.NAME          ;*Check Extension name for each participants and borrower
    END

    BEGIN CASE
        CASE OUTSTANDING.AMOUNT       ;* Use the passed outstanding amount
            tmp=AA.Framework.getContractDetails(); tmp<AA.Framework.CdBalEffDt,BAL.POS>=EFFECTIVE.DATE; AA.Framework.setContractDetails(tmp);* Assume this from the start of the current activity
            tmp=AA.Framework.getContractDetails(); tmp<AA.Framework.CdBalAmount,BAL.POS>=OUTSTANDING.AMOUNT; AA.Framework.setContractDetails(tmp)
            OUTSTANDING.AMOUNT = ""         ;* Reset as this variable holds the outstanding amounts for each payment date and needs to be returned back
        CASE SCHEDULE.INFO<24>           ;*if this flag is set then outstanding amount is already available in contract details
        CASE 1
            GOSUB GET.OUTSTANDING.FROM.BALANCES       ;* Get it from ACCT.ACTIVITY

***When curcommitment fully ustilised by drawings before bilateral to club conversion. In this case when we try to read CURCOMMITMENTINF for borrower, baldetails will be null since we will not raise INF for zero amount.But for FLR schedule prorata calculation to be done based on TOT commitment
*** Should not rely on TermAmount amount. Hence skip this GET.BALANCE.AMT for FLR schedule
            IF NOT(BAL.DETAILS) AND NOT(FAC.TERM.PROPERTY) THEN        ;* Get it from TERM.AMOUNT

** Load the Term Amount property if there is no balance amount and disbursement is not made yet. This can happen when term amount is calculated
** during modelling.

                LOAD.TERM.AMOUNT = 0 ;* Flag to get the balance amount from term amount to return outstanding amount to calculate calc amount for accelerated calc type for deposit.
                IF TERM.AMOUNT.REQD AND TERM.AMT.PROPERTY NE BALANCE.PROPERTY AND LIFECYCLE.STATUS = 'EXP' THEN
                    IF NOT(TEMP.BAL.AMT<PART.POS,BAL.POS>) THEN ;* there is no balance amount in EXP during new arrangement
                        LOAD.TERM.AMOUNT = 1
                    END
                END
                IF TERM.AMOUNT.REQD AND ((TERM.AMT.PROPERTY = BALANCE.PROPERTY) OR LOAD.TERM.AMOUNT) THEN ;* Term Amount may not be applicable for certain product types (Current Accounts?)
                    GOSUB GET.BALANCE.AMT
                END
** When the arrangement is in 'NEW.OFFER' status, Balance Details will be empty. So for borrower, assign the balance amount as Term amount
** For participants, assign the balance amount as Commitment Amount from participant property record
                IF R.ARRANGEMENT<AA.Framework.Arrangement.ArrArrStatus> EQ 'NEW.OFFER' THEN
                    IF IS.PARTICIPANT THEN
                        TEMP.BAL.EFF<PART.POS,BAL.POS> = EFFECTIVE.DATE
                        
                        BEGIN CASE
                            CASE IS.PORTFOLIO
                                TEMP.BAL.AMT<PART.POS,BAL.POS> = TEMP.PARTICIPANT.REC<AA.Participant.Participant.PrtPortfolioAmount, PF.CNT>
                            CASE PARTICIPANT EQ GlCustomer  ;* If current participant is BOOK., fetch the own commitment amount
                                TEMP.BAL.AMT<PART.POS,BAL.POS> = TEMP.PARTICIPANT.REC<AA.Participant.Participant.PrtOwnCommitAmt>
                            CASE 1
                                TEMP.BAL.AMT<PART.POS,BAL.POS> = TEMP.PARTICIPANT.REC<AA.Participant.Participant.PrtCommitmentAmt,PART.POS>
                        END CASE
                    END ELSE
                        GOSUB GET.BALANCE.AMT ;* For borrower, fetch the term amount from TERM.AMOUNT property record
                    END
                END
                IF ASSET.FINANCE.TAKEOVER THEN
                    GOSUB GET.BALANCE.AMT
                END
            END
    END CASE

** Set current balance amount
    IF ARRANGEMENT.ID NE 'DUMMY' THEN   ;* Invoke GetBill if it is a valid ArrangementId
        GOSUB GET.DEFERRED.CAP.BILLS        ;*Deferred Bills if any may be capitalised at a forward date which will contribute to outstanding amount. Include it as well
    END
    
    IF REPAY.OPTION THEN             ;* Execute this processing only for Deferred Holiday Interest.
        GOSUB GET.FORWARD.RECALC.PS.RECORD        ;* Get the payment Schedule record created for Forward Recalcualte activity.
        GOSUB GET.HOLIDAY.INTEREST.AMOUNTS    ;* Get the deferred Holiday interest amount from Balance type HOL<INTEREST>
        IF FORWARD.RECALC.DATE AND NOT(CUMILATIVE.ACD.HOL.PROP.DATES) THEN
            GOSUB GET.MIDDLE.PERIOD.HOL.DATES
        END
    END
    
** If the PROCESS.DATE is located in the TEMP.BAL.EFF array then assign the EFF.POS of PROCESS.DATE in the SAVE.PROCESS.DATE.POS variable.
** For example: After make due activity (make due on 8th of every month) and followed by an applypayment activity (9th), system must retain the same EFF.POS, if
** the CASHFLOW.EFFECTIVE.DATE is present in the TEMP.BAL.EFF date array, else do -1c.
    LOCATE PROCESS.DATE IN TEMP.BAL.EFF<PART.POS,BAL.POS,1> BY "AN" SETTING EFF.POS THEN
        IF CASHFLOW.EFFECTIVE.DATE AND CASHFLOW.EFFECTIVE.DATE NE PROCESS.DATE THEN
            SAVE.PROCESS.DATE.POS = EFF.POS
            LOCATE CASHFLOW.EFFECTIVE.DATE IN TEMP.BAL.EFF<PART.POS,BAL.POS,1> BY "AN" SETTING EFF.POS ELSE
                EFF.POS = SAVE.PROCESS.DATE.POS
            END
        END
** These cases are for FORWARD VALUE dated accounts.
** Scenario 1 : When we have CONSTANT and CHARGE bill falling on holiday then the system must update the EB.CASHFLOW correctly without removing the PRINCIPAL-ACCOUNT from it.
** example: 4 CONSTANT BILLS (08/01/2023, 08/02/2023, 08/03/2023, 08/04/2023-holiday) and 1 CHARGE bill (10/04/2023- holiday)
** PROCESS.DATE : (-1) 20230410, TEMP.BAL.EFF : (-1) 20221208\20230109\20230208\20230308\20230409, EFF.POS : (-1) 6
** During CHARGE make due activity (10th APR-holiday), system has the financial dates in TEMP.BAL.EFF array. PROCESS.DATE will not be located in the is not
** located in the TEMP.BAL.EFF array and the EFF.POS will be decremented. So system will take the previous financial date and update the EB.CASHFLOW correctly.

** Scenario 2 : 4 bills should be generated , last bill before last payment date should fall on holiday.
** Example : 4th bill falls on 22-4-2023 which is holiday and last schedule date is 22-5-2023.
** EB.CASHFLOW has wrong amount for PRINCIPAL-ACCOUNT for last payment date and EIR is wrong.
** during make due activity of (22nd APR- holiday), system checks the TEMP.BAL.EFF which has the financial dates. here system takes the 23rd APR as the fin date
** for 22nd APR makedue activity and updates the correct outstanding amount for the last schedule and the april schedule and calculates the EIR rate accordingly.
** here the system must retain the same EFF.POS, when we have the value in TEMP.BAL.EFF.
    END ELSE
        IF EFF.POS GT 1 AND (NOT(CASHFLOW.EFFECTIVE.DATE) OR TEMP.BAL.EFF<PART.POS, BAL.POS, EFF.POS> EQ "") THEN
            EFF.POS -= 1
        END
    END

** Update OutstandingAmount for Borrower and Participants in two different variables.
** For Borrower, ArrangementId will be populated in ContractDetails.
** For Participant, ParticipantId each separated by '*' will be populated in Contract Details.
    IF IS.PARTICIPANT THEN
        PARTICIPANT.PRESENT.VALUE<1,-1> = ABS(TEMP.BAL.AMT<PART.POS,BAL.POS,EFF.POS>)
        TEMP.ARRID<-1> = VALID.PARTICIPANTS<1,PART.POS>
    END ELSE
        PRESENT.VALUE = ABS(TEMP.BAL.AMT<PART.POS,BAL.POS,EFF.POS>)  ;* Current outstanding amount, set for each payment date
        TEMP.ARRID<PART.POS> = ARRANGEMENT.ID
    END
    
    GOSUB BUILD.CONTRACT.DETAILS        ;* Set updated Values in ContractDetails common
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name=GET.BALANCE.TO.CHECK>
*** <desc>Get property balance name</desc>
GET.BALANCE.TO.CHECK:

    CUR.PROPERTY = BALANCE.PROPERTY
    GOSUB GET.PARTICIPANT.ACCT.MODE     ;* Send Participant AcctMode to get Balance Name
    IF PARTICIPATION.TYPE THEN
        CUR.PROPERTY<4> = 'RISK.PARTICIPANT'            ;* Send Risk Participant flag to get Balance build.
    END
    BALANCE.PROPERTY = CUR.PROPERTY
    
    AA.ProductFramework.PropertyGetBalanceName(ARRANGEMENT.ID, BALANCE.PROPERTY, LIFECYCLE.STATUS, "", "BANK", BALANCE.TO.CHECK) ;* Get property balance name
    
RETURN

*** </region>
*-----------------------------------------------------------------------------
*** <region name=STORE.BALANCE.TO.CHECK>
*** <desc>Store balance in common to be used for Interest/Charge calculations</desc>
STORE.BALANCE.TO.CHECK:
    
    IF NOT(RISK.ACCOUNT.PROCESS) THEN
        LOCATE BALANCE.TO.CHECK IN TEMP.BASE.BAL<PART.POS,1> SETTING BAL.POS ELSE
            BAL.POS = DCOUNT(TEMP.BASE.BAL<PART.POS>, @VM) + 1
            TEMP.BASE.BAL<PART.POS,BAL.POS> = BALANCE.TO.CHECK      ;* Store balance in common to be used for Interest/Charge calculations
        END
    END
RETURN
*** </region>
*-----------------------------------------------------------------------------


*** <region name=GET.TERM.ACCOUNT.PROPERTIES>
*** <desc>Get term.amount account property details</desc>
GET.TERM.ACCOUNT.PROPERTIES:

    IF NOT(AF.Framework.getProductRecord()) THEN      ;* Do no rely on common, may be called from enquiry!!
        GOSUB GET.PUBLISHED.RECORD
    END

    IF AA.Framework.getSourceDetails()<1> EQ ARRANGEMENT.ID ELSE          ;*Reset if loaded for a different arrangement
        AA.Framework.setSourceDetails(ARRANGEMENT.ID)
    END

** Get Term Amount property

    TERM.AMT.PROPERTY = AA.Framework.getSourceDetails()<6>      ;*Load from the common variable if present
    IF TERM.AMT.PROPERTY ELSE ;*Store it after loading
        PRODUCT.RECORD = AF.Framework.getProductRecord()
        AA.ProductFramework.GetPropertyName(PRODUCT.RECORD, "TERM.AMOUNT", TERM.AMT.PROPERTY)
        tmp=AA.Framework.getSourceDetails(); tmp<6>=TERM.AMT.PROPERTY; AA.Framework.setSourceDetails(tmp)
    END

** Get Account property

    ACCOUNT.PROPERTY = AA.Framework.getSourceDetails()<7>       ;*Load from the common variable if present
    IF ACCOUNT.PROPERTY ELSE  ;*Store it after loading
        PRODUCT.RECORD = AF.Framework.getProductRecord()
        AA.ProductFramework.GetPropertyName(PRODUCT.RECORD, "ACCOUNT", ACCOUNT.PROPERTY)
        tmp=AA.Framework.getSourceDetails(); tmp<7>=ACCOUNT.PROPERTY; AA.Framework.setSourceDetails(tmp)
    END

RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name=GET.PUBLISHED.RECORD>
*** <desc>Get published record</desc>
GET.PUBLISHED.RECORD:

** If Published product record is not loaded in common read it from disk and
** also load common

    PRODUCT.PROPERTY = "PRODUCT"
    tmp.AA$PRODUCT.RECORD = AF.Framework.getProductRecord()
    AA.ProductFramework.GetPublishedRecord(PRODUCT.PROPERTY, '', '', EFFECTIVE.DATE, tmp.AA$PRODUCT.RECORD, VAL.ERROR)
    AF.Framework.setProductRecord(tmp.AA$PRODUCT.RECORD)
*    AA.Framework.setProductRecord(tmp.AA$PRODUCT.RECORD)

RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= GET.OUTSTANDING.FROM.BALANCES>
*** <desc>File variables and local variables</desc>
GET.OUTSTANDING.FROM.BALANCES:

    BAL.DETAILS = ""
    BALANCE.CHECK.DATE = EFFECTIVE.DATE

** Get movement details for the property balance from ACCT.ACTIVITY

    MAT.DATE = AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdMaturityDate>      ;* Get future principla movements

** pass activity effective date as MAT.DATE for CALL contracts
    CALL.CONTRACT = ''
    IF NOT(MAT.DATE) THEN
        MAT.DATE = EFFECTIVE.DATE
        IF TERM.AMOUNT.REQD THEN
            CALL.CONTRACT = '1' ;* set this flag to indicate call contract to reset current period accured amount variable
        END
    END

    SKIP.INAU.FLAG = ''
    AA.Framework.DetermineNauProcessing(SKIP.INAU.FLAG)
    IF IS.PARTICIPANT THEN                  ;* Participant account number is in the formate of accountnumber*partcustomer id
        ACCOUNT.ID = ACCOUNT.ID:"*":PARTICIPANT
    END
    DATE.OPTIONS = ''
    IF NOT(SKIP.INAU.FLAG) THEN         ;*In COB Processing ,  Don't add the NAU Movements - if Disbursement is in INAU.
        DATE.OPTIONS<2> = "ALL"         ;* Include NAU too
    END
    IF PROCESS.PARTICIPANTS THEN        ;* To get the participant related balances requires to pass participant accounting mode to form balance type and fetch the balance of participants
        DATE.OPTIONS<7> = PART.ACCT.MODE
        DATE.OPTIONS<8> = 1
        IF PARTICIPATION.TYPE THEN
            DATE.OPTIONS<10> = 'RISK.PARTICIPANT'    ;* Send Risk Participant flag to get Balance build.
        END
    END
    
    DATE.OPTIONS<6> = EXTENSION.NAME
    
    IF FWD.ACC.FLAG THEN
        DATE.OPTIONS<9> = FWD.ACC.FLAG ;* If Forward Accounting is enabled, send FWD to retrieve consolidated balance of Real and FWD balance amounts
    END
    IF AA.Interest.getRStoreProjection() THEN ;*During Projection,We need to take CurAccount Balances from Arrangement Start Date
        BAL.START.DATE=ARR.START.DATE
    END ELSE
        IF SCHEDULE.INFO<68> AND SCHEDULE.INFO<67> LE EFFECTIVE.DATE THEN
            IF SCHEDULE.INFO<67> THEN
                BAL.START.DATE = SCHEDULE.INFO<67> ;*When we are able to find atleast one Interest Property(Schedule.info<68>,Take Oldest Last Payment Date)
            END ELSE
                BAL.START.DATE = ARR.START.DATE
            END
        END ELSE
            BAL.START.DATE=EFFECTIVE.DATE    ;*When we dont have any Interest Property,We can take as of Effective Date
        END
        IF BAL.START.DATE AND ARR.START.DATE AND BAL.START.DATE NE ARR.START.DATE THEN
            EB.API.Cdt("", BAL.START.DATE , "-1C")
        END
    END
    
    GOSUB GET.PERIOD.BALANCE
    
** AC.GET.PERIOD.BALANCES returns full dates

    IF BAL.DETAILS THEN
        TEMP.BAL.EFF<PART.POS,BAL.POS> = LOWER(BAL.DETAILS<AC.BalanceUpdates.AcctActivity.IcActDayNo>)
        GOSUB CHECK.DEPOSIT.OUT.STANDING
        
        TEMP.BAL.AMT<PART.POS,BAL.POS> = TEMP.BALANCE.AMT
        BALANCE.AMOUNT = TEMP.BAL.AMT<PART.POS,BAL.POS>
    END

    IF NOT(AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdStartDate>) AND PRODUCT.LINE EQ 'LENDING' THEN
        IF SCHEDULE.INFO<8> THEN
            GOSUB GET.AVL.BALANCE ;* Include available balance with committment for schedule projection, when disbursement is scheduled
        END ELSE
            IF BALANCE.PROPERTY EQ TERM.AMT.PROPERTY THEN
                STORE.BALANCE.PROPERTY = BALANCE.PROPERTY
                GOSUB GET.AVL.BALANCE
                BALANCE.PROPERTY = STORE.BALANCE.PROPERTY
            END
        END
    END
       
**For future dated schedules to check the balance arrangement start date has to be passed to get the correct balance amounts.
    IF BALANCE.CHECK.DATE LT ARR.START.DATE THEN
        BALANCE.CHECK.DATE = ARR.START.DATE
    END

    AVAILABLE.COMMIT.AMT = 0
    CUR.PROPERTY = TERM.AMT.PROPERTY
    GOSUB GET.PARTICIPANT.ACCT.MODE     ;* Send Participant AcctMode to get Balance Name
    IF PARTICIPATION.TYPE THEN
        CUR.PROPERTY<4> = 'RISK.PARTICIPANT'            ;* Send Risk Participant flag to get Balance build.
    END
    TOT.TERM.BAL = ""
    AA.ProductFramework.PropertyGetBalanceName(ARRANGEMENT.ID, CUR.PROPERTY, "TOT", "", "", TOT.TERM.BAL)
    AA.Framework.GetPeriodBalances(ACCOUNT.ID, TOT.TERM.BAL, DATE.OPTIONS, BALANCE.CHECK.DATE, "", "", BAL.DETAILS, "")
    TOT.TERM.AMT = ABS(BAL.DETAILS<AC.BalanceUpdates.AcctActivity.IcActBalance>)

    BAL.DETAILS = ''
    CUR.PROPERTY = TERM.AMT.PROPERTY
    GOSUB GET.PARTICIPANT.ACCT.MODE     ;* Send Participant AcctMode to get Balance Name
    IF PARTICIPATION.TYPE THEN
        CUR.PROPERTY<4> = 'RISK.PARTICIPANT'            ;* Send Risk Participant flag to get Balance build.
    END
    AA.ProductFramework.PropertyGetBalanceName(ARRANGEMENT.ID, CUR.PROPERTY, "CUR", "", "", TOT.TERM.BAL)
 
    AA.Framework.GetPeriodBalances(ACCOUNT.ID, TOT.TERM.BAL, DATE.OPTIONS, BALANCE.CHECK.DATE, "", "", BAL.DETAILS, "")
    CUR.TERM.AMT = ABS(BAL.DETAILS<AC.BalanceUpdates.AcctActivity.IcActBalance>)
***Assign available commitment with either cur/tot term, to disburse remaining schedule when schedule is left blank
    IF CUR.TERM.AMT THEN
        AVAILABLE.COMMIT.AMT = CUR.TERM.AMT
    END
  
    IF AA.Framework.getContractDetails()<AA.Framework.CdIncludePrinAmounts> MATCHES "YES":@VM:"PROGRESSIVE" THEN    ;* when IncludePrinAmounts is not set then only TOT.TERM.AMT & CUR.TERM.AMT variable should be assigned
        CUR.TERM.AMT = 0
        TOT.TERM.AMT = 0
    END
 
* If Participant offline process flag is set, thens set the TOT and CUR Amount from ParticipantCommitementbalances
    IF SCHEDULE.INFO<28> EQ 'OFFLINE' THEN
        IF IS.PARTICIPANT AND NOT(CUR.TERM.AMT) AND NOT(TOT.TERM.AMT) THEN
            ARRANGEMENT.ID<2> = 'OFFLINE'
            CommitmentBalances = ''
            PARTICIPANT<2> = IS.PARTICIPANT
            PARTICIPANT<3> = IS.PORTFOLIO
            AA.Participant.GetParticipantCommitmentBalances(ARRANGEMENT.ID, EFFECTIVE.DATE, PARTICIPANT, TEMP.PARTICIPANT.REC, CommitmentBalances)
            TOT.TERM.AMT = CommitmentBalances<1>
            CUR.TERM.AMT = CommitmentBalances<2>
**For Participant offline Processing, in online Participant related entries is not raised so we fetch amount (CUR & TOT) from Bill.
            IF CUR.TERM.AMT THEN
                AVAILABLE.COMMIT.AMT = CUR.TERM.AMT ;* During Auto Disbursement, Available Amount is assigned with Cur Term Amount
            END
        END
    END
** When arrangemnet created with PaymentType as DISBURSEMENT, Property amount for Borrower account will be updated using Tot and Cur TermAmount balance,
** Same should happen for Participants property amount updation also. So save TermAmount balances read from BAlance details and use during Properties Amount updation.
    IF SCHEDULE.INFO<28> OR FAC.TERM.PROPERTY THEN         ;*When participants defined
        SAVE.TOT.TERM.AMT<-1> = TOT.TERM.AMT            ;*Save Tot, Cur & Available  TermAmount for borrower and Participant for further processing
        SAVE.CUR.TERM.AMT<-1> = CUR.TERM.AMT
        SAVE.AVAILABLE.COMMIT.AMT<-1> = AVAILABLE.COMMIT.AMT
** During FLR, as part of non prorate changes, the formula is changed to consider both CUR and UTL balance instead of TOT balance
** If the amount that is being reduced is more than the available CUR, then UTL will also be used to calculate the non prorate amount
        IF FAC.TERM.PROPERTY THEN
            GOSUB GET.UTL.BALANCE.AMOUNT
        END
    
    END

RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= Get period balances>
*** <desc>Get balances between specified start and end dates</desc>
GET.PERIOD.BALANCE:

*Transaction happening in COB till SOD is included in bill at SOD stage. It should not include the transaction happening in COB till SOD because those transaction have value date as next date
*So,transaction happened upto before date, should be only included in bill
 
    BEGIN CASE

** For Make.Due activity, system should read the balances upto the effective date.
** Reading the balances upto maturity date will cause performance issue because of multiple reads of ACCT.BALANCE.ACTIVITY record.
        CASE ACTIVITY.ACTION MATCHES "MAKE.DUE":@VM:"DEFER.MAKEDUE":@VM:"CAPITALISE":@VM:"DEFER.CAPITALISE"
            AA.Framework.GetPeriodBalances(ACCOUNT.ID, BALANCE.TO.CHECK, DATE.OPTIONS, BAL.START.DATE, EFFECTIVE.DATE, '', BAL.DETAILS, "")
                  
        CASE ACTIVITY.ACTION EQ "ISSUE.BILL" AND INITIATION.TYPE.STAGE EQ "SOD" AND PROPERTIES.CLASS EQ "ACCOUNT"
            EB.API.Cdt("", PROCESS.DATE , "-1C")
            AA.Framework.GetPeriodBalances(ACCOUNT.ID, BALANCE.TO.CHECK, DATE.OPTIONS, BAL.START.DATE, PROCESS.DATE, '', BAL.DETAILS, "")
       
        CASE TERM.AMT.PROPERTY AND SCHEDULE.INFO<42>
******For Cashflow no need to get balance till maturity date if the tier source balance is TOT commitment for Term Amount Property class"
            CASHFLOW.EFFECTIVE.DATE = EFFECTIVE.DATE    ;* Initialize CASHFLOW.EFFECTIVE.DATE with EFFECTIVE.DATE for processing when date.convention is "calender" by default
            IF R.ACCOUNT THEN
                DATE.CONVENTION = R.ACCOUNT<AA.Account.Account.AcDateConvention>
                DATE.ADJUSTMENT = R.ACCOUNT<AA.Account.Account.AcDateAdjustment>
                IF DATE.CONVENTION EQ "FORWARD" AND DATE.ADJUSTMENT EQ "VALUE" THEN     ;* Case when "Forward" as date convention and "value" as date adjustment and schedule falling on holiday - Always set forward date(next working date) as effective date for cashflow handoff
                    NEXT.WORKING.DAY = EB.SystemTables.getRDates(EB.Utility.Dates.DatNextWorkingDay)
******During cob if the effective date is equal to the current system date then get the next working day as the cashflow date.
                    IF NEXT.WORKING.DAY AND (NEXT.WORKING.DAY LT MAT.DATE) THEN     ;* Dont go beyond maturity date while getting forward date
                        IF EFFECTIVE.DATE EQ CURRENT.SYS.DATE THEN
                            CASHFLOW.EFFECTIVE.DATE = NEXT.WORKING.DAY
                        END ELSE
******For any backdated activities, get the next working day as cashflow date.
                            GOSUB CHECK.WORKING.DAYS ; * check the EFFECTIVE.DATE is a working day
                            IF RETURN.CODE NE "ERR" THEN
                                CASHFLOW.EFFECTIVE.DATE = RETURN.DATE
                            END
                        END
                    END
                END
            END
            AA.Framework.GetPeriodBalances(ACCOUNT.ID, BALANCE.TO.CHECK, DATE.OPTIONS, BAL.START.DATE, CASHFLOW.EFFECTIVE.DATE, '', BAL.DETAILS, "")
             
        CASE 1
            IF MAT.DATE GT EFFECTIVE.DATE THEN
                AA.Framework.GetPeriodBalances(ACCOUNT.ID, BALANCE.TO.CHECK, DATE.OPTIONS, BAL.START.DATE, MAT.DATE, '', BAL.DETAILS, "")    ;* Get the balance for this date
            END ELSE
                SAVE.ACCOUNTID=ACCOUNT.ID
                IF EB.SystemTables.getRunningUnderBatch() AND EB.Service.getRTsaStatus()<EB.Service.TsaStatus.TsTssCurrentService>[1,3] EQ 'COB' THEN
                    ACCOUNT.ID<3> = 'NO.ADJ.BOOK'
                END
                AA.Framework.GetPeriodBalances(ACCOUNT.ID, BALANCE.TO.CHECK, DATE.OPTIONS, BAL.START.DATE, EFFECTIVE.DATE, '', BAL.DETAILS, "")        ;* Get the balance for this date
                ACCOUNT.ID=SAVE.ACCOUNTID
            END
        
    END CASE
    
RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Get Available balance>
*** <desc>Include the available balance with the curcommittment for schedule projection</desc>
GET.AVL.BALANCE:

    AA.Framework.CheckBaseBalance("", ACCOUNT.PROPERTY, BALANCE.PROPERTY)
    LIFECYCLE.STATUS = "AVL"
    GOSUB GET.BALANCE.AMOUNT
       
* If there is any amount present in CUR balance, then add it to outstanding amount for projection
    LIFECYCLE.STATUS = "CUR"
    GOSUB GET.BALANCE.AMOUNT
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= Get Balance amount>
*** <desc>Get the balance amount based on lifecycle status</desc>
GET.BALANCE.AMOUNT:

    GOSUB GET.BALANCE.TO.CHECK ;* To get the balance name based on lifecycle status
    BAL.START.DATE=ARR.START.DATE
    GOSUB GET.PERIOD.BALANCE ;* To get the corresponding balance amount

    IF BAL.DETAILS THEN
** the date has to be appended when the balance is there for the AVL account, which then will be added to the contract details.
        IF LIFECYCLE.STATUS EQ "AVL" THEN
            TEMP.BAL.EFF<PART.POS,BAL.POS> = LOWER(BAL.DETAILS<AC.BalanceUpdates.AcctActivity.IcActDayNo>)
        END
        GOSUB CHECK.DEPOSIT.OUT.STANDING

        TEMP.BAL.AMT<PART.POS,BAL.POS> += TEMP.BALANCE.AMT
        BALANCE.AMOUNT += TEMP.BALANCE.AMT
    END

RETURN
*** </region>
*-----------------------------------------------------------------------------

GET.DEFERRED.CAP.BILLS:
    
    TMP.ACCOUNT.DETAILS = tmp.AA$ACCOUNT.DETAILS
    CONVERT @SM TO @VM IN TMP.ACCOUNT.DETAILS
    
    IF ("CAPITALISE" MATCHES TMP.ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdPayMethod>) AND ("DEFER" MATCHES TMP.ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdBillStatus>) THEN ;* To check defer and cap bills are present in account details before blindly calling get bill routine.
        AA.PaymentSchedule.GetBill(ARRANGEMENT.ID, "", "", "", "", "CAPITALISE", "DEFER", "", "", "", "", "", DEFER.BILL.REFERENCES, RET.ERROR) ;*Retrieve all the capitalised bills
        LOOP
            REMOVE DEFER.BILL FROM DEFER.BILL.REFERENCES SETTING BILL.POS
        WHILE DEFER.BILL
            DEFER.BILL.DETAIL = ""          ;*Reset
            AA.PaymentSchedule.GetBillDetails(ARRANGEMENT.ID, DEFER.BILL, DEFER.BILL.DETAIL, RET.ERROR)          ;*Get the Bill Details
            GOSUB GET.DEFERRED.AMOUNT
        REPEAT
    END

RETURN
*-----------------------------------------------------------------------------
GET.DEFERRED.AMOUNT:

    DEFER.BILL.PROPERTIES = DEFER.BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdPayProperty>
    DEFER.BILL.AMOUNTS = DEFER.BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdOsPrAmt>
    DEFER.BILL.DATES = DEFER.BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdDeferDate>
    LOOP
        REMOVE DEFER.BILL.PROPERTY FROM DEFER.BILL.PROPERTIES SETTING DEF.POS
        REMOVE DEFER.PROPERTY.AMOUNT FROM DEFER.BILL.AMOUNTS SETTING DEF.POS
        REMOVE DEFER.BILL.DATE FROM DEFER.BILL.DATE SETTING DEF.POS
    WHILE DEFER.BILL.PROPERTY
        DEFER.PROPERTY.CLASS = ""
        AA.ProductFramework.GetPropertyClass(DEFER.BILL.PROPERTY, DEFER.PROPERTY.CLASS)
        GOSUB DETERMINE.CREDIT.DEBIT.TYPE
        DEFER.PROPERTY.AMOUNT = DEFER.PROPERTY.AMOUNT * SIGN * DEFER.SIGN       ;*Put it in the correct balance sign to add
        LOCATE DEFER.BILL.DATE IN TEMP.BAL.EFF<PART.POS,BAL.POS,1> BY "AR" SETTING DEFER.POS THEN
            TEMP.BAL.AMT<PART.POS,BAL.POS,DEFER.POS> += BALANCE.AMOUNT
        END ELSE
            INS EFFECTIVE.DATE BEFORE TEMP.BAL.EFF<PART.POS,BAL.POS,DEFER.POS>
            IF DEFER.POS GT 1 THEN
                INS TEMP.BAL.AMT<PART.POS,BAL.POS,DEFER.POS-1> + BALANCE.AMOUNT BEFORE TEMP.BAL.AMT<PART.POS,BAL.POS,DEFER.POS>
            END ELSE
                INS BALANCE.AMOUNT BEFORE TEMP.BAL.AMT<PART.POS,BAL.POS,DEFER.POS>
            END
        END
        tmp.VALUE =  TEMP.BAL.AMT<PART.POS,BAL.POS>
        TOTAL.CNT = DCOUNT(tmp.VALUE, @SM)
        FOR LOOP.CNT = DEFER.POS+1 TO TOTAL.CNT   ;*Ripple out the effective increase/decrease
            TEMP.BAL.AMT<PART.POS,BAL.POS, LOOP.CNT> = TEMP.BAL.AMT<PART.POS,BAL.POS, LOOP.CNT> + BALANCE.AMOUNT
        NEXT LOOP.CNT

    REPEAT

RETURN
*-----------------------------------------------------------------------------
DETERMINE.CREDIT.DEBIT.TYPE:

    BEGIN CASE
        CASE DEFER.PROPERTY.CLASS EQ "CHARGE"
            DEFER.SIGN = 1        ;*Default Debit Charge should increase the principal
            AA.Framework.LoadStaticData('F.AA.PROPERTY', DEFER.BILL.PROPERTY, R.PROPERTY, RET.ERROR)
            LOCATE "CREDIT" IN R.PROPERTY<AA.ProductFramework.Property.PropPropertyType,1> SETTING CREDIT.TYPE THEN
                DEFER.SIGN = -1   ;* Credit charge - other way
            END
        CASE DEFER.PROPERTY.CLASS EQ "INTEREST"
            BEGIN CASE
                CASE PRODUCT.LINE = "LENDING"
                    DEFER.SIGN = 1    ;*For lending, we need to increase

                CASE PRODUCT.LINE = "ACCOUNTS"
                    SOURCE.BALANCE.TYPE = ''
                    RET.ERR = ''
                    LOCATE DEFER.BILL.PROPERTY IN SOURCE.BAL.TYPE.ARRAY<1,1> SETTING SOURCE.BAL.TYPE.POS THEN
                        SOURCE.BALANCE.TYPE = SOURCE.BAL.TYPE.ARRAY<2, SOURCE.BAL.TYPE.POS>
                    END ELSE
                        AA.Framework.GetSourceBalanceType(DEFER.BILL.PROPERTY, '', '', SOURCE.BALANCE.TYPE, RET.ERR)
                        SOURCE.BAL.TYPE.ARRAY<1,-1> = DEFER.BILL.PROPERTY
                        SOURCE.BAL.TYPE.ARRAY<2,-1> = SOURCE.BALANCE.TYPE
                    END

                    IF SOURCE.BALANCE.TYPE EQ "DEBIT" THEN
                        DEFER.SIGN = 1          ;*Increase the principal
                    END ELSE
                        DEFER.SIGN = -1         ;*Decrease the principal
                    END

                CASE 1        ;** Get capitalise event types for Deposits
                    DEFER.SIGN = 1    ;*For Deposits, increase the principal

            END CASE

        CASE DEFER.PROPERTY.CLASS EQ "PERIODIC.CHARGES"
**Need to confirm after the Periodic charges spec part

    END CASE

RETURN
*-----------------------------------------------------------------------------

*** <region name= Check Deposit Outstanding balance>
*** <desc>For EXP Account Balance , Contract Details should be updated as Positive.</desc>
CHECK.DEPOSIT.OUT.STANDING:

    TEMP.BALANCE.AMT = ""
    IF NOT(PRODUCT.LINE MATCHES 'LENDING':@VM:'GUARANTEES') AND BALANCE.TO.CHECK[1,3] = "EXP" THEN
        TEMP.BALANCE.AMT =  LOWER(BAL.DETAILS<AC.BalanceUpdates.AcctActivity.IcActBalance>)
        TEMP.BALANCE.AMT =  ABS(TEMP.BALANCE.AMT)
    END ELSE
        TEMP.BALANCE.AMT  = LOWER(BAL.DETAILS<AC.BalanceUpdates.AcctActivity.IcActBalance>)
    END

RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Check Base balance>
*** <desc>Check if balance switch has to be done</desc>
CHECK.BASE.BALANCE:

** Get the balance property for the calculating the outstanding amount
** This may either TermAmount property or Account property

    AA.Framework.CheckBaseBalance(TERM.AMT.PROPERTY, ACCOUNT.PROPERTY, BALANCE.PROPERTY)

** If the balance property is TermAmount, take the EXP<Account> as the
** base balance instead of CUR<TermAmount> in case of Deposits
** For facility product line do not reset balance property as account property.let it be termamount property
    IF TERM.AMT.PROPERTY AND NOT(PRODUCT.LINE MATCHES 'LENDING':@VM:'GUARANTEES':@VM:'ASSET.FINANCE':@VM:'FACILITY') AND BALANCE.PROPERTY EQ TERM.AMT.PROPERTY THEN     ;*For ACCOUNTS product line, TERM.AMT.PROPERTY would be null. For Asset Finance product line, set BaseProperty to TermAmount property.
        LIFECYCLE.STATUS = 'EXP'
        BALANCE.PROPERTY = ACCOUNT.PROPERTY
    END

***For facility, to generate bill for commitment reduction(when term amount PC is defined in facility) as part of any recalculation activity(issuebill/makedue/increase), consider TOT commitment always
    IF PRODUCT.LINE EQ "FACILITY" THEN
        PAYMENT.SCHEDULE.PROPERTIES = R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsProperty>
        CONVERT @SM TO @VM IN PAYMENT.SCHEDULE.PROPERTIES
        LOCATE TERM.AMT.PROPERTY IN PAYMENT.SCHEDULE.PROPERTIES<1,1> SETTING TERM.PROP.POS THEN
            LIFECYCLE.STATUS = 'TOT'
            BALANCE.PROPERTY = TERM.AMT.PROPERTY
            FAC.TERM.PROPERTY = 1
        END
    END
    
***During fwd dated/current dated drawing creation if any activity charge is configured for this new arrangement, system was fetching the curaccount balance instead of taking the commitment balance during issuebill/makedue. Since arrangement is not disbursed yet LI.CASHFLOW is not getting updated after the drawing creation.
    IF NOT(AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdStartDate>) AND BALANCE.PROPERTY EQ ACCOUNT.PROPERTY AND CASHFLOW.LIMIT.CHECK THEN
        BALANCE.PROPERTY = TERM.AMT.PROPERTY
    END

RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Get Property Record>
*** <desc>Get the property record for the property and effective date</desc>
GET.PROPERTY.RECORD:

** Get the property record for the property

    R.PROPERTY.RECORD = ""
    AA.ProductFramework.GetPropertyRecord("", ARRANGEMENT.ID, PROPERTY.ID, PROPERTY.DATE, PROPERTY.CLASS, "", R.PROPERTY.RECORD, RET.ERROR) ;* Get the term amount record
    IF RET.ERROR THEN
        ERROR.FLAG = "1"
    END

RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Build payment dates>
*** <desc>Build payment dates, if not passed in</desc>
BUILD.PAYMENT.DATES:

** END.DATE should be passed as null for the entire list of dates
** This would be usually null for iterative calculations
    IF UNASSIGNED(PAYMENT.DATES) THEN
        PAYMENT.DATES = ""
    END

    IF NOT(PAYMENT.DATES) THEN
        START.DATE = ""
        END.DATE = ""
        NO.CYCLES = NO.CYCLES ;* If requested, up to these number of cycles
        END.DATE = REQD.END.DATE        ;* Up to the requested date

        PAYMENT.DATES = ""
        PAYMENT.AMOUNTS = ""
        PAYMENT.METHODS = ""
        PAYMENT.PERCENTAGES = ""
        PAYMENT.MIN.AMOUNTS = ""
        PAYMENT.DEFER.DATES = ""
        PAYMENT.BILL.TYPES = ""
        PAYMENT.FIN.DATES = ""
        PARTICIPANT.IDS = ""
        PARTICIPANTS.ACCT.MODE = ""
        PART.PARTICIPATION.TYPE = ""
        PARTICIPANTS.DETAILS = ''   ;* Participants list each separated by '*'
        PARTICIPANT.PROPERTIES.AMT = '' ;* Payment amount calculated for each property by payment type and payment date (sub-value) for each participant separated by '*'
        PARTICIPANT.TAX.DETAILS = '' ;* Tax amount calcualted for each property amount (sub-value) for each participant separated by '*'
        PARTICIPANT.OUTSTANDING.AMT = ''    ;* Outstanding amount for each participant separated by '*'
        PROCESS.PARTICIPANTS = 0            ;* Flag to check if Participant details need to be populated
    
        AA.PaymentSchedule.ProjectPaymentScheduleDates(SCHEDULE.INFO, START.DATE, END.DATE, NO.CYCLES, "", PAYMENT.DATES, "", PAYMENT.FIN.DATES, PAYMENT.TYPES, PAYMENT.METHODS, PAYMENT.AMOUNTS, PAYMENT.PROPERTIES, PAYMENT.PERCENTAGES,PAYMENT.MIN.AMOUNTS, PAYMENT.DEFER.DATES, PAYMENT.BILL.TYPES, PARTICIPANT.IDS, PARTICIPANTS.ACCT.MODE, PART.PAYMENT.PROPERTIES, PART.PARTICIPATION.TYPE, '', '', RET.ERROR)
        PAY.FIN.DATES = PAYMENT.FIN.DATES
        
    END
    
* During Interest Capitalisation, Participant list and other related details will be available in in arguments. Assign those to local variables for Participant processing
    IF PARTICIPANTS.DETAILS THEN
        PARTICIPANT.IDS = PARTICIPANTS.DETAILS
        PART.PARTICIPATION.TYPE = PARTICIPANT.PARTICIPATION.TYPES
    END
    
    IF PARTICIPANT.IDS THEN         ;* If Participants List returned from Dates routine
        PROCESS.PARTICIPANTS = 1        ;* Need to process Schedule for Participants also
        PART.ACCT.MODE =  'MEMO'          ;*Default Borrower Accounting Mode
           
** Store the participant payment properties in a different variable and then convert the SM and VM markers to special characters
** So that while doing LOOP REMOVE for each payment date, the corresponding participant properties are returned for the payment dates
** Using ~ and _ special characters because they are not allowed in property name
        STORE.PART.PAYMENT.PROPERTIES = PART.PAYMENT.PROPERTIES
        CONVERT @VM TO '~' IN STORE.PART.PAYMENT.PROPERTIES
        CONVERT @SM TO '_' IN STORE.PART.PAYMENT.PROPERTIES
    END
    
    HOLIDAY.PAYMENT.AMOUNTS = RAISE(RAISE(PAYMENT.MIN.AMOUNTS<2>)) ;* Assigning the holiday payment amounts
    PAYMENT.MIN.AMOUNTS = RAISE(RAISE(PAYMENT.MIN.AMOUNTS<1>)) ;* Assigning the payment minimum amounts

* Common variables defined for local developed routines
    FULL.PAYMENT.DATES = PAYMENT.DATES  ;*Store full payment dates
    FULL.PAYMENT.TYPES = PAYMENT.TYPES  ;*Store full payment types
    
    R.PARTICIPANT = RAISE(RAISE(SCHEDULE.INFO<44>))  ;* Get Participant record from Schedule Info which is passed from Project Payment Schedule Dates
    R.RISK.PARTICIPANT = RAISE(RAISE(SCHEDULE.INFO<45>))  ;* Get Risk Participant record from Schedule Info which is passed from Project Payment Schedule Dates
    
*To check if the account is 100 percent share transfer to raise bills correctly
    SHARE.TRANSFER.REC = ''
    FULL.SHARE.TRANSFER = ''
    POOL.ID = AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdSecuritisationPoolId>
    IF POOL.ID AND ACTIVITY.ACTION MATCHES 'ISSUE.BILL':@VM:'MAKE.DUE' THEN
        AA.ProductFramework.GetPropertyRecord('', ARRANGEMENT.ID, '', EFFECTIVE.DATE, 'SHARE.TRANSFER', '', SHARE.TRANSFER.REC, '')
        TRANSFER.PERC = SHARE.TRANSFER.REC<AA.ShareTransfer.ShareTransfer.StTransferPercentage>
        IF TRANSFER.PERC EQ '100' THEN
            FULL.SHARE.TRANSFER = '1'
        END
    END
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name=SAVE.BORROWER.AMOUNTS>
*** <desc>Save borrower related information to calculate participant amounts</desc>
SAVE.BORROWER.AMOUNTS:
    
    BORROWER.CALC.AMT = ''                                  ;* Borrower calculated amount to use when updating ProRata for Participants
    PREV.PRESENT.VALUE = PRESENT.VALUE                      ;* Borrower Outstanding amount from Previous run
    PREV.PART.PRESENT.VALUE = PARTICIPANT.PRESENT.VALUE     ;* Participants Outstanding amoutn from previous run
    IS.PARTICIPANT = 0
    IS.PORTFOLIO = 0
    PART.POS = 1
    BORROWER.ID = "BORROWER"
    PART.ID = ''
    PART.ACCT.MODE = ''
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
    
*** <region name= Build forward schedules>
*** <desc>Calculate payment amounts for each of the properties</desc>
BUILD.FORWARD.SCHEDULES:

** Build a list of schedules to calculate the property amounts
** When principal property is calculated update present value of the contract also.
    
    TEMP.AMOUNT = ''
    TEMP.UPDATE.AMOUNT = ''
    TEMP.CAP.PAYMENT.TYPE = ''

    SAV.PS.REC = R.PAYMENT.SCHEDULE     ;* Save the psyment schedule record to restore later.

    GOSUB GET.PROCESS.SEQUENCE          ;* Get default sequence

    PERIOD.START.DATE = R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsBaseDate>

    NO.OF.PAYMENT.DATES = DCOUNT(PAYMENT.DATES, @FM)         ;* Loop through each date and calculate payment amounts
    
* Set termamount property as schedule property to set ACCOUNT.FINAL.POS & ACCOUNT.PROP.FINAL.POS to process residual processing, incase of FLR schedule when its called from projector.
    SCHEDULE.PROPERTY = ACCOUNT.PROPERTY
    IF FAC.TERM.PROPERTY AND SCHEDULE.INFO<8> THEN ;*Only during projection
        SCHEDULE.PROPERTY = TERM.AMT.PROPERTY
    END
    GOSUB GET.FINAL.ACCOUNT.POS         ;** get final occurence of account property

    PAY.DATE.I = 1
    PAYMENT.DATES = PAYMENT.DATES       ;* Reset internal pointer for next time through
    PAYMENT.METHODS = PAYMENT.METHODS
    PAYMENT.TYPES = PAYMENT.TYPES
    PAYMENT.FIN.DATES = PAYMENT.FIN.DATES       ;* Reset internal pointer for next time through
    PAYMENT.AMOUNTS = PAYMENT.AMOUNTS
    HOLIDAY.PAYMENT.AMOUNTS = HOLIDAY.PAYMENT.AMOUNTS ;* Assigning holiday amounts
    PAYMENT.PROPERTIES = PAYMENT.PROPERTIES
    PAYMENT.DEFER.DATES = PAYMENT.DEFER.DATES
    PAYMENT.PERCENTAGES = PAYMENT.PERCENTAGES
    PARTICIPANT.IDS = PARTICIPANT.IDS
    PARTICIPANTS.ACCT.MODE = PARTICIPANTS.ACCT.MODE
    PARTICIPANT.PARTICIPATION.TYPES = PART.PARTICIPATION.TYPE
    PART.PAYMENT.PROPERTIES = ''                ;* Participant Properties list
    FINAL.PRINCIPAL.POS = 0
    ZERO.PRINCIPAL.POS = ''
    EXIT.LOOP = ""
    SAVE.CALC.AMT = ""
    PROCESS.SCHEDULES = 1     ;* Flag to indicate whether to process schedules
    RESIDUAL.DATES = ""
    RESIDUAL.AMOUNTS = ""
    LAST.PAYMENT.DATE = ""
    ADV.POS = ""    ;* Advance flag required to setup, Initialise the same
    RESIDUAL.DETAILS = SCHEDULE.INFO<9>
    BORROWER.TOT.DIS.AMT = ''
    BORROWER.INTEREST.PROPERTIES = ''
  
**Initialise the veriables to store the details of capitalised Interest/Charge for DUE.AND.CAP payment type
** If any excess cap amount then store that amount here! and the relavent details
    CAP.PAYMENT.AMOUNT.LIST = ""
    CAP.PAYMENT.PROPERTY.LIST = ""
    CAP.PAYMENT.METHOD.LIST = ""
    CAP.BILL.PAY.TYPE.LIST = ""
    CAP.PAYMENT.TYPE.LIST = ""
    CAP.PAYMENT.DATES = ""
    CAP.TAX.DETAILS.LIST = ""
    SKIP.PENALTY.INTEREST = ""
    SKIP.PENALTY.PROPERTY = ""
    CHECK.CLOSURE.ACTIVITY = 1 ;* Set the flag to avoid multiple checks to determine if the current activity is closure activity or not inside CalcInterest>AccrueInterest>GetBaseBalance
    HOLIDAY.PERIOD.POS = "" ;* Store Holiday date position from Payment Dates
    
    PROPERTY.TAX.DETAILS = ""
        
    NO.RES.CNT = DCOUNT(RESIDUAL.DETAILS, @VM)
    FOR RES.CNT = 1 TO NO.RES.CNT
        RESIDUAL.DATES<1,RES.CNT> = RESIDUAL.DETAILS<1,RES.CNT,1>
        RESIDUAL.AMOUNTS<1,RES.CNT> = RESIDUAL.DETAILS<1,RES.CNT,2>
    NEXT RES.CNT
    
    IF SCHEDULE.INFO<8> THEN            ;*From enquiry - project taking conditions till maturity date
        GOSUB GET.ALL.PAYMENT.SCHEDULE.RECORDS
    END
    
    LOOP
        REMOVE PAYMENT.DATE FROM PAYMENT.DATES SETTING YD
        REMOVE PAYMENT.FIN.DATE FROM PAYMENT.FIN.DATES SETTING FINPOS   ;* Update contract details based on financial date
        REMOVE CUR.PART.ID FROM PARTICIPANT.IDS SETTING PartPosVM
        REMOVE CUR.PART.ACCT.MODE FROM PARTICIPANTS.ACCT.MODE SETTING PartActPosVM
        REMOVE CUR.PART.PAYMENT.PROPERTIES FROM STORE.PART.PAYMENT.PROPERTIES SETTING PartPaymentPropPos ;*For each payment date, obtain the list of payment properties separated by * for each participant
        REMOVE CUR.PARTICIPATION.TYPE FROM PART.PARTICIPATION.TYPE SETTING PartTypePos
** Convert the participant payment properties back to the correct format
        CONVERT '~' TO @VM IN CUR.PART.PAYMENT.PROPERTIES
        CONVERT '_' TO @SM IN CUR.PART.PAYMENT.PROPERTIES
        
        GOSUB SAVE.BORROWER.AMOUNTS  ;* Save borrower related information to calculate participant amounts
        
    WHILE PAYMENT.DATE AND NOT(EXIT.LOOP)         ;* For each payment date/type/property, calcualte the payment amount
        IF PAYMENT.DATE LE DISBURSE.PROGRESSIVE.UPTO.DATE THEN ;*Build schedules only till progressive date
            INCLUDE.DISBURSE.SCHEDULE = 1
        END
        BEGIN CASE
            CASE NOT(INCLUDE.DISBURSE.SCHEDULE) OR NOT(OUTSTANDING.AMOUNT)
            CASE PAYMENT.DATE GT DISBURSE.PROGRESSIVE.UPTO.DATE ;*Build schedules only till progressive date
                INCLUDE.DISBURSE.SCHEDULE = ''
        END CASE
        CHANGE.RESIDUAL.POS = ''
        LOCATE PAYMENT.DATE IN RESIDUAL.DATES<1,1> BY "AL" SETTING RES.POS THEN
;* Multiple residual amounts will be defined incase of extend term scenario. For final payment date
;* and if the date equal to the renewal date, pick the correct residual amount.
;* For example 25000 & 5000 is respective residual amount effective from 01 Dec 2009 and 01 Jan 2010. Here only after the contract
;* is extended ie. from 01 JAN 2010, the residual amount should be picked as 5000 and not 25000.
            IF AA.Framework.getRArrangement()<AA.Framework.Arrangement.ArrLeaseType> AND (PAYMENT.DATE EQ PAYMENT.END.DATE AND PAYMENT.DATE EQ AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdRenewalDate>) THEN
                CHANGE.RESIDUAL.POS = 1
            END
        END ELSE
            CHANGE.RESIDUAL.POS = 1
        END
    
        IF CHANGE.RESIDUAL.POS THEN
            IF RES.POS GT 1 THEN
                RES.POS -= 1
            END
        END

        RESIDUAL.AMOUNT = RESIDUAL.AMOUNTS<1, RES.POS>

*** Assign the payment schedule record for payment date corresponding to the correct payment schedule effective date. For example if payment date is 30 DEC 2009
*** and the arr payment schedule exists for two dates 23 DEC 2009 and 23 JAN 2010 then this logic will assign the payment schedule record corresponding to 23 DEC 2009
        IF SCHEDULE.INFO<8> AND PS.EFFECTIVE.DATES THEN
            SAV.OLD.PS.REC = R.PAYMENT.SCHEDULE
            LOCATE PAYMENT.DATE IN PS.EFFECTIVE.DATES<1> BY "DN" SETTING PS.POS THEN
            END
            R.PAYMENT.SCHEDULE =  PS.PROPERTY.RECORDS<PS.POS>
            R.PAYMENT.SCHEDULE = RAISE(R.PAYMENT.SCHEDULE)
            IF NOT(R.PAYMENT.SCHEDULE) THEN
                R.PAYMENT.SCHEDULE = SAV.OLD.PS.REC           ;* If the record is blank in some reason then take it from Saved Variable.
            END
         
            IF R.PAYMENT.SCHEDULE NE SAV.OLD.PS.REC THEN
** These LOC are moved from GET.PAYMENT.SCHDEULE gosub because latest the R.PAYMENT.SCHEDULE record would be updated in BUILD.FORWARD.SCHDEULE gosub.
** The CALC.TYPE should be formed based on the correct R.PAYMENT.SCHEDULE record
** Get calculation and process types for the payment schedule record
                PROCESS.TYPES = ""        ;* Can be Manual or Calculated
                CALCULATION.TYPES = ""    ;*  Can be Constant, Linear, Actual
                EXTEND.CYCLES = ""        ;* Flag to indicate if the payment type needs to be projected even after maturity
                EXTEND.CYCLE = ""
                AA.PaymentSchedule.GetCalcType(R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsPaymentType>, CALCULATION.TYPES, PROCESS.TYPES, EXTEND.CYCLES)
                GOSUB GET.PAYMENT.MODES   ;* When we have multiple payment schedule PAYMENT.MODES should update from latest payment schedule.
                MIC.ARRAY = ''  ;* Re-initialise the variable if current processing record is different from old
                PROPERTY.DETAILS = ''   ;* Re-initialise the variable if current processing record is different from old
            END
        END

        GOSUB GET.ASSOC.PAY.DATA

        GOSUB SEQUENCE.PROPERTY.LIST    ;* Sequence the properties as Property Class to process
        GOSUB PROCESS.PAYMENT.FORWARD.SCHEDULES      ;* Calculate the amounts

        IF TEMP.AMOUNT AND TEMP.UPDATE.AMOUNT THEN
            GOSUB UPDATE.CAP.AMOUNT.IN.PRESENT.VALUE        ;* update once after process the entire properties present in same date.
        END

        IF PROCESS.PARTICIPANTS AND BORROWER.EXTENSION.NAME EQ 'BANK' THEN     ;* Store Borrower and Participant property amounts when called for BANK type
            GOSUB STORE.BORROWER.BANK.AMOUNT
        END
        
        IF PRODUCT.LINE MATCHES "ACCOUNTS":@VM:"ASSET.FINANCE":@VM:"LENDING":@VM:"DEPOSITS" THEN
            TRANS.TAX.LIST = ""             ;* Initialising transaction tax list
            UPDATE.TRANSACTION.TAX = ""     ;* Flag to indicate the updation of transaction list
            ProcessTax = AA.Framework.getProcessTax()         ;* Get whether PROCESS TAX activity type is present in the current actitivity
            IF ProcessTax OR SCHEDULE.INFO<8> THEN          ;* Allow if the process tax is in the activity or the call is from projection
                PROD.TAX.PROPERTY.COUNT = DCOUNT(TAX.PROPERTIES, @FM)
                FOR TAX.COUNT = 1 TO PROD.TAX.PROPERTY.COUNT    ;*Loop through tax in product
                    LOCATE TAX.PROPERTIES<TAX.COUNT> IN CONTAINER.TAX.PROPERTIES<1,1> SETTING TAX.PROP.POS THEN
                        GOSUB TAX.CALCULATION.FOR.PROCESS.TAX ; *Do tax calculation for container properties
                    END
                NEXT TAX.COUNT
            END
        END

        IF PAYMENT.PROPERTIES.AMT OR (PAYMENT.AMOUNT.LIST AND NOT(ISSUE.BILL.DATE)) OR PAY.DATE.I GT 1 THEN
            PAYMENT.PROPERTIES.AMT := @FM:BORROWER.PAYMENT.AMOUNT.LIST
            FINAL.PAYMENT.POS.AMT := @FM:BORROWER.POS.PAYMENT.AMOUNT.LIST  ;* append all the positive interest amounts
            FINAL.PAYMENT.NEG.AMT := @FM:BORROWER.NEG.PAYMENT.AMOUNT.LIST ;* append all the negative interest amounts
            PAYMENT.METHODS.NEW := @FM:BORROWER.PAYMENT.METHOD.LIST
            TAX.DETAILS := @FM:BORROWER.TAX.DETAILS.LIST
            PARTICIPANTS.DETAILS := @FM:TEMP.PARTICIPANTS.DETAILS
            PARTICIPANT.PROPERTIES.AMT := @FM:TEMP.PARTICIPANT.PROPERTIES.AMT
            PARTICIPANT.TAX.DETAILS := @FM:TEMP.PARTICIPANT.TAX.DETAILS
            PART.PAYMENT.PROPERTIES := @FM:TEMP.PARTICIPANT.PROPERTIES.LIST
        END ELSE
            PAYMENT.PROPERTIES.AMT = BORROWER.PAYMENT.AMOUNT.LIST
            FINAL.PAYMENT.POS.AMT = BORROWER.POS.PAYMENT.AMOUNT.LIST ;* get the positive interest amounts
            FINAL.PAYMENT.NEG.AMT = BORROWER.NEG.PAYMENT.AMOUNT.LIST ;* get the negative interest amounts
            PAYMENT.METHODS.NEW = BORROWER.PAYMENT.METHOD.LIST
            TAX.DETAILS = BORROWER.TAX.DETAILS.LIST
            PARTICIPANTS.DETAILS = TEMP.PARTICIPANTS.DETAILS
            PARTICIPANT.PROPERTIES.AMT = TEMP.PARTICIPANT.PROPERTIES.AMT
            PARTICIPANT.TAX.DETAILS = TEMP.PARTICIPANT.TAX.DETAILS
            PART.PAYMENT.PROPERTIES = TEMP.PARTICIPANT.PROPERTIES.LIST
        END
    
        IF PROJECT.END.AMOUNT NE "" THEN          ;*Ensure we project only upto this amount
            SCHEDULED.AMOUNT = PAYMENT.AMOUNT.LIST          ;*Full property's amounts
            CONVERT @SM TO @VM IN SCHEDULED.AMOUNT  ;*Maintain with similar delimiter
            PROJECT.END.AMOUNT -= SUM(SCHEDULED.AMOUNT)     ;*Store remaining amount to project after current repayment
            IF PROJECT.END.AMOUNT LE 0 THEN       ;*Fully utilised - no need to project anymore
                EXIT.LOOP = 1 ;*stop any more projection beyond this point
            END
        END

        IF SCHEDULE.INFO<51> AND SCHEDULE.INFO<8> AND DEFER.ALL.HOLIDAY.FLAG AND NOT(HOLIDAY.PROP.AMT.FLAG) THEN
            TEMP.PAYMENT.AMOUNT.LIST = PAYMENT.AMOUNT.LIST
            CONVERT @VM TO @SM IN TEMP.PAYMENT.AMOUNT.LIST
            IF SUM(TEMP.PAYMENT.AMOUNT.LIST) EQ '0' THEN ;* delete the date only when all the properties are holiday. there could be some restricted property as well.
                HOLIDAY.PERIOD.POS<-1> = PAY.DATE.I
            END
        END
    
        GOSUB UPDATE.OUTSTANDING.AMOUNT ;* Update the outstanding amount for the payment date

        IF PROCESS.PARTICIPANTS AND BORROWER.EXTENSION.NAME EQ 'BANK' THEN     ;* Reset Borrower and Participant property amounts when called for BANK type
            GOSUB RESET.BORROWER.BANK.AMOUNT
        END
    
        IF (PRESENT.VALUE - RESIDUAL.AMOUNT) LE 0 AND NOT(FINAL.PRINCIPAL.POS) THEN
            FINAL.PRINCIPAL.POS = PAY.DATE.I      ;*store the mv position
            ZERO.PRINCIPAL.POS = PAY.DATE.I
        END
        PAY.DATE.I += 1

        BILL.DETAILS = ""
        
    REPEAT

    IF NOT(FINAL.PRINCIPAL.POS) THEN
        FINAL.PRINCIPAL.POS = NO.OF.PAYMENT.DATES
    END

    SAVE.NO.OF.PAYMENT.DATES = NO.OF.PAYMENT.DATES
    IF SCHEDULE.INFO<51> AND PAY.END.DATE.POS THEN   ;* IF Holiday is defined then schedule residual on payment end date
        NO.OF.PAYMENT.DATES = PAY.END.DATE.POS
    END
    
    ACCOUNT.PROPERTY.FOUND = ''
    FIND ACCOUNT.PROPERTY IN PAYMENT.PROPERTIES<NO.OF.PAYMENT.DATES> SETTING FMPOS,VMPOS,SMPOS THEN
**For Operating Lease type Asset Finance contract, Residual amount should be in Outstanding instead of Due
**If residual amount is present and it is operating lease then we donot project the residual amount as Due
        IF R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsResidualAmount> NE '' AND SCHEDULE.INFO<63> ELSE
            ACCOUNT.PROPERTY.FOUND = 1
            BEGIN CASE
**For INFO bill type,system should add the account property amount in residual amount.
                CASE PAYMENT.BILL.TYPES<NO.OF.PAYMENT.DATES, VMPOS, SMPOS> EQ "INFO"
                    GOSUB GET.OUTSTANDING.AMT
                CASE ADD.RESIDUAL AND SCHEDULE.INFO<40> EQ ''  ;* add the residual amount against the principal for the last schedule
                    OS.LAST.VALUE= OUTSTANDING.AMOUNT<NO.OF.PAYMENT.DATES>
                    IF OS.LAST.VALUE THEN
                        PAYMENT.PROPERTIES.AMT<NO.OF.PAYMENT.DATES,VMPOS,SMPOS> = PAYMENT.PROPERTIES.AMT<NO.OF.PAYMENT.DATES,VMPOS,SMPOS> + OS.LAST.VALUE
                        OUTSTANDING.AMOUNT<NO.OF.PAYMENT.DATES> = OUTSTANDING.AMOUNT<NO.OF.PAYMENT.DATES>-OUTSTANDING.AMOUNT<NO.OF.PAYMENT.DATES>
;* when holiday is defined we might have made outstanding as 0 for a previous date as payment end date maybe earlier than total schedules, hence last outstanding must also be made 0
                        IF SCHEDULE.INFO<51> THEN
                            OUTSTANDING.AMOUNT<SAVE.NO.OF.PAYMENT.DATES> = OUTSTANDING.AMOUNT<SAVE.NO.OF.PAYMENT.DATES>-OUTSTANDING.AMOUNT<SAVE.NO.OF.PAYMENT.DATES>
                        END
                        IF SCHEDULE.INFO<69> NE '' AND R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsResidualAmount> NE '' THEN
** For SCHEDULE.INFO<69> set for cashflow Lease contracts ,when residual amount is available it should not display under Account or Interest property as new cashflow types PRINICPAL-URV and PRINCIPAL-GRV holds the residual amount.
                            PAYMENT.PROPERTIES.AMT<NO.OF.PAYMENT.DATES,VMPOS,SMPOS> = PAYMENT.PROPERTIES.AMT<NO.OF.PAYMENT.DATES,VMPOS,SMPOS> - R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsResidualAmount>
                        END
                        IF PARTICIPANT.OUTSTANDING.AMT<NO.OF.PAYMENT.DATES> THEN
                            GOSUB HANDLE.RESIDUAL.PROCESSING.FOR.PARTICIPANTS ;*Add participant residual amount in last schedule
                        END
                    END
            END CASE
        END
    END ELSE
        GOSUB GET.OUTSTANDING.AMT
        
    END
    
    NO.OF.PAYMENT.DATES = SAVE.NO.OF.PAYMENT.DATES ;* Restore the no.of.payment.dates
    
    IF PAYMENT.METHODS NE PAYMENT.METHODS.NEW THEN
        PAYMENT.METHODS = PAYMENT.METHODS.NEW
    END

** If flag is set return the details of capitalised Interest/Charge for DUE.AND.CAP payment type
    IF RET.PARTIAL.CAP.DETAIL THEN         ;* once all the dates have been processed we would have collected all the due and cap data
        GOSUB ADD.PART.CAP.DETAILS      ;*  now if the flag is set to return this data we will add the stored data to the output arguments
    END
        
    SCHEDULE.INFO<10> = ZERO.PRINCIPAL.POS        ;* Flag indicates account property remaining amount value goes to less than current bill account property amount
    IF AA.Framework.getFixedInterest() THEN
        IF SCHEDULE.INFO<8> THEN
            AA.Framework.setFixedInterest('') ;* Reset the common variable as the scope of this lies only within the projection
        END ELSE
            tmp=AA.Framework.getFixedInterest(); tmp<4>=''; AA.Framework.setFixedInterest(tmp) ;* Reset 4th position of common variable AA$FIXED.INTEREST as this is required only within the schedules.
        END
    END

    IF POS.NEG.FLAG EQ "FETCH.POS.NEG" THEN
        ADJUST.FINAL.AMOUNT<2> = LOWER(FINAL.PAYMENT.POS.AMT) ;* return the positive amounts for all payment dates after lowering as we are appending the amounts under FM
        ADJUST.FINAL.AMOUNT<3> = LOWER(FINAL.PAYMENT.NEG.AMT) ;* return the negative amounts for all payment dates after lowering as we are appending the amounts under FM
    END
    R.PAYMENT.SCHEDULE = SAV.PS.REC         ;* restore the payment schedule record
    
    IF HOLIDAY.PERIOD.POS AND SCHEDULE.INFO<8> THEN
        GOSUB DELETE.PAYMENT.HOL.PERIOD.DETAILS
    END
       
RETURN
*** </region>

*-----------------------------------------------------------------------------
*** <region name= Get Outstanding amount>
*** <desc>Get the residual amount</desc>
GET.OUTSTANDING.AMT:
    
    BEGIN CASE
        CASE RESIDUAL.AMOUNT AND ADD.RESIDUAL
** Since we have to display the residual against the principal, if we have the residual amount for any contract then insert the account property
** and add the residual amount against this and here as well make the last outstanding as zero
            INS ACCOUNT.PROPERTY BEFORE PAYMENT.PROPERTIES<NO.OF.PAYMENT.DATES,1>
            INS RESIDUAL.AMOUNT BEFORE PAYMENT.PROPERTIES.AMT<NO.OF.PAYMENT.DATES,1>
            FIND ACCOUNT.PROPERTY IN PAYMENT.PROPERTIES<NO.OF.PAYMENT.DATES> SETTING FMPOS,VMPOS,SMPOS THEN
                IF ADD.RESIDUAL AND SCHEDULE.INFO<40> EQ '' THEN
                    OUTSTANDING.AMOUNT<NO.OF.PAYMENT.DATES> = OUTSTANDING.AMOUNT<NO.OF.PAYMENT.DATES>-OUTSTANDING.AMOUNT<NO.OF.PAYMENT.DATES>
;* when holiday is defined we might have made outstanding as 0 for a previous date as payment end date maybe earlier than total schedules, hence last outstanding must also be made 0
                    IF SCHEDULE.INFO<51> THEN
                        OUTSTANDING.AMOUNT<SAVE.NO.OF.PAYMENT.DATES> = OUTSTANDING.AMOUNT<SAVE.NO.OF.PAYMENT.DATES>-OUTSTANDING.AMOUNT<SAVE.NO.OF.PAYMENT.DATES>
                    END
                END
            END
        
        CASE SCHEDULE.INFO<8> AND (OUTSTANDING.AMOUNT<NO.OF.PAYMENT.DATES>) AND PRODUCT.LINE EQ 'LENDING' AND PAYMENT.DATES<NO.OF.PAYMENT.DATES> EQ AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdPaymentEndDate> AND NOT(SCHEDULE.INFO<71>) AND (ACCOUNT.PROPERTY.FOUND OR SCHEDULE.INFO<42> OR ADD.RESIDUAL)
*** Only if the account property defined in payment schedule, Residual principal payment type should be projected and also for cashflow we are projecting the residual bill
*** SCHEDULE.INFO<71> is passed to identify the flow from LI.CASHFLOW for drawings. Hence we are skipping the execution for facility committment
*** Eventhough the ADD.RESIDUAL flag is set, but because of account property doesn't available for the last payment date(issue occurs when on single payment date is available for account property in a past shedule and monthly frequency for interest. so till maturity date the interest property is avaible for the payment dates but account property is not) and SCHEDULE.INFO<42> being only when Cashflow.Handoff. so if ADD.RESIDUAL flag is available do add the RESIDUAL.PRINCIPAL.
            INS "RESIDUAL.PRINCIPAL" BEFORE PAYMENT.TYPES<NO.OF.PAYMENT.DATES,1>
            INS "DUE" BEFORE PAYMENT.METHODS.NEW<NO.OF.PAYMENT.DATES,1>
            INS ACCOUNT.PROPERTY BEFORE PAYMENT.PROPERTIES<NO.OF.PAYMENT.DATES,1>
            INS OUTSTANDING.AMOUNT<NO.OF.PAYMENT.DATES> BEFORE PAYMENT.PROPERTIES.AMT<NO.OF.PAYMENT.DATES,1>
            OUTSTANDING.AMOUNT<NO.OF.PAYMENT.DATES> = OUTSTANDING.AMOUNT<NO.OF.PAYMENT.DATES>-OUTSTANDING.AMOUNT<NO.OF.PAYMENT.DATES>
;* when holiday is defined we might have made outstanding as 0 for a previous date as payment end date maybe earlier than total schedules, hence last outstanding must also be made 0
            IF SCHEDULE.INFO<51> THEN
                OUTSTANDING.AMOUNT<SAVE.NO.OF.PAYMENT.DATES> = OUTSTANDING.AMOUNT<SAVE.NO.OF.PAYMENT.DATES>-OUTSTANDING.AMOUNT<SAVE.NO.OF.PAYMENT.DATES>
            END
*** When we have Interest only payment defined along with the Residual amount then we will not have Account portion in the schedule.
*** In such cases we we project the cashflow then we must not consider the residual amount since residual amount will be shown separately.
*** For SCHEDULE.INFO<69> set for cashflow Lease contracts ,when residual amount is available it should not display under Account or Interest property as new cashflow types PRINICPAL-URV and PRINCIPAL-GRV holds the residual amount.
        CASE RESIDUAL.AMOUNT AND SCHEDULE.INFO<69> AND NOT(ACCOUNT.PROPERTY.FOUND) AND OUTSTANDING.AMOUNT<NO.OF.PAYMENT.DATES> NE "0"
            OUTSTANDING.AMOUNT<NO.OF.PAYMENT.DATES> =  OUTSTANDING.AMOUNT<NO.OF.PAYMENT.DATES> - RESIDUAL.AMOUNT
    END CASE
        

RETURN
*** </region>

*-----------------------------------------------------------------------------
*** <region name= DELETE.PAYMENT.HOL.PERIOD.DETAILS>
*** <desc>During Projector, we need to skip payment holiday period schedule when full period is holiday in PH setup</desc>
DELETE.PAYMENT.HOL.PERIOD.DETAILS:
    
    LOOP
        REMOVE PAY.HOL.PERIOD FROM HOLIDAY.PERIOD.POS SETTING PAY.HL.POS
    WHILE PAY.HOL.PERIOD
        DEL PAYMENT.DATES<HOLIDAY.PERIOD.POS<1>>
        DEL PAY.FIN.DATES<HOLIDAY.PERIOD.POS<1>>
        DEL PAYMENT.TYPES<HOLIDAY.PERIOD.POS<1>>
        DEL PAYMENT.METHODS<HOLIDAY.PERIOD.POS<1>>
        DEL PAYMENT.PROPERTIES<HOLIDAY.PERIOD.POS<1>>
        DEL PAYMENT.AMOUNTS<HOLIDAY.PERIOD.POS<1>>
        DEL PAYMENT.PROPERTIES.AMT<HOLIDAY.PERIOD.POS<1>>
        DEL TAX.DETAILS<HOLIDAY.PERIOD.POS<1>>
        DEL OUTSTANDING.AMOUNT<HOLIDAY.PERIOD.POS<1>>
    REPEAT

RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= Get All payment schedule records>
*** <desc>Get all the Payment schedule records</desc>
GET.ALL.PAYMENT.SCHEDULE.RECORDS:

** Get all the payment Schedule record those are created from the arrangement start date.
    
    TEMP.PS.EFFECTIVE.DATES = EFFECTIVE.DATE:@FM:COND.DATE    ;* From Date - Arrangement value date, To date - Maturity date
    AA.Framework.BuildPropertyRecords(ARRANGEMENT.ID, PROPERTY, "PAYMENT.SCHEDULE", TEMP.PS.EFFECTIVE.DATES, TEMP.PS.PROPERTY.RECORDS)
    
    GOSUB CHECK.PS.DATES.RECORDS

RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= Check PS Dates Records>
*** <desc>Check payment schedule dates & records</desc>
CHECK.PS.DATES.RECORDS:

** Suppose TempPsEffectiveDates having the future dated dates & TempPsPropertyRecords not having the PS condition record
** for pariculor date then make the PsEffectiveDate also Null.

    NO.PS.DATES = DCOUNT(TEMP.PS.EFFECTIVE.DATES, @FM)

    FOR PS.DATE = 1 TO NO.PS.DATES
        IF TEMP.PS.PROPERTY.RECORDS<PS.DATE> NE "" THEN
            PS.EFFECTIVE.DATES<-1> = TEMP.PS.EFFECTIVE.DATES<PS.DATE>
            PS.PROPERTY.RECORDS<-1> = TEMP.PS.PROPERTY.RECORDS<PS.DATE>
        END
    NEXT PS.DATE

RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= PROCESS.PAYMENT.FORWARD.SCHEDULES>
PROCESS.PAYMENT.FORWARD.SCHEDULES:
*** <desc>Calculate the amounts</desc>
                          
    PART.ID = BORROWER.ID
    PART.ACCT.MODE = 'MEMO'
    TEMP.AMOUNT = ''
    TEMP.UPDATE.AMOUNT = ''
    PART.TEMP.AMOUNT = ''
    PART.TEMP.UPDATE.AMOUNT = ''
    PART.PARTICIPANT.TYPE = ''
    BOOK.BANK.PROCESSING = ''
    DEFER.ALL.HOLIDAY.FLAG = 0    ;* Check Defer All Flag present in account details for corresponding payment type and payment holiday date
    HOLIDAY.PROP.AMT.FLAG = '' ;* Found Holiday Property amount defined in the Payment holiday for the corresponding payment holiday date.
    IF PROCESS.PARTICIPANTS THEN        ;* If valid participants exists then get outstanding amount for all the participants
        PART.ID := '*':CUR.PART.ID
        PART.ACCT.MODE := '*':CUR.PART.ACCT.MODE
        PART.PARTICIPANT.TYPE := '*':CUR.PARTICIPATION.TYPE
        TEMP.PARTICIPANTS.DETAILS = ''
        TEMP.PARTICIPANT.PROPERTIES.AMT = ''
        TEMP.PARTICIPANT.TAX.DETAILS = ''
        TEMP.PARTICIPANT.PROPERTIES.LIST = ''
        NEW.PART.LIST = ''
        NEW.PART.ACCT.MODE.LIST = ''
        NEW.PART.PARTICIPANT.TYPE = ''
        BOOK.CUST.POS = ''
        BOOK.BANK.POS = ''
        SUB.PART.TAX.DETAILS.LIST = ''
        STORE.CALC.AMOUNT = '' ;*Variable to store calc amount which we can use for each particpant
    END
    CONVERT '*' TO @VM IN PART.ID           ;* ParticipantList for Current PaymentDate
    CONVERT '*' TO @VM IN PART.ACCT.MODE;* ParticipantAccountingModeList for Current PaymentDate
    CONVERT '*' TO @VM IN PART.PARTICIPANT.TYPE;* ParticipationType for Current PaymentDate
    
    IS.PARTICIPANT = 0
*reinitialise Borrower details for every PaymentDate
    GROSS.ACCOUNT.PAY = '' ;* Flag to indicate gross account pay for tax calculation.
    BORROWER.PAYMENT.AMOUNT.LIST = ''
    BORROWER.PAYMENT.METHOD.LIST = ''
    BORROWER.TAX.DETAILS.LIST = ''
    BORROWER.PERIOD.START.DATE = ''
    BORROWER.PERIOD.END.DATE = ''
    BORROWER.LAST.PAYMENT.DATE = ''
** Storing the borrower property list before participants loop so that there's no impact on the existing borrower logic
    BORROWER.PROPERTY.LIST = PAYMENT.PROPERTY.LIST
    
* When SUB.TYPE called with BANK, Borrower and Participants will have no BANK balance and BOOK need to be populated with BANK balance.
* To arrive at BOOK-BANK properties amt and outstanding amounts, borrower should be processed with CUST balances and OWN bank should be processed with 2 options, one with OWN cust another one with OWN bank.
* so append BOOK-BANK to Participants list when called for SubType BANK
    IF PROCESS.PARTICIPANTS AND BORROWER.EXTENSION.NAME EQ 'BANK' THEN
        FOR PF.CNT = 1 TO DCOUNT(PART.ID, @VM)
            NEW.PART.LIST<1,-1> = PART.ID<1,PF.CNT>
            NEW.PART.ACCT.MODE.LIST<1,-1> = PART.ACCT.MODE<1,PF.CNT>
            NEW.PART.PARTICIPANT.TYPE<1,-1> = PART.PARTICIPANT.TYPE<1,PF.CNT>
            IF FIELD(PART.ID<1,PF.CNT>, '-',1) EQ 'BOOK' THEN
                NEW.PART.LIST<1,-1> = PART.ID<1,PF.CNT>:'-BANK'
                NEW.PART.ACCT.MODE.LIST<1,-1> = 'REAL'
                NEW.PART.PARTICIPANT.TYPE<1,-1> = ''
            END
        NEXT PF.CNT
        PART.ID = NEW.PART.LIST
        PART.ACCT.MODE = NEW.PART.ACCT.MODE.LIST
        PART.PARTICIPANT.TYPE = NEW.PART.PARTICIPANT.TYPE
    END
    TOTAL.PARTICIPANTS = DCOUNT(PART.ID, @VM)
    BOOK.VALUE = ''
    
    FOR PART.COUNT = 1 TO TOTAL.PARTICIPANTS
            
        LAST.PAYMENT.DATE = ""
        ZERO.PRINCIPAL.POS = ''
        EXIT.LOOP = ""
        PROCESS.SCHEDULES = 1     ;* Flag to indicate whether to process schedules
        IS.PORTFOLIO = 0
        BOOK.BANK.PROCESSING = ''
        IF PART.ID<1,PART.COUNT> NE 'BORROWER' THEN
            GOSUB GET.PARTICIPANT.PAYMENT.PROPERTIES ;* Fetch payment properties for each participant
        END

        IF PROCESS.PARTICIPANTS AND BORROWER.EXTENSION.NAME EQ 'BANK' THEN     ;* Reset EXTENSION.NAME when called for BANK Subtype
            GOSUB POPULATE.PROPERTIES.LIST          ;* Populate BOOK properties list
            GOSUB CHECK.EXTENSION.NAME          ;*Check Extension name for each participants and borrower
        END
            
        PAYMENT.PROPERTY.AMOUNTS = ''   ;*Re-initialise - this will be populated by the local routine for every date
        CALCULATED.TYPE = ""  ;*Flag to indicate if this is an advance schedule
        HOLIDAY.AMOUNT = "" ;* To know holiday amount for each payment date
        PREV.PAY.TYPE.I = "" ;* To know different payment types for each holiday amount
        PROCESSED.PAY.TYPE = ""  ;* Holds the process types that were processed in the previous loops
        PROCESSED.PAY.TYPE.POS = ""  ;* Holds the payment type positions processed so far
        REMAINING.HOLIDAY.AMT = ""  ;* The holiday amount if update already
        HOLIDAY.DATE = "" ;* To know payment date skip
        TAX.DETAILS.LIST = ""
        TAX.LIST = ""
        ISSUE.BILL.DATE = ""   ;* flag to indicate that issue bill is present for first payment date and to add its amounts in its corresponding position in the returned array
        REDUCE.HOLAMT = "" ;* Flag to indicate Outstanding amount is shown properly in schedule projection for arrangement with Constant payment type and issue bill is present with Holiday Amount defined.
    
        IF SCHEDULE.INFO<28> THEN           ;* When participants exist
            TOT.TERM.AMT = SAVE.TOT.TERM.AMT<PART.COUNT>            ;*Save Tot TermAmount balance of Borrower or Participant
            CUR.TERM.AMT = SAVE.CUR.TERM.AMT<PART.COUNT>            ;*Save Cur TermAmount balance of Borrower or Participant
            AVAILABLE.COMMIT.AMT = SAVE.AVAILABLE.COMMIT.AMT<PART.COUNT>            ;*Save Available Commitment of Borrower or Participant
            IF PART.ID<1,PART.COUNT> EQ 'BORROWER' THEN             ;* for Borrower, reset the Total disbursement amount calculated while processing previous PaymentDate
                TOT.DIS.AMT = BORROWER.TOT.DIS.AMT
            END ELSE
                TOT.DIS.AMT = ''                                ;* reset to NULL for participant
            END
        END
        FOR PC.POS = 1 TO NO.PROPERTY.CLASS       ;* Process each property class in an order
            GOSUB PROCESS.FORWARD.SCHEDULES       ;* Calculate the amounts for Borrower and each Participant in current PaymentDate
        NEXT PC.POS
        
        IF PART.ID<1,PART.COUNT> EQ 'BORROWER' THEN
            BORROWER.PAYMENT.PROPERTIES = BORROWER.PROPERTY.LIST        ;* Save Borrower PaymentProperties list for using while calculation ProRata for Participants
            BORROWER.PAYMENT.AMOUNT.LIST = PAYMENT.AMOUNT.LIST      ;* Save Borrower PaymentAmount list for using while calculation ProRata for Participants
            BORROWER.POS.PAYMENT.AMOUNT.LIST = PAYMENT.AMOUNT.POS.LIST
            BORROWER.NEG.PAYMENT.AMOUNT.LIST = PAYMENT.AMOUNT.NEG.LIST
            BORROWER.PAYMENT.METHOD.LIST =  PAYMENT.METHOD.LIST
            BORROWER.TAX.DETAILS.LIST = TAX.DETAILS.LIST
        END ELSE
            IF TEMP.PARTICIPANTS.DETAILS THEN
                TEMP.PARTICIPANTS.DETAILS := '*':PART.ID<1,PART.COUNT>              ;* ParticipantsList each separated by '*'
                TEMP.PARTICIPANT.PROPERTIES.AMT := '*':PAYMENT.AMOUNT.LIST      ;* Calculated amount for Participants separated by '*'
                TEMP.PARTICIPANT.TAX.DETAILS := '*':TAX.DETAILS.LIST            ;* Tax details for Participants separated by '*'
                TEMP.PARTICIPANT.PROPERTIES.LIST := '*':PAYMENT.PROPERTY.LIST
            END ELSE
                TEMP.PARTICIPANTS.DETAILS = PART.ID<1,PART.COUNT>
                TEMP.PARTICIPANT.PROPERTIES.AMT = PAYMENT.AMOUNT.LIST
                TEMP.PARTICIPANT.TAX.DETAILS = TAX.DETAILS.LIST
                TEMP.PARTICIPANT.PROPERTIES.LIST = PAYMENT.PROPERTY.LIST
            END
        END

    NEXT PART.COUNT
    PAYMENT.PROPERTY.LIST = BORROWER.PROPERTY.LIST ;*Restoring the Borrower property list once all the participants are processed
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= Update capitalised amount in present value>
*** <desc>Update capitalised amount in present value and contract details</desc>

UPDATE.CAP.AMOUNT.IN.PRESENT.VALUE:
** We need to update the present value and contract details at the end of entire properties get processed which are defined in same payment date.
** Otherwise system will consider balance for issuing bill and capitalization another property which comes for process on the same date.
** Which will create difference between actual accrual amount capitalized amount.

    SAVE.IS.PARTICIPANT = IS.PARTICIPANT    ;* store Participant loop variables before processing for borrower
    SAVE.PART.POS = PART.POS
    
    SAV.PAYMENT.METHOD = PAYMENT.METHOD
    PAYMENT.METHOD= 'CAPITALISE'
    TEMP.CAP.PAYMENT.TYPE = 1
    IF PROCESS.PARTICIPANTS THEN
        GOSUB UPDATE.CAP.AMT.IN.PART.PRESENT.VALUE  ;* Update capitalised amount in participant present value and contract details
    END ELSE
        UPDATE.AMOUNT = TEMP.UPDATE.AMOUNT
        AMOUNT = TEMP.AMOUNT
        PRESENT.VALUE = PRESENT.VALUE + UPDATE.AMOUNT       ;* Add the capitalised anount to the outstanding principal
        GOSUB UPDATE.CONTRACT.DETAILS
    END
    PAYMENT.METHOD = SAV.PAYMENT.METHOD
 
    TEMP.AMOUNT = ''
    TEMP.UPDATE.AMOUNT = ''
    TEMP.CAP.PAYMENT.TYPE = ''
    PART.TEMP.AMOUNT = ''
    PART.TEMP.UPDATE.AMOUNT = ''
    IS.PARTICIPANT = SAVE.IS.PARTICIPANT        ;*restore participant loop variables
    PART.POS = SAVE.PART.POS
   
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= Update capitalised amount in participant present value>
*** <desc>Update capitalised amount in present value and contract details</desc>
UPDATE.CAP.AMT.IN.PART.PRESENT.VALUE:

* Update Present value and contract details for borrower
    IS.PARTICIPANT = 0
    PART.POS = 1
    UPDATE.AMOUNT = TEMP.UPDATE.AMOUNT
    AMOUNT = TEMP.AMOUNT
    PRESENT.VALUE = PRESENT.VALUE + UPDATE.AMOUNT       ;* Add the capitalised anount to the outstanding principal
    GOSUB UPDATE.CONTRACT.DETAILS

* Update contract details and present value for each participant
    CONVERT '*' TO @VM IN CUR.PART.ID
    PRT.COUNT = DCOUNT(CUR.PART.ID,@VM)
    FOR PRT.CNT = 1 TO PRT.COUNT
        IS.PARTICIPANT = 1
        UPDATE.AMOUNT = PART.TEMP.UPDATE.AMOUNT<1,PRT.CNT>
        AMOUNT = PART.TEMP.AMOUNT<1,PRT.CNT>
        PARTICIPANT.PRESENT.VALUE<1,PRT.CNT> = PARTICIPANT.PRESENT.VALUE<1,PRT.CNT> + UPDATE.AMOUNT       ;* Add the capitalised anount to the outstanding principal
        PART.POS = PRT.CNT
        GOSUB UPDATE.CONTRACT.DETAILS
    NEXT PRT.CNT

RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= Get Bill Details>
*** <desc>Get Bill Details</desc>
GET.BILL.DETAILS:

    BILL.DETAIL = ""
    SPECIAL.PROCESSING = ""
    PROCESS.FLAG = ''
    SCHD.TYPE = PAYMENT.TYPE:"-":PAYMENT.PROPERTY
    LOCATE SCHD.TYPE IN STORE.SCHD.TYPE<1,1> SETTING SCHD.POS ELSE
        STORE.SCHD.TYPE<1,SCHD.POS> = SCHD.TYPE
        PROCESS.FLAG = 1
    END
    
** If called from Iteration/projection
** Invoke GetBill if it is a valid ArrangementId
    IF GET.BILL.REQUIRED AND PROCESS.FLAG AND ARRANGEMENT.ID NE 'DUMMY' THEN
** Get system bill type.
        BILL.TYPE = PAY.BILL.TYPE
        LOCATE BILL.TYPE IN BILL.TYPE.ARRAY<1,1> SETTING BILL.TYPE.POS THEN
            PAY.BILL.TYPE = BILL.TYPE.ARRAY<2, BILL.TYPE.POS>
        END ELSE
            AA.PaymentSchedule.GetSysBillType(BILL.TYPE, PAY.BILL.TYPE, '')
            BILL.TYPE.ARRAY<1,-1> = BILL.TYPE
            BILL.TYPE.ARRAY<2,-1> = PAY.BILL.TYPE
        END
    
        BILL.TYPE = 'PAYMENT'
        IF PAY.BILL.TYPE EQ 'DISBURSEMENT' THEN
            BILL.TYPE = 'DISBURSEMENT'
        END

* Get Bill details for the given payment date
        BILL.CNT = "0"
        AA.PaymentSchedule.GetBill(ARRANGEMENT.ID, "", PAYMENT.DATE, "", "", BILL.TYPE, "" , "ISSUED", "", "", "", "", BILL.REFERENCES, RET.ERROR)
        IF BILL.TYPE EQ "PAYMENT" AND BILL.REFERENCES THEN
            GOSUB CHECK.ISSUE.BILL.DATE ;* Check whether issue bill is present for the first payment date
        END
        IF BILL.REFERENCES THEN
            LOOP
                REMOVE BILL.REFERENCE FROM BILL.REFERENCES SETTING BILL.REF.POS
            WHILE BILL.REFERENCE
                AA.PaymentSchedule.GetBillDetails(ARRANGEMENT.ID, BILL.REFERENCE, BILL.DETAIL, RET.ERROR)
                BILL.DETAILS<-1> = LOWER(BILL.DETAIL)
                BILL.CNT = BILL.CNT + 1
            REPEAT
        END
    END

    IF ARRANGEMENT.ID NE 'DUMMY' THEN   ;* Invoke GetBill if it is a valid ArrangementId
        AA.PaymentSchedule.GetBill(ARRANGEMENT.ID, "", PAYMENT.DATE, "", "", "PAYMENT", "" , "ADVANCED", "", "", "", "", BILL.REFERENCES, RET.ERROR)      ;*By default check for advance Issued Bills
        IF NOT(BILL.REFERENCES) AND PROCESS.FLAG THEN        ;*Only if not, check for Issued Bills if any
            AA.PaymentSchedule.GetBill(ARRANGEMENT.ID, "", PAYMENT.DATE, "", "", "PAYMENT", "" , "ISSUED":@VM:"FINALISE", "", "", "", "", BILL.REFERENCES, RET.ERROR)    ;*By default check for advance Issued Bills
            GOSUB CHECK.ISSUE.BILL.DATE ;* Check whether issue bill is present for the first payment date
        END
        PAY.TYPE.FOUND = 0
        ADVANCE.BILL.DETAILS = ""
        HOL.PROP.AMT = ''
        BILL.PR.AMT = ''    ;* Flag to indicate Advance bill have PR amount
        LOOP
            REMOVE BILL.REFERENCE FROM BILL.REFERENCES SETTING BILL.REF.POS
        WHILE BILL.REFERENCE AND NOT(PAY.TYPE.FOUND)
            AA.PaymentSchedule.GetBillDetails(ARRANGEMENT.ID, BILL.REFERENCE, BILL.DETAIL, RET.ERROR)
            GOSUB GET.CALC.AMOUNT ;*Get system calculated amount from Bills
        REPEAT
    END

RETURN

*** </region>
*-----------------------------------------------------------------------------
*** <region name= Get Calc amount>
*** <desc>Get calculated amount</desc>
GET.CALC.AMOUNT:

    ADVANCE.FLAG = ''
** Constant type, ACCOUNT's CALC.AMOUNT is retrived which is stored in CONSTANT.PRIN.AMOUNT.
    IF CALC.AMOUNT EQ "" AND CALC.TYPE EQ "CONSTANT" AND PROPERTY.CLASS.TO.PROCESS<PC.POS> EQ "ACCOUNT" THEN
        CALC.AMOUNT = CONSTANT.PRIN.AMOUNT
    END
    SPECIAL.PROCESSING = '' ;*Initialise to null
    LOCATE PAYMENT.TYPE IN BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdPaymentType, 1> SETTING BILL.PAY.POS THEN   ;*Check for the current advance payment type
       
        IF BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdPaymentMethod, BILL.PAY.POS> EQ PAYMENT.METHOD THEN   ;*For DUE.AND.CAP payment type there can be multiple payment types falling on same date hence current processing payment method should be same as billpayment method
        
            IF BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdBillStatus,1> EQ "ADVANCED" THEN        ;*Check for existence of advance bills
** Fetch Interest amount settled towards ADVANCED bill.
                ADV.SETTLED.INT.AMT = SCHEDULE.INFO<74>
                GOSUB CHECK.SPECIAL.PROCESSING        ;*Check if this is for special processing (Linear + Int only)
                ADVANCE.BILL.DETAILS<-1> = LOWER(BILL.DETAIL)   ;*There can be multiple advance bills. Store this so that we compare the correct one for charge processing
** In some cases like partial repayment towards advance bills, while doing the second partial repayment projection amount miss
** the account property amount since the calc amount goes negative here due to the bill repay amount without considering the actual property that has been repaid.
                IF SUM((BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdOrPrAmt>)) THEN
                    BILL.PR.AMT = 1   ;* Flag to indicate Advance bill have PR amount
                    GOSUB GET.REPAY.PAY.TYPE          ;* Get the repayment amount from the respective payment type property in case of advance bills
                    BILL.OS.TOTAL.AMT = BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdPaymentAmount, BILL.PAY.POS> - BILL.REPAY.AMOUNT
                END ELSE
                    BILL.REPAY.AMOUNT = BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdRepayAmount>       ;*Repay reference for advance bill
                    CONVERT @SM TO @VM IN BILL.REPAY.AMOUNT ;*Get same delimiter across
                    BILL.OS.TOTAL.AMT = BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdOrTotalAmount> - SUM((BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdOrPrAmt>)) - SUM(BILL.REPAY.AMOUNT) ;*This is the total outstanding amount for the bill less escrow
                END
                IF CALC.AMOUNT = "" AND (CALC.TYPE MATCHES "CONSTANT":@VM:"PROGRESSIVE":@VM:"ACCELERATED":@VM:"PERCENTAGE":@VM:"FIXED EQUAL" OR SPECIAL.PROCESSING) THEN   ;*Check for existence of advance bills
                    CALC.AMOUNT =  BILL.OS.TOTAL.AMT  ;*We need to repay only the outstanding bills at this point.
                    CALCULATED.TYPE = 1     ;*Indicates the bill is either issued or settled in advance
                END
                IF SPECIAL.PROCESSING AND PAYMENT.AMOUNT.LIST<1,PAY.TYPE.I> AND ACTIVITY.ACTION EQ "MAKE.DUE" AND CALC.AMOUNT THEN
;* When advance repayment is done partially on a linear and interest only bill, such that only a part of the linear portion is settled, there will a change in the interest recalculated based on the new principal, the excess interest amount in the advance bill
;* is added to the principal, but there is actual amount specified for the principal which is exceeded in this case and is incorrect, hence when there is an actual amount , the same has to be considered in order to make the bill due.
                    ACT.AMT = PAYMENT.AMOUNT.LIST<1,PAY.TYPE.I>
                    LOCATE PAYMENT.PROPERTY IN BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdProperty,1> SETTING BILL.PROP.POS THEN
                        PROP.REPAY.AMT = SUM(BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdRepayAmount,BILL.PROP.POS>)
                        ACT.AMT = ACT.AMT - PROP.REPAY.AMT
                        IF CALC.AMOUNT GT ACT.AMT THEN
                            CALC.AMOUNT = ACT.AMT
                        END
                    END
                END
                IF CALC.AMOUNT EQ '' AND SPECIAL.PROCESSING THEN
                    IF BILL.OS.TOTAL.AMT LT 0 AND CALC.TYPE THEN ;* For Linear and interest only payment,settled unearned int not set unaccrued int portion will settle towards linear so remaining amount should not be -ve
                        BILL.OS.TOTAL.AMT = 0
                    END
                    CALC.AMOUNT =  BILL.OS.TOTAL.AMT  ;*We need to repay only the outstanding bills at this point.
                    CALCULATED.TYPE = 1     ;*Indicates the bill is either issued or settled in advance
                END
            END ELSE    ;*Okay then check Issued Bills
                IF CALC.TYPE MATCHES "ACTUAL":@VM:"LINEAR" AND CALC.TYPE MATCHES SCHEDULE.INFO<17> THEN
                    ADVANCE.FLAG = 1    ;* Flag set to Calculate amount only during Advance payments
                END
                BEGIN CASE
                    CASE CALC.AMOUNT EQ "" AND (CALC.TYPE MATCHES "CONSTANT":@VM:"PROGRESSIVE":@VM:"ACCELERATED":@VM:"PERCENTAGE":@VM:"FIXED EQUAL" OR ADVANCE.FLAG)
                        GOSUB GET.BILL.CALC.AMOUNT
*** For Corporate loans,we didnt found any scenarios related to Advanced bills,so currently proceeding with Issue bills alone
                        STORE.CALC.AMOUNT = CALC.AMOUNT
                    CASE PAYMENT.TYPE EQ "HOLIDAY.INTEREST"
                        GOSUB GET.HOL.INT.BILL.AMOUNT
                END CASE
                    
            END
            PAY.TYPE.FOUND = 1    ;*We have found the payment type. Keep the Bill Detail for further use
 
        END
    END

RETURN

*** </region>
*-----------------------------------------------------------------------------
*** <region name= GET.LINEAR.ADV.CALC.AMOUNT>
*** <desc>Get bill repay amount for advance type bill with linear</desc>
GET.LINEAR.ADV.CALC.AMOUNT:
    
    IF BILL.DETAILS<AA.PaymentSchedule.BillDetails.BdOrPrAmt, BILL.PAY.POS> THEN
        BILL.REPAY.AMOUNT = BILL.DETAILS<AA.PaymentSchedule.BillDetails.BdOrPrAmt, BILL.PAY.POS> - BILL.DETAILS<AA.PaymentSchedule.BillDetails.BdOsPrAmt, BILL.PAY.POS>
    END ELSE
        BILL.REPAY.AMOUNT = 0
    END
        
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= GET BILL CALC AMOUNT>
*** <desc>Get bill calc amount</desc>
GET.BILL.CALC.AMOUNT:

    CALC.AMOUNT = BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdPaymentAmount, BILL.PAY.POS>
    IF NOT(CALC.AMOUNT) AND SCHEDULE.INFO<51> THEN
        BILL.ADJUST.AMTS = BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdAdjustAmt, BILL.PAY.POS>
        BILL.ADJ.AMTS = BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdAdjustAmt>
        FOR BILL.ADJ.CNT = 1 TO DCOUNT(BILL.ADJ.AMTS, @VM)
            CALC.AMOUNT -= BILL.ADJ.AMTS<1, BILL.ADJ.CNT>  ;* If issued bills is made holiday then adjusted amount needs to be considered as calc amount for holiday interest calculation
        NEXT BILL.ADJ.CNT
    END
    LOCATE PAYMENT.PROPERTY IN BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdProperty,1> SETTING HOL.PROP.POS THEN
        ADJUST.REF = BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdAdjustRef,HOL.PROP.POS>
        HOL.PAYMENT.DATE = BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdPaymentDate>
        HOLIDAY.ADJUST.REF = INDEX(ADJUST.REF,'HOLIDAY',1)  ;* check if the property has got holiday information in the bill at any one instance
        IF HOLIDAY.ADJUST.REF THEN  ;* Holiday adjustment is present for the property!
            TOTAL.HOLIDAY.DATES = AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdHolidayDate>
            CONVERT @SM TO @VM IN TOTAL.HOLIDAY.DATES
            LOCATE HOL.PAYMENT.DATE IN TOTAL.HOLIDAY.DATES<1,1> SETTING MATCHED.HOL.POS ELSE  ;* holiday adjustment is there but the same is not present in account details,so dont consider the holiday amount in this case
                CALC.AMOUNT = ''
            END
        END
    END
    IF TAX.INCLUSIVE EQ "" THEN       ;*Beware - Ignore all tax amounts
        GOSUB GET.TAX.AMOUNT
    END
    CALCULATED.TYPE = 1     ;*Indicates the bill is either issued or settled in advance

                    
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= GET HOL INT BILL AMOUNT>
*** <desc>Get Holiday interest bill property amount</desc>
GET.HOL.INT.BILL.AMOUNT:
    
    LOCATE PAYMENT.PROPERTY IN BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdPayProperty,BILL.PAY.POS,1> SETTING HOL.PROP.POS THEN
        HOL.PROP.AMT = BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdOrPrAmt, BILL.PAY.POS, HOL.PROP.POS>
    END

RETURN

*** </region>
*-----------------------------------------------------------------------------

*** <region name= GET REPAY PAY TYPE>
*** <desc>Get the repayment amount from the respective payment type properties</desc>

GET.REPAY.PAY.TYPE:

    BILL.REPAY.AMOUNT = ''
    BILL.PAY.PROPERTY.CNT = DCOUNT(BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdPayProperty, BILL.PAY.POS>,@SM)

    FOR PAY.PROP.CNT = 1 TO BILL.PAY.PROPERTY.CNT

        PAY.PROPERTY = BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdPayProperty, BILL.PAY.POS, PAY.PROP.CNT>
        LOCATE PAY.PROPERTY IN BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdProperty, 1> SETTING PAY.PROPERTY.POS THEN
            IF BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdRepayAmount, PAY.PROPERTY.POS, 1> THEN
                BILL.REPAY.AMOUNT += SUM(BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdRepayAmount, PAY.PROPERTY.POS>)
            END
        END

    NEXT PAY.PROP.CNT

RETURN

*** </region>
*-----------------------------------------------------------------------------

*** <region name= Check Special processing>
*** <desc>Check special processing for Linear + Int only</desc>
CHECK.SPECIAL.PROCESSING:
    
    CONSTANT.FOUND = 0
    OTHER.TYPE.FOUND = 0
    TOTAL.TYPES = DCOUNT(BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdPaymentType>,@VM)
    FOR TYP.CNT = 1 TO TOTAL.TYPES UNTIL SPECIAL.PROCESSING
        CURR.BILL.PAYMENT.TYPE = BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdPaymentType, TYP.CNT>
        AA.PaymentSchedule.GetCalcType(CURR.BILL.PAYMENT.TYPE, PAY.CALC.TYPE, "", "")    ;*Get the calculate type for the payment type
***Scenario : When we have defined constant payment type and we also have Interest only definition. In that case to arrive at the correct calc amount and to allocate
***amount towards each payment type, we have to set the special processing flag. So logic is added to determine if we have constant+interest definition so that we can
***set the special processing flag.
        BEGIN CASE
            CASE PAY.CALC.TYPE EQ "LINEAR"          ;*Set special processing since we have found linear payment type
                SPECIAL.PROCESSING = 1
            CASE PAY.CALC.TYPE EQ "CONSTANT"          ;*We have got constant payment type, now check whether we have other types and set special processing once found
                CONSTANT.FOUND = 1
                IF OTHER.TYPE.FOUND THEN
                    SPECIAL.PROCESSING = 1
                END
            CASE PAY.CALC.TYPE NE "CONSTANT" AND CURR.BILL.PAYMENT.TYPE NE "CURRENT" ;*We have got other payment type except current,Now check whether we have alreay found Constant calc type
                OTHER.TYPE.FOUND = 1
                IF CONSTANT.FOUND THEN
                    SPECIAL.PROCESSING = 1
                END
        END CASE
    NEXT TYP.CNT

RETURN

*** </region>
*-----------------------------------------------------------------------------
*** <region name= Get Tax Amount>
*** <desc>Get Tax amount for the payment type</desc>
GET.TAX.AMOUNT:

    TOTAL.PROPERTIES = DCOUNT(BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdPayProperty,BILL.PAY.POS>,@SM)  ;*Loop through the properties of payment type
    FOR TAX.CNT = 1 TO TOTAL.PROPERTIES
        
*** Since the tax property will be standalone in the bill for transaction type of taxes, a seperate flow has to be created reducing the tax amount
        TRANSACTION.PROCESSING = ''
        LOCATE BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdPayProperty, BILL.PAY.POS, TAX.CNT> IN TRANS.TAX.PROPERTY.LIST<1,1> SETTING TRANS.POS THEN       ;* Set the transaction processing flag if the property type of the property has Transaction
            TRANSACTION.PROCESSING = '1'      ;* Flag to indicate reduce the tax amount from the calculated amount
        END
        IF BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdPayProperty, BILL.PAY.POS, TAX.CNT>["-",2,1] NE "" OR TRANSACTION.PROCESSING THEN     ;*Yes - this is a tax property
            IF BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdPaymentMethod> EQ "PAY" THEN                        ;* for pay type bill we have already reduced tax amount from the calc amount during issue bill, So adding it here
                CALC.AMOUNT += BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdOrPrAmt, BILL.PAY.POS, TAX.CNT>  ;*add Tax amount for pay type bill
            END ELSE
                CALC.AMOUNT -= BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdOrPrAmt, BILL.PAY.POS, TAX.CNT>  ;*Less Tax amount
            END
        END
    NEXT TAX.CNT

RETURN

*** </region>
*-----------------------------------------------------------------------------
*** <region name= Set processing sequence>
*** <desc>Decide processing sequence for Interest, Charge and Account</desc>
GET.PROCESS.SEQUENCE:

** Sequence the order of processing as Charge, Interest and Account always
** regardless of the payment calculation type
*
** Tax is always on a component cannot be standalone, so follow its source sequence
    
    PROPERTY.CLASS.TO.PROCESS = "CHARGE":@FM:"INTEREST":@FM:"ACCOUNT"
    IF SCHEDULE.INFO<17> THEN   ;* If Projection is called during advance repayment, include PeriodicCharges to those bill as well for Repayments
        PROPERTY.CLASS.TO.PROCESS = "PERIODIC.CHARGES":@FM:"CHARGE":@FM:"INTEREST":@FM:"ACCOUNT"    ;* Include PeriodicChargeS for Projection for repayments
    END
   
    IF FAC.TERM.PROPERTY THEN
        PROPERTY.CLASS.TO.PROCESS :=@FM: "TERM.AMOUNT" ;*Include TERM.AMOUNT also in list to handle term.amount schedule definition
    END
   
    FIND "HOLIDAY.INTEREST" IN PAYMENT.TYPES SETTING FM.POS, VM.POS, SM.POS THEN
        PROPERTY.CLASS.TO.PROCESS = "CHARGE":@FM:"INTEREST":@FM:"HOLIDAY-INTEREST":@FM:"ACCOUNT"          ;* Holiday Interest Component Should be processed along with others
    END
    
    FIND "HOLIDAY.ACCOUNT" IN PAYMENT.TYPES SETTING FM.POS, VM.POS, SM.POS THEN
        PROPERTY.CLASS.TO.PROCESS = PROPERTY.CLASS.TO.PROCESS:@FM:"HOLIDAY-ACCOUNT"          ;* Holiday Account Component Should be processed along with others
    END
    
    FIND "HOLIDAY.CHARGE" IN PAYMENT.TYPES SETTING FM.POS, VM.POS, SM.POS THEN
        PROPERTY.CLASS.TO.PROCESS = PROPERTY.CLASS.TO.PROCESS:@FM:"HOLIDAY-CHARGE"          ;* Holiday Account Component Should be processed along with others
    END
    
    FIND "HOLIDAY.PERIODICCHARGE" IN PAYMENT.TYPES SETTING FM.POS, VM.POS, SM.POS THEN
        PROPERTY.CLASS.TO.PROCESS = PROPERTY.CLASS.TO.PROCESS:@FM:"HOLIDAY-PERIODICCHARGE"          ;* Holiday Account Component Should be processed along with others
    END
   
    NO.PROPERTY.CLASS = DCOUNT(PROPERTY.CLASS.TO.PROCESS, @FM)

RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Get Final Account Pos>
*** <desc>Get Final Occurence of Account Property </desc>
GET.FINAL.ACCOUNT.POS:

    LAST.POS = NO.OF.PAYMENT.DATES
    ACCOUNT.PROP.FINAL.POS = ""
    
    IF AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdHolPaymentEndDate> THEN ;* If Holiday Payment end date is present then take the last position of Payment End date position
        LOCATE AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdPaymentEndDate> IN PAYMENT.DATES SETTING LAST.POS THEN
        END
    END
    
    LOOP

    WHILE NOT(ACCOUNT.PROP.FINAL.POS) AND PAYMENT.PROPERTIES<LAST.POS>

* Get the number of payment type in the Last Payment Date

        NUMBER.OF.PAYMENT.TYPE = DCOUNT(PAYMENT.PROPERTIES<LAST.POS>, @VM)

        FOR NO.OF.PAY.TYPE = 1 TO NUMBER.OF.PAYMENT.TYPE

            IF NOT(PAYMENT.TYPES<LAST.POS, NO.OF.PAY.TYPE> EQ "HOLIDAY.ACCOUNT") THEN  ;* dont consider account property under holiday.account payment type as we dont process residual for this payment type
* Locate the Account/TermAmount Property in the PAYMENT.PROPERTIES Array.
                LOCATE SCHEDULE.PROPERTY IN PAYMENT.PROPERTIES<LAST.POS, NO.OF.PAY.TYPE, 1> SETTING AC.POS THEN
 
* Get the Final Account Property Position.
 
                    ACCOUNT.FINAL.POS = NO.OF.PAY.TYPE
                    ACCOUNT.PROP.FINAL.POS = LAST.POS
                END
            END

        NEXT NO.OF.PAY.TYPE

        LAST.POS = LAST.POS - 1

    REPEAT

RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Get payment details>
*** <desc>Get payment details for the payment date</desc>
GET.ASSOC.PAY.DATA:

*
** Using Remove for efficiency extract all the data associated with the payment
** date:
**  PAYMENT.METHODS
**  PAYMENT.TYPES
**  PAYMENT.PROPERTIES
**  PAYMENT.AMOUNTS
*

    PAYMENT.METHOD.LIST = ''
    LOOP
        REMOVE PAY.METHOD FROM PAYMENT.METHODS SETTING YD
        PAYMENT.METHOD.LIST := PAY.METHOD
        IF YD = 3 THEN
            PAYMENT.METHOD.LIST := @VM
        END
    UNTIL YD = 0 OR YD = 2
    REPEAT
*
    PAYMENT.TYPE.LIST = ''
    LOOP
        REMOVE PAY.TYPE FROM PAYMENT.TYPES SETTING YD
        PAYMENT.TYPE.LIST := PAY.TYPE
        IF YD = 3 THEN
            PAYMENT.TYPE.LIST := @VM
        END
    UNTIL YD = 0 OR YD = 2
    REPEAT


    PAYMENT.MIN.AMT.LIST = ''
    LOOP
        REMOVE MIN.AMT FROM PAYMENT.MIN.AMOUNTS SETTING YD
        PAYMENT.MIN.AMT.LIST := MIN.AMT
        IF YD = 3 THEN
            PAYMENT.MIN.AMT.LIST := @VM
        END
    UNTIL YD = 0 OR YD = 2
    REPEAT

    BILL.PAY.TYPE.LIST = ''
    LOOP
        REMOVE BILL.PAY.TYPE FROM PAYMENT.BILL.TYPES SETTING YD
        BILL.PAY.TYPE.LIST := BILL.PAY.TYPE
        IF YD = 3 THEN
            BILL.PAY.TYPE.LIST := @VM
        END
    UNTIL YD = 0 OR YD = 2
    REPEAT
*
    PAYMENT.AMOUNT.LIST = ''
    LOOP
        REMOVE PAY.AMOUNT FROM PAYMENT.AMOUNTS SETTING YD
        PAYMENT.AMOUNT.LIST := PAY.AMOUNT
        BEGIN CASE
            CASE YD = 3
                PAYMENT.AMOUNT.LIST := @VM
            CASE YD = 4
                PAYMENT.AMOUNT.LIST := @SM
        END CASE
    UNTIL YD = 2 OR YD = 0    ;* Note that Pay amount can be null
    REPEAT
*
    HOLIDAY.PAYMENT.AMOUNT.LIST = ''
    LOOP
        REMOVE HOLIDAY.PAY.AMOUNT FROM HOLIDAY.PAYMENT.AMOUNTS SETTING YD
        HOLIDAY.PAYMENT.AMOUNT.LIST := HOLIDAY.PAY.AMOUNT
        BEGIN CASE
            CASE YD = 3
                HOLIDAY.PAYMENT.AMOUNT.LIST := @VM
            CASE YD = 4
                HOLIDAY.PAYMENT.AMOUNT.LIST := @SM
        END CASE
    UNTIL YD = 2 OR YD = 0    ;* Note that holiday amount can be null
    REPEAT
*
    PAYMENT.PROPERTY.LIST = ''
    LOOP
        REMOVE PAY.PROPERTY FROM PAYMENT.PROPERTIES SETTING YD
        PAYMENT.PROPERTY.LIST := PAY.PROPERTY
        BEGIN CASE
            CASE YD = 3
                PAYMENT.PROPERTY.LIST := @VM
            CASE YD = 4
                PAYMENT.PROPERTY.LIST := @SM
        END CASE
    UNTIL YD = 0 OR YD = 2
    REPEAT

    PAYMENT.PERCENTAGE.LIST = ''
    LOOP
        REMOVE PAY.PERCENT FROM PAYMENT.PERCENTAGES SETTING YD
        PAYMENT.PERCENTAGE.LIST := PAY.PERCENT
        BEGIN CASE
            CASE YD = 3
                PAYMENT.PERCENTAGE.LIST := @VM
            CASE YD = 4
                PAYMENT.PERCENTAGE.LIST := @SM
        END CASE
    UNTIL YD = 0 OR YD = 2
    REPEAT
*
    PAYMENT.DEFER.LIST = ''
    LOOP
        REMOVE PAY.DEFER FROM PAYMENT.DEFER.DATES SETTING YD
        PAYMENT.DEFER.LIST := PAY.DEFER
        BEGIN CASE
            CASE YD = 3
                PAYMENT.DEFER.LIST := @VM
            CASE YD = 4
                PAYMENT.DEFER.LIST := @SM
        END CASE
    UNTIL YD = 0 OR YD = 2
    REPEAT
*
RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Sequence properties>
*** <desc>Arrange the property list</desc>
SEQUENCE.PROPERTY.LIST:

** Sequence the property list by property class in the order Charge, Interest, Tax and Principal
** Ensure the payment type position and property position in respect to the variables
** PAYMENT.TYPES and PAYMENT.PROPERTIES are not altered because of the sequencing
** It is essential to maintain this order for further processing

    SEQUENCED.PROPERTY.LIST = ""        ;* List of properties in the order of PC for the payment date
    SEQUENCED.PROPERTY.POS = ""         ;* Payment type and property positions

    SEQUENCED.DISB.PROP.LIST = ""
    SEQUENCED.DISB.PROP.POS = ""
    
    CALC.AMOUNT = ""

    NO.OF.PAYMENT.TYPES = DCOUNT(PAYMENT.TYPE.LIST<1>, @VM)
    FOR PAY.TYPE.I = 1 TO NO.OF.PAYMENT.TYPES

*** If the Current payment type is Holiday Interest then update it as separte Interest

        YI = 1
        LOOP
            PAYMENT.PROPERTY = PAYMENT.PROPERTY.LIST<1, PAY.TYPE.I, YI>
        WHILE PAYMENT.PROPERTY
            GOSUB GET.PROPERTY.CLASS

            PAYMENT.PROPERTY.CLASS = PROPERTY.CLASS
            
            BEGIN CASE
                CASE PAYMENT.TYPE.LIST<1,PAY.TYPE.I> EQ "HOLIDAY.INTEREST"
                    PAYMENT.PROPERTY.CLASS = "HOLIDAY-": PAYMENT.PROPERTY.CLASS
            
                CASE PAYMENT.TYPE.LIST<1,PAY.TYPE.I> EQ "HOLIDAY.ACCOUNT"
                    PAYMENT.PROPERTY.CLASS = "HOLIDAY-": PAYMENT.PROPERTY.CLASS      ;* Add Holiday-Account Payment type into the List
                          
                CASE PAYMENT.TYPE.LIST<1,PAY.TYPE.I> EQ "HOLIDAY.CHARGE"
                    PAYMENT.PROPERTY.CLASS = "HOLIDAY-": PAYMENT.PROPERTY.CLASS
            
                CASE PAYMENT.TYPE.LIST<1,PAY.TYPE.I> EQ "HOLIDAY.PERIODICCHARGE"
                    PAYMENT.PROPERTY.CLASS = "HOLIDAY-": PAYMENT.PROPERTY.CLASS
                    
            END CASE
                        
        
            LOCATE PAYMENT.PROPERTY.CLASS IN PROPERTY.CLASS.TO.PROCESS<1> SETTING SEQ.POS THEN      ;* Sequence them
* If disbursement payment type is present in the first place of PS and other principal property is present in the order followed by disbursement
* and if schedule falls on the same date of future disbursement date. System should not project the due on the same date of disbursement.
* Hence storing the disbursement property and positions in the temporary variable. After processing all other principal property system will
* store the disb property and positions at last position in the SEQUENCED.PROPERTY.POS list.
                IF PAYMENT.PROPERTY.CLASS EQ "CHARGE" THEN ;* for charge property class , read the property record to check whether it is a transaction based charge , that is, activity field is defined
                    CHARGE.PROP.RECORD = ""
                    AA.Framework.LoadStaticData("F.AA.PROPERTY", PAYMENT.PROPERTY, CHARGE.PROP.RECORD, "")
                END
            
                BEGIN CASE
                    CASE BILL.PAY.TYPE.LIST<1,PAY.TYPE.I, YI> EQ "DISBURSEMENT" AND NOT(SEQUENCED.PROPERTY.LIST<SEQ.POS>)
                        SEQUENCED.DISB.PROP.LIST = PAYMENT.PROPERTY
                        SEQUENCED.DISB.PROP.POS = PAY.TYPE.I:AA.Framework.Sep:YI         ;* Store disbursement payment type and property positions.
                        ACC.POS = SEQ.POS   ;* Store the account property class position from the property class list if disbursement is present in the first place.
                    CASE CHARGE.PROP.RECORD<AA.ProductFramework.Property.PropActivity> AND SCHEDULE.INFO<8> ;* dont add charge properties which are setup for transaction based calculation, similar to periodic charges
                    CASE 1
                        SEQUENCED.PROPERTY.LIST<SEQ.POS,-1> = PAYMENT.PROPERTY
                        SEQUENCED.PROPERTY.POS<SEQ.POS,-1> = PAY.TYPE.I:AA.Framework.Sep:YI       ;* Store payment type and property positions
                END CASE
            END

            YI += 1
        REPEAT

    NEXT PAY.TYPE.I

    IF SEQUENCED.DISB.PROP.LIST AND SEQUENCED.DISB.PROP.POS THEN     ;* Check the variable has the disbursement payment type and property positions values.
        SEQUENCED.PROPERTY.LIST<ACC.POS,-1> = SEQUENCED.DISB.PROP.LIST
        SEQUENCED.PROPERTY.POS<ACC.POS,-1> =  SEQUENCED.DISB.PROP.POS       ;* Append the disbursement payment type and property positions at last in the sequence list.
    END
    
RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Get property class>
*** <desc>Get property class</desc>
GET.PROPERTY.CLASS:

** Get property class for the property, do not read from cache everytime
** use the local information if available

** Saving the payment property because skim properties are appended with "-SKIM" and thus have to be converted into normal property before any operation.
    STORE.PAYMENT.PROPERTY = PAYMENT.PROPERTY
    GOSUB CHECK.SKIM.FLAG
        
    LOCATE PAYMENT.PROPERTY IN PROPERTIES<1,1> SETTING PAY.POS THEN
        PROPERTY.CLASS = PROPERTIES.CLASS<1,PAY.POS>
    END ELSE
        PROPERTY.CLASS = ""
        AA.ProductFramework.GetPropertyClass(PAYMENT.PROPERTY, PROPERTY.CLASS)
    END

** Once the property class is obtained, the payment property is again rolled back to previous name(as we saw for skim)
    PAYMENT.PROPERTY = STORE.PAYMENT.PROPERTY

RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Get Participant Payment Properties>
*** <desc> Get Participant Payment Properties</desc>
GET.PARTICIPANT.PAYMENT.PROPERTIES:
       
    PART.POS = PART.COUNT-1
    IF BOOK.BANK.PROCESSING THEN
        PART.POS = PART.COUNT-2
    END
    
    IS.PARTICIPANT = 1
    
    IF FIELD(PART.ID<1,PART.COUNT>, '-', 1) EQ 'BOOK' AND FIELD(PART.ID<1,PART.COUNT>, '-', 2) AND FIELD(PART.ID<1,PART.COUNT>, '-', 2) NE 'BANK' THEN
        IS.PORTFOLIO = 1
    END
    
    PAYMENT.AMOUNT.LIST = ''
** Here, we are using Part count - 1 because 1st position in participant Id list is BORROWER and participant payment properties variable doesn't hold the properties for borrower
** For example ParticipantList: BORROWER*P1*P2*BOOK and CUR.PART.PAYMENT.PROPERTIES: P1.PAYMENT.PROPERTIES*P2.PAYMENT.PROPERTIES*BOOK.PAYMENT.PROPERTIES
** Thus, for each participant from participant list it's position - 1 is the corresponding position in part payment properties
    TEMP.PORTFOLIO.ID = ''
    IF IS.PORTFOLIO THEN
        TEMP.PORTFOLIO.ID = 'BOOK-':FIELD(PART.ID<1,PART.COUNT>, '-', 2)
        CONVERT '*' TO @FM IN CUR.PART.PAYMENT.PROPERTIES
        CONVERT '*' TO @FM IN CUR.PART.ID
        LOCATE TEMP.PORTFOLIO.ID IN CUR.PART.ID<1> SETTING PF.POS THEN
            PAYMENT.PROPERTY.LIST = CUR.PART.PAYMENT.PROPERTIES<PF.POS>
        END
        CONVERT @FM TO '*' IN CUR.PART.PAYMENT.PROPERTIES
        CONVERT @FM TO '*' IN CUR.PART.ID
    END ELSE
        PAYMENT.PROPERTY.LIST = FIELD(CUR.PART.PAYMENT.PROPERTIES, '*', PART.POS)
    END
    GOSUB SEQUENCE.PROPERTY.LIST ;* Sequence the participant payment properties based on the property classes.
    CALC.AMOUNT = STORE.CALC.AMOUNT ;* Borrower's CALC.AMOUNT is not changed.

RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Process forward schedules>
*** <desc>Process forward schedules</desc>
PROCESS.FORWARD.SCHEDULES:

** For "Constant" calculation type first calculate all components
** before calculating the principal (Account) amount
** For "Linear" calculation type only a single property (Account) would be
** defined, so no distribution of "Linear" or "Other" types
** Only a structure exists for charge and tax calculations
    
    PAYMENT.PERCENT = 0
       
    NO.OF.PAYMENT.PROPERTIES = DCOUNT(SEQUENCED.PROPERTY.LIST<PC.POS>, @VM)      ;* Properties to be processed for the date'
    RULE.78.INTEREST.TYPE = '' ;* Initializing the variable for Rule78 payments
    FOR YI = 1 TO NO.OF.PAYMENT.PROPERTIES

        PAYMENT.PROPERTY = SEQUENCED.PROPERTY.LIST<PC.POS,YI>         ;* For each property, calculate payment amount

        IF SKIP.PENALTY.INTEREST AND SKIP.PENALTY.PROPERTY EQ PAYMENT.PROPERTY ELSE
    
            SKIM.FLAG = '' ;* Initialise skim flag to NULL for every payment property
            GOSUB CHECK.SKIM.FLAG ;* Check if the current property is skim property
        
            PAY.TYPE.I = FIELD(SEQUENCED.PROPERTY.POS<PC.POS, YI>, AA.Framework.Sep, 1)       ;* Set the payment type position
            PROPERTY.I = FIELD(SEQUENCED.PROPERTY.POS<PC.POS, YI>, AA.Framework.Sep, 2)       ;* Set the property position

            PAYMENT.TYPE = PAYMENT.TYPE.LIST<1, PAY.TYPE.I>

            PAY.BILL.TYPE = ''

            PAYMENT.METHOD = PAYMENT.METHOD.LIST<1, PAY.TYPE.I>

            PAYMENT.PERCENT = PAYMENT.PERCENTAGE.LIST<1, PAY.TYPE.I>

            PAYMENT.MIN.AMT = PAYMENT.MIN.AMT.LIST<1, PAY.TYPE.I>

            BILL.PAYMENT.TYPE = BILL.PAY.TYPE.LIST<1, PAY.TYPE.I>

            PAYMENT.DEFER.DATE = PAYMENT.DEFER.LIST<1, PAY.TYPE.I>
       
            GOSUB GET.CALC.TYPE   ;* Determine calculation type
            GOSUB GET.HOLIDAY.RESTRICT.TYPE ;* To know the property restricted or not
 
            IF PREV.PAY.TYPE.I NE PAY.TYPE.I AND AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdHolPaymentType> THEN  ;* Reset Holiday amount when payment type is different.
                HOLIDAY.AMOUNT = HOLIDAY.PAYMENT.AMOUNT.LIST<1, PAY.TYPE.I> ;* Assigning the holiday amount for a particular payment date
                HOLIDAY.PROPERTY.AMOUNT = "" ;* Rest Holiday Property amount when payment type is different.
                IF SCHEDULE.INFO<8> OR SCHEDULE.INFO<72> OR SCHEDULE.INFO<53> OR SCHEDULE.INFO<52> THEN
                    GOSUB CHECK.DEFER.ALL.HOLIDAY.PROPERTY
                END
            END

* Remaining Holiday amount should be added to Account to display the total due as per holiday amount defined when Holiday amount present for the schedule date.
* Suppose there are Charge, Interest and Account scheduled with same frequency and there is remaining holiday amount present with respect to interest calculated
* for that period and original holiday amount for Interest, then the remaining holiday amount should be added to the Account portion.
            IF PROPERTY.CLASS.TO.PROCESS<PC.POS> EQ "ACCOUNT" AND HOLIDAY.AMOUNT AND PREV.PAY.TYPE.I NE PAY.TYPE.I AND SUM(REMAINING.HOLIDAY.AMT) THEN
                HOLIDAY.AMOUNT = HOLIDAY.AMOUNT + SUM(REMAINING.HOLIDAY.AMT)
            END

* The default process sequence of properties are Charge, Interest and Account. When there are multiple payment types with properties of same property class on the same day system
* will process the properties only based on this sequence. For example when there is a CONSTANT payment type with ACCOUNT and INTEREST properties
* and INTEREST payment type with PENALTYINTEREST property system will first process the INTEREST followed by PENALTYINTEREST and then ACCOUNT. In this sequence
* the holiday amount that is already calculated for first payment type may be overwritten when the second payment type is processed. So we need to
* make sure all the properties in a payment type are processed before aloowing to overwrite the payment holiday.

            LOCATE PAYMENT.TYPE IN PROCESSED.PAY.TYPE<1> SETTING PM.POS THEN  ;* To avoid overwriting the already calculated holiday amount for this PAYMENT.TYPE
                IF PAY.TYPE.I EQ PROCESSED.PAY.TYPE.POS<PM.POS> THEN
                    HOLIDAY.AMOUNT = REMAINING.HOLIDAY.AMT<PM.POS>
                END
            END
           
** Locate Payment Property Type in the PROPERTY.DETAILS, if available then take values from there
** Else invoke GetPropertyDetailsPaySchedule
            PAYMENT.PROP.TYPE = PAYMENT.TYPE:'-':PAYMENT.PROPERTY
            LOCATE PAYMENT.PROP.TYPE IN PROPERTY.DETAILS<1, 1> SETTING PAYMENT.TYPE.POS THEN
                PAYMENT.FREQ = PROPERTY.DETAILS<2, PAYMENT.TYPE.POS>
                PAY.BILL.TYPE = PROPERTY.DETAILS<3, PAYMENT.TYPE.POS>
                PROGRESS.RATE = PROPERTY.DETAILS<4, PAYMENT.TYPE.POS>
            END ELSE
                AA.PaymentSchedule.GetPropertyDetailsPaySchedule(R.PAYMENT.SCHEDULE,PAYMENT.TYPE,PAYMENT.PROPERTY,PAYMENT.FREQ,PAY.BILL.TYPE,PROGRESS.RATE)  ;* Get bill type, frequency, progress rate for given property and payment type
                PROPERTY.DETAILS<1, PAYMENT.TYPE.POS> = PAYMENT.PROP.TYPE
                PROPERTY.DETAILS<2, PAYMENT.TYPE.POS> = PAYMENT.FREQ
                PROPERTY.DETAILS<3, PAYMENT.TYPE.POS> = PAY.BILL.TYPE
                PROPERTY.DETAILS<4, PAYMENT.TYPE.POS> = PROGRESS.RATE
            END

            MIC.REQD = '' ;* Variable to indicate whether MIC required for the property
            RETURN.ERROR = ''
            BILL.TYPE = PAY.BILL.TYPE
            IF BILL.TYPE EQ '' AND AA.Framework.getContractDetails()<AA.Framework.CdIncludePrinAmounts> EQ "PROGRESSIVE" THEN
                BILL.TYPE = BILL.PAYMENT.TYPE
            END
            LOCATE BILL.TYPE IN BILL.TYPE.ARRAY<1,1> SETTING BILL.TYPE.POS THEN
                PAY.BILL.TYPE = BILL.TYPE.ARRAY<2, BILL.TYPE.POS>
            END ELSE
                PAY.BILL.TYPE = ''
                AA.PaymentSchedule.GetSysBillType(BILL.TYPE, PAY.BILL.TYPE, '')
                BILL.TYPE.ARRAY<1,-1> = BILL.TYPE
                BILL.TYPE.ARRAY<2,-1> = PAY.BILL.TYPE
            END
        
***Check the last disbursement date to identify to build schedules or not
            LAST.DISBURSEMENT.DATE = ""

            IF OUTSTANDING.AMOUNT AND PAY.BILL.TYPE EQ 'DISBURSEMENT' THEN
                AA.PaymentSchedule.GetLastDisbursementDate(ARRANGEMENT.ID, '', '', LAST.DISBURSEMENT.DATE,'','','')

                IF LAST.DISBURSEMENT.DATE EQ PAYMENT.DATE THEN
                    INCLUDE.DISBURSE.SCHEDULE = ''
                END
            END

** Locate Property Bill Type in the MIC.ARRAY, if available then take values from there
** Else invoke DetermineMinimumInvoiceComponent
            PROP.BILL.TYPE = PAYMENT.PROPERTY:'-':PAY.BILL.TYPE
            LOCATE PROP.BILL.TYPE IN MIC.ARRAY<1, 1> SETTING MIC.POS THEN
                MIC.REQD = MIC.ARRAY<2, MIC.POS>
            END ELSE
                AA.PaymentSchedule.DetermineMinimumInvoiceComponent(R.PAYMENT.SCHEDULE, PAYMENT.PROPERTY, PAY.BILL.TYPE, MIC.REQD, RETURN.ERROR) ;* API to detrmine MIC required for the current property and it return the minimum amount
                MIC.ARRAY<1, MIC.POS> = PROP.BILL.TYPE
                MIC.ARRAY<2, MIC.POS> = MIC.REQD
            END
          
            IF DEFER.ALL.HOLIDAY.FLAG ELSE
                GOSUB GET.BILL.DETAILS
            END
        
            IF CALC.TYPE MATCHES "CONSTANT":@VM:"PROGRESSIVE":@VM:"ACCELERATED":@VM:"PERCENTAGE":@VM:"FIXED EQUAL":@VM:"ADVANCE" AND CALC.AMOUNT = "" THEN ;* If constant/progressive or Advance Calc type, assuming only one for the payment date
                CALC.AMOUNT = PAYMENT.AMOUNT.LIST<1, PAY.TYPE.I>
                STORE.CALC.AMOUNT = CALC.AMOUNT ;*Storing Borrowers calc amount
            END
        
            IF CALC.TYPE EQ "PROGRESSIVE" THEN        ;*For Progressive type
                GOSUB PROCESS.PROGRESSIVE.PAYMENT     ;*Determine if we should use calc amount or we should increment by progress factor
            END

            GOSUB VALIDATE.SCHEDULE.AMOUNTS ;* validate the actual amount defined

            IF PROCESS.SCHEDULES THEN
                GOSUB PROCESS.PROPERTY.CLASS          ;* Continue if flag is set
            END
    
            IF HOLIDAY.AMOUNT NE "" THEN   ;* Store the holiday amount for this payment type, this will be required for the remaining properties of the payment type if available.
* Store the amounts in one position so that locate can be done to fetch the correct remaining holiday amount.
                LOCATE PAYMENT.TYPE IN PROCESSED.PAY.TYPE<1> SETTING HOL.POS THEN
                    REMAINING.HOLIDAY.AMT<HOL.POS> = HOLIDAY.AMOUNT
                END ELSE
                    PROCESSED.PAY.TYPE<-1> = PAYMENT.TYPE
                    PROCESSED.PAY.TYPE.POS<-1> = PAY.TYPE.I
                    REMAINING.HOLIDAY.AMT<-1> = HOLIDAY.AMOUNT
                END
            END
            PREV.PAY.TYPE.I = PAY.TYPE.I
        
*If it is a sepcial processing and not advance payment Reset the calc.amount for other payment type properties in the advance bill once the partial advance repayment is done over the issued bill.
*EX:    properties:charge^interest^account
*       propamt:50^80.34^1123.34
*For charge property calc.amount is set 50, if it is not reset then while calculating for interest it is updated as 50-80.34= -30.34. due to this projection and OR.Prop.Amt in bills are updating Incorrectly.
        
            IF CALC.TYPE MATCHES "ACTUAL":@VM:"LINEAR" AND CALC.AMOUNT NE '' AND (ADVANCE.FLAG OR (SPECIAL.PROCESSING AND BILL.PR.AMT)) THEN
                CALC.AMOUNT = ''    ;* Reinitialise the CalcAmount,so that CalcAmount is recalculated/reassigned for other payment type properties
            END
    
        END
    
    NEXT YI

RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name=Get holiday restrict type >
*** <desc>Get holiday restrict type</desc>
GET.HOLIDAY.RESTRICT.TYPE:

    RESTRICTED.HOL.TYPE = ""
    RESTRICTED.PROPERTY = ""
    
    IF AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdHolPaymentType> THEN
        AA.PaymentSchedule.DeterminePaymentHolidaySkipDate(ARRANGEMENT.ID, R.PAYMENT.SCHEDULE, "", PAYMENT.TYPE, BILL.PAYMENT.TYPE, PAYMENT.PROPERTY, PROPERTY.CLASS.TO.PROCESS<PC.POS>, RESTRICTED.HOL.TYPE, RET.ERROR)
    
        IF NOT(RESTRICTED.HOL.TYPE) THEN
            RESTRICTED.PROPERTY = 1
        END
    END
    
RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Check Skim Flag>
*** <desc>Check Skim Flag</desc>
CHECK.SKIM.FLAG:

** Check if the payment property is defined as Skim, if yes then set the skim flag
** If the payment property is skim it'll be defined in the format "PropertyName-SKIM", but it's just for identifying it as skim property
** Thus we take only the PropertyName from "PropertyName-Skim" to obtain the property class.
    IF FIELD(PAYMENT.PROPERTY, AA.Framework.Sep, 2) EQ "SKIM" THEN
        PAYMENT.PROPERTY = FIELD(PAYMENT.PROPERTY, AA.Framework.Sep, 1)
        SKIM.FLAG = 1
    END
    
RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Get calc type>
*** <desc>Get calc type</desc>
GET.CALC.TYPE:

    R.PAYMENT.TYPE = "" ; TAX.INCLUSIVE = "" ; DUE.AND.CAP = ""  ;*  this flag is set to indicate that the paymenttype is of due and cap type
    LOCATE PAYMENT.TYPE IN PAYMENT.TYPE.ARRAY<1,1> SETTING PAY.TYPE.POS THEN
        R.PAYMENT.TYPE = RAISE(RAISE(PAYMENT.TYPE.ARRAY<2, PAY.TYPE.POS>))
    END ELSE
        AA.Framework.LoadStaticData("F.AA.PAYMENT.TYPE", PAYMENT.TYPE, R.PAYMENT.TYPE, "")
        PAYMENT.TYPE.ARRAY<1,-1> = PAYMENT.TYPE
        PAYMENT.TYPE.ARRAY<2,-1> = LOWER(LOWER(R.PAYMENT.TYPE))
    END

** Get the type of calculation and Payment Modes for the Payment type
    LOCATE PAYMENT.TYPE IN R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsPaymentType,1> SETTING PAY.POS THEN
        CALC.TYPE = CALCULATION.TYPES<1,PAY.POS>
        PAYMENT.MODE =  PAYMENT.MODES<1,PAY.POS>

        PROCESS.TYPE = PROCESS.TYPES<1,PAY.POS>   ;* Get the process type
        IF EXTEND.CYCLE EQ '' THEN
            EXTEND.CYCLE = EXTEND.CYCLES<1,PAY.POS>
        END
    END ELSE        ;* Should not happen, just in case

        CALC.TYPE = R.PAYMENT.TYPE<AA.PaymentSchedule.PaymentType.PtCalcType>         ;* Calculation type for the payment type
        PAYMENT.MODE = R.PAYMENT.TYPE<AA.PaymentSchedule.PaymentType.PtPaymentMode>   ;* Payment mode for the Payment type
        PROCESS.TYPE = R.PAYMENT.TYPE<AA.PaymentSchedule.PaymentType.PtType>
    END
    
    PYMNT.CALCRTN = R.PAYMENT.TYPE<AA.PaymentSchedule.PaymentType.PtCalcRoutine>
    IF CALC.TYPE EQ "OTHER" AND PYMNT.CALCRTN EQ "AA.CALCULATE.RULE78.INTEREST.AMOUNT" THEN
        RULE.78.INTEREST.TYPE = 1   ;* Flag set to indicate Rule 78 Interest payment type
    END
    
    IF PRODUCT.LINE EQ 'LENDING' THEN ;* Tax inclusive will be applicable only to Lending
        TAX.INCLUSIVE = R.PAYMENT.TYPE<AA.PaymentSchedule.PaymentType.PtTaxInclusive> ;* To fetch the Tax.Inclusive
    END
    

** Check if altpaymentmethod is of DUE.AND.CAP type and set flag to process further
    IF R.PAYMENT.TYPE<AA.PaymentSchedule.PaymentType.PtAlternatePaymentMethod> EQ "DUE.AND.CAP" AND (SCHEDULE.INFO<30> OR SCHEDULE.INFO<53>) THEN ;* set flag if its a due and cap type or invoked from .Iterate routine
        DUE.AND.CAP = 1
    END

** Check if the advance calc type is present then set flag to process further
    IF R.PAYMENT.TYPE<AA.PaymentSchedule.PaymentType.PtAdvanceCalcType> THEN
        ADV.CALC.TYPE = 1
    END
RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Validate Schedule Amounts>
*** <desc> </desc>
VALIDATE.SCHEDULE.AMOUNTS:

* Check whether the actual amount defined does not be greater than the current outstanding amounts
    tmp.R$STORE.PROJECTION = AA.Interest.getRStoreProjection()
    IF PAYMENT.METHOD NE "MAINTAIN" AND SUM(PAYMENT.AMOUNT.LIST<1, PAY.TYPE.I>) GT PRESENT.VALUE AND PROCESS.TYPE = "MANUAL" AND NOT(PAYMENT.FREQ) AND NOT(tmp.R$STORE.PROJECTION) AND NOT(PAY.BILL.TYPE MATCHES "EXPECTED":@VM:"DISBURSEMENT")  THEN ;* Ignore the Actual amount check if the Bill Type is Disbursement.
        DIFF.AMOUNT = SUM(PAYMENT.AMOUNT.LIST<1, PAY.TYPE.I>) - PRESENT.VALUE
        RET.ERROR = "AA-MANUAL.AMT.GT.OUTSTANDING.AMOUNT":@FM:PAYMENT.DATE:@VM:DIFF.AMOUNT
    END

RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Process Property Class>
*** <desc> </desc>
PROCESS.PROPERTY.CLASS:

* Now process the defined properties

    HOLIDAY.DATE = "" ;* Initialise for each Properyt Class
    PAYMENT.PROPERTY.CLASS = PROPERTY.CLASS.TO.PROCESS<PC.POS>        ;* From class determine how to calculate

    LAST.ACCRUAL.DATE = ""
    PAYMENT.PROPERTY.AMOUNT = 0         ;* Reset amounts
    PAYMENT.PROPERTY.POS.AMOUNT = 0         ;* Reset amounts
    PAYMENT.PROPERTY.NEG.AMOUNT = 0         ;* Reset amounts
    INT.AMOUNT = 0
    CHARGE.AMOUNT = 0
    TAX.AMOUNT = 0
    AMOUNT = 0
    ACCOUNT.AMOUNT.CHECK = 0
    REMAIN.AMOUNT = 0
    UPDATE.AMOUNT = ''
    PAYMENT.METHOD.NEW = PAYMENT.METHOD.LIST<1, PAY.TYPE.I>
    TEMP.BORROWER.AMOUNT = 0            ;* Calculated property Amount for Borrower
    ADVANCE.HOL.POS = '' ;* flag to check if there is any holiday date in account details less than the current processing payment date
    HOLIDAY.DATES.ARRAY = ''
    
    BILL.PROPAMOUNT = "" ;* Check the Issue Bill Account Property Amount.
    IF REDUCE.HOLAMT AND BILL.DETAIL NE "" THEN ;* Check processing property class is Account, Issue bill and its bill details record present.
        LOCATE PAYMENT.PROPERTY IN BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdProperty,1> SETTING PROP.POS THEN ;* Get Issue Bill Account Property Amount.
            BILL.PROPAMOUNT = BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdOrPropAmount,PROP.POS>
        END
    END
    
 
        
    IF tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolPaymentType> AND (NOT(SCHEDULE.INFO<53> AND DEFER.ALL.HOLIDAY.FLAG) OR SCHEDULE.INFO<72>) THEN;* while skipping schedules without amount, marking the date as holiday date

        BEGIN CASE
    
            CASE NOT(HOLIDAY.AMOUNT) AND NOT(HOLIDAY.PROPERTY.AMOUNT)
                TotalHolPaymentType = DCOUNT(tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolPaymentType>,@VM)
*** If HOL.START.DATE is different but same HolPaymentTyp system update on two set of holiday details for HolPaymentTyp in Account details.
*** Hence, looping the each HolPaymentTyp and check with PaymentType
                FOR HolPaymentType = 1 TO TotalHolPaymentType
                    HolidayPaymentInfo = tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolPaymentType>
                    HolPaymentTypes = FIELDS(HolidayPaymentInfo,"-",1)
                    IF PAYMENT.TYPE EQ HolPaymentTypes<1,HolPaymentType> THEN
                        LOCATE PAYMENT.DATE IN tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolidayDate,HolPaymentType,1> SETTING HolPos THEN
                            HOLIDAY.DATE = 1
                            IF NOT(CALC.TYPE MATCHES 'CONSTANT':@VM:'PROGRESSIVE':@VM:"PERCENTAGE":@VM:"FIXED EQUAL":@VM:"HOLIDAY") OR ISSUE.BILL.DATE OR (REDUCE.HOLAMT AND BILL.PROPAMOUNT GT 0) THEN ;* When the account property amount exists in Issue Bill then assign the Holiday amount to display outstanding amount properly for issue bill date.
                                HOLIDAY.AMOUNT = tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolNewPaymentAmount,HolPaymentType,HolPos>
                            END
                        END
                        IF PAYMENT.MODE EQ "ADVANCE" THEN ;* check if there is any holiday date in account details less than the current processing payment date
                            LOCATE PAYMENT.DATE IN tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolidayDate,HolPaymentType,1> BY 'AN' SETTING ADVANCE.HOL.POS THEN
                            END
                        END
                        TOT.HOL.DATES = DCOUNT(tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolidayDate,HolPaymentType>, @SM)
                        FOR CNT = 1 TO TOT.HOL.DATES
                            IF tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolidayDate,HolPaymentType, CNT> THEN
                                HOLIDAY.DATES.ARRAY<1,-1> = tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolidayDate,HolPaymentType, CNT>
                            END
                        NEXT CNT
                    END
                NEXT HolPaymentType
    
                IF HOLIDAY.DATE THEN
                    GOSUB CHECK.DEFER.ALL.HOLIDAY.PROPERTY ;* Check Defer All Flag present in account details
                END
 
            CASE HOLIDAY.AMOUNT OR HOLIDAY.PROPERTY.AMOUNT
    
                GOSUB CHECK.DEFER.ALL.HOLIDAY.PROPERTY ;* Check Defer All Flag present in account details
        
        END CASE
        
        BEGIN CASE
        
            CASE (HOLIDAY.AMOUNT OR HOLIDAY.PAYMENT.AMOUNT.LIST<1, PAY.TYPE.I>) AND DEFER.ALL.HOLIDAY.FLAG AND NOT(RESTRICTED.PROPERTY) AND SCHEDULE.INFO<51> AND NOT(SCHEDULE.INFO<72>) AND NOT(SCHEDULE.INFO<8>)
            
                HOLIDAY.AMOUNT = 0 ;* During Make-Due activity Reset to Zero So that the build schedules will give dates projection correctly without considering holiday amount

            CASE NOT(RESTRICTED.PROPERTY) AND (DEFER.ALL.HOLIDAY.FLAG OR HOL.PROPERTY.DETAILS) AND (SCHEDULE.INFO<72> OR SCHEDULE.INFO<73> OR SCHEDULE.INFO<8> OR HOLIDAY.AMOUNT NE '' OR HOLIDAY.PROPERTY.AMOUNT NE '');* During Projection call/calc amount calculation need to get the amount from Hol Property Fields in account details
        
*** Get Holiday property amount from account details for corresponding payment type and payment holiday date
                CONVERT "#" TO @SM IN HOL.PROPERTY.DETAILS
                CONVERT "@" TO @VM IN HOL.PROPERTY.DETAILS
                TOT.HOL.PROP.CNT = DCOUNT(HOL.PROPERTY.DETAILS,@VM)
                FOR HOL.PROP.CNT = 1 TO TOT.HOL.PROP.CNT
                    IF HOL.PROPERTY.DETAILS<1,HOL.PROP.CNT,1> EQ PAYMENT.PROPERTY THEN
                                                
                        IF PAYMENT.PROPERTY.CLASS NE "ACCOUNT" THEN
                            IF HOL.PROPERTY.DETAILS<1,HOL.PROP.CNT,3> AND HOL.PROPERTY.DETAILS<1,HOL.PROP.CNT,3> GT HOL.PROPERTY.DETAILS<1,HOL.PROP.CNT,2> THEN
                                HOLIDAY.PROPERTY.AMOUNT = HOL.PROPERTY.DETAILS<1,HOL.PROP.CNT,2> ;* Needs to update Holiday property amount with latest rate change done in between issue.bill and make.due activity
                            END ELSE
                                HOLIDAY.PROPERTY.AMOUNT = HOL.PROPERTY.DETAILS<1,HOL.PROP.CNT,3> ;* New Holiday Property payment amount for the current payment date
                            END
                        
                        END ELSE
                            HOLIDAY.PROPERTY.AMOUNT = HOL.PROPERTY.DETAILS<1,HOL.PROP.CNT,3> ;* New Holiday Property payment amount for the current payment date
                        END
                    
                        IF HOLIDAY.PROPERTY.AMOUNT NE "" THEN
*** HOLIDAY.PAYMENT.AMOUNT.LIST - During finalise bill setup, the holiday amount is not returned in this variable. At that time need to check for holiday amount from account details.
                            HOLIDAY.AMOUNT = HOLIDAY.PROPERTY.AMOUNT
                            IF HOLIDAY.PROPERTY.AMOUNT EQ '0' THEN
                                HOLIDAY.DATE = 1
                            END ELSE
                                HOLIDAY.PROP.AMT.FLAG = 1
                            END
                        END ELSE
                            BEGIN CASE
                                CASE HOLIDAY.AMOUNT
                                    HOLIDAY.PROP.AMT.FLAG = 1
                                CASE SCHEDULE.INFO<73> ;* If there is any payment schedule frequency change in between the holiday periods, based on this flag we can get the holiday amount details during replay of Account/Interest/Charge/Periodic.Charges make-due activity
                                    HOLIDAY.PROPERTY.AMOUNT = HOL.PROPERTY.DETAILS<1,HOL.PROP.CNT,2>
                            END CASE
                        END
                    
                        TOT.HOL.PROP.CNT = HOL.PROP.CNT ;* Stop the loop. we have found the property and corresponding holiday property amount
                    END
                NEXT HOL.PROP.CNT
         
        END CASE

    END
    
    BILL.PROPERTY.AMOUNT = ""
    GOSUB GET.BILL.PROPERTY.AMOUNT

**Ignore bill details only if the bill property amount is NULL. Include 0 as well
    IF PAYMENT.PROPERTY.CLASS EQ "ACCOUNT" AND ((TEMP.AMOUNT AND TEMP.UPDATE.AMOUNT) OR (PART.TEMP.AMOUNT AND PART.TEMP.UPDATE.AMOUNT AND IS.PARTICIPANT)) THEN ;*Update calculated cap amt in contract details for participants also.
        GOSUB UPDATE.CAP.AMOUNT.IN.PRESENT.VALUE  ;* update once after process the entire properties present in same date.
    END
    
    PRESENT.VALUE.FOUND = 0
    IF PAYMENT.PROPERTY.CLASS EQ 'ACCOUNT' OR FAC.TERM.PROPERTY THEN ;*Handle term.amount schedule definition for facility, similar to account schedule
        IF IS.PARTICIPANT THEN
            IF PARTICIPANT.PRESENT.VALUE<1,PART.POS> GT 0 THEN
                PRESENT.VALUE.FOUND = 1 ;*Set this flag when participant os amount is GT 0
            END
        END ELSE
            IF PRESENT.VALUE GT 0 THEN
                PRESENT.VALUE.FOUND = 1 ;*else borrower OS amount is GT 0
            END
        END
    END

    REDUCE.CALC.AMT.TAX = "1" ;* Flag to denote calc amt to be reduced or not when tax is set as inclusive, for payment holiday calculation. reduce by default
    BEGIN CASE
        CASE PAYMENT.PROPERTY.CLASS EQ "HOLIDAY-CHARGE"
            PAYMENT.PROPERTY.AMOUNT = PAYMENT.AMOUNT.LIST<1, PAY.TYPE.I> ;* Update due amounts for each property
            PS.CALC.AMOUNT = PAYMENT.AMOUNT.LIST<1, PAY.TYPE.I> ;* Update due amounts for each property
** If the effective date is greater than the Holiday Start date then Check HOL balance amount Before make due it.
            LOCATE PAYMENT.PROPERTY IN HOLIDAY.PROPERTIES<1> SETTING PROP.POS THEN
                
                CURRENT.PROP.HOLIDAY.DATES = ACD.HOLIDAY.PROP.DATES<PROP.POS>
                HOL.PROP.LAST.PAYMENT.DATE = HOLIDAY.LAST.PAYMENT.DATES<PROP.POS>
                NO.DATES = DCOUNT(CURRENT.PROP.HOLIDAY.DATES, @VM)
                
                ACTUAL.TYPE.START.DATE = CURRENT.PROP.HOLIDAY.DATES<1,1>
                ACTUAL.TYPE.END.DATE =  CURRENT.PROP.HOLIDAY.DATES<1,NO.DATES>

                
*** If my system is in Holiday Period then take the CALC.AMOUNT as HOLIDAY.INTEREST and don't look in to the Actual HOL<INTEREST>
                DEFER.HOLIDAY.PERIOD = ""
                
                IF NOT(SCHEDULE.INFO<72>) THEN             ;* during Holiday Interest amount calculation don't consider Defer holiday period
                    GOSUB CHECK.HOLIDAY.PERIOD        ;* Check current system date is Holiday Period or Repayment Period
                END
                
                IF NOT(DEFER.HOLIDAY.PERIOD) THEN
                    GOSUB GET.HOLIDAY.PAYMENT.AMOUNT
                END ELSE
                    IF SCHEDULE.INFO<8> AND HOLIDAY.BILL.PRESENT THEN
                        PAYMENT.PROPERTY.AMOUNT = HOL.PROP.AMT
                    END ELSE

*** Don't execute below set of logic during the calculation of the Holiday interest from Calc Holiday Interest routine.
*** System shouldn't consider the Account Details amount during the Calc amount calculation.
                    
                        IF NOT(SCHEDULE.INFO<52>) THEN
                            GOSUB GET.HOLIDAY.PROJECTION.PAYMENT.AMOUNT      ;* This gosub to get the Holiday payment amount during Holiday period. It will look in to the account details to get the Total Holiday amount
                        END
                    END
                END
            END
            
*** Redue the Current payment amount also from Overall Holiday Utilisation

            IF NOT(RESTRICTED.PROPERTY) AND HOLIDAY.AMOUNT THEN ;* When non restricted property comes,decrement the holiday amount from calculated charge amount to utilise remaining amount for other properties
                IF NOT(SCHEDULE.INFO<72>) THEN
                    HOLIDAY.AMOUNT -= PAYMENT.PROPERTY.AMOUNT
                END ELSE
                    IF PAYMENT.PROPERTY.AMOUNT GE HOLIDAY.AMOUNT THEN
                        PAYMENT.PROPERTY.AMOUNT = PAYMENT.PROPERTY.AMOUNT - HOLIDAY.AMOUNT
                        HOLIDAY.AMOUNT = 0
                    END ELSE
                        PAYMENT.PROPERTY.AMOUNT = 0
                        HOLIDAY.AMOUNT = HOLIDAY.AMOUNT - PAYMENT.PROPERTY.AMOUNT
                    END
                END
            END

*** Additional check to not to carry forword Holiday Interest to next property

            IF NOT(PS.CALC.AMOUNT) AND  HOLIDAY.AMOUNT THEN
                HOLIDAY.AMOUNT = 0
            END
            IF HOLIDAY.AMOUNT AND HOLIDAY.AMOUNT LE 0 THEN ;* If holiday amount goes less than or equal to zero,then make is as zero
                HOLIDAY.AMOUNT = 0
            END
            
* Do tax calculations
            BASE.AMOUNT = PAYMENT.PROPERTY.AMOUNT
            BASE.PROPERTY = PAYMENT.PROPERTY
           
            ARRANGEMENT.INFO<3> = ""; ARRANGEMENT.INFO<4> = "" ; ARRANGEMENT.INFO<5> = ""
*** Skip Gross tax calculation flag should be set for makedue and the respective issuebill*paymentType which does not have ACCOUNT property and Pay method with GROSS passed in the AAA context.
            IF CURRENT.ACTIVITY MATCHES "ISSUEBILL":@VM:"MAKEDUE" AND (PAYMENT.TYPE.LIST<1, PAY.TYPE.I> EQ AF.Framework.getCurrActivity()["*",2,1] OR CURRENT.ACTIVITY EQ "MAKEDUE") THEN
                ARRANGEMENT.INFO<9> = 1 ;* Skip gross flag should be set by default
            END
                        
            IF BASE.AMOUNT THEN
                PRINCIPAL.INFLOW = ""   ;* Indicate account disburement/funding amount
                GOSUB CALCULATE.TAX.AMOUNT
            END
        
        CASE PAYMENT.PROPERTY.CLASS EQ "CHARGE"       ;* Do charge calculations
            CAP.AMOUNT = 0  ;* initialise the cap amount to 0 in each cycle
            IF BILL.PROPERTY.AMOUNT NE "" THEN        ;* For Advance schedule bills the charge is freezed. So, the os amount will be or.prop.amount - sum of repaid amount
                CHARGE.AMOUNT = BILL.PROPERTY.AMOUNT
            END ELSE
                GOSUB CHECK.CALC.CHARGE.REQUIRED ;*check if it is for payoff process and set the calculate charge flag.
                IF CALCULATE.CHARGE THEN
                    GOSUB CALCULATE.CHARGE.AMOUNT
                END
            END
        
            HOLIDAYINTAMT.TAXCALC = "" ;* flag to denote tax calculation on holiday amount
            TAX.BASE.AMOUNT = "" ;* save original base amount to calculate tax and reduce the calc amount for tax inclusive setup
            BEGIN CASE
                CASE SCHEDULE.INFO<8> AND DEFER.ALL.HOLIDAY.FLAG AND NOT(RESTRICTED.PROPERTY)
                    PAYMENT.PROPERTY.AMOUNT = HOLIDAY.AMOUNT
                    IF HOLIDAY.AMOUNT GT CHARGE.AMOUNT THEN
                        PAYMENT.PROPERTY.AMOUNT = CHARGE.AMOUNT
                    END
                    TAX.BASE.AMOUNT = CHARGE.AMOUNT
                    HOLIDAYINTAMT.TAXCALC = 1
                CASE (SCHEDULE.INFO<51> OR SCHEDULE.INFO<72>) AND DEFER.ALL.HOLIDAY.FLAG AND NOT(RESTRICTED.PROPERTY)
                    PAYMENT.PROPERTY.AMOUNT = CHARGE.AMOUNT - HOLIDAY.AMOUNT
                    IF PAYMENT.PROPERTY.AMOUNT LT 0 THEN
                        PAYMENT.PROPERTY.AMOUNT = 0
                    END
                CASE (HOLIDAY.AMOUNT AND HOLIDAY.AMOUNT LE CHARGE.AMOUNT) OR (NOT(HOLIDAY.AMOUNT) AND HOLIDAY.DATE) AND NOT(RESTRICTED.PROPERTY)  ;* When the holiday amount less than or equal to calculated charge amount,assign property amount as holiday amount.
                    PAYMENT.PROPERTY.AMOUNT = HOLIDAY.AMOUNT
                CASE 1
                    PAYMENT.PROPERTY.AMOUNT = CHARGE.AMOUNT ;* Otherwise assign calculated charge amount to property amount
            END CASE
    
            IF NOT(RESTRICTED.PROPERTY) AND HOLIDAY.AMOUNT THEN ;* When non restricted property comes,decrement the holiday amount from calculated charge amount to utilise remaining amount for other properties
                HOLIDAY.AMOUNT -= CHARGE.AMOUNT
            END
            IF HOLIDAY.AMOUNT AND HOLIDAY.AMOUNT LE 0 THEN ;* If holiday amount goes less than or equal to zero,then make is as zero
                HOLIDAY.AMOUNT = 0
            END

            IF SUM(PAYMENT.PROPERTY.AMOUNTS) THEN     ;* If local routine returns the charge/Interest/Principal value then it should take the same
                LOCATE PAYMENT.PROPERTY IN PAYMENT.PROPERTIES.LIST<1,1,1> SETTING PAYPROP.POS THEN
                    PAYMENT.PROPERTY.AMOUNT = PAYMENT.PROPERTY.AMOUNTS<1,1,PAYPROP.POS>
                END
            END

* Do tax calculations
            BASE.AMOUNT =  PAYMENT.PROPERTY.AMOUNT
            BASE.PROPERTY = PAYMENT.PROPERTY
            LOCATE BILL.TYPE IN BILL.TYPE.ARRAY<1,1> SETTING BILL.TYPE.POS THEN
                PAY.BILL.TYPE = BILL.TYPE.ARRAY<2, BILL.TYPE.POS>
            END ELSE
                AA.PaymentSchedule.GetSysBillType(BILL.TYPE, PAY.BILL.TYPE, '')
                BILL.TYPE.ARRAY<1,-1> = BILL.TYPE
                BILL.TYPE.ARRAY<2,-1> = PAY.BILL.TYPE
            END
                                           
*** Skip Gross tax calculation flag should be set for makedue and the respective issuebill*paymentType which does not have ACCOUNT property and Pay method with GROSS passed in the AAA context.
            IF CURRENT.ACTIVITY MATCHES "ISSUEBILL":@VM:"MAKEDUE" AND (PAYMENT.TYPE.LIST<1, PAY.TYPE.I> EQ AF.Framework.getCurrActivity()["*",2,1] OR CURRENT.ACTIVITY EQ "MAKEDUE") THEN
                ARRANGEMENT.INFO<9> = 1 ;* Skip gross tax flag should be set by default
            END
        
            IF PAY.BILL.TYPE NE 'INTERNAL' THEN ;*Skip tax calculation for internal bill type
                IF CAP.CHARGE.AMT AND DUE.AND.CAP THEN                              ;* For DUE.AND.CAP payment type, if there is any capitalised amount for charge then calculate and store tax amount saperately
                    CAP.AMOUNT = CAP.CHARGE.AMT
                    CAP.PROPERTY = PAYMENT.PROPERTY
                    GOSUB CALCULATE.CAP.TAX.AMOUNT
                END
** when tax is involved in annuity calculation for payment holiday we must reduce holiday amt with the tax portion rather than affecting the calc amt
** the calc amt will be reduced in separate calculation by reducing the tax amount calculated on origial base amount
                IF HOLIDAYINTAMT.TAXCALC AND TAX.INCLUSIVE THEN
                    SAVE.BASE.AMOUNT = BASE.AMOUNT
                    BASE.AMOUNT = TAX.BASE.AMOUNT
                    PRINCIPAL.INFLOW = ""   ;* Indicate account disburement/funding amount
                    GOSUB CALCULATE.TAX.AMOUNT          ;* calculate tax for CHARGE property
                    BASE.AMOUNT = SAVE.BASE.AMOUNT
                    REDUCE.CALC.AMT.TAX = "" ;* reset to not affect further tax processing on holiday amount
                END
                PRINCIPAL.INFLOW = ""   ;* Indicate account disburement/funding amount
                GOSUB CALCULATE.TAX.AMOUNT
            END

* Update principal balance if charge is capitalised
* If Deposits, Reduce the Tax from Charge amount and add the Tax if Loans.
**For DUE.AND.CAP payment type when there is capitalisation of Interest then this amount will need to be added to the principal
            IF CAP.CHARGE.AMT AND DUE.AND.CAP THEN                                   ;* if cap amount is found we need to only update this amount into pricnipal
                UPDATE.AMOUNT = CAP.CHARGE.AMT - CAP.TAX.AMOUNT      ;* The due amount would not be need to be updated into the principal
                CAP.UPDATE.PRINCIPAL.BALANCE = 1
            END ELSE
                UPDATE.AMOUNT = CHARGE.AMOUNT - TAX.AMOUNT
            END
            GOSUB UPDATE.PRINCIPAL.BALANCE
            
            TEMP.BORROWER.AMOUNT = CHARGE.AMOUNT            ;* Store Calculated property amount for Borrower

        CASE PAYMENT.PROPERTY.CLASS EQ "HOLIDAY-INTEREST"

            PAYMENT.PROPERTY.AMOUNT = PAYMENT.AMOUNT.LIST<1, PAY.TYPE.I> ;* Update due amounts for each property
            PS.CALC.AMOUNT = PAYMENT.AMOUNT.LIST<1, PAY.TYPE.I> ;* Update due amounts for each property
      
** If the effective date is greater than the Holiday Start date then Check HOL balance amount Before make due it.
            LOCATE PAYMENT.PROPERTY IN HOLIDAY.PROPERTIES<1> SETTING PROP.POS THEN
                
                CURRENT.PROP.HOLIDAY.DATES = ACD.HOLIDAY.PROP.DATES<PROP.POS>
                HOL.PROP.LAST.PAYMENT.DATE = HOLIDAY.LAST.PAYMENT.DATES<PROP.POS>
                NO.DATES = DCOUNT(CURRENT.PROP.HOLIDAY.DATES, @VM)
                
                ACTUAL.TYPE.START.DATE = CURRENT.PROP.HOLIDAY.DATES<1,1>
                ACTUAL.TYPE.END.DATE =  CURRENT.PROP.HOLIDAY.DATES<1,NO.DATES>

                
*** If my system is in Holiday Period then take the CALC.AMOUNT as HOLIDAY.INTEREST and don't look in to the Actual HOL<INTEREST>
                DEFER.HOLIDAY.PERIOD = ""
                
                IF NOT(SCHEDULE.INFO<72>) THEN             ;* during Holiday Interest amount calculation don't consider Defer holiday period
                    GOSUB CHECK.HOLIDAY.PERIOD        ;* Check current system date is Holiday Period or Repayment Period
                END
                
                IF NOT(DEFER.HOLIDAY.PERIOD) THEN
                    GOSUB GET.HOLIDAY.PAYMENT.AMOUNT
                END ELSE
                    IF SCHEDULE.INFO<8> AND HOLIDAY.BILL.PRESENT THEN
                        PAYMENT.PROPERTY.AMOUNT = HOL.PROP.AMT
                    END ELSE

*** Don't execute below set of logic during the calculation of the Holiday interest from Calc Holiday Interest routine.
*** System shouldn't consider the Account Details amount during the Calc amount calculation.
                    
                        IF NOT(SCHEDULE.INFO<52>) THEN
                            GOSUB GET.HOLIDAY.PROJECTION.PAYMENT.AMOUNT      ;* This gosub to get the Holiday payment amount during Holiday period. It will look in to the account details to get the Total Holiday amount
                        END
                    END
                END
            END
            
*** Redue the Current payment amount also from Overall Holiday Utilisation

            IF NOT(RESTRICTED.PROPERTY) AND HOLIDAY.AMOUNT THEN ;* When non restricted property comes,decrement the holiday amount from calculated charge amount to utilise remaining amount for other properties
                IF NOT(SCHEDULE.INFO<72>) THEN
                    HOLIDAY.AMOUNT -= PAYMENT.PROPERTY.AMOUNT
                END ELSE
                    IF PAYMENT.PROPERTY.AMOUNT GE HOLIDAY.AMOUNT THEN
                        PAYMENT.PROPERTY.AMOUNT = PAYMENT.PROPERTY.AMOUNT - HOLIDAY.AMOUNT
                        HOLIDAY.AMOUNT = 0
                    END ELSE
                        PAYMENT.PROPERTY.AMOUNT = 0
                        HOLIDAY.AMOUNT = HOLIDAY.AMOUNT - PAYMENT.PROPERTY.AMOUNT
                    END
                END
            END

*** Additional check to not to carry forword Holiday Interest to next property

            IF NOT(PS.CALC.AMOUNT) AND  HOLIDAY.AMOUNT THEN
                HOLIDAY.AMOUNT = 0
            END
            IF HOLIDAY.AMOUNT AND HOLIDAY.AMOUNT LE 0 THEN ;* If holiday amount goes less than or equal to zero,then make is as zero
                HOLIDAY.AMOUNT = 0
            END
            
* Do tax calculations
            BASE.AMOUNT = PAYMENT.PROPERTY.AMOUNT
            BASE.PROPERTY = PAYMENT.PROPERTY
           
            ARRANGEMENT.INFO<3> = ""; ARRANGEMENT.INFO<4> = "" ; ARRANGEMENT.INFO<5> = ""
*** Skip Gross tax calculation flag should be set for makedue and the respective issuebill*paymentType which does not have ACCOUNT property and Pay method with GROSS passed in the AAA context.
            IF CURRENT.ACTIVITY MATCHES "ISSUEBILL":@VM:"MAKEDUE" AND (PAYMENT.TYPE.LIST<1, PAY.TYPE.I> EQ AF.Framework.getCurrActivity()["*",2,1] OR CURRENT.ACTIVITY EQ "MAKEDUE") THEN
                ARRANGEMENT.INFO<9> = 1 ;* Skip gross flag should be set by default
            END
                        
            IF BASE.AMOUNT THEN
                PRINCIPAL.INFLOW = ""   ;* Indicate account disburement/funding amount
                GOSUB CALCULATE.TAX.AMOUNT
            END
               
        CASE PAYMENT.PROPERTY.CLASS EQ "INTEREST"     ;* Do interest calculations
            CAP.AMOUNT = 0                             ;* initialise as 0 in each cycle
            DEFER.HOLIDAY.INTEREST = ''
            IF BILL.PROPERTY.AMOUNT THEN
                BILL.INTEREST.AMOUNT = BILL.PROPERTY.AMOUNT
            END

**** Execute below set of logic only when user inputted the Payment Holiday activity. Otherwise not required.

            IF tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolPaymentType> THEN
                HOLIDAY.PAYMENT.DATE = PAYMENT.DATE
                GOSUB CHECK.DEFER.HOLIDAY.INTEREST
            END
        
            GOSUB CALCULATE.INTEREST.AMOUNT
            GOSUB GET.FINAL.INTEREST.AMOUNT

* Do tax calculations
            IF HOLIDAYINTAMT.TAXCALC THEN ;* Tax amount should be calculated for the Holiday Interest amount.
                BASE.AMOUNT =  PAYMENT.PROPERTY.AMOUNT
            END ELSE
                BASE.AMOUNT = TAX.BASE.AMOUNT
            END
            BASE.PROPERTY = PAYMENT.PROPERTY

* for interest property we update variable for proportional tax calculation used by AA.Tax.CalculateTax
** now we are calculating tax separately for negative and positive accruals. Hence pass total positive accrued amount
** and total negative accrued amount into ARRANGEMENT.INFO

            BANK.TAX.AMOUNT = "" ; ARRANGEMENT.INFO<3> = PERIOD.START.DATE:@VM:PERIOD.END.DATE ; ARRANGEMENT.INFO<4> = LOWER(R.ACCRUAL.DATA) ; ARRANGEMENT.INFO<5> = TOTAL.POS.AMT:@VM:TOTAL.NEG.AMT
           
*** Skip Gross tax calculation flag should be set for makedue and the respective issuebill*paymentType which does not have ACCOUNT property and Pay method with GROSS passed in the AAA context.
            IF CURRENT.ACTIVITY MATCHES "ISSUEBILL":@VM:"MAKEDUE" AND (PAYMENT.TYPE.LIST<1, PAY.TYPE.I> EQ AF.Framework.getCurrActivity()["*",2,1] OR CURRENT.ACTIVITY EQ "MAKEDUE") THEN
                ARRANGEMENT.INFO<9> = 1 ;* Skip gross flag should be set by default
            END
            IF SCHEDULE.INFO<23> EQ "FULL.CHARGEOFF" THEN
                BANK.TAX.AMOUNT = 1
            END
 
** For DUE.AND.CAP payment type, if there is any capitalised amount for I then calculate and store tax amount saperately
            IF CAP.INT.AMT AND DUE.AND.CAP THEN
                CAP.AMOUNT = CAP.TAX.BASE.AMOUNT
                CAP.PROPERTY = PAYMENT.PROPERTY
                GOSUB CALCULATE.CAP.TAX.AMOUNT
            END
                        
            IF NOT(NON.CUSTOMER.PROPERTY) THEN         ;* dont calculate tax for INTEREST property of type NON.CUSTOMER
** when tax is involved in annuity calculation for payment holiday we must reduce holiday amt with the tax portion rather than affecting the calc amt
** the calc amt will be reduced in separate calculation by reducing the tax amount calculated on origial base amount
                IF HOLIDAYINTAMT.TAXCALC AND TAX.INCLUSIVE THEN
                    SAVE.BASE.AMOUNT = BASE.AMOUNT
                    BASE.AMOUNT = TAX.BASE.AMOUNT
                    PRINCIPAL.INFLOW = ""   ;* Indicate account disburement/funding amount
                    GOSUB CALCULATE.TAX.AMOUNT          ;* calculate tax for INTEREST property
                    BASE.AMOUNT = SAVE.BASE.AMOUNT
                    REDUCE.CALC.AMT.TAX = "" ;* reset to not affect further tax processing on holiday amount
                END
                PRINCIPAL.INFLOW = ""   ;* Indicate account disburement/funding amount
                GOSUB CALCULATE.TAX.AMOUNT          ;* calculate tax for INTEREST property
            END
                                           
            ARRANGEMENT.INFO<3> = ""; ARRANGEMENT.INFO<4> = "" ; ARRANGEMENT.INFO<5> = ""

* Update principal balance if interest is capitalised
* If Deposits, Reduce the Tax from Interest amount and add the Tax if Loans.

**For DUE.AND.CAP payment type when there is capitalisation of Interest then this amount will need to be added to the principal
            IF CAP.INT.AMT AND DUE.AND.CAP THEN
                UPDATE.AMOUNT = CAP.INT.AMT - CAP.TAX.AMOUNT   ;* For DUE.AND.CAP payment type capitalised tax amount will be substarcted from capitalsed interest amount, to return the final principal amount
                CAP.UPDATE.PRINCIPAL.BALANCE = 1
            END ELSE
                UPDATE.AMOUNT = INT.AMOUNT  - TAX.AMOUNT
            END
            GOSUB UPDATE.PRINCIPAL.BALANCE
            
            TEMP.BORROWER.AMOUNT = INT.AMOUNT       ;* Store Calculated property amount for Borrower

            GOSUB POPULATE.POS.NEG.AMOUNTS ;* calculate the pos and neg amounts for interest

        CASE PAYMENT.PROPERTY.CLASS EQ "HOLIDAY-ACCOUNT"
        
            PAYMENT.PROPERTY.AMOUNT = PAYMENT.AMOUNT.LIST<1, PAY.TYPE.I> ;* Update due amounts for each property
            PS.CALC.AMOUNT = PAYMENT.AMOUNT.LIST<1, PAY.TYPE.I> ;* Update due amounts for each property
            
** If the effective date is greater than the Holiday Start date then Check HOL balance amount Before make due it.
            LOCATE PAYMENT.PROPERTY IN HOLIDAY.PROPERTIES<1> SETTING PROP.POS THEN
                
                CURRENT.PROP.HOLIDAY.DATES = ACD.HOLIDAY.PROP.DATES<PROP.POS>
                HOL.PROP.LAST.PAYMENT.DATE = HOLIDAY.LAST.PAYMENT.DATES<PROP.POS>
                NO.DATES = DCOUNT(CURRENT.PROP.HOLIDAY.DATES, @VM)
                
                ACTUAL.TYPE.START.DATE = CURRENT.PROP.HOLIDAY.DATES<1,1>
                ACTUAL.TYPE.END.DATE =  CURRENT.PROP.HOLIDAY.DATES<1,NO.DATES>

                
*** If my system is in Holiday Period then take the CALC.AMOUNT as HOLIDAY.INTEREST and don't look in to the Actual HOL<INTEREST>
                DEFER.HOLIDAY.PERIOD = ""
                
                IF NOT(SCHEDULE.INFO<72>) THEN             ;* during Holiday Interest amount calculation don't consider Defer holiday period
                    GOSUB CHECK.HOLIDAY.PERIOD        ;* Check current system date is Holiday Period or Repayment Period
                END
                
                IF NOT(DEFER.HOLIDAY.PERIOD) THEN
                    GOSUB GET.HOLIDAY.PAYMENT.AMOUNT
                END ELSE
                    IF SCHEDULE.INFO<8> AND HOLIDAY.BILL.PRESENT THEN
                        PAYMENT.PROPERTY.AMOUNT = HOL.PROP.AMT
                    END ELSE

*** Don't execute below set of logic during the calculation of the Holiday interest from Calc Holiday Interest routine.
*** System shouldn't consider the Account Details amount during the Calc amount calculation.
                    
                        IF NOT(SCHEDULE.INFO<52>) THEN
                            GOSUB GET.HOLIDAY.PROJECTION.PAYMENT.AMOUNT      ;* This gosub to get the Holiday payment amount during Holiday period. It will look in to the account details to get the Total Holiday amount
                        END
                    END
                END
            END
**Handle term.amount schedule definition for facility, similar to account schedule
        CASE (PAYMENT.PROPERTY.CLASS EQ "ACCOUNT" OR (FAC.TERM.PROPERTY AND PAYMENT.PROPERTY.CLASS EQ "TERM.AMOUNT")) AND (PRESENT.VALUE.FOUND OR PAY.BILL.TYPE MATCHES 'EXPECTED':@VM:'ADVANCE' OR (PAY.BILL.TYPE EQ 'DISBURSEMENT' AND (CUR.TERM.AMT OR AA.Framework.getContractDetails()<AA.Framework.CdIncludePrinAmounts> EQ "YES" OR INCLUDE.DISBURSE.SCHEDULE)))      ;* Calculate Account Account  Scheduled bills should generate after the disbursement so that should check the condition PRESENT.VALUE GT 0 OR PAY.BILL.TYPE matches 'EXPECTED' or 'ADVANCE'
            CAP.AMOUNT = 0                    ;* initialise as 0 for each schedule
           
            IF BILL.PROPERTY.AMOUNT THEN                                                                                                                                                                                                               ;* CUR.TERM.AMT holds value Null when IncludePrinAmounts field is set. so in additionally CdIncludePrinAmounts in common checked
                AMOUNT = BILL.PROPERTY.AMOUNT
                IF CALC.TYPE NE "MAINTAIN" THEN
                    GOSUB UPDATE.CONTRACT.DETAILS
                END ELSE
                    GOSUB UPDATE.PRESENT.VALUE
                END
            END ELSE
                GOSUB CALCULATE.AMOUNT
            END

            IF PAYMENT.PROPERTY.AMOUNT OR PAYMENT.PROPERTY.AMOUNT EQ '' OR (DEFER.ALL.HOLIDAY.FLAG AND NOT(RESTRICTED.PROPERTY) AND HOLIDAY.PROPERTY.AMOUNT NE '' AND SCHEDULE.INFO<8> AND HOLIDAY.DATE) ELSE ;* During projection call need to show holiday principal amount for the Holiday date, instead of showing original principal amount
                PAYMENT.PROPERTY.AMOUNT = AMOUNT
            END
        
            TEMP.BORROWER.AMOUNT = AMOUNT           ;* Store Calculated property amount for Borrower
             
            BASE.AMOUNT = PAYMENT.PROPERTY.AMOUNT
            BASE.PROPERTY = PAYMENT.PROPERTY

*** For ISSUEBILL and MAKEDUE activity except for PAY type ACCOUNT property with GROSS TAX.CALC.METHOD being passed, skip tax calculation.
            
            IF CURRENT.ACTIVITY MATCHES "ISSUEBILL":@VM:"MAKEDUE" AND (PAYMENT.TYPE.LIST<1, PAY.TYPE.I> EQ AF.Framework.getCurrActivity()["*",2,1] OR CURRENT.ACTIVITY EQ "MAKEDUE") THEN
                ARRANGEMENT.INFO<9> = 1
                LOCATE "TAX.CALC.METHOD" IN AF.Framework.getC_arractivityrec()<AA.Framework.ArrangementActivity.ArrActContextName, 1> SETTING CONTEXT.POS THEN
                    IF AF.Framework.getC_arractivityrec()<AA.Framework.ArrangementActivity.ArrActContextValue, CONTEXT.POS> EQ "GROSS" AND PAYMENT.PROPERTY.CLASS EQ "ACCOUNT" AND PAYMENT.METHOD.NEW AND PAYMENT.METHOD.NEW EQ "PAY" THEN
                        GROSS.ACCOUNT.PAY<1,PAY.TYPE.I> = 1 ;* Gross Tax calculation is allowed for this payment type with ACCOUNT property and method as PAY.
                        ARRANGEMENT.INFO<9> = ''
                    END
                END
            END
             
            PRINCIPAL.INFLOW = PAY.BILL.TYPE MATCHES "DISBURSEMENT":@VM:"EXPECTED"  ;* Indicate account disburement/funding amount
            GOSUB CALCULATE.TAX.AMOUNT          ;* calculate tax for ACCOUNT property
                        
*** For GROSS TAX.CALC.METHOD which is passed in the  AAA's Context and for PAY type of ACCOUNT, add the calcualted tax amount to the account property amount.
*** We should add the tax amount in CURACCOUNT and the entire amount will be credited to the PAYACCOUNT during account gross pay.
*** From the PAYACCOUNT, the tax will be debitted and credited to the bank's internal account.

            IF GROSS.ACCOUNT.PAY<1, PAY.TYPE.I> AND PAY.BILL.TYPE NE "DISBURSEMENT" THEN
                PAYMENT.PROPERTY.AMOUNT += ABS(TAX.AMOUNT) ;* Add the gross tax to the account property if we have gross calculation for this payment type.
            END
        
            IF SUM(PAYMENT.PROPERTY.AMOUNTS) THEN     ;* If local routine returns the charge/Interest/Principal value then it should take the same
                LOCATE PAYMENT.PROPERTY IN PAYMENT.PROPERTIES.LIST<1,1,1> SETTING PAYPROP.POS THEN
                    GOSUB VERIFY.PROPERTY.AMOUNT
                END
            END
** If the Payment Amount is more than the available CUR, then calculate the UTL portion that is going to be effected since the UTL portion will be reduced and OVD will be raised
            IF FAC.TERM.PROPERTY AND NOT(IS.PARTICIPANT) THEN
** Calculate the borrower UTL balance amount after payment amount reduction. This will be used to calculate the UTL portion of the participant
                IF (ABS(SAVE.TOT.TERM.AMT<1>) - ABS(PAYMENT.PROPERTY.AMOUNT)) LT ABS(SAVE.UTL.TERM.AMT<1>) THEN
                    BORR.UTL.CHANGE.AMOUNT = ABS(SAVE.TOT.TERM.AMT<1>) - ABS(PAYMENT.PROPERTY.AMOUNT)
                END ELSE
                    BORR.UTL.CHANGE.AMOUNT = SAVE.UTL.TERM.AMT<1>
                END
            END

** This case statement only for raising the error message. If the Present value Less than or equals to zero and we define
** the Actual amount then raise the error message.

        CASE PAYMENT.PROPERTY.CLASS EQ "ACCOUNT" AND (PRESENT.VALUE LE 0 OR PAY.BILL.TYPE NE 'EXPECTED')
            GOSUB CHECK.ACTUAL.AMOUNT
        
        CASE PAYMENT.PROPERTY.CLASS EQ "PERIODIC.CHARGES"       ;* For advance repayments, consider Periodic charges also
            BASE.AMOUNT = CALC.AMOUNT
            PAYMENT.PROPERTY.AMOUNT = CALC.AMOUNT
            BASE.PROPERTY = PAYMENT.PROPERTY

*** Skip Gross tax calculation flag should be set for makedue and the respective issuebill*paymentType which does not have ACCOUNT property and Pay method with GROSS passed in the AAA context.
            IF CURRENT.ACTIVITY MATCHES "ISSUEBILL":@VM:"MAKEDUE" AND (PAYMENT.TYPE.LIST<1, PAY.TYPE.I> EQ AF.Framework.getCurrActivity()["*",2,1] OR CURRENT.ACTIVITY EQ "MAKEDUE") THEN
                ARRANGEMENT.INFO<9> = 1 ;* Skip gross flag should be set by default
            END
            PRINCIPAL.INFLOW = ""   ;* Indicate account disburement/funding amount
            GOSUB CALCULATE.TAX.AMOUNT          ;* Calculate the Tax amount from the Charge component
            GOSUB UPDATE.PRINCIPAL.BALANCE      ;* Update the repayment amounts accordingly
        
    END CASE

**Find the date position to update the capitalised Interest/Charge details for DUE.AND.CAP payment type
    LOCATE PAYMENT.DATE IN CAP.PAYMENT.DATES BY 'AN' SETTING CAP.DATE.POS THEN
    END
 
    IF PAYMENT.MODE EQ "ADVANCE" THEN   ;* Check Payment Mode is advance then set the position of current date
        IF INT.AMOUNT THEN    ;* Check if Interest calculated then assign the amount to previous position
            IF ADVANCE.HOL.POS GT 1 OR SAVE.HOLIDAY.AMOUNT THEN   ;* There is a holiday present before the current processing payment date and so add the interest in the current payment date interest position itself since its advance position is holiday
                IF SAVE.HOLIDAY.AMOUNT THEN
                    INT.AMOUNT = SAVE.HOLIDAY.AMOUNT
                END
                PAYMENT.AMOUNT.LIST<1,PAY.TYPE.I,PROPERTY.I> = INT.AMOUNT  ;* Update due amounts for each property
            END ELSE
                PAYMENT.PROPERTIES.AMT<ADV.VAL, ADV.PROP.POS,PROPERTY.I> = INT.AMOUNT
                TAX.DETAILS<ADV.VAL, ADV.PROP.POS,PROPERTY.I> = TAX.LIST
           
            END
** Fix was added for interest advance payment type,the Pos nd Neg amount is misplaced its position so we have added up here along with its Payment Prop amount.
            FINAL.PAYMENT.POS.AMT<ADV.VAL, ADV.PROP.POS,PROPERTY.I> = PAYMENT.PROPERTY.POS.AMOUNT  ;* append all the positive interest amounts
            FINAL.PAYMENT.NEG.AMT<ADV.VAL, ADV.PROP.POS,PROPERTY.I> = PAYMENT.PROPERTY.NEG.AMOUNT  ;* append all the Negative interest amounts

        END
        ADV.POS<PAY.DATE.I, PAY.TYPE.I> = PAY.DATE.I          ;* Set the position
        IF IS.PARTICIPANT THEN
            GOSUB UPDATE.PARTICIPANT.TAX.DETAILS                    ;* Update Tax details for Participant
        END ELSE
            TAX.DETAILS.LIST<1, PAY.TYPE.I, PROPERTY.I>  =  ""
        END
    END ELSE
                 
** When Processed for Borrower, store calculated amount list to use while calculation ProRata for the participants.
** When processed for a participant, calculate pro-rata amount and overwrite the new value in PAYMENT.AMOUNT.LIST

        IF IS.PARTICIPANT THEN
            GOSUB UPDATE.PARTICIPANT.DATA       ;* Calculate Pro-rata amount for Participant
        END ELSE
            BORROWER.CALC.AMT<1, PAY.TYPE.I, PROPERTY.I> = TEMP.BORROWER.AMOUNT     ;* Store Borrower property amount to use while updating Participant amounts
        END
        PAYMENT.AMOUNT.LIST<1,PAY.TYPE.I,PROPERTY.I> = PAYMENT.PROPERTY.AMOUNT  ;* Update due amounts for each property
        PAYMENT.AMOUNT.POS.LIST<1,PAY.TYPE.I,PROPERTY.I> = PAYMENT.PROPERTY.POS.AMOUNT
        PAYMENT.AMOUNT.NEG.LIST<1,PAY.TYPE.I,PROPERTY.I> = PAYMENT.PROPERTY.NEG.AMOUNT
        
        IF DUE.AND.CAP THEN                                                            ;* store the cap amount and details of DUE.AND.CAP payment type
            CAP.PAYMENT.AMOUNT.LIST<CAP.DATE.POS, PAY.TYPE.I,PROPERTY.I> = CAP.AMOUNT  ;* Update due amounts for each property
            CAP.PAYMENT.PROPERTY.LIST<CAP.DATE.POS, PAY.TYPE.I,PROPERTY.I> = PAYMENT.PROPERTY.LIST<1, PAY.TYPE.I,PROPERTY.I>
        END
    END
    PAYMENT.METHOD.LIST<1,PAY.TYPE.I> = PAYMENT.METHOD.NEW
    
    IF DUE.AND.CAP THEN                                                             ;* store the remaining details as well for DUE.AND.CAP payment type
        CAP.PAYMENT.METHOD.LIST<CAP.DATE.POS, PAY.TYPE.I> = "CAPITALISE"            ;*Payment method will always be CAPITALISE for the capitalised Interest/Charge
        CAP.BILL.PAY.TYPE.LIST<CAP.DATE.POS, PAY.TYPE.I> = BILL.PAY.TYPE.LIST<1, PAY.TYPE.I>  ;* Capitalised bill types in case of DUE.AND.CAP payment type
        CAP.PAYMENT.TYPE.LIST<CAP.DATE.POS, PAY.TYPE.I> = PAYMENT.TYPE.LIST<1, PAY.TYPE.I>    ;* payment types in case of DUE.AND.CAP payment type
        CAP.PAYMENT.DATES<CAP.DATE.POS> = PAYMENT.DATE
    END
    
    
    IF NOT(PAYMENT.PROPERTY.CLASS MATCHES "HOLIDAY-INTEREST":@VM:"HOLIDAY-ACCOUNT") THEN    ;* Do not update last payment date in common variable since the very next schedule of normal interest would accrue from this holiday schedule date which is wrong!
        GOSUB BUILD.PROPERTY.DATES          ;* Build cycled dates for each property by payment type
    END
** When processing Borrower, store last payment date, payment end, start date for processing Participant for the same PAYMENT.DATE
** When processing Participant, use the Borrower start and end dates.
    IF NOT(IS.PARTICIPANT) AND SCHEDULE.INFO<28> THEN
        BORROWER.PERIOD.START.DATE<1,PAY.TYPE.I,PROPERTY.I> = PERIOD.START.DATE
        BORROWER.PERIOD.END.DATE<1,PAY.TYPE.I,PROPERTY.I> = PERIOD.END.DATE
        BORROWER.LAST.PAYMENT.DATE<1,PAY.TYPE.I,PROPERTY.I> = LAST.PAYMENT.DATE
        BORROWER.TOT.DIS.AMT = TOT.DIS.AMT              ;* save total disbursement amount calculated for current PAYMENT.DATE
    END
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= Get Bill amount>
*** <desc>Get bill property amount</desc>
VERIFY.PROPERTY.AMOUNT:

    IF PAYMENT.PROPERTY.AMOUNTS<1,1,PAYPROP.POS> LE PRESENT.VALUE THEN          ;*Okay if user defined amount doesn't exceed available amount
        PAYMENT.PROPERTY.AMOUNT = PAYMENT.PROPERTY.AMOUNTS<1,1,PAYPROP.POS>
    END

RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= Populate pos neg amounts>
*** <desc>Calculate the final pos and neg amounts based on any adjustment</desc>
POPULATE.POS.NEG.AMOUNTS:

** check if there is any adjustment in final interest amount calculated. Then we need to handle the pos and neg amounts also
** we need to know how much we need to increase pos when amount is increased and how much we need to increase neg when amount is decreased
** Generally (OS is outstanding amount):
** OS = POS - NEG
** OS + NEG = POS
** POS - OS = NEG

** below is the calculation logic for getting new pos amount where X is the amount to be added :
** NEWOS + NEG = NEWPOS
** NEWOS + NEG = POS + X
** X= NEWOS + NEG - POS

**** below is the calculation logic for getting new neg amount where X is the amount to be subtracted from neg to make it more negative :
**  POS - NEWOS = NEWNEG
**  POS - NEWOS = NEG + X
**  X = POS -NEWOS - NEG
    SUM.POS.NEG = TOTAL.POS.AMT + TOTAL.NEG.AMT ;* take the sum of positive and negative amounts
    IF ABS(SUM.POS.NEG) NE PAYMENT.PROPERTY.AMOUNT THEN ;* if pos and neg sum is not same as calculated interest amount then adjust pos and neg
        DIFFERENCE.AMOUNT = PAYMENT.PROPERTY.AMOUNT - ABS(SUM.POS.NEG) ;* get the adjustment amount
        IF DIFFERENCE.AMOUNT GT 0 THEN
            TOTAL.POS.AMT = TOTAL.POS.AMT + ((PAYMENT.PROPERTY.AMOUNT + ABS(TOTAL.NEG.AMT)) - TOTAL.POS.AMT) ;* if interest is getting increased, calculate new pos amount
        END ELSE
            TOTAL.NEG.AMT = TOTAL.NEG.AMT - ((TOTAL.POS.AMT - PAYMENT.PROPERTY.AMOUNT) - ABS(TOTAL.NEG.AMT)) ;* if interest is getting decreased, calculate new neg amount
        END
    END
    PAYMENT.PROPERTY.POS.AMOUNT = TOTAL.POS.AMT ;* get the calculated pos amount
    PAYMENT.PROPERTY.NEG.AMOUNT = TOTAL.NEG.AMT ;* get the calculated neg amount
    
    LOCATE PAYMENT.PROPERTY IN SOURCE.BAL.TYPE.ARRAY<1,1> SETTING SOURCE.BAL.TYPE.POS THEN
        SOURCE.BALANCE.TYPE = SOURCE.BAL.TYPE.ARRAY<2, SOURCE.BAL.TYPE.POS>
    END ELSE
        AA.Framework.GetSourceBalanceType(PAYMENT.PROPERTY, '', '', SOURCE.BALANCE.TYPE, "")
        SOURCE.BAL.TYPE.ARRAY<1,-1> = PAYMENT.PROPERTY
        SOURCE.BAL.TYPE.ARRAY<2,-1> = SOURCE.BALANCE.TYPE
    END
    
    IF SOURCE.BALANCE.TYPE EQ "DEBIT" THEN
        PAYMENT.PROPERTY.POS.AMOUNT = PAYMENT.PROPERTY.POS.AMOUNT * -1
        PAYMENT.PROPERTY.NEG.AMOUNT = PAYMENT.PROPERTY.NEG.AMOUNT * -1
    END
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= Get Bill amount>
*** <desc>Get bill property amount</desc>
GET.BILL.PROPERTY.AMOUNT:

* Get the bill amount for the property if bill issued earlier

    BILL.PROPERTY.AMOUNT = ""

    IF BILL.DETAILS THEN
        FOR BILL.DET.CNT = 1 TO BILL.CNT UNTIL BILL.PROPERTY.AMOUNT NE ""
            BILL.DETAIL.PROP = RAISE(BILL.DETAILS<BILL.DET.CNT>)
            LOCATE PAYMENT.TYPE IN BILL.DETAIL.PROP<AA.PaymentSchedule.BillDetails.BdPaymentType,1> SETTING PAY.TYPE.POSITION THEN ;*Get property amount under corresponding payment type
                LOCATE PAYMENT.PROPERTY IN BILL.DETAIL.PROP<AA.PaymentSchedule.BillDetails.BdPayProperty,PAY.TYPE.POSITION,1> SETTING PROPERTY.POS THEN
                    BILL.PROPERTY.AMOUNT = BILL.DETAIL.PROP<AA.PaymentSchedule.BillDetails.BdOrPrAmt,PAY.TYPE.POSITION,PROPERTY.POS>
                END
            END
        NEXT BILL.DET.CNT
    END

    IF PAYMENT.PROPERTY.CLASS MATCHES "CHARGE":@VM:"PERIODIC.CHARGES" THEN    ;* For advance payment, during partial repayment find the bill property amount excluding the repayment amounts.
        ADVANCE.BILL.COUNT = DCOUNT(ADVANCE.BILL.DETAILS,@FM)
        FOR ADV.CNT = 1 TO ADVANCE.BILL.COUNT
            BILL.DETAIL = RAISE(ADVANCE.BILL.DETAILS<ADV.CNT>)
            LOCATE PAYMENT.PROPERTY IN BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdProperty,1> SETTING PROPERTY.POS THEN
                BILL.PROPERTY.AMOUNT = BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdOrPropAmount,PROPERTY.POS> - SUM(BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdRepayAmount,PROPERTY.POS>)
                ADV.CNT = ADVANCE.BILL.COUNT      ;*Stop looping
            END
        NEXT ADV.CNT
    END

RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Calculate charge>
*** <desc>Calculate charge</desc>
CALCULATE.CHARGE.AMOUNT:

* Get the charge amount by calling the charge calculation routine. This routine
* will return Fixed charge or Calculated charge amount depending upon the charge
* property definition
    PART.TOT.TERM.AMT = 0
    BORROWER.TOT.TERM.AMT = 0
    CAP.CHARGE.AMT = 0                         ;* initialise the vaiarble
    ARR.BASE.AMOUNT = ''
    
    GOSUB GET.LAST.PAYMENT.DATE ;*To get the last payment date of current charge property
    GOSUB GET.PERIOD.START.END.DATE     ;*Get Period Start & End Date for the calculation

    START.DATE = PERIOD.START.DATE
    END.DATE = PERIOD.END.DATE
    IF NOT(CALC.TYPE MATCHES 'CONSTANT':@VM:'PROGRESSIVE':@VM:"PERCENTAGE":@VM:"FIXED EQUAL") AND (PAYMENT.AMOUNT.LIST<1,PAY.TYPE.I> NE '') THEN
        CHARGE.AMOUNT = PAYMENT.AMOUNT.LIST<1,PAY.TYPE.I>   ;* If the charge amount is defined in payment schedule then take it directly
    END ELSE
        R.CHARGE.RECORD = ''
        SOURCE.BALANCE = ""
        PER.CHARGE.CALC.INFO = ""
        CHARGE.SCHEDULE.DATE = PAYMENT.DATE
        CALC.REQUEST.TYPE<1> = "CURRENT"
        IF FULL.CHARGEOFF.STATUS THEN
            CALC.REQUEST.TYPE<3> = "CUST"
        END
          
        IF NOT(IS.PARTICIPANT) AND PROCESS.NON.CUST.PROP THEN
*If SCHEDULE.INFO<35> is set call CalcCharge routine with Dummy Arrangement Id to get the charge amounts from charge condition cached. SCHEDULE.INFO<35> will be set from
* ArrangementScheduleProjector routine
            ARRANGEMENT.ID.SAVE = ARRANGEMENT.ID
            IF SCHEDULE.INFO<38> THEN
                ARRANGEMENT.ID = 'DUMMY'
            END

**Force the system to calculate the charges during the projection of schedules.
            IF SCHEDULE.INFO<8> THEN
                CALC.REQUEST.TYPE<4> = 1
            END
            PROPERTY.REC = AA.ProductFramework.Property.CacheRead(PAYMENT.PROPERTY, "")
            CHARGE.ACTIVITIES = PROPERTY.REC<AA.ProductFramework.Property.PropActivity>
            IF CHARGE.ACTIVITIES THEN
                IF LAST.PAYMENT.DATE THEN
                    GOSUB PROCESS.START.DATE
                END
                CHARGE.ACTIVITIES = LOWER(CHARGE.ACTIVITIES)
                GOSUB FETCH.ACTIVITIES.FOR.ENTERPRISE.LEVEL ;*Fetch each instance of the activity and its txn.amount incase per unit is set in Fee record for Enterprise level charge calculation.
            END
              
            AA.Fees.CalcCharge(ARRANGEMENT.ID, CHARGE.SCHEDULE.DATE, PAYMENT.PROPERTY, "", R.CHARGE.RECORD, ARR.CCY, CALC.REQUEST.TYPE, ARR.BASE.AMOUNT, START.DATE, END.DATE, CHARGE.ACTIVITIES, SOURCE.BALANCE, CHARGE.AMOUNT, CHARGE.AMOUNT.LCY, PER.CHARGE.CALC.INFO, "", RET.ERROR)
            CHARGE.CALC.INFO<1,-1> = PER.CHARGE.CALC.INFO
            ARRANGEMENT.ID = ARRANGEMENT.ID.SAVE
            PREV.CHARGE.AMOUNT = CHARGE.AMOUNT ;*Save cap charge amount for participant prorata processing
        END
    END
    
    IF IS.PARTICIPANT THEN
        GOSUB GET.TOT.BALANCES
        
***Based on saved borrower amount, split charge cap amount for each participants
        IF PAYMENT.METHOD EQ "CAPITALISE" AND NOT(CHARGE.AMOUNT) THEN
            AA.PaymentSchedule.CalculateProRataAmount(PART.TOT.TERM.AMT,PREV.CHARGE.AMOUNT ,BORROWER.TOT.TERM.AMT ,CHARGE.AMOUNT, ARR.CCY, '', '', '')
        END
   
    END
   
    ROUND.AMT = CHARGE.AMOUNT
    GOSUB GET.ROUND.AMT
    CHARGE.AMOUNT = ROUND.AMT
    IF CALC.TYPE MATCHES "CONSTANT":@VM:"PROGRESSIVE":@VM:"PERCENTAGE":@VM:"FIXED EQUAL" THEN   ;* If part of annuity, reduce the remaining amount
     
        BEGIN CASE
            CASE MIC.REQD AND NOT(HOLIDAY.AMOUNT) AND CHARGE.AMOUNT GT CALC.AMOUNT ;* Minimum Invoice reqd and calculated charge amount is less than user defiend amount then consider the calcuted charge amount
                CALC.AMOUNT = 0
            CASE CHARGE.AMOUNT GT CALC.AMOUNT ;* calculated charge amount is greater than user defined amount then take the user defined amount as charge amount
** For DUE.AND.CAP payment type when an actual amount is specified in payment schedule then any excess charge amount will need to be capitalised into the principal
               
                IF DUE.AND.CAP THEN
                    CAP.CHARGE.AMT = CHARGE.AMOUNT - CALC.AMOUNT      ;*Find the excess capitalised amount
                END
                CHARGE.AMOUNT = CALC.AMOUNT
                CALC.AMOUNT = 0
            CASE 1
                CALC.AMOUNT -= CHARGE.AMOUNT
        END CASE
 
    END

    IF SCHEDULE.INFO<23> THEN
        CHARGE.AMOUNT = 0
    END

RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= Process Start Date>
*** <desc>PROCESS.START.DATE</desc>
PROCESS.START.DATE:
*** Get the previous ISSUBILL/MAKEDUE/CAPITALISE activity initiation type.
*** If it is EOD then need to do +1C, since the scheduled date activities are included in previous cycle.
*** Example
*** Scheduled E3d 21-Dec,22-Dec,23-Dec where 23-Dec is on SOD, then the start.date = 21-Dec || end.date = 23-Dec
*** 24-Dec,25-Dec,26-Dec where 26-Dec is on EOD, then the start.date = 23-Dec || end.date = 26-Dec
*** 27-Dec,28-Dec,29-Dec where 29-Dec is on SOD, then the start.date = 27-Dec || end.date = 29-Dec

    AA.Framework.ReadActivityHistory(ARRANGEMENT.ID, '', LAST.PAYMENT.DATE, R.ACTIVITY.HISTORY)
    PAYMENT.TYPE.CNT = DCOUNT(R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsPaymentType>,@VM)
    FOR CURR.CNT = 1 TO PAYMENT.TYPE.CNT
        IF R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsPaymentType, CURR.CNT> EQ PAYMENT.TYPE THEN
            LOCATE PAYMENT.PROPERTY IN R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsProperty, CURR.CNT, 1> SETTING CHARGE.PROP.POS THEN
                IF R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsIssueBill, CURR.CNT> EQ "NO" THEN
                    IF PAYMENT.METHOD EQ "CAPITALISE" THEN
                        SCHEDULE.ACTIVITY = PRODUCT.LINE:"-CAPITALISE-":SCHEDULE.INFO<3>
                    END ELSE
                        SCHEDULE.ACTIVITY = PRODUCT.LINE:"-MAKEDUE-":SCHEDULE.INFO<3>
                    END
                END ELSE
                    SCHEDULE.ACTIVITY = PRODUCT.LINE:"-ISSUEBILL-":SCHEDULE.INFO<3>:"*":PAYMENT.TYPE
                END
                CURR.CNT = PAYMENT.TYPE.CNT
            END
        END
    NEXT CURR.CNT

    LOCATE LAST.PAYMENT.DATE IN R.ACTIVITY.HISTORY<AA.Framework.ActivityHistory.AhEffectiveDate,1> SETTING LAST.PAY.DATE.POS THEN
        LOCATE SCHEDULE.ACTIVITY IN R.ACTIVITY.HISTORY<AA.Framework.ActivityHistory.AhActivity,LAST.PAY.DATE.POS,1> SETTING LAST.ACT.POS THEN
            PREVIOUS.INITIATION.TYPE = R.ACTIVITY.HISTORY<AA.Framework.ActivityHistory.AhInitiation, LAST.PAY.DATE.POS, LAST.ACT.POS>
            IF PREVIOUS.INITIATION.TYPE["*",2,1] EQ "EOD" THEN
                EB.API.Cdt('', START.DATE, "+1C")   ;* Since the activities count should be taken for current period, LastPaymentDate should not be included
            END
        END
    END
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= Calculate interest>
*** <desc>Calculate interest</desc>
CALCULATE.INTEREST.AMOUNT:
** Do interest calculations using standard interest calculation routine for AA
** Based on interest payment dates start and end dates are changed dynamically

    IF POS.NEG.FLAG EQ "FETCH.POS.NEG" THEN
        R.ACCRUAL.DETAILS = ''
    END
    CAP.INT.AMT = 0          ;* initialise the variable
    RESIDUAL.PROCESS.REQD = ''
    AA.Framework.LoadStaticData("F.AA.PROPERTY", PAYMENT.PROPERTY, R.PROPERTY, "")
    IF 'RESIDUAL.ACCRUAL' MATCHES R.PROPERTY<AA.ProductFramework.Property.PropPropertyType> THEN
        RESIDUAL.PROCESS.REQD = 1
    END

    NON.CUSTOMER.PROPERTY = ''         ;* set flag to indicate if INTEREST property is of type NON.CUSTOMER
    RISK.MARGIN.PROPERTY = ''            ;* set flag to indicate if INTEREST property is of type RISK.PARTICIPANT
    PROCESS.NON.CUST.PROP = 1                    ;* process non customer property by default
    IF "NON.CUSTOMER" MATCHES R.PROPERTY<AA.ProductFramework.Property.PropPropertyType> THEN
        NON.CUSTOMER.PROPERTY = 1
         
        IF "RISK.PARTICIPANT" MATCHES R.PROPERTY<AA.ProductFramework.Property.PropPropertyType> THEN
            RISK.MARGIN.PROPERTY = 1                    ;* flag set to indicate Risk MarginFees type property to be proceesed only for Risk Participants
            CHECK.RP.ID = PART.ID<1,PART.COUNT>
            GOSUB GET.LINKED.PORTFOLIO.ID                   ;* get linked portfolio id
        END
    
        IF PROCESS.PARTICIPANTS AND PART.ID<1,PART.COUNT> EQ 'BORROWER' THEN
            PROCESS.NON.CUST.PROP = 0                ;* ignore non customer type interest projection for borrower
        END
    END
    
    PROJECT.ACC.INTEREST = ''

    INTEREST.PROCESSED = 1    ;* Interest is processed, this works only when 1 interest property is present in the Arrangement!

    ADJUSTMENT.AMOUNT = 0
    FIX.INT.AMOUNT = ""       ;*Initialise the Fixed Interest amount

    IF CALC.TYPE NE "CONSTANT" AND CALC.TYPE NE "PROGRESSIVE" AND CALC.TYPE NE "ACCELERATED" AND CALC.TYPE NE "PERCENTAGE" AND CALC.TYPE NE "FIXED EQUAL" AND NOT(IS.PARTICIPANT) THEN   ;* is it now possible to return calculated amount through routine for Interest. Hence ignore only Annuity/Progressive type
        IF PAYMENT.MODE EQ "ADVANCE" THEN
            FIX.INT.AMOUNT = PAYMENT.AMOUNT.LIST<1,PAY.TYPE.I>
        END ELSE
            FIX.INT.AMOUNT = BORROWER.PAYMENT.AMOUNT.LIST<1,PAY.TYPE.I>
        END
    END
    IF FIX.INT.AMOUNT EQ 0 AND HOLIDAY.AMOUNT EQ 0 THEN
        FIX.INT.AMOUNT = ""    ;* holiday is defined as 0 for interest property so system has to carry forward that amount to next schedule
    END
** Get the last payment date for the current interest property
    GOSUB GET.LAST.PAYMENT.DATE
    GOSUB GET.PERIOD.START.END.DATE     ;*Get Period Start & End Date for the calculation

    LOCATE PAYMENT.PROPERTY IN INTEREST.DATA<1,1> SETTING PropPos THEN;* if accrual details are not available, fetch it
        R.ACCRUAL.DETAILS = RAISE(RAISE(INTEREST.DATA<3,PropPos>))
        INFO.ONLY.FLAG  =  INTEREST.DATA<4,PropPos>
    END ELSE
        INT.PAYMENT.PROPERTY = PAYMENT.PROPERTY
        GOSUB GET.ACCRUALS.RECORD
    END

    IF PAYMENT.MODE EQ "ADVANCE" THEN
        ADV.VAL = ''
        ADV.FLAG.COUNTER = ''
        ADV.CNT = DCOUNT(ADV.POS, @FM)
        ADV.VAL.CNT = DCOUNT(ADV.POS<ADV.CNT>, @VM) ;* Where payment types are VM separated
        FOR VAL.CNT = 1 TO ADV.VAL.CNT
            IF ADV.POS<ADV.CNT, VAL.CNT> NE '' THEN
                ADV.VAL = ADV.POS<ADV.CNT, VAL.CNT> ;* Loop to find the one has actual value
            END
        NEXT VAL.CNT

        IF NO.PREVIOUS.SCHEDULE THEN
            FOR ADV.COUNTER = 1 TO ADV.CNT
                IF ADV.POS<ADV.COUNTER> NE '' THEN
                    ADV.FLAG.COUNTER = ADV.POS<ADV.COUNTER>
                    ADV.COUNTER = ADV.CNT
                END
            NEXT ADV.COUNTER
        END
    
        LOCATE PAYMENT.PROPERTY IN PAYMENT.PROPERTIES<ADV.VAL,1> SETTING ADV.PROP.POS ELSE
            ADV.PROP.POS = ''
        END
        IF ADV.POS<ADV.VAL, ADV.PROP.POS> THEN    ;*Check the Advance interest and assign the position when Frequency is not defined
            ADV.DATE.POS = ADV.VAL
        END ELSE
            RETURN
        END
    END

** Performance tidy up, do not build huge list of accrual data the last accrued date should
** be enough to build next accrual/ interest amount for last day/first day purposes.
** AA.ACCRUE.INTEREST builds R.ACCRUAL.DATA with previous accrued information if it is
** null. This should be okay since R.ACCRUAL.DATA is only updated (i.e. TO.DATE) only
** for the next period, for which surely accruals would not be posted / updated

    R.ACCRUAL.DATA = ""
    
    IF LAST.ACCRUAL.DATE AND SCHEDULE.INFO<51> EQ '' THEN ;* Do not create un-ncessary vm (value marker)
        R.ACCRUAL.DATA<AC.Fees.EbAcToDate,1> = LAST.ACCRUAL.DATE
    END

    INT.AMOUNT = ""
    CURR.INT.AMOUNT = 0
    HOL.ST.POS = 0
    HOL.END.POS = 0
* To Enable this a New Argument "ADDITIONAL.INFO" has been added to AA.CALC.INTEREST.
* The values necessary for local hook routine will be passed in this Additional Argument.

    ADDITIONAL.INFO = ""      ;*Variable to hold payment type related information to calculate local routine returned amount

    IF CALC.TYPE EQ "OTHER" THEN        ;*Routine enabled type
        ADDITIONAL.INFO<1> = PAYMENT.TYPE         ;*Store the payment type
        ADDITIONAL.INFO<2> = LOWER(R.PAYMENT.SCHEDULE)      ;*And corresponding Payment Schedule record to pass to AA.CALC.INTEREST
        ADDITIONAL.INFO<9> = RESIDUAL.PROCESS.REQD OR RULE.78.INTEREST.TYPE  ;* Skip getting the user calculated amount when residual accrual property type and RULE.78.INTEREST.TYPE is not set.
    END
    
* When actual amount given for multiple interest payment types, interest accrual file stores actual amount for current period only. So for future
* schedules, we have to pass user given actual amount which is used for interest calculation.

    INT.ACTUAL.AMOUNT = PAYMENT.AMOUNTS<PAY.DATE.I,PAY.TYPE.I> ;* get actual amount for corresponding payment date
    IF AA.Interest.getRStoreProjection() AND CALC.TYPE EQ "ACTUAL" AND PROCESS.TYPE EQ "MANUAL" AND INT.ACTUAL.AMOUNT THEN
        ADDITIONAL.INFO<5> = INT.ACTUAL.AMOUNT
    END

    IF PROCESS.NON.CUST.PROP THEN                ;* Ignore interest projection when outstanding amt becomes zero.
* When the arrangement start date & disbursement date differs with Base Date Type set as "START" for ADVANCE type of interest,
* PAY/DUE bill is getting generated even there is no change in the interest/schedule.
* Hence overwriting the PERIOD.START.DATE with ADV.DATE.POS has to be stopped at this case to get the Adjustment amount correctly
        IF PAYMENT.MODE EQ "ADVANCE" THEN
            IF ADV.DATE.POS AND (ADV.FLAG.COUNTER NE ADV.CNT) THEN
                PERIOD.START.DATE = PAYMENT.DATES<ADV.DATE.POS>   ;* Period start date should be always previous payment date. Else system would calculate from the arrangement start date which would result in wrong interest amount.
            END
        END
    
** When Called for Participant, Send Participant Id in second position of ContractId
        CONTRACT.ID = ARRANGEMENT.ID
        IF IS.PARTICIPANT THEN
            STORE.PART.ID = PART.ID<1,PART.COUNT>
            IF SKIM.FLAG THEN ;* If skim property is defined then along with participant Id 'SKIM' is appended
                IF SKIM.PORTFOLIO THEN
                    STORE.PART.ID = STORE.PART.ID:'-':SKIM.PORTFOLIO:'*SKIM'
                END ELSE
                    STORE.PART.ID = STORE.PART.ID:'*SKIM'
                END
            END
            CONTRACT.ID<2> = STORE.PART.ID
            R.ACCRUAL.DATA = ''
            IF RISK.MARGIN.PROPERTY THEN
                CONTRACT.ID<12> = 1             ;* append flag to indicate risk margin processing
                CONTRACT.ID<25> = LINKED.PF             ;* flag set to indicate risk margin with linked portfolio processing
            END
* During Chargeoff when BOOK-BANK is being processed, ContractId should be BOOK-BANK. BOOK-BANK balances will be referred further
* when calculating Accrued Interest amount in GetBalanceCalcBasis.BOOK-BANK is appended at last position in Participants list
            IF EXTENSION.NAME EQ 'BANK' AND FIELD(PART.ID<1,PART.COUNT>, '-', 1) EQ 'BOOK' THEN
                CONTRACT.ID<8> = '1'
            END
        END
    
        IF (AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdSecuritisationPoolId> OR SCHEDULE.INFO<60> OR SCHEDULE.INFO<61> EQ "SUB.PARTICIPANT") AND PART.ID<1,PART.COUNT> EQ 'BORROWER' AND SCHEDULE.INFO<8> THEN
            CONTRACT.ID<24> = SCHEDULE.INFO<8>  ;* Flag to identify the projection for borrower
        END
        IF NOT(SCHEDULE.INFO<60>) AND NOT(SCHEDULE.INFO<8>) AND SHARE.TRANSFER.DATE THEN    ;* Make sure its not enquiry projection
            CONTRACT.ID<26> = SHARE.TRANSFER.DATE   ;* Pass share transfer activity date to CalcInterest
        END
    
        IF HOLIDAY.DATES.ARRAY AND NOT(SCHEDULE.INFO<51>) THEN ;* Only when array exists, get positions for split period interest calculation
            HOLIDAY.DATES.ARRAY = SORT(HOLIDAY.DATES.ARRAY)
            CHANGE @FM TO @VM IN HOLIDAY.DATES.ARRAY
            NO.HOL.DATES = DCOUNT(HOLIDAY.DATES.ARRAY, @VM)
*** Update PaymentHoliday is triggered to skip some schedules without repay option.
*** After crossing holiday period, trigger update PaymentHoliday to skip some more future schedules with repay
*** option as "DEFERRED". Now system considers first holiday period where repay option is null and proceed to
*** apportionate entire interest accruals to the immediate schedule post holiday period rather than
*** considering repay option defined for current holiday period.
            HOLIDAY.PAYMENT.DATE = HOLIDAY.DATES.ARRAY<1,NO.HOL.DATES>
*** Holiday Period is present in Current interst accruals calculation period

            IF (PERIOD.START.DATE LE HOLIDAY.PAYMENT.DATE) AND (PERIOD.END.DATE GT HOLIDAY.PAYMENT.DATE) THEN
                GOSUB CHECK.DEFER.HOLIDAY.INTEREST
            END
                            
            IF NOT(DEFER.HOLIDAY.INTEREST) THEN
            
                LOCATE PERIOD.START.DATE IN HOLIDAY.DATES.ARRAY<1,1> BY 'AN' SETTING HOL.ST.POS ELSE
                    INS PERIOD.START.DATE BEFORE HOLIDAY.DATES.ARRAY<1,HOL.ST.POS>
                END
                LOCATE PERIOD.END.DATE IN HOLIDAY.DATES.ARRAY<1,1> BY 'AN' SETTING HOL.END.POS ELSE
                    INS PERIOD.END.DATE BEFORE HOLIDAY.DATES.ARRAY<1,HOL.END.POS>
                END
                HOL.END.POS = HOL.END.POS - 1
            END ELSE
*** Let ignore the calculating accruals during Holiday Period Incase Holiday Interest amount deferred to repaid after End of the Holiday period
                LOCATE PERIOD.END.DATE IN HOLIDAY.DATES.ARRAY<1,1> BY 'AN' SETTING HOL.DEF.POS ELSE
                    PERIOD.START.DATE = HOLIDAY.DATES.ARRAY<1,HOL.DEF.POS-1>
                END
            END
        END
        IF HOL.ST.POS AND HOL.END.POS AND HOL.ST.POS NE HOL.END.POS THEN
            GOSUB CALC.HOLIDAY.SPLIT.INTEREST   ;*Calculate interest for holiday period split, to avoid 0.01 issue.
        END ELSE
            GOSUB CALC.INTEREST         ;* normal processing
        END
    END
           
** we take the negative and positive accrued amount from ADDITIONAL.INFO returned by ACCRUE.INTEREST but this is only the amounts which
** are currently getting accrued amount.The total negative and total positive already accrued amount will be present in ACCRUAL DETAILS
** which we are adding to amounts currently accrued. Now we need to take these amounts before any adjustement happens for the DUE amount
** because we need total negative and total positive accrual amount to calculate tax only before any adjustment. This is the logic that we
** have in AA.GET.ADJUSTED.ACCRUAL.DATA. If we take these amounts after the adjustment calculation, it will require a huge logic since we don't
** know adjustment amount is positive or negative
    TOTAL.POS.AMT = ADDITIONAL.INFO<3> ;* positive accrued amount currently accrued
    TOTAL.NEG.AMT = ADDITIONAL.INFO<4> ;* negative accrued amount currently accrued
    
** To calculate the Info Total Negative and Info Total Positive, the already accrued amounts will be found in R.ACCRUAL DETAILS, which we are adding to the amounts that are currently accrued.
    IF INFO.ONLY.FLAG THEN
        AA.ACC.PERIOD.START     = AA.Interest.InterestAccruals.IntAccInfoPeriodStart
        AA.ACC.TOT.POS.ACCR.AMT = AA.Interest.InterestAccruals.IntAccInfoTotPosAccrAmt
        AA.ACC.TOT.NEG.ACCR.AMT = AA.Interest.InterestAccruals.IntAccInfoTotNegAccrAmt
    END ELSE
        AA.ACC.PERIOD.START     = AA.Interest.InterestAccruals.IntAccPeriodStart
        AA.ACC.TOT.POS.ACCR.AMT = AA.Interest.InterestAccruals.IntAccTotPosAccrAmt
        AA.ACC.TOT.NEG.ACCR.AMT = AA.Interest.InterestAccruals.IntAccTotNegAccrAmt
    END

    LOCATE PERIOD.START.DATE IN R.ACCRUAL.DETAILS<AA.ACC.PERIOD.START, 1> SETTING PeriodStartPos THEN
        TOTAL.POS.AMT+=R.ACCRUAL.DETAILS<AA.ACC.TOT.POS.ACCR.AMT,PeriodStartPos> ;* total positive accrued amount already accrued
        TOTAL.NEG.AMT+=R.ACCRUAL.DETAILS<AA.ACC.TOT.NEG.ACCR.AMT,PeriodStartPos> ;* total negative accrued amount already accrued
    END
    
*** In case Rule 78 Payment Calculation, if Arrangement is not in Current  Status then don't issue the payment.

    IF CURRENT.ACTIVITY EQ "ISSUEBILL" OR CURRENT.ACTIVITY EQ"MAKEDUE" THEN
        IF PAYMENT.TYPE EQ "RULE.78.INTEREST" AND NOT(AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdStartDate>) THEN
            INT.AMOUNT = 0
            CURR.INT.AMOUNT = 0
            TOTAL.POS.AMT = 0
        END
    END
* This validation is to ensure that the schedules are projected correctly when we have local routine attached to the payment type and calc type mentioned as OTHER
    IF FIX.INT.AMOUNT EQ "" OR (CALC.TYPE EQ "OTHER" AND R.PAYMENT.TYPE<AA.PaymentSchedule.PaymentType.PtCalcRoutine>) THEN        ;*Only if No Actual amount is defined, go for calculated one
  
        IF CALC.TYPE EQ "OTHER" THEN    ;*Interest calculated through routine
            FIX.INT.AMOUNT = INT.AMOUNT ;*Take this as fixed interest amount
        END
                
        IF NOT(INFO.ONLY.FLAG) THEN
            GOSUB GET.PRESENT.INTEREST.ACCRUALS       ;* Get the carry over interest accrual amount
        END
             
        BEGIN CASE
            
            CASE BILL.INTEREST.AMOUNT
                DIFF.INT.AMT = CURR.INT.AMOUNT + ADJUSTMENT.AMOUNT - BILL.INTEREST.AMOUNT
                INT.AMOUNT = BILL.INTEREST.AMOUNT
                BILL.INTEREST.AMOUNT = ""
            CASE SCHEDULE.INFO<51>
                IF ADJUSTMENT.AMOUNT THEN
                    GOSUB GET.CAPTURED.AMOUNT ; * Consider adjustment interest of "CAPTURE.BALANCE" activity only for prior schedules of current processing schedule
                END
            CASE NOT(INFO.ONLY.FLAG)         ;* During Holiday Interest amount calculation don't re-concile the interest amount by accumilating both Curr and Adjustment amounts.
*** In case any make due happens then TOT.ACCR.AMT would get updated in the interest accrual record but We couldn't able to take it as Adjust interst amount from GetAdjustedInterestAmount routine.
                INT.AMOUNT =  CURR.INT.AMOUNT + ADJUSTMENT.AMOUNT         ;* now arrive at the net interest amount as current calculated interest amount + Previous month's balance (if any)
                DIFF.INT.AMT = 0
        
        END CASE
*
        INT.PROPERTY.AMOUNT = ''
        IF SUM(PAYMENT.PROPERTY.AMOUNTS) THEN     ;*Property Amounts are returned by Local routines
            LOCATE PAYMENT.PROPERTY IN PAYMENT.PROPERTY.LIST<1,1,1> SETTING PROP.LIST.POS THEN
                INT.PROPERTY.AMOUNT = PAYMENT.PROPERTY.AMOUNTS<1,1,PROP.LIST.POS>
            END
        END
*
     
* For FER while calculate TERM for new arrangement interest amount to be subtracted from actual amount
* for operating lease contracts wherein payment end date is equal to effective date, interest amount should be subtracted from actual amount (indicated by SCHEDULE.INFO<66>)
        IF (SCHEDULE.INFO<11> EQ "FER") OR (PAYMENT.END.DATE AND (EFFECTIVE.DATE LT PAYMENT.END.DATE)) OR (NOT(PAYMENT.END.DATE) AND CALL.CONTRACT) OR  (EFFECTIVE.DATE LT MAT.DATE AND NOT(PAYMENT.END.DATE)) OR (PAYMENT.END.DATE AND (PAYMENT.DATES<NO.OF.PAYMENT.DATES> GT PAYMENT.END.DATE)) OR (SCHEDULE.INFO<66>) THEN    ;*Carry forward interest should not go beyond maturity date. If amortisation term is given then consider it as last payment date for calculation.
            ALLOW.INT.ONLY = 0      ;* If the Bill amt for InterestOnly payment type is paid,so skip getting interest projection
            IF CALC.TYPE MATCHES SCHEDULE.INFO<17> AND CALC.TYPE EQ "ACTUAL" THEN
                IF BILL.DETAIL<AA.PaymentSchedule.BillDetails.BdBillStatus,1> EQ "ADVANCED" THEN    ;* Bill status wouldnt be set as settled when when there's no Os amt(Advance repayments udpate the bills and set status at AA.Payment.Schedule.Advance.Bills)
                    ALLOW.INT.ONLY = 1   ;* Allow InterestOnly payment type as well to get the latest interest amount
                END
            END
        
            IF INT.AMOUNT LT 0 THEN
                FINDSTR PAYMENT.PROPERTY IN AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdAdjustIntProp> SETTING FM.POS,VM.POS,SM.POS THEN
                    INT.AMOUNT =0
                END
            END
        
            BEGIN CASE
                CASE CALC.TYPE MATCHES "CONSTANT":@VM:"PROGRESSIVE":@VM:"ACCELERATED":@VM:"PERCENTAGE":@VM:"FIXED EQUAL" OR ALLOW.INT.ONLY ;* If the calc type is constant; Actual(InterestOnly) payments
                    IF INT.PROPERTY.AMOUNT THEN       ;*Applicable only for Progressive Type
                        ADJUSTMENT.AMOUNT = INT.AMOUNT - INT.PROPERTY.AMOUNT + DIFF.INT.AMT
                        INT.AMOUNT = INT.PROPERTY.AMOUNT
                    END ELSE
                    
                        BEGIN CASE
                            CASE MIC.REQD AND NOT(HOLIDAY.AMOUNT) AND INT.AMOUNT GT CALC.AMOUNT ;* Minimum Invoice reqd and calculated interest amount is less than user defiend amount then consider the calcuted interest amount
                                ADJUSTMENT.AMOUNT = 0
***When payment holiday is defined for INTEREST property with HOLIDAY.AMOUNT defined that is sufficient to settle CHARGE amount, then there are chances that the interest amount would get cumulative during holiday period which may lead to Interest amount become more than CALC.AMOUNT, in such cases, CALC.AMOUNT is assigned as INT.AMOUNT even during HOLIDAY period.
                            CASE INT.AMOUNT GT CALC.AMOUNT AND HOLIDAY.AMOUNT EQ ''         ;* Ensure constant amount is always maintained
** For DUE.AND.CAP payment type when an actual amount is specified in payment schedule then any excess charge amount will need to be capitalised into the principal
                                IF DUE.AND.CAP THEN
                                    CAP.INT.AMT = (DIFF.INT.AMT + INT.AMOUNT - CALC.AMOUNT)     ;*store the excess amount over the actual amount
                                    ADJUSTMENT.AMOUNT = 0                                       ;*for DUE.AND.CAP payment type , do not carry forward any adjustment amount to future schedule as any excess amount is capitalised to principal
                                END ELSE
                                    IF NOT(DEFER.HOLIDAY.INTEREST) THEN
** During advance payment where the payment amount is allocated to interest portion of partially settled bill which is in ADVANCED status, then that interest amount should not be considered as carry forward amount to next schedule because of CALC.AMOUNT becoming less than INT.AMOUNT..
** Hence reduce the repaid amount of interest portion while determining ADJUSTMENT.AMOUNT.
                                        ADJUSTMENT.AMOUNT = (DIFF.INT.AMT + INT.AMOUNT - CALC.AMOUNT - ADV.SETTLED.INT.AMT)     ;* Cycle forward the residual amount into next period
                                    END
                                END
                                IF DEFER.HOLIDAY.INTEREST AND SCHEDULE.INFO<51> ELSE
***Don't swape the amount with calc amount during user capitalisation activity(When schedule.info<64> is present. Calc amount won't be there since we are triggering this activity before due date. Hence accured interest amount should be returned as payment amount in this case
                                    IF NOT(RESTRICTED.PROPERTY) AND NOT(SCHEDULE.INFO<64>) THEN ;* Don't overwrite the Interest amount with Calc amount for restricted property.
                                        INT.AMOUNT = CALC.AMOUNT
                                    END
                                END
                        
                                IF (PAYMENT.DATE EQ PAYMENT.END.DATE) AND (AA.Interest.getRStoreProjection() OR SCHEDULE.INFO<42>) THEN ;* Include the residual interest amount on the last payment date in projection and also for cashflow
                                    INT.AMOUNT += ADJUSTMENT.AMOUNT
                                    ADJUSTMENT.AMOUNT = 0
                                END
                            CASE 1
                                IF HOLIDAY.AMOUNT NE "" AND INT.AMOUNT GT HOLIDAY.AMOUNT AND NOT(RESTRICTED.PROPERTY) THEN ;* Only consider the non-restriction type only
                                    IF NOT(DEFER.HOLIDAY.INTEREST) THEN           ;* Don't carry forward the Deferred Holiday Interest to Next Interest period. It will be collected separately
                                        ADJUSTMENT.AMOUNT = (DIFF.INT.AMT + INT.AMOUNT - HOLIDAY.AMOUNT) ;* When holiday amount defined,carry forwarding the interest amount
                                    END
                                END ELSE
                                    ADJUSTMENT.AMOUNT = DIFF.INT.AMT   ;* Clear out carry forward amount, if fully utilised
                                END
                        END CASE
                    END
*** The <32> flag indicates that this is term recalculation process. In this case we would project the profit amount based on the existing conditions before the term recalculation process
*** to determine the final schedule date and intern determine the term. but when we project scheuleds we need to ensure that the sum projected interest amounts should be to the maximum extent of the
*** existing REC profit.
                    IF SCHEDULE.INFO<32> AND AA.Framework.getFixedInterest() AND PAYMENT.PROPERTY MATCHES AA.Framework.getFixedInterest()<1> THEN    ;*Projection called from Iteration
                        REC.PROFIT = ""                                                                                                         ;* Initialise the variable to hold the current REC<INTEREST> balance.
                        AA.Interest.DetermineProfitAmount(ARRANGEMENT.ID, EFFECTIVE.DATE, PAYMENT.PROPERTY, "", "", "CURRENT", "RETRIEVE", "", REC.PROFIT, "", "", "")   ;* Fetch the current REC<INTEREST> balance. this will be the remaning profit to be collected.
*** During term recalculation, the collected profit amount sould reflect the existing REC<INTEREST> amount only.
                        LOCATE PAYMENT.PROPERTY IN AA.Framework.getFixedInterest()<1,1> SETTING FixProp THEN
                            CURRENT.CALCULATED.PROFIT = AA.Framework.getFixedInterest()<4,FixProp> + INT.AMOUNT    ;* Get the cumulative fixed profit amount
                        
                            IF CURRENT.CALCULATED.PROFIT GT REC.PROFIT THEN                                ;* We cannot exceed total profit amount
                                INT.AMOUNT -= CURRENT.CALCULATED.PROFIT - REC.PROFIT                       ;* Cap Interest amount at total profit amount
                            END
                        END
                    END
                    ACTUAL.CALC.AMOUNT = CALC.AMOUNT
                    BEGIN CASE
                        CASE MASTER.ACT.CLASS EQ "UPDATE-PAYMENT.HOLIDAY" OR MASTER.ACT.CLASS EQ "CHANGE-PAYMENT.HOLIDAY" AND NOT(HOLIDAY.DATE OR HOLIDAY.AMOUNT)
                            CALC.AMOUNT -= INT.AMOUNT     ;* Interest amount of the schedule should be reduced from annuity amount during update payment holiday/change payment holiday's validate and update stage
                        CASE (HOLIDAY.DATE OR HOLIDAY.AMOUNT) AND INT.AMOUNT GT HOLIDAY.AMOUNT AND NOT(RESTRICTED.PROPERTY) AND BILL.DETAIL AND (NOT(DEFER.ALL.HOLIDAY.FLAG) AND SCHEDULE.INFO<8>)
                            CALC.AMOUNT -= HOLIDAY.AMOUNT ;* Reduce the annuity amount for the interest amount in the bill during FORWARD.RECALCULATE activity and makedue of the bill
                        CASE 1
                            CALC.AMOUNT -= INT.AMOUNT     ;* Reduce the annuity amount for the interest calculated amount
                    END CASE
                    
***When Payment Schedule has more than one payment type Ex: Constant and interest. Property loops as ^^LOANINTEREST\PENALITYINTEREST^LOANACCOUNT. When CALC.AMOUNT is calculated
***by detucting the loaninterest amount from the principal, it is stored in CONSTANT.PRIN.AMOUNT. Else during Penalityinterest process, calc amount is nullified and it gets the CALC.AMOUNT
***from the bill to process the LOANACCOUNT.
                    IF CALC.TYPE EQ "CONSTANT" AND PAYMENT.PROPERTY.CLASS EQ "INTEREST" THEN
                        CONSTANT.PRIN.AMOUNT = CALC.AMOUNT
                    END
                CASE 1
                    GOSUB PROCESS.OTHER.PAY.TYPES     ;* for other payment types
            END CASE
        END
    END
* Within the schedules, at the final accrual period this has to be used to calculate the total past profit amounts.;*for DUE.AND.CAP payment type we have to also update the capitalized portion of interest in the common
    IF AA.Framework.getFixedInterest() AND NOT(IS.PARTICIPANT) THEN ;* We can have multiple fixed interest properties, so locate and update on the respective interest
        LOCATE PAYMENT.PROPERTY IN AA.Framework.getFixedInterest()<1,1> SETTING FixPropPos THEN
*For restructured contracts, the past accrued amounts prior to the restructure date should not be included in the FixedInterest common.
            RESTRUCTURE.DATE = AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdRestructureDate,1> ; *Get the Restructure date
            IF (PERIOD.START.DATE GE RESTRUCTURE.DATE AND RESTRUCTURE.DATE) OR NOT(RESTRUCTURE.DATE) THEN
                tmp=AA.Framework.getFixedInterest(); tmp<4,FixPropPos>=AA.Framework.getFixedInterest()<4,FixPropPos> + INT.AMOUNT + CAP.INT.AMT; AA.Framework.setFixedInterest(tmp)    ;*This will be used later to calculate the final schedule interest amount
            END
        END
    END

    IF FIX.INT.AMOUNT THEN    ;*Assign it to INT.AMOUNT for further processing
        INT.AMOUNT = FIX.INT.AMOUNT
        FIX.INT.AMOUNT = ""
    END
 
    IF REPAY.OPTION AND ADJUSTMENT.AMOUNT THEN
        GOSUB CHECK.CARRY.FORWARD.ACCRUALS        ;* Don't carry forward deferred Holiday Interest to Next Schedule
    END

 
    GOSUB UPDATE.PRESENT.INTEREST.ACCRUALS        ;* Update the residual interest amounts

    LAST.ACCRUAL.DATE = R.ACCRUAL.DATA<AC.Fees.EbAcToDate,1>     ;* Store the last accrued date
    IF AA.Interest.getRStoreProjection() THEN
        VMC = DCOUNT(R.ACCRUAL.DATA<AC.Fees.EbAcToDate>,@VM)

        FOR VIDX = VMC TO 1 STEP -1
            IF R.ACCRUAL.DATA<AC.Fees.EbAcFromDate,VIDX> GE PERIOD.START.DATE  THEN  ;**only include data Which belongs to this period
                BEGIN CASE
                    CASE SKIM.FLAG   ;* Append Participant Id and SKIM if the participant has skim property defined
                        ACCR.PROPERTY = PAYMENT.PROPERTY:"~":PART.ID<1,PART.COUNT>:"~":"SKIM"
                    CASE IS.PARTICIPANT   ;*  Append Participant Id alone when there is no skim prop defined
                        ACCR.PROPERTY = PAYMENT.PROPERTY:"~":PART.ID<1,PART.COUNT>
                    CASE 1  ;* Do not append anything when there is no participant
                        ACCR.PROPERTY = PAYMENT.PROPERTY
                END CASE
                CALC.DETAILS = ACCR.PROPERTY:"*":PERIOD.END.DATE
                FOR IDX = AC.Fees.EbAcFromDate TO AC.Fees.EbAcCompoundYield
                    CALC.DETAILS := "*":R.ACCRUAL.DATA<IDX,VIDX>
                NEXT IDX
                tmp=AA.Interest.getRProjectedAccruals(); tmp<-1>=CALC.DETAILS; AA.Interest.setRProjectedAccruals(tmp)
            END
        NEXT VIDX
    END

** Current period interest amount less than zero then this is negative interest

    READ.ERR = ''
    BALANCE.TYPE = ''
    PROPERTY = PAYMENT.PROPERTY
    PAYOFF.CAPITALISE = 0
    PAYOFF.PAYMENT.METHOD = ""
    LOCATE PROPERTY IN SOURCE.BAL.TYPE.ARRAY<1,1> SETTING SOURCE.BAL.TYPE.POS THEN
        BALANCE.TYPE = SOURCE.BAL.TYPE.ARRAY<2, SOURCE.BAL.TYPE.POS>
    END ELSE
        AA.Framework.GetSourceBalanceType(PROPERTY, '', '', BALANCE.TYPE, READ.ERR)   ;* Get the calculation type for Interest property
        SOURCE.BAL.TYPE.ARRAY<1,-1> = PROPERTY
        SOURCE.BAL.TYPE.ARRAY<2,-1> = BALANCE.TYPE
    END

    IF INT.AMOUNT AND INT.AMOUNT LT 0 THEN  ;* If it is negative rate
        BEGIN CASE
            CASE PAYMENT.METHOD = "CAPITALISE" ;* No need to change payment method for capitalisation but get tax base amount
                GOSUB GET.TAX.BASE.AMOUNT
            CASE 1 ;* Get tax base amount as it is and then change the payment method, while changing payment method make interest amount as unsigned.
                GOSUB GET.TAX.BASE.AMOUNT
                GOSUB ADJUST.PAYMENT.METHOD
        END CASE
    END ELSE
** When Payment method defined for the interest property was mismatched with its source type
        BEGIN CASE
            CASE BALANCE.TYPE EQ "DEBIT" AND PAYMENT.METHOD = "PAY"     ;* Debit interest property should contain the PAYMENT.METHOD as DUE
                PAYMENT.METHOD.NEW = "DUE"
            CASE BALANCE.TYPE EQ "CREDIT" AND PAYMENT.METHOD = "DUE"    ;* Credit interest property should contain the PAYMENT.METHOD as PAY
                PAYMENT.METHOD.NEW = "PAY"
        END CASE
        GOSUB GET.TAX.BASE.AMOUNT ;* Just get the base amount, nothing else need to be done
    END
*** The calculated negative interest amount should be assign with the absolute amount only if it was not payoff capitalise.This logic will be included in ADJUST.PAYMENT.METHOD gosub.Since if negative interest defined in interest condition with source type
*** as credit and Payment method as Pay system will assign the payment method as "due" and negative interest amount made as absolute amount. So, while generating the Payoff statement
*** interest amount would be displayed as positive which is wrong. Since, here we make the negative interest amount as absolute and payment method assigned as "Due". This will be returned
*** to PaymentScheduleCapitalise routine and Paymentmethods, Payment amounts assigned in the CdPaymentMethods,CdPaymentPropertiesAmount. In AA.PAYMENT.SCHEDULE.ISSUE.BILL while building the
*** bill details for the interest Payment method has been modified as "CAPIALISE" if it is the Payoff Capitalise process. Due to this, system will update the Payment indicator as "credit".
*** Hence, Payoff bill generated wrongly. To avoid this, for Payoff Capitalise process system should return the negative interest amount so that payment indicator will be updated as "debit" for negative interest.
*** For the payoff capitalise system should not the assign the Interest amount as zero if it is less than zero. Because, we need the negative amount
*** to calculate the Payoff bill correctly.
    IF INT.AMOUNT LT 0 AND PAYMENT.METHOD.NEW NE "CAPITALISE" AND NOT(PAYOFF.CAPITALISE)  THEN          ;** if interest amount after adjustment is less than zero then assign zero to interest
        INT.AMOUNT = 0
    END

    IF SCHEDULE.INFO<23> THEN   ;* If it is fully charged off , dont update BNK interest
        INT.AMOUNT = 0
    END
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name=Calculate Holiday Split Interest>
*** <desc>Calculate Holiday Split Interest</desc>
CALC.HOLIDAY.SPLIT.INTEREST:
    
    SAVE.PERIOD.START.DATE = PERIOD.START.DATE
    SAVE.PERIOD.END.DATE = PERIOD.END.DATE
    SAVE.FIXED.INTEREST = AA.Framework.getFixedInterest() ;* save the current fixed interest amount so as to restore it later
    
    TEMP.INT.AMOUNT = 0
    TEMP.CURR.INT.AMOUNT = 0
    
    CNT = HOL.ST.POS
    LOOP
    WHILE CNT LE HOL.END.POS
        INT.AMOUNT = 0
        CURR.INT.AMOUNT = 0
        PERIOD.START.DATE =  HOLIDAY.DATES.ARRAY<1,CNT>
        PERIOD.END.DATE = HOLIDAY.DATES.ARRAY<1,CNT+1>
        GOSUB CALC.INTEREST
        TEMP.INT.AMOUNT += INT.AMOUNT
        TEMP.CURR.INT.AMOUNT += CURR.INT.AMOUNT
        
* in a case where last payment date is made holiday , we will loop here to 2 interest periods say 1 dec 2020 to 31st dec 2020 and 1 jan 2021 to 31st jan 2021, where 1 jan 2021 was made holiday.
* for each period iteration we need to set the fixed interest common with the interest accrued (1 dec 2020 to 31st dec 2020 period here) as that value will be used to the determine the past profit amount already accrued
* in aa.accrue.interest for the final date (31st jan 2021) accrual. Now 1 jan 2021 to 30th jan 2021 has accrued 0.22. For 31st jan final date, we will pass only the remaining amount (0 in this case) to eb.calculate.accrual
* out of the total profit amount such that we will accrue -0.22 so as to totally accrue 0 for the 2nd period. This way we ensure interest is not doubled for the last payment date.
        LOCATE PAYMENT.PROPERTY IN AA.Framework.getFixedInterest()<1,1> SETTING FixPropPos THEN
            CurrentFixedInt=AA.Framework.getFixedInterest(); CurrentFixedInt<4,FixPropPos> += INT.AMOUNT; AA.Framework.setFixedInterest(CurrentFixedInt)
        END
        
        CNT ++
    REPEAT
    
    INT.AMOUNT = TEMP.INT.AMOUNT
    CURR.INT.AMOUNT = TEMP.CURR.INT.AMOUNT
    
    PERIOD.START.DATE = SAVE.PERIOD.START.DATE
    PEROD.END.DATE = SAVE.PERIOD.END.DATE
   
    AA.Framework.setFixedInterest(SAVE.FIXED.INTEREST) ;* restore the fixed interest amount as we already have a generic code to update the final interest amount later
   
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name=Calculate Interest>
*** <desc>Calculate Interest</desc>
CALC.INTEREST:
***Passing Accrue data and details to AA.ACCRUE.INTEREST routine to avoid read on GetInterestAccruals

    LOCATE PAYMENT.PROPERTY IN INTEREST.DATA<1,1> SETTING PropPos THEN
        ADDITIONAL.INFO<6> = RAISE(INTEREST.DATA<2,PropPos>)
        ADDITIONAL.INFO<7> = RAISE(INTEREST.DATA<3,PropPos>)
    END

    IF SCHEDULE.INFO<51> THEN
        CONTRACT.ID<13> = '1'
    END
    IF ASF.OPERATING.LEASE THEN
        CONTRACT.ID<19> = ASF.OPERATING.LEASE     ;*Set the flag if the asset finance lease type is operating
    END
    
    ADDITIONAL.INFO<8> = LOWER(R.CUSTOMER)  ;* Pass customer record
    CONTRACT.ID<29> = SCHEDULE.INFO<42> ;*when Cashflow ,don't add the adjustment amount with past profit amount for final period. Hence, CONTRACT.ID<29> - new position enabled to Pass the update EB.CASHFLOW flag.
    CONTRACT.ID<30> = CHECK.CLOSURE.ACTIVITY
    CONTRACT.ID<32> = SCHEDULE.INFO<74> ;* To skip final schedule date processing during lending prepayment. 32 position is used as 31 is already been used in AccrueInterest.
    IF SCHEDULE.INFO<75> THEN
        CONTRACT.ID<33> = 1
    END
    AA.Interest.CalcInterest(CONTRACT.ID, PAYMENT.PROPERTY, EXTENSION.NAME, RECORD.START.DATE, PERIOD.START.DATE, PERIOD.END.DATE, R.ACCRUAL.DATA, INT.AMOUNT, CURR.INT.AMOUNT, ADDITIONAL.INFO, RET.ERROR)       ;*Returns Interest for the period
    CHECK.CLOSURE.ACTIVITY = ADDITIONAL.INFO<9> ; CONTRACT.ID<13> = ""
    
    IF (SCHEDULE.INFO<42> AND CURR.INT.AMOUNT EQ "0" AND MASTER.ACT.CLASS EQ "NEW-ARRANGEMENT" AND RECORD.START.DATE NE PERIOD.START.DATE) THEN
***this flag used to avoid read in AA.GET.BALANCE.CALC.BASIS repeatedly(till last payment date) for penalty interest property
***if the interest amount is zero for all payment dates
        LAST.PAYMENT.PROPERTIES.AMT.POS = DCOUNT(PAYMENT.PROPERTIES.AMT,@FM)
        LAST.PAYMENT.PROPERTIES.AMT = PAYMENT.PROPERTIES.AMT<LAST.PAYMENT.PROPERTIES.AMT.POS>
        TEMP.PAYMENT.PROPERTY.LIST = PAYMENT.PROPERTY.LIST
        
        CONVERT @SM TO @VM IN TEMP.PAYMENT.PROPERTY.LIST
        CONVERT @SM TO @VM IN LAST.PAYMENT.PROPERTIES.AMT
        
        LOCATE PAYMENT.PROPERTY IN TEMP.PAYMENT.PROPERTY.LIST<1,1> SETTING LAST.POS THEN
            IF LAST.PAYMENT.PROPERTIES.AMT<1,LAST.POS> EQ "0" THEN
                SKIP.PENALTY.INTEREST = 1
                SKIP.PENALTY.PROPERTY = PAYMENT.PROPERTY
            END
        END
    END
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name=Get Period dates from accruals>
*** <desc>Get Period dates from accruals</desc>
GET.PERIOD.START.END.DATE:

    PERIOD.START.DATE = ""
    PERIOD.END.DATE = ""
    BEGIN CASE
        CASE IS.PARTICIPANT                     ;* for Participant, rely on borrower period start and end date from same PAYMENT.DATE processing
            GOSUB GET.PARTICIPANT.PERIOD.START.END.DATE         ;* populate period start & end date for participants
        CASE LAST.PAYMENT.DATE AND NOT(FIRST.INTEREST.PROJECTION) AND NOT(IS.PARTICIPANT)      ;*Cycling might have happened - rely on LAST.PAYMENT.DATE
            PERIOD.START.DATE = LAST.PAYMENT.DATE     ;* Last payment date is the start date
        CASE NOT(LAST.PAYMENT.DATE)         ;*No schedule has crossed yet - project from New arrangement date
            IF PAYMENT.PROPERTY.CLASS EQ "INTEREST" THEN     ;* Period start date is assigned with the interest accruals records value for interest properties
                AA.Interest.GetInterestLastDate(ARRANGEMENT.ID, PAYMENT.PROPERTY,"","", PERIOD.START.DATE)
            END
            IF NOT(PERIOD.START.DATE) THEN
                PERIOD.START.DATE = AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdValueDate>      ;*always consider the new arrangement date as the first Period Start Date
            END
            IF PAYMENT.MODE EQ 'ADVANCE' THEN
                NO.PREVIOUS.SCHEDULE = '1' ;* To set the flag if no schedules processed yet
            END
        CASE FIRST.INTEREST.PROJECTION AND PAYMENT.PROPERTY.CLASS EQ "INTEREST"      ;*Retrieve from Interest accruals as depending on LAST.PAYMENT.DATE may not be valid in case bills are already generated & settled in advance
            R.ACCRUAL.DETAILS = ""
            PMT.END.DATE = AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdPaymentEndDate>  ;*payment end date from the account details record
            COOLING.DATE = AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdCoolingDate> ;*cooling date from the account details record
            IF NOT(IS.PARTICIPANT) AND PROCESS.PARTICIPANTS THEN
                IF NON.CUSTOMER.PROPERTY THEN
                    ARRANGEMENT.ID<4> = 'BOOK'          ;* Non Customer interest processed only for own book in club loans
                END
                IF RISK.MARGIN.PROPERTY THEN
                    ARRANGEMENT.ID<4> = PART.ID<1,TOTAL.PARTICIPANTS>          ;* Risk Participant interest processed only for risk participants in club loans. Sending last risk participant id here while processing borrower, to cycle for next payment date by referring risk participant accruals record
                    IF LINKED.PORTFOLIO.LIST<1,1> THEN
                        ARRANGEMENT.ID<4> = RP.LIST<1,1>:'-':LINKED.PORTFOLIO.LIST<1,1>         ;* check interest accruals of 1st <RiskParticipant>-<Linked Portfolio> record to populate Period End Date when processing borrower accrual
                    END
                END
            END
            LOCATE PAYMENT.PROPERTY IN INTEREST.DATA<1,1> SETTING PropPos THEN
                R.ACCRUAL.DETAILS = RAISE(RAISE(INTEREST.DATA<3,PropPos>))
                INFO.ONLY.FLAG  =  INTEREST.DATA<4,PropPos>
            END ELSE
                INT.PAYMENT.PROPERTY = PAYMENT.PROPERTY
                GOSUB GET.ACCRUALS.RECORD
            END
 
            LOCATE LAST.PAYMENT.DATE IN R.ACCRUAL.DETAILS<AA.Interest.InterestAccruals.IntAccPeriodStart, 1> BY "AN" SETTING LAST.PAY.POS THEN     ;*Get the period where last payment date resides
                PERIOD.START.DATE = R.ACCRUAL.DETAILS<AA.Interest.InterestAccruals.IntAccPeriodStart,LAST.PAY.POS>
            END ELSE
**If not located, this is possible for fully settled Advance bills - get the previous position
** When the Adhoc start date defined in schedule and change schedule activity to be happen on next day to cycle the period then
** during projection on current date, here Period start date will be assign with previous period date since the period was stopped upto adhoc date.
** Due to this it will result rounding difference in schedule on/after change schedule date.
                LAST.PERIOD.END.POS = DCOUNT(R.ACCRUAL.DETAILS<AA.Interest.InterestAccruals.IntAccPeriodEnd>, @VM)
                BEGIN CASE
                    CASE AA.Interest.getRStoreProjection() AND LAST.PAYMENT.DATE EQ R.ACCRUAL.DETAILS<AA.Interest.InterestAccruals.IntAccPeriodEnd,LAST.PERIOD.END.POS>
                        PERIOD.START.DATE = R.ACCRUAL.DETAILS<AA.Interest.InterestAccruals.IntAccPeriodEnd,LAST.PERIOD.END.POS>
                    CASE COOLING.DATE AND LAST.PAYMENT.DATE EQ PMT.END.DATE AND LAST.PAYMENT.DATE LE COOLING.DATE
**for the contract which has the future dated cooling period date and which crosses one schedule and when the redemption is done before the second schedule then
**the period start date should be the last payment date, the last payment date will be the redemption date if so then the interest data in the projection will be zero
**if not then the accrual amount after the first schedule and then till the redemption date will be updated in the projection on maturity date, which is wrong.

                        PERIOD.START.DATE = LAST.PAYMENT.DATE
                    CASE 1
                        IF LAST.PAY.POS GT 1 THEN;*Ensure one valid period is got
                            LAST.PAY.POS -= 1
                        END
                        PERIOD.START.DATE = R.ACCRUAL.DETAILS<AA.Interest.InterestAccruals.IntAccPeriodStart,LAST.PAY.POS>
                END CASE
            END

** Last payment is set as period start date for subsequent cycle however, during respite last payment date should set to respite end date.
            RESPITE.END.DATE = R.ACCRUAL.DETAILS<AA.Interest.InterestAccruals.IntAccAdvPayPeriodEnd,LAST.PAY.POS>
            IF  RESPITE.END.DATE THEN
                PERIOD.START.DATE = R.ACCRUAL.DETAILS<AA.Interest.InterestAccruals.IntAccAdvPayPeriodEnd, LAST.PAY.POS,1>
            END
        
        CASE FIRST.INTEREST.PROJECTION AND PAYMENT.PROPERTY.CLASS EQ "CHARGE"
            PERIOD.START.DATE = LAST.PAYMENT.DATE
        CASE 1          ;*No scenario can exist - because there can be no instance where LAST.PAYMENT.DATE is NULL & FIRST.INTEREST.PROJECTION is NULL as well other than first period
    END CASE
    PERIOD.END.DATE = PAYMENT.DATE      ;* End period of interest
    
    IF PERIOD.START.DATE LT AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdValueDate> THEN  ;* When last payment date is assigned to period start date and is less than arrangement value date, change period start date to base date. Since Value date is changed after restore arrangement activity.
        
        PERIOD.START.DATE = AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdValueDate>
        
    END
    IF SCHEDULE.INFO<51> AND  PERIOD.START.DATE GE PERIOD.END.DATE THEN
        LOCATE PERIOD.END.DATE IN PAYMENT.DATES<2> SETTING DATE.POS THEN
            PERIOD.START.DATE = PAYMENT.DATES<DATE.POS-1>           ;* Lets take the previous position
        END
    END
    
    IF PERIOD.START.DATE AND PERIOD.START.DATE LT AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdStartDate> THEN ;* When last payment date is lesser than the start date and the base date type is set as "START" then period start date should be arrangement start date
        AA.Framework.GetBaseDateType(ARRANGEMENT.ID, "", BASE.TYPE, "")
        IF BASE.TYPE EQ "START" THEN
            PERIOD.START.DATE = AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdStartDate>
            LOCATE PERIOD.START.DATE IN R.ACCRUAL.DETAILS<AA.Interest.InterestAccruals.IntAccPeriodStart, 1> BY "AR"  SETTING POS1 ELSE
                IF POS1 GT 1 THEN
                    POS1 -= 1
                END
                PERIOD.START.DATE = R.ACCRUAL.DETAILS<AA.Interest.InterestAccruals.IntAccPeriodStart,POS1>
            END
        END
    END
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name=GET.LAST.PAYMENT.DATE>
*** <desc>Get last payment date for the current interest property</desc>
GET.LAST.PAYMENT.DATE:

    LAST.PAYMENT.DATE = ""
    LAST.PAYMENT.DETAILS = ""
    FIRST.INTEREST.PROJECTION = ""      ;*Flag to indicate first interest calculation for this pro
    IF IS.PARTICIPANT THEN          ;* For Participant, rely on borrower last payment date from same PAYMENT.DATE processing
        GOSUB GET.PARTICIPANT.LAST.PAYMENT.DATE         ;* populate last payment date for participants
    END ELSE
        LOCATE PAYMENT.PROPERTY IN AA.Framework.getContractDetails()<AA.Framework.CdProperty,1> SETTING PR.POS THEN
            PROPERTY.DATE.COUNT = DCOUNT(AA.Framework.getContractDetails()<AA.Framework.CdPropertyDate,PR.POS>, @SM)
            LAST.PAYMENT.DATE = AA.Framework.getContractDetails()<AA.Framework.CdPropertyDate,PR.POS,PROPERTY.DATE.COUNT>
            LAST.ACCRUAL.DATE = PROPERTY.ACCRUAL.DATA<PR.POS, PROPERTY.DATE.COUNT>  ;* Get the last accrual date
        END

        IF LAST.PAYMENT.DATE = "" THEN      ;*We are retrieving for the first time
            FIRST.INTEREST.PROJECTION = 1   ;*To flag that last payment date is obtained from AA.GET.LAST.PAYMENT.DATE
            PROCESS.MODE<1> = "CURRENT"
            IF SCHEDULE.INFO<51> AND SCHEDULE.INFO<33> THEN
                PROCESS.MODE<1> = "PREVIOUS" ;* When schedules is called from MAKE.DUE routines(INTEREST & ACCOUNT) it should get previous last date as current date is updated in account details during ps.make.due.
            END
            PROCESS.MODE<2> = "INTERIM.DATE"          ;* If interim capitalisation date is found, return the greatest of interim date and payment date.
            PROCESS.MODE<3> = SCHEDULE.INFO<22>  ;*This schedule flag will be set to ADJUST.CAP/ADJUST.DUE activity to get last payment date by locating current activity date.
            AA.PaymentSchedule.GetLastPaymentDate(ARRANGEMENT.ID, "", PAYMENT.PROPERTY, PROCESS.MODE, LAST.PAYMENT.DATE, "", "", "") ;* Payment type should not be passed, since last payment date of the payment type is returned which is wrong, it should return the last payment date of the interest property when the same property is part of multiple payment types
            IF LAST.PAYMENT.DATE THEN ;* Include the last payment date and its corresponding property in order to get the Adjustment amount only for current interest period
                LOCATE PAYMENT.PROPERTY IN LAST.PAYMENT.DETAILS<1,1> SETTING LAST.PAYMENT.DETAILS.POS ELSE
                    LAST.PAYMENT.DETAILS<1,-1> = PAYMENT.PROPERTY
                    LAST.PAYMENT.DETAILS<2,-1> = LAST.PAYMENT.DATE
                END
            END
        END
    END

RETURN
*** </region>
*-----------------------------------------------------------------------------
    
*** <region name= GET.PRESENT.INTEREST.ACCRUALS>
*** <desc>Get present interest accrual amount</desc>
GET.PRESENT.INTEREST.ACCRUALS:
** here we are getting the interest accrual which are carried over from previous period to the current period
** these can happen when there are some adjustments made as part of payment recalculation
** or when interest amount is calculated as a %, in which case, the balance of the original amount will be carried over
** to the next interest period and added to the current interest amount

    BALANCE.UTILISED = ""
    SAVE.ARR = ''
    BEGIN CASE
        CASE IS.PARTICIPANT                 ;* For Participant, rely on borrower interest properties list and balance.utilised from same PAYMENT.DATE processing
            LOCATE PAYMENT.PROPERTY IN BORROWER.INTEREST.PROPERTIES<1,1> SETTING PART.PAY.POS THEN
                BALANCE.UTILISED = BORROWER.INTEREST.PROPERTIES<2,PART.PAY.POS>
            END
            SAVE.ARR = ARRANGEMENT.ID       ;*store arrangement id
        
        CASE 1
            LOCATE PAYMENT.PROPERTY IN INTEREST.PROPERTIES<1,1> SETTING PAY.POS THEN
                IF INTEREST.PROPERTIES<2,PAY.POS> = "Y" THEN        ;*For Residual projection, take from accruals only for the first time irrespective of Period End Date
                    BALANCE.UTILISED = 1
                END
* when calculating interest accurals for Participant, utilisation status for Borrower should be reused.
* So,save both the property list and balance utilisation info of borrower
                IF SCHEDULE.INFO<28> THEN
                    BORROWER.INTEREST.PROPERTIES<1,PAY.POS> = PAYMENT.PROPERTY          ;* save interest properties updation status for borrower
                    BORROWER.INTEREST.PROPERTIES<2,PAY.POS> = BALANCE.UTILISED          ;* save balance utilisation status
                END
            END
    END CASE
 
    RES.INT.AMOUNT = 0

    BEGIN CASE
        CASE NOT(BALANCE.UTILISED)       ;* For the first time get the interest accrual carry over
            IF IS.PARTICIPANT THEN          ;* need to send participant id along with skim if it is defined in <4> of arrangement.id to fetch interest accruals record of participant
                ARRANGEMENT.ID<4> = STORE.PART.ID
                IF LINKED.PF AND RISK.MARGIN.PROPERTY THEN
                    ARRANGEMENT.ID<4>  = STORE.PART.ID:'-':LINKED.PF
                END
            END
            IF RESIDUAL.PROCESS.REQD THEN   ;*Do Residual Processing
                REQUEST.TYPE = 'RESIDUAL'   ;*Get the Residual amount alone
                AA.Interest.GetAdjustedInterestAmount(ARRANGEMENT.ID, PAYMENT.PROPERTY, EXTENSION.NAME, REQUEST.TYPE, PERIOD.START.DATE, PERIOD.END.DATE, ADJUSTMENT.AMOUNT, "")
                RES.INT.AMOUNT = ADJUSTMENT.AMOUNT    ;*This should be passed to the local routine
                REQUEST.TYPE = 'CURRENT.ONLY'
                AA.Interest.GetAdjustedInterestAmount(ARRANGEMENT.ID, PAYMENT.PROPERTY, EXTENSION.NAME, REQUEST.TYPE, PERIOD.START.DATE, PERIOD.END.DATE, ADJUSTMENT.AMOUNT, "")
                ADJUSTMENT.AMOUNT += RES.INT.AMOUNT   ;*Make Sure that the adjustment contains Residual + Current period's accrued amount if any
            END ELSE
                GOSUB CHECK.ADJUSTMENT.REQUIRED       ;* By pass the adjustment check during Holiday period for deferred holiday payments
            END
            DEF.INT.DETAIL = RES.INT.AMOUNT
            IF IGNORE.INT.PROP.UPDATE ELSE          ;* Update only for borrower
                IF NOT(IS.PARTICIPANT) THEN            ;* Utilisation info need to be updated only for borrower, the same info will be used for Particiapnts also
                    INTEREST.PROPERTIES<2,PAY.POS> = "Y"  ;* Balance utilised
                END
            END
   
        CASE SCHEDULE.INFO<51> AND PERIOD.END.DATE LE CURRENT.SYS.DATE
            AA.Interest.GetAdjustedInterestAmount(ARRANGEMENT.ID, PAYMENT.PROPERTY, EXTENSION.NAME, "CURRENT.ACCRUE", PERIOD.START.DATE, PERIOD.END.DATE, ADJUSTMENT.AMOUNT, "")
**We avoid to adding the ADJUSTMENT.AMOUNT into the INTEREST.AMOUNT when PAYMENT.DATE EQ PAYMENT.END.DATE and it have fixed interest.
        CASE PAYMENT.DATE EQ PAYMENT.END.DATE AND (PAYMENT.PROPERTY MATCHES AA.Framework.getFixedInterest()<1>) AND NOT(ADV.CALC.TYPE) AND BALANCE.UTILISED
        CASE 1
            ADJUSTMENT.AMOUNT = INTEREST.PROPERTIES.RESIDUAL.AMOUNT<1,PAY.POS>      ;* See if residual amounts are to be added as part of projection
            DEF.INT.DETAIL = ADJUSTMENT.AMOUNT
    END CASE
    

** Last payment is set as period start date for subsequent cycle however, during respite last payment date should set to respite end date.
** Donot add previous period adjustment amounts to current period if within respite period.
    IF RESPITE.END.DATE THEN
        ADV.PAY.END = R.ACCRUAL.DETAILS<AA.Interest.InterestAccruals.IntAccAdvPayPeriodEnd>
        CHANGE @SM TO @VM IN ADV.PAY.END
        LOCATE PERIOD.START.DATE IN ADV.PAY.END<1,1> SETTING POS THEN
            ADJUSTMENT.AMOUNT = 0
        END
    END
    
    IF IS.PARTICIPANT THEN
        ARRANGEMENT.ID = SAVE.ARR       ;*restore arrangement id if modified for processing participant interest accruals
    END
    
RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name=PROCESS.OTHER.PAY.TYPES>
*** <desc>Process other payment type to get the PRESENT.INT.ACCRUAL amount</desc>
PROCESS.OTHER.PAY.TYPES:

    IF PAYMENT.PERCENT THEN   ;* find percentage of the interest amount calculated
        INT.PERCENT.AMOUNT = INT.AMOUNT * PAYMENT.PERCENT / 100
        ROUND.AMT = INT.PERCENT.AMOUNT
        GOSUB GET.ROUND.AMT
        INT.PERCENT.AMOUNT = ROUND.AMT
        ADJUSTMENT.AMOUNT = INT.AMOUNT - INT.PERCENT.AMOUNT ;* now the balance of the interest amount has to be carried over to the next interest period
        INT.AMOUNT = INT.PERCENT.AMOUNT
    END ELSE
        IF ((HOLIDAY.AMOUNT AND INT.AMOUNT GT HOLIDAY.AMOUNT) OR (NOT(HOLIDAY.AMOUNT) AND HOLIDAY.DATE)) AND NOT(RESTRICTED.PROPERTY) THEN  ;* Only consider the non-restriction type only.Carry forward the interest amount to subsequent due when the schedule is declared as holiday.
            IF NOT(DEFER.HOLIDAY.INTEREST) THEN    ;* if the current Holiday payment date doesn't deferred then get the adjustment.amount.
            
                ADJUSTMENT.AMOUNT = (DIFF.INT.AMT + INT.AMOUNT - HOLIDAY.AMOUNT) ;* When holiday amount defined,carry forwarding the interest amount
            END ELSE
                IF SCHEDULE.INFO<51> THEN
                    ADJUSTMENT.AMOUNT = 0 ;* Fully utilised
                END
            END
        END ELSE
            ADJUSTMENT.AMOUNT = 0 ;* Fully utilised
        END
        
    END

    IF FIX.INT.AMOUNT THEN    ;*Store the difference in amount to carry forward
        ADJUSTMENT.AMOUNT = INT.AMOUNT - FIX.INT.AMOUNT
    END

*Interest amt should be reduced only while doing advance payment.
    IF SPECIAL.PROCESSING AND CALC.AMOUNT AND NOT(BILL.PR.AMT) THEN        ;*Advanced payment for Linear + Interest only
        CALC.AMOUNT -= INT.AMOUNT       ;*Reduce from the available amount
    END

RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Update Residual interest amounts>
*** <desc>Update residual interest amounts to be carried forward</desc>
UPDATE.PRESENT.INTEREST.ACCRUALS:

** Update the residual interest amount to be carried forward for the next period

    LOCATE PAYMENT.PROPERTY IN INTEREST.PROPERTIES<1,1> SETTING PAY.POS THEN
        INTEREST.PROPERTIES.RESIDUAL.AMOUNT<1,PAY.POS> = ADJUSTMENT.AMOUNT
    END

    IF RESIDUAL.PROCESS.REQD THEN       ;* AA.CONTRACT.DETAILS updated for RES balance type / Used to get a adjustment amount
        LIFECYCLE.STATUS = "RES"
        BALANCE.PROPERTY = PAYMENT.PROPERTY
        CUR.PROPERTY = BALANCE.PROPERTY
        PARTICIPANT = PART.ID<1,PART.POS>
        GOSUB GET.PARTICIPANT.ACCT.MODE     ;* Send Participant AcctMode to get Balance Name
        AA.ProductFramework.PropertyGetBalanceName(ARRANGEMENT.ID, CUR.PROPERTY, LIFECYCLE.STATUS, "", "BANK", BALANCE.TO.CHECK)
        LOCATE BALANCE.TO.CHECK IN AA.Framework.getContractDetails()<BASE.BALANCE.POS,1> SETTING RES.POS THEN
            tmp=AA.Framework.getContractDetails(); tmp<BASE.BALANCE.POS,RES.POS>=BALANCE.TO.CHECK; tmp<BAL.EFF.DATE.POS,RES.POS>=PAYMENT.DATE; tmp<BAL.AMT.POS,RES.POS>=ADJUSTMENT.AMOUNT * SIGN; AA.Framework.setContractDetails(tmp)
        END ELSE
            tmp=AA.Framework.getContractDetails(); tmp<BASE.BALANCE.POS,RES.POS>=BALANCE.TO.CHECK; tmp<BAL.EFF.DATE.POS,RES.POS>=PAYMENT.DATE; tmp<BAL.AMT.POS,RES.POS>=ADJUSTMENT.AMOUNT * SIGN; AA.Framework.setContractDetails(tmp);* Store balance in common to be used
        END
        ACCOUNT.ID = SAVE.ACCOUNT.ID
    END

RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Calculate Tax>
*** <desc>Calculate Tax</desc>
CALCULATE.TAX.AMOUNT:

* Get the Tax Amount for Interest/ Charge Property & return the Tax Details array with
* Base property (Interest/ Charge Property) , Tax Properties , Tax Amounts.
*
* Get the Tax amount by calling the Tax calculation routine.
    IF SCHEDULE.INFO<55> THEN ;* No need to check tax if the flag is set
        RETURN
    END

    TAX.LIST = ""
    EFFECTIVE.DATE =  PAYMENT.DATE
    TAX.AMOUNTS = ""
    TAX.AMOUNT.LCY = ""
    TAX.PROPERTY = TAX.PROPERTIES

    UPFRONT.TAX.RATE = "" ;* Upfront Tax Rate
*** When we have the property defined in the tax condition, check if we have upfront tax rate in the interest accruals and take the latest tax rate.
    LOCATE BASE.PROPERTY IN INTEREST.DATA<1,1> SETTING INT.POS THEN
        R.INTEREST.ACCRUALS = RAISE(RAISE(INTEREST.DATA<3,INT.POS>))
        BASE.PROPERTY<2> = LOWER(R.INTEREST.ACCRUALS)
        AA.Tax.DetermineUpfrontTaxAmount(ARRANGEMENT.ID , EFFECTIVE.DATE, BASE.PROPERTY, "", BASE.AMOUNT, UPFRONT.TAX.RATE, "", "GET", TAX.AMOUNTS, "", "", "")
    END
*** If Upfront tax rate is there, calculate the tax for upfront tax on the base property instead of calling CalculateTax.
*** If tax rate is present but it is 0%, we would have updated as 0.00. During this case also, we need to call DetermineUpfrontTaxAmount routine. In this routine,
*** currently TAX.AMOUNTS.LCY is not handled.

    IF UPFRONT.TAX.RATE NE "" THEN
        AA.Tax.DetermineUpfrontTaxAmount(ARRANGEMENT.ID , EFFECTIVE.DATE, BASE.PROPERTY, "", BASE.AMOUNT, UPFRONT.TAX.RATE, "", "", TAX.AMOUNTS, "", "", "")
    END ELSE
        IF TAX.PROPERTIES THEN    ;*Process only if Tax properties are present for the arrangement
*** Check whether Tax is defined for the processing Property at one time alone, if so then invoke CalculateTax for each Payment date
*** Else no need to invoke Calculate Tax for each payment date. As the Tax amount would be NULL
*** IN below logic, Property that have Tax are updated in 1st position of PROPERTY.TAX.DETAILS
*** Property that don't have Tax are updated in 2nd position of PROPERTY.TAX.DETAILS
            LOCATE BASE.PROPERTY IN PROPERTY.TAX.DETAILS<1,1> SETTING PROPERTY.TAX.POS THEN ;* Check whether the processing property have Tax defined and invoke Calculate Tax
                LOCATE BASE.PROPERTY IN LAST.PAYMENT.DETAILS<1,1> SETTING LAST.PAYMENT.DETAILS.POS THEN
                    CURRENT.PERIOD.DATE = LAST.PAYMENT.DETAILS<2,LAST.PAYMENT.DETAILS.POS>
                    IF CURRENT.PERIOD.DATE THEN
                        EFFECTIVE.DATE<2> = CURRENT.PERIOD.DATE ;* Pass the last payment date to determine if we are in first interest period for fetching activity balance
                    END
                END
                TEMP.BASE.AMOUNT = BASE.AMOUNT ; TEMP.BASE.AMOUNT<2> = PRINCIPAL.INFLOW
                AA.Tax.CalculateTax(ARRANGEMENT.ID , EFFECTIVE.DATE , BASE.PROPERTY , TEMP.BASE.AMOUNT , TAX.PROPERTY , ARRANGEMENT.INFO, TAX.AMOUNTS , TAX.AMOUNT.LCY , PROCESSTYPE, RET.ERROR)
            END ELSE
                LOCATE BASE.PROPERTY IN PROPERTY.TAX.DETAILS<2,1> SETTING PROPERTY.TAX.POS THEN ;* If the processing property doesn't have Tax then no need to invoke Calculate Tax
                    TAX.PROPERTY = ""
                END ELSE
                    AA.Tax.GetTaxCode(ARRANGEMENT.ID, BASE.PROPERTY, EFFECTIVE.DATE, TAX.PROPERTY, ACTUAL.TAX.PROPERTIES, TAX.CODES, TAX.CONDITIONS, TAX.CONTEXTS, "", "")
                    IF TAX.CODES OR TAX.CONDITIONS OR TAX.CONTEXTS THEN
                        PROPERTY.TAX.DETAILS<1,-1> = BASE.PROPERTY ;* Update the property that have Tax in 1st position
                        LOCATE BASE.PROPERTY IN LAST.PAYMENT.DETAILS<1,1> SETTING LAST.PAYMENT.DETAILS.POS THEN
                            CURRENT.PERIOD.DATE = LAST.PAYMENT.DETAILS<2,LAST.PAYMENT.DETAILS.POS>
                            IF CURRENT.PERIOD.DATE THEN
                                EFFECTIVE.DATE<2> = CURRENT.PERIOD.DATE ;* Pass the last payment date to determine if we are in first interest period for fetching activity balance
                            END
                        END
                        TEMP.BASE.AMOUNT = BASE.AMOUNT ; TEMP.BASE.AMOUNT<2> = PRINCIPAL.INFLOW ; TAX.PROPERTY = ACTUAL.TAX.PROPERTIES
                        AA.Tax.CalculateTax(ARRANGEMENT.ID , EFFECTIVE.DATE , BASE.PROPERTY , TEMP.BASE.AMOUNT , TAX.PROPERTY, ARRANGEMENT.INFO, TAX.AMOUNTS , TAX.AMOUNT.LCY , PROCESSTYPE, RET.ERROR)
                    END ELSE
                        PROPERTY.TAX.DETAILS<2,-1> = BASE.PROPERTY ;* Update the property that doesn't Tax in 2nd position
                        TAX.PROPERTY = ""
                    END
                END
            END
        END
        IF PROCESSTYPE EQ "GROSS" THEN
            GROSS.ACCOUNT.PAY<1,PAY.TYPE.I> = 1
        END
        IF BANK.TAX.AMOUNT EQ "1" THEN
            TAX.AMOUNTS = 0
        END
    END

    ARRANGEMENT.INFO<9> = '' ;* Reset skip gross tax flag each time.

*** Constant amount should be calculated properly when we set Tax inclusive to Yes. When Tax inclusive is set to Yes
*** And when sum of (Tax amount and interest amount) is GT original calc amount, then we should derive the interest amount and tax amount based on the original calc amount.
    TOTAL.AMOUNT = TAX.AMOUNTS + INT.AMOUNT
    BEGIN CASE
        CASE TAX.INCLUSIVE AND SCHEDULE.INFO<51> AND SAVE.HOLIDAY.AMOUNT AND NOT(REDUCE.CALC.AMT.TAX) ;* for holiday date calculate tax inclusive amounts based on holiday amount
            TOTAL.AMOUNT = TAX.AMOUNTS + PAYMENT.PROPERTY.AMOUNT
            IF TOTAL.AMOUNT GT SAVE.HOLIDAY.AMOUNT THEN
                PAYMENT.PROPERTY.AMOUNT = (PAYMENT.PROPERTY.AMOUNT/TOTAL.AMOUNT)*SAVE.HOLIDAY.AMOUNT
                TAX.AMOUNTS = SAVE.HOLIDAY.AMOUNT - PAYMENT.PROPERTY.AMOUNT
            END
        
        CASE TAX.INCLUSIVE AND SCHEDULE.INFO<51> AND SAVE.HOLIDAY.PROPERTY.AMOUNT AND NOT(REDUCE.CALC.AMT.TAX) ;* for holiday date calculate tax inclusive amounts based on holiday property amount
            TOTAL.AMOUNT = TAX.AMOUNTS + PAYMENT.PROPERTY.AMOUNT
            IF TOTAL.AMOUNT GT SAVE.HOLIDAY.PROPERTY.AMOUNT THEN
                PAYMENT.PROPERTY.AMOUNT = (PAYMENT.PROPERTY.AMOUNT/TOTAL.AMOUNT)*SAVE.HOLIDAY.PROPERTY.AMOUNT
                TAX.AMOUNTS = SAVE.HOLIDAY.PROPERTY.AMOUNT - PAYMENT.PROPERTY.AMOUNT
            END
        
        CASE TAX.INCLUSIVE AND ACTUAL.CALC.AMOUNT NE "" AND TOTAL.AMOUNT GT ACTUAL.CALC.AMOUNT AND HOLIDAY.AMOUNT EQ ''
            INT.AMOUNT = (INT.AMOUNT/TOTAL.AMOUNT)*ACTUAL.CALC.AMOUNT
            TAX.AMOUNTS = ACTUAL.CALC.AMOUNT - INT.AMOUNT
            PAYMENT.PROPERTY.AMOUNT = INT.AMOUNT
*** We might have updated the int amount for the current processing schedule date. But, when we have a fixed interest / upfront profit with tax inclusive set and if the total interest amount exceeds the actual calc amount,
*** We might have calculated a new int amount and tax amount which is less than the actual calc amount. In this case, subtract the previously updated int amount which is capped with the actual calc amount as it exceeds and add the newly calculated int amount which is less than the actual calc amount.
* Within the schedules, at the final accrual period this has to be used to calculate the total past profit amounts.;*for DUE.AND.CAP payment type we have to also update the capitalized portion of interest in the common
            IF AA.Framework.getFixedInterest() AND NOT(IS.PARTICIPANT) THEN ;* We can have multiple fixed interest properties, so locate and update on the respective interest
                LOCATE PAYMENT.PROPERTY IN AA.Framework.getFixedInterest()<1,1> SETTING FixPropPos THEN
*For restructured contracts, the past accrued amounts prior to the restructure date should not be included in the FixedInterest common.
                    RESTRUCTURE.DATE = AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdRestructureDate,1> ; *Get the Restructure date
                    IF (PERIOD.START.DATE GE RESTRUCTURE.DATE AND RESTRUCTURE.DATE) OR NOT(RESTRUCTURE.DATE) THEN
                        tmp=AA.Framework.getFixedInterest(); tmp<4,FixPropPos>=AA.Framework.getFixedInterest()<4,FixPropPos> - ACTUAL.CALC.AMOUNT + INT.AMOUNT; AA.Framework.setFixedInterest(tmp)    ;*This will be used later to calculate the final schedule interest amount
                    END
                END
            END
                        
    END CASE
    
    ACTUAL.CALC.AMOUNT = ""

    TAX.LIST<1,AA.Tax.TxBaseProp> = BASE.PROPERTY
    TAX.LIST<1,AA.Tax.TxTaxProp> = TAX.PROPERTY     ;* Will be seperated by "SM".
    TAX.LIST<1,AA.Tax.TxTaxAmt> =  TAX.AMOUNTS      ;* Corresponding tax amounts for the tax Properties.

    IF TAX.AMOUNT.LCY THEN

        TAX.LIST<1,AA.Tax.TxTaxAmtLcy> = TAX.AMOUNT.LCY      ;*Tax amount in local currency
    END

    TAX.LIST = LOWER(LOWER(TAX.LIST))   ;* Will be Sepreated by "VM" , needs to be at Lower Level than "SM"  to insert at Property Position.

    IF IS.PARTICIPANT THEN
        GOSUB UPDATE.PARTICIPANT.TAX.DETAILS        ;* Update Tax details for Participant
    END ELSE
        TAX.DETAILS.LIST<1, PAY.TYPE.I, PROPERTY.I>  =  TAX.LIST
    END

* During Capitalise Tax Amount should be add with Base Amount for Loans & reduced with Base Amount for Deposits.
    TAX.AMOUNT = SUM(TAX.AMOUNTS) * SIGN     ;* Will be Sum of  Taxes for each Property.

;* check the holiday related flag before reducing the calc amt as its to be done only when tax is calculated for original amount
    IF TAX.INCLUSIVE AND REDUCE.CALC.AMT.TAX THEN
        CALC.AMOUNT -= ABS(TAX.AMOUNT)  ;* Reduce the annuity amount for the calculated tax amount
    END

RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= Calculate Tax>            ;* para to calculate tax for cap amounts
*** <desc>For DUE.AND.CAP payment type the tac for capitalised portion of Interest/Charge will be Calculated </desc>
CALCULATE.CAP.TAX.AMOUNT:

* Get the Tax Amount for Interest/ Charge Property & return the Tax Details array with
* Base property (Interest/ Charge Property) , Tax Properties , Tax Amounts.
*
* Get the Tax amount by calling the Tax calculation routine.

    IF SCHEDULE.INFO<55> THEN ;* No need to check tax if the flag is set
        RETURN
    END

    CAP.TAX.LIST = ""
    EFFECTIVE.DATE =  PAYMENT.DATE
    CAP.TAX.AMTS = 0
    CAP.TAX.AMOUNT.LCY = 0
    TAX.PROPERTY = TAX.PROPERTIES
    IF TAX.PROPERTIES THEN    ;*Process only if Tax properties are present for the arrangement
        LOCATE CAP.PROPERTY IN LAST.PAYMENT.DETAILS<1,1> SETTING LAST.PAYMENT.DETAILS.POS THEN
            CURRENT.PERIOD.DATE = LAST.PAYMENT.DETAILS<2,LAST.PAYMENT.DETAILS.POS>
            IF CURRENT.PERIOD.DATE THEN
                EFFECTIVE.DATE<2> = CURRENT.PERIOD.DATE ;* Pass the last payment date to determine if we are in first interest period for fetching activity balances
            END
        END
        AA.Tax.CalculateTax(ARRANGEMENT.ID , EFFECTIVE.DATE , CAP.PROPERTY , CAP.AMOUNT , TAX.PROPERTY , ARRANGEMENT.INFO, CAP.TAX.AMOUNTS , CAP.TAX.AMOUNT.LCY , PROCESSTYPE, RET.ERROR)        ;*New argument added
    END
    IF BANK.TAX.AMOUNT EQ "1" THEN
        CAP.TAX.AMOUNTS = 0
    END
    
*** Constant amount should be calculated properly when we set Tax inclusive to Yes. When Tax inclusive is set to Yes
*** And when sum of (Tax amount and interest amount) is GT original calc amount, then we should derive the interest amount and tax amount based on the original calc amount.
    TOTAL.AMOUNT = CAP.TAX.AMOUNTS + INT.AMOUNT
    
    CAP.TAX.LIST<1,AA.Tax.TxBaseProp> = CAP.PROPERTY
    CAP.TAX.LIST<1,AA.Tax.TxTaxProp> = TAX.PROPERTY     ;* Will be seperated by "SM".
    CAP.TAX.LIST<1,AA.Tax.TxTaxAmt> =  CAP.TAX.AMOUNTS      ;* Corresponding tax amounts for the tax Properties.

    IF CAP.TAX.AMOUNT.LCY THEN

        CAP.TAX.LIST<1,AA.Tax.TxTaxAmtLcy> = TAX.AMOUNT.LCY      ;*Tax amount in local currency
    END

    CAP.TAX.LIST = LOWER(LOWER(CAP.TAX.LIST))   ;* Will be Sepreated by "VM" , needs to be at Lower Level than "SM"  to insert at Property Position.

    IF IS.PARTICIPANT THEN
        GOSUB UPDATE.PARTICIPANT.TAX.DETAILS        ;* Update Tax details for Participant
    END ELSE
        LOCATE PAYMENT.DATE IN CAP.PAYMENT.DATES BY 'AN' SETTING CAP.DATE.POS THEN
        END
        CAP.TAX.DETAILS.LIST<CAP.DATE.POS, PAY.TYPE.I, PROPERTY.I>  =  CAP.TAX.LIST
    END

* During Capitalise Tax Amount should be add with Base Amount for Loans & reduced with Base Amount for Deposits.
    CAP.TAX.AMOUNT = SUM(CAP.TAX.AMOUNTS) * SIGN     ;* Will be Sum of  Taxes for each Property.
   
*Tax inclusive code has been removed because for partial capitalisation, entier excess amount will be capitalised to principal. If required this can be added in future

RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Calculate amount>
*** <desc>Calculate amount</desc>
CALCULATE.AMOUNT:

** Based on calculate type, calculate amount (principal or Account)
** For "Constant" it is the difference between the total amount and the sum of
** other properties associated with the payment type
** For "Linear" it is the payment amount itself so is for
** "Other" and "Actual" calculation type

    TEMP.VALUE = PRESENT.VALUE
    IF IS.PARTICIPANT THEN
        TEMP.VALUE = PARTICIPANT.PRESENT.VALUE<1,PART.POS>

    END
    
    AMOUNT = 0
    IF RESIDUAL.AMOUNT GT TEMP.VALUE THEN      ;*Limit Residual amount not to exceed Outstanding principal
        RESIDUAL.AMOUNT = TEMP.VALUE
    END

    BEGIN CASE

        CASE PAY.BILL.TYPE EQ 'DISBURSEMENT'          ;*For Disbursement, ensure we don't exceed available commitment amount
            REMAIN.AMOUNT = CUR.TERM.AMT

        CASE PAY.BILL.TYPE MATCHES 'EXPECTED':@VM:'ADVANCE'    ;*For Deposits expected type, no need to restrict the scheduled amount to be deposited.For the system bill type as Advance we need to update the remaining amount in order to get the Account property amount
            REMAIN.AMOUNT = PAYMENT.AMOUNT.LIST<1,PAY.TYPE.I>

        CASE CALC.TYPE = 'TRANSACTION' AND PAYMENT.PERCENT NE "" ;* When payment percentage defined in Downpayment payment type we need to get the Disbursement amount plus its activity charges amount otherwise Actual amount defined will be final downpayment amount.
            TransactionAmount = ""
            AA.PaymentSchedule.GetTransactionAmount(ARRANGEMENT.ID, TransactionAmount, Reserved)
            REMAIN.AMOUNT = TransactionAmount

        CASE NOT(R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsPaymentType> OR PAY.BILL.TYPE)
            REMAIN.AMOUNT = TEMP.VALUE - RESIDUAL.AMOUNT
          
        CASE PAY.BILL.TYPE        ;*For all accounts schedule, ensure we do not exceed the outstanding principal amount
            REMAIN.AMOUNT = TEMP.VALUE - RESIDUAL.AMOUNT   ;* any bill types other than above three should not be taken to update the amount
    
        CASE BILL.PAYMENT.TYPE
            LOCATE BILL.PAYMENT.TYPE IN BILL.TYPE.ARRAY<1,1> SETTING BILL.TYPE.POS THEN
                BILL.PAY.TYPE = BILL.TYPE.ARRAY<2, BILL.TYPE.POS>
            END ELSE
                AA.PaymentSchedule.GetSysBillType(BILL.PAYMENT.TYPE, BILL.PAY.TYPE, '')
                BILL.TYPE.ARRAY<1,-1> = BILL.PAYMENT.TYPE
                BILL.TYPE.ARRAY<2,-1> = BILL.PAY.TYPE
            END
            IF NOT(BILL.PAY.TYPE MATCHES 'DISBURSEMENT':@VM:'EXPECTED') THEN
                REMAIN.AMOUNT = PRESENT.VALUE - RESIDUAL.AMOUNT ;* any bill types other than above three should not be taken to update the amount
            END
        
    END CASE

    BEGIN CASE
        CASE PAYMENT.METHOD EQ "MAINTAIN"
            AMOUNT = TEMP.VALUE - PAYMENT.AMOUNT.LIST<1,PAY.TYPE.I>
            IF AMOUNT > 0 THEN
                PAYMENT.METHOD.NEW = "PAY"
            END ELSE
                PAYMENT.METHOD.NEW = "DUE"
            END
            AMOUNT = ABS(AMOUNT)
            GOSUB UPDATE.PRESENT.VALUE
            GOSUB UPDATE.CONTRACT.DETAILS  ;*To update the current outstanding balance in the case of "MAINTAIN" method, contract details must be updated.

        CASE CALC.TYPE MATCHES "CONSTANT":@VM:"PROGRESSIVE":@VM:"ACCELERATED":@VM:"PERCENTAGE":@VM:"FIXED EQUAL":@VM:"ADVANCE" ; * For the Calc type as Advance
            IF CALC.AMOUNT = "" THEN        ;* If annuity not defined, unlikely
                CALC.AMOUNT = SUM(PAYMENT.PROPERTIES.AMT<PAY.DATE.I,PAY.TYPE.I>)
            END ELSE
                GOSUB CALCULATE.ACCOUNT.AMOUNT
            END
            GOSUB UPDATE.CONTRACT.DETAILS

        CASE CALC.TYPE MATCHES "LINEAR":@VM:"ACTUAL":@VM:"OTHER":@VM:"TRANSACTION":@VM:"ADVANCE"
            GOSUB CALCULATE.ACCOUNT.AMOUNT
            IF PAY.BILL.TYPE EQ 'DISBURSEMENT' THEN
                IF NOT(PAYMENT.PERCENT) THEN ;* If Disbursement Schedule defined in Percentage Don't compare Disbursement amount with commitment amount
                    GOSUB CALCULATE.DISBURSE.AMT          ;* Validate disbursement amount if it is greater than commitment amount
** Do not include disbursement schedule amount during the projection when the start date not present in account details. Otherwise system print the deliver message payment schedule details based on double the commitment.
                END
                UPD.CONTRACT.DETAILS = "" ;* Flag to update the contract details common.
                INCLUDE.PRINCIPAL.PAYMENTS = ""
                INCLUDE.PRIN.PAYMENT = R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsIncludePrinPayments>
                
                IF SCHEDULE.INFO<42> AND INCLUDE.PRIN.PAYMENT THEN
                    INCLUDE.PRINCIPAL.PAYMENTS = 1    ;* Flag to indicate the call is to update the EB.CASHFLOW record
                END
                
                BEGIN CASE
                    CASE AA.Framework.getContractDetails()<AA.Framework.CdIncludePrinAmounts> EQ "YES" OR INCLUDE.DISBURSE.SCHEDULE OR INCLUDE.PRINCIPAL.PAYMENTS;* Update Contract details with Disbursement Sch. Amount to calculate the Interest when Include Prin Amounts set as Yes.
                        UPD.CONTRACT.DETAILS = 1
                    CASE AA.Interest.getRStoreProjection() AND AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdStartDate>
                        UPD.CONTRACT.DETAILS = 1
                END CASE
        
                IF UPD.CONTRACT.DETAILS THEN
                    GOSUB UPDATE.CONTRACT.DETAILS
                END
            END ELSE
                GOSUB UPDATE.CONTRACT.DETAILS
            END
    END CASE

    IF EXTEND.CYCLE EQ 'INTEREST' OR MASTER.ACT.CLASS EQ "UPDATE-PAYMENT.HOLIDAY" AND NOT(CALC.TYPE MATCHES 'CONSTANT':@VM:'PROGRESSIVE':@VM:'ACCELERATED':@VM:"PERCENTAGE") THEN
        GOSUB UPDATE.PAYMENT.END.DATE
    END

RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Present Value>
*** <desc>Update Present value (oustanding amount)</desc>
UPDATE.PRESENT.VALUE:
    
    TEMP.VALUE = PRESENT.VALUE
    IF IS.PARTICIPANT THEN
        TEMP.VALUE = PARTICIPANT.PRESENT.VALUE<1,PART.POS>
    END

    BEGIN CASE
        CASE PAYMENT.METHOD = "MAINTAIN"
            IF PAYMENT.METHOD.NEW = "DUE" THEN
                TEMP.VALUE = TEMP.VALUE - (AMOUNT * DUE.AMOUNT.SIGN)          ;* If Savings plan increase present value, else decrease it
            END ELSE
                TEMP.VALUE = TEMP.VALUE - AMOUNT          ;* Decrease the present value (Deposits, Loans, Savings)
            END
        CASE PAYMENT.METHOD = "DUE"
            TEMP.VALUE = TEMP.VALUE - (AMOUNT * DUE.AMOUNT.SIGN)
        CASE PRODUCT.LINE EQ 'LENDING' AND PAYMENT.METHOD EQ 'PAY' AND PAY.BILL.TYPE EQ "DISBURSEMENT" AND AA.Interest.getRStoreProjection() AND AA.Framework.getContractDetails()<AA.Framework.CdIncludePrinAmounts> NE "YES" AND NOT(INCLUDE.DISBURSE.SCHEDULE)
            TEMP.VALUE =  TEMP.VALUE + AMOUNT
        CASE PRODUCT.LINE EQ 'LENDING' AND PAYMENT.METHOD EQ 'PAY'
            TEMP.VALUE = TEMP.VALUE   ;* Dont Increase the present value
        CASE PAYMENT.METHOD = "PAY"
            TEMP.VALUE = TEMP.VALUE - AMOUNT
    END CASE

    IF IS.PARTICIPANT THEN
        PARTICIPANT.PRESENT.VALUE<1,PART.POS> = TEMP.VALUE
    END ELSE
        PRESENT.VALUE = TEMP.VALUE
    END
    
RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Account amount / Oustanding Principal>
*** <desc>Calculate Account amount</desc>
CALCULATE.ACCOUNT.AMOUNT:

    IF NOT(AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdPaymentEndDate>) THEN       ;* Don't adjust for CALL contracts
        ADJUST.FINAL.AMOUNT = ""
    END

    GOSUB CHECK.RESIDUAL.PROCESS
    GOSUB GET.ACCOUNT.AMOUNT.CHECK
    tmp.R$STORE.PROJECTION = AA.Interest.getRStoreProjection()
    IF REMAIN.AMOUNT AND (REMAIN.AMOUNT LT ACCOUNT.AMOUNT.CHECK) AND NOT(tmp.R$STORE.PROJECTION) THEN
        GOSUB CHECK.ACTUAL.AMOUNT
    END

    IF PROCESS.RESIDUAL THEN
** During the final payment end date process there is a chance to amount value goes to less than or equal to zero and hence
** set the zero principal position. Which will be used make due action routine to update the bill amount as recalculated amount.
        ZERO.PRINCIPAL.POS = PAY.DATE.I
**System shouldn't allocate the resudual amount or remaining amount to the INFO bill type.
        IF SCHEDULE.INFO<8> AND PAY.BILL.TYPE EQ "INFO" ELSE
            IF TEMP.VALUE GE RESIDUAL.AMOUNT THEN
                AMOUNT = TEMP.VALUE - RESIDUAL.AMOUNT
            END ELSE
                AMOUNT = TEMP.VALUE
            END
        END
    END ELSE
        IF REMAIN.AMOUNT THEN
            IF (REMAIN.AMOUNT LT ACCOUNT.AMOUNT.CHECK) THEN
** If account property remaining amount value goes to less than current bill os amount set the zero principal position.
** Which will be used make due action routine to update the bill amount as recalculated amount.
                ZERO.PRINCIPAL.POS = PAY.DATE.I
                IF TEMP.VALUE GT 0 THEN
                    AMOUNT = REMAIN.AMOUNT
                END ELSE
                    AMOUNT = 0
                END
            END ELSE
                AMOUNT = ACCOUNT.AMOUNT.CHECK
            END
        END ELSE
            IF NOT(OUTSTANDING.AMOUNT.REQD) OR (PAY.BILL.TYPE EQ 'DISBURSEMENT' AND (CUR.TERM.AMT OR AA.Framework.getContractDetails()<AA.Framework.CdIncludePrinAmounts> EQ "YES" OR INCLUDE.DISBURSE.SCHEDULE)) THEN        ;*For savings where there is no Present Value, we need to take payment amount
                AMOUNT = ACCOUNT.AMOUNT.CHECK                  ;*Amount has to be assigned even if IncludePrinAmounts is set as CUR.TERM.AMT variable is null since we ignore in  GET.OUTSTANDING.FROM.BALANCES para.
            END

        END
    END

RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= Calculate Disburse Amt>
*** <desc> </desc>
CALCULATE.DISBURSE.AMT:

* Logic is to first calculate disbrusement amount for each schedule and compare it against the term amount.
* Store remaining disbursement amount with the amount totally disbursed till previous schedule.
* Change the disbursement amount to be difference between commitment amount and disbursement amount as of previous schedule.
* For ex: if TA is 12T and Disbursement is scheduled for 5T every month then
* On 3rd Schedule -> TOT.DIS.AMT will be 15T, REMAIN.DIB.AMT will be 10T and CUR.TERM.AMT will be 12T
* Originally AMOUNT will be 5T but since TOT.DIS.AMT is greater than CUR.TERM.AMT, AMOUNT will be come 2T.

    IF CUR.TERM.AMT  OR AA.Framework.getContractDetails()<AA.Framework.CdIncludePrinAmounts> EQ "YES" OR INCLUDE.DISBURSE.SCHEDULE THEN     ;* Only when there is automatic disbrusement defined but not actually disbursed
        CURRENT.TERM.AMT = CUR.TERM.AMT
        IF AA.Framework.getContractDetails()<AA.Framework.CdIncludePrinAmounts> EQ "YES" OR INCLUDE.DISBURSE.SCHEDULE THEN ;* get the Current Loan Term Amount.
            BAL.DETAILS = ""
            CURRENT.TERM.AMT = ""
            CUR.PROPERTY = TERM.AMT.PROPERTY
            PARTICIPANT = PART.ID<1,PART.POS>
            GOSUB GET.PARTICIPANT.ACCT.MODE     ;* Send Participant AcctMode to get Balance Name
            AA.ProductFramework.PropertyGetBalanceName(ARRANGEMENT.ID, CUR.PROPERTY, "CUR", "", "", TOT.TERM.BAL)
            AA.Framework.GetPeriodBalances(ACCOUNT.ID, TOT.TERM.BAL, DATE.OPTIONS, EFFECTIVE.DATE, "", "", BAL.DETAILS, "")
            IF BAL.DETAILS THEN
                CURRENT.TERM.AMT = ABS(BAL.DETAILS<AC.BalanceUpdates.AcctActivity.IcActBalance>)
            END
            ACCOUNT.ID = SAVE.ACCOUNT.ID
        END
    END
   
    IF CURRENT.TERM.AMT THEN
                  
        BEGIN CASE
            CASE NO.MORE.DISB.SCH ;* Do not project disbursement schedule
                AMOUNT = 0

            CASE 1
                TOT.DIS.AMT += AMOUNT       ;* Total disbursed amount based on schedule

                IF TOT.DIS.AMT GT CURRENT.TERM.AMT  THEN   ;* Schedule amount for disbursement has exceeded committment amount
                    AMOUNT = CURRENT.TERM.AMT  - REMAIN.DISB.AMT     ;* Schedule amount should be the amount that is actually available
                    NO.MORE.DISB.SCH = 1    ;* Stop projecting disbrusement schedule
                END ELSE
                    REMAIN.DISB.AMT = TOT.DIS.AMT     ;* This is the amount disbrused so far
                END

        END CASE

    END

RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= Check Account Amount>
*** <desc>Check the account property amount</desc>
GET.ACCOUNT.AMOUNT.CHECK:

    BEGIN CASE
        CASE CALC.TYPE MATCHES "CONSTANT":@VM:"PROGRESSIVE":@VM:"ACCELERATED":@VM:"PERCENTAGE":@VM:"FIXED EQUAL":@VM:"ADVANCE" ; * For the Calc type as Advance
            ACCOUNT.AMOUNT.CHECK = CALC.AMOUNT

            IF ACCOUNT.AMOUNT.CHECK LT 0 THEN         ;* Should not get here at all
                ACCOUNT.AMOUNT.CHECK = 0
            END

        CASE CALC.TYPE MATCHES "ACTUAL" :@VM:"TRANSACTION"
            IF PAYMENT.PERCENT NE "" THEN
                BEGIN CASE
                    CASE PAY.BILL.TYPE EQ "DISBURSEMENT" AND (AA.Framework.getContractDetails()<AA.Framework.CdIncludePrinAmounts> EQ "YES" OR INCLUDE.DISBURSE.SCHEDULE)
                        TOTAL.TERM.AMOUNT = ""
                        BAL.DETAILS = ""
                        CUR.PROPERTY = TERM.AMT.PROPERTY
                        PARTICIPANT = PART.ID<1,PART.COUNT>
                        GOSUB GET.PARTICIPANT.ACCT.MODE     ;* Send Participant AcctMode to get Balance Name
                        
                        IF IS.PARTICIPANT THEN
                            IF PARTICIPANT EQ "BOOK" THEN
                                ACCOUNT.ID = ACCOUNT.ID:'*':GlCustomer          ;* Account no for Book
                            END ELSE
                                ACCOUNT.ID = ACCOUNT.ID:'*':PARTICIPANT         ;* Account no for Participant
                            END
                            DATE.OPTIONS<7> = PART.ACCT.MODE<1,PART.COUNT>
                            DATE.OPTIONS<8> = 1
                        END
                        AA.ProductFramework.PropertyGetBalanceName(ARRANGEMENT.ID, CUR.PROPERTY, "TOT", "", "", TOT.TERM.BAL)
                        AA.Framework.GetPeriodBalances(ACCOUNT.ID, TOT.TERM.BAL, DATE.OPTIONS, EFFECTIVE.DATE, "", "", BAL.DETAILS, "")
                        TOTAL.TERM.AMOUNT = ABS(BAL.DETAILS<AC.BalanceUpdates.AcctActivity.IcActBalance>)
                        ACCOUNT.ID = SAVE.ACCOUNT.ID
                        ACCOUNT.AMOUNT.CHECK = TOTAL.TERM.AMOUNT * PAYMENT.PERCENT / 100
***During schedule projection, there is a possibility where the projection outstanding amount might go beyond the total commitment
***To overcome, we have a variable to keep track of available amount and show projections only till the available amount

                        IF ACCOUNT.AMOUNT.CHECK GT AVAILABLE.COMMIT.AMT AND (AA.Framework.getContractDetails()<AA.Framework.CdIncludePrinAmounts> MATCHES "YES":@VM:"PROGRESSIVE") THEN
                            ACCOUNT.AMOUNT.CHECK = AVAILABLE.COMMIT.AMT
                        END
                        AVAILABLE.COMMIT.AMT -= ACCOUNT.AMOUNT.CHECK  ;*Available amount is iterated for each schedule to find out the remaining amount to disburse, when left blank
                    CASE PAY.BILL.TYPE EQ "DISBURSEMENT"
                        ACCOUNT.AMOUNT.CHECK = TOT.TERM.AMT * PAYMENT.PERCENT / 100
                        IF ACCOUNT.AMOUNT.CHECK GT AVAILABLE.COMMIT.AMT AND (AA.Framework.getContractDetails()<AA.Framework.CdIncludePrinAmounts> MATCHES "PROGRESSIVE") THEN
                            ACCOUNT.AMOUNT.CHECK = AVAILABLE.COMMIT.AMT
                        END
                        IF FULL.SHARE.TRANSFER AND NOT(PART.ID<1,PART.COUNT> MATCHES 'BORROWER':@VM:'BOOK')THEN    ;* For full transfer consider the INF balance for disbursement instead of PART balance.
                            TOTAL.TERM.AMOUNT = ""
                            BAL.DETAILS = ""
                            AA.ProductFramework.PropertyGetBalanceName(ARRANGEMENT.ID, TERM.AMT.PROPERTY, "TOT", "", "", TOT.TERM.BAL)
                            AA.Framework.GetPeriodBalances(ACCOUNT.ID, TOT.TERM.BAL, DATE.OPTIONS, EFFECTIVE.DATE, "", "", BAL.DETAILS, "")
                            TOTAL.TERM.AMOUNT = ABS(BAL.DETAILS<AC.BalanceUpdates.AcctActivity.IcActBalance>)
                            ACCOUNT.AMOUNT.CHECK = TOTAL.TERM.AMOUNT * PAYMENT.PERCENT / 100
                        END
                        AVAILABLE.COMMIT.AMT -= ACCOUNT.AMOUNT.CHECK  ;*Available amount is iterated for each schedule to find out the remaining amount to disburse, when left blank
                        
                    CASE CALC.TYPE EQ "TRANSACTION"
                        ACCOUNT.AMOUNT.CHECK = REMAIN.AMOUNT * PAYMENT.PERCENT / 100
                        
                    CASE 1
                        ACCOUNT.AMOUNT.CHECK = PRESENT.VALUE * PAYMENT.PERCENT / 100
                END CASE
                
                ROUND.AMT = ACCOUNT.AMOUNT.CHECK
                GOSUB GET.ROUND.AMT
                ACCOUNT.AMOUNT.CHECK = ROUND.AMT
            END ELSE
                IF IS.PARTICIPANT THEN
                    GOSUB CALCULATE.PARTICIPANT.DISBURSE.AMOUNT             ;* calculate Disbursement amount for participant when Payment percentage is not defined
                END ELSE
                    ACCOUNT.AMOUNT.CHECK = PAYMENT.AMOUNT.LIST<1,PAY.TYPE.I>
***Available amount is iterated for each schedule to find out the remaining amount to disburse, when left blank
***Available commitment amount should be taken only when there is no actual amount defintion for the disbursment payment type.
***if actual amount is given as 0 then it has to be considered while issuing a bill for disbursement.
                    IF PAY.BILL.TYPE EQ "DISBURSEMENT" THEN
                        IF NOT(PAYMENT.AMOUNT.LIST<1,PAY.TYPE.I>) AND PAYMENT.AMOUNT.LIST<1,PAY.TYPE.I> NE "0" THEN
                            ACCOUNT.AMOUNT.CHECK = AVAILABLE.COMMIT.AMT
                        END
***During schedule projection, there is a possibility where the projection outstanding amount might go beyond the total commitment
***To overcome, we have a variable to keep track of available amount and show projections only till the available amount
                        IF ACCOUNT.AMOUNT.CHECK GT AVAILABLE.COMMIT.AMT AND (AA.Framework.getContractDetails()<AA.Framework.CdIncludePrinAmounts> MATCHES "YES":@VM:"PROGRESSIVE") THEN
                            ACCOUNT.AMOUNT.CHECK = AVAILABLE.COMMIT.AMT
                        END
                        AVAILABLE.COMMIT.AMT -= ACCOUNT.AMOUNT.CHECK
                    END
                END
            END
            PAY.SCHEDULE.MIN.PAY = RAISE(R.PAYMENT.SCHEDULE)
            PAYMENT.MIN.AMT = PAYMENT.MIN.AMT.LIST<1, PAY.TYPE.I>

            BILLS.COMBINE = R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsBillsCombined>

            IF PAYMENT.MIN.AMT GT 0 THEN    ;*Only if Minimum amount is present, do the processing
                PAYMENT.AMOUNT.DETAILS = PAYMENT.AMOUNT.LIST    ;*Don't pass this variable. If someone changes it that's all we are finished
                BILL.PAY.DETAILS = BILL.PAY.TYPE.LIST ;*Don't pass the original variable as it might get changed in the routine
                PAY.METHOD.DETAILS = PAYMENT.METHOD.LIST
                DEL PAYMENT.AMOUNT.DETAILS<1,PAY.TYPE.I>        ;*Remove the current details as we pass it separately through ACCOUNT.AMOUNT.CHECK so that it is not duplicated
                DEL BILL.PAY.DETAILS<1,PAY.TYPE.I>    ;*Remove corresponding Bill type details as well.
                DEL PAY.METHOD.DETAILS<1,PAY.TYPE.I>  ;*Remove corresponding payment method details as well.
                AA.PaymentSchedule.CalculateMinimumPaymentAmount(PAYMENT.DATE, PAYMENT.MIN.AMT, BILL.PAYMENT.TYPE, PAYMENT.METHOD, PAY.METHOD.DETAILS, BILL.PAY.DETAILS, PAYMENT.AMOUNT.DETAILS, ACCOUNT.AMOUNT.CHECK, BILLS.COMBINE)
            END

        CASE CALC.TYPE = "OTHER"  ;* Check if user routines exists and call
            GOSUB CALCULATE.USER.AMOUNT

        CASE 1
            IF CALCULATED.TYPE THEN         ;* For linear type advance schedules, the CALC.AMOUNT will be the full linear payment amount
                ACCOUNT.AMOUNT.CHECK = CALC.AMOUNT
            END ELSE
                ACCOUNT.AMOUNT.CHECK = PAYMENT.AMOUNT.LIST<1,PAY.TYPE.I>
            END
    END CASE

RETURN

*** </region>
*-----------------------------------------------------------------------------
*** <region name=CALCULATE.PARTICIPANT.DISBURSE.AMOUNT>
CALCULATE.PARTICIPANT.DISBURSE.AMOUNT:
*** <desc>calculate Disbursement amount for participant when Payment percentage is not defined</desc>

* When disbursment amount is defined for borrower,do prorata
* calculation to arrive at disbursement amount for each participant
  
    PRO.RATA.AMOUNT = 0
    PartValue = 0
    BorrowerValue = 0
    PrevValue = 0
    
    PartValue = CUR.TERM.AMT            ;* participant current termamount
    BorrowerValue =  BORROWER.PAYMENT.AMOUNT.LIST<1, PAY.TYPE.I, PROPERTY.I>            ;*calculated payment amount for borrower
    PrevValue = SAVE.CUR.TERM.AMT<1>        ;*Borrower current term amount

    AA.PaymentSchedule.CalculateProRataAmount(PartValue, BorrowerValue, PrevValue, PRO.RATA.AMOUNT, ARR.CCY, '', '', '')        ;*Calculate ProRata amount for participant
    ACCOUNT.AMOUNT.CHECK = PRO.RATA.AMOUNT
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= Check residual process>
*** <desc>Check residual process</desc>
CHECK.RESIDUAL.PROCESS:

    PROCESS.RESIDUAL = 1      ;** do adjust of final amt if its last occurence of account.
    ADD.RESIDUAL =  ''      ;* Initialise to null
    PAY.END.DATE.POS = ''
    
    BEGIN CASE
        CASE PAY.DATE.I NE ACCOUNT.PROP.FINAL.POS
            PROCESS.RESIDUAL = ''
        CASE PAY.TYPE.I NE ACCOUNT.FINAL.POS
            PROCESS.RESIDUAL = ''
        CASE REQD.END.DATE<1> AND REQD.END.DATE<1> NE AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdPaymentEndDate>        ;* If end date equal to payment end date is that last account positions!!
            PROCESS.RESIDUAL = ''
* In the enquiry, if we set the ToDate to a date lesser than the last payment date, then we dont need to add the residual amount
* Only if we are giving a date greater than the payment end date, then add residual to last principal
            IF REQD.END.DATE<1> GE AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdPaymentEndDate> THEN   ;* Check if the error code delivered as part of component dependency exists
                IF NOT(RESIDUAL.AMOUNT) AND CALC.AMOUNT AND NOT(QUOTATION.REF) AND SCHEDULE.INFO<8> AND NOT(AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdRenewalDate>) AND PRODUCT.LINE EQ "LENDING" THEN
* In the enquiry, if we set the ToDate to a date Greater than the last payment date, then we need to add the residual amount
* When we have renewal date in AA.PAYMENT.SCHEDULE.ISSUEBILL we are not setting ADJUST.FINAL.AMOUNT flag during Issuebill of last schedule.So restriciting this fix only when there is no renewal date
                    IF DATE.POS THEN
                        CHECK.VAL = AA.Framework.getContractDetails()<AA.Framework.CdBalAmount,BAL.POS,DATE.POS>  ;* Get the value of the last schedule
                    END ELSE
*** for single BAL.POS (ie. CURRLOANACCOUNT if it has more than one effective balance on different dates in ContractDetails) and the current PAY.DATE.I is the ACCOUNT.PROP.FINAL.POS and ACCOUNT.FINAL.POS ,system can get the lastest effective balance as RESIDUAL.AMOUNT
                        PREV.BAL.AMT.POS = DCOUNT(AA.Framework.getContractDetails()<AA.Framework.CdBalAmount,BAL.POS>, @SM)
                        CHECK.VAL = AA.Framework.getContractDetails()<AA.Framework.CdBalAmount,BAL.POS,PREV.BAL.AMT.POS> ;* Get the value of the last schedule
                    END
                    IF ABS(CHECK.VAL) - PRESENT.VALUE EQ "0" THEN  ;* if the difference is 0, then pass the residual seperately
                        RESIDUAL.AMOUNT= PRESENT.VALUE
                    END
                END
                IF RESIDUAL.AMOUNT THEN
                    ADD.RESIDUAL = '1'  ;* Set flag only if Residual amount is present
                END
            END
** Previously ADJUST.FINAL.AMOUNT flag only from Iterate and projection, now same flag is setting from issue bill and make due activities
** also, because during raising bill also we need to check the last account pos, if that is last account pos we need to adjust
** account amount.
        CASE NOT(ADJUST.FINAL.AMOUNT)
            PROCESS.RESIDUAL = ''

        CASE PAY.BILL.TYPE EQ "DISBURSEMENT"
            PROCESS.RESIDUAL = ''

        CASE PAY.TYPE.I EQ ACCOUNT.FINAL.POS AND PAY.BILL.TYPE EQ 'EXPECTED'        ;* For Deposits do not check for residual on the last payment date
            PROCESS.RESIDUAL = ''
            
** During the schedule projection don't set PROCESS.RESIDUAL flag when actual amount defined payment types in case the payment date is the renewal
** date of the arr. In the above case there can be outstanding balance even after the last schedule.
        CASE SCHEDULE.INFO<8>     ;* Determine process from enquiry
            IF NO.CYCLES AND PAYMENT.DATE NE AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdPaymentEndDate> THEN
                PROCESS.RESIDUAL = ''
            END ELSE
                ACTUAL.FOUND = ""
                IF PAYMENT.DATE EQ AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdRenewalDate> THEN
                    GOSUB CHECK.ACTUAL.AMOUNT       ;* Check the actual amount defined payment type or not.
                END
** If we don't have the CALC.AMOUNT,Then system should assign the PRESENT.VALUE to RESIDUAL.AMOUNT.
                IF NOT(RESIDUAL.AMOUNT) AND NOT(QUOTATION.REF)  AND ((PAYMENT.END.DATE GT PAYMENT.DATE) OR (ACTUAL.FOUND)) AND (CALC.TYPE MATCHES "CONSTANT":@VM:"LINEAR") THEN
                    IF DATE.POS THEN
                        CHECK.VAL = AA.Framework.getContractDetails()<AA.Framework.CdBalAmount,BAL.POS,DATE.POS>  ;* Get the value of the last schedule
                    END ELSE
*** for single BAL.POS (ie. CURRLOANACCOUNT if it has more than one effective balance on different dates in ContractDetails) and the current PAY.DATE.I is the ACCOUNT.PROP.FINAL.POS and ACCOUNT.FINAL.POS ,system can get the lastest effective balance as RESIDUAL.AMOUNT
                        PREV.BAL.AMT.POS = DCOUNT(AA.Framework.getContractDetails()<AA.Framework.CdBalAmount,BAL.POS>, @SM)
                        CHECK.VAL = AA.Framework.getContractDetails()<AA.Framework.CdBalAmount,BAL.POS,PREV.BAL.AMT.POS> ;* Get the value of the last schedule
                    END
                    IF ABS(CHECK.VAL) - PRESENT.VALUE EQ "0" THEN  ;* if the difference is 0, then pass the residual seperately
                        RESIDUAL.AMOUNT= PRESENT.VALUE
                    END
                END
                IF RESIDUAL.AMOUNT AND NOT(QUOTATION.REF) THEN   ;* Check if the error code delivered as part of component dependency exists
                    ADD.RESIDUAL = '1'  ;* Set flag only if Residual amount is present
                END
        
                IF  NOT(REQD.END.DATE<1>) AND RESIDUAL.AMOUNT THEN ;* If REQD.END.DATE is not set and residual amount is present during the schedule projection don't set PROCESS.RESIDUAL flag
                    PROCESS.RESIDUAL = ''  ;* existing check
                    PAY.END.DATE.POS = PAY.DATE.I
                END
            
                IF ACTUAL.FOUND THEN
                    PROCESS.RESIDUAL = ''
                END
            END
 
    END CASE
 
RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Check Actual Amount>
*** <desc>Check Actual amount greate than the Remaining maount</desc>
CHECK.ACTUAL.AMOUNT:

    ACTUAL.FOUND = ""
    ACTUAL.AMOUNT = PAYMENT.AMOUNTS<PAY.DATE.I,PAY.TYPE.I>
    
    IF SCHEDULE.INFO<54> AND SCHEDULE.INFO<54> NE PAYMENT.TYPE THEN
        TEMP.ACTUAL = ACTUAL.AMOUNT
        ACTUAL.AMOUNT = ""
    END
    
    DIFF.AMT = ABS(REMAIN.AMOUNT - ACCOUNT.AMOUNT.CHECK)    ;* difference amount
    TEMP.PAYMENT.TYPES = R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsPaymentType>
    PAY.TYPE = 1
    LOOP
        REMOVE PAYMENT.TYPE FROM TEMP.PAYMENT.TYPES SETTING PAY.POS
    WHILE PAYMENT.TYPE AND NOT(ACTUAL.FOUND)      ;* If One payment type has multiple actual amounts then we should have to loop for each value
        FOR SM.CNT = 1 TO DCOUNT(R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsActualAmt,PAY.TYPE>,@SM)
            IF ACTUAL.AMOUNT AND (ACTUAL.AMOUNT EQ R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsActualAmt,PAY.TYPE,SM.CNT>) THEN
                PS.BILL.TYPE = R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsBillType,PAY.TYPE>
                LOCATE PS.BILL.TYPE IN BILL.TYPE.ARRAY<1,1> SETTING BILL.TYPE.POS THEN
                    SYST.BILL.TYPE = BILL.TYPE.ARRAY<2, BILL.TYPE.POS>
                END ELSE
                    AA.PaymentSchedule.GetSysBillType(PS.BILL.TYPE, SYST.BILL.TYPE, '')
                    BILL.TYPE.ARRAY<1,-1> = PS.BILL.TYPE
                    BILL.TYPE.ARRAY<2,-1> = SYST.BILL.TYPE
                END
                IF SYST.BILL.TYPE NE "INFO" THEN ;* Actual amount should be validated with the payment amount for payments other than INFO bill type
                    TEMP.PAYMENT.TYPE = PAYMENT.TYPE
                    ACTUAL.FOUND = 1
                END
            END
        NEXT SM.CNT
        PAY.TYPE += 1
    REPEAT
*** Only when define the actual amount and scheduled amount is greater than the current outstanding amount
*** then only raise the error message.
*** SCHEDULE.INFO<79> - This flag used to iterate the payment dates completely, without this flag system has skipped to process the last payment date,
*** so that interest is not calculated properly during principal decrease activity for new the new principal balance
    IF ACTUAL.FOUND AND NOT(SCHEDULE.INFO<8>) AND NOT(SCHEDULE.INFO<79>) THEN
        EXIT.LOOP = 1
        PAY.TYPE = PAY.TYPE - 1
        RET.ERROR = "AA-ACT.AMT.GT.CUR.OUTSTAND.AMOUNT":@FM:DIFF.AMT:@VM:TEMP.PAYMENT.TYPE:@VM:PAYMENT.DATE:@FM:PAY.TYPE
    END
    
    IF TEMP.ACTUAL THEN
        ACTUAL.AMOUNT = TEMP.ACTUAL
    END
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= Update Contract details>
*** <desc>Update contract details </desc>
** Update contract details
UPDATE.CONTRACT.DETAILS:

*For Deposits & Savings, we need to check the Payment Method before deciding if the Balance amount should be increased or decreased

* while adding the capitalised amount to the outstanding principal, current processing payment type and capitalised payment types will be different.
*Therefore no need to check for holiday amount and holiday date when adding the details of capitalised amount to the outstanding principal
    IF NOT(TEMP.CAP.PAYMENT.TYPE) THEN
        IF (HOLIDAY.AMOUNT AND HOLIDAY.AMOUNT LE AMOUNT) OR (NOT(HOLIDAY.AMOUNT) AND HOLIDAY.DATE) AND NOT(RESTRICTED.PROPERTY) THEN ;* When the holiday amount less than or equal to calculated amount,assign property amount as holiday amount.
            IF DEFER.ALL.HOLIDAY.FLAG AND (SCHEDULE.INFO<51> OR SCHEDULE.INFO<73> OR SCHEDULE.INFO<72> OR SCHEDULE.INFO<52>) AND NOT(RESTRICTED.PROPERTY) THEN
                BEGIN CASE
                    CASE (SCHEDULE.INFO<72> AND SCHEDULE.INFO<51>) OR SCHEDULE.INFO<52>
                        PAYMENT.PROPERTY.AMOUNT = AMOUNT - HOLIDAY.AMOUNT ;* Since holiday amount will be paid in that period, do not include for calc amount calculation for holiday payment types in aa.arr.paymentschedule
                        IF PAYMENT.PROPERTY.AMOUNT EQ 0 THEN
                            PAYMENT.PROPERTY.AMOUNT = '' ;* Both Holiday amount and payment property amount is same then no need to return the payment property amount for the payment date
                        END
                    CASE (SCHEDULE.INFO<8> OR SCHEDULE.INFO<73>) AND HOLIDAY.PROPERTY.AMOUNT NE ''
                        PAYMENT.PROPERTY.AMOUNT = HOLIDAY.PROPERTY.AMOUNT ;* During projection call need to show holiday principal amount for the Holiday date, instead of showing original principal amount
                    CASE SCHEDULE.INFO<8> AND HOLIDAY.AMOUNT
                        PAYMENT.PROPERTY.AMOUNT = HOLIDAY.AMOUNT ;* During projection call need to show holiday amount for the Holiday date, instead of showing original principal amount
                    CASE SCHEDULE.INFO<8>
                        PAYMENT.PROPERTY.AMOUNT = ''
                END CASE
                IF SCHEDULE.INFO<51> AND NOT(SCHEDULE.INFO<33>) THEN
                    LOCATE PAYMENT.DATE IN TEMP.BAL.EFF<PART.POS,BAL.POS,1> SETTING PAST.PAYMENT.DATE.POS THEN
                        AMOUNT = 0
                    END
                END
            END ELSE
                IF SCHEDULE.INFO<51> AND HOLIDAY.AMOUNT THEN
                    LOCATE PAYMENT.DATE IN TEMP.BAL.EFF<PART.POS,BAL.POS,1> SETTING PAST.PAYMENT.DATE.POS THEN
                        PAYMENT.PROPERTY.AMOUNT = HOLIDAY.AMOUNT
                        HOLIDAY.AMOUNT = 0
                    END
                END
                AMOUNT = HOLIDAY.AMOUNT
            END
        END

* If the holiday amount is higher than the actual amount, at last for the Account property assign that amount since we can able to define higher holiday amount for the payment type which has account property
        IF PAYMENT.PROPERTY.CLASS EQ "ACCOUNT" AND (HOLIDAY.AMOUNT GT AMOUNT) AND NOT(RESTRICTED.PROPERTY) THEN
            AMOUNT = HOLIDAY.AMOUNT
        END
        
        IF NOT(RESTRICTED.PROPERTY) AND HOLIDAY.AMOUNT THEN ;* When non restricted property comes,decrement the holiday amount from calculated amount to utilise remaining amount for other properties
            HOLIDAY.AMOUNT -= AMOUNT
        END
        
        IF HOLIDAY.AMOUNT AND HOLIDAY.AMOUNT LE 0 THEN ;* If holiday amount goes less than or equal to zero,then make is as zero
            HOLIDAY.AMOUNT = 0
        END
    END
     
    SAVE.AMOUNT = AMOUNT
    BEGIN CASE
        CASE PRODUCT.LINE EQ 'DEPOSITS' AND (PAYMENT.METHOD MATCHES "PAY" OR (PAYMENT.METHOD.NEW EQ "PAY" AND PAYMENT.METHOD EQ "MAINTAIN"))    ;*Should Decrease the balance
            AMOUNT = AMOUNT * (-1)
        CASE PRODUCT.LINE EQ 'SAVINGS' AND PAYMENT.METHOD EQ "PAY"        ;*Should Decrease the balance
            AMOUNT = AMOUNT * (-1)
        CASE PRODUCT.LINE EQ 'LENDING' AND PAYMENT.METHOD EQ "PAY" AND (AA.Interest.getRStoreProjection() OR AA.Framework.getContractDetails()<AA.Framework.CdIncludePrinAmounts> EQ "YES" OR INCLUDE.DISBURSE.SCHEDULE OR INCLUDE.PRINCIPAL.PAYMENTS)      ;*Should Decrease the balance
            AMOUNT = AMOUNT * (-1)
    END CASE
    
    IF PAYMENT.DEFER.DATE AND PAYMENT.PROPERTY.CLASS NE "ACCOUNT" THEN
        COMPARE.DATE = PAYMENT.DEFER.DATE         ;*Add details on the Defer date as this is the date on which accounting will be raised for DUE/PAY/CAP
    END ELSE
        COMPARE.DATE = PAYMENT.DATE     ;*Else take the payment date on which we process accounting entries
    END

    GOSUB GET.UPDATE.FIELD.NO       ;* Populate ContractDetails field positions
    GOSUB LOAD.CONTRACT.DETAILS     ;* Get updated Values from ContractDetails common
    
* For a Participant, ProRata amount is calculate and directly updated as outstanding amount
    GOSUB CALCULATE.PARTICIPANT.NEXT.OUTSTANDING.AMT        ;* Calculate Next Outstanding amount for Participant

*   For EXPECTED Bill.Payment.Type on Maturity.Date, dont update the contract details as
*   there can be chances that the EXPECTED bill get cancelled, if its unpaid
    IF BILL.PAYMENT.TYPE EQ "EXPECTED" AND PAYMENT.DATE EQ MAT.DATE AND NOT(SCHEDULE.INFO<8>) THEN
        AMOUNT = 0
    END
    
    LOCATE COMPARE.DATE IN TEMP.BAL.EFF<PART.POS,BAL.POS,1> BY "AR" SETTING DATE.POS THEN
        IF NOT(IS.PARTICIPANT) THEN     ;*Borrower Outstanding amount update
            IF NOT(SCHEDULE.INFO<51>) THEN  ;* donot update outstanding amount during forward recalc activity... as make due would have already happened with correct outstanding amount.
    
                TEMP.BAL.AMT<PART.POS,BAL.POS,DATE.POS> = TEMP.BAL.AMT<PART.POS,BAL.POS,DATE.POS> + AMOUNT  ;* Sign to indicate repayment
            END
        END ELSE                        ;*Participant Outstanding amount update
            TEMP.BAL.AMT<PART.POS,BAL.POS,DATE.POS> = AMOUNT  ;* Update calculatedProRata amount
        END
    END ELSE
        IF NOT(IS.PARTICIPANT) THEN     ;*Borrower Outstanding amount update
            INS COMPARE.DATE BEFORE TEMP.BAL.EFF<PART.POS,BAL.POS,DATE.POS>
            INS TEMP.BAL.AMT<PART.POS,BAL.POS,DATE.POS-1> + AMOUNT BEFORE TEMP.BAL.AMT<PART.POS,BAL.POS,DATE.POS>
        END ELSE                        ;*Participant Outstanding amount update
            INS COMPARE.DATE BEFORE TEMP.BAL.EFF<PART.POS,BAL.POS,DATE.POS>
            INS AMOUNT BEFORE TEMP.BAL.AMT<PART.POS,BAL.POS,DATE.POS>           ;* Update calculatedProRata amount
        END
    END

    AMOUNT = SAVE.AMOUNT
    CURR.POS = DATE.POS
    LOOP
        CURR.POS += 1
    WHILE TEMP.BAL.EFF<PART.POS,BAL.POS,CURR.POS>
        IF NOT(IS.PARTICIPANT) THEN             ;* Borrower OutstandingAmount Update
            TEMP.BAL.AMT<PART.POS,BAL.POS,CURR.POS> = TEMP.BAL.AMT<PART.POS,BAL.POS,CURR.POS> + AMOUNT
        END ELSE                                ;* Participant OutstandingAmount Update
            TEMP.BAL.AMT<PART.POS,BAL.POS,CURR.POS> = AMOUNT            ;* Update calculatedProRata amount
        END
    REPEAT

    IF COMPARE.DATE NE PAYMENT.DATE THEN          ;*Get the Present Value as on Payment date's position
        LOCATE PAYMENT.FIN.DATE IN TEMP.BAL.EFF<PART.POS,BAL.POS,1> BY "AR" SETTING DATE.POS ELSE
            IF DATE.POS GT 1 THEN
                DATE.POS -= 1
            END
        END
    END

    GOSUB BUILD.CONTRACT.DETAILS    ;* Set updated Values in ContractDetails common
    
    IF IS.PARTICIPANT THEN
        temp = AA.Framework.getContractDetails()<AA.Framework.CdPartBalAmount>
        CONVERT '*' TO @FM IN temp
        PARTICIPANT.PRESENT.VALUE<1,PART.POS> = ABS(temp<PART.POS,BAL.POS,DATE.POS>)        ;*  Reset to AA$CONTRACT.DETAILS at the end of every day
    END ELSE
        PRESENT.VALUE = ABS(AA.Framework.getContractDetails()<AA.Framework.CdBalAmount,BAL.POS,DATE.POS>) ;*Ensure we reset to AA$CONTRACT.DETAILS at the end of every day
    END
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= Check DeferAll Holiday>
*** <desc> Check current processing payment date is Holiday one or not</desc>
CHECK.DEFER.ALL.HOLIDAY.PROPERTY:
    
    DEFER.ALL.HOLIDAY.FLAG = 0    ;* Check Defer All Flag present in account details for corresponding payment type and payment holiday date
    HOL.PROPERTY.DETAILS = ""     ;* Get holiday property amount details for corresponding payment type and payment holiday date
    
*** Check Current payment has declared as Holiday.
    TOTAL.HOLIDAY.PAYMENT.TYPE = DCOUNT(tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolPaymentType>,@VM)
*** If HOL.START.DATE is different but same HolPaymentType system update on two set of holiday details for HolPaymentType in Account details.
*** Hence, looping the each HolPaymentTyp and check with PaymentType
   
    FOR HOL.PAY.TYPE.POS = 1 TO TOTAL.HOLIDAY.PAYMENT.TYPE
        HOLIDAY.PAYMENT.INFO = tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolPaymentType>
        HOLIDAY.PAYMENT.TYPES = FIELDS(HOLIDAY.PAYMENT.INFO,"-",1)
        
        IF PAYMENT.TYPE EQ HOLIDAY.PAYMENT.TYPES<1,HOL.PAY.TYPE.POS> THEN
            LOCATE PAYMENT.DATE IN tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolidayDate,HOL.PAY.TYPE.POS,1> SETTING HOL.POS THEN
                BEGIN CASE
                    CASE tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolRepayOption,HOL.PAY.TYPE.POS> EQ "DEFER.ALL"
                        DEFER.ALL.HOLIDAY.FLAG = 1
                        IF SCHEDULE.INFO<53> THEN
                            HOLIDAY.AMOUNT = "" ;* If it is called from iterate routine, Skip holiday amount when repay option set as DeferAll
                            IF PAYMENT.AMOUNT.LIST<1, PAY.TYPE.I> EQ 0 THEN
                                HOL.PROP.DETAILS = tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolPropertyDetails,HOL.PAY.TYPE.POS,HOL.POS>
                                GOSUB UPDATE.PAYMENT.AMT.LIST
                            END
                        END ELSE
                            HOL.PROP.DETAILS = tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolPropertyDetails,HOL.PAY.TYPE.POS,HOL.POS>
                            CONVERT "#" TO @SM IN HOL.PROP.DETAILS
                            CONVERT "@" TO @SM IN HOL.PROP.DETAILS
                            LOCATE PAYMENT.PROPERTY IN HOL.PROP.DETAILS<1,1,1> SETTING POSITION THEN
                                HOL.PROPERTY.DETAILS = tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolPropertyDetails,HOL.PAY.TYPE.POS,HOL.POS>
                            END
                        END
                    CASE 1 ;* Need to handle existing Deffered/Null in RepayOtion when user inputted in holiday property amount details for holiday date
                        HOL.PROPERTY.DETAILS = tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolPropertyDetails,HOL.PAY.TYPE.POS,HOL.POS>
                END CASE
                TOTAL.HOLIDAY.PAYMENT.TYPE = HOL.PAY.TYPE.POS   ;* Exit from the Loop
            END
        END
    
    NEXT HOL.PAY.TYPE.POS

RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= UPDATE.PAYMENT.AMT.LIST>
*** <desc> Update payment amount for full ph scenario - During any changes in schedule frequency inbetween issue and make due</desc>
UPDATE.PAYMENT.AMT.LIST:
    CONVERT "#" TO @SM IN HOL.PROP.DETAILS
    CONVERT "@" TO @VM IN HOL.PROP.DETAILS
    TOT.HOL.PROP.CNT = DCOUNT(HOL.PROP.DETAILS,@VM)
    FOR HOL.PROP.CNT = 1 TO TOT.HOL.PROP.CNT
        IF HOL.PROP.DETAILS<1,HOL.PROP.CNT,1> EQ PAYMENT.PROPERTY THEN
            PAYMENT.AMOUNT.LIST<1, PAY.TYPE.I> = HOL.PROP.DETAILS<1,HOL.PROP.CNT,2>
            HOL.PROP.CNT = TOT.HOL.PROP.CNT
        END ELSE
            TEMP.PAY.PROPERTY.LIST = PAYMENT.PROPERTY.LIST<1,PAY.TYPE.I>
            TOT.LIST = DCOUNT(TEMP.PAY.PROPERTY.LIST,@SM)
            FOR CNT.PROP = 1 TO TOT.LIST
                IF HOL.PROP.DETAILS<1,HOL.PROP.CNT,1> EQ TEMP.PAY.PROPERTY.LIST<1,1,CNT.PROP> THEN
                    PAYMENT.AMOUNT.LIST<1, PAY.TYPE.I> = HOL.PROP.DETAILS<1,1,2>
                    CNT.PROP = TOT.LIST
                END
            NEXT CNT.PROP
            HOL.PROP.CNT = TOT.HOL.PROP.CNT
        END
    NEXT HOL.PROP.CNT

RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= Update Payment End Date>
*** <desc>Update Payment End Date </desc>
** Update Payment End Date
UPDATE.PAYMENT.END.DATE:

    tmp=AA.Framework.getContractDetails(); tmp<AA.Framework.CdPaymentEndDate>=PAYMENT.DATE; AA.Framework.setContractDetails(tmp)

RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= CALCULATE.USER.AMOUNT>
*** <desc>Calculate user amounts, check if routine exists and call the user routine</desc>
CALCULATE.USER.AMOUNT:
    LOCATE PAYMENT.TYPE IN PAYMENT.TYPE.ARRAY<1,1> SETTING PAY.TYPE.POS THEN
        R.PAYMENT.TYPE = RAISE(RAISE(PAYMENT.TYPE.ARRAY<2, PAY.TYPE.POS>))
    END ELSE
        AA.Framework.LoadStaticData("F.AA.PAYMENT.TYPE", PAYMENT.TYPE, R.PAYMENT.TYPE, "")
        PAYMENT.TYPE.ARRAY<1,-1> = PAYMENT.TYPE
        PAYMENT.TYPE.ARRAY<2,-1> = LOWER(LOWER(R.PAYMENT.TYPE))
    END
    CALC.ROUTINE = R.PAYMENT.TYPE<AA.PaymentSchedule.PaymentType.PtCalcRoutine>


    IF NOT(ARRANGEMENT.ID) THEN
        ARRANGEMENT.ID = AA.Framework.getArrId()
    END
 
*User exit field will support both JBC and java method implementation to acheive the local developements.

    AA.PaymentSchedule.setFinalPaymentDate(FINAL.PAYMENT.DATE)
    AA.PaymentSchedule.setPreviousPayDate(PREVIOUS.PAY.DATE)
    AA.PaymentSchedule.setPaymentType(PAYMENT.TYPE)
    AA.PaymentSchedule.setPaymentPropertiesList(PAYMENT.PROPERTIES.LIST)
    AA.PaymentSchedule.setPaymentPropertyAmounts(PAYMENT.PROPERTY.AMOUNTS)
    AA.PaymentSchedule.setLastAccDate(LAST.ACC.DATE)
    AA.PaymentSchedule.setPresentValue(PRESENT.VALUE)
    AA.PaymentSchedule.setDefIntDetail(DEF.INT.DETAIL)
    AA.PaymentSchedule.setFullPaymentDates(FULL.PAYMENT.DATES)
    AA.PaymentSchedule.setFullPaymentTypes(FULL.PAYMENT.TYPES)
    
    hookId = "HOOK.AA.PAYMENT.TYPE.CALC.ROUTINE" ;* Interface for the hook attached
    numberOfArguments = '6'
    arguments = ARRANGEMENT.ID:@IM:PAYMENT.PROPERTY:@IM:R.PAYMENT.SCHEDULE:@IM:PAYMENT.DATE:@IM:PAYMENT.AMOUNT:@IM:RET.ERROR
   
    ebApi<1> = CALC.ROUTINE      ;* Name of the hook attached
    ebApi<2> = 'IM'              ;* Arguments delimiter
    ebApi<4> = numberOfArguments ;* Number of arguments
    ebApi<6> = hookId
    
    EB.SystemTables.CallApi(ebApi, arguments)
    
    PAYMENT.PROPERTY.AMOUNTS =  AA.PaymentSchedule.getPaymentPropertyAmounts()
    PAYMENT.AMOUNT = FIELD(arguments, @IM, 5) ;* Reassigning the returned payment amount to the "PAYMENT.AMOUNT" variable
    RET.ERROR = FIELD(arguments, @IM, 6)
    
    EB.API.RoundAmount(ARR.CCY, PAYMENT.AMOUNT, "", "")

    IF NOT(RET.ERROR) THEN
        ACCOUNT.AMOUNT.CHECK = PAYMENT.AMOUNT ;* take the user calculated payment amount
    END


RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Update outstanding amount>
*** <desc>Update the array representing outstanding amount for a given payment date</desc>
UPDATE.OUTSTANDING.AMOUNT:

    IF OUTSTANDING.AMOUNT NE "" THEN
        OUTSTANDING.AMOUNT := @FM:PRESENT.VALUE
    END ELSE
        OUTSTANDING.AMOUNT = PRESENT.VALUE
    END

    CONVERT @VM TO '*' IN PARTICIPANT.PRESENT.VALUE
    IF  PARTICIPANT.OUTSTANDING.AMT NE '' THEN
        PARTICIPANT.OUTSTANDING.AMT := @FM:PARTICIPANT.PRESENT.VALUE
    END ELSE
        PARTICIPANT.OUTSTANDING.AMT = PARTICIPANT.PRESENT.VALUE
    END
    CONVERT '*' TO @VM IN PARTICIPANT.PRESENT.VALUE
             
RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Property dates>
*** <desc>Build property dates</desc>
BUILD.PROPERTY.DATES:

** Buiild cycled dates for each property, this is required for interest
** calculations to get the previous periods or start of the current period.
** Multiple instances of the interest property class can be defined in the Payment
** Schedule. It is imperative to pass the correct dates for each of the interest
** properties, which can be really mixed up.
** As a foresight the update is done for all properties.

    NEW.PROP = ''         ;*Flag to know if this is a new property or not
    LOCATE PAYMENT.PROPERTY IN AA.Framework.getContractDetails()<AA.Framework.CdProperty,1> SETTING PR.POS ELSE
        NEW.PROP = 1
        tmp.CONT = AA.Framework.getContractDetails()
        INS PAYMENT.PROPERTY BEFORE tmp.CONT<AA.Framework.CdProperty,PR.POS>
        AA.Framework.setContractDetails(tmp.CONT)
    END

** Don't set the PAYMENT.DATE as AA$CONTRACT.DETAILS PROPERTY.DATE for the property which has PAYMENT.MODE as "ADVANCE"
** and while process the first period itself.Since we added one more additional period as value date from the .dates
** and also we required adjustment amount (Cooling period accrual amount) to process the upfront interest collection.
** Because there was chance to arrangement creation and disbursement was done by different dates.

    IF PAYMENT.MODE EQ "ADVANCE" AND FIRST.INTEREST.PROJECTION THEN
        tmp=AA.Framework.getContractDetails(); tmp<AA.Framework.CdPropertyDate,PR.POS,-1>=PERIOD.START.DATE; AA.Framework.setContractDetails(tmp)
    END ELSE
        tmp=AA.Framework.getContractDetails(); tmp<AA.Framework.CdPropertyDate,PR.POS,-1>=PAYMENT.DATE; AA.Framework.setContractDetails(tmp)
    END

** This update is part of the performance improvement, while building up the schedules
** up to the maturity date (quite a lot of schedules), it will be a overhead to keep
** all the details in R.ACCRUAL.DATA. It is more than sufficient to have only the final
** accrual date to calculate the accrual / interest amount for the next period

*There can be NULL LAST.ACCRUAL.DATE in case both Start & End Date falls on the same date.
*Don't append then as it will overwrite previous NULL position.
*
    IF NEW.PROP THEN
        PROPERTY.ACCRUAL.DATA<PR.POS> = LAST.ACCRUAL.DATE
    END ELSE
        PROPERTY.ACCRUAL.DATA<PR.POS> = PROPERTY.ACCRUAL.DATA<PR.POS>:@VM:LAST.ACCRUAL.DATE
    END

RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Update principal Balance>
*** <desc> </desc>
UPDATE.PRINCIPAL.BALANCE:

* Update principal balance amount in AA.CONTRACT.DETAILS.

    IF PAYMENT.METHOD EQ 'CAPITALISE' OR CAP.UPDATE.PRINCIPAL.BALANCE THEN   ;*For DUE.AND.CAP payment type if there is capitalised Interest/Charge, update that into principal balance amount

        CAP.SIGN = ''
        SAVE.SIGN = SIGN
        LOCATE PAYMENT.PROPERTY IN SOURCE.BAL.TYPE.ARRAY<1,1> SETTING SOURCE.BAL.TYPE.POS THEN
            SRC.BALANCE.TYPE = SOURCE.BAL.TYPE.ARRAY<2, SOURCE.BAL.TYPE.POS>
        END ELSE
            AA.Framework.GetSourceBalanceType(PAYMENT.PROPERTY, '', '', SRC.BALANCE.TYPE, '')   ;* Get the balance type for Interest property
            SOURCE.BAL.TYPE.ARRAY<1,-1> = PAYMENT.PROPERTY
            SOURCE.BAL.TYPE.ARRAY<2,-1> = SRC.BALANCE.TYPE
        END

*** For lending, when source balance type defined as credit, sign and cap.sign should be updated as positive.
        BEGIN CASE
            CASE SRC.BALANCE.TYPE EQ "CREDIT" AND PRODUCT.LINE EQ "LENDING"
                SIGN = SIGN * -1
                CAP.SIGN = SIGN     ;*Need to add charge amount to outstanding amount if charge property belongs to CREDIT type!!
            CASE SRC.BALANCE.TYPE EQ "CREDIT"
                CAP.SIGN = SIGN   ;*Need to add charge amount to outstanding amount if charge property belongs to CREDIT type!!
            CASE SCHEDULE.INFO<8> OR AA.Framework.getRArrangement()<AA.Framework.Arrangement.ArrLeaseType>
* By default, The SIGN flag will be +ve for asset finance.
* so when the payment type is Interest-Only and the payment method is Capitalise, the outstanding amount will appear with a negative sign. When we add the interest amount (which has a positive sign), the outstanding amount will be reduced by the interest amount.
* This results in the interest amount being derived wrongly from the subsequence schedules.
* Hence, we need to change the sign here to add the interest amount into outanding amount variable.
 
                SIGN = -1 ;* For debit type of charge system should reduce from the outstanding instead of adding it.
                CAP.SIGN = SIGN

        END CASE

        AMOUNT = UPDATE.AMOUNT * SIGN

        IF CAP.SIGN THEN
            UPDATE.AMOUNT = UPDATE.AMOUNT * SIGN
        END

** Need to hold the cap amount update in PRESENT.VALUE and AA$CONTRACT.DETAILS variables
** until system completes the entire payment types on same day. Because if multiple payment types capitalize happen on same day and
** during the accrual process there is a difference between bill and interest accrual amount
        IF IS.PARTICIPANT THEN
            PART.TEMP.AMOUNT<1,PART.POS> += AMOUNT
            PART.TEMP.UPDATE.AMOUNT<1,PART.POS> += UPDATE.AMOUNT
            PART.CAP.AMOUNT<1,PART.POS> += UPDATE.AMOUNT ;*Update calculated participant cap amount
        END ELSE
            TEMP.AMOUNT += AMOUNT
            TEMP.UPDATE.AMOUNT += UPDATE.AMOUNT
        END
        SIGN = SAVE.SIGN
    END

    CAP.CHARGE.AMT = 0   ;*reassign these variables as 0 as this amount is now capitalised to principal;* So next processing scheduled property amount should not hold previous value
    CAP.INT.AMT = 0
    CAP.UPDATE.PRINCIPAL.BALANCE = 0

RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name=GET.ACCOUNT.PROPERTY.RECORD>
*** <desc>Get account property details</desc>
GET.ACCOUNT.PROPERTY.RECORD:

    PROPERTY.ID = ACCOUNT.PROPERTY
    PROPERTY.CLASS = "ACCOUNT"
    GOSUB GET.PROPERTY.RECORD
    R.ACCOUNT = R.PROPERTY.RECORD ;* Get Account property record to load balance amount
*
RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name=Get Customer Property Record>
*** <desc>Get Customer property details</desc>
GET.CUSTOMER.PROPERTY.RECORD:

    PROPERTY.ID = ""     ;* Property is not required since custoemr is single
    PROPERTY.CLASS = "CUSTOMER"
    GOSUB GET.PROPERTY.RECORD ;* Get customer property record
    R.CUSTOMER = R.PROPERTY.RECORD ;* Customer Property class record

RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Process payment for negative rate>
*** <desc>Payment method to be determine depending on interest amount</desc>
PROCESS.PAYMENT.FOR.NEG.RATE:

* If negative interest and balance type is CREDIT/BOTH , payment method should be DUE

    PROPERTY = PAYMENT.PROPERTY
    LOCATE PROPERTY IN SOURCE.BAL.TYPE.ARRAY<1,1> SETTING SOURCE.BAL.TYPE.POS THEN
        BALANCE.TYPE = SOURCE.BAL.TYPE.ARRAY<2, SOURCE.BAL.TYPE.POS>
    END ELSE
        AA.Framework.GetSourceBalanceType(PROPERTY, '', '', BALANCE.TYPE, '')   ;* Get the calculation type for Interest property
        SOURCE.BAL.TYPE.ARRAY<1,-1> = PROPERTY
        SOURCE.BAL.TYPE.ARRAY<2,-1> = BALANCE.TYPE
    END

    IF BALANCE.TYPE NE 'DEBIT' AND PAYMENT.METHOD.NEW = 'PAY' AND INT.AMOUNT < 0 THEN
        PAYMENT.METHOD.NEW = 'DUE'      ;* Set to due as the interest is to be paid by customer
        INT.AMOUNT = ABS(INT.AMOUNT)
    END

RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= Get Tax Base amount>
*** <desc> </desc>
GET.TAX.BASE.AMOUNT:

* Credit interest with negative rate - Tax should not be calculated. Here INT.AMOUNT will be -ve, take INT.AMOUNT as it is
* Credit interest with positive rate - Tax should be calculated. Here INT.AMOUNT will be +ve, take INT.AMOUNT as it is
* Debit interest with negative rate - Tax should be calculated. Here INT.AMOUNT will be -ve, take INT.AMOUNT as unsigned
* Debit interest with negative rate - Tax should be calculated. Here INT.AMOUNT will be +ve, take INT.AMOUNT as unsigned

    IF CAP.INT.AMT THEN
        CAP.TAX.BASE.AMOUNT = CAP.INT.AMT      ;*If there is capitalised interest for DUE.AND.CAP payment type then set the base tax amount for the same
    END
    IF BALANCE.TYPE EQ 'CREDIT' THEN ;* Only for credit interest property signed balance is required
        TAX.BASE.AMOUNT = INT.AMOUNT
    END ELSE ;* For other cases unsigned balance would suffice
        TAX.BASE.AMOUNT = ABS(INT.AMOUNT)
    END

RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= Adjust Payment Method>
*** <desc>Payment method to be determined depending on interest amount</desc>
ADJUST.PAYMENT.METHOD:
    AA.Framework.DeterminePayoffProcess(PAYOFF.PROCESSING.REQD, PAYOFF.CAPITALISE,PAYOFF.PAYMENT.METHOD)    ;* Check if the current process is payoff capitalise

    IF NOT(PAYOFF.CAPITALISE) THEN
        INT.AMOUNT = ABS(INT.AMOUNT) ;* Make it unsigned
    END

    BEGIN CASE
        CASE BALANCE.TYPE EQ "CREDIT" AND PAYMENT.METHOD = "PAY"
            PAYMENT.METHOD.NEW = "DUE"

        CASE BALANCE.TYPE EQ "DEBIT" AND PAYMENT.METHOD = "DUE"
            PAYMENT.METHOD.NEW = "PAY"
    END CASE

RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name = process payment for progressive type payment>
*** <desc> Payment amount should be calculated based on the PROG.PAY.PERC value</desc>
PROCESS.PROGRESSIVE.PAYMENT:

* If initial payment it takes CALC.AMOUNT directly, else it'll find the new amount using the payment percentage

    IF LAST.PAY.DATE NE PAYMENT.DATE THEN

        IF PROGRESSIVE.PAYMENT AND (SAVE.CALC.AMT AND CALC.AMOUNT EQ SAVE.CALC.AMT) THEN
            PROGRESSIVE.PAYMENT = PROGRESSIVE.PAYMENT * (1+ PROGRESS.RATE/100)
            EB.API.RoundAmount(ARR.CCY, PROGRESSIVE.PAYMENT, "", "")
        END ELSE
            PROGRESSIVE.PAYMENT = CALC.AMOUNT
            SAVE.CALC.AMT = CALC.AMOUNT
        END

        CALC.AMOUNT = PROGRESSIVE.PAYMENT
        LAST.PAY.DATE = PAYMENT.DATE

        GOSUB GET.RES.INTEREST.PROPERTY
    END

RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name = Get all interest property list for the payment type>
*** <desc> get the residual interest property</desc>
GET.RES.INTEREST.PROPERTY:

    RESIDUAL.PROCESS.REQD = ''
    LOOP
        REMOVE PAYMENT.PROPERTY.ID FROM SEQUENCED.PROPERTY.LIST SETTING PROPERTY.POS
    WHILE PAYMENT.PROPERTY.ID:PROPERTY.POS        ;* which property contain property type as a residual accrual for that property we need to find the adjustment amount
        IF PAYMENT.PROPERTY.ID THEN
            AA.Framework.LoadStaticData("F.AA.PROPERTY", PAYMENT.PROPERTY.ID, R.PROPERTY.DATA, "")
            IF 'RESIDUAL.ACCRUAL' MATCHES R.PROPERTY.DATA<AA.ProductFramework.Property.PropPropertyType> THEN
                RESIDUAL.PROCESS.REQD = 1
                PAYMENT.PROPERTY = PAYMENT.PROPERTY.ID
                GOSUB PROCESS.RESIDUAL.INTEREST   ;* find the adjustment amount
            END
        END
    REPEAT
    SEQUENCED.PROPERTY.LIST = SEQUENCED.PROPERTY.LIST       ;* Reinitialised the same (May be the same list can use for other)
RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name = process residual interest>
*** <desc> Process defined for the residual interest</desc>
PROCESS.RESIDUAL.INTEREST:

    LOCATE PAYMENT.TYPE IN PAYMENT.TYPE.ARRAY<1,1> SETTING PAY.TYPE.POS THEN
        R.PAYMENT.TYPE = RAISE(RAISE(PAYMENT.TYPE.ARRAY<2,PAY.TYPE.POS>))
    END ELSE
        AA.Framework.LoadStaticData("F.AA.PAYMENT.TYPE", PAYMENT.TYPE, R.PAYMENT.TYPE, "")
        PAYMENT.TYPE.ARRAY<1,-1> = PAYMENT.TYPE
        PAYMENT.TYPE.ARRAY<2,-1> = LOWER(LOWER(R.PAYMENT.TYPE))
    END
    GOSUB GET.LAST.PAYMENT.DATE

    IF LAST.PAYMENT.DATE THEN
        PREVIOUS.PAY.DATE = LAST.PAYMENT.DATE
    END ELSE
        PREVIOUS.PAY.DATE = R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsBaseDate>
    END

    IGNORE.INT.PROP.UPDATE = 1          ;*Don't update the field INTEREST.PROPERTIES as we don't process Interest here.
    GOSUB GET.PRESENT.INTEREST.ACCRUALS
    IGNORE.INT.PROP.UPDATE = ''         ;*Reset so that it doesn't affect norma interest processing

    LAST.ACC.DATE = LAST.ACCRUAL.DATE
    PAYMENT.AMOUNT = CALC.AMOUNT

    LOCATE PAYMENT.TYPE IN PAYMENT.TYPE.LIST<1,1> SETTING PAYTYPE.POS THEN
        PAYMENT.PROPERTIES.LIST = PAYMENT.PROPERTY.LIST<1,PAYTYPE.POS>
    END

    IF R.PAYMENT.TYPE<AA.PaymentSchedule.PaymentType.PtCalcRoutine> THEN
        GOSUB CALCULATE.USER.AMOUNT
    END
 
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name=GET.ROUND.AMT>
*** <desc>Get rounded amount</desc>
GET.ROUND.AMT:

    EB.API.RoundAmount(ARR.CCY, ROUND.AMT, '1', '')

RETURN
*** </region>
*----------------------------------------------------------------------------
*** <region name=GET.UPDATE.FIELD.NO>
*** <desc>Populate ContractDetails field positions</desc>
GET.UPDATE.FIELD.NO:

** If called when processing Borrower, populate existing field positions.(CdArrId, CdBaseBalance, CdBalEffDt, CdBalAmount)
** Else if called when processing Participant, populate newly introduced field positions (CdPartArrId, CdPartBaseBalance, CdPartBalEffDt, CdPartBalAmount)

    IF IS.PARTICIPANT THEN          ;* called when processing a Participant
        ARRANGEMENT.POS = AA.Framework.CdPartArrId
        BASE.BALANCE.POS = AA.Framework.CdPartBaseBalance
        BAL.EFF.DATE.POS = AA.Framework.CdPartBalEffDt
        BAL.AMT.POS = AA.Framework.CdPartBalAmount
    END ELSE                        ;* called when processing Borrower
        ARRANGEMENT.POS = AA.Framework.CdArrId
        BASE.BALANCE.POS = AA.Framework.CdBaseBalance
        BAL.EFF.DATE.POS = AA.Framework.CdBalEffDt
        BAL.AMT.POS = AA.Framework.CdBalAmount
    END
 
RETURN
*** </region>
*----------------------------------------------------------------------------
*** <region name=BUILD.CONTRACT.DETAILS>
*** <desc>Set updated Values in ContractDetails common</desc>
BUILD.CONTRACT.DETAILS:
 
** Set updated Values in ContractDetails common.
** each Participants details are expected to be separated by '*'
    
    CONVERT @FM TO '*' IN TEMP.ARRID
    CONVERT @FM TO '*' IN TEMP.BASE.BAL
    CONVERT @FM TO '*' IN TEMP.BAL.EFF
    CONVERT @FM TO '*' IN TEMP.BAL.AMT
    Contractdetails<ARRANGEMENT.POS> = TEMP.ARRID
    Contractdetails<BASE.BALANCE.POS> = TEMP.BASE.BAL
    Contractdetails<BAL.EFF.DATE.POS> = TEMP.BAL.EFF
    Contractdetails<BAL.AMT.POS> = TEMP.BAL.AMT
    AA.Framework.setContractDetails(Contractdetails)
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name=LOAD.CONTRACT.DETAILS>
*** <desc>Get updated Values from ContractDetails common</desc>
LOAD.CONTRACT.DETAILS:
 
** Get existing Values from ContractDetails common.
** each Participants details are expected to be separated by '*'
** For defalut it should take from arrangement related fields, for participant values should be taken from participant related fields
   
    Contractdetails = AA.Framework.getContractDetails()
    TEMP.ARRID = Contractdetails<ARRANGEMENT.POS>
    TEMP.BASE.BAL = Contractdetails<BASE.BALANCE.POS>
    TEMP.BAL.EFF = Contractdetails<BAL.EFF.DATE.POS>
    TEMP.BAL.AMT = Contractdetails<BAL.AMT.POS>
    CONVERT '*' TO @FM IN TEMP.ARRID
    CONVERT '*' TO @FM IN TEMP.BASE.BAL
    CONVERT '*' TO @FM IN TEMP.BAL.EFF
    CONVERT '*' TO @FM IN TEMP.BAL.AMT
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= GET.PARTICIPANT.ACCT.MODE >
GET.PARTICIPANT.ACCT.MODE:
*** <desc>Send Participant AcctMode to get Balance Name</desc>
*** <desc> </desc>

** For participant, BALANCE.PROPERTY<2> is populated with its Accouting Mode to get balancename with correct Suffix.

    BEGIN CASE
        CASE IS.PARTICIPANT AND PART.PARTICIPANT.TYPE<1,PART.COUNT>
            CUR.PROPERTY<2> = PART.ACCT.MODE<1,PART.COUNT>            ;* For other Participants, use value received from Dates routine
            CUR.PROPERTY<4> = 'RISK.PARTICIPANT'
        CASE IS.PARTICIPANT AND FIELD(PARTICIPANT, '-', 1) EQ 'BOOK'       ;* For Own Company, AccoutingMode will be REAL
            CUR.PROPERTY<2> = 'REAL'
            IF FIELD(PARTICIPANT, '-', 2) THEN
                CUR.PROPERTY<6> = FIELD(PARTICIPANT, '-', 2)
            END
        CASE IS.PARTICIPANT
            CUR.PROPERTY<2> = PART.ACCT.MODE<1,PART.COUNT>            ;* For other Participants, use value received from Dates routine
    END CASE

RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= UPDATE.PARTICIPANT.DATA>
UPDATE.PARTICIPANT.DATA:
*** <desc>Calculate Pro-rata amount for Participant</desc>
*** <desc> </desc>

** Calculate Pro-Rata amount using the calculated Participant Payment Amount, Borrower Payment Amount and Amount from previous date.

    PRO.RATA.AMOUNT = 0
    PartValue = 0
    BorrowerValue = 0
    PrevValue = 0
    CALCULATE.PRO.AMOUNT = 0

** When skim properties are defined, the corresponding borrower amounts are taken by locating the skim property in Borrower Property list.
** This is because, skim property which was in the format "PropertyName-SKIM" is converted with only PropertName with SkimFlag set.
** For example, Borrower properties will be of the format LOANACCOUNT\LOANINT with amounts 1000\50 and for participant LOANACCOUNT\LOANINT\LOANINT-SKIM
** Thus, for skim property LOANINT of participant, the corresponding amount for borrower is 50.
    BEGIN CASE
        CASE SKIM.FLAG
            LOC.BORROWER.PAYMENT.PROPERTIES = BORROWER.PAYMENT.PROPERTIES<1,PAY.TYPE.I>
            LOCATE PAYMENT.PROPERTY IN LOC.BORROWER.PAYMENT.PROPERTIES<1,1,1> SETTING SKIM.PROPERTY.I THEN
                BORROWER.PROP.AMT = BORROWER.PAYMENT.AMOUNT.LIST<1,PAY.TYPE.I,SKIM.PROPERTY.I>
            END
        
        CASE 1
            IF SUM(BORROWER.PAYMENT.AMOUNT.LIST) THEN     ;* If local routine returns the charge/Interest/Principal value then it should take the same
                LOCATE PAYMENT.PROPERTY IN LOC.BORROWER.PAYMENT.PROPERTIES<1,1,1> SETTING LOAN.PROPERTY THEN
                    BORROWER.PROP.AMT = BORROWER.PAYMENT.AMOUNT.LIST<1,PAY.TYPE.I,LOAN.PROPERTY>
                END ELSE
                    BORROWER.PROP.AMT = BORROWER.PAYMENT.AMOUNT.LIST<1,PAY.TYPE.I,PROPERTY.I>                      ;* get Borrower Property amount
                END
            END
    END CASE
    
***Handle term.amount schedule definition for facility, similar to account schedule
    BEGIN CASE
        CASE (PAYMENT.PROPERTY.CLASS EQ "ACCOUNT" OR (FAC.TERM.PROPERTY AND PAYMENT.PROPERTY.CLASS EQ "TERM.AMOUNT")) AND PAY.BILL.TYPE NE 'DISBURSEMENT'           ;* For ACCOUNT property, calculate amount using Outstanding amount of both Borrower and Participant
            PartValue = PREV.PART.PRESENT.VALUE<1,PART.POS>                                    ;* for auto-disbursement, participant amount is calculated already using Disbursement amount defined for borrower
            BorrowerValue = BORROWER.PROP.AMT
            PrevValue = PREV.PRESENT.VALUE
            CALCULATE.PRO.AMOUNT = 1
            IF FAC.TERM.PROPERTY AND PAYMENT.PROPERTY.CLASS EQ "TERM.AMOUNT" THEN ;* During FLR, as part of non prorate changes, the formula is changed to consider both CUR and UTL balance (If we dont have enough CUR) instead of TOT balance
                PrevValue = SAVE.CUR.TERM.AMT<1>
                PartValue = SAVE.CUR.TERM.AMT<PART.COUNT>
                PART.UTL.TERM.AMT = SAVE.UTL.TERM.AMT<PART.COUNT>
** If the Payment Amount is more than the available CUR, then calculate the UTL portion that is going to be effected since the UTL portion will be reduced and OVD will be raised
** Calculate the borrower CUR balance after the reduction. This will be used to calculate the participant CUR term amount balance
                IF BorrowerValue GT PrevValue THEN
                    BorrowerValue =  0
                END ELSE
                    BorrowerValue =  PrevValue - BorrowerValue
                END
            
            END
            IF FULL.SHARE.TRANSFER THEN
                IF NOT(PART.ID<1,PART.COUNT> MATCHES 'BORROWER':@VM:'BOOK')THEN        ;* For full transfer raise the bill entirely for investor since there may be capitalised amount in bank book which leads to book bill entry.
                    PartValue  = SUM(PREV.PART.PRESENT.VALUE<1>)
                    BOOK.VALUE = '1'
                END ELSE
                    IF BOOK.VALUE THEN
                        PartValue = 0
                    END
                END
            END
    
        CASE PAYMENT.PROPERTY.CLASS EQ "INTEREST" AND NOT(NON.CUSTOMER.PROPERTY)       ;* For INTEREST property, use calculated amount from CalcInterest for both Borrower and Participant
            PartValue = PAYMENT.PROPERTY.AMOUNT
            BorrowerValue = BORROWER.PROP.AMT
            IF SKIM.FLAG THEN ;* If payment property is skim, then take the borrower value from the skim property index which is already defined
                PrevValue = BORROWER.CALC.AMT<1, PAY.TYPE.I, SKIM.PROPERTY.I>
            END ELSE
                PrevValue = BORROWER.CALC.AMT<1, PAY.TYPE.I, PROPERTY.I>
            END
            CALCULATE.PRO.AMOUNT = 1
        
        CASE PAYMENT.PROPERTY.CLASS EQ "CHARGE"             ;* For CHARGE property, use TOT.Commitment amount of both Borrower and Participant
            BorrowerValue = BORROWER.PROP.AMT
            ArrangementDetails = ARRANGEMENT.ID
            ArrangementDetails<2> = ARR.CCY
            ArrangementDetails<5> = ACCOUNT.ID
            ArrangementDetails<6> = GlCustomer
            BalanceCheckDate = EFFECTIVE.DATE
            
            
            IF NON.CUSTOMER.PROPERTY THEN
                IF PART.PARTICIPANT.TYPE<1,PART.COUNT> THEN
                    ArrangementDetails<3> = 'RISK.PARTICIPANT'
                END
                IF FIELD(PART.ID<1,PART.COUNT>, '-', 1) EQ 'BOOK' THEN
                    ArrangementDetails<4> = 'NON.CUSTOMER'      ;* Non Customer Book bill to be raised for actual borrower charge amt
                END
            END
            
*use GET.PARTICIPANT.CHARGE.AMOUNT to calculate charge amount based on the Participant Charge defined.
            AA.PaymentSchedule.GetParticipantChargeAmount(ArrangementDetails,BalanceCheckDate,PART.ID<1,PART.COUNT>, PAYMENT.PROPERTY, BorrowerValue, PRO.RATA.AMOUNT,R.PARTICIPANT, FWD.ACC.FLAG, ReturnError)
* For Risk Fee property, we no charge amount defined in Participant condition, raise bill for the actual charge amt
            IF PRO.RATA.AMOUNT EQ '' AND RISK.MARGIN.PROPERTY THEN
                AA.Fees.CalcCharge(ARRANGEMENT.ID, CHARGE.SCHEDULE.DATE, PAYMENT.PROPERTY, "", R.CHARGE.RECORD, ARR.CCY, CALC.REQUEST.TYPE, ARR.BASE.AMOUNT, START.DATE, END.DATE, "", SOURCE.BALANCE, PRO.RATA.AMOUNT, CHARGE.AMOUNT.LCY, PER.CHARGE.CALC.INFO, "", RET.ERROR)
            END
            PAYMENT.PROPERTY.AMOUNT = PRO.RATA.AMOUNT
    END CASE

    IF CALCULATE.PRO.AMOUNT THEN
        AA.PaymentSchedule.CalculateProRataAmount(PartValue, BorrowerValue, PrevValue, PRO.RATA.AMOUNT, ARR.CCY, '', '', '')        ;*Calculate ProRata amount for participant
        PAYMENT.PROPERTY.AMOUNT = PRO.RATA.AMOUNT
** Calculate the CUR and UTL portion seperately so that the OVD can be raised appropriately if we dont have enough CUR term amount
        IF FAC.TERM.PROPERTY AND PAYMENT.PROPERTY.CLASS EQ "TERM.AMOUNT" THEN
            
** PFB an example to under stand the formula better
** Balances before reduction
**              ________________________________
**             |    CUR |   UTL     |   TOT     |
**             |================================|
**Borrower     |    0   |   40,000  |   60,000  |
**             |================================|
**Book         |    0   |   15,000  |   35,000  |
**             |================================|
**Participant  |    0   |   25,000  |   25,000  |
**             |================================|

*The Payment amount is 50,000 for the borrower. Here only 20,000 is available (TOT - UTL). So 30,000 will be raised as OVD and that 30,000 will be reduced from UTL

*Borrower balance after reduction (Movement amount is 50,000)
**              _____________________________________________
**             |    CUR |   UTL     |   TOT     |   OVD     |
**             |================================|===========|
**Borrower     |    0   |   10,000  |   10,000  |   30,000  |
**             |================================|===========|

* To calculate the movement amounts for participants, we calculate the CUR and UTL balance for the participant.
* NewCurBal of Paricipant = OldCur of Participant/OldCur of Borrower * NewCur of Borrower. Same for UTL balance
* New Participant Tot = NewCurBal + NewUtlBal. Movement amount = Current Participant TOT -  New Participant TOT
* Below example calculation for Book
* NewCurBal = 0/0*0 = 0
* NewUtlBal = 15,000/40,000 * 10,000 = 3,750
* NewTotBal = 0 + 3,750 = 3,750
* MovementAmt = 35,000 - 3,750 = 31,250

            UTL.PRO.RATA.AMOUNT = ""
            AA.PaymentSchedule.CalculateProRataAmount(PART.UTL.TERM.AMT,BORR.UTL.CHANGE.AMOUNT, SAVE.UTL.TERM.AMT<1>, UTL.PRO.RATA.AMOUNT, ARR.CCY, '', '', '')        ;*Calculate ProRata amount for participant
            PAYMENT.PROPERTY.AMOUNT += ABS(UTL.PRO.RATA.AMOUNT)
            PAYMENT.PROPERTY.AMOUNT = ABS(SAVE.TOT.TERM.AMT<PART.COUNT>) - PAYMENT.PROPERTY.AMOUNT
        END
        IF NOT(PAYMENT.PROPERTY.AMOUNT) AND PART.CAP.AMOUNT<1,PART.POS> AND PAYMENT.PROPERTY.CLASS EQ "ACCOUNT" AND BorrowerValue THEN
            PAYMENT.PROPERTY.AMOUNT = PART.CAP.AMOUNT<1,PART.POS>
        END
    END
 
* Calculate BOOK-BANK property amount by checking minimum of present value of BOOK-BANK with BOOK property amount and take that as bill amount.
    IF BORROWER.EXTENSION.NAME EQ 'BANK' AND FIELD(PART.ID<1,PART.COUNT>, '-', 1) EQ 'BOOK' THEN
        GOSUB CALCULATE.BOOK.BANK.AMOUNT        ;* Calculate BOOK-BANK bill amount
    END
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name=UPDATE.PARTICIPANT.TAX.DETAILS>
UPDATE.PARTICIPANT.TAX.DETAILS:
*** <desc>Update Tax details for Participant</desc>

** Only borrower and own book will have participant related information.
** None of other participants will hold TAX related information
     
* When processing for BANK SubType, Tax details should be sent only for BOOK-BANK.
    IF PROCESS.PARTICIPANTS AND BORROWER.EXTENSION.NAME EQ 'BANK' THEN
        IF PART.SUB.TYPE EQ 'BANK' THEN
            TAX.DETAILS.LIST<1, PAY.TYPE.I, PROPERTY.I>  =  BORROWER.TAX.DETAILS.LIST<1, PAY.TYPE.I, PROPERTY.I>
        END
    END ELSE
                
        BEGIN CASE
            CASE R.PARTICIPANT<AA.Participant.Participant.PrtBankRole> EQ "PARTICIPANT"  ;* When Bank Role is Participant
                PfTaxAmount = ''
                GOSUB GET.TOT.BALANCES
                PartValue = PART.TOT.TERM.AMT    ;* Fetch Tot Amount of Participant
                PART.TAX.DETAILS.LIST = RAISE(BORROWER.TAX.DETAILS.LIST<1, PAY.TYPE.I, PROPERTY.I>)
                BorrowerValue = PART.TAX.DETAILS.LIST<1,1,3> ;* Get Borrower Tax Amount for each Property
                PrevValue = BORROWER.TOT.TERM.AMT    ;* Fetch Borrower Tot Amount
                AA.PaymentSchedule.CalculateProRataAmount(PartValue, BorrowerValue, PrevValue, PfTaxAmount, ARR.CCY, '', '', '')
                PART.TAX.DETAILS.LIST<1,1,3> = PfTaxAmount
                IF PART.ID<1,PART.COUNT> EQ "BOOK" OR (FIELD(PART.ID<1,PART.COUNT>,  '-', 1) EQ "BOOK" AND FIELD(PART.ID<1,PART.COUNT>,  '-', 2) EQ SKIM.PORTFOLIO) THEN ;* When Part Id is Book, Update Tax Details List
                    IF (FIELD(PART.ID<1,PART.COUNT>,  '-', 1) EQ "BOOK" AND FIELD(PART.ID<1,PART.COUNT>,  '-', 2) EQ SKIM.PORTFOLIO) AND SKIM.PORTFOLIO THEN
                        PRIMARY.PORT.POS = PART.COUNT-1 ;*Exclude the borrower pos
                    END
                    IF SUB.PART.TAX.DETAILS.LIST THEN
                        TEMP.SUB.PART.TAX.DETAILS.LIST = RAISE(SUB.PART.TAX.DETAILS.LIST<1, PAY.TYPE.I, PROPERTY.I>)
                        TEMP.SUB.PART.TAX.DETAILS.LIST<1, 1, 3> += PfTaxAmount
                        TAX.DETAILS.LIST<1, PAY.TYPE.I, PROPERTY.I> = LOWER(TEMP.SUB.PART.TAX.DETAILS.LIST)
                        TEMP.SUB.PART.TAX.DETAILS.LIST = ""
                    END ELSE
                        TAX.DETAILS.LIST<1, PAY.TYPE.I, PROPERTY.I>  =  LOWER(PART.TAX.DETAILS.LIST)
                    END
                END ELSE
                    IF SUB.PART.TAX.DETAILS.LIST<1, PAY.TYPE.I, PROPERTY.I> THEN   ;* When Part Id is Sub Participant, Update Sub Part Tax Details List and add later to Tax Details List when Part Id is Book
                        TEMP.SUB.PART.TAX.DETAILS.LIST = RAISE(SUB.PART.TAX.DETAILS.LIST<1, PAY.TYPE.I, PROPERTY.I>)
                        TEMP.SUB.PART.TAX.DETAILS.LIST<1, 1, 3> += PfTaxAmount
                        SUB.PART.TAX.DETAILS.LIST<1, PAY.TYPE.I, PROPERTY.I> = LOWER(TEMP.SUB.PART.TAX.DETAILS.LIST)
                        GOSUB UPDATE.PRIMARY.PORTFOLIO.TAX.DETAILS
                        TEMP.SUB.PART.TAX.DETAILS.LIST = ""
                    END ELSE
                        SUB.PART.TAX.DETAILS.LIST<1, PAY.TYPE.I, PROPERTY.I>  =  LOWER(PART.TAX.DETAILS.LIST)
                        GOSUB UPDATE.PRIMARY.PORTFOLIO.TAX.DETAILS
                    END
                END
            CASE PART.ID<1,PART.COUNT> EQ 'BOOK' OR (FIELD(PART.ID<1,PART.COUNT>,  '-', 1) EQ "BOOK" AND FIELD(PART.ID<1,PART.COUNT>,  '-', 2) EQ SKIM.PORTFOLIO)
                TAX.DETAILS.LIST<1, PAY.TYPE.I, PROPERTY.I>  =  BORROWER.TAX.DETAILS.LIST<1, PAY.TYPE.I, PROPERTY.I>
        
            CASE 1
                TAX.DETAILS.LIST<1, PAY.TYPE.I, PROPERTY.I>  =  ""
        
        END CASE
    END

RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name=CALCULATE.PARTICIPANT.NEXT.OUTSTANDING.AMT>
CALCULATE.PARTICIPANT.NEXT.OUTSTANDING.AMT:
*** <desc>Calculate Next Outstanding amount for Participant</desc>

    PartValue = 0
    BorrowerValue = 0
    PrevValue = 0
    PRO.RATA.AMOUNT = 0
    OutAmountSign = 1
    IF FIELD(PART.ID<1,PART.COUNT>, '-', 1) EQ 'BOOK' THEN
        OutAmountSign = -1          ;*To update Outstanding amount for BOOK in contract details
    END
*** Calculate ProRata for Participant Outstanding amount current
***processing PaymentDate using the already saved initial Outstanding amounts for Borrower and all participants.
    IF IS.PARTICIPANT THEN
        PrevValue = SAVE.BORROWER.OUT.AMT       ;* Borrower Outstanding amount
        BorrowerValue = PRESENT.VALUE      ;* Present Value of Borrower from current date processing
        PartValue = SAVE.PART.OUT.AMT<1,PART.POS>   ;* Participant Outstanding amt
        
***When account & charge capitalisation schedule is defined, if outstading balances are made as 0 (through write.off/adjust activities). At that time during account schedule processing charge cap amount is being set as account property payment amount for borrower.
*** If its club loans do prorata processing for each participants based on borrower prop amount
        IF PAYMENT.METHOD EQ "CAPITALISE" AND PREV.CHARGE.AMOUNT AND PART.TEMP.UPDATE.AMOUNT<1,PRT.CNT> THEN
            PrevValue = BORROWER.TOT.TERM.AMT
            BorrowerValue = PREV.CHARGE.AMOUNT
            PartValue = PART.TOT.TERM.AMT
        END
    
        AA.PaymentSchedule.CalculateProRataAmount(PartValue, BorrowerValue, PrevValue, PRO.RATA.AMOUNT, ARR.CCY, '', '', '')        ;*Calculate ProRata amount for participant
        AMOUNT = PRO.RATA.AMOUNT * OutAmountSign
    END
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name=CALCULATE.PARTICIPANT.NEXT.OUTSTANDING.AMT>
*** <desc>flag is set to return due and cap details;*para to add the stored details to the output arguments</desc>

** Once all the payment dates have been processe and if DUE.AND CAP payment types are present then return the capitalised Interest/Charge details in addition to the otther details

ADD.PART.CAP.DETAILS:
                                              
    TOT.DATE.CNT = DCOUNT(CAP.PAYMENT.DATES, @FM)
    
    FOR DATE.CNT = 1 TO TOT.DATE.CNT
        LOCATE CAP.PAYMENT.DATES<DATE.CNT> IN PAYMENT.DATES<1> SETTING FOUND.POS THEN
            TOT.CAP.PT = DCOUNT(CAP.PAYMENT.TYPE.LIST, @VM)
            FOR CAP.PT.CNT = 1 TO TOT.CAP.PT
                
                IF SUM(CAP.PAYMENT.AMOUNT.LIST<DATE.CNT, CAP.PT.CNT>) THEN
                 
                    PAYMENT.TYPES<FOUND.POS> = PAYMENT.TYPES<FOUND.POS>:@VM:CAP.PAYMENT.TYPE.LIST<DATE.CNT, CAP.PT.CNT>      ;*Returrning both Due payment type and cap payment type in case of DUE.AND.CAP payment type setup
                    PAYMENT.METHODS<FOUND.POS> = PAYMENT.METHODS<FOUND.POS>:@VM:CAP.PAYMENT.METHOD.LIST<DATE.CNT, CAP.PT.CNT>  ;*Returrning both Due payment method and cap payment method in case of DUE.AND.CAP payment type setup
                    PAYMENT.PROPERTIES<FOUND.POS> = PAYMENT.PROPERTIES<FOUND.POS>:@VM:CAP.PAYMENT.PROPERTY.LIST<DATE.CNT, CAP.PT.CNT>  ;*Returrning both Due payment property and cap payment property in case of DUE.AND.CAP payment type setup
                    PAYMENT.PROPERTIES.AMT<FOUND.POS> = PAYMENT.PROPERTIES.AMT<FOUND.POS>:@VM:CAP.PAYMENT.AMOUNT.LIST<DATE.CNT, CAP.PT.CNT>  ;*Returrning both Due payment type and cap payment type in case of DUE.AND.CAP payment type setup
                    TOT.CAP.AMT = SUM(CAP.PAYMENT.AMOUNT.LIST<DATE.CNT, CAP.PT.CNT>)
                    PAYMENT.AMOUNTS<FOUND.POS> = PAYMENT.AMOUNTS<FOUND.POS>:@VM:TOT.CAP.AMT                                       ;*Returrning both Due payment amount and cap payment amount in case of DUE.AND.CAP payment type setup
                    PAYMENT.BILL.TYPES<FOUND.POS> = PAYMENT.BILL.TYPES<FOUND.POS>:@VM:CAP.BILL.PAY.TYPE.LIST<DATE.CNT, CAP.PT.CNT> ;*Returrning both Due bill type and cap bill type in case of DUE.AND.CAP payment type setup
                    TAX.DETAILS<FOUND.POS> = TAX.DETAILS<FOUND.POS>:@VM:CAP.TAX.DETAILS.LIST<DATE.CNT, CAP.PT.CNT>                ;*Returrning both Due tax details and cap tax details in case of DUE.AND.CAP payment type setup
                    
                END
            
            NEXT CAP.PT.CNT
        END
    NEXT DATE.CNT
        
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= CHECK.ISSUE.BILL.DATE>
*** <desc>Check whether issue bill is present for the first payment date </desc>
CHECK.ISSUE.BILL.DATE:
 
** when issue bill is found,system considers that payment date as last payment date and would have cycled the payment dates
** So we need to set the payment amount for issued payment date in the returned PAYMENT.PROPERTIES.AMT array at its corresponding position else leads to the mismatch in positions
    IF BILL.REFERENCES AND NOT(ISSUE.BILL.DATE) AND (PAYMENT.DATES<1> EQ PAYMENT.DATE) AND PAY.DATE.I EQ 1 THEN
        ISSUE.BILL.DATE = 1
    END

** For schedule projection when bill is in Issued status for Constant payment type set the below flag to consider the
** Holiday amount for the schedule date to be reduced in Outstanding amount properly.
    IF SCHEDULE.INFO<8> AND CALC.TYPE EQ "CONSTANT" AND BILL.REFERENCES AND NOT(REDUCE.HOLAMT) THEN
        LOCATE PAYMENT.DATE IN PAYMENT.DATES<1> SETTING ISSUEDATE.POS THEN
            REDUCE.HOLAMT = 1
        END
    END
        
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= GET.BALANCE.AMT>
*** <desc> Assign the balance amount as Term amount </desc>
GET.BALANCE.AMT:
    PROPERTY.ID = TERM.AMT.PROPERTY
    PROPERTY.CLASS = "TERM.AMOUNT"
    GOSUB GET.PROPERTY.RECORD
    R.TERM.AMOUNT = R.PROPERTY.RECORD ;* Get term amount property record to load balance amount
    BALANCE.AMOUNT = R.TERM.AMOUNT<AA.TermAmount.TermAmount.AmtAmount> * SIGN
    TEMP.BAL.EFF<PART.POS,BAL.POS> = EFFECTIVE.DATE
    TEMP.BAL.AMT<PART.POS,BAL.POS> = BALANCE.AMOUNT
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= CHECK.EXTENSION.NAME>
CHECK.EXTENSION.NAME:
*** <desc>Check Extension name for each participants and borrower</desc>
*** <desc> </desc>

    BEGIN CASE
                    
        CASE NOT(IS.PARTICIPANT)          ;* When processing for BANK type, Borrower EXTENSION.NAME should be NULL
            EXTENSION.NAME = ''
            
        CASE IS.PARTICIPANT AND NOT(PART.SUB.TYPE)    ;* When processing for BANK type, participant's EXTENSION.NAME should be NULL
            EXTENSION.NAME = ''
        
        CASE IS.PARTICIPANT AND PART.SUB.TYPE EQ 'BANK'  ;* When processing for BANK type, own book's EXTENSION.NAME
            EXTENSION.NAME = 'BANK'      ;* should be processed for BANK type and NULL type once
            
    END CASE
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= CALCULATE.BOOK.CUST.AMOUNT>
CALCULATE.BOOK.BANK.AMOUNT:
*** <desc>Calculate BOOK-BANK amount during Chargeoff</desc>
*** <desc> </desc>

* Store BOOK-CUST property amounts and BOOK-BANK interest property amount to calculate BOOK-BANK Account property amount.
    BEGIN CASE
        CASE PAYMENT.PROPERTY.CLASS EQ "INTEREST" AND NOT(PART.SUB.TYPE)        ;* Save BOOK-CUST Interest property amount
            BOOK.CUST.INT.AMOUNT = PAYMENT.PROPERTY.AMOUNT
                
        CASE PAYMENT.PROPERTY.CLASS EQ "ACCOUNT" AND NOT(PART.SUB.TYPE)         ;* Save BOOK-CUST Account property amount
            BOOK.CUST.ACC.AMOUNT = PAYMENT.PROPERTY.AMOUNT
                
        CASE PAYMENT.PROPERTY.CLASS EQ "INTEREST" AND PART.SUB.TYPE EQ 'BANK'   ;* Save BOOK-BANK Interest property amount
            BOOK.BANK.INT.AMOUNT = PAYMENT.PROPERTY.AMOUNT
 
* For the BOOK-BANK processing, pro-rated calculation should not be applied. instead we should check minimum of present value
* of BOOK-BANK with BOOK property amount and take that as bill amount
        CASE PAYMENT.PROPERTY.CLASS EQ "ACCOUNT" AND PART.SUB.TYPE EQ 'BANK'        ;* Calculate BOOK-BANK Account property amount.

            IF CALC.TYPE MATCHES "CONSTANT":@VM:"PROGRESSIVE":@VM:"ACCELERATED":@VM:"PERCENTAGE":@VM:"FIXED EQUAL" THEN
                TEMP.BANK.AMOUNT = BOOK.CUST.ACC.AMOUNT + BOOK.CUST.INT.AMOUNT - BOOK.BANK.INT.AMOUNT
            END ELSE
                IF IS.PORTFOLIO THEN
                    TEMP.BANK.AMOUNT = PAYMENT.PROPERTY.AMOUNT
                END ELSE
                    TEMP.BANK.AMOUNT = BOOK.CUST.ACC.AMOUNT
                END
            END
        
* BOOK-BANK amount can be calculated until when there is available balance. So populate minimum of Cust balances and calculated present outstanding amount
            IF PREV.PART.PRESENT.VALUE<1,PART.POS> LT TEMP.BANK.AMOUNT THEN
                PAYMENT.PROPERTY.AMOUNT = PREV.PART.PRESENT.VALUE<1,PART.POS>
            END ELSE
                PAYMENT.PROPERTY.AMOUNT = TEMP.BANK.AMOUNT
            END
    END CASE
     
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= Populate BOOK properties list>
*** <desc>Update capitalised amount in present value and contract details</desc>
POPULATE.PROPERTIES.LIST:

* When Processing for BANK subtype for an arrangement with participants, BOOK need to be processed twice - CUST and BANK types.
* BOOK-BANK property amounts will be calculated based on BOOK-CUST amounts. ProjectPaymentScheduleDates will return BOOK properties list once in PART.PAYMENT.PROPERTIES list.
* Since BOOK need to be processed twice, store BOOK properties list locally when processing CUST type and reuse the same list for BOOK-BANK processing.
    IF IS.PORTFOLIO THEN
        PART.SUB.TYPE = FIELD(PART.ID<1,PART.COUNT>,'-',3)
    END ELSE
        PART.SUB.TYPE = FIELD(PART.ID<1,PART.COUNT>,'-',2)      ;* Populate Participant SubType.for Borrower Participants and BOOK-CUST SubType will be NULL
    END
        
    BEGIN CASE
        CASE PART.ID<1,PART.COUNT> EQ 'BOOK' OR (IS.PORTFOLIO AND PART.SUB.TYPE EQ '')          ;* When processing BOOK for CUST SubType, store BOOK properties list
            BOOK.CUST.POS<1,-1> = PART.COUNT-1
            BOOK.CUST.PAYMENT.PROPERTY.LIST = PAYMENT.PROPERTY.LIST
            BOOK.CUST.PROPERTY.LIST = SEQUENCED.PROPERTY.LIST
            BOOK.CUST.PROPERTY.POS = SEQUENCED.PROPERTY.POS
            
        CASE PART.ID<1,PART.COUNT> EQ 'BOOK-BANK' OR (IS.PORTFOLIO AND PART.SUB.TYPE EQ 'BANK')           ;* When processing BOOK-BANK, restore BOOK properties list
            BOOK.BANK.POS<1,-1> = PART.COUNT-1
            IF IS.PORTFOLIO THEN
                PART.ID<1,PART.COUNT> = 'BOOK-':FIELD(PART.ID<1,PART.COUNT>, '-',2)
            END ELSE
                PART.ID<1,PART.COUNT> = 'BOOK'
            END
            SEQUENCED.PROPERTY.LIST = BOOK.CUST.PROPERTY.LIST
            SEQUENCED.PROPERTY.POS = BOOK.CUST.PROPERTY.POS
            PAYMENT.PROPERTY.LIST = BOOK.CUST.PAYMENT.PROPERTY.LIST
            BOOK.BANK.PROCESSING = 1
    END CASE
            
    IF NOT(BOOK.BANK.PROCESSING) THEN
        BOOK.CUST.INT.AMOUNT = ''
        BOOK.CUST.ACC.AMOUNT = ''
        BOOK.BANK.INT.AMOUNT = ''
        TEMP.BANK.AMOUNT = ''
    END
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= Save Borrower and participant CUST amount>
*** <desc>Store Borrower and Participant share amuont when called for BANK type</desc>
STORE.BORROWER.BANK.AMOUNT:
        
* Save Borrower and Participants and BOOK-CUST outstanding amount and Property amounts list before defining Out params and
* reset back to use those values for next schedule
  
    SAVE.PRESENT.VALUE = PRESENT.VALUE      ;* store Borrower present value
    SAVE.PARTICIPANT.PRESENT.VALUE = PARTICIPANT.PRESENT.VALUE      ;* store participants present value list
    SAVE.BORROWER.PAYMENT.AMOUNT.LIST = BORROWER.PAYMENT.AMOUNT.LIST
    SAVE.TEMP.PARTICIPANT.PROPERTIES.AMT = TEMP.PARTICIPANT.PROPERTIES.AMT
    SAVE.BORROWER.TAX.DETAILS.LIST = BORROWER.TAX.DETAILS.LIST
        
    PAYMENT.AMT.LIST = BORROWER.PAYMENT.AMOUNT.LIST
    UPDATE.BORROWER.TAX = 1
    GOSUB DEFINE.CUST.CHARGEOFF.AMT             ;*Define property amount for borrower and BOOK-CUST for BANK type
    BORROWER.PAYMENT.AMOUNT.LIST = PAYMENT.AMT.LIST
        
    CONVERT '*' TO @FM IN TEMP.PARTICIPANTS.DETAILS
    CONVERT '*' TO @FM IN TEMP.PARTICIPANT.PROPERTIES.AMT
    CONVERT '*' TO @FM IN TEMP.PARTICIPANT.TAX.DETAILS
    CONVERT '*' TO @FM IN TEMP.PARTICIPANT.PROPERTIES.LIST
    
    PARTICIPANT.CNT = DCOUNT(TEMP.PARTICIPANTS.DETAILS,@FM)
    UPDATE.BORROWER.TAX = 0
    FOR PART.CNT = 1 TO PARTICIPANT.CNT
        IF NOT(PART.CNT MATCHES BOOK.BANK.POS) THEN      ;* skip restting property amount for BOOK-BANK
            PAYMENT.AMT.LIST = TEMP.PARTICIPANT.PROPERTIES.AMT<PART.CNT>
            GOSUB DEFINE.CUST.CHARGEOFF.AMT             ;*Define property amount for borrower and BOOK-CUST for BANK type
            TEMP.PARTICIPANT.PROPERTIES.AMT<PART.CNT> = PAYMENT.AMT.LIST
            PARTICIPANT.PRESENT.VALUE<1,PART.CNT> = 0       ;* Participants outstanding amounts will not be populated when processing for BANK subtype
        END
    NEXT PART.CNT
 
* We maintain CUST properties,property amount and outstanding amount for processing BOOK-BANK details.
* Once BOOK-BANK details are updated in out args, BOOK CUST details are deleted from out args.
* Final List will contain Participant CUST details and BOOK-BANK details.
    CUST.DEL.CNT = 0
    FOR BOOK.CUST.POS.CNT = 1 TO DCOUNT(BOOK.CUST.POS, @VM)
        CUR.BOOK.CUST.POS = BOOK.CUST.POS<1,BOOK.CUST.POS.CNT> - CUST.DEL.CNT
        DEL TEMP.PARTICIPANTS.DETAILS<CUR.BOOK.CUST.POS>            ;* Delete BOOK-CUST details when processing for BANK type
        DEL TEMP.PARTICIPANT.PROPERTIES.AMT<CUR.BOOK.CUST.POS>
        DEL TEMP.PARTICIPANT.TAX.DETAILS<CUR.BOOK.CUST.POS>
        DEL TEMP.PARTICIPANT.PROPERTIES.LIST<CUR.BOOK.CUST.POS>
        DEL PARTICIPANT.PRESENT.VALUE<1,CUR.BOOK.CUST.POS>
        CUST.DEL.CNT += 1
    NEXT BOOK.CUST.POS.CNT
            
    GOSUB CHECK.PORTFOLIO.CHARGEOFF.DETAILS
            
    CONVERT @FM TO '*' IN TEMP.PARTICIPANTS.DETAILS
    CONVERT @FM TO '*' IN TEMP.PARTICIPANT.PROPERTIES.AMT
    CONVERT @FM TO '*' IN TEMP.PARTICIPANT.TAX.DETAILS
    CONVERT @FM TO '*' IN TEMP.PARTICIPANT.PROPERTIES.LIST
    PRESENT.VALUE = 0               ;* Borrower outstanding amounts will not be populated when processing for BANK subtype
      
RETURN
*** </region>
*-----------------------------------------------------------------------------
CHECK.PORTFOLIO.CHARGEOFF.DETAILS:
    
    PARTICIPANT.CNT = DCOUNT(TEMP.PARTICIPANTS.DETAILS,@FM)
    FOR PART.CNT = 1 TO PARTICIPANT.CNT
        CUR.BNK.PART.ID = TEMP.PARTICIPANTS.DETAILS<PART.CNT>
        IF FIELD(CUR.BNK.PART.ID, '-',1) EQ 'BOOK' AND FIELD(CUR.BNK.PART.ID, '-', 2) THEN      ;* check portfolio specific chargeoff details
            ARRANGEMENT.ID<4> = FIELD(CUR.BNK.PART.ID, '-', 2)
            GOSUB GET.CHARGEOFF.DETAILS
            IF NOT(CHARGEOFF.DATE) THEN
                PAYMENT.AMT.LIST = TEMP.PARTICIPANT.PROPERTIES.AMT<PART.CNT>
                GOSUB DEFINE.CUST.CHARGEOFF.AMT             ;*Define property amount for borrower and BOOK-CUST for BANK type
                TEMP.PARTICIPANT.PROPERTIES.AMT<PART.CNT> = PAYMENT.AMT.LIST
                PARTICIPANT.PRESENT.VALUE<1,PART.CNT> = 0       ;* Participants outstanding amounts will not be populated when processing for BANK subtype
            END
        END
    NEXT PART.CNT
        
RETURN
*** </region>
*-----------------------------------------------------------------------------
GET.CHARGEOFF.DETAILS:
    
    AA.ChargeOff.GetChargeoffDetails(ARRANGEMENT.ID, "", CHARGEOFF.DATE, "", FULL.CHARGEOFF.STATUS) ;* check chargeoff flag for phase2 processing

RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= Populate Borrower and participant CUST amount>
*** <desc>Reset Borrower and Participant share amuont when called for BANK type</desc>
RESET.BORROWER.BANK.AMOUNT:
    
    PRESENT.VALUE = SAVE.PRESENT.VALUE          ;* restore borrower present value
    PARTICIPANT.PRESENT.VALUE = SAVE.PARTICIPANT.PRESENT.VALUE      ;* restore participants present value list
    BORROWER.PAYMENT.AMOUNT.LIST = SAVE.BORROWER.PAYMENT.AMOUNT.LIST
    TEMP.PARTICIPANT.PROPERTIES.AMT = SAVE.TEMP.PARTICIPANT.PROPERTIES.AMT
    BORROWER.TAX.DETAILS.LIST = SAVE.BORROWER.TAX.DETAILS.LIST

RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= define property amount for Chargeoff BANK subtype>
*** <desc>Define property amount for borrower and BOOK-CUST for BANK type</desc>
DEFINE.CUST.CHARGEOFF.AMT:
    
    PAY.TYP.CNT = DCOUNT(PAYMENT.AMT.LIST,@VM)
    FOR PAY.TYP = 1 TO PAY.TYP.CNT
        PROP.AMT.LIST = PAYMENT.AMT.LIST<1,PAY.TYP>
        PROP.TYP.CNT = DCOUNT(PROP.AMT.LIST,@SM)
        FOR PROP.TYP = 1 TO PROP.TYP.CNT
            PAYMENT.AMT.LIST<1,PAY.TYP,PROP.TYP> = ''
            
            IF BORROWER.TAX.DETAILS.LIST<1,PAY.TYP,PROP.TYP> AND UPDATE.BORROWER.TAX THEN         ;* Tax should be null for borrower when called for BANK subtype
                BORROWER.TAX.DETAILS.LIST<1,PAY.TYP,PROP.TYP> = ''
            END
            
        NEXT PROP.TYP
    NEXT PAY.TYP
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name=CHECK.CALC.CHARGE.REQUIRED>
*** <desc>to check if the payoff process is required</desc>
CHECK.CALC.CHARGE.REQUIRED:

    CALCULATE.CHARGE = 1
    AA.Framework.LoadStaticData('F.AA.PROPERTY', PAYMENT.PROPERTY, CHARGE.PROPERTY.RECORD, '') ;* Get property record to filter out in calucation over charge

    LOCATE "ADVANCE" IN CHARGE.PROPERTY.RECORD<AA.ProductFramework.Property.PropPropertyType, 1> SETTING ADVANCE.POS THEN
        AA.Framework.DeterminePayoffProcess(PayoffProcess,SettleActivity,ERR)
        IF (PayoffProcess OR SettleActivity) THEN
            CALCULATE.CHARGE = '0'
        END
    END
 
    NON.CUSTOMER.PROPERTY = ''         ;* set flag to indicate if CHARGE property is of type NON.CUSTOMER
    RISK.MARGIN.PROPERTY = ''            ;* set flag to indicate if CHARGE property is of type RISK.PARTICIPANT
    PROCESS.NON.CUST.PROP = 1         ;* process non customer charge property by default
    IF "NON.CUSTOMER" MATCHES CHARGE.PROPERTY.RECORD<AA.ProductFramework.Property.PropPropertyType> THEN
        NON.CUSTOMER.PROPERTY = 1           ;* * set flag to indicate if CHARGE property is of type NON.CUSTOMER
        
        IF "RISK.PARTICIPANT" MATCHES CHARGE.PROPERTY.RECORD<AA.ProductFramework.Property.PropPropertyType> THEN
            RISK.MARGIN.PROPERTY = 1                 ;* flag set to indicate Risk MarginFees type property to be proceesed only for Risk Participants
            CHECK.RP.ID = PART.ID<1,PART.COUNT>
            GOSUB GET.LINKED.PORTFOLIO.ID               ;* Get linked portfolio id
        END
    
        IF PROCESS.PARTICIPANTS THEN
            PROCESS.NON.CUST.PROP = 0              ;* flag set to ignore non customer charge processing for borrower when participants defined
        END
    END
 
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= Get Holiday Interest Amounts>
*** <desc>Get Holiday Interest Amount</desc>
GET.HOLIDAY.INTEREST.AMOUNTS:

*** For these Holiday dates, get the Holiday interest amount from the Schedules then accumilate whole Interest amount.
    
    IF FORWARD.PS.RECORD THEN
        HOL.PAYMENT.SCHEDULE = FORWARD.PS.RECORD
        CURRENT.PS.PAYMENT.TYPES = R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsPaymentType> ;* Payment Types in Payment Schedule record
        CURRENT.PS.PAYMENT.PROPERTIES = R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsProperty> ;* Properties in Payment Schedule record
        CURRENT.PS.PAY.TYPE.PROP.LIST = SPLICE(CURRENT.PS.PAYMENT.TYPES,'-',CURRENT.PS.PAYMENT.PROPERTIES)
    END ELSE
        HOL.PAYMENT.SCHEDULE = R.PAYMENT.SCHEDULE
        FORWARD.PS.DATE = ""
    END

    PS.PAYMENT.TYPES = HOL.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsPaymentType>
    PS.PAYMENT.PROPERTIES = HOL.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsProperty>
    PS.START.DATES = HOL.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsStartDate>
    PS.END.DATES = HOL.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsEndDate>
    PS.APPLY.DATE.CONV = HOL.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsApplyDateConvention>
    
    DATE.CONVENTION = R.ACCOUNT<AA.Account.Account.AcDateConvention>
    BUS.DAY.CENTRES = R.ACCOUNT<AA.Account.Account.AcBusDayCentres>
    IF R.ACCOUNT<AA.Account.Account.AcOtherBusDayCentre> THEN    ;* Add arrangement currency country code to bus day centres
        AA.Account.GetArrCurrencyCode(R.ACCOUNT, ARRANGEMENT.ID, BUS.DAY.CENTRES, RET.ERROR)
    END
        
    HOLIDAY.PROPERTIES = "" ; HOLIDAY.PROP.AMOUNTS = "" ;HOLIDAY.PROP.PROJECT.AMOUNTS = "" ; PS.HOLIDAY.START.DATES = ""
    PS.HOLIDAY.END.DATES = "" ; ACD.HOLIDAY.PROP.DATES = "" ; CUMILATIVE.ACD.HOL.PROP.DATES = "" ; HOLIDAY.LAST.PAYMENT.DATES = ""
    CUMULATIVE.ACD.HOLIDAY.PROPERTY.DATES = ""
    HOL.PROP.POS = 0
        
    NO.PAYMENT.TYPES = DCOUNT(PS.PAYMENT.TYPES, @VM)
    NO.HOL.TYPES = DCOUNT(PS.PAYMENT.TYPES, @VM)
    
*** Payment Schedule may have more than 1 HOLIDAY.INTEREST payment types. So, loop it and caluclate Holiday interest for each payment type.
    
    FOR HOL.TYPE = 1 TO NO.HOL.TYPES
        IF PS.PAYMENT.TYPES<1,HOL.TYPE> MATCHES "HOLIDAY.INTEREST":@VM:"HOLIDAY.ACCOUNT":@VM:"HOLIDAY.CHARGE":@VM:"HOLIDAY.PERIODICCHARGE" THEN
            HOLIDAY.CUR.PROPERTY = PS.PAYMENT.PROPERTIES<1,HOL.TYPE> ;* Properties present under HOLIDAY.INTEREST payment type in Payment Schedule Record.
            
            LAST.PH.PAYMENT.DATE = ""
            AA.PaymentSchedule.GetLastPaymentDate(ARRANGEMENT.ID, PS.PAYMENT.TYPES<1,HOL.TYPE>, HOLIDAY.CUR.PROPERTY, "CURRENT", LAST.PH.PAYMENT.DATE, "", "", "")
          
**while triggering the CHANGE.TERM activity after UPDATE-PAYMENT.HOLIDAY activity system taking the previously updated payment schedule record
**instead of taking the triggered activity's payment scheuled record when we have FORWARD RECALCULATE DATE in the Account Details record which final holday interest scheduled date. Which is wrong.
            PS.HOL.PS.START.DATE = PS.START.DATES<1,HOL.TYPE>
            PS.HOL.PS.END.DATE = PS.END.DATES<1,HOL.TYPE>
            
            IF FORWARD.PS.RECORD THEN
                GOSUB CHECK.HOLIDAY.INTEREST.DATE.DETAILS ;* To Check on Date details of HOLIDAY.INTEREST payment type.
            END
        
            HOL.PROP.POS = HOL.PROP.POS + 1    ;* Just increment the position
            HOLIDAY.PROPERTIES<HOL.PROP.POS> = HOLIDAY.CUR.PROPERTY
            
            IF PS.HOL.PS.START.DATE AND NOT(PS.HOL.PS.START.DATE MATCHES "8N") THEN
                RETURN.DATE = ''
                AA.Framework.GetRelativeDate(ARRANGEMENT.ID, PS.HOL.PS.START.DATE, "", "", "", "", "", RETURN.DATE, '')
                PS.HOLIDAY.START.DATES<HOL.PROP.POS> = RETURN.DATE
            END ELSE
                PS.HOLIDAY.START.DATES<HOL.PROP.POS> = PS.HOL.PS.START.DATE
            END
        
            IF (LEN(PS.HOL.PS.START.DATE) EQ "8" OR FIELD(PS.HOL.PS.START.DATE, "_", 1) EQ "D") AND PS.APPLY.DATE.CONV<1,HOL.TYPE> EQ "START.DATE" AND DATE.CONVENTION AND DATE.CONVENTION NE "CALENDAR" THEN    ;* Is start date not in relative date format?
                AA.PaymentSchedule.CheckWorkingDay(PS.HOLIDAY.START.DATES<HOL.PROP.POS>, DATE.CONVENTION, BUS.DAY.CENTRES, "", "", UPDATED.DATE)    ;* Get working day if inputted start date falls on holiday
            
                IF UPDATED.DATE AND PS.HOLIDAY.START.DATES<HOL.PROP.POS> NE UPDATED.DATE THEN   ;* Is payment start date falls on holiday and convention happened?
                    PS.HOLIDAY.START.DATES<HOL.PROP.POS> = UPDATED.DATE   ;* Update the latest date
                END
            END
        
            IF PS.HOL.PS.START.DATE MATCHES "R_MATURITY":@VM:"R_LAST" THEN
                PS.HOL.PS.END.DATE = PS.HOL.PS.START.DATE
            END
        
            IF PS.HOL.PS.END.DATE AND NOT(PS.HOL.PS.END.DATE MATCHES "8N") THEN
                RETURN.DATE = ''
                AA.Framework.GetRelativeDate(ARR.NO, PS.HOL.PS.END.DATE, "", "", "", "", "", RETURN.DATE, '')
                PS.HOLIDAY.END.DATES<HOL.PROP.POS> = RETURN.DATE
            END ELSE
                PS.HOLIDAY.END.DATES<HOL.PROP.POS> = PS.HOL.PS.END.DATE
            END
        
            HOLIDAY.LAST.PAYMENT.DATES<HOL.PROP.POS> = LAST.PH.PAYMENT.DATE
   
** Get the Holiday Interest Amount
            BALANCE.TO.CHECK = "HOL": HOLIDAY.CUR.PROPERTY        ;* just Concatenate the balane prefix along with property.
            IF ASF.OPERATING.LEASE THEN                         ;* For operating Lease Asset Finance contract, inf suffix needs to be added.
                BALANCE.TO.CHECK = BALANCE.TO.CHECK : "INF"
            END
            DATE.OPTIONS = "" ; BAL.DETAILS = ""
            DATE.OPTIONS<2> = "ALL"
            AA.Framework.GetPeriodBalances(ACCOUNT.ID, BALANCE.TO.CHECK, DATE.OPTIONS, EFFECTIVE.DATE, "", "", BAL.DETAILS, "")        ;* Get the balance for this date
            HOLIDAY.PROP.AMOUNTS<HOL.PROP.POS> = ABS(BAL.DETAILS<AC.BalanceUpdates.AcctActivity.IcActBalance>)            ;* Update Outstanding holiday Interest amount
            
            GOSUB GET.PARENT.TYPE.HOLIDAY.DATE        ;* Get the latest cycle Holiday dates for Parent payment type of Holiday Interest
            IF NOT(CUMULATIVE.ACD.HOLIDAY.PROPERTY.DATES<HOL.PROP.POS>) THEN ;* populate holiday dates only once when we encounter a holiday.interest type in payment schedule
                GOSUB GET.HOL.INTEREST.TYPE.HOLIDAY.DATE ;* Get the latest cycle Holiday dates for HOLIDAY.INTEREST payment type
            END
            GOSUB GET.HOL.DEFERRED.AMOUNT       ;* Get the Deferred Holiday Interest from the Account details Record
        END

    NEXT HOL.TYPE

RETURN
*** </region>
*----------------------------------------------------------------------------

*** <region name=Get Payrent Type Holiday dates>
*** <desc>Get the Parent payment type Holiday dates from Account details</desc>
GET.PARENT.TYPE.HOLIDAY.DATE:

    HOLIDAY.PAYMENT.TYPE = ""

    FOR PAYMENT.TYPE.CNT = 1 TO NO.PAYMENT.TYPES
        IF NOT(PS.PAYMENT.TYPES<1,PAYMENT.TYPE.CNT> MATCHES "HOLIDAY.INTEREST":@VM:"HOLIDAY.ACCOUNT":@VM:"HOLIDAY.CHARGE":@VM:"HOLIDAY.PERIODICCHARGE") THEN             ;* Exclude the HOLIDAY.INTEREST payment type
            LOCATE HOLIDAY.CUR.PROPERTY IN PS.PAYMENT.PROPERTIES<1,PAYMENT.TYPE.CNT,1> SETTING PROP.POS THEN
                AA.PaymentSchedule.GetSysBillType(HOL.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsBillType, PAYMENT.TYPE.CNT>, SysBillType, ReturnError)
                RPaymentType = AA.PaymentSchedule.PaymentType.CacheRead(PS.PAYMENT.TYPES<1,PAYMENT.TYPE.CNT>, "")
*** Do not add disbursement, Downpayment, and info.bill payment types to the list as they cann't be declared as holiday.
                IF NOT(SysBillType MATCHES "DISBURSEMENT":@VM:"INFO") AND RPaymentType<AA.PaymentSchedule.PaymentType.PtCalcType> NE "TRANSACTION" THEN
                    HOLIDAY.PAYMENT.TYPE =  PS.PAYMENT.TYPES<1,PAYMENT.TYPE.CNT>
                    PAYMENT.TYPE.CNT = NO.PAYMENT.TYPES   ;* Exist from the Loop
                END
            END
        END
    NEXT PAYMENT.TYPE.CNT
 
    TOT.HOL.PAYMENT.TYPES = DCOUNT(tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolPaymentType>,@VM)
        
    FOR HOL.PAYMENT.TYPE = 1 TO TOT.HOL.PAYMENT.TYPES
        HOLIDAY.PAYMENT.INFO = tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolPaymentType>
        HOL.PAYMENT.TYPES = FIELDS(HOLIDAY.PAYMENT.INFO,"-",1)
        IF HOLIDAY.PAYMENT.TYPE EQ HOL.PAYMENT.TYPES<1,HOL.PAYMENT.TYPE> THEN
            ACD.HOLIDAY.PROP.DATES<HOL.PROP.POS> = RAISE(tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolidayDate,HOL.PAYMENT.TYPE>)
            IF NOT(CUMILATIVE.ACD.HOL.PROP.DATES<HOL.PROP.POS>) THEN
                CUMILATIVE.ACD.HOL.PROP.DATES<HOL.PROP.POS> = RAISE(tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolidayDate,HOL.PAYMENT.TYPE>)
            END ELSE
                CUMILATIVE.ACD.HOL.PROP.DATES<HOL.PROP.POS> = CUMILATIVE.ACD.HOL.PROP.DATES<HOL.PROP.POS>:@VM:RAISE(tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolidayDate,HOL.PAYMENT.TYPE>)
            END
        END
    NEXT HOL.PAYMENT.TYPE

RETURN
*** </region>
*----------------------------------------------------------------------------
*** <region name=Get HOLIDAY.INTEREST payment type Holiday dates>
*** <desc>Get the HOLIDAY.INTEREST payment type Holiday dates from Account details</desc>
GET.HOL.INTEREST.TYPE.HOLIDAY.DATE:
   
    TOT.HOL.PAYMENT.TYPES = DCOUNT(tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolPaymentType>,@VM)
        
    FOR HOL.PAYMENT.TYPE = 1 TO TOT.HOL.PAYMENT.TYPES  ;* loop through all holiday payment types
        HOLIDAY.PAYMENT.INFO = tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolPaymentType>
        HOL.PAYMENT.TYPES = FIELDS(HOLIDAY.PAYMENT.INFO,"-",1)
        IF HOL.PAYMENT.TYPES<1,HOL.PAYMENT.TYPE> MATCHES "HOLIDAY.INTEREST":@VM:"HOLIDAY.ACCOUNT":@VM:"HOLIDAY.CHARGE":@VM:"HOLIDAY.PERIODICCHARGE" THEN ;* whenever holiday.interest type is available, store the holiday dates for current property
            IF NOT(CUMULATIVE.ACD.HOLIDAY.PROPERTY.DATES<HOL.PROP.POS>) THEN
                CUMULATIVE.ACD.HOLIDAY.PROPERTY.DATES<HOL.PROP.POS> = RAISE(tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolidayDate,HOL.PAYMENT.TYPE>)
            END ELSE
                CUMULATIVE.ACD.HOLIDAY.PROPERTY.DATES<HOL.PROP.POS> = CUMULATIVE.ACD.HOLIDAY.PROPERTY.DATES<HOL.PROP.POS>:@VM:RAISE(tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolidayDate,HOL.PAYMENT.TYPE>)
            END
        END
    NEXT HOL.PAYMENT.TYPE

RETURN
*** </region>
*----------------------------------------------------------------------------
 
*** <region name= Check Defer Holiday Interest>
*** <desc> Check current processing payment date is Holiday one or not</desc>
CHECK.DEFER.HOLIDAY.INTEREST:

*** Check Current payment has declared as Holiday and selected Deferment of Holiday Interest and Repaid later after end of Holiday Period.
    
    TotalHolPaymentType = DCOUNT(tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolPaymentType>,@VM)
*** If HOL.START.DATE is different but same HolPaymentTyp system update on two set of holiday details for HolPaymentTyp in Account details.
*** Hence, looping the each HolPaymentTyp and check with PaymentType
   
    FOR HolPaymentType = 1 TO TotalHolPaymentType
        HolidayPaymentInfo = tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolPaymentType>
        HolPaymentTypes = FIELDS(HolidayPaymentInfo,"-",1)
        IF PAYMENT.TYPE EQ HolPaymentTypes<1,HolPaymentType> THEN
            LOCATE HOLIDAY.PAYMENT.DATE IN tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolidayDate,HolPaymentType,1> SETTING HolPos THEN
                IF tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolRepayOption,HolPaymentType> MATCHES "DEFERRED":@VM:"DEFER.ALL" THEN
                    DEFER.HOLIDAY.INTEREST = 1
                    HolPaymentType = TotalHolPaymentType   ;* Exit from the Loop
                END
            END
        END
    NEXT HolPaymentType

RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name= Get Final Interest Amount>
*** <desc> Get the Outstanidng Holiday Interest amount for Holiday Periods</desc>
GET.FINAL.INTEREST.AMOUNT:
    
    HOLIDAYINTAMT.TAXCALC = ""
    BEGIN CASE
        CASE SCHEDULE.INFO<8> AND DEFER.HOLIDAY.INTEREST AND DEFER.ALL.HOLIDAY.FLAG AND HOLIDAY.DATE AND NOT(HOLIDAY.AMOUNT) AND NOT(RESTRICTED.PROPERTY)
            PAYMENT.PROPERTY.AMOUNT = 0  ;* During projection call need to show holiday interest amount as zero when Full period amount is holiday for Interest property class in Payment holiday setup
            HOLIDAYINTAMT.TAXCALC = 1
            
        CASE (SCHEDULE.INFO<8> OR SCHEDULE.INFO<73>) AND DEFER.HOLIDAY.INTEREST AND DEFER.ALL.HOLIDAY.FLAG AND HOLIDAY.PROPERTY.AMOUNT AND NOT(RESTRICTED.PROPERTY)
            SAVE.HOLIDAY.PROPERTY.AMOUNT = HOLIDAY.PROPERTY.AMOUNT ;* save the holiday property amount for tax inclusive calculation if needed
            PAYMENT.PROPERTY.AMOUNT = HOLIDAY.PROPERTY.AMOUNT  ;* During projection call need to show holiday interest original property amount when Partiall period amount is holiday for Interest property class in Payment holiday setup
            HOLIDAYINTAMT.TAXCALC = 1 ;* Flag to indicate Tax amount should be calculated for the Holiday Interest amount.
            IF HOLIDAY.AMOUNT THEN
                HOLIDAY.AMOUNT -= INT.AMOUNT ;* When non restricted property comes,decrement the holiday amount from calculated interest amount  to utilise remaining amount for other properties
            END
            IF HOLIDAY.AMOUNT AND HOLIDAY.AMOUNT LE 0 THEN ;* If holiday amount goes less than or equal to zero,then make is as zero
                HOLIDAY.AMOUNT = 0
            END
            
        CASE SCHEDULE.INFO<8> AND DEFER.HOLIDAY.INTEREST AND DEFER.ALL.HOLIDAY.FLAG AND HOLIDAY.AMOUNT AND NOT(RESTRICTED.PROPERTY)
            GOSUB NON.DEFER.HOLIDAY.INTEREST  ;* During projection call need to show holiday interest original property amount when Partiall period amount is holiday for Interest property class in Payment holiday setup

        CASE SCHEDULE.INFO<51> AND DEFER.HOLIDAY.INTEREST AND NOT(RESTRICTED.PROPERTY) ;* process the non-enquiry holiday calculation here only for non restricted property
            GOSUB DEFER.HOLIDAY.INTEREST
    
        CASE 1
            GOSUB NON.DEFER.HOLIDAY.INTEREST
    END CASE

RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name = Defer Holiday Interest>
*** <desc> Get the Outstanidng Holiday Interest amount for Holiday Periods </desc>
DEFER.HOLIDAY.INTEREST:
    
*** Just take the Remaining Interest portion after Billing.

*** For example User given Holiday Payment 40. Current Period Accrued Interest - 100.
*** Then Holiday Payment Schould be calcualted for remaining accrued interest after Holiday payment . i.e = 100 - 40 = 60

*** Else Condition

*** If Holiday Payment Given as 100 or more and Current Period Accrue Interest - 100
*** Then there is no Outstanding accrued Interest to defer it and Collect after Holiday End. So, lets take it as = 0.

    IF TAX.INCLUSIVE THEN  ;* For tax inclusive payment type we need to find how much was the interest portion before determining the defer amount
        BASE.AMOUNT = HOLIDAY.AMOUNT
        BASE.PROPERTY = PAYMENT.PROPERTY
        REDUCE.CALC.AMT.TAX = "" ;* dont reduce calc amt as this calculation needed only for determining holiday amount
        PRINCIPAL.INFLOW = ""   ;* Indicate account disburement/funding amount
        GOSUB CALCULATE.TAX.AMOUNT   ;* calculate tax on the holiday amount
        REDUCE.CALC.AMT.TAX = "1" ;* restore the flag for further tax processing
        TOTAL.AMOUNT = TAX.AMOUNTS + HOLIDAY.AMOUNT
        INT.HOLIDAY.AMOUNT = (HOLIDAY.AMOUNT/TOTAL.AMOUNT)*HOLIDAY.AMOUNT ;* holiday amount apportioned for interest alone
    END
    BEGIN CASE
        CASE HOLIDAY.AMOUNT LT INT.AMOUNT AND TAX.INCLUSIVE ;* for tax inclusive subtract only the holiday amt apportioned to interest property
            PAYMENT.PROPERTY.AMOUNT = INT.AMOUNT - INT.HOLIDAY.AMOUNT
        CASE HOLIDAY.AMOUNT LT INT.AMOUNT
            PAYMENT.PROPERTY.AMOUNT = INT.AMOUNT - HOLIDAY.AMOUNT
        CASE 1
            PAYMENT.PROPERTY.AMOUNT = 0
    END CASE
 
    IF NOT(RESTRICTED.PROPERTY) AND HOLIDAY.AMOUNT THEN
        HOLIDAY.AMOUNT -= INT.AMOUNT ;* When non restricted property comes,decrement the holiday amount from calculated interest amount  to utilise remaining amount for other properties
    END
    IF HOLIDAY.AMOUNT AND HOLIDAY.AMOUNT LE 0 THEN ;* If holiday amount goes less than or equal to zero,then make is as zero
        HOLIDAY.AMOUNT = 0
    END
                 
RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name = Non Defer Holiday Interest >
*** <desc> Regular Interest calcualtion for each payment date</desc>
NON.DEFER.HOLIDAY.INTEREST:

    SAVE.HOLIDAY.AMOUNT = HOLIDAY.AMOUNT
    IF (HOLIDAY.AMOUNT AND HOLIDAY.AMOUNT LE INT.AMOUNT) OR (NOT(HOLIDAY.AMOUNT) AND HOLIDAY.DATE AND NOT(SCHEDULE.INFO<51>)) AND NOT(SCHEDULE.INFO<52>) OR (HOLIDAY.PROPERTY.AMOUNT EQ '0' AND HOLIDAY.AMOUNT EQ '0') AND NOT(RESTRICTED.PROPERTY) THEN ;* When the holiday amount less than or equal to calculated interest amount,assign property amount as holiday amount.
        PAYMENT.PROPERTY.AMOUNT = HOLIDAY.AMOUNT
        HOLIDAYINTAMT.TAXCALC = 1
    END ELSE
        PAYMENT.PROPERTY.AMOUNT = INT.AMOUNT ;* Otherwise assign calculated interest amount to property amount
    END
    IF NOT(RESTRICTED.PROPERTY) AND HOLIDAY.AMOUNT THEN
        HOLIDAY.AMOUNT -= INT.AMOUNT ;* When non restricted property comes,decrement the holiday amount from calculated interest amount  to utilise remaining amount for other properties
    END
    IF HOLIDAY.AMOUNT AND HOLIDAY.AMOUNT LE 0 THEN ;* If holiday amount goes less than or equal to zero,then make is as zero
        HOLIDAY.AMOUNT = 0
    END
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= Check adjustment Required>
*** <desc>Check adjustment Required</desc>
CHECK.ADJUSTMENT.REQUIRED:
            
    HOLIDAY.DATES = ""
            
    IF REPAY.OPTION THEN
        LOCATE PAYMENT.PROPERTY IN HOLIDAY.PROPERTIES<1> SETTING PROP.POS THEN
            CURRENT.PROP.HOLIDAY.DATES = CUMILATIVE.ACD.HOL.PROP.DATES<PROP.POS>
        END
        HOLIDAY.DATES = CURRENT.PROP.HOLIDAY.DATES

*** It is mid of the Holiday period before sytem processing the Forward Recalcualte activity. So, lets take the HOLIDAY.DATES
*** as directly from Account details Record.
        
        IF NOT(HOLIDAY.DATES) AND CUMILATIVE.ACD.HOL.PROP.DATES THEN
            HOLIDAY.PAYMENT.TYPES = CUMILATIVE.ACD.HOL.PROP.TYPES
            NO.TYPES = DCOUNT(CUMILATIVE.ACD.HOL.PROP.TYPES, @FM)
            FOR TYPE.CNT = 1 TO NO.TYPES
                IF PAYMENT.TYPE EQ CUMILATIVE.ACD.HOL.PROP.TYPES<TYPE.CNT> THEN
                    HOLIDAY.DATES = CUMILATIVE.ACD.HOL.PROP.DATES<TYPE.CNT>
                END
            NEXT TYPE.CNT
        END
*** Still there is no Holidays then just for safer side take the Holiday dates from the HOLIDAY.DATES.ARRAY
        IF NOT(HOLIDAY.DATES) THEN
            HOLIDAY.DATES = HOLIDAY.DATES.ARRAY
        END
    END
    
    BEGIN CASE
        CASE PAYMENT.MODE EQ "ADVANCE"
            AA.Interest.GetAdjustedInterestAmount(ARRANGEMENT.ID, PAYMENT.PROPERTY, EXTENSION.NAME, "CURRENT.ACCRUE", PERIOD.START.DATE, PERIOD.END.DATE, ADJUSTMENT.AMOUNT, HOLIDAY.DATES)
    
        CASE AF.Framework.getActivityId()<AA.Framework.ActActivity> EQ "APPLYPAYMENT"
            AA.PaymentSchedule.GetActualAdjustedInterestAmount(ARRANGEMENT.ID, PAYMENT.PROPERTY, EXTENSION.NAME, "CURRENT", PERIOD.START.DATE, PERIOD.END.DATE, ADJUSTMENT.AMOUNT, HOLIDAY.DATES)

        CASE 1
            AA.Interest.GetAdjustedInterestAmount(ARRANGEMENT.ID, PAYMENT.PROPERTY, EXTENSION.NAME, "CURRENT", PERIOD.START.DATE, PERIOD.END.DATE, ADJUSTMENT.AMOUNT, HOLIDAY.DATES)
    END CASE
        
RETURN
*** </region>
*-----------------------------------------------------------------------------
GET.FORWARD.RECALC.PS.RECORD:
    
    TOT.HOL.PAYMENT.TYPES = DCOUNT(tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolPaymentType>,@VM)
    
***When UPDATE-PAYMENT.HOLIDAY activity triggered for Multiple time for same property.So,System will have multiple date on AdHolidayDate field.
***System should process and get the payment schedule record based on the Latest AdHolidayDate field value.
    CNT = 1
    FOR HOL.PAYMENT.CNT = TOT.HOL.PAYMENT.TYPES TO 1 STEP -1
        IF tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolRepayOption, HOL.PAYMENT.CNT> EQ "DEFERRED" THEN
            NO.HOL.DATES = DCOUNT(tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolidayDate, HOL.PAYMENT.CNT>, @SM)
            FORWARD.RECALC.DATE<CNT> =  tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolidayDate, HOL.PAYMENT.CNT, NO.HOL.DATES>
            FORWARD.RECALC.PROPERTY<CNT> = FIELD(tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolDefInterest, HOL.PAYMENT.CNT>, AA.Framework.Sep, 1)
            CNT ++
        END
        IF tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolRepayOption, HOL.PAYMENT.CNT> EQ "DEFER.ALL" THEN
            NO.HOL.DATES = DCOUNT(tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolidayDate, HOL.PAYMENT.CNT>, @SM)
            FORWARD.RECALC.PROPERTIES = RAISE(RAISE(FIELDS(tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolDeferProperty, HOL.PAYMENT.CNT>, "#", 1)))
            HOL.DEF.PROP.CNT = DCOUNT(FORWARD.RECALC.PROPERTIES,@FM)
            FOR CUR.HOL.DEF.PROP = 1 TO HOL.DEF.PROP.CNT
                FORWARD.RECALC.PROPERTY<CNT> = FORWARD.RECALC.PROPERTIES<CUR.HOL.DEF.PROP>
                FORWARD.RECALC.DATE<CNT> = tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolidayDate, HOL.PAYMENT.CNT, NO.HOL.DATES>
                CNT ++
            NEXT CUR.HOL.DEF.PROP
        END
    NEXT HOL.PAYMENT.CNT
    
    FORWARD.PS.RECORD = ""
*** Schedule Info <49> Will be set in Update Cashflow routine
    TOT.DEF.HOL.PROP.CNT = DCOUNT(FORWARD.RECALC.PROPERTY, @FM)
    FOR DEF.HOL.PROP.CNT = 1 TO TOT.DEF.HOL.PROP.CNT WHILE NOT(FORWARD.PS.RECORD)
        IF (FORWARD.RECALC.DATE<DEF.HOL.PROP.CNT> AND EFFECTIVE.DATE LT FORWARD.RECALC.DATE<DEF.HOL.PROP.CNT>) OR SCHEDULE.INFO<49> THEN
            AA.ProductFramework.GetPropertyRecord("", ARRANGEMENT.ID, "", FORWARD.RECALC.DATE<DEF.HOL.PROP.CNT>, "PAYMENT.SCHEDULE", "", FORWARD.PS.RECORD, "") ;* Get the payment schedule record
            FORWARD.PS.DATE = FORWARD.RECALC.DATE<DEF.HOL.PROP.CNT>
        END
    NEXT DEF.HOL.PROP.CNT

RETURN
*** </region>
*----------------------------------------------------------------------------
*** <region name=  Get Middel Period Hol Dates>
*** <desc>Get Middel Period Hol Dates</desc>
GET.MIDDLE.PERIOD.HOL.DATES:
    
    CUMILATIVE.ACD.HOL.PROP.TYPES = ""
    
    TOTAL.HOL.PAYMENT.TYPES = DCOUNT(tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolPaymentType>,@VM)
    FOR HOL.PAYMENT.TYPE = 1 TO TOTAL.HOL.PAYMENT.TYPES
        HOLIDAY.PAYMENT.INFO = tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolPaymentType>
        HOL.PAYMENT.TYPES = FIELDS(HOLIDAY.PAYMENT.INFO,"-",1)
        IF tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolRepayOption, HOL.PAYMENT.TYPE> MATCHES "DEFERRED":@VM:"DEFER.ALL" THEN
            LOCATE HOL.PAYMENT.TYPES<1,HOL.PAYMENT.TYPE> IN CUMILATIVE.ACD.HOL.PROP.TYPES<1> SETTING HOL.POS THEN
                CUMILATIVE.ACD.HOL.PROP.DATES<HOL.POS> = CUMILATIVE.ACD.HOL.PROP.DATES<HOL.POS>:@VM:RAISE(tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolidayDate,HOL.PAYMENT.TYPE>)
            END ELSE
                CUMILATIVE.ACD.HOL.PROP.DATES<HOL.POS> = RAISE(tmp.AA$ACCOUNT.DETAILS<AA.PaymentSchedule.AccountDetails.AdHolidayDate,HOL.PAYMENT.TYPE>)
                CUMILATIVE.ACD.HOL.PROP.TYPES<HOL.POS> = HOL.PAYMENT.TYPES<1,HOL.PAYMENT.TYPE>
            END
        END
    NEXT HOL.PAYMENT.TYPE
    
RETURN
*** </region>
*----------------------------------------------------------------------------
*** <region name = Check Holiday Period >
*** <desc>Check my current payment in Holiday Period or Repayment Period</desc>
CHECK.HOLIDAY.PERIOD:

    TEMP.PAYMENT.DATES = PAYMENT.DATES

    LOCATE CURRENT.SYS.DATE IN TEMP.PAYMENT.DATES<1> BY "AN" SETTING DATE.POS THEN
        NEXT.PAYMENT.DATE = TEMP.PAYMENT.DATES<DATE.POS+1>
    END ELSE
        NEXT.PAYMENT.DATE = TEMP.PAYMENT.DATES<DATE.POS>
    END

    BEGIN CASE

**** Next payment is starting after Final Holiday date. So, it is Holiday Period
        CASE NEXT.PAYMENT.DATE AND NEXT.PAYMENT.DATE LE ACTUAL.TYPE.END.DATE
            LOCATE NEXT.PAYMENT.DATE IN ACD.HOLIDAY.PROP.DATES<1,1> SETTING DATE.POS THEN         ;* It could be Partial payment Holiday
            
                DEFER.HOLIDAY.PERIOD = 1
            END
*** Our Current System date is less than Holiday Period End date AND Out next payment date is greater than the Holiday Period End date

        CASE (CURRENT.SYS.DATE LT ACTUAL.TYPE.END.DATE) AND (NEXT.PAYMENT.DATE GT ACTUAL.TYPE.END.DATE)
            DEFER.HOLIDAY.PERIOD = 1
                    
*** During makedue activity of final payment holiday date, system should still consider it as a DEFER.HOLIDAY.PERIOD
        CASE (CURRENT.SYS.DATE EQ ACTUAL.TYPE.END.DATE) AND (NEXT.PAYMENT.DATE GT ACTUAL.TYPE.END.DATE) AND MASTER.ACT.CLASS EQ "MAKEDUE-PAYMENT.SCHEDULE"
            DEFER.HOLIDAY.PERIOD = 1

*** My current system date is in between Holiday Period Start and End dates. So, it is holiday Period.
        CASE (CURRENT.SYS.DATE GE ACTUAL.TYPE.START.DATE) AND  (CURRENT.SYS.DATE LT ACTUAL.TYPE.END.DATE)
            DEFER.HOLIDAY.PERIOD = 1
            
*** Next Payment is present in Holiday Dates. So, it could be Holiday period with Partial payment.
            
        CASE NEXT.PAYMENT.DATE
            LOCATE NEXT.PAYMENT.DATE IN ACD.HOLIDAY.PROP.DATES<1,1> SETTING DATE.POS THEN         ;* It could be Partial payment Holiday
                DEFER.HOLIDAY.PERIOD = 1
            END
    END CASE
*** If the current payment date is after the future second payment holiday date (period balances wont be available yet so take from calc amount)
    IF (PAYMENT.DATE GE ACTUAL.TYPE.START.DATE) AND (CURRENT.SYS.DATE LT ACTUAL.TYPE.END.DATE) THEN
        DEFER.HOLIDAY.PERIOD = 1
    END

*** In case of migration if user Defines the payment Effective on TODAY and deines the Holiday then when user is in Current System date treate
**** it as DeferHolidayPeriod. The below code introduced only to address the Regression failures. And we need to look for property fix later.

    IF ARR.START.DATE EQ CURRENT.SYS.DATE THEN
        LOCATE ARR.START.DATE IN ACD.HOLIDAY.PROP.DATES<1,1> SETTING HOL.POS THEN
            DEFER.HOLIDAY.PERIOD = 1
        END
    END
    
    IF SCHEDULE.INFO<49> AND (NEXT.PAYMENT.DATE GT ACTUAL.TYPE.END.DATE) THEN
        DEFER.HOLIDAY.PERIOD = 1
    END
    
    
** Need to check if there is any issued bill for the current payment date with holiday interest amount
** Invoke GetBill if it is a valid ArrangementId
    IF NOT (BILL.DETAILS) AND ARRANGEMENT.ID NE 'DUMMY' THEN
        AA.PaymentSchedule.GetBill(ARRANGEMENT.ID, "", PAYMENT.DATE, "", "", BILL.TYPE, "" , "ISSUED", "", "", "", "", BILL.REFERENCES, RET.ERROR)
        IF BILL.REFERENCES THEN
            LOOP
                REMOVE BILL.REFERENCE FROM BILL.REFERENCES SETTING BILL.REF.POS
            WHILE BILL.REFERENCE
                AA.PaymentSchedule.GetBillDetails(ARRANGEMENT.ID, BILL.REFERENCE, BILL.DETAIL, RET.ERROR)
                BILL.DETAILS<-1> = LOWER(BILL.DETAIL)
                BILL.CNT = BILL.CNT + 1
            REPEAT
        END
    END
    
    HOLIDAY.BILL.PRESENT = ""
    FOR BILL.CNT = 1 TO DCOUNT(BILL.DETAILS, @FM)
        CURR.BILL.DETAILS = RAISE(BILL.DETAILS<BILL.CNT>)
        FOR PAY.TYPE.CNT = 1 TO DCOUNT(CURR.BILL.DETAILS<AA.PaymentSchedule.BillDetails.BdPaymentType>,@VM)
            IF PAYMENT.TYPE EQ CURR.BILL.DETAILS<AA.PaymentSchedule.BillDetails.BdPaymentType, PAY.TYPE.CNT> THEN ;* Payment Type can be HOLIDAY.INTEREST/HOLIDAY.ACCOUNT/HOLIDAY.CHARGE/HOLIDAY.PERIODICCHARGE
                LOCATE PAYMENT.PROPERTY IN CURR.BILL.DETAILS<AA.PaymentSchedule.BillDetails.BdPayProperty, PAY.TYPE.CNT, 1> SETTING VM.POS THEN
                    HOLIDAY.BILL.PRESENT = 1
                END
            END
        NEXT PAY.TYPE.CNT
    NEXT BILL.CNT

       
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
  
*** <region name = Cehck Carry forward Accruals >
*** <desc>During defer Holiday period system should not be carry forward the Interest amount</desc>
CHECK.CARRY.FORWARD.ACCRUALS:
    
    LOCATE PAYMENT.PROPERTY IN HOLIDAY.PROPERTIES<1> SETTING PROP.POS THEN
        CURRENT.PROP.HOLIDAY.DATES = CUMILATIVE.ACD.HOL.PROP.DATES<PROP.POS>
    END
    
*** It is mid of the Holiday period before sytem processing the Forward Recalcualte activity. So, lets take the HOLIDAY.DATES
*** as directly from Account details Record.
        
    IF NOT(CURRENT.PROP.HOLIDAY.DATES) AND CUMILATIVE.ACD.HOL.PROP.DATES THEN
        HOLIDAY.PAYMENT.TYPES = CUMILATIVE.ACD.HOL.PROP.TYPES
        NO.TYPES = DCOUNT(CUMILATIVE.ACD.HOL.PROP.TYPES, @FM)
        FOR TYPE.CNT = 1 TO NO.TYPES
            IF PAYMENT.TYPE EQ CUMILATIVE.ACD.HOL.PROP.TYPES<TYPE.CNT> THEN
                CURRENT.PROP.HOLIDAY.DATES = CUMILATIVE.ACD.HOL.PROP.DATES<TYPE.CNT>
            END
        NEXT TYPE.CNT
    END
    
    LOCATE PERIOD.START.DATE IN CURRENT.PROP.HOLIDAY.DATES<1,1> SETTING HOL.POS THEN
        ADJUSTMENT.AMOUNT = 0
    END
        
    LOCATE PERIOD.END.DATE IN CURRENT.PROP.HOLIDAY.DATES<1,1> SETTING HOL.POS THEN
        ADJUSTMENT.AMOUNT = 0
    END
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name = Get Master Activity >
*** <desc>Get the master activity class from AAA record</desc>
GET.ACTUAL.MASTER.ACTIVITY.CLASS:

**** This logic has to be modified later. Some where master activity is getting changed, so we are reading the AAA record and taking from there.

    MASTER.AAA.ID = AF.Framework.getC_arractivityrec()<AA.Framework.ArrangementActivity.ArrActMasterAaa>
    MASTER.ACTIVITY.RECORD = AA.Framework.ArrangementActivity.Read(MASTER.AAA.ID,"")
    MASTER.ACTIVITY.CLASS = MASTER.ACTIVITY.RECORD<AA.Framework.ArrangementActivity.ArrActActivityClass>
    MASTER.ACT.CLASS = FIELD(MASTER.ACTIVITY.CLASS, "-", 2,2)

RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name = Get Holiday Payment Amount >
*** <desc>Get Holiday Payment Amount</desc>
GET.HOLIDAY.PAYMENT.AMOUNT:

    START.DATE = PS.HOLIDAY.START.DATES<PROP.POS>
    END.DATE = PS.HOLIDAY.END.DATES<PROP.POS>
**System needs to calculate the holiday payment amount based on actual amount.
**Even if we have defined Start and End date for the HOLIDAYINTEREST payment type.
    IF ((PAYMENT.DATE GE START.DATE) AND (PAYMENT.DATE LE END.DATE)) OR SCHEDULE.INFO<51> OR HOLIDAY.BILL.PRESENT OR NOT(START.DATE) OR NOT(END.DATE) OR (FORWARD.PS.RECORD) THEN   ;* NOT(START.DATE) is added for a specific condition when we have to project PS if holiday interest properties are captured only during Balance catpture activity
*** Use Period Balance since we are in Repayment Mode and reduce it for each installment
        IF PAYMENT.PROPERTY.AMOUNT LE HOLIDAY.PROP.AMOUNTS<PROP.POS> THEN
*** Let due the actual Property amount and reduce it from the Outstanding Balance
            IF PAYMENT.DATE EQ END.DATE THEN
                PAYMENT.PROPERTY.AMOUNT = HOLIDAY.PROP.AMOUNTS<PROP.POS>
                HOLIDAY.PROP.AMOUNTS<PROP.POS> = 0      ;* Reset to zero. So, if any sub sequence schedules those would not be collected
            END ELSE

*** In case when system performing the Forward Recalcualte on Due date where already HOLIDAYINTEREST payment collected, then during
*** next Holiday Intrest component Calculation current PAYMENT.DATE holiday amount should not be reduced from the Total HOLIDAY.DEF.AMOUNT
*** Since it was make due and reduced from Period Balance. Since Dates returning the MAKEDUE date as well, ignore here reducing the
*** bill Holiday amount from the Total HOLIDAY.PROP.AMOUNTS - Scenario SCRPT211050373887
            
                IF HOL.PROP.LAST.PAYMENT.DATE THEN ;* OK Forward recalculate falls on a holiday interest date already made due
                    CURRENT.DATE.HOLIDAY = ""  ;* flag to indicate whether the current payment date is also made holiday as part of current update-payment.holiday
                    LOCATE PAYMENT.DATE IN CUMULATIVE.ACD.HOLIDAY.PROPERTY.DATES<PROP.POS> SETTING HOL.DATE.POS THEN ;* look for the current payment date in holiday dates of HOLIDAY.INTEREST type in account details
                        CURRENT.DATE.HOLIDAY = "1"
                    END
                END
** even if the current payment date bill is already collected , still reduce the PAYMENT.DATE holiday amount from the Total HOLIDAY.DEF.AMOUNT as
** that is also made as holiday in current update-payment.holiday activity, the details of which are now available in account details as we are updating holiday.interest
** payment type also in account details
                IF NOT(HOL.PROP.LAST.PAYMENT.DATE) OR (PAYMENT.DATE GT HOL.PROP.LAST.PAYMENT.DATE) OR (CURRENT.DATE.HOLIDAY) THEN
                    HOLIDAY.PROP.AMOUNTS<PROP.POS> = HOLIDAY.PROP.AMOUNTS<PROP.POS> -  PAYMENT.PROPERTY.AMOUNT
                END
            END
        END ELSE
            PAYMENT.PROPERTY.AMOUNT = HOLIDAY.PROP.AMOUNTS<PROP.POS>
            HOLIDAY.PROP.AMOUNTS<PROP.POS> = 0      ;* Reset to zero. So, if any sub sequence schedules those would not be collected
        END
    END
                
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name = Get Holiday Deferred Amount >
*** <desc>Get the Deferred Holiday Interest from the account details record</desc>
GET.HOL.DEFERRED.AMOUNT:

    HOLIDAY.DEF.AMOUNT = ""
    AA.PaymentSchedule.ProcessHolDeferredAmount("", HOLIDAY.PAYMENT.TYPE,  HOLIDAY.CUR.PROPERTY, HOLIDAY.DEF.AMOUNT, "GET", "", "")
***For example, if we're mid-way through a deferment period (e.g., 5 schedules with only 2 completed), the account details may return 0 for holiday interest, as it hasn't been calculated for the previous activity.
*** However, the remaining interest for the next 3 schedules is available in ECB, so we're retrieving the holiday amount from ECB.
    IF NOT(HOLIDAY.DEF.AMOUNT) AND HOLIDAY.PROP.AMOUNTS<HOL.PROP.POS> THEN
        HOLIDAY.DEF.AMOUNT = HOLIDAY.PROP.AMOUNTS<HOL.PROP.POS>           ;* Update Outstanding holiday Interest amount
        ECB.HOL.AMT = 1     ;* Flag to determine holiday interest amount is retrived from ECB.
    END
    HOLIDAY.PROP.PROJECT.AMOUNTS<HOL.PROP.POS> = HOLIDAY.DEF.AMOUNT
    
    
RETURN
*** </region>
*-----------------------------------------------------------------------------

*** <region name = Get Holiday Projection Payment Amount >
*** <desc>Get Holiday Projection Payment Amount</desc>
GET.HOLIDAY.PROJECTION.PAYMENT.AMOUNT:

    START.DATE = PS.HOLIDAY.START.DATES<PROP.POS>
    END.DATE = PS.HOLIDAY.END.DATES<PROP.POS>
    
    IF ((PAYMENT.DATE GE START.DATE) AND (PAYMENT.DATE LE END.DATE)) OR SCHEDULE.INFO<51> THEN
*** Use Period Balance since we are in Repayment Mode and reduce it for each installment
        IF PAYMENT.PROPERTY.AMOUNT LE HOLIDAY.PROP.PROJECT.AMOUNTS<PROP.POS> THEN
*** Let due the actual Property amount and reduce it from the Outstanding Balance
            IF PAYMENT.DATE EQ END.DATE THEN
                PAYMENT.PROPERTY.AMOUNT = HOLIDAY.PROP.PROJECT.AMOUNTS<PROP.POS>
                HOLIDAY.PROP.PROJECT.AMOUNTS<PROP.POS> = 0      ;* Reset to zero. So, if any sub sequence schedules those would not be collected
            END ELSE
                IF NOT(HOL.PROP.LAST.PAYMENT.DATE) OR PAYMENT.DATE GT HOL.PROP.LAST.PAYMENT.DATE THEN
                    HOLIDAY.PROP.PROJECT.AMOUNTS<PROP.POS> = HOLIDAY.PROP.PROJECT.AMOUNTS<PROP.POS> -  PAYMENT.PROPERTY.AMOUNT
                END
            END
        END ELSE
            PAYMENT.PROPERTY.AMOUNT = HOLIDAY.PROP.PROJECT.AMOUNTS<PROP.POS>
            HOLIDAY.PROP.PROJECT.AMOUNTS<PROP.POS> = 0      ;* Reset to zero. So, if any sub sequence schedules those would not be collected
        END
    END ELSE
***Hol interest for the payment date before the start date should be excluded from the total hol amount, or it will persist until the end date and cause an incorrect amount in the final schedule.
        IF PAYMENT.DATE EQ FORWARD.PS.DATE AND PAYMENT.PROPERTY.AMOUNT AND DEFER.HOLIDAY.PERIOD AND ECB.HOL.AMT THEN
            HOLIDAY.PROP.PROJECT.AMOUNTS<PROP.POS> = HOLIDAY.PROP.PROJECT.AMOUNTS<PROP.POS> -  PAYMENT.PROPERTY.AMOUNT
        END
    END
                        
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name = populate period start & end date for participants >
*** <desc>populate period start & end date for participants</desc>
GET.PARTICIPANT.PERIOD.START.END.DATE:

    BEGIN CASE
        CASE RISK.MARGIN.PROPERTY OR SKIM.FLAG
            LOCATE PAYMENT.PROPERTY IN BORROWER.PROPERTY.LIST<1, PAY.TYPE.I, 1> SETTING RPPOS THEN
                PERIOD.START.DATE = BORROWER.PERIOD.START.DATE<1, PAY.TYPE.I, RPPOS>            ;* get start and end date from risk margin or skim property prop pos
                PERIOD.END.DATE = BORROWER.PERIOD.END.DATE<1, PAY.TYPE.I, RPPOS>
            END
        CASE 1
            PERIOD.START.DATE = BORROWER.PERIOD.START.DATE<1,PAY.TYPE.I,PROPERTY.I>         ;* get borrower start and end date
            PERIOD.END.DATE = BORROWER.PERIOD.END.DATE<1,PAY.TYPE.I,PROPERTY.I>
    END CASE
   
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name = populate period start & end date for participants >
*** <desc>populate last payment date for participants</desc>
GET.PARTICIPANT.LAST.PAYMENT.DATE:
    
    BEGIN CASE
        CASE RISK.MARGIN.PROPERTY OR SKIM.FLAG
            LOCATE PAYMENT.PROPERTY IN BORROWER.PROPERTY.LIST<1, PAY.TYPE.I, 1> SETTING RPPOS THEN
                LAST.PAYMENT.DATE = BORROWER.LAST.PAYMENT.DATE<1, PAY.TYPE.I, RPPOS>         ;* get last payment date from risk margin or skim property prop pos
            END
        CASE 1
            LAST.PAYMENT.DATE = BORROWER.LAST.PAYMENT.DATE<1,PAY.TYPE.I,PROPERTY.I>             ;* get borrower last payment date
    END CASE

RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name = Set Cache Details >
*** <desc>Set the cache details</desc>
SET.CACHE.DETAILS:
    
    UPDATE.CACHE = ''
    IF CONTRACT.ID<34> THEN ;*for cache update called from process activites set flag to skip update
        SCHEDULE.INFO<77> = 1
    END
    IF PRODUCT.LINE EQ "LENDING" AND NOT(AA.MarketingCatalogue.getPrdScheduleProjector()) AND NOT(REQD.END.DATE OR NO.CYCLES) AND (NOT(PARTICIPANTS.DETAILS<1>) OR (MAXIMUM(AA.Framework.getAccountDetails()<AA.PaymentSchedule.AccountDetails.AdHolidayDate>) GT EFFECTIVE.DATE)) AND NOT(SCHEDULE.INFO<71>) AND NOT(RESIDUAL.AMOUNTS<1,1>) AND NOT(SCHEDULE.INFO<18>) AND NOT(AA.SIM.REF) AND NOT(MASTER.ACT.CLASS EQ "RESTRUCTURE-BALANCE.MAINTENANCE") AND NOT(CAP.PAYMENT.AMOUNT.LIST) AND NOT(TOTAL.NEG.AMT) AND NOT(R.ACCRUAL.DETAILS<AA.Interest.InterestAccruals.IntAccProfitRate,1>) AND NOT(SCHEDULE.INFO<53>) THEN
        CURRENT.COMPANY = EB.SystemTables.getIdCompany() ;* Get the current company
        R.AA.PARAMETER = AA.Framework.AaParameter.CacheRead(CURRENT.COMPANY, "")
        IF NOT(R.AA.PARAMETER) THEN
            R.AA.PARAMETER = AA.Framework.AaParameter.CacheRead("SYSTEM","" ) ;* Read SYSTEM record from AA.PARAMETER table if no company specific record
        END
        UPDATE.CACHE = R.AA.PARAMETER<45> EQ "YES"
    END

    IF AA.MarketingCatalogue.getPrdScheduleProjector() OR UPDATE.CACHE THEN
        AA.PaymentSchedule.CacheScheduleProjection(ARRANGEMENT.ID,PAYMENT.DATES,PAYMENT.TYPES,PAYMENT.METHODS,PAYMENT.AMOUNTS,PAYMENT.PROPERTIES,PAYMENT.PROPERTIES.AMT,TAX.DETAILS,OUTSTANDING.AMOUNT,PAYMENT.BILL.TYPES,PAYMENT.DEFER.DATES,PAY.FIN.DATES,RESERVED2,RESERVED3,
        '','','','','','','','','','','','')
    END

RETURN
***
*-------------------------------------------------------------------
*** <region name = Get Tot Balances >
*** <desc>Get Tot Balances</desc>
GET.TOT.BALANCES:
    TOT.TERM.BAL = ''
    CUR.PROPERTY = TERM.AMT.PROPERTY
    PARTICIPANT = PART.ID<1,PART.COUNT>
    IF FIELD(PARTICIPANT, '-', 2) THEN
        CUR.PROPERTY<6> = FIELD(PARTICIPANT, '-', 2)
    END
    GOSUB GET.PARTICIPANT.ACCT.MODE     ;* Send Participant AcctMode to get Balance build.
    DATE.OPTIONS<7> = PART.ACCT.MODE<1,PART.COUNT>
    DATE.OPTIONS<8> = '1'
    IF FIELD(PARTICIPANT, '-', 1) EQ 'BOOK' THEN
        IF IS.PORTFOLIO THEN
            PARTICIPANT = GlCustomer:'*':FIELD(PARTICIPANT, '-', 2)
        END ELSE
            PARTICIPANT = GlCustomer
        END
    END
    IF PART.PARTICIPANT.TYPE<1,PART.COUNT> THEN
        DATE.OPTIONS<10> = 'RISK.PARTICIPANT'    ;* Send Risk Participant flag to get Balance build.
    END

    ACCOUNT.ID = ACCOUNT.ID:'*':PARTICIPANT
    AA.ProductFramework.PropertyGetBalanceName(ARRANGEMENT.ID, CUR.PROPERTY, "TOT", "", "", TOT.TERM.BAL)
    AA.Framework.GetPeriodBalances(ACCOUNT.ID, TOT.TERM.BAL, DATE.OPTIONS, PAYMENT.DATE, "", "", BAL.DETAILS, "")
    PART.TOT.TERM.AMT = ABS(BAL.DETAILS<AC.BalanceUpdates.AcctActivity.IcActBalance>)           ;* Participant Tot Commitment
        
    ACCOUNT.ID = SAVE.ACCOUNT.ID
    DATE.OPTIONS<7> = ''
    DATE.OPTIONS<8> = ''
    DATE.OPTIONS<10> = ''
    AA.ProductFramework.PropertyGetBalanceName(ARRANGEMENT.ID, TERM.AMT.PROPERTY, "TOT", "", "", TOT.TERM.BAL)
    AA.Framework.GetPeriodBalances(ACCOUNT.ID, TOT.TERM.BAL, DATE.OPTIONS, PAYMENT.DATE, "", "", BAL.DETAILS, "")
    BORROWER.TOT.TERM.AMT = ABS(BAL.DETAILS<AC.BalanceUpdates.AcctActivity.IcActBalance>)       ;* Borrower Tot Commitment
 

RETURN
***
*-------------------------------------------------------------------
*** <region name= GET.CAPTURED.AMOUNT>
GET.CAPTURED.AMOUNT:
*** <desc> Consider adjustment interest of "CAPTURE.BALANCE" activity only for prior schedules of current processing schedule</desc>

    IF NOT(ACTBAL.READ) THEN
        R.ACTIVITY.BALANCES = ''
        AA.Framework.GetActivityBalances(ARRANGEMENT.ID, R.ACTIVITY.BALANCES, '') ;* Read activity balances record
        ACTBAL.READ = 1 ;* Flag to skip GetActivityBalances call for each payment date
    END
    
    ADJ.AMT = 0
    IF R.ACTIVITY.BALANCES THEN
        PROPERTY.BALANCE.TYPE = PAYMENT.PROPERTY:".ACC":PAYMENT.PROPERTY

*** Consider adjustment interest of "CAPTURE.BALANCE" activity only for prior schedules of current processing schedule
        LOCATE PERIOD.START.DATE IN R.ACTIVITY.BALANCES<AA.Framework.ActivityBalances.ActBalActivityDate, 1> BY "AN" SETTING ACT.START.POS THEN
        END
                    
        LOCATE PERIOD.END.DATE IN R.ACTIVITY.BALANCES<AA.Framework.ActivityBalances.ActBalActivityDate, 1> BY "DN" SETTING ACT.END.POS ELSE
            IF ACT.END.POS GT 1 THEN
                ACT.END.POS -= 1
            END
        END

        FOR PROP.BAL.I = ACT.START.POS TO ACT.END.POS
            LOCATE PROPERTY.BALANCE.TYPE IN R.ACTIVITY.BALANCES<AA.Framework.ActivityBalances.ActBalProperty, PROP.BAL.I, 1> SETTING PROP.BAL.POS THEN
                ADJ.AMT += (R.ACTIVITY.BALANCES<AA.Framework.ActivityBalances.ActBalPropertyAmt, PROP.BAL.I, PROP.BAL.POS>) * -1
            END
        NEXT PROP.BAL.I
                        
        IF ADJ.AMT THEN
            INT.AMOUNT = CURR.INT.AMOUNT + ADJ.AMT
        END
    END
      
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= TAX.CALCULATION.FOR.PROCESS.TAX>
*** <desc> Do tax calculation for container properties </desc>
TAX.CALCULATION.FOR.PROCESS.TAX:

    ARRANGEMENT.INFO<8> = 1     ;* Flag to indicate transaction processing
    PAYMENT.AMT.LIST.CNT = DCOUNT(BORROWER.PAYMENT.AMOUNT.LIST, @VM)
    
    FOR PAYMENT.AMT.LIST = 1 TO PAYMENT.AMT.LIST.CNT
        BASE.AMOUNT = SUM(BORROWER.PAYMENT.AMOUNT.LIST<1,PAYMENT.AMT.LIST>)     ;* Sum of the total bill amount
        IF SCHEDULE.INFO<8> THEN
*** There's no need to pass all the payment types at once. Since we are iterating through each payment amount, we can pass the payment types one at a time.
*** Payment schedule record will include all payment types. however, the disbursement payment type will be excluded from processing. Therefore, use payment.type.list, as it holds the current payment types.
            ARRANGEMENT.ID<5,1> = PAYMENT.TYPE.LIST<1,PAYMENT.AMT.LIST> ;* Sending the payment type inorder to get the tax informations only if the call is from projection
            ARRANGEMENT.ID<5,2> = PAYMENT.DATE ;* Sending the payment date inorder to get the tax informations from correct bills only if the call is from projection
        END
        TRANS.TAX.PROPERTIES = "" ; TOT.TRANS.TAX.AMOUNT = 0
        AA.Tax.CalculateTax(ARRANGEMENT.ID , EFFECTIVE.DATE , TAX.PROPERTIES<TAX.COUNT> , BASE.AMOUNT , TRANS.TAX.PROPERTIES , ARRANGEMENT.INFO, TRANS.TAX.AMOUNTS , TRANS.TAX.AMOUNT.LCY , PROCESSTYPE, RET.ERROR)        ;*Calculate tax for the total bill amount
        TAX.SM.COUNT = DCOUNT(TRANS.TAX.PROPERTIES,@SM)
        FOR SM.CNT = 1 TO TAX.SM.COUNT
            IF TRANS.TAX.AMOUNTS<1,1,SM.CNT> THEN
                TRANS.TAX.LIST<SM.CNT,AA.Tax.TxBaseProp> = "TRANSACTION"
                TRANS.TAX.LIST<SM.CNT,AA.Tax.TxTaxProp> = TRANS.TAX.PROPERTIES<1,1,SM.CNT>    ;* Will be seperated by "SM".
                TRANS.TAX.LIST<SM.CNT,AA.Tax.TxTaxAmt> =  TRANS.TAX.AMOUNTS<1,1,SM.CNT>    ;* Corresponding tax amounts for the tax Properties.
                IF TRANS.TAX.AMOUNT.LCY THEN
                    TRANS.TAX.LIST<SM.CNT,AA.Tax.TxTaxAmtLcy> = TRANS.TAX.AMOUNT.LCY<1,1,SM.CNT>      ;*Tax amount in local currency
                END
                TOT.TRANS.TAX.AMOUNT += TRANS.TAX.AMOUNTS<1,1,SM.CNT> ;* Total transaction tax amount for a payment type
                UPDATE.TRANSACTION.TAX = 1
            END
        NEXT SM.CNT
        
        IF UPDATE.TRANSACTION.TAX THEN
            IF GROSS.ACCOUNT.PAY<1, PAYMENT.AMT.LIST> AND PAY.BILL.TYPE NE "DISBURSEMENT" THEN
                BORROWER.PAYMENT.AMOUNT.LIST<1,PAYMENT.AMT.LIST> += ABS(TOT.TRANS.TAX.AMOUNT) ;* For Gross Account Pay, add the transaction tax to the account property of the payment type
            END
            BORROWER.TAX.DETAILS.LIST<1,PAYMENT.AMT.LIST,-1> = LOWER(LOWER(TRANS.TAX.LIST)) ;*Adding the transaction tax in the respective position based on Payment type
        END
    NEXT PAYMENT.AMT.LIST
    
    ARRANGEMENT.INFO<8> = ""
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= GET.LINKED.PORTFOLIO.ID>
*** <desc> Get linked portfolio Id </desc>
GET.LINKED.PORTFOLIO.ID:
    
    LINKED.PF = ''
    IF LINKED.PORTFOLIO.LIST<1,1> THEN
        LOCATE CHECK.RP.ID IN RP.LIST<1,1> SETTING RPPOS THEN
            LINKED.PF = LINKED.PORTFOLIO.LIST<1,RPPOS>          ;* populate linked portfolio for risk participants processing
        END
    END
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= GET.SHARE.TRANSFER.DATE>
*** <desc>Get share transfer activity date</desc>
GET.SHARE.TRANSFER.DATE:
    
** We might add participant property in arrangement if share transfer was triggered without participation setup. In that case we need to pass share transfer
** activity date to fetch interest information properly. So get share transfer activity date and pass it to CalcInterest for proper interest calculation.
    IF NOT(SHARE.TRANSFER.REC) THEN
        AA.ProductFramework.GetPropertyRecord("", ARRANGEMENT.ID, "", EFFECTIVE.DATE, "SHARE.TRANSFER", "",SHARE.TRANSFER.REC, "")    ;* Get share transfer property record
    END
    SHARE.ACTIVITY = SHARE.TRANSFER.REC<AA.ShareTransfer.ShareTransfer.StActivity>
    BUY.BACK = SHARE.TRANSFER.REC<AA.ShareTransfer.ShareTransfer.StBuyBack>
    POOL.ID = SHARE.TRANSFER.REC<AA.ShareTransfer.ShareTransfer.StSecuritisationPoolId>
    
    IF POOL.ID THEN
        AA.ProductFramework.GetPropertyRecord("", ARRANGEMENT.ID, "", RECORD.START.DATE, "ACCOUNT", "", REC.ACCOUNT, RET.ERR)
        IF REC.ACCOUNT<AA.Account.Account.AcBalanceTreatment> NE "PARTICIPATION" THEN
            SHARE.TRANSFER.DATE = FIELD(SHARE.TRANSFER.REC<AA.ShareTransfer.ShareTransfer.StIdCompThr>,'.',1)
            IF BUY.BACK EQ "YES" THEN
                AA.Framework.ReadActivityHistory(ARRANGEMENT.ID,"",RECORD.START.DATE, R.ACTIVITY.HISTORY)
                ACTIVITY.REF = SHARE.ACTIVITY:AA.Framework.PassbackSep:"COUNT"
                LOCATE ACTIVITY.REF IN R.ACTIVITY.HISTORY<AA.Framework.ActivityHistory.AhActivityConRef,1> SETTING ACT.POS THEN
                    ACTIVITY.DATE.LIST = R.ACTIVITY.HISTORY<AA.Framework.ActivityHistory.AhActDate,ACT.POS>
                    TOT.DATE.LIST = DCOUNT(ACTIVITY.DATE.LIST,@SM)
                    SHARE.TRANSFER.DATE = ACTIVITY.DATE.LIST<1,1,TOT.DATE.LIST>
                END
            END
        END
    END

RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= HANDLE.RESIDUAL.PROCESSING.FOR.PARTICIPANTS>
*** <desc> Handle residual processing for participants </desc>
HANDLE.RESIDUAL.PROCESSING.FOR.PARTICIPANTS:
    
    FOR PART.OS = 1 TO TOTAL.PARTICIPANTS-1
        CUR.POS.LAST.VAL = FIELD(PARTICIPANT.OUTSTANDING.AMT<NO.OF.PAYMENT.DATES>,"*",PART.OS) ;*Get each participants outstanding amount
        CUR.PART.PROP.AMOUNT = FIELD(PARTICIPANT.PROPERTIES.AMT<NO.OF.PAYMENT.DATES>,"*",PART.OS) ;*Get each participants properties amount
        IF CUR.POS.LAST.VAL AND CUR.PART.PROP.AMOUNT THEN
            CUR.PART.PROP.AMOUNT<1,VMPOS,SMPOS> = CUR.PART.PROP.AMOUNT<1,VMPOS,SMPOS>+CUR.POS.LAST.VAL ;*Add the pending outstanding amount to last schedule principal amount
            CUR.POS.LAST.VAL = CUR.POS.LAST.VAL-CUR.POS.LAST.VAL ;*Make outstanding amount as zero once added with principal
        END
        NEW.OUTSTANDING.ARRAY<PART.OS> = CUR.POS.LAST.VAL
        NEW.PROPERTIES.ARRAY<PART.OS> = CUR.PART.PROP.AMOUNT
    NEXT PART.OS
    CONVERT @FM TO "*" IN NEW.OUTSTANDING.ARRAY
    CONVERT @FM TO "*" IN NEW.PROPERTIES.ARRAY
    PARTICIPANT.OUTSTANDING.AMT<NO.OF.PAYMENT.DATES> = NEW.OUTSTANDING.ARRAY
    PARTICIPANT.PROPERTIES.AMT<NO.OF.PAYMENT.DATES> = NEW.PROPERTIES.ARRAY
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= CHECK.HOLIDAY.INTEREST.DATE.DETAILS>
*** <desc>To Check on Date details of HOLIDAY.INTEREST payment type</desc>
CHECK.HOLIDAY.INTEREST.DATE.DETAILS:
    
**Here after system will process with FORWARD.PS.RECORD when FORWARD.RECALC.DATE is present and lessthan START DATE which is in the triggered activity's payment scheuled record .
    LOCATE HOLIDAY.CUR.PROPERTY IN FORWARD.RECALC.PROPERTY<1> SETTING HOL.INT.DATE.POS THEN
        HOL.PAY.TYPE.PROP = PS.PAYMENT.TYPES<1,HOL.TYPE>:"-":HOLIDAY.CUR.PROPERTY
        LOCATE HOL.PAY.TYPE.PROP IN CURRENT.PS.PAY.TYPE.PROP.LIST<1,1> SETTING HOL.TYPE.POS THEN
            CUR.PS.START.DATE = R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsStartDate, HOL.TYPE.POS>
            IF CUR.PS.START.DATE AND NOT(CUR.PS.START.DATE MATCHES "8N") THEN
                RETURN.DATE = ''
                AA.Framework.GetRelativeDate(ARRANGEMENT.ID, CUR.PS.START.DATE, "", "", "", "", "", RETURN.DATE, '')
                CUR.PS.START.DATE = RETURN.DATE
            END
            HOL.INT.PROP.DATE = FORWARD.RECALC.DATE<HOL.INT.DATE.POS>
            IF NOT(HOL.INT.PROP.DATE) OR (HOL.INT.PROP.DATE AND HOL.INT.PROP.DATE LT CUR.PS.START.DATE) THEN
                PS.HOL.PS.START.DATE = CUR.PS.START.DATE
                PS.HOL.PS.END.DATE= R.PAYMENT.SCHEDULE<AA.PaymentSchedule.PaymentSchedule.PsEndDate, HOL.TYPE.POS>
            END
        END
    END
                
RETURN
*** </region>
*-----------------------------------------------------------------------------
GET.ACCRUALS.RECORD:
*** <region name= GET.ACCRUALS.RECORD>
*** <desc>To get accruals record from both period of normal accruals and info accruals</desc>

    R.ACCRUAL.DETAILS = '' ;NEW.ACCRUAL.DATA  = '' ;INFO.ONLY.FLAG = ''
    AA.Interest.GetInterestAccruals("VAL", ARRANGEMENT.ID, INT.PAYMENT.PROPERTY, "", NEW.ACCRUAL.DATA, R.ACCRUAL.DETAILS, "", EXTENSION.NAME)
***Amount projected in payment schedule for an interest property for which SUPPRESS.ACCRUAL has been set to INFO.ONLY. Total accrual projected holds the accrual amount from current system date.
    IF R.ACCRUAL.DETAILS<AA.Interest.InterestAccruals.IntAccInfoPeriodStart,1> THEN
        NEW.ACCRUAL.DATA  = ''
        AA.Interest.GetInterestAccruals("", ARRANGEMENT.ID, INT.PAYMENT.PROPERTY, "", NEW.ACCRUAL.DATA, R.ACCRUAL.DETAILS, "", "INFO.ONLY")
        INFO.ONLY.FLAG = 1   ;*Flag set to calculate for the interest has info only
    END
    INTEREST.DATA<1,PropPos> = INT.PAYMENT.PROPERTY
    INTEREST.DATA<2,PropPos> = LOWER(LOWER(NEW.ACCRUAL.DATA))
    INTEREST.DATA<3,PropPos> = LOWER(LOWER(R.ACCRUAL.DETAILS))
    INTEREST.DATA<4,PropPos> = INFO.ONLY.FLAG
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= CHECK.WORKING.DAYS>
CHECK.WORKING.DAYS:
*** <desc> Check Working Days</desc>

    BUS.DAYS = R.ACCOUNT<AA.Account.Account.AcBusDayCentres>         ;* For holiday checking
    IF R.ACCOUNT<AA.Account.Account.AcOtherBusDayCentre> THEN
        AA.Account.GetArrCurrencyCode(R.ACCOUNT, ARRANGEMENT.ID, BUS.DAYS, "")
    END
    
    RETURN.DATE = ""
    RETURN.CODE = ""

    ST.Config.WorkingDay("S", EFFECTIVE.DATE, "+", "0", "F", BUS.DAYS, "", RETURN.DATE, RETURN.CODE, "")
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= UPDATE.PRIMARY.PORTFOLIO.TAX.DETAILS>
UPDATE.PRIMARY.PORTFOLIO.TAX.DETAILS:
*** <desc> Update primary portfolio tax details</desc>

    IF PRIMARY.PORT.POS AND PfTaxAmount THEN    ;* When more than one portfolio is present then process the other portfolios tax amount and add it with the primary portfolio tax amount
        CONVERT "*" TO @FM IN TEMP.PARTICIPANT.TAX.DETAILS
        PRIMARY.TAX.DETAILS = TEMP.PARTICIPANT.TAX.DETAILS<PRIMARY.PORT.POS>  ;* Get portfolio Tax details
        TEMP.PRIMARY.TAX.DETAILS = RAISE(PRIMARY.TAX.DETAILS<1, PAY.TYPE.I, PROPERTY.I>)
        TEMP.PRIMARY.TAX.DETAILS<1, 1, 3> += PfTaxAmount
        PRIMARY.TAX.DETAILS<1, PAY.TYPE.I, PROPERTY.I> = LOWER(TEMP.PRIMARY.TAX.DETAILS)
        TEMP.PARTICIPANT.TAX.DETAILS<PRIMARY.PORT.POS> = PRIMARY.TAX.DETAILS
        CONVERT @FM TO "*" IN TEMP.PARTICIPANT.TAX.DETAILS
    END

RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= FETCH.ACTIVITIES.FOR.ENTERPRISE.LEVEL>
FETCH.ACTIVITIES.FOR.ENTERPRISE.LEVEL:
*** <desc> For Enterprise Level Fee calculation per activity </desc>
*** When calculating charge per unit of the activity, we need to send each transaction amount, total transaction amount and total count of the activity to CalcCharge routine.
    
    IF ENTERPRISE.LEVEL THEN
*** For calculating the charge per unit of the activity for the property, we need to find the count and txn amount of each instance of the activity in the given time period.
        AA.ActivityCharges.RefineScheduledChargeActivities(ARRANGEMENT.ID, PAYMENT.PROPERTY, START.DATE, END.DATE, CHARGE.ACTIVITIES, SOURCE.BALANCE, '')
    END
RETURN
*** </region>
*-----------------------------------------------------------------------------
*** <region name= FETCH.ACTIVITIES.FOR.ENTERPRISE.LEVEL>
GET.UTL.BALANCE.AMOUNT:
*** <desc> Get the Utilization balance </desc>
    BAL.DETAILS = ''
    CUR.PROPERTY = TERM.AMT.PROPERTY
    GOSUB GET.PARTICIPANT.ACCT.MODE     ;* Send Participant AcctMode to get Balance Name
    AA.ProductFramework.PropertyGetBalanceName(ARRANGEMENT.ID, CUR.PROPERTY, "UTL", "", "", TOT.TERM.BAL)
    AA.Framework.GetPeriodBalances(ACCOUNT.ID, TOT.TERM.BAL, DATE.OPTIONS, BALANCE.CHECK.DATE, "", "", BAL.DETAILS, "")
    SAVE.UTL.TERM.AMT<-1> = ABS(BAL.DETAILS<AC.BalanceUpdates.AcctActivity.IcActBalance>)
    
RETURN
*** </region>
*-----------------------------------------------------------------------------
END