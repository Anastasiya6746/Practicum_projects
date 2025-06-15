/* Проект первого модуля: анализ данных для агентства недвижимости
 * Часть 2. Решаем ad hoc задачи
 * 
 * Автор: Макарова Анастасия
 * Дата: 01.01.2025
*/

-- Пример фильтрации данных от аномальных значений
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),
-- Найдем id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    )
-- Выведем объявления без выбросов:
SELECT *
FROM real_estate.flats
WHERE id IN (SELECT * FROM filtered_id);


-- Задача 1: Время активности объявлений
-- Результат запроса должен ответить на такие вопросы:
-- 1. Какие сегменты рынка недвижимости Санкт-Петербурга и городов Ленинградской области 
--    имеют наиболее короткие или длинные сроки активности объявлений?
-- 2. Какие характеристики недвижимости, включая площадь недвижимости, среднюю стоимость квадратного метра, 
--    количество комнат и балконов и другие параметры, влияют на время активности объявлений? 
--    Как эти зависимости варьируют между регионами?
-- 3. Есть ли различия между недвижимостью Санкт-Петербурга и Ленинградской области по полученным результатам?
WITH limits AS (			
    SELECT  			
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,			
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,			
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,			
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,			
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l			
    FROM real_estate.flats     			
),			
-- Найдём id объявлений, которые не содержат выбросы:			
filtered_id AS(			
    SELECT * -- берём всё потому, что это позволит нам сделать расчёты в осном теле запроса			
    FROM real_estate.flats  			
    WHERE 			
        total_area < (SELECT total_area_limit FROM limits)			
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)			
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)			
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)			
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)			
    ),			
Категории as (select *,			
CASE           			
            WHEN city = 'Санкт-Петербург'          			
                THEN 'Санкт-Петербург'      			
                    else 'ЛенОбл'    			
            END as регион,			
            CASE       			
            WHEN days_exposition <= 30     			
                THEN 'До месяца'			
             WHEN days_exposition > 30 and  days_exposition <=90   			
                THEN 'До трех месяцев'			
                WHEN days_exposition > 90 and days_exposition <=180
                THEN 'До полугода'
                WHEN days_exposition >180
                THEN 'более полугода'	
                    else 'без категории'			
            END as сегмент_активности 			
            from real_estate.advertisement			
join real_estate.flats on flats.id=advertisement.id			
join real_estate.city on city.city_id=flats.city_id
join real_estate.type on flats.type_id=type.type_id
WHERE advertisement.id IN (SELECT id FROM filtered_id) and type='город'		
)			
  select 			
  регион,			
  сегмент_активности,			
  COUNT (*) as оличество_обьявлений_в_регионе,			
  ROUND(CAST(AVG(last_price  / total_area) AS NUMERIC),2) as ср_стоимость_кв_местра,			
  ROUND(CAST(AVG(total_area) AS NUMERIC),2) as ср_площадь_кваритр,			
  ROUND(CAST(AVG(kitchen_area) AS NUMERIC),2) as ср_площадь_кухни,			
  ROUND(CAST(AVG(ceiling_height) AS NUMERIC),2) as ср_высота_потолка,			
  ROUND(CAST(AVG(rooms) AS NUMERIC),2) as ср_кол_во_комнат			
  from Категории			
  GROUP BY регион,сегмент_активности 			

		


-- Задача 2: Сезонность объявлений
-- Результат запроса должен ответить на такие вопросы:
-- 1. В какие месяцы наблюдается наибольшая активность в публикации объявлений о продаже недвижимости? 
--    А в какие — по снятию? Это показывает динамику активности покупателей.
-- 2. Совпадают ли периоды активной публикации объявлений и периоды, 
--    когда происходит повышенная продажа недвижимости (по месяцам снятия объявлений)?
-- 3. Как сезонные колебания влияют на среднюю стоимость квадратного метра и среднюю площадь квартир? 
--    Что можно сказать о зависимости этих параметров от месяца?

