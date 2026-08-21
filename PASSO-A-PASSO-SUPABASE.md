# Passo a passo – Supabase do zero (Sistema Água)

E-mail do dono sugerido: **arisantos0771@gmail.com**  
Login no app (simples): **nome + PIN** (entregador não precisa de e-mail)

---

## 1. Criar conta / projeto na Supabase

1. Acesse: https://supabase.com  
2. **Start your project** / faça login (pode usar o Gmail `arisantos0771@gmail.com`)  
3. **New project**
   - Name: `agua-galoes` (ou o nome que quiser)
   - Database password: **anote em lugar seguro** (não é o PIN do app)
   - Region: escolha a mais perto (ex: South America)  
4. Espere o projeto ficar **Ready**

---

## 2. Rodar o SQL (criar as tabelas)

1. No menu esquerdo: **SQL Editor**  
2. **New query**  
3. Abra o arquivo `supabase-schema.sql` e **cole o conteúdo inteiro**  
4. Clique em **Run**  
5. Deve aparecer sucesso. Isso cria:
   - usuários (dono + entregadores)
   - clientes, pedidos, estoque, etc.
   - usuário inicial: nome **Dono** / PIN **1234**

---

## 3. Pegar URL e chave do projeto

1. Menu: **Project Settings** (engrenagem) → **API**  
2. Copie:
   - **Project URL** → algo como `https://abcdefgh.supabase.co`
   - **anon public** key → texto longo começando com `eyJ...`

---

## 4. Colar no site (HTML)

No arquivo `agua-sistema.html`, no início do `<script>`, procure:

```js
const SUPABASE_URL = '';
const SUPABASE_ANON_KEY = '';
```

Cole assim:

```js
const SUPABASE_URL = 'https://SEU_PROJETO.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOi...sua_chave_anon...';
```

Salve, suba de novo no **GitHub** e a **Vercel** atualiza sozinha (ou faça redeploy).

---

## 5. Testar o login

1. Abra o site na Vercel  
2. Na tela de login:
   - Nome: `Dono`
   - PIN: `1234`  
3. Entre e **troque o PIN depois** (pode editar na tabela `usuarios` no Supabase ou pela tela Funcionários no futuro)

---

## 6. Cadastrar entregador (Matheus) – pelo app

1. Entre como **Dono**  
2. Menu → **Funcionários**  
3. **Novo** → Nome: `Matheus` | PIN: `2580` (exemplo)  
4. Salvar  

No celular do Matheus:
- Abre o mesmo link da Vercel  
- Nome: `Matheus` | PIN: `2580`  
- Ele só vê: Pedido, Entregas, Clientes  

Quando o dono lançar pedidos e o Matheus **atualizar** a página, os pedidos novos aparecem.

---

## 7. (Opcional) Ver dados no Supabase

- Menu **Table Editor** → tabelas `pedidos`, `clientes`, `usuarios`  
- Ali você confere se está gravando online  

---

## 8. Segurança (resumo honesto)

Este setup usa a **chave anon** e políticas abertas, pensado para **equipe pequena e de confiança** (dono + 2–3 entregadores).  
Não publique o link em grupo aberto.  
No futuro dá para apertar com Auth por e-mail só do dono + Edge Functions.

---

## Problemas comuns

| Problema | O que fazer |
|----------|-------------|
| Login não entra | Confirme se rodou o SQL e se URL/key estão corretos |
| “Nome ou PIN incorreto” | Table Editor → `usuarios` → confira nome e pin |
| Dados não aparecem no outro celular | Confirme que `SUPABASE_URL` e key estão no HTML publicado na Vercel |
| Erro de CORS / fetch | URL do projeto errada ou projeto pausado |

---

## Checklist rápido

- [ ] Projeto criado na Supabase  
- [ ] SQL `supabase-schema.sql` executado  
- [ ] URL + anon key colados no HTML  
- [ ] Deploy na Vercel  
- [ ] Login Dono / 1234 ok  
- [ ] Cadastrou entregador com nome + PIN  
- [ ] Testou no celular do entregador  
