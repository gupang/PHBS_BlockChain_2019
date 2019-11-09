pragma solidity^0.5.0;
import "./SmartLoan.sol";
import "./TimeSim.sol";

/*
This contract should not be considered as a part of the Securitization contracts
Its merely a tool to facilitate creation and tracking of loans and therefore
only contains the most basic functionalites
*/
contract Bank
{
    uint public LoansNumber;
    address public BankDirector;
    address public TmpLoanAddress;
    address public TimeAddress;
    address public Securitization;
    mapping (address => address) public AccountsToLoans;
    address[] public Loans;
    TimeSim Time;
    SmartLoan TmpLoan;

    modifier OnlyDirector {if (msg.sender == BankDirector)_; else throw;}

    function SetSecuritization(address sfc) public {
    Securitization = sfc;
    }

    function Bank ()
    {
    Time  = new TimeSim();
    TimeAddress = Time;
    BankDirector = msg.sender;
    }

function GetLoanAddress() public returns (address){return AccountsToLoans[msg.sender];}
function getLoans() public returns (address[]) {
  return Loans;
}



    function NewLoan (address _Borrower, uint _Balance, uint _InterestRateBPS,
                      uint _TermMonths)
                      public OnlyDirector returns (address)
    {
        TmpLoan = new SmartLoan(this,_Balance,_InterestRateBPS,_TermMonths,
                                Time);
        TmpLoanAddress = TmpLoan;
        AccountsToLoans[_Borrower] = TmpLoanAddress;
        Loans.push(TmpLoanAddress);
 	LoansNumber++;
        return TmpLoanAddress;
    }

}
