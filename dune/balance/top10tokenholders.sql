WITH top_holders AS
(
    SELECT address, SUM(amount) AS token_balance
    FROM (

    SELECT "from" AS address, -SUM(value/10^'{{token decimals}}') AS amount
    FROM erc20."ERC20_evt_Transfer"
    WHERE contract_address = CONCAT('\x', substring('{{token address}}' from 3))::bytea -- Token address
    GROUP BY 1

    UNION ALL

    SELECT "to" AS address, SUM(value/10^'{{token decimals}}') AS amount
    FROM erc20."ERC20_evt_Transfer"
    WHERE contract_address = CONCAT('\x', substring('{{token address}}' from 3))::bytea -- Token address
    GROUP BY 1

    ) to_from
    GROUP BY 1
    ORDER BY 2 DESC
    LIMIT 10
)

, last_7days AS (
    SELECT address, SUM(amount) AS change_7days
    FROM (

    SELECT "from" AS address, -SUM(value/10^'{{token decimals}}') AS amount
    FROM erc20."ERC20_evt_Transfer"
    WHERE contract_address = CONCAT('\x', substring('{{token address}}' from 3))::bytea -- Token address
    AND evt_block_time > now() - interval '7 days'
    AND "from" IN (SELECT address FROM top_holders)
    GROUP BY 1

    UNION ALL

    SELECT "to" AS address, SUM(value/10^'{{token decimals}}') AS amount
    FROM erc20."ERC20_evt_Transfer"
    WHERE contract_address = CONCAT('\x', substring('{{token address}}' from 3))::bytea -- Token address
    AND evt_block_time > now() - interval '7 days'
    AND "to" IN (SELECT address FROM top_holders)
    GROUP BY 1

    ) to_from
    GROUP BY 1
    ORDER BY 2 DESC
)

SELECT labels.url(th.address) AS address,
        labels.get(th.address, 'owner', 'project') AS labels,
        token_balance,
        token_balance*(
                        SELECT price
                        FROM prices."usd"
                        WHERE contract_address = CONCAT('\x', substring('{{token address}}' from 3))::bytea -- Token address
                        ORDER BY minute desc
                        LIMIT 1
                    ) AS usd_value_balance,
        change_7days
FROM top_holders th
LEFT JOIN last_7days sd ON th.address = sd.address
;
