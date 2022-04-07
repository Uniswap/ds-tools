CREATE TEMP FUNCTION
  PARSE_LOG(data STRING, topics ARRAY<STRING>)
  RETURNS STRUCT<`sender` STRING, `recipient` STRING, `amount0` STRING, `amount1` STRING, `sqrtPriceX96` STRING, `liquidity` STRING, `tick` STRING>
  LANGUAGE js AS """
    var parsedEvent = {"anonymous": false, "inputs": [{"indexed": true, "internalType": "address", "name": "sender", "type": "address"}, {"indexed": true, "internalType": "address", "name": "recipient", "type": "address"}, {"indexed": false, "internalType": "int256", "name": "amount0", "type": "int256"}, {"indexed": false, "internalType": "int256", "name": "amount1", "type": "int256"}, {"indexed": false, "internalType": "uint160", "name": "sqrtPriceX96", "type": "uint160"}, {"indexed": false, "internalType": "uint128", "name": "liquidity", "type": "uint128"}, {"indexed": false, "internalType": "int24", "name": "tick", "type": "int24"}], "name": "Swap", "type": "event"}
    return abi.decodeEvent(parsedEvent, data, topics, false);
"""
OPTIONS
  ( library="https://storage.googleapis.com/ethlab-183014.appspot.com/ethjs-abi.js" );

WITH parsed_logs AS
(SELECT
    logs.block_timestamp AS block_timestamp
    ,logs.block_number AS block_number
    ,logs.transaction_hash AS transaction_hash
    ,logs.log_index AS log_index
    ,logs.address as address
    ,PARSE_LOG(logs.data, logs.topics) AS parsed
FROM `bigquery-public-data.crypto_ethereum.logs` AS logs
WHERE  topics[SAFE_OFFSET(0)] = '0xc42079f94a6350d7e6235f29174924f928cc2ac818eb64fed8004e115fbcca67'
)
SELECT
     block_timestamp
     ,block_number
     ,transaction_hash
     ,log_index
    ,parsed.sender AS `sender`
    ,parsed.recipient AS `recipient`
    ,parsed.amount0 AS `amount0`
    ,parsed.amount1 AS `amount1`
    ,parsed.sqrtPriceX96 AS `sqrtPriceX96`
    ,parsed.liquidity AS `liquidity`
    ,parsed.tick AS `tick`
    ,address 
FROM parsed_logs