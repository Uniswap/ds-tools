WITH agg AS
(
SELECT
    t.*,
    AVG (profit_usd / cost_usd) over (order by time rows between 24 preceding and current row) as profit_margin_smooth_24,
    AVG (profit_usd / cost_usd) over (order by time rows between 72 preceding and current row) as profit_margin_smooth_72,

    AVG (profit_usd / (cost_usd * .1)) over (order by time rows between 24 preceding and current row) as profit_margin_L2_smooth_24,
    AVG (profit_usd / (cost_usd * .1)) over (order by time rows between 72 preceding and current row) as profit_margin_L2_smooth_72,

 --   AVG (IF (cost_usd <= 0, 0, profit_usd / cost_usd)) over (order by time rows between 24 preceding and current row) as profit_margin_smooth_24,
    SUM (profit_usd) OVER (ORDER BY time) as culm_profit,
    SUM (cost_usd) OVER (ORDER BY time) as culm_cost,
    SUM (revenue_usd) OVER (ORDER BY time) as culm_revenue
FROM
(
    SELECT
        DISTINCT
        add."call_block_time" as time,
        tx_add."from",
        tx_add."to",
        add.call_block_number as block_number,
        add."call_tx_hash" as add_hash,
        remove."call_tx_hash" as remove_hash,

        add_liq."amount0" as add_amount0,
        add_liq."amount1" as add_amount1,

        add_liq."amount0" / 10 ^ p0.decimals * p0.median_price as add_amount0_usd,
        add_liq."amount1" / 10 ^ p1.decimals * p1.median_price as add_amount1_usd,

        token0."contract_address" as token0_address,
        token1."contract_address" as token1_address,

        p0.median_price,
        p1.median_price,

        collect."amount0" as remove_amount0,
        collect."amount1" as remove_amount1,

        collect."amount0" / 10 ^ p0.decimals * p0.median_price as remove_amount0_usd,
        collect."amount1" / 10 ^ p1.decimals * p1.median_price as remove_amount1_usd,

        (collect."amount0" / 10 ^ p0.decimals * p0.median_price - add_liq."amount0" / 10 ^ p0.decimals * p0.median_price) + (collect."amount1" / 10 ^ p1.decimals * p1.median_price - add_liq."amount1" / 10 ^ p1.decimals * p1.median_price) as revenue_usd,

        CASE
            WHEN tx_add.gas_price != 0 THEN tx_add.gas_used * tx_add.gas_price * weth_price.median_price / 10 ^ 18
            ELSE 0
        END add_cost_usd,

        CASE
            WHEN tx_add.gas_price != 0 THEN tx_remove.gas_used * tx_remove.gas_price * weth_price.median_price / 10 ^ 18
            ELSE eth_miner_bribe.value * weth_price.median_price / 10 ^ 18
        END remove_cost_usd,

        CASE
            WHEN tx_add.gas_price != 0 THEN tx_add.gas_used * tx_add.gas_price * weth_price.median_price / 10 ^ 18 + tx_remove.gas_used * tx_remove.gas_price * weth_price.median_price / 10 ^ 18  + (eth_miner_bribe.value * weth_price.median_price / 10 ^ 18)
            ELSE eth_miner_bribe.value * weth_price.median_price / 10 ^ 18
        END cost_usd,

        CASE
            WHEN tx_add.gas_price != 0 THEN
            (collect."amount0" / 10 ^ p0.decimals * p0.median_price - add_liq."amount0" / 10 ^ p0.decimals * p0.median_price) + (collect."amount1" / 10 ^ p1.decimals * p1.median_price - add_liq."amount1" / 10 ^ p1.decimals * p1.median_price)
                - (tx_add.gas_used * tx_add.gas_price * weth_price.median_price / 10 ^ 18 + tx_remove.gas_used * tx_remove.gas_price * weth_price.median_price / 10 ^ 18) - eth_miner_bribe.value * weth_price.median_price / 10 ^ 18
            ELSE
            (collect."amount0" / 10 ^ p0.decimals * p0.median_price - add_liq."amount0" / 10 ^ p0.decimals * p0.median_price) + (collect."amount1" / 10 ^ p1.decimals * p1.median_price - add_liq."amount1" / 10 ^ p1.decimals * p1.median_price)
                - eth_miner_bribe.value * weth_price.median_price / 10 ^ 18
        END profit_usd

    --    "output_tokenId"
    --    tokenURI."output_0"
    FROM uniswap_v3."NonfungibleTokenPositionManager_call_burn" remove
    INNER JOIN uniswap_v3."NonfungibleTokenPositionManager_call_mint" add ON add.call_block_number = remove.call_block_number and
                                                                             add."output_tokenId" = remove."tokenId"

    INNER JOIN uniswap_v3."NonfungibleTokenPositionManager_evt_Collect" collect on remove."call_tx_hash" = collect.evt_tx_hash AND remove."tokenId" = collect."tokenId"
    INNER JOIN uniswap_v3."NonfungibleTokenPositionManager_evt_IncreaseLiquidity" add_liq ON add_liq.evt_tx_hash = add.call_tx_hash

    LEFT JOIN erc20."ERC20_evt_Transfer" token0 ON token0.value = add_liq."amount0"and token0."evt_tx_hash" = add_liq."evt_tx_hash"
    LEFT JOIN erc20."ERC20_evt_Transfer" token1 ON token1.value = add_liq."amount1"and token1."evt_tx_hash" = add_liq."evt_tx_hash"

    LEFT JOIN prices.prices_from_dex_data p0 ON p0."contract_address" = token0."contract_address" AND p0.hour = date_trunc('hour', token0.evt_block_time)
    LEFT JOIN prices.prices_from_dex_data p1 ON p1."contract_address" = token1."contract_address" AND p1.hour = date_trunc('hour', token1.evt_block_time)

    LEFT JOIN prices.prices_from_dex_data weth_price ON weth_price.symbol = 'WETH' AND weth_price.hour = date_trunc('hour', add.call_block_time)

    INNER JOIN ethereum.transactions tx_add ON tx_add.hash = add.call_tx_hash
    INNER JOIN ethereum.transactions tx_remove ON tx_remove.hash = remove.call_tx_hash

    INNER JOIN ethereum.blocks block on tx_remove.block_number = block."number"

    -- pre eip, there might be a bribe
    LEFT JOIN  ethereum.traces eth_miner_bribe ON eth_miner_bribe.tx_hash = remove."call_tx_hash" AND eth_miner_bribe.success = True AND eth_miner_bribe."to" = block.miner AND (call_type NOT IN ('delegatecall', 'callcode', 'staticcall') OR call_type IS null)


    WHERE token0.contract_address IS NOT NULL
        AND token1.contract_address IS NOT NULL

) t
WHERE cost_usd != 0
),

clean AS
(
SELECT
time,
"add_amount0_usd",
"add_amount1_usd",
"remove_amount0_usd",
"remove_amount1_usd",
"add_amount0_usd"-"remove_amount0_usd" as "0_diff",
"add_amount1_usd"-"remove_amount1_usd" as "1_diff"
FROM agg
)

SELECT
date_trunc('month', time) as month,
sum(JIT_volume) as JIT_volume
FROM
(
SELECT
time,
abs("0_diff") as JIT_volume
FROM clean
) as net
GROUP BY 1
ORDER BY 1 desc
