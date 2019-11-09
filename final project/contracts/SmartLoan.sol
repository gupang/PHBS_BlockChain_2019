pragma solidity^0.5.0;

import "./TimeSim.sol";
contract SmartLoan
{

/*
The SmartLoan contract represents the loan which the originator grants to the
borrowers. The originator sends the loan balance to the borrower and deploys the
contract code on the blockchain. The code allows to track the loan, to make
payments to the loan and to withdraw funds from it.
*/

/*
Variables
-------------------------------------------------------------------------------
*/
uint public OriginalBalance;
uint public CurrentBalance;
uint public IntPaidIn;
uint public PrinPaidIn;
uint public MonthlyInstallment;
uint public InterestRateBasisPoints;
uint public OriginalTermMonths;
uint public RemainingTermMonths;
uint public NextPaymentDate;
uint public PaymentsMade;
uint public OverdueDays;

uint public Now;
uint [120] public PaymentDates;


bool public ContractCurrent = true;

address public LenderAddress;
address public TimeAddress;

TimeSim Time;


/*
Modifiers
-------------------------------------------------------------------------------
*/
modifier OnlyLender {if (msg.sender == LenderAddress) _;}
modifier monthlyInstallment {if (msg.value == MonthlyInstallment)_;}



/*
Constructor
-------------------------------------------------------------------------------
•	lenderAddress: This is the adress of an account on the blockchain. The account
 can be controlled by a human or another contract. Whoever controls this account
 is allowed to withdraw paidin funds from the Smartloan contract.
•	balance: The principal balance of the loan which must be repaid by the
  borrower
•	interestRateBasisPoints: The interstate charged on the loan. It is given in
  basispoints i.e. the input for 5% interest would be 500
•	termMonths: The term of the loan in moths. In this implementation fixed to 12.
*/
function SmartLoan (address lenderAddress, uint balance,
                    uint interestRateBasisPoints, uint termMonths
                    , address timeAddress)
{
  LenderAddress = lenderAddress;
  TimeAddress=timeAddress;
  OriginalBalance = balance;
  CurrentBalance = balance;
  InterestRateBasisPoints = interestRateBasisPoints;
  OriginalTermMonths = termMonths;
  RemainingTermMonths =termMonths;
  Time = TimeSim(timeAddress);

/*
the calculation of the monhtly installment needs divions. Since floats are not
availabe, we make the calc in a way to reduce rounding error:
*/
uint MonthlyInstallment1 = (interestRateBasisPoints*
                           (10000* termMonths+interestRateBasisPoints)
                           **termMonths)/1000000;
uint MonthlyInstallment2 = ((10000*termMonths+interestRateBasisPoints)
                          **termMonths*10000*termMonths-10000
                          **(termMonths+1)*termMonths**(termMonths+1))/1000000;

if (MonthlyInstallment2!=0) MonthlyInstallment = balance * (MonthlyInstallment1) / (MonthlyInstallment2+1);


	if (MonthlyInstallment2!=0) MonthlyInstallment = balance *  MonthlyInstallment1 / (MonthlyInstallment2+1);

  for (uint k =0; k< termMonths; k++){PaymentDates [k] = now + (k+1) * 30 days;}

  NextPaymentDate = PaymentDates[0];
}

/*
Function to read the state
*/
function Read () returns (uint[11])
{
  return [OverdueDays,
          OriginalBalance,
          CurrentBalance,
          NextPaymentDate,
          IntPaidIn,
          PrinPaidIn,
          MonthlyInstallment,
          InterestRateBasisPoints,
          OriginalTermMonths,
          RemainingTermMonths,
          this.balance];
	}

/*
selfexplanatory
*/
function ReadTime () public returns(address){return TimeAddress;}

/*
Updates the state after installment is paid in
*/
function ContractCurrentUpdate() private returns(uint)
{
  PaymentsMade = OriginalTermMonths - RemainingTermMonths;
  NextPaymentDate=PaymentDates[PaymentsMade];

  if (Time.Now()> NextPaymentDate && RemainingTermMonths !=0)
  {
    ContractCurrent = false;
    OverdueDays = (Time.Now() - NextPaymentDate)/(60*60*24);
    return OverdueDays;
  }

  OverdueDays = 0;
  ContractCurrent = true;
  return OverdueDays;
}


/*
This function is essential for transfer of ownership. The lenderAddress owner
has the option to grant its rights to withdraw funds from the loan to another
party. In our case this will be another contract on the blockchain to which the
originator "sells " the loan.
*/
function Transfer(address NewLender) public OnlyLender()
{LenderAddress = NewLender;}


/*
Allows the borrower to pay an installment. The installments are of equal size
depending on the interest rate, original balance and loanterm. The installment
has an interest and a principal portion, it is not possible to pay more or less
than one installment by using this function. Upon payment of the installment,
the contract updates its status information (see below).
*/
function PayIn() public payable
{
  uint Principal;
  uint Interest;

  if (msg.value != MonthlyInstallment) throw;
  if (RemainingTermMonths == 0) throw;

  RemainingTermMonths --;
  Principal = CalculatePVOfInstallment (OriginalTermMonths-RemainingTermMonths);
  Interest = MonthlyInstallment - Principal;
  CurrentBalance -=Principal;
  IntPaidIn += Interest;
  PrinPaidIn +=Principal;

  ContractCurrentUpdate();
}

/*
Allows the lenderAddress owner to withdraw funds from the contract. This
function also passes along the status of the loan.
*/
function WithdrawIntPrin() public OnlyLender returns (uint[10])
{
  uint intPaidIn = IntPaidIn;
  uint prinPaidIn = PrinPaidIn;

  OverdueDays = ContractCurrentUpdate();

  if(LenderAddress.send(IntPaidIn + PrinPaidIn)==false) throw;

  IntPaidIn = 0;
  PrinPaidIn = 0;

  return [OverdueDays,
          OriginalBalance,
          CurrentBalance,
          NextPaymentDate,
          intPaidIn,
          prinPaidIn,
          MonthlyInstallment,
          InterestRateBasisPoints,
          OriginalTermMonths,
          RemainingTermMonths];
}

/*
Function used for Present Vaule calc in the Principal portion calculation
*/
function CalculatePVOfInstallment (uint periods) public returns (uint)
{
uint PV = MonthlyInstallment * (10000*OriginalTermMonths)**periods/
          (10000*OriginalTermMonths+InterestRateBasisPoints)**periods;

return PV;
}

}
