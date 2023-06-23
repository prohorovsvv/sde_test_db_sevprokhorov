drop table if exists results;

--Создать таблицу results c атрибутами id (INT), response (TEXT), где
--•	id – номер запроса из списка ниже
--•	response – результат запроса

CREATE TABLE bookings.results (
	id int,
	response text
);

--1.	Вывести максимальное количество человек в одном бронировании
insert into results
select 1, max(cnt)
from (
    select book_ref, count(passenger_id) as cnt
    from tickets t
    group by book_ref
    ) as count_passenger_id;

--2.	Вывести количество бронирований с количеством людей больше среднего значения людей на одно бронирование
insert into results
select * from (
with passengers_count as (
	select book_ref, count(passenger_id) as cnt_pass
    from tickets t
    group by book_ref)
select 2, count(book_ref) as cnt_book_ref
from passengers_count
where cnt_pass > (
	select avg(cnt_pass)
	from passengers_count
	)) e;

--3.	Вывести количество бронирований, у которых состав пассажиров повторялся два и более раза, среди бронирований
--с максимальным количеством людей (п.1)?
insert into results
select 3, count(t1.book_ref)
from (
         select book_ref
              , string_agg(passenger_id, ',' order by passenger_id) as ps
              , rank() over (order by count(passenger_id) desc) as rank_o
         from tickets
         group by book_ref
         order by count(passenger_id) desc
     ) t1
where t1.rank_o = 1
group by t1.ps
having count(t1.ps) > 1;

--4.	Вывести номера брони и контактную информацию по пассажирам в брони (passenger_id, passenger_name, contact_data)
--с количеством людей в брони = 3

insert into results
select  4, concat('|', t.book_ref, string_agg(t.passenger_info, '|')) as p_inf
from (
         select book_ref
              , concat('|', passenger_id, passenger_name, contact_data) AS passenger_info
         from tickets
         where book_ref IN (
                               select book_ref
                               from tickets
                               group by book_ref
                               having count(passenger_id) = 3
                           )
     ) t
group by t.book_ref
order by p_inf;

--	5.	Вывести максимальное количество перелётов на бронь

insert into results
select 5, max(cnt_b)
from (
	select count(b.book_ref) as cnt_b
	from bookings b
	join tickets t on b.book_ref = t.book_ref
	join ticket_flights tf on t.ticket_no = tf.ticket_no
	group by b.book_ref) c;

--	6.	Вывести максимальное количество перелётов на пассажира в одной брони

insert into results
select 6, max(count)
from (
	select b.book_ref,count(t.passenger_id)
	from ticket_flights tf
	join tickets t on tf.ticket_no = t.ticket_no
	join bookings b on t.book_ref = b.book_ref
	group by b.book_ref, t.passenger_id) a;

--	7.	Вывести максимальное количество перелётов на пассажира

insert into results
select 7, max(count)
from (
select count(t.passenger_id)
	from ticket_flights tf
	join tickets t on tf.ticket_no = t.ticket_no
	group by t.passenger_id) a;


--	8.	Вывести контактную информацию по пассажиру(ам) (passenger_id, passenger_name, contact_data) и
--	 общие траты на билеты, для пассажира потратившему минимальное количество денег на перелеты
insert into results
select * from (
with sum_amount as(
	select passenger_id, passenger_name, contact_data, sum(amount) as s_amount
	from ticket_flights tf
	join tickets t on tf.ticket_no = t.ticket_no
	group by passenger_id, passenger_name, contact_data
	order by sum(amount))
select 8, passenger_id||'|'||passenger_name||'|'||contact_data||'|'|| s_amount
from (
	select passenger_id, passenger_name, contact_data, s_amount
	from sum_amount
	where s_amount = (
						select min(s_amount)
						from sum_amount)
	order by passenger_id, passenger_name, contact_data) a) e;

--9.	Вывести контактную информацию по пассажиру(ам) (passenger_id, passenger_name, contact_data) и
-- общее время в полётах, для пассажира, который провёл максимальное время в полётах
insert into results
select * from (
with sum_time_flight as(
	select passenger_id, passenger_name, contact_data, sum(actual_duration) as sum_duration
	from flights_v fv
	join ticket_flights tf on fv.flight_id = tf.flight_id
	join tickets t on tf.ticket_no = t.ticket_no
	where actual_duration is not null
	group by passenger_id, passenger_name, contact_data
	order by sum(actual_duration) desc)
select 9, concat(passenger_id, '|', passenger_name, '|', contact_data, '|', sum_duration)
from (
	select passenger_id, passenger_name, contact_data, sum_duration
	from sum_time_flight
	where sum_duration = (
		select max(sum_duration) as max_flight_time
		from sum_time_flight
	)
	order by passenger_id, passenger_name, contact_data
) a) e;

