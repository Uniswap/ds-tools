
On-chain data science guide, queries, and tools



**<span style="text-decoration:underline;">Data sources and use cases</span>**



1. Dune Analytics (& Flipside):
    * Mostly for gathering business intelligence, such as volume / user market share
    * _Advantages_: convenient abstraction tables + easy visualization tools
    * _Disadvantages_: runtime limits + hard to modularize & plug in to other workflows; SQL support only
    * Tips:
        1. use pro-version to download the data in csv format; Flipside has batched api processes that’s easy to setup; Dune is also beta releasing api access for select users
        2. Speed up query by exploring through “Explain”
        3. Address labels are helpful: [https://dune.com/labels](https://dune.com/labels)
2. GCP Bigquery
    * [Ethereum-ETL public data](https://github.com/blockchain-etl/ethereum-etl)
    * Indexed by google and accessible as [public data ](https://cloud.google.com/blog/products/data-analytics/introducing-six-new-cryptocurrencies-in-bigquery-public-datasets-and-how-to-analyze-them)
    * Derived Protocol-level data using [ABI parser](https://github.com/nansen-ai/abi-parser)
        4. Events
        5. Traces
    * Support user upload of additional data to be merged
    * _Advantages:_ fast, sql-based, multiple methods to access
    * _Disadvantages_: Lacking stateful data without construction from events/traces; currently only support Ethereum, Polygon; missing Solana data
    * Tips: Use Etherscan or equivalent decoders (e.g. [https://ethtx.info/](https://ethtx.info/)) to extract data
3. Subgraph
    * Stateful data that supplements events/traces
    * _Advantages_: indexing of  data that is not available elsewhere (beyond event emits)
    * _Disadvantages_: very slow + potential unknown data quality depending on the protocol; someone needs to write and maintain the indexer, usually done by dev team from protocols
4. Archive node calls
    * Services such as Moralis make node call easy
    * Used to query on-chain data that is not normally indexed by data providers, e.g. call smart contract functions to extract output that historically might never have been called
    * Usually helpful to use web3.py and web3.js to facilitate calling and parsing the node
    * _Advantages_: ability to extract counterfactual data that was not generated/emitted, or smart contract information that’s not readily available e.g. what would the price impact of trading x amount of token pair be through a dex? Test if a token have fee-on-transfer by calling the contract
    * _Disadvantages_: running a node is expensive and function calls are slower than obtaining parsed data if data exists
5. Other data sources
    * Nansen.ai : Has labeling of addresses that can be useful
    * TRM Labs/Chainalysis: mapping of addresses to entities, particularly KYC’d entities

**<span style="text-decoration:underline;">Helpful blog posts</span>**



* [https://alexkroeger.mirror.xyz/0C3EQBtFqAK4k2TAGPZhg0JMY-upfTAxuTD-o91vBPc](https://alexkroeger.mirror.xyz/0C3EQBtFqAK4k2TAGPZhg0JMY-upfTAxuTD-o91vBPc)
* [https://medium.com/linum-labs/everything-you-ever-wanted-to-know-about-events-and-logs-on-ethereum-fec84ea7d0a5](https://medium.com/linum-labs/everything-you-ever-wanted-to-know-about-events-and-logs-on-ethereum-fec84ea7d0a5)
* [https://medium.com/coinmonks/querying-data-in-an-ethereum-blockchain-86289d3fc385](https://medium.com/coinmonks/querying-data-in-an-ethereum-blockchain-86289d3fc385)
* [https://twitter.com/Logvinov_Leon/status/1481618513806696451](https://twitter.com/Logvinov_Leon/status/1481618513806696451)
* [https://towardsdatascience.com/graphql-walkthrough-how-to-query-crypto-with-uniswap-defi-e0cbe2035290](https://towardsdatascience.com/graphql-walkthrough-how-to-query-crypto-with-uniswap-defi-e0cbe2035290)
