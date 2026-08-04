import 'package:supabase_functions/supabase_functions.dart';

Deno.serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { action, plan, amount, currency, phone, email, tx_ref } = await req.json();

    if (action === 'initialize') {
      return new Response(
        JSON.stringify({
          status: 'success',
          message: 'Flutterwave checkout session initialized',
          link: `https://checkout.flutterwave.com/v3/hosted/pay/mock_${tx_ref}`,
          tx_ref: tx_ref,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      );
    }

    if (action === 'verify') {
      return new Response(
        JSON.stringify({
          status: 'successful',
          tx_ref: tx_ref,
          verified: true,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      );
    }

    return new Response(
      JSON.stringify({ error: 'Invalid action' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    );
  }
});