--10.	Вывести город(а) с количеством аэропортов больше одного

insert into results
select 10, city
from airports a
group by city
having count(city) > 1
order by city;

--11.	Вывести город(а), у которого самое меньшее количество городов прямого сообщения
insert into results
select * from (
with cnt_routes as (
	select departure_city, count(distinct arrival_city) as cnt
	from routes r
	group by departure_city)
select 11, departure_city
from cnt_routes
where cnt = (select min(cnt) from cnt_routes)
order by departure_city) e;

--12.	Вывести пары городов, у которых нет прямых сообщений исключив реверсные дубликаты
insert into results
select * from (
with d_routes as(
	select distinct departure_city, arrival_city
	from routes)
select 12, concat(dep_city, '|', arr_city)
from(
	select t1.departure_city dep_city, t2.arrival_city arr_city
	from d_routes t1, d_routes t2
	where t1.departure_city < t2.arrival_city
	except
	select * from d_routes) a
order by dep_city, arr_city) e;

--13.	Вывести города, до которых нельзя добраться без пересадок из Москвы?

insert into results
select distinct 13, departure_city
from routes
where departure_city != 'Москва'
	and departure_city not in (
		select arrival_city from routes
		where departure_city = 'Москва')
order by departure_city;

--14.	Вывести модель самолета, который выполнил больше всего рейсов
insert into results
select 14, a.model
from flights f
    join aircrafts a on f.aircraft_code = a.aircraft_code
where f.status = 'Arrived'
group by a.model
order by count(flight_id) DESC
limit 1;

--15.	Вывести модель самолета, который перевез больше всего пассажиров
insert into results
select 15, a.model
from ticket_flights tf
    join flights f on tf.flight_id = f.flight_id
    join aircrafts a on f.aircraft_code = a.aircraft_code
where f.status = 'Arrived'
group by a.model
order by count(tf.ticket_no) desc
limit 1;


--16.	Вывести отклонение в минутах суммы запланированного времени перелета от фактического по всем перелётам

insert into  results
select 16, abs(extract(epoch from sum(scheduled_duration) - sum(actual_duration)) / 60) as dif
from flights_v
where status = 'Arrived';

--17.	Вывести города, в которые осуществлялся перелёт из Санкт-Петербурга 201-09-13

insert into results
select distinct 17, arrival_city
from flights_v
where date(actual_departure) = '2016-09-13'
  and status in ('Arrived', 'Departed')
  and departure_city = 'Санкт-Петербург'
order by arrival_city;


--18.	Вывести перелёт(ы) с максимальной стоимостью всех билетов
insert into results
select 18, flight_id
from flights_v
where flight_id = (
	select flight_id
	from ticket_flights
	group by flight_id
	order by sum(amount) desc
	limit 1);

--19.	Выбрать дни в которых было осуществлено минимальное количество перелётов
insert into results
select * from (
with cnt_flights as (
	select date(actual_departure) as depart_date, count(flight_id) as cnt
	from flights f
	where status != 'Cancelled'
		  and actual_departure is not null
	group by date(actual_departure)
)
select 19, depart_date
from cnt_flights
where cnt = (
	select min(cnt)
	from cnt_flights)
) e;


--	20.	Вывести среднее количество вылетов в день из Москвы за 09 месяц 2016 года

insert into results
select * from (
with flights_m as (
select cast(actual_departure as date) dd, count(1) cnt
from flights_v fv
where extract(year from fv.actual_departure) = 2016
    and extract(month from fv.actual_departure) = 9
	and status in('Arrived','Departed')
	and departure_city = 'Москва'
group by cast(actual_departure as date)
)
select 20 id, avg(cnt)
from flights_m ) e;

--	21.	Вывести топ 5 городов у которых среднее время перелета до пункта назначения больше 3 часов


insert into results
select 21, departure_city
from flights_v
where status = 'Arrived'
group by departure_city
having avg(actual_duration) > interval '3 hours'
order by avg(actual_duration) desc
limit 5;