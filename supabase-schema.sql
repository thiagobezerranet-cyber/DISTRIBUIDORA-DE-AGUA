-- ============================================================
-- SISTEMA ÁGUA / GALÕES – Schema Supabase
-- Rode este SQL no Supabase: SQL Editor → New query → Run
-- ============================================================

-- Usuários do app (dono e entregadores) – login por NOME + PIN
CREATE TABLE IF NOT EXISTS usuarios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome TEXT NOT NULL UNIQUE,
  pin TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('admin', 'entregador')),
  ativo BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Configurações (preço galão, taxa entrega)
CREATE TABLE IF NOT EXISTS config (
  id INT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  preco_galao NUMERIC(10,2) NOT NULL DEFAULT 15,
  taxa_entrega NUMERIC(10,2) NOT NULL DEFAULT 4,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO config (id, preco_galao, taxa_entrega)
VALUES (1, 15, 4)
ON CONFLICT (id) DO NOTHING;

-- Clientes
CREATE TABLE IF NOT EXISTS clientes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome TEXT NOT NULL,
  whatsapp TEXT,
  endereco TEXT,
  bairro TEXT,
  cidade TEXT,
  obs TEXT,
  ano_galao_atual TEXT,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_clientes_bairro ON clientes (bairro);
CREATE INDEX IF NOT EXISTS idx_clientes_nome ON clientes (nome);

-- Funcionários (cadastro operacional – espelha entregadores ativos)
-- Pode usar a própria tabela usuarios com role=entregador.
-- Mantemos referencia por id de usuarios.

-- Produtos extras (bomba, filtro...)
CREATE TABLE IF NOT EXISTS produtos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome TEXT NOT NULL,
  tipo TEXT NOT NULL DEFAULT 'outro',
  preco NUMERIC(10,2) NOT NULL DEFAULT 0
);

-- Estoque por ano de fabricação do galão
CREATE TABLE IF NOT EXISTS estoque (
  ano TEXT PRIMARY KEY,
  cheios INT NOT NULL DEFAULT 0,
  vazios INT NOT NULL DEFAULT 0
);

-- Galões com clientes (cliente + ano → quantidade)
CREATE TABLE IF NOT EXISTS com_clientes (
  cliente_id UUID NOT NULL REFERENCES clientes(id) ON DELETE CASCADE,
  ano TEXT NOT NULL,
  qtd INT NOT NULL DEFAULT 0,
  PRIMARY KEY (cliente_id, ano)
);

-- Pedidos / vendas
CREATE TABLE IF NOT EXISTS pedidos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  data TIMESTAMPTZ NOT NULL DEFAULT now(),
  data_entrega TIMESTAMPTZ,
  cliente_id UUID REFERENCES clientes(id) ON DELETE SET NULL,
  ano_galao TEXT,
  qtd_galoes INT NOT NULL DEFAULT 0,
  preco_galao NUMERIC(10,2) NOT NULL DEFAULT 0,
  tipo_op TEXT NOT NULL DEFAULT 'entrega' CHECK (tipo_op IN ('entrega', 'retirada')),
  taxa_entrega NUMERIC(10,2) NOT NULL DEFAULT 0,
  entregador_id UUID REFERENCES usuarios(id) ON DELETE SET NULL,
  vazios_devolvidos INT NOT NULL DEFAULT 0,
  vazios_pendentes INT NOT NULL DEFAULT 0,
  outro_produto_id UUID REFERENCES produtos(id) ON DELETE SET NULL,
  outro_qtd INT NOT NULL DEFAULT 0,
  outro_preco NUMERIC(10,2) NOT NULL DEFAULT 0,
  valor_total NUMERIC(10,2) NOT NULL DEFAULT 0,
  valor_pago NUMERIC(10,2) NOT NULL DEFAULT 0,
  status_pagamento TEXT NOT NULL DEFAULT 'a_pagar' CHECK (status_pagamento IN ('pago', 'a_pagar', 'parcial')),
  status_entrega TEXT NOT NULL DEFAULT 'a_entregar' CHECK (status_entrega IN ('a_entregar', 'entregue', 'cancelado')),
  forma_pagamento TEXT,
  obs TEXT,
  criado_por UUID REFERENCES usuarios(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_pedidos_data ON pedidos (data DESC);
CREATE INDEX IF NOT EXISTS idx_pedidos_status_entrega ON pedidos (status_entrega);
CREATE INDEX IF NOT EXISTS idx_pedidos_status_pag ON pedidos (status_pagamento);

-- Movimentações de estoque
CREATE TABLE IF NOT EXISTS movimentacoes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  data TIMESTAMPTZ NOT NULL DEFAULT now(),
  tipo TEXT NOT NULL,
  ano TEXT,
  qtd INT NOT NULL DEFAULT 0,
  descricao TEXT
);

-- ============================================================
-- RLS: app pequeno, equipe de confiança – políticas abertas na anon key
-- (controle de tela é feito no app por role admin/entregador)
-- ============================================================
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE config ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE estoque ENABLE ROW LEVEL SECURITY;
ALTER TABLE com_clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE pedidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE movimentacoes ENABLE ROW LEVEL SECURITY;

-- Políticas: permitir tudo via anon (app faz o controle de quem vê o quê)
DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY['usuarios','config','clientes','produtos','estoque','com_clientes','pedidos','movimentacoes']
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS "allow_all_%s" ON %I', t, t);
    EXECUTE format('CREATE POLICY "allow_all_%s" ON %I FOR ALL USING (true) WITH CHECK (true)', t, t);
  END LOOP;
END $$;

-- ============================================================
-- USUÁRIO INICIAL (DONO) – troque o PIN depois do primeiro login
-- Nome de login: Dono | PIN: 1234
-- ============================================================
INSERT INTO usuarios (nome, pin, role, ativo)
VALUES ('Dono', '1234', 'admin', true)
ON CONFLICT (nome) DO NOTHING;

-- Produto padrão
INSERT INTO produtos (nome, tipo, preco)
SELECT 'Galão 20L', 'galao', 15
WHERE NOT EXISTS (SELECT 1 FROM produtos WHERE nome = 'Galão 20L');

INSERT INTO produtos (nome, tipo, preco)
SELECT 'Bomba d''água', 'outro', 35
WHERE NOT EXISTS (SELECT 1 FROM produtos WHERE nome = 'Bomba d''água');
