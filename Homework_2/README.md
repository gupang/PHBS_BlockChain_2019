
### Name: 顾庞 @Rambo， ID：1901212580, rambopang@pku.edu.cn
# Homework2- BlockChain


## 1. Homework Solution Summary
This homework mainly focuses on how to handle a set of transactions and make up a block which can be added to the blockchain.

There are several main ideas of this project:

1) The blockchain is a tree formed by blocks.

2) The transaction pool is global, but the utxopool is based on every block created.

3) The system contains a confirmation mechanism, which is realized by setting CUT_OFF_AGE. That means blocks under (maxheight-CUT_OFF_AGE) could not be added. 

4) The blockchain need not be stored as a whole, which is realized by setting MAXSTORAGE. That means blocks out of this height range need not to be stored.

The following are the methods created by myself:

Main Part | Test Part
------------ | -------------
public class BlockFamily | public void testNewChainBasics()
public BlockFamily getMaxHeightBlock(BlockFamily block) | public void testComprehensive()
public BlockFamily addBlock(BlockFamily target, Block newblock) |                   
public BlockFamily getGenesisblock() |              

## 2. First Part- Realization of Class BlockChain
###### 2.1 Method1- public class BlockFamily
This method is the basic data structure of this project, which builds a structure for all the nodes in the blockchain. Each node is the member of this BlockFamily. The following properties are assigned for each member:

`BlockFamily parent;`
`Block block;`
`UTXOPool utxoPool;`
`int height;`
`List<BlockFamily> children;`

![hw2photo1](https://github.com/gupang/PHBS_BlockChain_2019/blob/master/hw2screenshots/hw2photo1.png)

Also, when initizalizing a new member of family, these properties need to be assigned.

###### 2.2 Method2- public BlockChain(Block genesisBlock)
This method is to create an empty block chain with just a genesis block, assuming the genesis block is a valid block.

First, a genesis node is initialized with the given info of the genesisblock. Then add the coinbase tx into utxo and the transactionpool. Note that the coinbase info can be obtained using the 'Block' data structure.

###### 2.3 Method3- public BlockFamily getMaxHeightBlock(BlockFamily block)
This method is created by myself. It has a input parameter, which is a genesis block. Note that the genesis block here is not typical genesis block because it may be no longer the one created when initializing a new blockchain(this mechanism will be explained more explicitly in later methods). The input genesis block might has been updated to later blocks, which will be used to trace forward until we find the block with the maxheight. 

The main idea is tracing from the input block to see whether it has children, if not, then it is exactly the maxheight block. If it has children, then traverse through all the children including children's children subsequently in a loop to finally find the maximum height block.

Note that the return is actually a member of the BlockFamily. As the children blocks are all stored in a list, it will return the oldest block.

###### 2.4 Method4- public Block getMaxHeightBlock()
Since we have constructured a method to find the new block, in this method, we do not need to input new parameters because the genesis block is the same through this BlockChain.java. Just return the result with the previous method:

`return getMaxHeightBlock(genesisblock).block;`

###### 2.5 Method5- public UTXOPool getMaxHeightUTXOPool()
Since we have found the node with the maxheight, we just need to output one of its property, which is the uxtopool:

`return getMaxHeightBlock(genesisblock).utxoPool;`

###### 2.6 Method6- public TransactionPool getTransactionPool()
Since the transaction pool is global, we just need to return the declared `txpool` in this method. 

###### 2.7 Method7- public BlockFamily addBlock(BlockFamily target, Block newblock)
This method is created by myself, which can be used to add a given block onto the target. In most cases, the target block is not actually the previous block which the new block points to. So this method will find the real previous block from the target block in a loop.

There are several cases the newblock could not be added, like: the new block's height <= getMaxHeightBlock().height - CUT_OFF_AGE, or the transactions in the new block are not all valid.

If the new block is added successfully, then the utxopool should be updated by removing used ones and adding new ones into it. Also, the transaction will be updated by removing packaged ones and adding the coinbase transaction.

Note that this method only returns the target.

###### 2.8 Method8- public boolean addBlock(Block block)
Since we have created a method to add a new block. Then if we want to return the addition result, naturally the parameter should be the genesis block.

Here I want to explain the genesis block update mechanism: 

The reason why it needs to be updated is because we could not store the whole blockchain. And actually the oldest blocks are of no use because they are confirmed after ten blocks. So the main design idea is to store a height range of 11 blocks because all the operations just need the genesis block to trace forward. 

So each time we add a block successfully, it will examine whether the genesis block need to be updated. The criteria is the current maxheight of the blockchain >= current genesisblock's height + MAXSTORAGE. If so, the genesis block should be one of its chilren who is one the brach of the maxheight block.

```
if (buoy) {
            int currentgenesisblockheight = getMaxHeightBlock(genesisblock).height;

            if (currentgenesisblockheight >= genesisblock.height+MAXSTORAGE){
                List<BlockFamily> list1 = genesisblock.children;
                int gap = 0;
                // to traverse through all the children of certain block
                for (BlockFamily genesisblockcandidate : list1) {
                    if ((currentgenesisblockheight-genesisblockcandidate.height)> gap){
                        gap = currentgenesisblockheight-genesisblockcandidate.height;
                        genesisblock = genesisblockcandidate;
                    }
                }
            }
            buoy = false;
            return true;
}
```

Note that this method only returns true of false.

###### 2.9 Method9- public void addTransaction(Transaction tx)
This method is to use the addTransction method in TransactionPool.java to add new transactions into the global txpool:

`txpool.addTransaction(tx);`

###### 2.10 Method10- public BlockFamily getGenesisblock()
As the genesis node might be changed during the update of the blockchain, this method is created by myself to see its status. And it will be used in the testing suite.


## 3. Second Part- BlockChain Test
To finish the task, I utilized the JUNIT Test Suite in IntelliJ Idea. In the external libraries, I imported three jars:

`harcrest-core-1.3.jar`

`junit.jar`

`junit-4.121.jar`

The whole testing idea is divided into two parts: 

1) part1- do some testing on basic functions of a blockchain