1. запрос для размещенных обьявлений:
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)),
            промежут_итог as (
    select extract ('month' from first_day_exposition) as номер_месяца_публикации,
count(advertisement.id) as число_публикаций_в_этом_месяце_за_все_года,
avg(last_price/total_area) as ср_стоимость_квадратного_метра,
avg(total_area) as средняя_площадь
from real_estate.advertisement
join real_estate.flats on flats.id=advertisement.id
join real_estate.type on flats.type_id=type.type_id
WHERE flats.id IN (SELECT * FROM filtered_id) and type='город' and extract ('year' from first_day_exposition::date)<>'2014' and 
extract ('year' from first_day_exposition::date)<>'2019'
group by extract ('month' from first_day_exposition)
order by avg(last_price/total_area))
select *,
число_публикаций_в_этом_месяце_за_все_года/sum(число_публикаций_в_этом_месяце_за_все_года) over () as доля_публикаций_в_этом_мес_к_общему_числу
from промежут_итог

2.Запрос для обьявлений снятых с продажи:
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)),
            промежут_итог as (
    select extract ('month' from (first_day_exposition::date+days_exposition::integer)) as номер_месяца_снятия, 
 count(advertisement.id) as число_снятий_в_этом_месяце_за_все_года,
avg(last_price/total_area) ср_стоимость_квадратного_метра,
avg(total_area) as средняя_площадь
from real_estate.advertisement
join real_estate.flats on flats.id=advertisement.id
join real_estate.type on flats.type_id=type.type_id
WHERE flats.id IN (SELECT * FROM filtered_id) and type='город' and extract ('year' from first_day_exposition::date)<>'2014' and 
extract ('year' from first_day_exposition::date)<>'2019'
group by extract ('month' from (first_day_exposition::date+days_exposition::integer))
order by avg(last_price/total_area))
select *,
число_снятий_в_этом_месяце_за_все_года/sum(число_снятий_в_этом_месяце_за_все_года) over () as доля_снятий_в_этом_мес_к_общему_числу
from промежут_итог


-- Задача 3: Анализ рынка недвижимости Ленобласти
-- Результат запроса должен ответить на такие вопросы:
-- 1. В каких населённые пунктах Ленинградской области наиболее активно публикуют объявления о продаже недвижимости?
-- 2. В каких населённых пунктах Ленинградской области — самая высокая доля снятых с публикации объявлений? 
--    Это может указывать на высокую долю продажи недвижимости.
-- 3. Какова средняя стоимость одного квадратного метра и средняя площадь продаваемых квартир в различных населённых пунктах? 
--    Есть ли вариация значений по этим метрикам?
-- 4. Среди выделенных населённых пунктов какие пункты выделяются по продолжительности публикации объявлений? 
--    То есть где недвижимость продаётся быстрее, а где — медленнее.


WITH limits AS 
(
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
)
-- Найдём id объявлений, которые не содержат выбросы:
, filtered_id AS
(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    )
, сняты_с_продажи as 
(
    select  
        city,
        count (advertisement.id) as объв_снято,avg(days_exposition) as кол_дней_публикации,
        avg (last_price/total_area) as цена_за_метр_проданных, avg(total_area )    as общая_площадь_проданных        
    from real_estate.advertisement
        join real_estate.flats on flats.id=advertisement.id
        join real_estate.city on city.city_id=flats.city_id
    where 
        days_exposition is not NULL
        AND flats.id IN (SELECT * FROM filtered_id)
    group by city
),
всего_обьявлений as 
(
    select  
        city,
        count (advertisement.id) as общее
    from real_estate.advertisement
        join real_estate.flats on flats.id=advertisement.id
        join real_estate.city on city.city_id=flats.city_id
    WHERE 
        flats.id IN (SELECT * FROM filtered_id)
    group by city
)
select 
    сняты_с_продажи.city,
    общее,
    сняты_с_продажи.объв_снято, кол_дней_публикации,
    объв_снято/общее::real as доля_проданных,
    цена_за_метр_проданных,
    общая_площадь_проданных
from сняты_с_продажи
    join всего_обьявлений on всего_обьявлений.city=сняты_с_продажи.city
where 
    сняты_с_продажи.city <> 'Санкт-Петербург' 
    and общее > 50