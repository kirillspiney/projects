1. В каких городах больше одного аэропорта?
Логика запроса:
1) Берем таблицу с аэропортами.
2) Считаем количество аэропортов (airport_code) по каждому городу.
3) Сортируем результат, выводя только те, где полученное значение больше 1.

select city, count(airport_code) 
from airports a
group by city
having count(airport_code) > 1

2. В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета? ПОДЗАПРОС
Логика:
1) В подзапросе вычисляем, какая есть в настоящий момент максимальная дальность перелета.
2) Делаем основной запрос из таблицы перелтов, джойним таблицу aircraft, чтобы узнать максимальную дальность самолета на каждом рейсе, джойним таблицу с
аэропортами, чтобы подвязать название аэропорта.
3) Выбираем только те значения, в которых дальность равняется максимальной, которую мы вычислили.
4) Выводим все уникальные значения по сути departure_airport. Можно выводить и через arival, но логично, что результат в таком случае будет одинаковым.

select distinct a2.airport_name  
from flights f
join aircrafts a on a.aircraft_code = f.aircraft_code
join airports a2 on f.departure_airport = a2.airport_code 
where a."range" = (select max("range") 
from aircrafts a )

3.Вывести 10 рейсов с максимальным временем задержки вылета
- Оператор LIMIT

Логика:
1) Берем данные по рейсам.
2) Берем только те данные, по которым значение ненулевое.
3) Вычитаем из времени реального отбытия запланированное.
4) Сортируем от большего к меньшему.
5) Выводим первые 10 полученных записей.

select actual_departure - scheduled_departure
from flights f
where actual_departure is not null and scheduled_departure is not null
order by actual_departure - scheduled_departure desc
limit 10

4.Были ли брони, по которым не были получены посадочные талоны?

1) Мы берем отношения по посадочным талонам.
2) Присоединяем к нему билеты, используя right join, чтобы можно было вывести нулевые значения, где есть данные по номерами броней.
3) Берем условия, что данные номера должны быть нулевыми.
4) Выводим нужные данные.

--Неуникальные
select t.book_ref, bp.boarding_no 
from boarding_passes bp
right join tickets t on t.ticket_no = bp.ticket_no
where bp.boarding_no is null

--Уникальные
select distinct t.book_ref, bp.boarding_no 
from boarding_passes bp
right join tickets t on t.ticket_no = bp.ticket_no
where bp.boarding_no is null

5. Найдите количество свободных мест для каждого рейса, их % отношение к общему количеству мест в самолете.
Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день. 
Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело из данного аэропорта на этом или более ранних рейсах в течении дня.
- Оконная функция
- Подзапросы или/и cte

Логика:
1) Сначала вычисляем в cte общее количество мест на каждом самолете.
2) Во втором сте вычисляем количество реально занятых мест согласно посадочным талонам.
3) В основном запросе вычисляем кол-во свободных мест вычитанием, процент свободных мест делением и накопительную сумму по количеству занятых мест
с группировкой по дню реального вылета и аэропорту, сортируя по времени вылета.

with cte as (select aircraft_code, count(seat_no) 
from seats s
group by aircraft_code),
cte2 as (select flight_id, count(seat_no) 
from boarding_passes bp
group by flight_id)
select f.departure_airport, f.actual_arrival, f.flight_id, cte.count - cte2.count as "Кол-во свободных мест",
round(((cte.count - cte2.count::numeric) / cte.count::numeric * 100)) as "Процент свободных мест", sum(cte2.count) over 
(partition by date_trunc('day', f.actual_departure), f.departure_airport order by f.actual_arrival)
from flights f
join cte on cte.aircraft_code = f.aircraft_code
join cte2 on cte2.flight_id = f.flight_id


6. Найдите процентное соотношение перелетов по типам самолетов от общего количества.
- Подзапрос или окно
- Оператор ROUND
Логика проста:
1) Берем данные по перелетам. Считаем подзапросом общее количество перелетов.
2) Считаем количество перелетов по каждому типу самолета.
3) Делим количество перелетов по каждому типу самолета на общее количество, приведя в тип намерик, умножая на 100 и округляя до целого числа

select aircraft_code, round(count(flight_id)::numeric / (select count(flight_id)
from flights f2)::numeric * 100)
from flights f
group by aircraft_code

7. Были ли города, в которые можно  добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?

Таких перелетов не было. Изменение данных по стоимости билета в бизнес-классе на меньшую, чем эконом, подтверждает, что запрос работает хорошо.
Логика:
1) Делаем 2 сте: в первой оставляем только билеты бизнес-класса, во второй - эконом.
2) Джойним эти две сте.
3) Вычитаем из стоимости билетов эконом-класса стоимость билетов бизнес-класса. Если эта стоимость превышает, то она будет больше нуля.
4) Делаем условие, что должно быть больше нуля.

with bt as (select *
from ticket_flights tf
where tf.fare_conditions = 'Business'),
et as (select *
from ticket_flights tf
where tf.fare_conditions = 'Economy')
select *, et.amount - bt.amount
from bt
join et on bt.flight_id = et.flight_id
where et.amount - bt.amount > 0

8. Между какими городами нет прямых рейсов?
- Декартово произведение в предложении FROM
- Самостоятельно созданные представления (если облачное подключение, то без представления)
- Оператор except
Логика:
1) Вычисляем, какие есть перелеты между городами в сте, присоединяем таблицы для названий городов.
2) В основном запросе вычисляем с помощью декартово произведения все возможные комбинации между городами, с условием чтобы не было повторов самого на себя
3) Исключаем из полученных комбинаций ранее вычисленный сте.

with cte as (select distinct a.city, a2.city
from flights f 
join airports a on f.departure_airport = a.airport_code 
join airports a2 on f.arrival_airport = a2.airport_code)
select distinct a.city, a2.city
from airports a, airports a2 
where a.city != a2.city
except select * 
from cte

create view task1 as
select city, count(airport_code) 
from airports a
group by city
having count(airport_code) > 1

create view task2 as
select distinct a2.airport_name  
from flights f
join aircrafts a on a.aircraft_code = f.aircraft_code
join airports a2 on f.departure_airport = a2.airport_code 
where a."range" = (select max("range") 
from aircrafts a )

9. Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой максимальной дальностью перелетов  в самолетах, 
обслуживающих эти рейсы *
- Оператор RADIANS или использование sind/cosd
- CASE
Логика:
1) Делаем как в предыдущем запросе - смотрим, какие есть прямые рейсы между городами.
2) Присоединяем все нужные таблицы, в том числе для понимания максимальной дальности.
3) Вычисляем расстояние по приведенной формуле, используя sind, cosd и умножая на 6371.
4) Делаем условие, что если максимальная дальность больше, чем вычисленное расстояние, значит, самолет долетает. Если меньше, то нет.

select distinct f.departure_airport, f.arrival_airport, a."range",
acos(sind(a2.latitude) * sind(a3.latitude) + cosd(a2.latitude) * cosd(a3.latitude) * cosd(a2.longitude - a3.longitude)) * 6371,
case 
	when a."range" > acos(sind(a2.latitude) * sind(a3.latitude) + cosd(a2.latitude) * cosd(a3.latitude) * cosd(a2.longitude - a3.longitude)) * 6371
	then 'Долетает'
	else 'Нет'
end
from flights f
join aircrafts a on f.aircraft_code = a.aircraft_code
join airports a2 on a2.airport_code = f.departure_airport
join airports a3 on a3.airport_code = f.arrival_airport
