
-- *************************************************************************
select dim_date.year_no "Year", 
    dim_product.category "Category", 
    dim_product.upc "UPC", 
    dim_product.description "Description", 
    Sum(fct_sales.sales_qty) "Sum of Sales Qty", 
    Count(fct_sales.reg_unit_price) "Count of Reg Unit Price"
from fct_sales
    inner join dim_date on fct_sales.date_key = dim_date.date_key
    inner join dim_product on fct_sales.product_key = dim_product.product_key
where fct_sales.date_key in (
    select date_key
    from dim_date
    where dim_date.year_no in ( "2011", "2013") 
    and dim_date.month_no in ( "1", "2", "3")
) 
and fct_sales.product_key in (
    select product_key
    from dim_product
    where dim_product.category in ( "Bakery", "Grocery") 
    and dim_product.upc in ( "0-7236801523-1", "0-7236801524-8") 
    and dim_product.description in ( "DeLallo Grt Northern Bns", "DeLallo Romano Bns")
) 
group by dim_date.year_no, dim_product.category, dim_product.upc, dim_product.description
order by dim_date.year_no, dim_product.category, dim_product.upc, dim_product.description;

