pragma solidity^0.5.0;

/*
This is for simulation of passing time. Only necessary for testing
*/
contract TimeSim
{
     uint public Now;
     function TimeSim() {Now = now; }
     function Step()public{Now += 30 days;}
}
