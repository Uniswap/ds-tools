create view px_daily
as
select * from (
                  SELECT date_trunc(block_timestamp,day) as date, block_timestamp, block_number, address, token0symbol,token1symbol, token0, token1, price, tick,
                         row_number() over (partition by date_trunc(block_timestamp,day), address order by block_number desc) as rn
                  FROM `mimetic-design-338620.uniswap.px` ) where rn=1 order by block_number;

