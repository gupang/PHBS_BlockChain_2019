package Main;
/**
 * RAMBO GU
 * ID: 1901212580, PHBS
 */

import java.util.*;


public class TxHandler {

    // use Main.UTXO class to instantiate an private object in class Main.TxHandler
    private UTXOPool utxoPool;

    /**
     * Creates a public ledger whose current Main.UTXOPool (collection of unspent transaction outputs) is
     * {@code utxoPool}. This should make a copy of utxoPool by using the Main.UTXOPool(Main.UTXOPool uPool)
     * constructor.
     */
    public TxHandler(UTXOPool utxoPool) {
        // IMPLEMENT THIS
        // 'this' refer to the object in this class instead of the parameter's name
        // copy the utxoPool to here
        this.utxoPool = new UTXOPool(utxoPool);
    }


    /**
     * @return true if:
     * (1) all outputs claimed by {@code tx} are in the current Main.UTXO pool,
     * (2) the signatures on each input of {@code tx} are valid, 
     * (3) no Main.UTXO is claimed multiple times by {@code tx},
     * (4) all of {@code tx}s output values are non-negative, and
     * (5) the sum of {@code tx}s input values is greater than or equal to the sum of its output
     *     values; and false otherwise.
     */
    public boolean isValidTx(Transaction tx) {
        // IMPLEMENT THIS

        double inputtotal=0;
        double outputtotal=0;

        // Create a arraylist, each element in 'claimedoutputs' is an object of class Main.UTXO
        ArrayList<UTXO> claimedoutputs = new ArrayList<>();

        // If the current utxoPool is empty, presents error
        if(utxoPool == null)
            return false;

        // Traverse through all the inputs in given transaction tx
        for(int i=0; i<tx.getInputs().size();i++){

            //use Main.UTXO class to instantiate utxo with given inputs' info(prehash& outputindex)
            Transaction.Input input = tx.getInput(i);
            UTXO utxo = new UTXO(input.prevTxHash,input.outputIndex);

            // requirement(1): to verify all the outputs claimed by tx are in the current utxoPool
            // If utxo does not appear in the utxoPool, presents error
            if(!utxoPool.contains(utxo))
                return false;

            Transaction.Output out = utxoPool.getTxOutput(utxo);

            // requirement(2): to verify the signatures of each given transaction tx
            // three parameters to verify a signature: receiver's pk, message, signature of the msg using sk of sender
            if (!Crypto.verifySignature(out.address,tx.getRawDataToSign(i),input.signature))
                return false;

            // requirement(3): to verify no uxto is claimed multiple times by given transaction tx
            // If the claimed utxo already exists in 'claimedoutputs', represents error
            if(claimedoutputs.contains(utxo))
                return false;
            else
                // If this utxo has not been claimed, then add it into the claimedoutputs as a proof for next verification for double claiming
                claimedoutputs.add(utxo);


            // add this utxo's output value to the current tx's inputtoal value
            inputtotal = inputtotal + out.value;
        }

        // Traverse through all the outputs in given transaction tx
        for(Transaction.Output output:tx.getOutputs()){
            // requirement (4): all of the output values should be non-negative
            if(output.value < 0)
                return false;
            outputtotal = outputtotal + output.value;
        }

        // requirement (5) the inputtotal of tx should be >= the outputtotal
        if(outputtotal > inputtotal)
            return false;

        // If passes all 5 verification process, return true
        return true;
    }

    /**
     * Handles each epoch by receiving an unordered array of proposed transactions, checking each
     * transaction for correctness, returning a mutually valid array of accepted transactions, and
     * updating the current Main.UTXO pool as appropriate.
     */
    public Transaction[] handleTxs(Transaction[] possibleTxs) {
        // IMPLEMENT THIS
        // Create a arraylist, each element in it is the object of class 'Main.Transaction'
        ArrayList<Transaction> validtxs = new ArrayList<>();

        // requirement(1) check whether each given transaction is correct
        // Traverse through all transactions in given [] 'possibleTxs'
        for(Transaction tx: possibleTxs){
            // 'this' refer to the object that current class points to
            if(this.isValidTx(tx)){
                // If this tx is vaild, add it into the valid array
                validtxs.add(tx);
                // Since this tx is vaild, the output used in utxo should be removed
                for(Transaction.Input input: tx.getInputs()){
                    // use Main.UTXO class to instantiate utxo with given inputs' info(prehash& outputindex)
                    UTXO utxo = new UTXO(input.prevTxHash, input.outputIndex);
                    // remove this utxo with stated info
                    utxoPool.removeUTXO(utxo);
                }
                // Since this tx is valid, add its output into the utxopool for update
                for(int i=0; i<tx.numOutputs();i++){
                    Transaction.Output output = tx.getOutput(i);
                    // use Main.UTXO class to instantiate utxo with given output's info(hash& outputindex)
                    UTXO utxo = new UTXO(tx.getHash(),i);
                    // add this uxto with index i into the utxoPool
                    utxoPool.addUTXO(utxo,output);
                }
            }
        }

        // Return the ultimate valid array of transactions
        return validtxs.toArray(new Transaction[validtxs.size()]);

    }

}
