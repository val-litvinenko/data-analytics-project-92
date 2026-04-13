-- Получение общего количества клиентов в базе
select count (*) from customers;

----------------------------------------------------------------------------------------------

--top_10_total_income.csv
--Создаем временную таблицу (CTE) с полными именами и ID продавцов
with sellers_names as (
    select 
        e.first_name || ' ' || e.last_name as seller,
        e.employee_id as seller_id
    from employees e
)

select
    seller,
    -- Считаем количество уникальных сделок для каждого продавца
    count(distinct s.sales_id) as operations,
    -- Считаем общую сумму продаж (цена товара * кол-во) и округляем до целого
    round(sum(p.price * s.quantity), 0) as income
from sellers_names sn
-- Соединяем имена с таблицей продаж и информацией о товарах
inner join sales s 
   on sn.seller_id = s.sales_person_id
inner join products p
   on p.product_id = s.product_id
-- Группируем данные, чтобы всё считалось для каждого продавца отдельно
group by sn.seller_id, sn.seller
-- Сортируем по выручке: от самых прибыльных к менее прибыльным
order by income desc
-- Ограничиваем вывод до первых десяти лидеров 
limit 10;

----------------------------------------------------------------------------------------------

--lowest_average_income.csv
--Создаем временную таблицу (CTE) с полными именами и ID продавцов
with sellers_names as (
    select 
        e.first_name || ' ' || e.last_name as seller,
        e.employee_id as seller_id
    from employees e
)

select
    seller,
    -- Считаем средний чек продавца
    round(avg(p.price * s.quantity), 0) as average_income
from sellers_names sn
-- Соединяем продавцов со сделками и товарами
inner join sales s 
   on sn.seller_id = s.sales_person_id
inner join products p
   on p.product_id = s.product_id
-- Группируем по ID и имени
group by sn.seller_id, sn.seller
-- Фильтруем группы: оставляем тех, кто заработал меньше среднего по всем продажам
having avg(p.price * s.quantity) < (
    -- Вложенный запрос: вычисляем среднее значение по всем продажам в базе
    select round(avg(p2.price * s2.quantity), 0)
    from sales s2
    inner join products p2
    on s2.product_id = p2.product_id
)
-- Сортируем результат от меньшего дохода к большему
order by average_income;

----------------------------------------------------------------------------------------------

--day_of_the_week_income.csv
--Создаем временную таблицу (CTE) с полными именами и ID продавцов
with sellers_names as (
  select 
    e.first_name || ' ' || e.last_name as seller, -- Склеиваем имя и фамилию
    e.employee_id as seller_id
  from employees e
)

select
  seller,
  -- Вытаскиваем название дня недели из даты
  -- 'FMDay' вместо TRIM для удаления пробелов
  TO_CHAR(sale_date, 'FMDay') as day_of_week,
  -- Считаем общую сумму продаж (количество * цена) и округляем до целого
  ROUND(SUM(s.quantity * p.price), 0) as income
from sellers_names sn
-- Объединяем таблицы
inner join sales s
  on s.sales_person_id = sn.seller_id
inner join products p
  on p.product_id = s.product_id
-- Группируем данные
group by 
  seller, 
  day_of_week, 
  TO_CHAR(sale_date, 'ID') -- Группируем по ID дня (ISO-день: 1 = Monday, 7 = Sunday), чтобы корректно работала сортировка
-- Сортируем: сначала по номеру дня недели, затем по продавцам внутри каждого дня
order by 
  TO_CHAR(sale_date, 'ID'), 
  seller;

----------------------------------------------------------------------------------------------

--age_groups.csv

SELECT 
  -- Распределяем покупателей по категориям на основе столбца age
  CASE 
    WHEN age BETWEEN 16 AND 25 THEN '16-25' -- Если возраст от 16 до 25 включительно
    WHEN age BETWEEN 26 AND 40 THEN '26-40' -- Если возраст от 26 до 40 включительно
    WHEN age > 40 THEN '40+'                -- Если возраст строго больше 40
  END AS age_category,
  -- Подсчитываем общее количество покупателей для каждой категории
  COUNT(*) AS age_count
-- Берем данные из таблицы customers
FROM customers c 
-- Группируем данные по возрастным категориям
GROUP BY age_category
-- Сортируем итоговую таблицу по имени категории по возрастанию
ORDER BY age_category;

----------------------------------------------------------------------------------------------

--customers_by_month.csv 

select
  -- Преобразуем дату продажи в текстовый формат ГОД-МЕСЯЦ
  TO_CHAR(s.sale_date, 'YYYY-MM') as selling_month,
  -- Подсчитываем уникальных покупателей в каждом месяце
  COUNT(distinct s.customer_id) as total_customers,
  -- Вычисляем общую выручку (цена * количество) и округляем до целого
  ROUND(SUM(p.price * s.quantity), 0) as income
from sales s
-- Присоединяем таблицу товаров, чтобы получить цены
inner join products p
 on s.product_id = p.product_id 
-- Группируем данные по месяцам
group by selling_month
-- Сортируем итоговую таблицу
order by selling_month;

----------------------------------------------------------------------------------------------

--special_offer.csv

--Создаем CTE для поиска самой первой покупки каждого клиента
with first_purchases as (
  -- Берем только первую уникальную запись по ID покупателя
  select DISTINCT ON (customer_id)
    customer_id,
    sale_date,
    sales_person_id,
    product_id
  from sales
  -- Сортируем по покупателю и дате, чтобы взять именно самую раннюю сделку
  order by customer_id, sale_date
)

select
  -- Склеиваем полное имя покупателя
  CONCAT_WS(' ', c.first_name, c.middle_initial, c.last_name) as customer,
  -- Выводим дату первой покупки
  f.sale_date as sale_date,
  -- Склеиваем полное имя продавца
  CONCAT_WS(' ', e.first_name, UPPER(e.middle_initial), e.last_name) as seller   
from first_purchases f
-- Присоединяем таблицу товаров, чтобы проверить их стоимость
inner join products p 
  on f.product_id = p.product_id 
-- Подтягиваем данные покупателей для формирования полного имени
inner join customers c 
  on f.customer_id = c.customer_id
-- Подтягиваем данные продавцов для формирования полного имени
inner join employees e
  on f.sales_person_id = e.employee_id
-- Фильтруем результат: оставляем только тех, чья первая покупка была бесплатной
where p.price = 0
-- Сортируем итоговую таблицу по ID покупателя
order by f.customer_id;

----------------------------------------------------------------------------------------------
