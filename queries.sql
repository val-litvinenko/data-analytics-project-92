-- Получение общего количества клиентов в базе
SELECT count(*) AS customers_count FROM customers;

--------------------------------------------------------------------------------

--top_10_total_income.csv
--Создаем временную таблицу (CTE) с полными именами и ID продавцов
WITH sellers_names AS (
    SELECT
        e.employee_id AS seller_id,
        e.first_name || ' ' || e.last_name AS seller
    FROM employees AS e
)

SELECT
    sn.seller,
    -- Считаем количество уникальных сделок для каждого продавца
    count(DISTINCT s.sales_id) AS operations,
    -- Считаем общую сумму продаж и приводим к bigint
    floor(sum(p.price * s.quantity))::BIGINT AS income
FROM sellers_names AS sn
-- Соединяем имена с таблицей продаж и информацией о товарах
INNER JOIN sales AS s
    ON sn.seller_id = s.sales_person_id
INNER JOIN products AS p
    ON s.product_id = p.product_id
-- Группируем данные для каждого продавца отдельно
GROUP BY
    sn.seller_id,
    sn.seller
-- Сортируем по выручке: от самых прибыльных
ORDER BY income DESC
-- Ограничиваем вывод до первых десяти лидеров
LIMIT 10;

--------------------------------------------------------------------------------

--lowest_average_income.csv
--Создаем временную таблицу (CTE) с полными именами и ID продавцов
WITH sellers_names AS (
    SELECT
        e.employee_id AS seller_id,
        e.first_name || ' ' || e.last_name AS seller
    FROM employees AS e
)

SELECT
    sn.seller,
    -- Считаем средний чек продавца
    floor(avg(p.price * s.quantity))::BIGINT AS average_income
FROM sellers_names AS sn
-- Соединяем продавцов со сделками и товарами
INNER JOIN sales AS s
    ON sn.seller_id = s.sales_person_id
INNER JOIN products AS p
    ON s.product_id = p.product_id
-- Группируем по ID и имени
GROUP BY
    sn.seller_id,
    sn.seller
-- Фильтруем группы: оставляем тех, кто заработал меньше среднего
HAVING
    avg(p.price * s.quantity) < (
        SELECT avg(p2.price * s2.quantity)
        FROM sales AS s2
        INNER JOIN products AS p2
            ON s2.product_id = p2.product_id
    )
-- Сортируем результат от меньшего дохода к большему
ORDER BY average_income;

--------------------------------------------------------------------------------

--day_of_the_week_income.csv
--Создаем временную таблицу (CTE) с полными именами и ID продавцов
WITH sellers_names AS (
    SELECT
        e.employee_id AS seller_id,
        e.first_name || ' ' || e.last_name AS seller
    FROM employees AS e
)

SELECT
    sn.seller,
    -- Вытаскиваем название дня недели из даты
    to_char(s.sale_date, 'fmday') AS day_of_week,
    -- Считаем общую сумму продаж, приводим к bigint
    floor(sum(s.quantity * p.price))::BIGINT AS income
FROM sellers_names AS sn
-- Объединяем таблицы
INNER JOIN sales AS s
    ON sn.seller_id = s.sales_person_id
INNER JOIN products AS p
    ON s.product_id = p.product_id
-- Группируем данные
GROUP BY
    sn.seller,
    day_of_week,
    -- Группируем по ID дня (ISO-день: 1 = Monday, 7 = Sunday)
    to_char(s.sale_date, 'ID')
-- Сортируем: сначала по номеру дня недели, затем по продавцам
ORDER BY
    to_char(s.sale_date, 'ID'),
    sn.seller;

--------------------------------------------------------------------------------

--age_groups.csv

SELECT
    -- Распределяем покупателей по категориям на основе age
    CASE
        WHEN c.age BETWEEN 16 AND 25 THEN '16-25'
        WHEN c.age BETWEEN 26 AND 40 THEN '26-40'
        WHEN c.age > 40 THEN '40+'
    END AS age_category,
    -- Подсчитываем общее количество покупателей
    count(*) AS age_count
-- Берем данные из таблицы customers
FROM customers AS c
-- Группируем данные по возрастным категориям
GROUP BY age_category
-- Сортируем итоговую таблицу по имени категории
ORDER BY age_category;

--------------------------------------------------------------------------------

--customers_by_month.csv

SELECT
    -- Преобразуем дату продажи в текстовый формат ГОД-МЕСЯЦ
    to_char(s.sale_date, 'YYYY-MM') AS selling_month,
    -- Подсчитываем уникальных покупателей в каждом месяце
    count(DISTINCT s.customer_id) AS total_customers,
    -- Вычисляем общую выручку и округляем до целого
    floor(sum(p.price * s.quantity))::BIGINT AS income
FROM sales AS s
-- Присоединяем таблицу товаров, чтобы получить цены
INNER JOIN products AS p
    ON s.product_id = p.product_id
-- Группируем данные по месяцам
GROUP BY to_char(s.sale_date, 'YYYY-MM')
-- Сортируем итоговую таблицу
ORDER BY selling_month;

--------------------------------------------------------------------------------

--special_offer.csv

--Создаем CTE для поиска самой первой покупки каждого клиента
WITH first_purchases AS (
    -- Берем только первую уникальную запись по ID покупателя
    SELECT DISTINCT ON (customer_id)
        customer_id,
        sales_person_id,
        product_id,
        sale_date
    FROM sales
    -- Сортируем по покупателю и дате
    ORDER BY customer_id, sale_date
)

SELECT
    -- Выводим дату первой покупки (чистая простая колонка — идет первой)
    f.sale_date,
    -- Склеиваем полное имя покупателя (вычисление — идет ниже)
    c.first_name || ' ' || c.last_name AS customer,
    -- Склеиваем полное имя продавца (вычисление)
    e.first_name || ' ' || e.last_name AS seller
FROM first_purchases AS f
-- Присоединяем таблицу товаров
INNER JOIN products AS p
    ON f.product_id = p.product_id
-- Подтягиваем данные покупателей
INNER JOIN customers AS c
    ON f.customer_id = c.customer_id
-- Подтягиваем данные продавцов
INNER JOIN employees AS e
    ON f.sales_person_id = e.employee_id
-- Фильтруем результат: оставляем только бесплатные
WHERE p.price = 0
-- Сортируем итоговую таблицу по ID покупателя
ORDER BY f.customer_id;