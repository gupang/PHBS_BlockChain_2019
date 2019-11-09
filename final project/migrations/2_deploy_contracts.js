var AssetLedger = artifacts.require("./AssetLedger.sol");
var Bank = artifacts.require("./Bank.sol");
var Bond = artifacts.require("./Bond.sol");
var Escrow = artifacts.require("./Escrow.sol");
var Pool = artifacts.require("./Pool.sol");
var SFContract = artifacts.require("./SFContract.sol");
var SmartLoan = artifacts.require("./SmartLoan.sol");
var TimeSim = artifacts.require("./TimeSim.sol");
var Waterfall = artifacts.require("./WaterFall.sol");
//var Factory = artifacts.require("./Factory.sol");



//var MetaCoin = artifacts.require("./MetaCoin.sol");

module.exports = function(deployer) {
  //deployer.deploy(ConvertLib);
  //deployer.link(ConvertLib, MetaCoin);

  //deployer.deploy(AssetLedger);
  deployer.deploy(Bank);//this is for the app
  deployer.deploy(Pool);//this is for the simulation

  //deployer.deploy(Factory);

};
