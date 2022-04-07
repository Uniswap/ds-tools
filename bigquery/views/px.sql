create view px
as
select * from (

                  select pl.block_timestamp, pl.block_number, pl.address, ptd.token0, ptd.token1, ptd.token0symbol,ptd.token1symbol,
                         pow(10,ptd.decimals1-ptd.decimals0)/pow(cast(pl.sqrtPriceX96 as float64)/pow(2,96),2) as price,
                         pl.tick, pl.sqrtPriceX96, ptd.decimals0,ptd.decimals1, ptd.fee, ptd.tickSpacing
                  from uniswap.price pl left join `mimetic-design-338620.uniswap.pools_tokens_decimals` ptd on ptd.pool=pl.address)

where price is not null order by block_number desc;

