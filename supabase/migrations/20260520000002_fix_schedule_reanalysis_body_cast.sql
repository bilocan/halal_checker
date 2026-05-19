CREATE OR REPLACE FUNCTION public.products_schedule_reanalysis()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  _url text;
  _key text;
BEGIN
  IF (NEW.ingredients IS DISTINCT FROM OLD.ingredients OR
      NEW.name        IS DISTINCT FROM OLD.name        OR
      NEW.labels      IS DISTINCT FROM OLD.labels      OR
      NEW.is_non_food IS DISTINCT FROM OLD.is_non_food) THEN

    SELECT value INTO _url FROM app_config WHERE key = 'supabase_url'      LIMIT 1;
    SELECT value INTO _key FROM app_config WHERE key = 'supabase_anon_key' LIMIT 1;

    IF _url IS NOT NULL AND _key IS NOT NULL THEN
      PERFORM net.http_post(
        url     := _url || '/functions/v1/lookup-product',
        headers := jsonb_build_object(
          'Content-Type',  'application/json',
          'Authorization', 'Bearer ' || _key
        ),
        body    := jsonb_build_object('barcode', NEW.barcode)
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$function$;
