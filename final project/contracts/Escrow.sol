pragma solidity^0.5.0;
import "./SmartLoan.sol";
import "./AssetLedger.sol";
import "./WaterFall.sol";
import "./Bond.sol";
import "./TimeSim.sol";
contract Escrow
{


/*
The Escrow Contract is responsible for establishing trust between investors and
 the Orignator i.e. the seller of the pool of loans. It makes sure that the
 pool for sale is being transferred to the AssetLedger contract (see below) as
 advertised. It also ensures that the reserve was send as advertised. Within
 the investmentperiod it waits for investments from investors and it allows a
 third party to confirm the advertised quality of the pool on behalf of the
 investors.
*/


/*
Saves the state stages of the Escrow contract
*/
struct State {
bool InvestorFundsReceivedA;
bool InvestorFundsReceivedB;
bool PoolReceived;
bool ReserveReceived;
bool ThirdPartyPoolValidation;
bool FundingPeriodOver;
bool Success;
bool Fail;}

State public CurrentState = State(false,false,false,false,
                                  false,false,false,false);
bool[8] currentState;//this is a variable used in a function for temp storage

/*
Mappings to Track investor Balances
*/
mapping (address => uint) public BalancesA;
mapping (address => uint) public BalancesB;

/*
Input variables: capital structure, reserve and InvestmentPeriod duration
*/
uint public RequiredFundsA;
uint public RequiredFundsB;
uint public ReceivedFundsA;
uint public ReceivedFundsB;
uint public ReserveRequired;
uint public ReserveReceived;
uint public InvestmentPeriodEnd;

/*
related contracts addresses
*/
address public TrustedParty;
address public Owner;//SFContract
address public Originator;
address public WaterFall;
address public Ledger;

/*
TimeSim is used for testing purposes only
*/
address public TimeAddress;//this is used for testing purposes only
TimeSim public Time;

/*
Ledger and WaterFall are created after this contract, hence their addresses
have to be passed after creation of this contract. We want them to be set once
only
*/
bool public WaterFallSet =false;
bool public LedgerSet =false;


/*
Modifiers
-------------------------------------------------------------------------------
*/
modifier OnlyFunding () {if (CurrentState.FundingPeriodOver==false)_;}
modifier OnlyFinalSuccess () {if (CurrentState.Success)_;}
modifier OnlyFinalFail () {if (CurrentState.Fail)_;}
modifier OnlyUntilAFull (){if (!CurrentState.InvestorFundsReceivedA)_;}
modifier OnlyUntilBFull (){if (!CurrentState.InvestorFundsReceivedB)_;}
modifier OnlyOwner(){if (msg.sender == Owner)_;}


/*
Constructor
-------------------------------------------------------------------------------
•	poolAccounts: This is the list of addresses of smartloans in the pool for sale
•	requiredFundsA: The notional amount of class A bonds required to sell the pool
•	requiredFundsB: The notional amount of class B bonds required to sell the pool
•	reserveRequired: The reserve to be posted by the seller of the pool to improve
  credit quality
• investmentPeriodEnd: The date at which the Escrow contract decides whether the
  transaction failed or will kick off
•	trustedParty: This is the address of the third party which analyses the pool
  on behalf of the investors
•	owner: The address of the controlling contract. This is the Securitization
  contract which deployed this contract and controlls ist behaviour
•	originator: The address of the originator (seller of the pool)
•	waterFall: The address of the WaterFall contract which is responsible for
  distribution of the funds.
*/
function Escrow (uint requiredFundsA, uint requiredFundsB,
                 uint reserveRequired, uint investmentPeriodEnd,
                 address trustedParty, address owner,
                 address originator, address time)
{
  RequiredFundsA =requiredFundsA;
  RequiredFundsB =requiredFundsB;
  ReserveRequired =reserveRequired;
  InvestmentPeriodEnd = investmentPeriodEnd;
  TrustedParty = trustedParty;
  Owner = owner;
  TimeAddress = time;
  Time = TimeSim(TimeAddress);
  Originator = originator;
}


/*
This function checks with the AssetLedger contract if the advertised pool has
been received.
*/
function PoolTransfer() OnlyFunding() public returns(bool)
{
  CurrentState.PoolReceived = AssetLedger(Ledger).PoolTransfer();
  return CurrentState.PoolReceived;
}


/*
SetWaterFallAddress() and SetLedger() are necessary because this contract is
created befoer Waterfall and Ledger, therefore we need to tell this contract
about them
*/
function  SetWaterFallAddress (address waterFallAddress) public OnlyOwner()
{
  if (WaterFallSet == true) throw;
  WaterFall = waterFallAddress;
  WaterFallSet = true;
}

function  SetLedger (address ledger) public //OnlyOwner()
{
  if (LedgerSet == true) throw;
  Ledger = ledger;
  LedgerSet = true;
}


/*
InvestorPayInA () / InvestorPayInB ():
These functions are available to investors. They allow for investments beeing
made up to the investmentlimit for each class. The investments are beeing
stored in the contract and mapped to the accounts from which they have been
received.
*/
function InvestorPayInA () OnlyFunding () OnlyUntilAFull() payable public
{
  if (msg.value<=RequiredFundsA - ReceivedFundsA)
  {
    BalancesA[msg.sender] += msg.value;
    ReceivedFundsA +=msg.value;

    if(RequiredFundsA - ReceivedFundsA==0)
    CurrentState.InvestorFundsReceivedA = true;
  }
	else {throw;}
}

function InvestorPayInB () OnlyFunding () OnlyUntilBFull()public payable
{
  if (msg.value<=RequiredFundsB - ReceivedFundsB)
  {
    BalancesB[msg.sender] += msg.value;
    ReceivedFundsB +=msg.value;

    if(RequiredFundsB - ReceivedFundsB==0)
    CurrentState.InvestorFundsReceivedB = true;
	}
  else {throw;}
}


/*
GetInvestorsBalanceA() GetInvestorsBalanceB()
These functions are used later when Bond tokens are minted. They tell the bond
token contract the amount of funds received from each investor.
These could be removed and replaced by a call from the Token directly
*/
function GetInvestorsBalanceA (address investorAddress)
OnlyFinalSuccess () public returns (uint)
{
  return BalancesA[investorAddress];
}

function GetInvestorsBalanceB (address investorAddress)
OnlyFinalSuccess () public returns (uint)
{
  return BalancesB[investorAddress];
}

/*
If the transaction is deemed to have failed after the investmentperiod,
the two functions below revert the investments of investors and sends back the reserve
and pool to the investor.
 */
function RevertInvestmentInvestor () OnlyFinalFail() public
{
  if(BalancesA[msg.sender]>0)
  {
    if(msg.sender.send(BalancesA[msg.sender])==true) BalancesA[msg.sender]=0;
        else throw;
  }

  if(BalancesB[msg.sender]>0)
  {
    if(msg.sender.send(BalancesB[msg.sender])==true) BalancesB[msg.sender]=0;
        else throw;
  }
}


function RevertInvestmentORiginator () OnlyFinalFail() public
{
  AssetLedger(Ledger).SendbackPool(Originator);
  if(Originator.send(ReserveReceived)==false) throw;
  ReserveReceived = 0;
}

//I keep this duplicate for now, cant hurt
function ReturnReserve ()  OnlyFinalFail() public
{
  if(Originator.send(ReserveReceived)) ReserveReceived =0;
    else throw;
}



/*
Checks if  time elapsed and if the transaction worked.
Has to be modified when real timestamps are used instead of a TimeSim
*/
function CheckTime() public
{
  if (Time.Now()>InvestmentPeriodEnd) CurrentState.FundingPeriodOver=true;
}


/*
This function checks and returns the status of the escrow contract.
*/
function CheckState () public returns (bool[8])
{
  currentState =[false,false,false,false,false,false,false,false];
  CheckTime();

  currentState[0]= CurrentState.InvestorFundsReceivedA;
  currentState[1]= CurrentState.InvestorFundsReceivedB;
  currentState[2]= CurrentState.PoolReceived;
  currentState[3]= CurrentState.ReserveReceived;
  currentState[4]= CurrentState.ThirdPartyPoolValidation;
  currentState[5]= CurrentState.FundingPeriodOver;

  if(currentState[0] && currentState[1] &&
     currentState[2] && currentState[3] && currentState[4])
     CurrentState.Success=true;

  if((!currentState[0]||!currentState[1]||
      !currentState[2]||!currentState[3]||
      !currentState[4])==true && currentState[5])
      CurrentState.Fail=true;

  currentState[6]= CurrentState.Success;
  currentState[7]= CurrentState.Fail;

  return currentState;
}



/*
This function allows the Originator to withdraw the funds invested by investors
after all requirements for the transaction to kick off have been fulfilled.
*/
function OriginatorWithdrawFunds () public OnlyFinalSuccess ()
{
  if(Originator.send(ReceivedFundsA+ReceivedFundsB))
  {
    ReceivedFundsA=0;
    ReceivedFundsB=0;
  }
  else throw;
}


/*
Lets the originator pay the reserve as advertised.
*/
function PayReserve () OnlyFunding () public payable
{
  ReserveReceived += msg.value;
  if (ReserveReceived >= ReserveRequired) CurrentState.ReserveReceived =true;
}

/*
Sends the Reserve to the Waterfall
*/
function SendReserve (address waterFallAddress)public OnlyFinalSuccess OnlyOwner
{
  if(waterFallAddress.send(ReserveReceived))  ReserveReceived=0;
  else throw;
}

/*
Lets A third Party Confirm Validity of Claimed Pool - Only One of the Validated
Parties
*/  function PoolValid () public
{
  if (msg.sender == TrustedParty) CurrentState.ThirdPartyPoolValidation =true;
}

}
