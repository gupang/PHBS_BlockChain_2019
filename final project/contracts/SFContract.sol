pragma solidity^0.5.0;
import "./SmartLoan.sol";
import "./AssetLedger.sol";
import "./WaterFall.sol";
import "./Bond.sol";
import "./BondA.sol";
import "./BondB.sol";
import "./Escrow.sol";

contract SFContract
{

/*
This is the central contract which schedules the processes and should be the
interface for the users (dunring funding some interface functions are executed
Escrow.sol too)
*/

/*
Variables
-------------------------------------------------------------------------------
*/

/*
Captures the state of the overall transaction
*/
struct State {
bool LedgerAndEscrowCreated;
bool EscrowSuccess;
bool EscrowFail;
bool BondsAndWaterFallCreated;
mapping (address => bool) InvestorWithdrawn;
}

State public SecuritisationState = State(false,false,false,false);

bool [8] public EscrowState;

/*
Balances and fundamentals
*/
uint public OriginalPoolBalance;
uint public NumberOfLoans;
uint public ClassAInitialBal;
uint public ClassAInterestRateBPS;
uint public ClassBInitialBal;
uint public ClassBInterestRateBPS;
uint public ReserveRequired;
uint public InvestmentPeriodEnd;

uint[8] public ReadNumbersOutput;//used for a function as temp var

/*
related accounts
*/
address [2] public AccountAddresses;
address public TrustedParty;
address public Owner;
address public Originator;
address public ExcessFundsReceiver;
address public PoolAdd;

address[13] ReadAddressesOutput;//used for a function as temp var


/*
related conract adresses
*/
address public EscrowAddress;
address public AssetLedgerAddress;
address public WaterFallAddress;
address public ClassABondAddress;
address public ClassBBondAddress;
address public TimeAddress;

/*
instances of related contracts
*/
Escrow public EscrowAccount;
AssetLedger public AssetLedgerAccount;
WaterFall public WaterFallAccount;
BondA public ClassABond;
BondB public ClassBBond;
//BondExcess public ClassSubClass;
TimeSim public Time;


/*
Modifiers
-------------------------------------------------------------------------------
*/
modifier OnlyAfterEscrowLedgerCreated()
{if (SecuritisationState.LedgerAndEscrowCreated == true)_;}

modifier OnlyAfterEscrowSuccess()
{if (SecuritisationState.EscrowSuccess == true) _;}

modifier NotAfterEscrowFail() {if(SecuritisationState.EscrowFail == false) _;}

modifier OnlyAfterBondsAndWaterFall()
{if(SecuritisationState.BondsAndWaterFallCreated == true)_;}



/*
Constructor
-------------------------------------------------------------------------------
•	accountAddresses: the adresses of loans (for simplicity, we assume that the
   loans are settled over the blockchain, see the SmartLoan contract herof)
•	OriginalPoolBalance: the aggregate balance of the loans in the pool to be sold
•	NumberOfLoans: the number of loans in the pool
•	ClassAInitialBal: The aggregate balance of class A Bonds to be issued
•	ClassAInterestRateBPS: The inerestrate which class A Bondholders recveive
•	ClassBInitialBal: The aggregate balance of class B Bonds to be issued
•	ClassBInterestRateBPS: The inerestrate which class A Bondholders receive
•	ReserveRequired: The originator can specifiy a reserve which will increase
  creditenhancement of the structure
•	InvestmentPeriodEnd: The duration of the period in which investors can
  subscribe to bonds. If funding is successful the structure will start, if not
 investors can reclaim their investment
•	TrustedParty: The address of third party which conducts an audit/analysis of
the pool and structure.
•	ExcessFundsReceiver: The address off a party which is allowed to withdraw
  excess funds from the structure
*/
function SFContract (address [2] accountAddresses ,uint originalPoolBalance,
                     uint numberOfLoans, uint classAInitialBal,
                     uint classAInterestRateBPS, uint classBInitialBal,
                     uint classBInterestRateBPS, uint reserveRequired,
                     uint investmentPeriodEnd,address trustedParty,
                     address originator, address excessFundsReceiver,
                    address pool,address time)
{
  TimeAddress =time;
	Time = TimeSim(TimeAddress);
  AccountAddresses =accountAddresses;
  OriginalPoolBalance =originalPoolBalance;
  NumberOfLoans = numberOfLoans;
  ClassAInitialBal = classAInitialBal;
  ClassAInterestRateBPS = classAInterestRateBPS;
  ClassBInitialBal = classBInitialBal;
  ClassBInterestRateBPS = classBInterestRateBPS;
  ReserveRequired = reserveRequired;
  InvestmentPeriodEnd = investmentPeriodEnd;
  TrustedParty = trustedParty;
  Owner = this;
	PoolAdd = pool;
	ExcessFundsReceiver = excessFundsReceiver;
  Originator = originator;
}

/*
creates two contracts:
•	A ledger that packages a pool of SmartLoans and allows to interact with
  this pool (withdraw funds and read information)
•	An escrow contract which waits for all transaction prerequisites to be
  satisfied:
-Pool of loans has been transferred into the ledger as specified
-Investor funds are received
-A third party has reviewed the pool and structure and approved claimed
 properties
-The reserve has been received as specified

*/
function CreateEscrowAndLedger(address escrowAddress, address ledgerAddress) public
{
  if (SecuritisationState.LedgerAndEscrowCreated == true) throw;


  EscrowAccount = Escrow(escrowAddress);
  AssetLedgerAccount = AssetLedger(ledgerAddress);
  EscrowAddress = escrowAddress;
  AssetLedgerAddress = ledgerAddress;
  SecuritisationState.LedgerAndEscrowCreated = true;
}


/*
check the state of the escrow contract:
*/
function CheckEscrow () public OnlyAfterEscrowLedgerCreated()
{
  EscrowState= EscrowAccount.CheckState();
/*
Elements of EscrowAccount.CheckState():
//currentState[0]= CurrentState.InvestorFundsReceivedA;
//currentState[1]= CurrentState.InvestorFundsReceivedB;
//currentState[2]= CurrentState.PoolReceived;
//currentState[3]= CurrentState.ReserveReceived;
//currentState[4]= CurrentState.ThirdPartyPoolValidation;
//currentState[5]= CurrentState.FundingPeriodOver;
//currentState[6]= CurrentState.Success;
//currentState[7]= CurrentState.Fail;
*/
  if (EscrowState[6]) {SecuritisationState.EscrowSuccess =true;}
  if (EscrowState[7]) {SecuritisationState.EscrowFail =true;}
}


/*
Once the escrow conditions are satisified, a numer of other contracts are being
created:
•	Bond Contracts for each class of investors which mint Bond tokens and allow
  the tokenholder to withdraw funds from the transaction.
•	A waterfall contract which takes funds and cashflow information from the
  Legder and calculates how the funds are to be distributed among bondholders.
*/
function CreateBondsAndWaterFall (address AbondsAddress,
																	address BbondsAddress,
	 															  address waterFallAddress)
																	public OnlyAfterEscrowLedgerCreated()//OnlyAfterEscrowSuccess()
																				 NotAfterEscrowFail()
{
  if(SecuritisationState.BondsAndWaterFallCreated == true) throw;

  ClassABond = BondA(AbondsAddress);
  ClassABondAddress = AbondsAddress;

	ClassBBond= BondB(BbondsAddress);
  ClassBBondAddress = BbondsAddress;


  WaterFallAccount = WaterFall(waterFallAddress);
	WaterFallAddress = waterFallAddress;

	AssetLedgerAccount.WaterFallset(WaterFallAddress);
	ClassABond.SetWaterFall(WaterFallAddress);
	ClassBBond.SetWaterFall(WaterFallAddress);
	EscrowAccount.SendReserve (WaterFallAddress);
	// the function above needs to be moved into a separate functio
  //originator could lose the reserve
	SecuritisationState.BondsAndWaterFallCreated = true;
	//ClassSubClass.transfer(Originator, 1000);
}

/*
function that let investors request their tokens when the trx kicked off
*/
function SendMeMyBonds () OnlyAfterBondsAndWaterFall() OnlyAfterEscrowSuccess()
public
{
	if(SecuritisationState.InvestorWithdrawn[msg.sender] == true)throw;

			  ClassABond.transfer(msg.sender,
		    EscrowAccount.GetInvestorsBalanceA(msg.sender));

				ClassBBond.transfer(msg.sender,
  			EscrowAccount.GetInvestorsBalanceB(msg.sender));

	SecuritisationState.InvestorWithdrawn[msg.sender] = true;

}


/*
Allows to move funds from the Ledger to the Waterfall. frequency is currently
not set for testing and simulation. This should be done frequently e.g. on a
daily basis
*/
function MoveFundsFromLedgerToWaterfall() OnlyAfterBondsAndWaterFall()
OnlyAfterEscrowSuccess()public
{
  // if(Time.Now()/(60*60*24) % 2 == 0) //THIS TEST IS DISABLED FOR TESTING PURPOSES
	WaterFallAccount.CalcWaterFall();
/*this is the waterfallfunction which withdraws funds from the ledger and then
calcs waterfall, double withdrawal is not possible*/
}


/*
Allows to sweep funds from the individual SmartLoans in the pool into the ledger
frequency is currently not set for testing and simulation. This should be done
frequently e.g. on a daily basis
*/
function MoveFundsFromPoolIntoLedger () OnlyAfterBondsAndWaterFall() OnlyAfterEscrowSuccess()
public returns(uint[12])
{
//if(Time.Now()/(60*60*24) % 2 != 0)//THIS TEST IS DISABLED FOR TESTING PURPOSES
	return AssetLedgerAccount.WithdrawDueLoans();
}


/*
Allows to sweep funds from the waterfall into the Bond token contract.
frequency is currently not set for testing and simulation. This should be done
frequently e.g. on a daily basis
*/
function MoveFundsIntoBonds () OnlyAfterBondsAndWaterFall()
OnlyAfterEscrowSuccess() public
{
	//if(Time.Now()/(60*60*24) % 2 != 0) {//THIS TEST IS DISABLED FOR TESTING PURPOSES
	ClassABond.PayIn();
	ClassBBond.PayIn();
	//ClassSubClass.PayIn();//}
}


/*
Reads and returns the status of the trx
*/
function ReadState() public returns (bool[4])
{
  return [SecuritisationState.LedgerAndEscrowCreated,
         SecuritisationState.EscrowSuccess,
         SecuritisationState.EscrowFail,
         SecuritisationState.BondsAndWaterFallCreated];
}


/*
Reads and returns central variables
*/
function ReadNumbers() public returns (uint[8])
{
  ReadNumbersOutput[0]= OriginalPoolBalance ;
  ReadNumbersOutput[1]= NumberOfLoans;
  ReadNumbersOutput[2]= ClassAInitialBal;
  ReadNumbersOutput[3]= ClassAInterestRateBPS;
  ReadNumbersOutput[4]= ClassBInitialBal;
  ReadNumbersOutput[5]= ClassBInterestRateBPS;
  ReadNumbersOutput[6]= ReserveRequired ;
  ReadNumbersOutput[7]= InvestmentPeriodEnd;

  return ReadNumbersOutput;
}

/*
Reads and returns central adresses
*/
function ReadAddresses() public returns (address[13])
{
  ReadAddressesOutput[0]= AccountAddresses[0];
  ReadAddressesOutput[1]= AccountAddresses[1];
  ReadAddressesOutput[2]= TrustedParty;
  ReadAddressesOutput[3]= Owner;
  ReadAddressesOutput[4]= Originator;
  ReadAddressesOutput[5]= ExcessFundsReceiver;
  ReadAddressesOutput[6]= PoolAdd;
  ReadAddressesOutput[7]= EscrowAddress;
  ReadAddressesOutput[8]= AssetLedgerAddress;
  ReadAddressesOutput[9]= WaterFallAddress;
  ReadAddressesOutput[10]= ClassABondAddress;
  ReadAddressesOutput[11]= ClassBBondAddress ;
  ReadAddressesOutput[12]= TimeAddress;

  return ReadAddressesOutput;
}

}
