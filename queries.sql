--Получение общего количества
--клиентов в базе

select count(*) as customers_count from customers;

--top_10_total_income.csv
--Создаем временную таблицу (CTE
--с полными именами и ID продавцов
with sellers_names as (
    select
        e.employee_id as seller_id,
        e.first_name,
        e.last_name
    from employees as e
)

select
    sn.seller_id,
    sn.first_name || ' ' || sn.last_name as seller,
    --Считаем общую сумму продаж (цена*кол-во)
    --и приводим к bigint, округляем
    floor(sum(p.price * s.quantity))::bigint as income,
    -- Считаем количество уникальных сделок
    --для каждого продавца
    count(distinct s.sales_id) as operations
from sellers_names as sn
--Соединяем имена с таблицей
--продаж и информацией о товарах
inner join sales as s
    on sn.seller_id = s.sales_person_id
inner join products as p
    on s.product_id = p.product_id
--Группируем теперь по чистым полям из CTE
group by
    sn.seller_id,
    sn.first_name,
    sn.last_name
--Сортируем по выручке:
--от самых прибыльных к менее прибыльных
order by income desc
--Ограничиваем вывод до
--первых десяти лидеров 
limit 10;

--lowest_average_income.csv

--Создаем временную таблицу (CTE)
--с полными именами и ID продавцов
with sellers_names as (
    select
        e.employee_id as seller_id,
        e.first_name || ' ' || e.last_name as seller
    from employees as e
)

select
    sn.seller,
    --Считаем средний чек продавца
    floor(avg(p.price * s.quantity))::bigint as average_income
from sellers_names as sn
--Соединяем продавцов
--со сделками и товарами
inner join sales as s
    on sn.seller_id = s.sales_person_id
inner join products as p
    on s.product_id = p.product_id
--Группируем по ID и имени
group by sn.seller_id, sn.seller
--Фильтруем группы: оставляем тех, кто
--заработал меньше среднего по всем прод.
having
    avg(p.price * s.quantity) < (
    --Вложенный запрос: вычисляем среднее
    --значение по всем продажам в базе
        select avg(p2.price * s2.quantity)
        from sales as s2
        inner join products as p2
            on s2.product_id = p2.product_id
    )
--Сортируем результат от
--меньшего дохода к большему
order by average_income;

--day_of_the_week_income.csv

--Создаем временную таблицу (CTE)
--с полными именами и ID продавцов
with sellers_names as (
    select
        --Склеиваем имя и фамилию
        e.employee_id as seller_id,
        e.first_name || ' ' || e.last_name as seller
    from employees as e
)

select
    sn.seller,
    --Вытаскиваем название дня недели из даты
    to_char(s.sale_date, 'fmday') as day_of_week,
    --Считаем общую сумму продаж (кол-во * цена)
    --приводим к bigint и округляем до целого
    floor(sum(s.quantity * p.price))::bigint as income
from sellers_names as sn
--Объединяем таблицы
inner join sales as s
    on sn.seller_id = s.sales_person_id
inner join products as p
    on s.product_id = p.product_id
--Группируем данные
group by
    sn.seller,
    day_of_week,
    --Группируем по ID дня (ISO-день: 1=Monday, и т.д.),
    --чтобы корректно работала сортировка
    to_char(s.sale_date, 'ID')
--Сортируем: сначала по номеру дня недели,
--затем по продавцам внутри каждого дня
order by
    to_char(s.sale_date, 'ID'),
    sn.seller;

--age_groups.csv

select
    case
    --Если возраст меньше 16
        when age < 16 then '0-15'
        --Если возраст от 16 до 25 включительно
        when age between 16 and 25 then '16-25'
        --Если возраст от 26 до 40 включительно
        when age between 26 and 40 then '26-40'
        --Если возраст строго больше 40
        when age > 40 then '40+'
    end as age_category,
    --Подсчитываем общее количество
    --покупателей для каждой категории
    count(*) as age_count
--Берем данные из таблицы customers
from customers
--Группируем данные по возрастн категориям
group by age_category
--Сортируем итоговую таблицу
--по имени категории по возрастанию
order by age_category;

--customers_by_month.csv 

select
    --Преобразуем дату продажи в
    --текстовый формат ГОД-МЕСЯЦ
    to_char(s.sale_date, 'YYYY-MM') as selling_month,
    --Подсчитываем уникальных
    --покупателей в каждом месяце
    count(distinct s.customer_id) as total_customers,
    --Вычисляем общую выручку (цена * кол-во)
    --и округляем до целого
    floor(sum(p.price * s.quantity))::bigint as income
from sales as s
--Присоединяем таблицу товаров,
--чтобы получить цены
inner join products as p
    on s.product_id = p.product_id
--Группируем данные по месяцам
group by to_char(s.sale_date, 'YYYY-MM')
--Сортируем итоговую таблицу
order by selling_month;


--special_offer.csv

--Создаем CTE для поиска самой
--первой покупки каждого клиента
with first_purchases as (
    --Берем только первую уникальную
    --запись по ID покупателя
    select distinct on (customer_id)
        customer_id,
        sale_date,
        sales_person_id,
        product_id
    from sales
    --Сортируем по покупателю и дате,
    --чтобы взять именно самую раннюю сделку
    order by customer_id, sale_date
)

select
    --Выводим дату первой покупки
    f.sale_date,
    --Склеиваем полное имя покупателя
    c.first_name || ' ' || c.last_name as customer,
    -- Склеиваем полное имя продавца
    e.first_name || ' ' || e.last_name as seller
from first_purchases as f
--Присоединяем таблицу товаров,
--чтобы проверить их стоимость
inner join products as p
    on f.product_id = p.product_id
--Подтягиваем данные покупателей
--для формирования полного имени
inner join customers as c
    on f.customer_id = c.customer_id
--Подтягиваем данные продавцов
--для формирования полного имени
inner join employees as e
    on f.sales_person_id = e.employee_id
--Фильтруем результат: оставляем только тех,
--чья первая покупка была бесплатной
where p.price = 0
--Сортируем итоговую таблицу
--по ID покупателя
order by f.customer_id;
