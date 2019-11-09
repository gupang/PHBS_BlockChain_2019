pragma solidity^0.5.0;
import "./SmartLoan.sol";
import "./AssetLedger.sol";
import "./WaterFall.sol";

contract Bond
{

/*
TO DO:
Make sure modifiers are applied correctly
check for overflows
*/

/*
The Bond Contract allows its creator to mint an arbitrary fixed supply of tokens
and distribute the tokens to adress owners on the blockchain. The token holders
have the right to withdraw funds directly from the Bonds contract depending
on the fraction of overall supply the token holder possesses. The Bond Contract
keeps track of inflows and outflows of funds. The A Bonds and B Bonds are
beeing derived from this more general Bonds Contract.
*/

/*
Variables
-------------------------------------------------------------------------------
*/

/*
Ledgers to keep track of investor balances
*/
mapping (address => uint) public balanceOfBondTokens;
mapping (address => uint) public ETHWithdrawnInt;
mapping (address => uint) public ETHWithdrawnPrin;

/*
aggregate balance status variables of the contract
*/
uint public TotalETHPaidinInt;
uint public TotalETHPaidinPrin;
uint public InitialSupply;
uint [8] public StatusOutput;

/*
Addresses  of dependent contracts
*/
address public WaterfallAddress;
address public Owner;

/*
Funds received from the Waterfall this period
*/
uint[2] WaterFallIntPrin;

/*
State variable
*/
bool public WaterFallSet =false;


modifier OnlyOwner(){if (msg.sender == Owner)_;}




/*
This contract is deployed before the Waterfall contract and therefore needs to
get the address of the WaterFall get passed by a function
*/
function SetWaterFall (address waterfallAddress) public
{
	if (WaterFallSet) throw;
	 WaterfallAddress= waterfallAddress;
}

/*
This function lets any tokenholder transfer all or part of his tokens to some
other address on the Blockchain if he chooses to do so. I.e. he can sell the
bonds with this functions.
*/
function transfer(address _to, uint256 _value) public
{
/*
Check if transferror has enough tokens and check for overflows
*/
  if (balanceOfBondTokens[msg.sender] < _value) throw;
  if (balanceOfBondTokens[_to] + _value < balanceOfBondTokens[_to]) throw;

/*
Assign remaining (not withdrawn) interest and principal balances to new owner
*/
  if(ETHWithdrawnInt[msg.sender]>=
    (ETHWithdrawnInt[msg.sender]* _value /(balanceOfBondTokens[msg.sender])))
  {
    ETHWithdrawnInt[_to] +=
    (ETHWithdrawnInt[msg.sender]* _value /(balanceOfBondTokens[msg.sender]));
    ETHWithdrawnInt[msg.sender] -=
    (ETHWithdrawnInt[msg.sender]* _value /(balanceOfBondTokens[msg.sender]));
  }

  if(ETHWithdrawnPrin[msg.sender]>=
    (ETHWithdrawnPrin[msg.sender]* _value /(balanceOfBondTokens[msg.sender])))
  {
    ETHWithdrawnPrin[_to] +=
    (ETHWithdrawnPrin[msg.sender]* _value /(balanceOfBondTokens[msg.sender]));
    ETHWithdrawnPrin[msg.sender] -=
    (ETHWithdrawnPrin[msg.sender]* _value /(balanceOfBondTokens[msg.sender]));
  }

  balanceOfBondTokens[msg.sender] -= _value;
  balanceOfBondTokens[_to] += _value;
}

/*
this function updates the balance variables  and is used in the derived
ABond and BBond Contracts when funds are paid in
*/
function UpdateBalances (uint interest , uint principal) internal
{
  TotalETHPaidinInt += interest;
  TotalETHPaidinPrin += principal;
}


/*
Allows tokenholders to draw their portion of interest and principal funds from the Bond Contract.
*/
function Withdraw () public payable
{
  uint AvailableBalanceInt;
  uint AvailableBalancePrin;
  uint AvailableBalance;

/*
Check if investor has aleay withdrawn his share and set the AvailableBalance
accordingly
*/
  if (balanceOfBondTokens[msg.sender]*
     ((TotalETHPaidinInt + TotalETHPaidinPrin)/InitialSupply) >
     ETHWithdrawnInt[msg.sender]+ ETHWithdrawnPrin[msg.sender])

    {
      AvailableBalanceInt =
      (balanceOfBondTokens[msg.sender]* TotalETHPaidinInt -
      ETHWithdrawnInt[msg.sender]* InitialSupply)/ InitialSupply;

      AvailableBalancePrin =
      (balanceOfBondTokens[msg.sender]* (TotalETHPaidinPrin) -
      ETHWithdrawnPrin[msg.sender]* InitialSupply)/InitialSupply ;
    }

  else
    {
        AvailableBalanceInt =0;
        AvailableBalancePrin =0;
    }


/*
Send AvailableBalance
*/
  if(msg.sender.send(AvailableBalanceInt + AvailableBalancePrin)==false) throw;
    ETHWithdrawnInt[msg.sender]+=AvailableBalanceInt;
    ETHWithdrawnPrin[msg.sender]+=AvailableBalancePrin;
}


/*
This function allows to check the status of the overall Bond Contract as well
as the status of individual token holders.
*/
function CheckStatus (address BondAdress) public returns (uint[8])
{
    StatusOutput[0]=balanceOfBondTokens[BondAdress];
    StatusOutput[1]=ETHWithdrawnInt[BondAdress];
    StatusOutput[2]=ETHWithdrawnPrin[BondAdress];
    StatusOutput[3]=TotalETHPaidinInt;
    StatusOutput[4]=TotalETHPaidinPrin;
    //StatusOutput[5]=ETHPerBondInt;
    //StatusOutput[6]=ETHPerBondPrin;
    StatusOutput[7]=InitialSupply;
    return  StatusOutput;
  }

/*
Fallback function allows to send funds to this contract
*/
function () payable{}
}
