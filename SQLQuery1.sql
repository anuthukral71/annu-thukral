-- Inspecting Data
select * from [dbo].[sales_data_sample]

-- Checking Unique values

select distinct STATUS from [dbo].[sales_data_sample]
select distinct YEAR_ID from [dbo].[sales_data_sample]
select distinct PRODUCTLINE from [dbo].[sales_data_sample]
select distinct COUNTRY from [dbo].[sales_data_sample]
select distinct DEALSIZE from [dbo].[sales_data_sample]
select distinct TERRITORY from [dbo].[sales_data_sample]

-- Analysis
-- Lets start by grouping sales by productline

select productline, round(sum(sales),2) Revenue
from sales_data_sample
group by productline
order by Revenue desc


select year_id, round(sum(sales),2) Revenue
from sales_data_sample
group by year_id
order by Revenue desc


select distinct MONTH_ID, sum(sales) from [dbo].[sales_data_sample]
where year_id = 2005
group by MONTH_ID

select DEALSIZE, round(sum(sales),2) Revenue
from sales_data_sample
group by DEALSIZE
order by Revenue desc

-- What was the best month for sales in a specific year? How much was earned that month?
 -- Year 2023
 select MONTH_ID, sum(sales) Revenue, count(ordernumber) Frequency
 from sales_data_sample
 where YEAR_ID = 2004
 group by MONTH_ID
 order by Revenue desc

 -- Year 2004
 select MONTH_ID, sum(sales) Revenue, count(ordernumber) Frequency
 from sales_data_sample
 where YEAR_ID = 2004
 group by MONTH_ID
 order by Revenue desc

 -- month 11(November) has the highest Revenues for both years

 -- what product do they sell in november?

 select PRODUCTLINE, sum(sales) Revenue, count(ordernumber) Frequency
 from sales_data_sample
 where MONTH_ID = 11
 group by PRODUCTLINE
 order by Revenue desc

 -- who is our best customer?
 
 drop table if exists #rfm 
 ;with rfm as
 (
	select 
		CUSTOMERNAME, 
		sum(sales) MonetaryValue,
		avg(sales) AVGMonetaryValue,
		count(ordernumber) Frequency,
		max(orderdate) latest_order_date,
		(select max(orderdate) from sales_data_sample) max_order_date,
		datediff(DD, max(orderdate),(select max(orderdate) from sales_data_sample)) Recency
	from sales_data_sample
	group by CUSTOMERNAME
),
rfm_calc as
(
	select r.*,
		NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by Frequency) rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue) rfm_monetary
	from rfm r 
)
select
	c.*, rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary as varchar) rfm_cell_string
into #rfm
from rfm_calc c

select CUSTOMERNAME, rfm_recency , rfm_frequency , rfm_monetary,
	case
		when rfm_cell_string in (111,112,121,122,123,132,211,212,114,141) then'lost customers' --lost customers
		when rfm_cell_string in (133,134,143,244,334,343,344,144) then'slipping away, cannot lose' 
		when rfm_cell_string in (311,411,331) then'new customers' 
		when rfm_cell_string in (222,223,233,322) then'potential churners' 
		when rfm_cell_string in (323,333,321,422,332,432) then'active' 
		when rfm_cell_string in (433,434,443,444) then'loyal' 
	end rfm_segment
from #rfm

-- what products are most often sold together?

-- select * from sales_data_sample where ordernumber = 10411
select distinct ordernumber,  stuff(
	(select ',' + PRODUCTCODE
	from sales_data_sample p
	where ordernumber in (

		select ordernumber
		from (
			select ordernumber, count(*) rn
			from sales_data_sample
			where status = 'Shipped'
			group by ordernumber
		) m
		where rn = 2
	)
	and p.ORDERNUMBER = s.ORDERNUMBER
	for xml path (''))
	, 1, 1, '') ProductCodes
from sales_data_sample s
order by 2 desc