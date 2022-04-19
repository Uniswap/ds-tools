-- this query mirrors https://dune.xyz/queries/463288/879957 on Dune Analytics

SELECT
    DATE_TRUNC('{{frequency}}', block_time) as date1,
    case
        WHEN project = 'Uniswap'
            OR project = 'Sushiswap'
            OR project = 'Curve'
            OR project = '0x Native'
            OR project = 'Balancer'
            THEN project
        ELSE 'Other'
        END as project_version,
    SUM(usd_amount) as volume,
    COUNT(distinct tx_from) as unique_trader_count,
    COUNT(tx_hash) as number_of_trades
FROM dex.trades trades
WHERE block_time > DATE_TRUNC('{{frequency}}',now()) - interval '{{history length}} {{frequency}}'
  AND trades.category = 'DEX'
  AND tx_hash NOT in (
    SELECT distinct tx_hash FROM dex.trades WHERE category = 'Aggregator' AND block_time > DATE_TRUNC('{{frequency}}',now()) - interval '{{history length}} {{frequency}}'
)
GROUP BY date1, project_version



