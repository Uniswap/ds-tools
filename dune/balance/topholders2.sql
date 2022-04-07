WITH addresses AS (SELECT '\x1f9840a85d5af5bf1d1762f925bdaddc4201f984' AS address),
thresh as (SELECT 0 as threshhold ),
decimals as (SELECT 18 as decimals ),

alles as (
  SELECT  address,
          case when y.lables isnull then 'smart contract'
          else y.lables end as labels,
          amount
          from
  (

  SELECT  cast (labels as text) as lables,
          address,
          amount
  from
  (
  SELECT
  address,
  labels.get(address) AS labels,
  SUM(amount) as amount
  FROM
      (
      -- IN
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

      UNION

      -- IN
      SELECT a."from" as address,
          -1*sum(value/(10^decimals)) amount
      FROM decimals,
          (SELECT "from"
          FROM erc20."ERC20_evt_Transfer"
          WHERE contract_address = '\x1f9840a85d5af5bf1d1762f925bdaddc4201f984'
          GROUP BY "from") a left outer join
              (SELECT *
              FROM erc20."ERC20_evt_Transfer"
              WHERE contract_address = '\x1f9840a85d5af5bf1d1762f925bdaddc4201f984') b on
              a."from" = b."from"

      GROUP BY a."from"
      ) c
  GROUP BY address
  ORDER BY amount desc
  ) as x) as y

),

agg as(

select  address,
        amount from alles, thresh
where amount > threshhold
order by amount desc
)

SELECT sum(amount), address
from agg
group by 2
