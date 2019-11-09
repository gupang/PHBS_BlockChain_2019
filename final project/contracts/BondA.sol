
pragma solidity^0.5.0;
import "./SmartLoan.sol";
import "./AssetLedger.sol";
import "./WaterFall.sol";
import "./Bond.sol";

contract BondA is Bond
{
/*
See the Bond.sol file for details
*/

/*
Constructor
*/
function BondA(uint256 initialSupply, address owner)
{
balanceOfBondTokens[msg.sender] = initialSupply;
InitialSupply = initialSupply;
Owner = owner;
}

//lets someone withdraw funds from the waterfall into this contract
function PayIn () public payable
{
	if (msg.sender != Owner) throw;
WaterFallIntPrin = WaterFall(WaterfallAddress).SendFundsA();
UpdateBalances(WaterFallIntPrin[0] ,WaterFallIntPrin[1]);
}
}
