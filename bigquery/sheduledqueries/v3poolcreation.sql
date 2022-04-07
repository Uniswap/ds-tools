CREATE TEMP FUNCTION
  PARSE_LOG(data STRING, topics ARRAY<STRING>)
  RETURNS STRUCT<`token0` STRING, `token1` STRING, `fee` STRING, `tickSpacing` STRING, `pool` STRING>
  LANGUAGE js AS """
    var parsedEvent = {"anonymous": false, "inputs": [{"indexed": true, "internalType": "address", "name": "token0", "type": "address"}, {"indexed": true, "internalType": "address", "name": "token1", "type": "address"}, {"indexed": true, "internalType": "uint24", "name": "fee", "type": "uint24"}, {"indexed": false, "internalType": "int24", "name": "tickSpacing", "type": "int24"}, {"indexed": false, "internalType": "address", "name": "pool", "type": "address"}], "name": "PoolCreated", "type": "event"}
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
WHERE address = '0x1f98431c8ad98523631ae4a59f267346ea31f984'
  AND topics[SAFE_OFFSET(0)] = '0x783cca1c0412dd0d695e784568c96da2e9c22ff989357a2e8b1d9b2b4e6b7118'
)
SELECT
     block_timestamp
     ,block_number
     ,transaction_hash
     ,log_index
    ,parsed.token0 AS `token0`
    ,parsed.token1 AS `token1`
    ,parsed.fee AS `fee`
    ,parsed.tickSpacing AS `tickSpacing`
    ,parsed.pool AS `pool`
FROM parsed_logs