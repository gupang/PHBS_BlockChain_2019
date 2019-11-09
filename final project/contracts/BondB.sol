pragma solidity^0.5.0;
import "./SmartLoan.sol";
import "./AssetLedger.sol";
import "./WaterFall.sol";
import "./Bond.sol";

contract BondB is Bond
{
/*
See the Bond.sol file for details
*/

/*
Constructor
*/
function BondB(uint256 initialSupply, address owner )
{
balanceOfBondTokens[msg.sender] = initialSupply;
InitialSupply = initialSupply;
Owner = owner;
}

function PayIn () public payable
{
if (msg.sender != Owner) throw;
WaterFallIntPrin = WaterFall(WaterfallAddress).SendFundsB();
UpdateBalances (WaterFallIntPrin[0] ,WaterFallIntPrin[1]);
}
}
