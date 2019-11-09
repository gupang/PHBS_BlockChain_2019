pragma solidity^0.5.0;
import "./SmartLoan.sol";
import "./AssetLedger.sol";


contract WaterFall
{


/*
The WaterFall Contract is responsible for distribution of the funds collected by
the AssetLedger to the Bonds. A very simplified allocation has been used here
for illustration purposes.
*/

/*
Variables
-------------------------------------------------------------------------------
*/
struct Class
{
  uint OrigBal;
  uint CurrentBal;
  uint InterestBPS;
  uint InterestDue;
  uint InterestAvailable;
  uint PrincipalAvailable;
}

Class public ClassA;
Class public ClassB;

struct Pool
{
  uint IntFromPool;
  uint PrinFromPool;
  uint RecovFromPool;
  uint DefaultFromPool;
}

Pool public PoolA;

uint public ReserveFundTarget;
uint public ReserveFundAvailable;
uint public AvailableFunds;
uint public ExcessSpread;

AssetLedger public AssetsLedgerA;

address public AssetsAddress;
address public LiabilitiesAddressA;
address public LiabilitiesAddressB;
address public ExcessFundsAddress;
address public OwnerAddress;

uint [5] public SendFundsOutput;

/*
Modifiers
-------------------------------------------------------------------------------
*/
modifier OnlyOwner() {if(msg.sender==OwnerAddress)_;}


/*
Constructor
-------------------------------------------------------------------------------
•	ReserveAmount: The reserve fund is provided by the Originator and improves
  credit quality
•	classAInitialBal: The aggregate balance of Class A Bonds
•	classAInterestRateBPS: The interest rate paid to Class A Bondholders
•	classBInitialBal:  The aggregate balance of Class B Bonds
•	classBInterestRateBPS: The interest rate paid to Class B Bondholders. This is
  higher than for Class A since the Class B bonds are riskier because they
  receive principal payments only after Class A is fully repaid.
•	assetsAddress: The address of the AssetLdeger Contract where funds come from
•	liabilitiesAddressA: Address of the Contract responsible for Class A bonds
•	liabilitiesAddressB: Address of the Contract responsible for Class B bonds
•	ownerAddress: Address of the "Securitization" contract, which is the
  controlling contract
•	excessFundsAddress: The address where excess funds go to. Excess funds are
  interest funds received from the asset ledger after all deductions for Bond
  interest and top up of the reserve.
*/
function WaterFall (uint reserveAmount, uint classAInitialBal,
                   uint classAInterestRateBPS, uint classBInitialBal,
                   uint classBInterestRateBPS, address assetsAddress,
                   address liabilitiesAddressA, address liabilitiesAddressB,
                   address ownerAddress) public
{
  AssetsAddress = assetsAddress;
	AssetsLedgerA = AssetLedger(assetsAddress);
  LiabilitiesAddressA= liabilitiesAddressA;
  LiabilitiesAddressB= liabilitiesAddressB;
  //ExcessFundsAddress = excessFundsAddress;
	OwnerAddress =ownerAddress;
  ClassA.OrigBal = classAInitialBal;
  ClassA.CurrentBal =classAInitialBal;
  ClassA.InterestBPS =classAInterestRateBPS;
  //Periods*UpscaleForBasisPoints = 12*10000 = 120000
  ClassA.InterestDue = ClassA.CurrentBal*classAInterestRateBPS/(120000);

  ClassB.OrigBal = classBInitialBal;
  ClassB.CurrentBal =classBInitialBal;
  ClassB.InterestBPS = classBInterestRateBPS;
  ClassB.InterestDue = ClassB.CurrentBal*classBInterestRateBPS/(120000);

  ReserveFundTarget =reserveAmount;
  ReserveFundAvailable =reserveAmount;
}

/*
SendFundsA()/ SendFundsB()
Sends funds due to the A (B) Bonds as calculated by the waterfall to the A
(B) Bonds. This function is executable from the "Securitization" conract in a
scheduled frequency. Along with the funds, the information on split of interest
and principal is beeing passed
*/
function SendFundsA() public returns (uint[2])
{
  uint intavail =ClassA.InterestAvailable;
	uint prinavail =ClassA.PrincipalAvailable;

  if (msg.sender != LiabilitiesAddressA) throw;
	if(LiabilitiesAddressA.send(intavail+prinavail)==false) throw;

  ClassA.InterestAvailable=0;
  ClassA.PrincipalAvailable=0;

  return [intavail,prinavail];
}

function SendFundsB() public returns (uint[2])
{
  uint intavail =ClassB.InterestAvailable;
  uint prinavail =ClassB.PrincipalAvailable;

  if (msg.sender != LiabilitiesAddressB) throw;
  if(LiabilitiesAddressB.send(intavail+prinavail)==false) throw;

  ClassB.InterestAvailable=0;
	ClassB.PrincipalAvailable=0;

  return [intavail,prinavail];
}

/*
The ExcessSpread is currently not allocated correctly so this function needs to
be reviewed
*/
function SendFundsExcessSpread() public OnlyOwner returns (uint)
{
		uint xsavail =ExcessSpread;
    if(LiabilitiesAddressB.send(ExcessSpread)==false) throw;
		ExcessSpread=0;
    return xsavail;
}

/*
This function draws the funds from the asset ledger and executable by the "Securitization" contract in a scheduled frequency.
*/
function Withdraw() public payable
{
SendFundsOutput = AssetsLedgerA.SendFunds();
/*
.Sendfunds returns this:
[PrincipalThisPeriod,InterestThisPeriod,RecoveriesThisPeriod,DefaultThisPeriod]
*/
AvailableFunds = SendFundsOutput[0]+
                 SendFundsOutput[1]+
                 SendFundsOutput[2]+
                 ReserveFundAvailable;
}

/*
This function calculates how the funds are beeing distributed among the bonds.
The waterfall structure used here is simplified for demonstration purposes.
Therefore, first interest due is calculated, thereafter the following rules
apply.

1.	Interest to A Bonds
2.	Interest to B Bonds
3.	Top up of Reserve (the reserve covers interest shortfalls during the life
                      of the transaction and is available for credit enhancement
                      at the end of its life)
4.	Principal to A Bonds
5.	Principal to B Bonds
*/
function CalcWaterFall()public OnlyOwner
{
  Withdraw();

  //CLASS A INTEREST
  if(AvailableFunds >ClassA.InterestDue )
  {
    AvailableFunds-=ClassA.InterestDue;
    ClassA.InterestAvailable =ClassA.InterestDue;
  }
  else
  {
    ClassA.InterestAvailable = AvailableFunds;
    AvailableFunds=0;
  }

//CLASS B INTEREST
  if(AvailableFunds >ClassB.InterestDue )
  {
    AvailableFunds-=ClassB.InterestDue;
    ClassB.InterestAvailable =ClassB.InterestDue;
  }
  else
  {
    ClassB.InterestAvailable = AvailableFunds;
    AvailableFunds=0;
  }

//TOP UP RESERVE
 if(AvailableFunds >ReserveFundTarget)
 {
   AvailableFunds =AvailableFunds - ReserveFundTarget;
   ReserveFundAvailable =ReserveFundTarget;
 }
 else
 {
   ReserveFundAvailable = AvailableFunds;
   AvailableFunds=0;
 }

//FIGURE OUT WHEN AND HOW TO RELEASE THE RESERVE FOR CREDIT ENHANCEMENT

//CLASS A PRINCIPAL
  if(AvailableFunds >ClassA.CurrentBal)
  {
    AvailableFunds-=ClassA.CurrentBal;
    ClassA.PrincipalAvailable =ClassA.CurrentBal;
    ClassA.CurrentBal=0;
  }
  else
  {
    ClassA.PrincipalAvailable = AvailableFunds;
    AvailableFunds=0;
    ClassA.CurrentBal-=ClassA.PrincipalAvailable;
  }

//CLASS B PRINCIPAL
  if(AvailableFunds >ClassB.CurrentBal )
  {
    AvailableFunds-=ClassB.CurrentBal;
    ClassB.PrincipalAvailable =ClassB.CurrentBal;
    ClassB.CurrentBal=0;
  }
  else
  {
    ClassB.PrincipalAvailable = AvailableFunds;
    AvailableFunds=0;
    ClassB.CurrentBal-=ClassB.PrincipalAvailable;
  }

//EXCESS SPREAD
  ExcessSpread = AvailableFunds;
  AvailableFunds =0;

  CalculateInterestDue();
}


/*
function updates interestdue
*/
function CalculateInterestDue () private
{
  ClassA.InterestDue = ClassA.CurrentBal*ClassA.InterestBPS/(120000);
  ClassB.InterestDue = ClassB.CurrentBal*ClassB.InterestBPS/(120000);
}



/*
Fallback allows to send funds to this contract
*/
function () payable {} //allows to send funds
}
