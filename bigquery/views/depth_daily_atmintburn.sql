create view depth_daily_atmintburn
as
select md.date, md.pct, md.block_number, md. address, md.marketdepth as depth0,
       md.unit_token0 as token0, ptd.token1symbol as token1, ptd.fee, ptd.tickSpacing,
       pd.price, md.marketdepth/pd.price as depth1
from uniswap.marketdepth md left join uniswap.pools_tokens_decimals ptd on md.address=ptd.pool
                                  left join uniswap.px_daily pd on md.date=pd.date and md.address=pd.address;

