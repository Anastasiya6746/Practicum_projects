/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор:Макарова Анастасия Александровна 
 * Дата: 05.12.2024
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
-- 
SELECT COUNT(payer) AS COUNT_payer,
sum(payer) as sum_payer,
avg(payer) as avg_payer
FROM fantasy.users

Вывод: Доля платящих игроков составляет 17% от общего числа игроков.

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
-- Напишите ваш запрос здесь
SELECT race,
COUNT(payer) AS COUNT_user,
sum(payer) as user_payer,
sum(payer)/COUNT(payer)::real as payer_doly
FROM fantasy.users
join fantasy.race on users.race_id=race.race_id
group by race

Вывод: раса персонажа почти не влияет на количество платящих игроков. Доля платящих составляет ы основном примерно 17%. 
В расе Demon и Hobit доля платящих игроков выше 0,19 и 0,18 соответвенно. 

-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
-- Напишите ваш запрос здесь
SELECT 
COUNT(transaction_id) AS COUNT_transaction,
sum(amount ) as sum_amount ,
min(amount ) as min_amount,
max(amount ) as max_amount,
avg(amount ) as avg_amount,
PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY amount ) AS med_tamount ,
STDDEV(amount ) AS A_amount 
FROM fantasy.events

Выводы: Всего было сделано 1 307 678 покупок на общую сумму 686 615 040 в валюте «райские лепестки».
минимальная стоимость покупки - 0 (такие покупки нужно детально изучить), максимальная- 486 615. Сребнее значение покупок - 525. Медиана - 74,
стандартное отклонение - 2517.

-- 2.2: Аномальные нулевые покупки:
-- Напишите ваш запрос здесь
вычисляем количество нулевых покупок и их долю среди всех покупок:
with coun as (SELECT 
COUNT(amount) AS COUNT_nul
FROM fantasy.events
where amount=0)
select COUNT_nul, 
COUNT_nul::real/(SELECT 
COUNT(transaction_id) AS COUNT_transaction FROM fantasy.events) as doly
from coun

Вывод:Получилось 907 нулевых покупок. Доля таких покупок составляет очень маленькую часть 0,069%.

-- 2.3: Сравнительный анализ активности платящих и неплатящих игроков:
-- Напишите ваш запрос здесь
with count_u as 
(SELECT payer,
count(distinct users.id) AS count_usery,
Count(amount)  AS avg_pok,
sum(amount) AS sum_pok
FROM fantasy.events
join fantasy.users on events.id=users.id
where amount>0
group by payer
)
select payer,
count_usery,avg_pok,
avg_pok::real/count_usery as avg_pokupka,
sum_pok/count_usery as avg_sum
from count_u

Вывод: неплатящих игроков больше. Неплатящих - 11 348, платящих - 2 444. Зато у неплатящих
большее количество покупок (1 107 145), чем у неплатящих (199 626). Так же у неплатящих большее количество покупок на
на 1 игрока (97), чем у платящих (81). Зато у платящих выше средняя стоимость покупки на 1 человека (55), сем у неплатящих (48).

-- 2.4: Популярные эпические предметы:
-- Напишите ваш запрос здесь
WITH orders_stat AS
(  SELECT
  COUNT(DISTINCT transaction_id) AS total_orders, 
  COUNT(DISTINCT id ) AS total_users
  FROM fantasy.events
  where amount>0 )
sELECT
 items.game_items AS game_item,
 count(DISTINCT events.transaction_id) AS total_orders,
 COUNT(DISTINCT events.id) AS total_users,
 (COUNT(events.transaction_id)::real / (SELECT total_orders FROM orders_stat)*100)::numeric(6,4) AS доля_продаж,
 (COUNT(DISTINCT events.id)::real / (SELECT total_users FROM orders_stat)*100)::numeric(6,4) AS доля_игроков
FROM fantasy.events 
LEFT JOIN fantasy.items ON events.item_code = items.item_code
where amount>0
GROUP BY game_item
order by total_orders desc

Вывод: Самые популярные предметы: Book legends-1 004 516 общее количество продаж, 
Bag OF holding - 271 875 количество продаж. Эти предметы покупают чаще остальных.
И их покупает более количество игроков.

