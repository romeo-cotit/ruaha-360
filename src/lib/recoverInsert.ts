import { supabase } from '@/lib/supabase'

/** A timed-out response can follow a committed insert. Never blindly replay it. */
export async function recoverInsert(table: 'pue_request' | 'buyer' | 'buyer_demand' | 'opportunity_supply', id: string | undefined, error: { message: string }) {
  if (id) {
    const result = await supabase.from(table).select('id').eq('id', id).maybeSingle()
    if (!result.error && result.data) return result.data
  }
  throw new Error(error.message)
}