2) part2- comprehensive testing, which means to put blockchain tested under different scenarios

###### 3.1 Test part1- public void testNewChainBasics()
This part is to test some basic functions of a blockchain. It includes:

1) to verify the Creation of a blockchain with the genesis block is successful;
   critera: the genesisBlock is the maxheight block

2) to verify that uxtopool can be updated after a genesisblock creation;
   criteria: the utxopool's number is only 1 and that contains genesisutxo

3) to verify that txpool can be updated after a genesisblock creation;
   criteria: the utxopool's number is only 1 and that contains coinbase of genesisBlock

4) to verify that a second genesis block could not be processed;
   criteria: the genesis block is still the maxheight block

5) to verify that a null block could not be processed;
   criteria: the process method returns false

6) to verify that a block with a series of transactions can be added
   criteria: the process method returns true

7）to verify that the coinbase of a block could not be used in the transaction of this block
   criteria: the process method returns true

###### 3.2 Test part2- public void testComprehensive()
This part is to test several more complicated scenarios: 

1) to verify blocks can be processed with a fork;
   criteria: two blocks with the same height can all be processed 

2) to verify the getMaxHeightBlock() under two scenarios: same height/ not same height;
   criteria: the getMaxHeightBlock returns the oldest block when there is a fork; returns the MaxHeightBlock correctly
   ![hw2photo2](https://github.com/gupang/PHBS_BlockChain_2019/blob/master/hw2screenshots/hw2photo2.png)
   
   ![hw2photo3](https://github.com/gupang/PHBS_BlockChain_2019/blob/master/hw2screenshots/hw2photo3.png)
   



3) to verify the getMaxHeightUTXOPool() function well under multiple transactions and blocks;
    criteria: the returned UTXOPool returns the correct size of uxtos and contains all the correct utxos
    ![hw2photo4](https://github.com/gupang/PHBS_BlockChain_2019/blob/master/hw2screenshots/hw2photo4.png)

4) to verify the getTransactionPool() function well under multiple transactions and blocks;
    criteria:the returned txPool returns the correct size of txs and contains all the correct txs
    ![hw2photo5](https://github.com/gupang/PHBS_BlockChain_2019/blob/master/hw2screenshots/hw2photo5.png)

5) to verify the double spending attack scenarios;
    criteria: the process method should return false
    ![hw2photo6](https://github.com/gupang/PHBS_BlockChain_2019/blob/master/hw2screenshots/hw2photo6.png) 
    
6) to verify the detection and reject of block containing invalid transactions;
    criteria: the process method should return false
    ![hw2photo7](https://github.com/gupang/PHBS_BlockChain_2019/blob/master/hw2screenshots/hw2photo7.png)

7) to verify the confirmation mechanism: block under maxheight-CUT_OFF_AGE could not be added;
    criteria: the process method should return false
    ![hw2photo8](https://github.com/gupang/PHBS_BlockChain_2019/blob/master/hw2screenshots/hw2photo8.png)


8) to verify that the system only need to store limited part of the blockchain
    criteria: the genesisblock's height should be 3
    ![hw2photo9](https://github.com/gupang/PHBS_BlockChain_2019/blob/master/hw2screenshots/hw2photo9.png)
