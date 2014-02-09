-- Function: load_fct_sales(integer, integer)

-- DROP FUNCTION load_fct_sales(integer, integer);

CREATE OR REPLACE FUNCTION load_fct_sales(start_date integer, end_date integer)
  RETURNS integer AS
$BODY$
    --<< outerblock >>
DECLARE
    dates RECORD;
    stores RECORD;
    products RECORD;
    transaction_no bigint;
    tran integer;
    transaction_key bigint := 0;
    item_count integer;
    cashier_key integer;
    sales_qty integer;
    reg_unit_price integer;
    disc_unit_price integer;
    net_unit_price integer;
    ext_disc_amnt integer;
    ext_sales_amnt integer;
    ext_cost_amnt integer;
    ext_gross_profit_amnt integer;
    int_price integer;
    int_cost integer;
    product_percentage integer := 40;
    year_multiplier float ARRAY := '{1.0,1.1,1.05,1.2,1.25}';
    month_multiplier float ARRAY := '{1.1,0.9,1.0,  1.0,1.1,1.2,  1.25,1.25,1.0,  1.0,1.35,1.3}';
    day_of_week_multiplier float ARRAY := '{1.2,  0.9,1.0,1.1,1.0,1.1,  1.3}';  -- Sunday, Monday, ... Friday, Saturday
    final_multiplier float;
    store_multiplier float;
    tran_cnt_base integer  := 8;	-- 140
    tran_cnt_rand integer  := 2;	-- 20
    prod_perc_base integer := 8;	-- 20
    prod_perc_rand integer := 2;	-- 40
BEGIN
    truncate table fct_sales;
    truncate table dim_transaction;
    -- For each date requested
    FOR dates IN SELECT date_key, yyyymmdd_date, year_no, month_no, day_no, day_of_week_no FROM dim_date where yyyymmdd_date between start_date::text and end_date::text ORDER BY yyyymmdd_date LOOP
        -- For all stores
        FOR stores IN SELECT store_key, name, name_code, square_footage FROM dim_store where name_code <> '' ORDER BY name_code LOOP
            -- Calculate the multiplier for this day and this store
            store_multiplier := replace(stores.square_footage, ',', '')::float;
            final_multiplier := year_multiplier[dates.year_no::integer - 2009] * month_multiplier[dates.month_no::integer] * 
                day_of_week_multiplier[dates.day_of_week_no::integer+1] * (store_multiplier/15000.0);
            -- For a bunch of transactions
            transaction_no := ( (dates.yyyymmdd_date::bigint * 1000) + stores.store_key) * 10000;
            FOR tran IN 1..(  trunc(tran_cnt_base * final_multiplier) + trunc(random() * tran_cnt_rand * final_multiplier)  ) LOOP
                transaction_no := transaction_no + 1;
                transaction_key := transaction_key + 1;
                item_count := 0;
                cashier_key := trunc(random() * 3 + 1);
                product_percentage := prod_perc_base + (random() * prod_perc_rand)::integer;
                FOR products IN SELECT product_key, price, cost FROM dim_product where brand <> '' ORDER BY product_key LOOP
                    IF random() * 1000 < product_percentage THEN
                        item_count := item_count + 1;
                        sales_qty := (power(random()+0.5, 3.5)+0.5)::integer;
                        int_price := (products.price::real*100.0)::integer;
                        int_cost  := (products.cost::real*100.0)::integer;

                        -- Calculate the singular price values
                        reg_unit_price := int_price;
                        disc_unit_price := ((int_price-int_cost)/2);
                        net_unit_price := reg_unit_price - disc_unit_price;

                        -- Calculate the extended price/cost values
                        ext_disc_amnt := sales_qty * disc_unit_price;
                        ext_sales_amnt := sales_qty * net_unit_price;
                        ext_cost_amnt := sales_qty * int_cost;
                        ext_gross_profit_amnt := ext_sales_amnt - ext_cost_amnt;

                        insert into fct_sales (
                            date_key, product_key, store_key, promotion_key, cashier_key, payment_method_key, transaction_key, 
                            transaction_no, sales_qty, reg_unit_price, disc_unit_price, net_unit_price, 
                            ext_disc_amnt, ext_sales_amnt, ext_cost_amnt, ext_gross_profit_amnt
                        )
                        values (
                            dates.date_key, products.product_key, stores.store_key, 1, cashier_key, 1, transaction_key, 
                            transaction_no, sales_qty, reg_unit_price, disc_unit_price, net_unit_price, 
                            ext_disc_amnt, ext_sales_amnt, ext_cost_amnt, ext_gross_profit_amnt
                        );
                    END IF; -- random product selection
                END LOOP; -- for all products for this transaction

                insert into dim_transaction (transaction_no, store_name, year_no, month_no, day_no, yyyymmdd_date, item_count)
                values (transaction_no, stores.name,  dates.year_no, dates.month_no, dates.day_no, dates.yyyymmdd_date, item_count);
                
            END LOOP; -- for random transactions
        END LOOP; -- for stores
    END LOOP; -- for dates

    RETURN 1;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION load_fct_sales(integer, integer)
  OWNER TO postgres;

