-- Find unique first 5 characters of sku/upc
select substr(sku,1,7), brand, count(*) from dim_product
where brand != ''
group by substr(sku,1,7), brand

-- Change the first 5 characters of sku
update dim_product set sku = '0-41275' || substr(sku,8,7)  where substr(sku,1,7) = '0-72368';
update dim_product set sku = '0-79371' || substr(sku,8,7)  where substr(sku,1,7) = '0-70044';
update dim_product set sku = '0-12187' || substr(sku,8,7)  where substr(sku,1,7) = '7-54122';

-- Change brand in description
update dim_product set description = replace(description, 'Antolina', 'Terneth')       where brand = 'Antolina';
update dim_product set description = replace(description, 'Champion', 'Failina')       where brand = 'Champion';
update dim_product set description = replace(description, 'Cocco', 'Chocowill')        where brand = 'Cocco';
update dim_product set description = replace(description, 'Colonial Inn', 'Old Hotel') where brand = 'Colonial Inn';
update dim_product set description = replace(description, 'DeLallo', 'Reynaldo')       where brand = 'DeLallo';
update dim_product set description = replace(description, 'Prince Omar', 'Shiek Sam')  where brand = 'Prince Omar';
update dim_product set description = replace(description, 'San Martino', 'Monaco')     where brand = 'San Martino';

-- Change brand
update dim_product set brand = 'Terneth'   where brand = 'Antolina';
update dim_product set brand = 'Failina'   where brand = 'Champion';
update dim_product set brand = 'Chocowill' where brand = 'Cocco';
update dim_product set brand = 'Old Hotel' where brand = 'Colonial Inn';
update dim_product set brand = 'Reynaldo'  where brand = 'DeLallo';
update dim_product set brand = 'Shiek Sam' where brand = 'Prince Omar';
update dim_product set brand = 'Monaco'    where brand = 'San Martino';

-- fix last 5 characters of sku
update dim_product set sku = substr(sku,1,7) || reverse(substr(sku,8,5)) || substr(sku,13,2);
--select sku, substr(sku,1,7) || reverse(substr(sku,8,5)) || substr(sku,13,2) from dim_product;

-- move updated sku into upc
update dim_product set upc = sku;


-- Pull out new load file
select * from (
	select
	  sku || '~' ||  sku_and_version || '~' ||  base_sku || '~' ||  upc || '~' ||  department || '~' ||
	  category || '~' ||  sub_category || '~' ||  description || '~' ||  brand || '~' ||  price || '~' ||
	  cost || '~' ||  coupon || '~' ||  promotion_level || '~' ||  unit_of_measure || '~' ||  weight || '~' ||
	  upc_contains_price || '~' ||  unit_pack || '~' ||  case_pack || '~' ||  layer_count || '~' ||  layers_per_pallet || '~' ||
	  pallet_height || '~' ||  pallet_width || '~' ||  pallet_depth || '~' ||  pallet_stack_count || '~' ||  pallet_package_type || '~' ||
	  gluten_free || '~' ||  fat_content || '~' ||  organic || '~' ||  sugar_content || '~' ||  cholesterol_content || '~' ||
	  "natural" || '~' ||  kosher || '~' ||  halal || '~' ||  country_origin || '~' ||  region_origin as val
	from dim_product
	where brand != ''
	order by product_key
) T where val like '%"%'