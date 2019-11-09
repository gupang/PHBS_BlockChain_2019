pragma solidity^0.5.0;
import "./SmartLoan.sol";
import "./TimeSim.sol";

contract AssetLedger
{
/*
TO DO:
The algo of the WithdrawDueLoans() func can be improved
It is possible to use variable lenght arrays now which should be used here
*/

/*
  The asset ledger manages and keeps track of all the SmartLoans contracts sold
  by the originator.
*/

/*
Variables
-------------------------------------------------------------------------------
*/

//Information on individual loans
address [2]  public AccountAddress;
uint  [2]  public OBAL;
uint  [2]  public CBAL;
uint  [2]  public LastPaymentDate;
uint  [2]  public Nextpaymentdate =[now -1,now -1];
uint  [2]  public IntpaidIn;
uint  [2]  public Prinpaidin;
uint  [2]  public RecoveriesPaidin;
//uint  [2]  public TotalRecoveries;
uint  [2]  public OverdueDays;
bool  [2]  public Default =[false,false];
uint  [10] public InitialLoaninfo;

/*InitialLoaninfo has the following entries
1  [OverdueDays,
2  OriginalBalance,
3  CurrentBalance,
4  NextPaymentDate,
5  intPaidIn,
6  prinPaidIn,
7  MonthlyInstallment,
8  InterestRateBasisPoints,
9  OriginalTermMonths,
10  RemainingTermMonths];
*/

//Periodical Information on the Pool
uint  public PrincipalThisPeriod;
uint  public InterestThisPeriod;
uint  public RecoveriesThisPeriod;
uint  public DefaultThisPeriod;
uint [4] public PeriodicInfo;

//Cumulative Information on the Pool
uint  public PrincipalCum;
uint  public InterestCum;
uint  public RecoveriesCum;
uint  public DefaultCum;
uint  public LoansRepaid;
uint  public OriginalNumberOfLoans;
uint  public OriginalPoolBalance;
uint  public CurrentlPoolBalance;

//Adresses of contracts to interact with
address public Controller;// this is the SFContract
address public TimeAddress;
address public WaterFall;
address public ThisAddress = this;

//Instances of other contracts used by the code
SmartLoan public Loan;
TimeSim public Time;

//State Variables
bool public PoolTransfer = false;
bool public waterFallset = false;

/*
Modifiers
-------------------------------------------------------------------------------
*/
modifier OnlyController {if (msg.sender == Controller) _;}
modifier OnlyWaterFall {if (msg.sender == WaterFall) _;}
modifier IfPoolNotTransferred {if (!PoolTransfer) _;}


/*
Constructor
-------------------------------------------------------------------------------
•	accountAddresses: A list of all the adresses of SmartLoans sold by the
  originator
•	originalPoolBalance: The aggregate balance of all SmartLoans at the time
  of transferral
•	numberOfLoans: The aggregate number of  SmartLoans transferred
•	controller: This is the Address of another contract which is allowed to
  give instructions to this contract. This is the "Securitization" contract
  mentioned above
*/

function AssetLedger(address [2] accountAddresses, uint originalPoolBalance,
                     uint numberOfLoans,address controller, address timeAddress)
{
  TimeAddress = timeAddress;
  Time = TimeSim(TimeAddress);
  Controller =controller;
  OriginalNumberOfLoans = numberOfLoans;
  AccountAddress = accountAddresses;
  OriginalPoolBalance = originalPoolBalance;
  CurrentlPoolBalance = originalPoolBalance;
}


/*
Functions
-------------------------------------------------------------------------------
*/


/*
This function tells the AssetLedger Contract who is allowed to
withdraw the funds. This is the WaterFall contract which is explained below.
*/
function WaterFallset (address waterfallAddress) OnlyController
{
  if(waterFallset== true) throw;
	WaterFall = waterfallAddress;
	waterFallset= true;
}

/*
This function is used by the Escrow contract and verifies that the pool of
loans for sale has actually been transferred as advertised.
*/
function PooTransferred () public returns(bool)
{
  for (uint i = 0; i < OriginalNumberOfLoans; i++)
  {
    Loan = SmartLoan(AccountAddress[i]);
    if(Loan.LenderAddress()!=ThisAddress)
    {
	     PoolTransfer = false;
	     return PoolTransfer;
    }
    OBAL[i]	=	Loan.OriginalBalance();
    CBAL[i]	=	Loan.CurrentBalance();
  }

  PoolTransfer = true;
  return PoolTransfer;
}


/*
Sends back the pool to the Originator if the Escrow contract has
*/
function SendbackPool(address newLender) public OnlyController
{
  for (uint i=0; i<OriginalNumberOfLoans; i++)
  {
      Loan = SmartLoan(AccountAddress[i]);
      Loan.Transfer(newLender);
  }
}

/*
This function just returns the accountAddresses, explore where this is used
and delete
*/
function GetLoans() public returns(address[2])
{
  return AccountAddress;
}



/*
This function withdraws funds from SmartLoans which became due since the last
 withdrawal. Withdrawals are being made in a scheduled frequency. One important
question to be considered and tested is how the limitations of the Blockchain
(block size and computational cost) affect this function when thousands of
loans would be due at once.

After withdrawal of funds, this function updates a ledger which keeps track of
each individual loan as well as aggregate information of the pool.

If this function fails to withdraw funds sufficiently often from a loan,
it decides whether the loan is to be considered defaulted. Funds received from
defaulted loans are classified as recoveries.
*/
function WithdrawDueLoans () public payable OnlyController returns(uint[12])
{
//loop over all loans
for (uint j = 0; j < OriginalNumberOfLoans; j++)
{
  //select the ones that are due
  if (Time.Now() > Nextpaymentdate[j])
  {
    Loan = SmartLoan(AccountAddress[j]);
    //call the withdraw function of the loan and fill the InitialLoaninfo array
    InitialLoaninfo = Loan.WithdrawIntPrin();

         //update the loanbyloan info
         //determine if already default/new default
      if (InitialLoaninfo[0]>=180)
      {
          RecoveriesPaidin[j] =InitialLoaninfo[4]+InitialLoaninfo[5] ;
          //TotalRecoveries[j] +=RecoveriesPaidin[j] ;
          RecoveriesThisPeriod+=RecoveriesPaidin[j];
          OverdueDays [j] = InitialLoaninfo[0];
          if(InitialLoaninfo[0]==180) DefaultThisPeriod +=InitialLoaninfo[2];
       }

          //if not default:
      else
      {
        OverdueDays [j] = InitialLoaninfo[0];

//        if(OverdueDays [j]==0)
//          {
            CBAL[j]-=InitialLoaninfo[5];
            LastPaymentDate[j]=Nextpaymentdate[j];
            Nextpaymentdate[j] = now + 30 days;
            IntpaidIn [j] = InitialLoaninfo[4];
            Prinpaidin [j] = InitialLoaninfo[5];
            OverdueDays [j] = InitialLoaninfo[0];
//          }
/*
        else
         {
            Nextpaymentdate[j] = now + 30 days;
            OverdueDays [j] = InitialLoaninfo[0];
         }
*/
         if(CBAL[j]==0) LoansRepaid ++;


      }//end of condition not defualt

   PrincipalThisPeriod+= Prinpaidin [j];
   InterestThisPeriod+= IntpaidIn [j];
   PrincipalCum+=Prinpaidin [j];
   InterestCum+=IntpaidIn [j];
   RecoveriesCum+=RecoveriesPaidin[j];

   CurrentlPoolBalance-=Prinpaidin [j];
    }//End of condivion Loandue
  }//End of loop
DefaultCum +=DefaultThisPeriod;
return
[PrincipalThisPeriod,
InterestThisPeriod,
RecoveriesThisPeriod,
DefaultThisPeriod,
PrincipalCum,
InterestCum,
RecoveriesCum,
DefaultCum,
LoansRepaid ,
OriginalNumberOfLoans ,
OriginalPoolBalance ,
CurrentlPoolBalance];
}


/*
This function lets the controller address ("Securtization" Contract) send the
funds stored in this contract to the WaterFall contract. Along with the funds,
 statusinformation is being passed:
*/
function SendFunds() OnlyWaterFall public returns (uint[4])
{
  PeriodicInfo[0] = PrincipalThisPeriod;
  PeriodicInfo[1] = InterestThisPeriod;
  PeriodicInfo[2] = RecoveriesThisPeriod;
  PeriodicInfo[3] = DefaultThisPeriod;

  if(WaterFall.send(PeriodicInfo[0]+PeriodicInfo[1]
     +PeriodicInfo[2])==false) throw;

  PrincipalThisPeriod=0;
  InterestThisPeriod=0;
  RecoveriesThisPeriod=0;
  DefaultThisPeriod=0;

  return PeriodicInfo;
}

/*
Fallback allows funds to be sent to the contract
*/
function () payable {}

}
