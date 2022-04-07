CREATE TEMP FUNCTION
  PARSE_LOG(data STRING, topics ARRAY<STRING>)
  RETURNS STRUCT<`tokenId` STRING, `liquidity` STRING, `amount0` STRING, `amount1` STRING>
  LANGUAGE js AS """
    var parsedEvent = {"anonymous": false, "inputs": [{"indexed": true, "internalType": "uint256", "name": "tokenId", "type": "uint256"}, {"indexed": false, "internalType": "uint128", "name": "liquidity", "type": "uint128"}, {"indexed": false, "internalType": "uint256", "name": "amount0", "type": "uint256"}, {"indexed": false, "internalType": "uint256", "name": "amount1", "type": "uint256"}], "name": "IncreaseLiquidity", "type": "event"}
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
    ,PARSE_LOG(logs.data, logs.topics) AS parsed
FROM `bigquery-public-data.crypto_ethereum.logs` AS logs
WHERE address = '0xc36442b4a4522e871399cd717abdd847ab11fe88'
  AND topics[SAFE_OFFSET(0)] = '0x3067048beee31b25b2f1681f88dac838c8bba36af25bfb2b7cf7473a5847e35f'
)
SELECT
     block_timestamp
     ,block_number
     ,transaction_hash
     ,log_index
    ,parsed.tokenId AS `tokenId`
    ,parsed.liquidity AS `liquidity`
    ,parsed.amount0 AS `amount0`
    ,parsed.amount1 AS `amount1`
FROM parsed_logs