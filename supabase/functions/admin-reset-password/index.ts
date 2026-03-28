import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!

    // Caller'ın JWT'sini doğrula — Supabase önerilen pattern:
    // anon key + user JWT header → auth.getUser() parametresiz
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Yetkilendirme başlığı eksik.' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const callerClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } }
    })

    const { data: { user: callerUser }, error: authErr } = await callerClient.auth.getUser()
    if (authErr || !callerUser) {
      return new Response(JSON.stringify({ error: 'Oturum doğrulanamadı: ' + (authErr?.message ?? '') }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // adminClient — tüm DB sorguları ve admin operasyonları service role ile (RLS bypass)
    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false }
    })

    // Caller'ın yönetici olduğunu doğrula (service role ile, RLS yok)
    const { data: callerPersonel, error: rolErr } = await adminClient
      .from('personel')
      .select('rol_kodu')
      .eq('auth_id', callerUser.id)
      .single()

    if (rolErr || callerPersonel?.rol_kodu !== 'yönetici') {
      return new Response(JSON.stringify({ error: 'Bu işlem yalnızca yöneticilere açıktır.' }), {
        status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // İstek gövdesini oku
    const { pkod, new_password } = await req.json()

    if (!pkod || !new_password) {
      return new Response(JSON.stringify({ error: 'pkod ve new_password zorunludur.' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    if (new_password.length < 8) {
      return new Response(JSON.stringify({ error: 'Şifre en az 8 karakter olmalıdır.' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Hedef kullanıcının auth_id'sini bul
    const { data: targetPersonel, error: targetErr } = await adminClient
      .from('personel')
      .select('auth_id, ad, soyad')
      .eq('pkod', pkod)
      .single()

    if (targetErr || !targetPersonel?.auth_id) {
      return new Response(JSON.stringify({ error: 'Kullanıcı bulunamadı veya auth_id eksik.' }), {
        status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Şifreyi güncelle
    const { error: updateErr } = await adminClient.auth.admin.updateUserById(
      targetPersonel.auth_id,
      { password: new_password }
    )

    if (updateErr) {
      return new Response(JSON.stringify({ error: updateErr.message }), {
        status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    return new Response(
      JSON.stringify({ success: true, message: `${targetPersonel.ad} ${targetPersonel.soyad} için şifre güncellendi.` }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
