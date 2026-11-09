// ==============================================================================
// PROJETO: WM CASH CONTROL ONLINE
// CONFIGURAÇÃO PÚBLICA DO SUPABASE CLIENT
// ==============================================================================
// IMPORTANTE: Insira aqui a URL do seu projeto Supabase e a Chave Pública Anon.
// Estas chaves são seguras para uso no frontend público, pois toda a segurança
// de leitura, escrita e exclusão é garantida pelo Row Level Security (RLS) no PostgreSQL.
// JAMAIS insira a chave "service_role" aqui!
// ==============================================================================

const SUPABASE_CONFIG = {
    // Exemplo: 'https://xyzcompany.supabase.co'
    url: window.localStorage.getItem('wm_supabase_url') || '',
    
    // Exemplo: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
    anonKey: window.localStorage.getItem('wm_supabase_anon_key') || ''
};

// Instância do cliente Supabase
let supabaseClient = null;

function initSupabase() {
    if (window.supabase && SUPABASE_CONFIG.url && SUPABASE_CONFIG.anonKey) {
        try {
            supabaseClient = window.supabase.createClient(SUPABASE_CONFIG.url, SUPABASE_CONFIG.anonKey, {
                auth: {
                    persistSession: true,
                    autoRefreshToken: true,
                    detectSessionInUrl: true
                }
            });
            return true;
        } catch(e) {
            console.error("Erro ao inicializar Supabase Client:", e);
            return false;
        }
    }
    return false;
}
