
-- this query computes cumulative unique number of LPs for each token on Uniswap, V2 + V3

-- set time range
DECLARE from_date DATE DEFAULT '2020-04-01';
DECLARE to_date DATE DEFAULT CURRENT_DATE();

with union_23 as (
    -- union V2 and V3 swaps
    SELECT  -- this is for V2
            address as pool_address,
            DATE(v2.block_timestamp) AS mint_time,
            v2.transaction_hash,
            v2_fac.token0,
            v2_fac.token1,
            '2' as version
    FROM `mimetic-design-338620.uniswap.Mint_V2`  v2
        LEFT JOIN `mimetic-design-338620.uniswap.V2_Factory`v2_fac
    ON v2.address = v2_fac.pair
    WHERE DATE(v2.block_timestamp) > from_date
      AND DATE(v2.block_timestamp) < to_date

    UNION ALL

    SELECT  -- this is for V3
        address as pool_address,
        DATE(v3.block_timestamp) AS mint_time,
        v3.transaction_hash,
        v3_fac.token0,
        v3_fac.token1,
        '3' as version
    FROM `mimetic-design-338620.uniswap.MintBurn`   v3
        LEFT JOIN `mimetic-design-338620.uniswap.V3Factory_PoolCreated`v3_fac
    ON v3.address = v3_fac.pool
    WHERE DATE(v3.block_timestamp) > from_date
      AND DATE(v3.block_timestamp) < to_date
      AND v3.amount > 0
),

     token_mint_history as (
         SELECT
             union_23.pool_address,
             union_23.mint_time,
             union_23.transaction_hash,
             union_23.token0 as token,
             union_23.version,
             tx.from_address as tx_from,
             tx.to_address as tx_to
         FROM union_23
                  LEFT JOIN `bigquery-public-data.crypto_ethereum.transactions` tx
         ON union_23.transaction_hash = tx.hash

         UNION ALL

         SELECT
             union_23.pool_address,
             union_23.mint_time,
             union_23.transaction_hash,
             union_23.token1 as token,
             union_23.version,
             tx.from_address as tx_from,
             tx.to_address as tx_to
         FROM union_23
             LEFT JOIN `bigquery-public-data.crypto_ethereum.transactions` tx
         ON union_23.transaction_hash = tx.hash
     ),

     first_mint_by_user as (
         SELECT
             token,
             tx_from as minter,
             min(mint_time) as first_mint_time
         FROM token_mint_history
         GROUP BY token, minter
     ),

     unique_minter_count_by_date_by_token as (
         SELECT
             token,
             first_mint_time as as_of_date,
             ROW_NUMBER() OVER(PARTITION BY token
                 ORDER BY first_mint_time ASC) AS count_user
         FROM first_mint_by_user
     ),

     cumulative_unique_minter_count_by_date_by_token_with_missing_dates as (
         SELECT
             token,
             as_of_date,
             max(count_user) as cumulative_unique_user
         FROM unique_minter_count_by_date_by_token
         GROUP BY token, as_of_date
         ORDER BY token, as_of_date DESC
     ),

     all_dates as (
         SELECT
             *
         FROM UNNEST(GENERATE_DATE_ARRAY(from_date, to_date, INTERVAL 1 DAY)) as calendar_date
     ),

     token_date_range as (
         SELECT
             token,
             min(as_of_date) as token_min_date,
             to_date as token_max_date
         FROM cumulative_unique_minter_count_by_date_by_token_with_missing_dates
         GROUP BY token
     )
        ,

     token_in_range_dates as (
         SELECT
             token,
             a.calendar_date
         FROM token_date_range r
                  INNER JOIN all_dates a
                             ON a.calendar_date BETWEEN r.token_min_date AND r.token_max_date
     ),


     minter_count_date_up_to AS
         (
             SELECT
                 t1.token,
                 t1.calendar_date,
                 t2.cumulative_unique_user,
                 t2.as_of_date,
                 ROW_NUMBER() OVER
                     (
                     PARTITION BY t1.token, t1.calendar_date
                     ORDER BY t2.as_of_date DESC
                     ) AS RowNum -- this logic is to get the most recent cumulative minter count
             FROM token_in_range_dates t1
                      INNER JOIN cumulative_unique_minter_count_by_date_by_token_with_missing_dates t2
                                 ON t1.token = t2.token
                                     AND t2.as_of_date <= t1.calendar_date
         )

select * from minter_count_date_up_to
WHERE RowNum = 1
ORDER BY token, calendar_date ASC
;

