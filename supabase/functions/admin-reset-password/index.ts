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

    // Authorization header kontrolü
    const authHeader = req.headers.get('Authorization') ?? ''
    if (!authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Yetkilendirme başlığı eksik.' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // JWT doğrulama: callerClient (anon key + user JWT) → auth.getUser()
    // Supabase önerilen pattern — imzayı doğrular ve user bilgisini döner
    const callerClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } }
    })
    const { data: { user: callerUser }, error: authErr } = await callerClient.auth.getUser()
    if (authErr || !callerUser) {
      return new Response(JSON.stringify({ error: 'Oturum doğrulanamadı: ' + (authErr?.message ?? '') }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // adminClient — tüm DB sorguları service role ile (RLS bypass)
    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false }
    })

    // Caller'ın yönetici olduğunu doğrula
    const { data: callerPersonel, error: rolErr } = await adminClient
      .from('personel')
      .select('rol_kodu')
      .eq('auth_id', callerUser.id)
      .single()

    if (rolErr || callerPersonel?.rol_kodu !== 'yönetici') {
      return new Response(JSON.stringify({
        error: 'Bu işlem yalnızca yöneticilere açıktır.',
        detail: rolErr?.message ?? null
      }), {
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
      .select('auth_id, ad, soyad, eposta')
      .eq('pkod', pkod)
      .single()

    if (targetErr || !targetPersonel) {
      return new Response(JSON.stringify({
        error: 'Kullanıcı bulunamadı.',
        detail: targetErr?.message ?? null
      }), {
        status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // auth_id yoksa → yeni Supabase Auth kullanıcısı oluştur
    if (!targetPersonel.auth_id) {
      if (!targetPersonel.eposta) {
        return new Response(JSON.stringify({
          error: 'Bu kullanıcının e-posta adresi eksik. Önce Ayarlar sayfasından e-posta adresini ekleyin.'
        }), {
          status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
      }
      const { data: newUser, error: createErr } = await adminClient.auth.admin.createUser({
        email: targetPersonel.eposta,
        password: new_password,
        email_confirm: true
      })
      if (createErr || !newUser?.user) {
        return new Response(JSON.stringify({
          error: createErr?.message ?? 'Kullanıcı hesabı oluşturulamadı.'
        }), {
          status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
      }
      await adminClient.from('personel').update({ auth_id: newUser.user.id }).eq('pkod', pkod)
      return new Response(
        JSON.stringify({ success: true, message: `${targetPersonel.ad} ${targetPersonel.soyad} için hesap oluşturuldu ve şifre belirlendi.` }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // auth_id varsa → mevcut şifreyi güncelle
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
