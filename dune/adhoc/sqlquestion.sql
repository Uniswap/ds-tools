

-- Why is the 1st query so much faster than the second though effectively they are the same?ABS

-- 1
WITH addresses AS (SELECT '\x1f9840a85d5af5bf1d1762f925bdaddc4201f984' AS address),
thresh as (SELECT 0 as threshhold ),
decimals as (SELECT 18 as decimals )

SELECT a."to" as address,
          sum(value/(10^decimals)) amount
      FROM  decimals,
          (SELECT "to"
          FROM erc20."ERC20_evt_Transfer"
          WHERE contract_address = '\x1f9840a85d5af5bf1d1762f925bdaddc4201f984'
          GROUP BY "to") a left outer join
              (SELECT *
              FROM erc20."ERC20_evt_Transfer"
              WHERE contract_address = '\x1f9840a85d5af5bf1d1762f925bdaddc4201f984') b on
              a."to" = b."to"
      GROUP BY a."to"

-- 2
  SELECT
  evt_block_time,
  tr."to" AS address,
  tr.value AS amount,
    contract_address
   FROM erc20."ERC20_evt_Transfer" tr
   WHERE contract_address = '\x1f9840a85d5af5bf1d1762f925bdaddc4201f984'
