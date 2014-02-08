
-- Original
select distinct dim_date.year_no "Year", dim_date.month_name "Month Name", dim_date.day_of_week "Day of Week" 
from dim_date 
where dim_date.year_no in ( '2010') 
and dim_date.month_name in ( 'January') 
and dim_date.day_of_week in ( 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday') 
group by dim_date.year_no, dim_date.month_name, dim_date.day_of_week 
order by dim_date.year_no, right('0' || month_no,2), day_of_week_no;

-- Fixed
select "Year", "Month Name", "Day of Week"
from (
	select distinct dim_date.year_no "Year", dim_date.month_name "Month Name", dim_date.day_of_week "Day of Week", right('0' || month_no,2) month_no, day_of_week_no
	from dim_date 
	where dim_date.year_no in ( '2010') 
	and dim_date.month_name in ( 'January') 
	and dim_date.day_of_week in ( 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday') 
	group by dim_date.year_no, dim_date.month_name, dim_date.day_of_week, right('0' || month_no,2), day_of_week_no 
) T
order by "Year", month_no, day_of_week_no;
