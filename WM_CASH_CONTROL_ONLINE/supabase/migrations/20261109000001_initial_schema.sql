-- ==============================================================================
-- PROJETO: WM CASH CONTROL ONLINE
-- VERSÃO: 1.0.0
-- BANCO DE DADOS: PostgreSQL (Supabase)
-- DESCRIÇÃO: Estrutura completa de banco de dados, constraints de integridade,
--            índices de alta performance e políticas de segurança RLS (Row Level Security).
-- ==============================================================================

-- 1. HABILITAR EXTENSÃO UUID (padrão no Supabase)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- 2. TABELA: user_settings (Configurações Financeiras do Usuário)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.user_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    default_year INTEGER NOT NULL DEFAULT 2026,
    simulated_card_cut NUMERIC(5,2) DEFAULT 15.00,
    simulated_fixed_cut NUMERIC(5,2) DEFAULT 10.00,
    emergency_months INTEGER DEFAULT 6,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_user_settings_user UNIQUE (user_id),
    CONSTRAINT chk_default_year CHECK (default_year >= 2000 AND default_year <= 2100),
    CONSTRAINT chk_emergency_months CHECK (emergency_months IN (3, 6, 12))
);

COMMENT ON TABLE public.user_settings IS 'Armazena preferências financeiras, ano padrão e parâmetros de simulação do usuário.';

-- ==============================================================================
-- 3. TABELA: revenue_sources (Fontes de Receita / Entradas Mensais)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.revenue_sources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    year INTEGER NOT NULL,
    name VARCHAR(150) NOT NULL,
    type VARCHAR(30) NOT NULL DEFAULT 'Fixa',
    values NUMERIC(15,2)[] NOT NULL DEFAULT ARRAY[0,0,0,0,0,0,0,0,0,0,0,0]::NUMERIC(15,2)[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT chk_revenue_year CHECK (year >= 2000 AND year <= 2100),
    CONSTRAINT chk_revenue_type CHECK (type IN ('Fixa', 'Variável', 'Variavel')),
    CONSTRAINT chk_revenue_values_length CHECK (array_ndims(values) = 1 AND array_length(values, 1) = 12)
);

COMMENT ON TABLE public.revenue_sources IS 'Fontes de receita do usuário por ano, contendo exatamente 12 meses de valores (Jan a Dez).';

-- ==============================================================================
-- 4. TABELA: expenses (Contas / Despesas / Parcelamentos / Empréstimos)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    year INTEGER NOT NULL,
    name VARCHAR(150) NOT NULL,
    category VARCHAR(60) NOT NULL DEFAULT 'Outros',
    due_day INTEGER NOT NULL DEFAULT 10,
    values NUMERIC(15,2)[] NOT NULL DEFAULT ARRAY[0,0,0,0,0,0,0,0,0,0,0,0]::NUMERIC(15,2)[],
    paid_months BOOLEAN[] NOT NULL DEFAULT ARRAY[false,false,false,false,false,false,false,false,false,false,false,false]::BOOLEAN[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT chk_expense_year CHECK (year >= 2000 AND year <= 2100),
    CONSTRAINT chk_expense_due_day CHECK (due_day >= 1 AND due_day <= 31),
    CONSTRAINT chk_expense_values_length CHECK (array_ndims(values) = 1 AND array_length(values, 1) = 12),
    CONSTRAINT chk_expense_paid_months_length CHECK (array_ndims(paid_months) = 1 AND array_length(paid_months, 1) = 12)
);

COMMENT ON TABLE public.expenses IS 'Despesas e contas do usuário por ano, contendo exatamente 12 valores e 12 status de pagamento booleanos (Jan a Dez).';

-- ==============================================================================
-- 5. ÍNDICES DE PERFORMANCE
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_user_settings_user ON public.user_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_revenue_sources_user_year ON public.revenue_sources(user_id, year);
CREATE INDEX IF NOT EXISTS idx_expenses_user_year ON public.expenses(user_id, year);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON public.expenses(user_id, year, category);

-- ==============================================================================
-- 6. FUNÇÃO E TRIGGERS: ATUALIZAÇÃO AUTOMÁTICA DE updated_at
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_user_settings_updated_at ON public.user_settings;
CREATE TRIGGER trg_user_settings_updated_at
    BEFORE UPDATE ON public.user_settings
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_revenue_sources_updated_at ON public.revenue_sources;
CREATE TRIGGER trg_revenue_sources_updated_at
    BEFORE UPDATE ON public.revenue_sources
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_expenses_updated_at ON public.expenses;
CREATE TRIGGER trg_expenses_updated_at
    BEFORE UPDATE ON public.expenses
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ==============================================================================
-- 7. SEGURANÇA: ROW LEVEL SECURITY (RLS) E POLÍTICAS DE ACESSO
-- ==============================================================================

-- 7.1 HABILITAR RLS EM TODAS AS TABELAS
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.revenue_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

-- 7.2 POLÍTICAS: user_settings
DROP POLICY IF EXISTS "Usuários podem visualizar suas próprias configurações" ON public.user_settings;
CREATE POLICY "Usuários podem visualizar suas próprias configurações"
    ON public.user_settings FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuários podem inserir suas próprias configurações" ON public.user_settings;
CREATE POLICY "Usuários podem inserir suas próprias configurações"
    ON public.user_settings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuários podem atualizar suas próprias configurações" ON public.user_settings;
CREATE POLICY "Usuários podem atualizar suas próprias configurações"
    ON public.user_settings FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuários podem excluir suas próprias configurações" ON public.user_settings;
CREATE POLICY "Usuários podem excluir suas próprias configurações"
    ON public.user_settings FOR DELETE
    USING (auth.uid() = user_id);

-- 7.3 POLÍTICAS: revenue_sources
DROP POLICY IF EXISTS "Usuários podem visualizar suas próprias receitas" ON public.revenue_sources;
CREATE POLICY "Usuários podem visualizar suas próprias receitas"
    ON public.revenue_sources FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuários podem inserir suas próprias receitas" ON public.revenue_sources;
CREATE POLICY "Usuários podem inserir suas próprias receitas"
    ON public.revenue_sources FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuários podem atualizar suas próprias receitas" ON public.revenue_sources;
CREATE POLICY "Usuários podem atualizar suas próprias receitas"
    ON public.revenue_sources FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuários podem excluir suas próprias receitas" ON public.revenue_sources;
CREATE POLICY "Usuários podem excluir suas próprias receitas"
    ON public.revenue_sources FOR DELETE
    USING (auth.uid() = user_id);

-- 7.4 POLÍTICAS: expenses
DROP POLICY IF EXISTS "Usuários podem visualizar suas próprias despesas" ON public.expenses;
CREATE POLICY "Usuários podem visualizar suas próprias despesas"
    ON public.expenses FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuários podem inserir suas próprias despesas" ON public.expenses;
CREATE POLICY "Usuários podem inserir suas próprias despesas"
    ON public.expenses FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuários podem atualizar suas próprias despesas" ON public.expenses;
CREATE POLICY "Usuários podem atualizar suas próprias despesas"
    ON public.expenses FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuários podem excluir suas próprias despesas" ON public.expenses;
CREATE POLICY "Usuários podem excluir suas próprias despesas"
    ON public.expenses FOR DELETE
    USING (auth.uid() = user_id);
