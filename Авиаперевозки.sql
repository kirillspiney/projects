1. � ����� ������� ������ ������ ���������?
������ �������:
1) ����� ������� � �����������.
2) ������� ���������� ���������� (airport_code) �� ������� ������.
3) ��������� ���������, ������ ������ ��, ��� ���������� �������� ������ 1.

select city, count(airport_code) 
from airports a
group by city
having count(airport_code) > 1

2. � ����� ���������� ���� �����, ����������� ��������� � ������������ ���������� ��������? ���������
������:
1) � ���������� ���������, ����� ���� � ��������� ������ ������������ ��������� ��������.
2) ������ �������� ������ �� ������� ��������, ������� ������� aircraft, ����� ������ ������������ ��������� �������� �� ������ �����, ������� ������� �
�����������, ����� ��������� �������� ���������.
3) �������� ������ �� ��������, � ������� ��������� ��������� ������������, ������� �� ���������.
4) ������� ��� ���������� �������� �� ���� departure_airport. ����� �������� � ����� arival, �� �������, ��� ��������� � ����� ������ ����� ����������.

select distinct a2.airport_name  
from flights f
join aircrafts a on a.aircraft_code = f.aircraft_code
join airports a2 on f.departure_airport = a2.airport_code 
where a."range" = (select max("range") 
from aircrafts a )

3.������� 10 ������ � ������������ �������� �������� ������
- �������� LIMIT

������:
1) ����� ������ �� ������.
2) ����� ������ �� ������, �� ������� �������� ���������.
3) �������� �� ������� ��������� ������� ���������������.
4) ��������� �� �������� � ��������.
5) ������� ������ 10 ���������� �������.

select actual_departure - scheduled_departure
from flights f
where actual_departure is not null and scheduled_departure is not null
order by actual_departure - scheduled_departure desc
limit 10

4.���� �� �����, �� ������� �� ���� �������� ���������� ������?

1) �� ����� ��������� �� ���������� �������.
2) ������������ � ���� ������, ��������� right join, ����� ����� ���� ������� ������� ��������, ��� ���� ������ �� �������� ������.
3) ����� �������, ��� ������ ������ ������ ���� ��������.
4) ������� ������ ������.

--������������
select t.book_ref, bp.boarding_no 
from boarding_passes bp
right join tickets t on t.ticket_no = bp.ticket_no
where bp.boarding_no is null

--����������
select distinct t.book_ref, bp.boarding_no 
from boarding_passes bp
right join tickets t on t.ticket_no = bp.ticket_no
where bp.boarding_no is null

5. ������� ���������� ��������� ���� ��� ������� �����, �� % ��������� � ������ ���������� ���� � ��������.
�������� ������� � ������������� ������ - ��������� ���������� ���������� ���������� ���������� �� ������� ��������� �� ������ ����. 
�.�. � ���� ������� ������ ���������� ������������� ����� - ������� ������� ��� �������� �� ������� ��������� �� ���� ��� ����� ������ ������ � ������� ���.
- ������� �������
- ���������� ���/� cte

������:
1) ������� ��������� � cte ����� ���������� ���� �� ������ ��������.
2) �� ������ ��� ��������� ���������� ������� ������� ���� �������� ���������� �������.
3) � �������� ������� ��������� ���-�� ��������� ���� ����������, ������� ��������� ���� �������� � ������������� ����� �� ���������� ������� ����
� ������������ �� ��� ��������� ������ � ���������, �������� �� ������� ������.

with cte as (select aircraft_code, count(seat_no) 
from seats s
group by aircraft_code),
cte2 as (select flight_id, count(seat_no) 
from boarding_passes bp
group by flight_id)
select f.departure_airport, f.actual_arrival, f.flight_id, cte.count - cte2.count as "���-�� ��������� ����",
round(((cte.count - cte2.count::numeric) / cte.count::numeric * 100)) as "������� ��������� ����", sum(cte2.count) over 
(partition by date_trunc('day', f.actual_departure), f.departure_airport order by f.actual_arrival)
from flights f
join cte on cte.aircraft_code = f.aircraft_code
join cte2 on cte2.flight_id = f.flight_id


6. ������� ���������� ����������� ��������� �� ����� ��������� �� ������ ����������.
- ��������� ��� ����
- �������� ROUND
������ ������:
1) ����� ������ �� ���������. ������� ����������� ����� ���������� ���������.
2) ������� ���������� ��������� �� ������� ���� ��������.
3) ����� ���������� ��������� �� ������� ���� �������� �� ����� ����������, ������� � ��� �������, ������� �� 100 � �������� �� ������ �����

select aircraft_code, round(count(flight_id)::numeric / (select count(flight_id)
from flights f2)::numeric * 100)
from flights f
group by aircraft_code

7. ���� �� ������, � ������� �����  ��������� ������ - ������� �������, ��� ������-������� � ������ ��������?

����� ��������� �� ����. ��������� ������ �� ��������� ������ � ������-������ �� �������, ��� ������, ������������, ��� ������ �������� ������.
������:
1) ������ 2 ���: � ������ ��������� ������ ������ ������-������, �� ������ - ������.
2) ������� ��� ��� ���.
3) �������� �� ��������� ������� ������-������ ��������� ������� ������-������. ���� ��� ��������� ���������, �� ��� ����� ������ ����.
4) ������ �������, ��� ������ ���� ������ ����.

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

8. ����� ������ �������� ��� ������ ������?
- ��������� ������������ � ����������� FROM
- �������������� ��������� ������������� (���� �������� �����������, �� ��� �������������)
- �������� except
������:
1) ���������, ����� ���� �������� ����� �������� � ���, ������������ ������� ��� �������� �������.
2) � �������� ������� ��������� � ������� ��������� ������������ ��� ��������� ���������� ����� ��������, � �������� ����� �� ���� �������� ������ �� ����
3) ��������� �� ���������� ���������� ����� ����������� ���.

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

9. ��������� ���������� ����� �����������, ���������� ������� �������, �������� � ���������� ������������ ���������� ���������  � ���������, 
������������� ��� ����� *
- �������� RADIANS ��� ������������� sind/cosd
- CASE
������:
1) ������ ��� � ���������� ������� - �������, ����� ���� ������ ����� ����� ��������.
2) ������������ ��� ������ �������, � ��� ����� ��� ��������� ������������ ���������.
3) ��������� ���������� �� ����������� �������, ��������� sind, cosd � ������� �� 6371.
4) ������ �������, ��� ���� ������������ ��������� ������, ��� ����������� ����������, ������, ������� ��������. ���� ������, �� ���.

select distinct f.departure_airport, f.arrival_airport, a."range",
acos(sind(a2.latitude) * sind(a3.latitude) + cosd(a2.latitude) * cosd(a3.latitude) * cosd(a2.longitude - a3.longitude)) * 6371,
case 
	when a."range" > acos(sind(a2.latitude) * sind(a3.latitude) + cosd(a2.latitude) * cosd(a3.latitude) * cosd(a2.longitude - a3.longitude)) * 6371
	then '��������'
	else '���'
end
from flights f
join aircrafts a on f.aircraft_code = a.aircraft_code
join airports a2 on a2.airport_code = f.departure_airport
join airports a3 on a3.airport_code = f.arrival_airport