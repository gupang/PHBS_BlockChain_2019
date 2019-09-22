# URL: www.github.com-Rambo-PHBS_BlockChain_2019
# Name: 顾庞 @Rambo， ID：1901212580, rambopang@pku.edu.cn
# Homework1- ScroogeCoin, A Centralized Bitcoin System


## 1. Homework Solution Summary
In this homework, the task is to complete a centralized blockchain system which invloves two parts. The first part is to handle the given transaction(s). That means verifying whether each transaction is valid and giving a series of valid transactions. The second part is to test whether these two classes functions well in the system.  
I completed the 'TxHandler' class and the 'TxHandlerTest' class based on the description above.


## 2. First Part- Class TxHandler 
###### 2.1 Method1- public TxHandler(UTXOPool utxoPool) 
This method is to transmit a real utxoPool into the private uxtoclass object created under this class. So the language is quite simple:
`this.utxoPool = new UTXOPool(utxoPool)`

###### 2.2 Method2- public boolean isValidTx(Transaction tx)
In this method, 5 requirements are realized seperately. In requirement (1): If utxo does not appear in the utxoPool, presents error. In requirement (2): three parameters are used to verify a signature: receiver's pk, message, signature of the msg using sk of sender. In requirement (3): If the claimed utxo already exists in 'claimedoutputs', represents error. If this utxo has not been claimed, then add it into the claimedoutputs as a proof for next verification for double claiming. In requirement (4)& (5): compute the related value of 'inputtotal' & 'outputtotal'.

###### 2.3 Method3- public Transaction[] handleTxs(Transaction[] possibleTxs)
This method is to handle a series of given transactions. It entails several steps: Verify each transaction by calling method 'isValid'-> Remove the related utxo in the utxoPool(this make the afterwards transaction cannot claim this utxo)-> Update the utxoPool by adding the new transction's output into the pool. So in this process, it contains the First Come First Serve Logic. Even if the aferwards transaction's chain is longer, it would not be accepted into the return list.


## 3. Second Part- Class TxhandlerTest
To finish the task, I utilized the JUNIT Test Suite in IntelliJ Idea. In the external libraries, I imported three jars:
harcrest-core-1.3.jar
junit.jar
junit-4.121.jar
The whold design idea(excluding some preparing methods) is creating wrong transacitions that violates certain requirements while holding other requirements satisfied. If the method returns wrongly, then we know that function works.

###### 3.1 Method1- public void signTx(PrivateKey sk, int input)
This method is to sign each transaction using the sender's private key, which is the prerequisite method for testing. I wrote and put it under the class 'Transaction'.

###### 3.2  Method2- public void before()
This method is to intialze some parameters and setting for further testing, like the initial transaction and utxoPool.
In this method, I created a transaction which has 5 output for Scrooge himself, and added these 5 utxos into the utxoPool.

###### 3.3 Method3- public void testIsValidTxreq1() 
This method is to test the requirement (1) of 'isValidTx'. As required, all outputs claimed by certain tx should in the current utxoPool. So my design iogic is creating a transaction whose input is not in the current utxoPool.

###### 3.4 Method4- public void testIsValidTxreq2()
This method is to test the requirement (2) of 'isValidTx'. As required, the signature on each input should be valid. So my design logic is creating a scenario where Scrooge sent 50 coin to Rambo1, but Rambo2 wants to claim these coins. Then their signature should not match.

###### 3.5 Method5- public void testIsValidTxreq3()
This method is to test the requirement (3) of 'isValidTx'. As required, no UTXO can be claimed multiple times by certain transactions. So my design logic is creating two transactions that claim the same utxo(utxo2) in the utxoPool.

###### 3.6 Method6- public void testIsValidTxreq4()
This method is to test the requirement (4) of 'isValidTx'. As required, all of transaction output values should be non-negative. So my design logic is creating a transaction whose output value is negative.

###### 3.7 Method7- public void testIsValidTxreq5()
This method is to test the requirement (5) of 'isValidTx'. As required, the sum of the transaction input should >= the sum of its output. So my design logic is creating a transaction whose output is bigger than its input.

###### 3.8 Method8- public void testHandleTxs()
This method is to test 'HandleTxs' to see whether it can return appropriate list of transactions after given a series of transactions. 
I created three transactions: Scrooge spent uxto4 by sending to Rambo1/ Scooge spent uxto5 by sending to Rambo2/ Scrooge spent uxto4 by sending to Rambo3. We can find that two transaction has claimed the same uxto in the utxoPool. To avoid double spending, as the First Come First Serve logic designed in the method, only two transactions will appear in the return list.


