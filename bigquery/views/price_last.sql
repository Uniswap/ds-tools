create view price_last
as

WITH px AS (
  SELECT p.*, ROW_NUMBER() OVER (PARTITION BY address ORDER BY block_number DESC) AS rn
  FROM uniswap.price AS p
)
SELECT * FROM px WHERE rn = 1;

