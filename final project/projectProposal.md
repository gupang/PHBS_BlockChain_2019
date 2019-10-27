# Final Project Proposal- BlockChain-based Asset Backed Security
### Group Member

Name| Student ID
------------ | -------------
顾庞 | 1901212580
赖琳 | 1801212867


## 1. Motivation — the problem to be solved？

We focus on securitization, or more specific, ABS, in this project. Because ABS not only serves the large banks and asset management companies, but also helps small and medium-sized institutions to get low cost financing through ABS, so long as they have the high quality assets. As a result, those small and medium-sized agencies with low rating also can easily achieve low-cost financing.
The following picture illustrates the growing market size of ABS in China from 2012 to 2018.

![finalproposalimg1](https://github.com/gupang/PHBS_BlockChain_2019/blob/master/final%20project/screenshots/finalproposalimg1.png)

However, there are three main issues need to be improved in current ABS system.

**1) Regulation Problem**

_Real cases:_ Citic securities and CICC falsified the prospectus and even got a fine, which was accused of weak internal control.

a)	on April 28, 2019, in the document Reply to the inquiry letter on the examination of application documents for initial public offering of A-share shares and listing in Sci-Tech innovation board submitted to the Shanghai stock exchange and the updated prospectus submitted simultaneously, CICC Wan jiuqing and Mo peng, as the specific person in charge of recommendation work, revised the information disclosure data and content of the prospectus related to business data, business and technology, management analysis and other information without authorization, and thus simultaneously revised the related content of the prospectus quoted in the Shanghai stock exchange inquiry questions. 

b)	on July 16, 2019, according to the warning letter issued by CSRC, CSRC found that during the application for initial public offering of Shanghai Baichu electronic technology co., LTD, for "sorting and refining the content of the prospectus disclosure", Citic securities made an unauthorized deletion in the registration document of the prospectus (June 28) of the contents required to be disclosed in the previous inquiry about “Why the comprehensive gross profit rate, net sales interest rate and return on equity were significantly higher than those of comparable listed companies in the same industry, and the period expense ratio was far lower than those of comparable listed companies in the same industry”.

Then we come up with the following problems: 

Since the number of people supervising exchanges is much smaller than the number of people in the investment banking department of securities brokerages, the supervision problem has always been a big loophole. For the internal quality control of securities firms, is the same situation. We have asked ourselves the following questions:

a)	Can we timely check and compare the correctness of documents and information in a company’s securitization(financing) process? If any difference occurs, can we find a solution to detect them at the first time?

b)	Can we ensure the safety and efficiency for the transfer of assets related?

c)	Can we provide a transparent environment for investors to do transaction?

**2) Call Auction Problem**

_Real cases:_ On April 22, Guangfa securities was penalized by regulators for bidding for corporate bond projects at prices below cost. In the letter of decision on administrative supervision measures, Guangdong securities regulatory bureau determined that Guangfa securities violated the provisions of article 7 and article 38 of the administrative measures on issuance and trading of corporate bonds, and ordered it to make corrections. This is also the first time that since the brokerage investment bank price war, the brokerage was penalized by the regulatory department, also caused great concern in the market.

So can we solve the malicious bidding problem through the block chain? For example, we can set a model similar to an auction and limit the range of each offer. The last offer which is written into the recognized securities firm in the block chain, can undertake and do the business?

**3) Low Liquidity Problem**

According to wind data, the transaction volume of secondary ABS in the inter-bank market in 2017 was 169.227 billion yuan, with 614 transactions with an average amount of 276 million yuan, while the total circulation of primary ABS in the same period was 597.729 billion yuan. The total transaction volume of secondary ABS on the Shanghai and Shenzhen stock exchanges was 37.083 billion yuan, with 1,148 transactions with an average amount of about 32 million yuan, while the primary issuance in the same period was 804.077 billion yuan.

Originally, the innovation of ABS lies in the separation of main rating and debt rating, but domestic ABS does not realize this. Even though small and medium-sized institutions have high-quality assets with high debt rating, they miss such a financing tool because their main rating is not high enough.

The main reason for this problem is that it is difficult to achieve objective and fair rating of bonds, so everyone gives priority to main rating, which causes investors to trust large institutions with high main rating more, even if the ABS bonds issued by these institutions are of low rating. Taking consumer finance ABS as an example, the underlying assets of consumer finance are typically characterized by large number of transactions, small amount and high degree of dispersion, which greatly increases the difficulty of debt rating. Therefore, no matter investors, asset appraisal, asset provider or business regulator, they all hold a wait-and-see attitude towards consumer finance ABS.

So can we use blockchain to solve the consensus problem of rating between people and institutions that don't trust each other?


        

## 2. Solution — how to solve？

##### 1) Background: 
Blockchain is a data structure with blocks generated by cryptography, also characterized by decentralization, openness and transparency, so that everyone can participate in database records. It can also be called distributed ledger, divided into public ledger and private ledger, and corresponding to public and private blockchain technology.

##### 2) Suitability of Blockchain: 
Features of blockchain includes decentralization, encryption security, and tamper-proof technology, which solves the problems of central data monopoly, credit authentication problem and information asymmetry.

##### 3) For ABS process, how can Blockchain address the three main problems mentioned in the first part?

Note: Our solution is based on the framework of Ethereum, which supports smart contract and is account-based.

**1) Regulation Problem**

* One version of the truth
Blockchain enables a single, consistent source of information for all participants in the network. In an industry that currently faces inefficiencies around the storage, reconciliation, transfer, and transparency of data across multiple independent entities, this feature could be highly beneficial.

