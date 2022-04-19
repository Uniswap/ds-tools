-- This mirrors Dune query https://dune.xyz/queries/483828/916537

WITH
    eth_price AS (
    SELECT
        date_trunc('{{frequency}}', minute) as period,
        avg(price) as price
    FROM prices.usd
    WHERE symbol = 'WETH'
      AND minute > now() - interval '{{history length}} {{frequency}}'
    GROUP BY period
),

     volume AS
         (
             SELECT
                 date_trunc('{{frequency}}', block_time) as period,
                 sum(usd_amount) as volume
             FROM dex."trades"
             WHERE project = 'Uniswap'
               AND block_time > now() - interval '{{history length}} {{frequency}}'
             GROUP BY period
         )

SELECT
    v.period,
    volume,
    price as ETH_price
FROM volume v
         LEFT JOIN eth_price p ON v.period = p.period
ORDER BY period desc

