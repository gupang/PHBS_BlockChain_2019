package main;
import java.util.*;

import java.util.ArrayList;
import java.util.Arrays;

/**
 * RAMBO GU
 * ID: 1901212580, PHBS
 */

public class BlockChain {
    // set cut_off_age to function as a confirmation of transaction
    public static final int CUT_OFF_AGE = 10;
    public static final int MAXSTORAGE = 11;
    // set a indicator as adding block
    public boolean buoy;
    private TransactionPool txpool;
    private BlockFamily genesisblock;

    // If for every block, a utxopool need to be maintained, then we have to add a new data structure for block
    public class BlockFamily{
        // for each block in the block family, it has several properties
        public BlockFamily parent;
        public Block block;
        public UTXOPool utxoPool;
        public int height;
        // for each block in the block family, it has a list of children because of forks
        public List<BlockFamily> children;

        // add a method to initialize a new block(not a genesis one)
        public BlockFamily(Block block, BlockFamily parent, int height, List<BlockFamily> children, UTXOPool utxoPool){
            this.parent= parent;
            this.block= block;
            this.utxoPool= utxoPool;
            this.height = height;
            this.children = children;
        }

        // add a method to initialize a new block(a genesis one), a genesis block does not have a parent
        public BlockFamily(Block block) {
            // this refer to previous method 'BlockFamily'
            this(block, null, 0, new ArrayList<BlockFamily>(), new UTXOPool());
        }
    }


    /**
     * create an empty block chain with just a genesis block. Assume {@code genesisBlock} is a valid
     * block
     */
    public BlockChain(Block genesisBlock) {
        // IMPLEMENT THIS
        // initialize a new genesis block with the given 'genesisBlock'
        this.genesisblock = new BlockFamily(genesisBlock);
        // as the new block is created, a coinbase transaction will be created, thus changing the utxopool
        UTXO utxo = new UTXO(genesisBlock.getCoinbase().getHash(), 0);
        // get the output of this utxo
        Transaction.Output output = genesisBlock.getCoinbase().getOutput(0);
        // add the uxto into the utxopool
        this.genesisblock.utxoPool.addUTXO(utxo,output);
        // the transaction pool alse need to be updated for this new transaction
        this.txpool =  new TransactionPool();
        txpool.addTransaction(genesisBlock.getCoinbase());
    }

    // if we are to find the block with the max height, we must traverse from the first block- genesis block
    private BlockFamily getMaxHeightBlock(BlockFamily block) {
        if (block.children.isEmpty()) {
            return block;
        } else {
            int height = block.height;
            List<BlockFamily> list = block.children;
            // to traverse through all the children of certain block
            for (BlockFamily xblock : list) {
                // for every block, find if has any children, if so, traverse through its children's block list
                // and it manifests that there should be a block has a higher height
                // as the children blocks are all stored in a list, it will return the oldest block
                xblock = getMaxHeightBlock(xblock);
                if (xblock.height > height) {
                    block = xblock;
                    height = xblock.height;
                }
            }
        }
        return block;
    }

    /** Get the maximum height block */
    public Block getMaxHeightBlock() {
        // IMPLEMENT THIS
        return getMaxHeightBlock(genesisblock).block;
    }

    /** Get the main.UTXOPool for mining a new block on top of max height block */
    public UTXOPool getMaxHeightUTXOPool() {
        // IMPLEMENT THIS
        return getMaxHeightBlock(genesisblock).utxoPool;
    }

    /** Get the transaction pool to mine a new block
     * @return*/
    public TransactionPool getTransactionPool() {
        // IMPLEMENT THIS
        return txpool;
    }

    /**
     * Add {@code block} to the block chain if it is valid. For validity, all transactions should be
     * valid and block should be at {@code height > (maxHeight - CUT_OFF_AGE)}.
     * 
     * <p>
     * For example, you can try creating a new block over the genesis block (block height 2) if the
     * block chain height is {@code <=
     * CUT_OFF_AGE + 1}. As soon as {@code height > CUT_OFF_AGE + 1}, you cannot create a new block
     * at height 2.
     * 
     * @return true if block is successfully added
     */

