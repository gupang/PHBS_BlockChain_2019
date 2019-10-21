package test;

import main.*;
import org.junit.Test;
import org.junit.Before;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.util.ArrayList;
import java.util.List;
import static junit.framework.TestCase.assertTrue;
import static junit.framework.TestCase.assertFalse;
import static org.hamcrest.core.Is.is;
import static org.junit.Assert.*;

/** 
* BlockChain Tester
* @author <RAMBO GU> No. 1901212580, PHBS
*/

public class BlockChainTest {


    KeyPair rambo1key, rambo2key, rambo3key, rambo4key, rambo5key, rambo6key, rambo7key, rambo8key, rambo9key, rambo10key;

    Transaction tx1, tx2, tx3, tx4, tx5, tx6, tx7, tx8, tx9;

    Block genesisBlock, genesisBlock2, nullblock, Block1, Block2, Block3, Block4, Block5, Block6, Block7, Block8, Block9, Block10, Block11, Block12, Block13, Block14, Block15, Block16, Block17;

    BlockChain blockChain;

    BlockHandler blockHandler;



    @Before
    public void before() throws Exception {
        this.rambo1key = KeyPairGenerator.getInstance("RSA").generateKeyPair();
        this.rambo2key = KeyPairGenerator.getInstance("RSA").generateKeyPair();
        this.rambo3key = KeyPairGenerator.getInstance("RSA").generateKeyPair();
        this.rambo4key = KeyPairGenerator.getInstance("RSA").generateKeyPair();
        this.rambo5key = KeyPairGenerator.getInstance("RSA").generateKeyPair();
        this.rambo6key = KeyPairGenerator.getInstance("RSA").generateKeyPair();
        this.rambo7key = KeyPairGenerator.getInstance("RSA").generateKeyPair();
        this.rambo8key = KeyPairGenerator.getInstance("RSA").generateKeyPair();
        this.rambo9key = KeyPairGenerator.getInstance("RSA").generateKeyPair();
        this.rambo10key = KeyPairGenerator.getInstance("RSA").generateKeyPair();
    }



