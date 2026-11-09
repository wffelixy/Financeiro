# GUIA DE PUBLICAÇÃO & CONFIGURAÇÃO ONLINE — WM CASH CONTROL

Este guia explica passo a passo como configurar o **Supabase** e publicar a aplicação online (no **GitHub Pages**, **Vercel** ou qualquer hospedagem estática gratuita) sem precisar instalar nenhum programa na sua máquina local.

---

## 1. Configuração do Banco de Dados no Supabase (Gratuito)

1. Crie uma conta gratuita em [supabase.com](https://supabase.com).
2. Clique em **New project** e defina:
   - **Name**: `WM Cash Control`
   - **Database Password**: Escolha uma senha segura e anote.
   - **Region**: Selecione `South America (São Paulo)` para menor latência.
3. Aguarde o provisionamento do projeto (cerca de 1 a 2 minutos).

### 1.1 Execução do Script SQL (Tabelas, RLS e Triggers)
1. No menu lateral esquerdo do Supabase, clique no ícone **SQL Editor** (ou acesse `https://supabase.com/dashboard/project/<seu-id>/sql`).
2. Clique no botão **New query**.
3. Abra o arquivo [supabase/schema.sql](./supabase/schema.sql), copie todo o seu conteúdo e cole no editor SQL.
4. Clique em **Run** (Executar).
5. O painel exibirá `Success. No rows returned`. Todas as tabelas (`user_settings`, `revenue_sources`, `expenses`), constraints de 12 meses, índices e políticas de Row Level Security (RLS) estarão criadas.

---

## 2. Conectar o Frontend com o Supabase

1. No painel do Supabase, acesse **Project Settings** (ícone de engrenagem) > **API**.
2. Localize:
   - **Project URL** (ex: `https://abcdefghijklm.supabase.co`)
   - **anon / public key** (uma chave longa começando com `eyJhbGci...`)
   > ⚠️ **ATENÇÃO:** Nunca use a chave `service_role`. Ela dá acesso irrestrito ao banco e jamais deve ir para o frontend.
3. Abra o sistema no seu navegador (ex: clicando duas vezes em `index.html` ou pelo GitHub Pages).
4. Clique no ícone de engrenagem no cabeçalho ou no botão **Entrar > Configurações**.
5. Cole sua **Project URL** e sua chave **anon**.
6. Clique em **Salvar e Conectar**.
7. Pronto! A partir desse momento você pode clicar em **Entrar**, criar contas para você e sua família, e acessar de qualquer computador ou celular.

---

## 3. Publicação no GitHub Pages (Online para qualquer celular e PC)

1. Crie um repositório no seu GitHub (ex: `wm-cash-control`).
2. Faça o commit e push dos arquivos do projeto:
   - `index.html` (página principal)
   - `Financeiro.html`
   - `supabase_config.js`
   - `logo_wellington.svg`
   - pasta `manual/`
   - pasta `dados/`
   - pasta `supabase/`
3. No seu repositório no GitHub, acesse:
   - **Settings** > **Pages**
   - Em **Source**, selecione `Deploy from a branch`
   - Em **Branch**, selecione `main` (ou `master`) e pasta `/ (root)`
   - Clique em **Save**.
4. Em 1 a 2 minutos, o GitHub exibirá o link público da sua aplicação:
   `https://seu-usuario.github.io/wm-cash-control/`

---

## 4. Segurança Multiusuário e Isolamento

* O isolamento é garantido por **Row Level Security (RLS)** nativo no PostgreSQL.
* Quando o Usuário A faz login, o Supabase emite um token JWT contendo seu `user_id`.
* O banco de dados só retorna e só permite alterar linhas onde `auth.uid() = user_id`.
* O Usuário B, mesmo acessando pelo mesmo navegador ou inspecionando requisições, só tem permissão para visualizar e gerenciar os seus próprios registros.

---

## 5. Migração Segura e Backup

* **Migração dos Dados Anteriores**: Ao fazer login pela primeira vez em um computador com finanças salvas no navegador, o sistema exibe o assistente de migração, validando a quantidade de contas e receitas antes e depois do envio para a nuvem. Seus dados locais são preservados e só são apagados se você confirmar explicitamente.
* **Backup JSON**: Permanece ativo na barra superior para exportar e restaurar seus dados a qualquer momento em um único arquivo oficial `.json`.