    // to add a 'newblock' to a existed block 'target' in blockchain, we need a new method
    public BlockFamily addBlock(BlockFamily target, Block newblock){
        // first we have to make sure the target block is the one we want to append to
        ByteArrayWrapper targethash = new ByteArrayWrapper(target.block.getHash());
        ByteArrayWrapper newblockhash = new ByteArrayWrapper(newblock.getPrevBlockHash());
        if (targethash.equals(newblockhash)){
            // calculate the height of newblock
            int newblockheight = target.height+1;
            // as required, we have to know the least block height from cut_off_age, to make sure the new block could be added validly
            int minheight = getMaxHeightBlock(genesisblock).height - CUT_OFF_AGE;
            // if the newblock's height is even smaller than the minheight required, we could not add it
            // then the newest block is still 'target', meaning the addition does not succeed
            if (newblockheight <= minheight){
                return target;
            }

            // if the block could be added, then we have to add this newblock into BlockFamily
            // we have to update some properties for the newblock in BlockFamily

            // get the current utxopool before addition
            UTXOPool newblockutxopool = new UTXOPool(target.utxoPool);
            TxHandler txHandler = new TxHandler(newblockutxopool);
            // to process the current target's utxopool, we have to get all the txs in the newblock
            Transaction[] targettx = newblock.getTransactions().toArray(new Transaction[newblock.getTransactions().size()]);
            // by the method 'handleTxs', the targetutxopool is actually updated
            Transaction[] validTxs = txHandler.handleTxs(targettx);

            // if the there exist some invalid transactions, then the block will not be added successfully
            if (!(validTxs.length == targettx.length)){
                return target;
            }

            // the coinbase utxo should be added manually
            newblockutxopool.addUTXO(new UTXO(newblock.getCoinbase().getHash(), 0), newblock.getCoinbase().getOutput(0));
            // then we can update this newblock as the children of the target block
            List<BlockFamily> newblockchildren = new ArrayList<>();
            target.children.add(new BlockFamily(newblock, target, newblockheight, newblockchildren, newblockutxopool));
            // set the indicator to be 1
            buoy = true;
            // since the addition succeed, we need to update the global transaction pool
            List<Transaction> transactions = newblock.getTransactions();
            for (Transaction transaction: transactions) {
                txpool.removeTransaction(transaction.getHash());
            }
            txpool.addTransaction(newblock.getCoinbase());



        // there is another case that if the target node is not the latest one because of some delay
        // that means the so called target is not the one on which we actually want to append the newblock
        }else {
            // travers through the target's children list, to see whether newer target exists
            ListIterator<BlockFamily> blockFamilyListIterator = target.children.listIterator();
            // only when the blockchain has not been updated and target's children list is not empty
            while (!buoy && blockFamilyListIterator.hasNext()) {
                BlockFamily newertarget = blockFamilyListIterator.next();
                // to try to append the newblock actually on the newer target
                blockFamilyListIterator.set(addBlock(newertarget, newblock));
            }
        }
        return target;
    }


    // to indicate whether the addition succeed
    public boolean addBlock(Block block) {
        // IMPLEMENT THIS
        // to avoid adding a genesis block
        if (block.getPrevBlockHash() == null ) {
            return false;
        }
        // add the new block through adding it onto the genesis block(even though genesis block may not be its target block)
        // it will update the genesisblock every time we successfully add a new block, then we do not need to store the whole blockchain
        genesisblock = addBlock(genesisblock, block);
        // after addition, we need to update the
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
        } else {
            return false;
        }
    }

    /** Add a transaction to the transaction pool */
    public void addTransaction(Transaction tx) {
        // IMPLEMENT THIS
        txpool.addTransaction(tx);
    }

    public BlockFamily getGenesisblock(){
        return genesisblock;
    }
}