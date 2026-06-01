# OpenClaw Learn — Método de Aprendizado Contínuo para Agentes

**Data:** 1 de junho de 2026  
**Autor:** David + Sergio  
**Status:** Método validado  
**Princípio:** Tudo que fizermos precisa virar um método replicável e registrado.

---

## 1. Visão Geral

O OpenClaw não aprende sozinho por padrão — ele **acorda do zero a cada sessão**. O aprendizado precisa ser construído intencionalmente com 4 camadas complementares:

| Camada | Tipo de Memória | Mecanismo | Persistência |
|--------|----------------|-----------|-------------|
| **Memória de Fatos** | Contexto, preferências, decisões | `MEMORY.md` + `memory/*.md` + `memory_search` | Arquivos Markdown indexados (SQLite + embeddings) |
| **Memória Procedimental** | Workflows, processos, correções | Skills (`SKILL.md`) | Arquivos em `workspace/skills/` |
| **Recall Automático** | Injeção de contexto antes da resposta | Active Memory (plugin) | Sub-agente blocker que consulta memória |
| **Captura Automática** | Detectar aprendizados em tempo real | Skill Workshop (plugin) | Propostas de skill criadas automaticamente |

**O circuito:**
```
Trabalho → Correções/Insights → Captura → Registro → Recall na próxima sessão
```

---

## 2. Camada 1 — Memória de Fatos (Base)

### O que é
Registros de contexto, decisões, preferências, eventos. A "memória de longo prazo" do agente.

### Como funciona
- **Arquivos:** `MEMORY.md` (curado) + `memory/YYYY-MM-DD.md` (diários)
- **Indexação:** SQLite com FTS5 (keyword/BM25) + embeddings (vetorial)
- **Busca:** `memory_search` (hibrida) + `memory_get` (leitura direta)
- **Index location:** `~/.openclaw/memory/<agentId>.sqlite`

### Providers de Embedding Suportados

| Provider | ID | Precisa API Key | Notas |
|----------|-----|----------------|-------|
| OpenAI | `openai` | Sim | Padrão. Modelo: `text-embedding-3-small` |
| Gemini | `gemini` | Sim | Suporta multimodal (imagem + áudio) |
| Ollama | `ollama` | Não | Local/self-hosted |
| Local | `local` | Não | GGUF, ~0.6 GB download |
| DeepInfra | `deepinfra` | Sim | Default: `BAAI/bge-m3` |
| Bedrock | `bedrock` | Não | AWS credential chain |
| Mistral | `mistral` | Sim | |
| Voyage | `voyage` | Sim | |
| OpenAI-compatível | `openai-compatible` | Geralmente | Genérico `/v1/embeddings` |
| GitHub Copilot | `github-copilot` | Não | Subscription Copilot |

### Configuração mínima (OpenAI, que já funciona com `OPENAI_API_KEY`):
```json5
{
  agents: {
    defaults: {
      memorySearch: {
        provider: "openai",  // já é o padrão se OPENAI_API_KEY existe
      },
    },
  },
}
```

### Melhorias opcionais
- **Temporal decay:** notas antigas perdem peso. Útil com meses de diários.
- **MMR (diversidade):** reduz resultados duplicados.
- **Session memory:** indexar transcrições de sessões para recall de conversas antigas.

```json5
{
  agents: {
    defaults: {
      memorySearch: {
        provider: "openai",
        query: {
          hybrid: {
            mmr: { enabled: true },
            temporalDecay: { enabled: true },
          },
        },
        experimental: {
          sessionMemory: true,  // indexa transcrições de sessões
        },
      },
    },
  },
}
```

### Comandos de manutenção
```bash
openclaw memory status              # status do índice
openclaw memory status --deep       # detalhes do provider + vector store
openclaw memory index --force       # reconstruir índice
```

### Práticas
- Agente registra eventos em `memory/YYYY-MM-DD.md` durante o trabalho
- Periodicamente (heartbeat ou cron), consolida diários em `MEMORY.md`
- `MEMORY.md` é memória curada — o essencial, não logs brutos
- NUNCA carregar `MEMORY.md` em sessões compartilhadas (segurança)

---

## 3. Camada 2 — Memória Procedimental (Skills)

### O que é
Workflows reutilizáveis que o agente segue em tarefas futuras. "Como fazer X."

### Como funciona
- Cada skill é uma pasta com `SKILL.md` (YAML frontmatter + instruções)
- Carregadas automaticamente pelo OpenClaw no prompt do agente
- Precedência: workspace > project-agent > personal-agent > managed > bundled > extra dirs

### Estrutura de uma skill
```
workspace/skills/<nome-da-skill>/
├── SKILL.md              # Obrigatório. Frontmatter + instruções
├── references/           # Opcional. Frameworks, docs de apoio
├── templates/            # Opcional. Templates usados pelo processo
├── scripts/              # Opcional. Scripts auxiliares
└── assets/               # Opcional. Recursos estáticos
```

### Exemplo mínimo de SKILL.md
```markdown
---
name: exemplo-workflow
description: Descrição de quando e como usar esta skill.
---

# Título do Workflow

## Quando usar
- Situação A
- Situação B

## Workflow
1. Passo 1
2. Passo 2
3. Passo 3

## Regras
- Sempre verificar X
- Nunca fazer Y
```