    /**
     * Method: testNewChainBasics()
     * Some basic testings on a blockchain
     * to verify the Creation of a blockchain with the genesis block is successful;
     * to verify that uxtopool can be updated after a genesisblock creation;
     * to verify that txpool can be updated after a genesisblock creation;
     * to verify that a second genesis block could not be appended;
     * to verify that a null block could not be processed;
     * to verify that a block with a series of transactions can be added
     * to verify that the coinbase of a block could not be used in the transaction of this block
     */
    @Test
    public void testNewChainBasics() throws Exception {

        this.genesisBlock = new Block(null, rambo1key.getPublic());
        genesisBlock.finalize();
        this.blockChain = new BlockChain(genesisBlock);
        this.blockHandler = new BlockHandler(blockChain);

        // to verify that the genesisBlock is the mose recent block in the new blockchain
        assertThat(genesisBlock,is(blockChain.getMaxHeightBlock()));

        // to verify that the current utxoPool is updated
        UTXO genesisutxo = new UTXO(genesisBlock.getCoinbase().getHash(), 0);
        List<UTXO> currentutxopool1 = new ArrayList<>(blockChain.getMaxHeightUTXOPool().getAllUTXO());
        assertTrue("the utxopool now has correct number of utxo", currentutxopool1.size() == 1);
        assertTrue("contains genesisutxo", blockChain.getMaxHeightUTXOPool().contains(genesisutxo));

        // to verify that the current transactionPool is updated
        List<Transaction> currenttxpool1 = new ArrayList<>(blockChain.getTransactionPool().getTransactions());
        assertTrue("the global transactionpool now has correct number of transaction", currenttxpool1.size()==1);
        assertTrue("contains tx of coinbase", currenttxpool1.contains(genesisBlock.getCoinbase()));

        // to verify that a second genesis block could not be appended
        this.genesisBlock2 = new Block(null, rambo2key.getPublic());
        genesisBlock2.finalize();
        blockHandler.processBlock(genesisBlock2);
        assertFalse(blockHandler.processBlock(genesisBlock2));
        assertThat(genesisBlock,is(blockChain.getMaxHeightBlock()));

        // to verify that we could not process a null block
        this.nullblock = null;
        blockHandler.processBlock(nullblock);
        assertFalse(blockHandler.processBlock(nullblock));

        // to verify that a block with a series of transactions can be added
        this.Block1 = new Block(genesisBlock.getHash(), rambo2key.getPublic());
        this.tx1 = new Transaction();
        tx1.addInput(genesisBlock.getCoinbase().getHash(), 0);
        tx1.addOutput(genesisBlock.COINBASE, rambo3key.getPublic());
        tx1.signTx(rambo1key.getPrivate(), 0);
        tx1.finalize();
        blockHandler.processTx(tx1);
        Block1.addTransaction(tx1);
        this.tx2 = new Transaction();
        tx2.addInput(tx1.getHash(), 0);
        tx2.addOutput(25, rambo4key.getPublic());
        tx2.signTx(rambo3key.getPrivate(), 0);
        tx2.finalize();
        blockHandler.processTx(tx2);
        Block1.addTransaction(tx2);
        Block1.finalize();
        assertTrue(blockHandler.processBlock(Block1));

        // to verify that the coinbase of a block could not be used in the transaction of this block
        this.Block2 = new Block(Block1.getHash(), rambo4key.getPublic());
        this.tx3 = new Transaction();
        tx3.addInput(Block2.getCoinbase().getHash(), 0);
        tx3.addOutput(Block2.COINBASE, rambo3key.getPublic());
        tx3.signTx(rambo4key.getPrivate(), 0);
        tx3.finalize();
        blockHandler.processTx(tx3);
        Block2.addTransaction(tx3);
        Block2.finalize();
        assertFalse(blockHandler.processBlock(Block2));


    }



    /**
     *
     * Method: testComprehensive()
     * there are several scenarios tested in this method(not limited to follows):
     *  to verify blocks can be processed with a fork；
     *  to verify the getMaxHeightBlock() under two scenarios: same height/ not same height；
     *  to verify the getMaxHeightUTXOPool() function well under multiple transactions and blocks；
     *  to verify the getTransactionPool() function well under multiple transactions and blocks；
     *  to verify the double spending attack scenarios；
     *  to verify the detection and reject of block containing invalid transactions；
     *  to verify the confirmation mechanism: block under maxheight-CUT_OFF_AGE could not be appended；
     *  to verify that the system only need to store limited part of the blockchain
     */