-- Часть 2. Решение ad hoc-задач
-- Задача 1. Зависимость активности игроков от расы персонажа:
-- Напишите ваш запрос здесь
WITH reg_users_data AS (
 SELECT
 DISTINCT race.race AS race,
 COUNT(users.id) OVER(PARTITION BY race.race) AS total_players,
 SUM(users.payer) OVER(PARTITION BY race.race) AS total_payers
 FROM fantasy.users
 LEFT JOIN fantasy.race on  race.race_id=users.race_id
),
user_events_data AS 
( select distinct
        e.id
        , r.race AS race
        , u.payer,
        count( e.id) as кол_сов_покупки,
        count( transaction_id) AS кол_во_покупок,
        sum ( amount) AS стоимость_всех_покупок
    FROM fantasy.events AS e
         LEFT JOIN fantasy.users AS u 
                ON u.id = e.id
         LEFT JOIN fantasy.race AS r 
                ON u.race_id = r.race_id
    WHERE e.amount > 0
     group by race,e.id,u.payer)
, purchases_users_data as
( SELECT race , 
COUNT(payer) AS total_players_w_purch ,
SUM(payer) AS total_payers_w_purch
    from  user_events_data
    group by race),
users_stat AS (
 SELECT
 DISTINCT events.id,race.race,
 COUNT(events.transaction_id) OVER(PARTITION BY events.id, race.race) AS total_purchases,
 SUM(events.amount) OVER(PARTITION BY events.id, race.race) AS total_amount,
 AVG(events.amount) OVER(PARTITION BY events.id, race.race) AS avg_amount
 FROM fantasy.events
join fantasy.users on  events.id=users.id
join fantasy.race on  race.race_id=users.race_id
 Where amount>0
), races_stat as  
(    SELECT
        race
        , COUNT(id)
        , AVG(total_purchases)::numeric(8,2) AS avg_purc_per_player
        , AVG(total_amount)::numeric(8,2) AS avg_total_amount_per_player
       , avg(total_amount)::numeric(8,2)/avg(total_purchases) as ср_стоимость_покупки
    FROM users_stat
    GROUP BY race
)
SELECT
    rud.race AS race
     , rud.total_players
    , pud.total_players_w_purch
    , (pud.total_players_w_purch::real / rud.total_players)::numeric(4,3) AS players_w_purch_share
    , (pud.total_payers_w_purch::real / pud.total_players_w_purch)::numeric(4,3) AS payers_w_purch
    , rs.avg_purc_per_player
    , rs.avg_total_amount_per_player
    , rs.ср_стоимость_покупки
FROM races_stat as rs
    LEFT JOIN reg_users_data AS rud ON rs.race = rud.race
    LEFT JOIN purchases_users_data AS pud ON rs.race = pud.race
ORDER BY rs.race

Вывод: В рассах Human -6328 зарег. поль, Hobbit- 3648 зарег. поль и Orc - 3619 зарег. поль.
больше всего зарегистрированных пользователей, 
а так же покупающих, количество покупающих пользователей: Human -3921, Hobbit -2266 и Orc -2276.
Доля покупающих примерно одинаковая, но у рассы Orc она чуть выше и составляет 0,629. 
При этом доля платящих самая высокая у:
demon - 0,19, Northman - 0,182, Human - 0,18. 
Самое большее количество покупок на 1 пользователя в рассах Human -121 и Angel - 106.
Самая большая сумма всех покупок на 1 пользователя в рассах: Northman -62 520 и Elf -53 761.
средняя суммарная стоимость всех покупок на одного игрока: Elf -791,84 и Northman - 781,05.

-- Задача 2: Частота покупок
-- Напишите ваш запрос здесь
WITH разница_дней_между_покупками as ( 
SELECT  
transaction_id,
id, 
date::date,
Lead(date::date) OVER (PARTITION by id ORDER BY date::date) as дата_пред_поку,
Lead(date::date) OVER (PARTITION by id ORDER BY date::date)-date::date as дней_с_покупки
FROM fantasy.events
order by date::date),

покупки_на_игроков as (
select events.id,
count(events.transaction_id) as кол_во_покупок,
avg (дней_с_покупки) as ср_ко_во_дне_с_покупки,
 CASE 	
            WHEN payer = 0	
                THEN 'неплатящий' 	
           else 'платящий' 	
            END as категория_игрока	
         from fantasy.events
join разница_дней_между_покупками on events.id=разница_дней_между_покупками.id
join fantasy.users on events.id=users.id
GROUP by events.id,категория_игрока),

ранжирование as (select 
id,кол_во_покупок,ср_ко_во_дне_с_покупки,категория_игрока,
NTILE(3) OVER(ORDER by ср_ко_во_дне_с_покупки desc) as ранг
from покупки_на_игроков)
select*
from ранжирование


