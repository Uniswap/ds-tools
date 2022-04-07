
select pools.*, tk0.symbol as token0symbol, cast(tk0.decimals as int) as decimals0, tk1.symbol as token1symbol, cast(tk1.decimals as int) as decimals1 from `mimetic-design-338620.uniswap.V3Factory_PoolCreated` pools 
left join `bigquery-public-data.crypto_ethereum.amended_tokens` tk0 on pools.token0=tk0.address
left join `bigquery-public-data.crypto_ethereum.amended_tokens` tk1 on pools.token1=tk1.address

