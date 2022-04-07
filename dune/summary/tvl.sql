# INCORRECT SINCE UNCOLLECTED FEES ARE NOT ACCOUNTED FOR
-- select all pools
WITH pools AS
(
SELECT
    pool,
    token0,
    token1
FROM uniswap_v3."Factory_evt_PoolCreated" where pool='\x8ad599c3a0ff1de082011efddc58f1908eb6e6d8'
),

-- select net deposits as: mint - burn + swap (into)
net_deposits AS
(
SELECT
    dt,
    token0,
    sum(total_token_a) as token_a_amount,
    token1,
    sum(total_token_b) as token_b_amount,
    pool
FROM (
    SELECT
        date_trunc('day', evt_block_time) as dt,
        token0,
        sum(amount0) as total_token_a,
        token1,
        sum(amount1) as total_token_b,
        p.pool
    FROM uniswap_v3."Pair_evt_Mint" m
    LEFT JOIN pools p ON m.contract_address = p.pool
    GROUP BY dt, token0, token1, pool

    UNION

    SELECT
        date_trunc('day', evt_block_time) as dt,
        token0,
        sum(-amount0) as total_token_a,
        token1,
        sum(-amount1) as total_token_b,
        p.pool
    FROM uniswap_v3."Pair_evt_Burn" m
    LEFT JOIN pools p ON m.contract_address = p.pool
    GROUP BY dt, token0, token1, pool

    UNION

    SELECT
        date_trunc('day', evt_block_time) as dt,
        token0,
        sum(amount0) as total_token_a,
        token1,
        sum(amount1) as total_token_b,
        pools.pool
    FROM uniswap_v3."Pair_evt_Swap" s
    LEFT JOIN pools ON s.contract_address = pools.pool
    GROUP BY dt, token0, token1, pool
    ) as net
GROUP BY dt, token0, token1, pool
),

-- add up dtly sums to get dtly cumulative sum
token_amounts AS
(
SELECT
    dt,
    symbol,
    pool,
    sum(cumulative_token_balance) as token_balance
FROM (
    SELECT
        dt,
        symbol,
        pool,
        sum(sum(token_a_amount/10^decimals)) over (partition by symbol, pool order by dt) as cumulative_token_balance
    FROM net_deposits n
    LEFT JOIN erc20."tokens" t ON t.contract_address = n.token0
    GROUP BY dt, symbol, pool

    UNION

    SELECT
        dt,
        symbol,
        pool,
        sum(sum(token_b_amount/10^decimals)) over (partition by symbol, pool order by dt) as cumulative_token_balance
    FROM net_deposits n
    LEFT JOIN erc20."tokens" t ON t.contract_address = n.token1
    GROUP BY dt, symbol, pool
    ) as net

GROUP BY dt, symbol, pool
),

-- get token prices
prices AS
(
SELECT
    minute,
    symbol,
    price
FROM prices.usd
)

-- multiply token amounts with token price to get USD token balances
SELECT
    dt,
    -- count(distinct symbol) as count_token,
    -- pool,
    sum(token_balance) as tvlusd
FROM (
    SELECT
        dt,
        t.symbol,
        t.pool,
        sum(token_balance * p.price) as token_balance
    FROM token_amounts t
    LEFT JOIN prices p ON date_trunc('minute', t.dt) = p.minute AND t.symbol = p.symbol
    GROUP BY dt, t.symbol, t.pool
    ) as net
WHERE token_balance > 0
GROUP BY dt, pool
ORDER BY dt asc, tvlusd desc
