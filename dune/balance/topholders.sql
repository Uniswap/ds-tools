WITH transfers AS (
    SELECT
    evt_block_time,
    tr."from" AS address,
    -tr.value AS amount,
    contract_address
     FROM erc20."ERC20_evt_Transfer" tr
    WHERE contract_address = '\x1f9840a85d5af5bf1d1762f925bdaddc4201f984'


UNION ALL

    SELECT
    evt_block_time,
    tr."to" AS address,
    tr.value AS amount,
      contract_address
     FROM erc20."ERC20_evt_Transfer" tr
     WHERE contract_address = '\x1f9840a85d5af5bf1d1762f925bdaddc4201f984'

)

    SELECT
    address,
    sum(amount/10^decimals) as balance
    FROM transfers tr
    LEFT JOIN erc20.tokens tok ON tr.contract_address = tok.contract_address
    GROUP BY 1
    ORDER BY 2 DESC
    LIMIT 10
    ;
