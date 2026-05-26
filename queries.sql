-- Получение общего количества клиентов в базе
SELECT count(*) AS customers_count FROM customers;

----------------------------------------------------------------------------------------------

--top_10_total_income.csv
--Создаем временную таблицу (CTE) с полными именами и ID продавцов
WITH sellers_names AS (
    SELECT
        e.first_name || ' ' || e.last_name AS seller
        , e.employee_id AS seller_id
    FROM employees AS e
)

SELECT
    sn.seller
    -- Считаем количество уникальных сделок для каждого продавца
    , count(DISTINCT s.sales_id) AS operations
    -- Считаем общую сумму продаж (цена товара * кол-во) и приводим к bigint, округляем
    , floor(sum(p.price * s.quantity))::BIGINT AS income
FROM sellers_names AS sn
-- Соединяем имена с таблицей продаж и информацией о товарах
INNER JOIN sales AS s
    ON sn.seller_id = s.sales_person_id
INNER JOIN products AS p
    ON p.product_id = s.product_id
-- Группируем данные, чтобы всё считалось для каждого продавца отдельно
GROUP BY
    sn.seller_id
    , sn.seller
-- Сортируем по выручке: от самых прибыльных к менее прибыльным
ORDER BY income DESC
-- Ограничиваем вывод до первых десяти лидеров 
LIMIT 10;

----------------------------------------------------------------------------------------------

--lowest_average_income.csv
--Создаем временную таблицу (CTE) с полными именами и ID продавцов
WITH sellers_names AS (
    SELECT
        e.first_name || ' ' || e.last_name AS seller
        , e.employee_id AS seller_id
    FROM employees AS e
)

SELECT
    sn.seller
    -- Считаем средний чек продавца
    , floor(avg(p.price * s.quantity))::BIGINT AS average_income
FROM sellers_names AS sn
-- Соединяем продавцов со сделками и товарами
INNER JOIN sales AS s
    ON sn.seller_id = s.sales_person_id
INNER JOIN products AS p
    ON p.product_id = s.product_id
-- Группируем по ID и имени
GROUP BY
    sn.seller_id
    , sn.seller
-- Фильтруем группы: оставляем тех, кто заработал меньше среднего по всем продажам
HAVING avg(p.price * s.quantity) < (
    -- Вложенный запрос: вычисляем среднее значение по всем продажам в базе
    SELECT avg(p2.price * s2.quantity)
    FROM sales AS s2
    INNER JOIN products AS p2
        ON s2.product_id = p2.product_id
)
-- Сортируем результат от меньшего дохода к большему
ORDER BY average_income;

----------------------------------------------------------------------------------------------

--day_of_the_week_income.csv
--Создаем временную таблицу (CTE) с полными именами и ID продавцов
WITH sellers_names AS (
    SELECT
        e.first_name || ' ' || e.last_name AS seller -- Склеиваем имя и фамилию
        , e.employee_id AS seller_id
    FROM employees AS e
)

SELECT
    sn.seller
    -- Вытаскиваем название дня недели из даты
    , to_char(s.sale_date, 'fmday') AS day_of_week
    -- Считаем общую сумму продаж (количество * цена) приводим к bigint и округляем до целого
    , floor(sum(s.quantity * p.price))::BIGINT AS income
FROM sellers_names AS sn
-- Объединяем таблицы
INNER JOIN sales AS s
    ON s.sales_person_id = sn.seller_id
INNER JOIN products AS p
    ON p.product_id = s.product_id
-- Группируем данные
GROUP BY
    sn.seller
    , day_of_week
    , to_char(s.sale_date, 'ID') -- Группируем по ID дня (ISO-день: 1 = Monday, 7 = Sunday), чтобы корректно работала сортировка
-- Сортируем: сначала по номеру дня недели, затем по продавцам внутри каждого дня
ORDER BY
    to_char(s.sale_date, 'ID')
    , sn.seller;

----------------------------------------------------------------------------------------------

--age_groups.csv

SELECT
    -- Распределяем покупателей по категориям на основе столбца age
    CASE
        WHEN c.age BETWEEN 16 AND 25 THEN '16-25' -- Если возраст от 16 до 25 включительно
        WHEN c.age BETWEEN 26 AND 40 THEN '26-40' -- Если возраст от 26 до 40 включительно
        WHEN c.age > 40 THEN '40+'                -- Если возраст строго больше 40
    END AS age_category
    -- Подсчитываем общее количество покупателей для каждой категории
    , count(*) AS age_count
-- Берем данные из таблицы customers
FROM customers AS c
-- Группируем данные по возрастным категориям
GROUP BY age_category
-- Сортируем итоговую таблицу по имени категории по возрастанию
ORDER BY age_category;

----------------------------------------------------------------------------------------------

--customers_by_month.csv 

SELECT
    -- Преобразуем дату продажи в текстовый формат ГОД-МЕСЯЦ
    to_char(s.sale_date, 'YYYY-MM') AS selling_month
    -- Подсчитываем уникальных покупателей в каждом месяце
    , count(DISTINCT s.customer_id) AS total_customers
    -- Вычисляем общую выручку (цена * количество) и округляем до целого
    , floor(sum(p.price * s.quantity))::BIGINT AS income
FROM sales AS s
-- Присоединяем таблицу товаров, чтобы получить цены
INNER JOIN products AS p
    ON s.product_id = p.product_id
-- Группируем данные по месяцам
GROUP BY to_char(s.sale_date, 'YYYY-MM')
-- Сортируем итоговую таблицу
ORDER BY selling_month;

----------------------------------------------------------------------------------------------

--special_offer.csv

--Создаем CTE для поиска самой первой покупки каждого клиента
WITH first_purchases AS (
    -- Берем только первую уникальную запись по ID покупателя
    SELECT DISTINCT ON (customer_id)
        customer_id
        , sale_date
        , sales_person_id
        , product_id
    FROM sales
    -- Сортируем по покупателю и дате, чтобы взять именно самую раннюю сделку
    ORDER BY customer_id, sale_date
)

SELECT
    -- Склеиваем полное имя покупателя
    c.first_name || ' ' || c.last_name AS customer
    -- Выводим дату первой покупки
    , f.sale_date AS sale_date
    -- Склеиваем полное имя продавца
    , e.first_name || ' ' || e.last_name AS seller
FROM first_purchases AS f
-- Присоединяем таблицу товаров, чтобы проверить их стоимость
INNER JOIN products AS p
    ON f.product_id = p.product_id
-- Подтягиваем данные покупателей для формирования полного имени
INNER JOIN customers AS c
    ON f.customer_id = c.customer_id
-- Подтягиваем данные продавцов для формирования полного имени
INNER JOIN employees AS e
    ON f.sales_person_id = e.employee_id
-- Фильтруем результат: оставляем только тех, чья первая покупка была бесплатной
WHERE p.price = 0
-- Сортируем итоговую таблицу по ID покупателя
ORDER BY f.customer_id;