/*
    select Count(*) from test
    select * from test
    select * from dim_store
    select * from fct_sales
    select * from fct_payments
    select * from dim_product
    select * from dim_payment_method
    select (20+trunc(random() * 9 + 1)) 
    SELECT yyyymmdd_date FROM dim_date where yyyymmdd_date between 20130101::text and 20130202::text ORDER BY yyyymmdd_date

    select (power(random()+0.5, 3.5)+0.5)::integer from generate_series(1,10) A;


    DO $$
    DECLARE
        a integer := 0;
    BEGIN
        a = load_fct_payments();
        RAISE NOTICE 'Return value is %', a;
    END$$;

*/


CREATE OR REPLACE FUNCTION load_fct_payments() RETURNS integer AS $$
    --<< outerblock >>
DECLARE
    payments RECORD;
    rand_pm real;
    payment_methods integer ARRAY;
    payment integer ARRAY;
    num_payment_methods integer;
    payment_idx integer;
    lines_loaded integer := 0;
BEGIN
    truncate table fct_payments;
    FOR payments IN
        select F.date_key, store_key, transaction_key, Sum(ext_sales_amnt) tran_amount
        from fct_sales F 
            inner join dim_date D on F.date_key = D.date_key
        where D.yyyymmdd_date <> '' --and D.yyyymmdd_date::integer between #{start_date} and #{end_date}
        group by F.date_key, store_key, transaction_key
        order by F.date_key, store_key, transaction_key
    LOOP
        rand_pm := random();
        payment[1] := payments.tran_amount;
        num_payment_methods := 1;
        IF rand_pm < 0.3 THEN
          payment_methods[1] := 1;   -- cash
        ELSIF rand_pm < 0.6 THEN
          payment_methods[1] :=  2;  -- check
        ELSIF rand_pm < 0.65 THEN
          payment_methods[1] :=  3;  -- Visa
        ELSIF rand_pm < 0.70 THEN
          payment_methods[1] :=  4;  -- MasterCard
        ELSIF rand_pm < 0.75 THEN
          payment_methods[1] :=  5;  -- Discover
        ELSIF rand_pm < 0.80 THEN
          payment_methods[1] :=  6;  -- AmericanExpress
        ELSIF rand_pm < 0.85 THEN
          payment_methods[1] :=  1;  -- cash and
          payment_methods[2] :=  2;  -- check
          payment[2] = payment[1]/2;
          payment[1] = payment[1] - payment[2];
          num_payment_methods := 2;
        ELSIF rand_pm < 0.90 THEN
          payment_methods[1] := 1;  -- cash and
          payment_methods[2] := 3;  -- Visa
          payment[2] := payment[1]/3;
          payment[1] := payment[1] - payment[2];
          num_payment_methods := 2;
        ELSIF rand_pm < 0.95 THEN
          payment_methods[1] := 2;  -- check and
          payment_methods[2] := 4;  -- MasterCard
          payment[2] := payment[1]/4;
          payment[1] := payment[1] - payment[2];
          num_payment_methods := 2;
        ELSE
          payment_methods[1] := 1;  -- cash and
          payment_methods[2] := 2;  -- check and
          payment_methods[3] := 3;  -- Visa
          payment[2] := payment[1]/2;
          payment[1] := payment[1] - payment[2];
          payment[3] := payment[2]/2;
          payment[2] := payment[2] - payment[3];
          num_payment_methods := 3;
        END IF;

        FOR payment_idx IN 1..num_payment_methods LOOP
            INSERT INTO fct_payments (date_key, store_key, payment_method_key, transaction_key, payment_anount)
            VALUES (payments.date_key, payments.store_key, payment_methods[payment_idx], payments.transaction_key, payment[payment_idx]);
            lines_loaded := lines_loaded + 1;
        END LOOP;
    END LOOP;

    RETURN lines_loaded;
END;
$$ LANGUAGE plpgsql;