    @Test
    public void testComprehensive() throws Exception {
        this.genesisBlock = new Block(null, rambo1key.getPublic());
        genesisBlock.finalize();
        this.blockChain = new BlockChain(genesisBlock);
        this.blockHandler = new BlockHandler(blockChain);

        // Initialize Block1: send coinbase to rambo2, containing transaction- tx1: rambo1->rambo3, $25
        this.Block1 = new Block(genesisBlock.getHash(), rambo2key.getPublic());
        this.tx1 = new Transaction();
        tx1.addInput(genesisBlock.getCoinbase().getHash(), 0);
        tx1.addOutput(genesisBlock.COINBASE, rambo3key.getPublic());
        tx1.signTx(rambo1key.getPrivate(), 0);
        tx1.finalize();
        blockHandler.processTx(tx1);
        Block1.addTransaction(tx1);
        Block1.finalize();
        blockHandler.processBlock(Block1);

        // Initialize Block2: send coinbase to rambo4, containing transaction- tx2: rambo2->rambo6, $25
        this.Block2 = new Block(Block1.getHash(), rambo4key.getPublic());
        this.tx2 = new Transaction();
        tx2.addInput(Block1.getCoinbase().getHash(), 0);
        tx2.addOutput(Block1.COINBASE, rambo6key.getPublic());
        tx2.signTx(rambo2key.getPrivate(), 0);
        tx2.finalize();
        blockHandler.processTx(tx2);
        Block2.addTransaction(tx2);
        Block2.finalize();
        blockHandler.processBlock(Block2);

        // Initialize Block3: send coinbase to rambo5, containing transaction- tx3: rambo3->rambo7, $25
        this.Block3 = new Block(Block1.getHash(), rambo5key.getPublic());
        this.tx3 = new Transaction();
        tx3.addInput(tx1.getHash(), 0);
        tx3.addOutput(25, rambo7key.getPublic());
        tx3.signTx(rambo3key.getPrivate(), 0);
        tx3.finalize();
        blockHandler.processTx(tx3);
        Block3.addTransaction(tx3);
        Block3.finalize();
        blockHandler.processBlock(Block3);
        // to verify the method getMaxHeightBlock() when fork happens
        // the maxheight block currently should be Block2(although Block3 is of the same height, but Block2 is older)
        assertThat(Block2,is(blockChain.getMaxHeightBlock()));

        // Initialize and add Block4: send coinbase to rambo8, containing transaction- tx4: rambo6->rambo9, $25
        this.Block4 = new Block(Block2.getHash(), rambo8key.getPublic());
        this.tx4 = new Transaction();
        tx4.addInput(tx2.getHash(), 0);
        tx4.addOutput(25, rambo9key.getPublic());
        tx4.signTx(rambo6key.getPrivate(), 0);
        tx4.finalize();
        blockHandler.processTx(tx4);
        Block4.addTransaction(tx4);
        this.tx5 = new Transaction();
        tx5.addInput(Block2.getCoinbase().getHash(), 0);
        tx5.addOutput(Block2.COINBASE, rambo10key.getPublic());
        tx5.signTx(rambo4key.getPrivate(), 0);
        tx5.finalize();
        blockHandler.processTx(tx5);
        Block4.addTransaction(tx5);
        Block4.finalize();
        blockHandler.processBlock(Block4);
        // to verify the method getMaxHeightBlock() again
        // now the maxheight block should be Block4
        assertThat(Block4,is(blockChain.getMaxHeightBlock()));

        // to verify the method getMaxHeightUTXOPool()
        // now the max height block is Block4, whose utxopool contains 4 utxos:
        UTXO utxo1 = new UTXO(tx1.getHash(), 0);
        UTXO utxo2 = new UTXO(Block4.getCoinbase().getHash(), 0);
        UTXO utxo3 = new UTXO(tx4.getHash(), 0);
        UTXO utxo4 = new UTXO(tx5.getHash(), 0);
        // to verify these 4 utxos are contained in the current utxopool
        List<UTXO> currentutxopool = new ArrayList<>(blockChain.getMaxHeightUTXOPool().getAllUTXO());
        assertTrue("the uxtopool now has the correct number of utxos", currentutxopool.size() == 4);
        assertTrue("contains utxo1", blockChain.getMaxHeightUTXOPool().contains(utxo1));
        assertTrue("contains utxo2", blockChain.getMaxHeightUTXOPool().contains(utxo2));
        assertTrue("contains utxo3", blockChain.getMaxHeightUTXOPool().contains(utxo3));
        assertTrue("contains utxo4", blockChain.getMaxHeightUTXOPool().contains(utxo4));

        // to verify the method getTransactionPool()
        // now we have 5 txs in total in the transaction pool
        List<Transaction> currenttxpool = new ArrayList<>(blockChain.getTransactionPool().getTransactions());
        assertTrue("the global transactionpool now has correct number of transaction", currenttxpool.size()==5);
        assertTrue("contains tx of coinbase", currenttxpool.contains(genesisBlock.getCoinbase()));
        assertTrue("contains coinbase of block1", currenttxpool.contains(Block1.getCoinbase()));
        assertTrue("contains coinbase of block2", currenttxpool.contains(Block2.getCoinbase()));
        assertTrue("contains coinbase of block3", currenttxpool.contains(Block3.getCoinbase()));
        assertTrue("contains coinbase of block4", currenttxpool.contains(Block4.getCoinbase()));

        // verification: double spending
        // now if we want to append a block a double spending onto the blockchain
        this.Block5 = new Block(Block4.getHash(), rambo1key.getPublic());
        this.tx6 = new Transaction();
        tx6.addInput(tx4.getHash(), 0);
        tx6.addOutput(25, rambo2key.getPublic());
        tx6.signTx(rambo9key.getPrivate(), 0);
        tx6.finalize();
        Block5.addTransaction(tx6);
        this.tx7 = new Transaction();
        tx7.addInput(tx4.getHash(), 0);
        tx7.addOutput(25, rambo3key.getPublic());
        tx7.signTx(rambo9key.getPrivate(), 0);
        tx7.finalize();
        Block5.addTransaction(tx7);
        Block5.finalize();
        assertFalse(blockHandler.processBlock(Block5));
        // there exists double spending in block5, it could not be appended, so the maxheight block is still block4
        assertThat(Block4,is(blockChain.getMaxHeightBlock()));


        // verification: invalid transaction
        // now if we want to append a block containing invalid transaction
        this.Block6 = new Block(Block4.getHash(), rambo1key.getPublic());
        this.tx8 = new Transaction();
        tx8.addInput(tx2.getHash(), 0);
        tx8.addOutput(25, rambo10key.getPublic());
        tx8.signTx(rambo6key.getPrivate(), 0);
        tx8.finalize();
        Block6.addTransaction(tx8);
        Block6.finalize();
        blockHandler.processBlock(Block6);
        assertFalse(blockHandler.processBlock(Block6));
        // as the new Block6 containing invalid transaction(), the maxheight block is still block4
        assertThat(Block4,is(blockChain.getMaxHeightBlock()));


        // verification: the block whose height <= maxheight- cut_off_age could not be appended
        // add block until the maxheight exceeds 13(Block3.height(3)+cut_off_age(10))
        this.Block7 = blockHandler.createBlock(rambo10key.getPublic());
        this.Block8 = blockHandler.createBlock(rambo10key.getPublic());
        this.Block9 = blockHandler.createBlock(rambo10key.getPublic());
        this.Block10 = blockHandler.createBlock(rambo10key.getPublic());
        this.Block11 = blockHandler.createBlock(rambo10key.getPublic());
        this.Block12 = blockHandler.createBlock(rambo10key.getPublic());
        this.Block13 = blockHandler.createBlock(rambo10key.getPublic());
        this.Block14 = blockHandler.createBlock(rambo10key.getPublic());
        this.Block15 = blockHandler.createBlock(rambo10key.getPublic());
        this.Block16 = blockHandler.createBlock(rambo10key.getPublic());
        // create a new Block, try to append it on Block3
        this.Block17 = new Block(Block3.getHash(), rambo9key.getPublic());
        this.tx9 = new Transaction();
        tx9.addInput(tx3.getHash(), 0);
        tx9.addOutput(25, rambo8key.getPublic());
        tx9.signTx(rambo7key.getPrivate(), 0);
        tx9.finalize();
        blockHandler.processTx(tx9);
        Block17.addTransaction(tx9);
        Block17.finalize();
        // since the Block17's height > 3+10, so it could not be appended
        assertFalse(blockHandler.processBlock(Block17));

        // verification: not storing the whole blockchain, just from the genesisblock
        // now the source block is updated, blocks before it need not a full storage
        System.out.print(blockChain.getGenesisblock().height);
        assertThat(Block4,is(blockChain.getGenesisblock().block));

    }


} 

