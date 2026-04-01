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