### Gating (carregamento condicional)
```markdown
---
name: skill-com-api
description: Skill que precisa de API externa.
metadata: {"openclaw": {"requires": {"bins": ["curl"], "env": ["MINHA_API_KEY"]}}}
---
```

### Comandos
```bash
openclaw skills list                  # listar skills carregadas
openclaw skills install <slug>        # instalar do ClawHub
openclaw skills install git:owner/repo@ref  # instalar do Git
openclaw skills update --all          # atualizar todas
```

---

## 4. Camada 3 — Active Memory (Recall Automático)

### O que é
Plugin que roda um sub-agente **antes** de cada resposta, buscando memória relevante e injetando como contexto oculto. O agente "lembra" sem precisar ser perguntado.

### Quando usar
- Sessões persistentes com o usuário (chat direto)
- Quando continuidade e personalização importam
- Quando o agente tem memória significativa acumulada

### Quando NÃO usar
- Automação / workers internos
- One-shot API tasks
- Onde personalização oculta seria surpreendente

### Configuração recomendada
```json5
{
  plugins: {
    entries: {
      "active-memory": {
        enabled: true,
        config: {
          agents: ["main"],                    // quais agentes usam
          allowedChatTypes: ["direct"],         // só chat direto (não grupos)
          queryMode: "recent",                  // quanto contexto enviar
          promptStyle: "balanced",              // quão eager na recall
          timeoutMs: 15000,                     // timeout em ms
          maxSummaryChars: 220,                 // max chars do resumo injetado
          persistTranscripts: false,            // transcripts temporários
          logging: true,                        // logs pra debug
        },
      },
    },
  },
}
```

### Query Modes

| Modo | Contexto enviado | Latência recomendada | Use quando |
|------|-----------------|---------------------|-----------|
| `message` | Só a última mensagem do usuário | 3-5s | Velocidade máxima, preferências estáveis |
| `recent` | Última mensagem + cauda da conversa | 15s | **Padrão.** Bom equilíbrio |
| `full` | Conversa completa | 15s+ | Qualidade máxima de recall |

### Prompt Styles

| Estilo | Comportamento |
|--------|--------------|
| `strict` | Menos eager. Só matches óbvios |
| `balanced` | **Padrão para `recent`.** Equilibrado |
| `contextual` | Mais peso no histórico da conversa |
| `recall-heavy` | Mais disposto a surfacing memory |
| `precision-heavy` | Agressivamente prefere NONE |
| `preference-only` | Otimizado para preferências e hábitos |

### Modelos rápidos recomendados
- `cerebras/gpt-oss-120b` — baixíssima latência
- `google/gemini-3-flash` — bom fallback sem mudar modelo principal
- Herdar modelo da sessão (deixar `config.model` vazio) — mais simples

### Debug ao vivo
```
/verbose on     → mostra status line "Active Memory: status=ok elapsed=Xms"
/trace on       → mostra debug summary com o que foi recuperado
```

### Cold-start grace (pós-restart)
```json5
{
  config: {
    timeoutMs: 15000,
    setupGraceTimeoutMs: 30000,  // budget extra no primeiro recall após restart
  },
}
```

---

## 5. Camada 4 — Skill Workshop (Captura Automática)

### O que é
Plugin que detecta correções e procedimentos reutilizáveis durante o trabalho e transforma em skills automaticamente.

### O que captura (bom)
- "Next time, faça X"
- "From now on, prefira Y"
- "Sempre verifique Z"
- Workflows complexos que deram certo
- Correções do usuário

### O que NÃO captura (ruim)
- Fatos ("o usuário gosta de azul")
- Transcrições brutas
- Segredos/credenciais
- Instruções one-off que não vão se repetir

### Configuração recomendada (modo pending — seguro)
```json5
{
  plugins: {
    entries: {
      "skill-workshop": {
        enabled: true,
        config: {
          autoCapture: true,          // capturar automaticamente
          approvalPolicy: "pending",  // requer aprovação antes de escrever
          reviewMode: "hybrid",       // heurística + LLM reviewer
          reviewInterval: 15,         // revisar a cada 15 turns
          reviewMinToolCalls: 8,      // revisar a cada 8 tool calls
          maxPending: 50,             // max propostas pendentes
        },
      },
    },
  },
}
```

### Configuração trusted (auto — ambientes controlados)
```json5
{
  config: {
    autoCapture: true,
    approvalPolicy: "auto",   // escreve automaticamente (com scanner de segurança)
    reviewMode: "hybrid",
  },
}
```

### Três caminhos de captura

1. **Explícito:** Agente chama `skill_workshop` tool diretamente
2. **Heurística:** Detecta frases como "next time", "from now on", "sempre verifique"
3. **LLM Reviewer:** Sub-agente compacto analisa transcrição recente e propõe skills

### Ciclo de vida das propostas

```
Capturada → pending → approved → applied (escrita em workspace/skills/)
                  → rejected (descartada)
                  → quarantined (bloqueada por scanner de segurança)
```

