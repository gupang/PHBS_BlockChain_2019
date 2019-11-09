pragma solidity^0.5.0;
import "./SmartLoan.sol";
import "./AssetLedger.sol";
import "./WaterFall.sol";
import "./Bond.sol";
import "./Escrow.sol";
import "./TimeSim.sol";
import "./SFContract.sol";

contract Pool
{


/*
This contract is used only to speed up and facilitate testing in the solidity
Web compiler and the truffle framework. I didnt document everything properly
and did not take too much care for cleaning up unused functions etc
It is basically work in progress and I want to add more testing scenarios
*/


address public Owner;
address public PoolAddress;
address public Loan1Address;
address public Loan2Address;
address public TimeAddress;
address public SFCAddress;
address public EscrowAddress;
address public LedgerAddress;

/*
INPUTS
Carefull with amending them, this can in some cases lead to collisions, this
needs to be worked on so that collision free amending of these INPUTS can be
done for testing
*/
uint Reserve = 200000;
uint InvestmentPeriodEnds;

//Classes
uint ClassAInitialBal= 10000000;
uint ClassAIntBPS = 1000;
	uint ClassBInitialBal= 10000000;
uint ClassBIntBPS = 1000;

//Loans
uint NumberOfLoans = 2;
uint OriginalBal1 = 10000000;
uint Int1 = 1000;
uint Term1= 12;

uint OriginalBal2 = 10000000;
uint Int2 = 1000;
uint Term2= 12;

/*
Instances of deployed contracts
*/
SmartLoan public Loan1;
SmartLoan public Loan2;
TimeSim public Time;
SFContract public SFC;

/*
Constructor
-------------------------------------------------------------------------------
*/

function Pool ()
{
	Owner = this;
	Time = new TimeSim();
	TimeAddress = Time;
	InvestmentPeriodEnds = Time.Now()+10 days;
	PoolAddress = msg.sender;
/*
	Loan1 = new SmartLoan(Owner,OriginalBal1,Int1,Term1,TimeAddress);
	Loan1Address = Loan1;

	Loan2 = new SmartLoan(Owner,OriginalBal2,Int2,Term2,TimeAddress);
	Loan2Address = Loan2;*/
}

function DeployLoans() public
{
	Loan1 = new SmartLoan(Owner,OriginalBal1,Int1,Term1,TimeAddress);
	Loan1Address = Loan1;

	Loan2 = new SmartLoan(Owner,OriginalBal2,Int2,Term2,TimeAddress);
	Loan2Address = Loan2;
}

function NewOwner () public returns(address[3])
{
 SmartLoan(Loan1).Transfer(LedgerAddress);
 SmartLoan(Loan2).Transfer(LedgerAddress);
}

function Pay() public payable
{
 SmartLoan(Loan1).PayIn();//.value(1200000).gas(2500)();
 SmartLoan(Loan2).PayIn();//.value(1200000).gas(2500)();
}


function DeploySFContract()public returns(address)
{
	SFC = new SFContract([Loan1Address,Loan2Address], OriginalBal1+OriginalBal2,
		                   NumberOfLoans,ClassAInitialBal,ClassAIntBPS,
											 ClassBInitialBal,ClassBIntBPS, Reserve,
											 InvestmentPeriodEnds,Owner, Owner, Owner,
											 PoolAddress, Time);
	SFCAddress = SFC;
	return SFC;
}

/*
function CreateEscrowAndLedger (address ) returns(address)
{
	SFC.CreateEscrowAndLedger();
	return SFC.EscrowAddress();
}*/

function GetEscrowLedgerAddress ()
{
	EscrowAddress = SFC.EscrowAddress();
	LedgerAddress = SFC.AssetLedgerAddress();
}


function EscrowGiveLedgerAddrestoEscrow()
{
	Escrow(EscrowAddress).SetLedger(LedgerAddress);
}

function LedgerCheckPool ()
{
	AssetLedger(LedgerAddress).PooTransferred();
}

function EscrowInvestorPaySetValA() payable
{
	Escrow(EscrowAddress).InvestorPayInA.value(ClassAInitialBal)();
}


function EscrowInvestorPaySetValB() payable
{
Escrow(EscrowAddress).InvestorPayInB.value(ClassAInitialBal)();
}

function EscrowPayereserve() payable returns (uint)
{
	Escrow(EscrowAddress).PayReserve.value(ClassAInitialBal)();
	return Escrow(EscrowAddress).ReserveRequired();
}

function EscrowTrustedParty(){Escrow(EscrowAddress).PoolValid (); }
function EscrowPoolTransferr(){Escrow(EscrowAddress).PoolTransfer (); }
function EscrowCheckState(){Escrow(EscrowAddress).CheckState();}

/*
function Status () payable returns (address[2])
{
	DeploySFContract();
	CreateEscrowAndLedger ();
	GetEscrowLedgerAddress ();
	EscrowGiveLedgerAddrestoEscrow();
	NewOwner ();
	LedgerCheckPool ();
	EscrowTrustedParty();
	EscrowPoolTransferr();
	EscrowInvestorPaySetValA();
	EscrowInvestorPaySetValB();
	EscrowCheckState();
	EscrowPayereserve();
	return [EscrowAddress,SFC];
}*/

}
