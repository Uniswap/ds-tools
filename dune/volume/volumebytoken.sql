SELECT
sum(usd_amount) as volume, count(trader_a) as ntraders, count(usd_amount) as ct, token_a_symbol, token_b_symbol, token_a_address, token_b_address
FROM dex.trades where project='Uniswap' and date_trunc('day',block_time)>'2022-01-09'
group by  token_a_address, token_b_address, token_a_symbol, token_b_symbol
limit 10
-- select distinct project from dex.trades
