/**
 * RAMBO GU
 * ID: 1901212580, PHBS
 */

package main;
import java.util.*;


public class TxHandler {

    // use Main.UTXO class to instantiate an private object in class Main.TxHandler
    private UTXOPool utxoPool;

    /**
     * Creates a public ledger whose current UTXOPool (collection of unspent transaction outputs) is
     * {@code utxoPool}. This should make a copy of utxoPool by using the UTXOPool(UTXOPool uPool)
     * constructor.
     */
    public TxHandler(UTXOPool utxoPool) {
        // IMPLEMENT THIS
        // 'this' refer to the object in this class instead of the parameter's name
        // copy the utxoPool to here
        this.utxoPool = utxoPool;
    }

    public UTXOPool getUTXOPool() {
        return utxoPool;
    }

    /**
     * @return true if:
     * (1) all outputs claimed by {@code tx} are in the current UTXO pool,
     * (2) the signatures on each input of {@code tx} are valid,
     * (3) no UTXO is claimed multiple times by {@code tx},
     * (4) all of {@code tx}s output values are non-negative, and  DONE
     * (5) the sum of {@code tx}s input values is greater than or equal to the sum of its output
     * values; and false otherwise.
     */
    public boolean isValidTx(Transaction tx) {
        // IMPLEMENT THIS

        int i = 0;
        double inputSum = 0;
        Set<UTXO> claimedUtxos = new HashSet<UTXO>();

        // Traverse through all the inputs in given transaction tx
        for (Transaction.Input input : tx.getInputs()) {
            UTXO utxo = new UTXO(input.prevTxHash, input.outputIndex);
            // requirement(3): to verify no uxto is claimed multiple times by given transaction tx
            // If the claimed utxo already exists in 'claimedoutputs', represents error
            if (claimedUtxos.contains(utxo)) {
                return false;
            }
            claimedUtxos.add(utxo);
            // requirement(1): to verify all the outputs claimed by tx are in the current utxoPool
            // If utxo does not appear in the utxoPool, presents error
            if (!utxoPool.contains(utxo)) {
                return false;
            }
            // requirement(2): to verify the signatures of each given transaction tx
            // three parameters to verify a signature: receiver's pk, message, signature of the msg using s
            if (!Crypto.verifySignature(utxoPool.getTxOutput(utxo).address, tx.getRawDataToSign(i), input.signature)) {
                return false;
            }
            inputSum += utxoPool.getTxOutput(utxo).value;
            i++;
        }

        double totalOutputValue = 0;
        // Traverse through all the outputs in given transaction tx
        for (Transaction.Output output : tx.getOutputs()) {
            // requirement (4): all of the output values should be non-negative
            if (output.value < 0) {
                return false;
            }
            totalOutputValue += output.value;
        }
        // requirement (5) the inputtotal of tx should be >= the outputtotal
        if (totalOutputValue > inputSum) {
            return false;
        }
        // If passes all 5 verification process, return true
        return true;
    }

    /**
     * Handles each epoch by receiving an unordered array of proposed transactions, checking each
     * transaction for correctness, returning a mutually valid array of accepted transactions, and
     * updating the current UTXO pool as appropriate.
     */
    public Transaction[] handleTxs(Transaction[] possibleTxs) {
        // IMPLEMENT THIS
        Set<Transaction> acceptedTxs = new HashSet<Transaction>();
        Set<Transaction> validTxs = new HashSet<Transaction>();
        Set<Transaction> invalidTxs = new HashSet<Transaction>();

        // requirement(1) check whether each given transaction is correct
        // Traverse through all transactions in given [] 'possibleTxs'
        for (Transaction tx : possibleTxs) {
            if (isValidTx(tx)) {
                processValidTransaction(acceptedTxs, validTxs, tx);
            } else {
                invalidTxs.add(tx);
            }
        }
        // Process initially invalid transactions
        do {
            validTxs.clear();
            for (Transaction tx : invalidTxs) {
                if (isValidTx(tx)) {
                    processValidTransaction(acceptedTxs, validTxs, tx);
                }
            }
            invalidTxs.removeAll(validTxs);
        } while(!validTxs.isEmpty());

        Transaction[] arrayOfAcceptedTxs = acceptedTxs.toArray(new Transaction[acceptedTxs.size()]);
        return arrayOfAcceptedTxs;
    }

    private void processValidTransaction(Set<Transaction> acceptedTxs, Set<Transaction> validTxs, Transaction tx) {
        for (Transaction.Input input : tx.getInputs()) {
            // use Main.UTXO class to instantiate utxo with given inputs' info(prehash& outputindex
            UTXO utxo = new UTXO(input.prevTxHash, input.outputIndex);
            // remove this utxo with stated info
            if (utxoPool.contains(utxo)) {
                utxoPool.removeUTXO(utxo);
            }
        }

        //Add new UTXO's to the pool
        List<Transaction.Output> outputList = tx.getOutputs();
        for (int i = 0; i < outputList.size(); i++) {
            // use Main.UTXO class to instantiate utxo with given output's info(hash& outputindex)
            UTXO utxo = new UTXO(tx.getHash(), i);
            // add this uxto with index i into the utxoPool
            utxoPool.addUTXO(utxo, outputList.get(i));
        }
        validTxs.add(tx);
        acceptedTxs.add(tx);
    }
}