* A complete, immutable, and traceable audit trail
From loan origination to primary issuance, servicing, and changes in ownership in the secondary market, blockchain can create a chronological and immutable audit trail of all transactions. With this capability, regulators and auditors could finally get a systemic view of the ownership of the underlying securitized assets. An issue that troubled the industry during the global financial crisis—determining who owned the title to some underlying assets— could be more easily resolved.

* Monitoring the duration of the underlying assets
The monitoring of the underlying assets is similar to the formation and transfer of the above mentioned assets. It is based on the openness and sharing spirit of blockchain to strictly track and monitor the duration of the entire asset pool, so as to facilitate data analysis and processing. At the same time, recording every asset and its overdue and early repayment on the blockchain is naturally information disclosure.

* Decentralized and secured transfer of basic assets
Each transfer of an asset is fully and truly recorded on the blockchain to facilitate tracking of asset ownership, which effectively prevents the phenomenon of "multiple sales".
On the other hand, transactions on the blockchain can be realized through scripts to reduce human intervention, and smart contracts can be built in to improve the efficiency and convenience of asset transfer.


**2) Call Auction Problem**

* Smart contract based call auction
There are several bidders but only one seller in this call auction. There are two scenarios in the ABS process can use this smart contract. The first happens when the company choosing a broker to make this ABS deal, the other happens when finally deciding the selling price of ABS. But in an auction problem, a third party who cost a lot and of no trust is no longer needed when blockchain appears. We can easily decide which party wins this auction just from the smart contract. For example, we can set the limit for bidding price and bidding times, and all of the participants can monitor the whole bidding process, which not only improves the efficiency and cuts down the cost but is also decentralized.


**3) Low Liquidity Problem**

* Unanimous formation of underlying assets
At present, the application pointcut of block chain to ABS mainly focuses on the formation process of underlying assets. With block chain technology, the authenticity of each underlying asset can be confirmed and Shared by all participants, greatly reducing information asymmetry. On the other hand, in the ABS structure of cyclic purchase, multiple signatures on the block chain can greatly improve the security and efficiency of cyclic purchase. By setting up multiple signatures, it can be agreed that at least the unanimous signatures of participants of two parties (such as asset service institutions and managers) can be obtained to determine the capital flow and realize the joint decision.

* Help and accelerate securities trading in the secondary market
At present, the lack of liquidity of ABS secondary market is a major sticking point in the development of ABS. ABS holders are recorded on the blockchain, and even with the connection between different blockchains forming a blockchain, investors can share the underlying asset status of ABS, which provides a transparent and safe trading platform for ABS trading.
On the other hand, blockchain technology can improve the efficiency of securities registration, trading and settlement, and meet the requirements of supervision and audit.

In summary, the transparent, efficient, shared and decentralized inner spirit of blockchain coincides with the core of asset securitization. The introduction of block chain technology makes it possible for ABS participants to simultaneously monitor the asset pool. Ledger recording details of every asset is open to all the principals in blockchain. It provides a strong support for the detail of the due diligence of the project manager, so that the rating agencies can analyze the quality of each asset rather than implement sampling survey method due to the limitation of technology. It makes firms more easily to grasp the legal risk of the entire asset pool, and asset services more easily to grasp the balance payments and the default condition, so investors can penetrate the underlying assets increase trust.



## 3. Rationale — why such solution but not other alternatives?

##### Why do not we use centralized online coordination system like google docs?

Some centralized doc/file coordination system like google docs have several differences compared to blockchain:

* A centralized system is always not so secure compared with blockchain because sometimes the data for securitization entails inside information which would severely affect the market. If not encrypted, the leak of any confidential info would lead to problem.

* There is no programming or coding option for centralized coordination system, some of the applications like call auction for ABS could not be done on this platform. Even in the future, there exists an addition function that the sever could handle different contracts, it is still not transparent and secure because all the computations are still done without all the people’s supervision and consensus.


##### Why do not we use distributed version control system like Git?

We have to admit that Git could efficiently manage the versions of a large project at a quite high speed. However, there are several aspects making Git different from blockchain, or to some extent, not so useful in our ABS case:

*In a blockchain implementation, every block is verified independently multiple times before it is added to the blockchain, which is called consensus. This is indeed one of the most important things about blockchain technology and is what ensures its "unhackability." On the other hand, many git projects do not require independent verification and, when they do, they only require one person to sign off on a change before it is committed to the repository. Hence, with at most one point of validation that you must trust, git breaks one of the core tenets of blockchain technology.

*A git repository is not necessarily duplicated on many servers. You can work from a git repository locally and if your local disk were corrupted, you would lose everything. Blockchain technology implies the reproduction of the ledger across servers. 

Git could not tell the difference between two binary files.

You can rewrite git history. A git push `<remote> <branch> --force` where `<branch>` is set to a previous state than that at `<remote>` would rewrite the history. In blockchains, the ledger is an immutable history.


## References

1. https://zh.wikipedia.org/wiki/资产抵押债券
2. https://www.forbes.com/sites/tomgroenfeldt/2018/09/12/using-blockchain-to-record-asset-backed-securities/#1c6d53c86ec8
3. https://baijiahao.baidu.com/s?id=1616259455873262809&wfr=spider&for=pc
4. 阿尔文德·纳拉亚南著, 林华, 王勇译. 区块链技术驱动金融[M]. 中信出版社, 2016.
5. http://www.sohu.com/a/133661999_408971
6. https://en.wikipedia.org/wiki/Git
7. https://www.guggenheiminvestments.com/perspectives/portfolio-strategy/asset-backed-securities-abs