### Ferramentas disponíveis
```
skill_workshop status          → contagem por estado
skill_workshop list_pending    → listar pendentes
skill_workshop list_quarantine → listar quarentena
skill_workshop inspect <id>    → inspecionar proposta
skill_workshop suggest {...}   → criar proposta
skill_workshop apply <id>      → aprovar e aplicar
skill_workshop reject <id>     → rejeitar
```

### Segurança
Propostas com achados críticos são **quarentenadas automaticamente**:
- Prompt injection
- Exfiltração de secrets
- Pipe to shell (curl | bash)
- Bypass de ferramentas

---

## 6. Fluxo de Reflexão Diária (Cron)

### O que é
Job automatizado que roda diariamente para consolidar aprendizados.

### Configuração
```json5
{
  name: "daily-reflection",
  schedule: {
    kind: "cron",
    expr: "0 23 * * *",       // 23:00 UTC todo dia
    tz: "America/New_York",   // ajustar para timezone do Sergio
  },
  sessionTarget: "isolated",
  payload: {
    kind: "agentTurn",
    message: "Reflexão diária. Leia os arquivos memory/ dos últimos 3 dias. Identifique: (1) decisões importantes, (2) lições aprendidas, (3) padrões emergentes, (4) skills que precisam de atualização. Atualize MEMORY.md com informações consolidadas. Se encontrar procedimentos novos ou correções, proponha updates nas skills relevantes. Se nada de relevante, não escreva.",
    timeoutSeconds: 120,
  },
  delivery: { mode: "none" },  // silencioso, a menos que tenha algo importante
}
```

---

## 7. Arquitetura Completa

```
┌──────────────────────────────────────────────────┐
│              SESSÃO DE TRABALHO                   │
│                                                  │
│  Sergio ↔ Agente                                 │
│    ├── Active Memory (recall automático)          │
│    ├── Skills carregadas (procedimentos)          │
│    ├── MEMORY.md (contexto de longo prazo)        │
│    └── memory/*.md (diários recentes)             │
│                                                  │
│  Durante o trabalho:                              │
│    ├── Correções → Skill Workshop captura          │
│    ├── Insights → Escritos em memory/YYYY-MM-DD   │
│    └── Procedimentos novos → Propostas de skill    │
└────────────────────────┬─────────────────────────┘
                         │
                ┌────────▼────────┐
                │  CRON DIÁRIO    │
                │  (sub-agente)   │
                │                 │
                │  1. Lê diários  │
                │  2. Consolida   │
                │  3. Atualiza    │
                │     MEMORY.md   │
                │  4. Propõe      │
                │     skill updates│
                └─────────────────┘
                         │
                ┌────────▼────────┐
                │  PRÓXIMA SESSÃO │
                │                 │
                │  Active Memory  │──→ Contexto relevante injetado
                │  Skillsupdated  │──→ Procedimentos disponíveis
                │  MEMORY.md      │──→ Memória de longo prazo atualizada
                └─────────────────┘
```

---

## 8. Checklist de Implementação

- [ ] **Memória base:** Confirmar que `memory_search` funciona (`openclaw memory status`)
- [ ] **Embedding provider:** Configurar provider (OpenAI padrão ou local/Ollama)
- [ ] **Active Memory:** Habilitar plugin com config recomendada
- [ ] **Skill Workshop:** Habilitar plugin em modo `pending`
- [ ] **Cron diário:** Criar job de reflexão noturna
- [ ] **Temporal decay:** Habilitar se houver meses de diários acumulados
- [ ] **Session memory:** Habilitar `experimental.sessionMemory` se recall de conversas for necessário
- [ ] **Validação:** Testar com `/verbose on` + `/trace on` e verificar recall

---

## 9. Troubleshooting Rápido

| Problema | Verificar |
|----------|-----------|
| Memory search sem resultados | `openclaw memory index --force` |
| Só keyword matches | Provider de embedding não configurado: `openclaw memory status --deep` |
| Active Memory não aparece | Plugin habilitado? Agente na lista? Sessão interativa? |
| Skill Workshop não captura | `autoCapture: true`? `reviewMode` não é `off`? |
| Proposta em quarentena | `skill_workshop list_quarantine` para ver motivo |
| Primeiro recall após restart dá timeout | Configurar `setupGraceTimeoutMs: 30000` |
| Skills não carregam | `openclaw skills list` + verificar gating (bins, env, config) |

---

## 10. Referências

- **Docs locais:** `/usr/local/lib/node_modules/openclaw/docs/`
- **Memory:** `concepts/memory-builtin.md`, `concepts/memory-search.md`, `concepts/active-memory.md`
- **Skills:** `tools/skills.md`, `tools/creating-skills.md`
- **Skill Workshop:** `plugins/skill-workshop.md`
- **Active Memory:** `concepts/active-memory.md`
- **ClawHub (skills públicas):** https://clawhub.ai
- **Docs online:** https://docs.openclaw.ai

---

*Método criado em 1 de junho de 2026. Documentado como parte do princípio FBR: tudo que fizermos precisa virar um método replicável e registrado.*
