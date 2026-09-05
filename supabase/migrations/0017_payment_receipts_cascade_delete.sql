-- ==============================================================================
-- Migration: 0017_payment_receipts_cascade_delete.sql
-- Description: Updates payment_receipts foreign key constraint to ON DELETE CASCADE
-- ==============================================================================

BEGIN;

-- Drop existing FK constraint(s) on payment_receipts.user_id
DO $$
DECLARE
    v_con text;
BEGIN
    FOR v_con IN
        SELECT tc.constraint_name
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu
          ON tc.constraint_name = kcu.constraint_name
          AND tc.table_schema = kcu.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY'
          AND tc.table_schema = 'public'
          AND tc.table_name = 'payment_receipts'
          AND kcu.column_name = 'user_id'
    LOOP
        EXECUTE format('ALTER TABLE public.payment_receipts DROP CONSTRAINT IF EXISTS %I', v_con);
    END LOOP;
END $$;

-- Add foreign key constraint with ON DELETE CASCADE
ALTER TABLE public.payment_receipts
    ADD CONSTRAINT payment_receipts_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users (id) ON DELETE CASCADE;

COMMIT;
