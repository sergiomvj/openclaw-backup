---
name: pipeline-fbr
description: "Pipeline comercial completo da FBR. Captação, comercialização e relacionamento para qualquer produto ou negócio. Recebe reports de marketing e entrega ações concretas com análise de mercado."
---

# Pipeline FBR

Pipeline comercial unificado da FBR Inc. Um único processo contínuo que cobre as 4 fases de comercialização de qualquer produto:

```
Pré-requisitos → Captação → Comercialização → Relacionamento
```

Cada fase pode ser executada independentemente ou como parte do fluxo completo.

A captação tem dois tracks independentes:
- **Track B2C** — captação de usuários/clientes finais
- **Track B2B** — captação de parceiros, afiliados e anunciantes

Cada track pode ser executado por um agente diferente.

## Comandos de entrada

O agente identifica a fase pelo comando do usuário:

| Comando | Fase executada |
|---|---|
| "Pré-requisitos para [produto]" | Fase 0 — Pré-requisitos |
| "Definir ICP de [produto]" | Fase 0 — Pré-requisitos |
| "Baseline de [produto]" | Fase 0 — Pré-requisitos |
| "Benchmark de [produto]" | Fase 0 — Pré-requisitos |
| "Analisa a captação de [produto]" | Captação (Track B2C) |
| "Captar leads para [produto]" | Captação (Track B2C) |
| "Estratégia de captação para [produto]" | Captação (Track B2C) |
| "Captar parceiros para [produto]" | Captação (Track B2B) |
| "Parceiros e afiliados de [produto]" | Captação (Track B2B) |
| "Estratégia B2B para [produto]" | Captação (Track B2B) |
| "Comercializa os leads de [produto]" | Comercialização |
| "Estratégia de vendas para [produto]" | Comercialização |
| "Vender os leads de [produto]" | Comercialização |
| "Relacionamento para [produto]" | Relacionamento |
| "Retenção de [produto]" | Relacionamento |
| "Pipeline completo para [produto]" | Todas as fases em sequência |
| "Status do pipeline de [produto]" | Apenas leitura do scenario.md |

Se o comando não for claro, perguntar qual fase o usuário quer executar.

## Arquivos de estado

Dois arquivos vivem no diretório do produto e são a memória do agente:

### scenario.md — Fonte de verdade estratégica

Localizado em `[produto]/scenario.md`. Estado atual do pipeline.

### bigimage.md — Timeline de aprendizado

Localizado em `[produto]/bigimage.md`. Registro cronológico de **todas** as ações executadas e seus resultados. O agente consulta este arquivo no início de cada sessão para entender o histórico completo.

**Estrutura obrigatória do bigimage.md:**
```markdown
# Big Picture: [Produto]

## Timeline de Ações

### [YYYY-MM-DD] — [Título da ação]
- **Fase:** [Fase 0 / Captação B2C / Captação B2B / Comercialização / Relacionamento]
- **Ação:** [o que foi feito]
- **Input:** [o que motivou a ação]
- **Decisão tomada:** [qual caminho foi escolhido e por quê]
- **Resultado:** [o que aconteceu — métricas, feedback, consequências]
- **Aprendizado:** [o que o agente aprendeu com esta ação]
- **Próximo passo definido:** [o que vem a seguir]
- **Status:** [concluído / em andamento / bloqueado / cancelado]

---
```

**Regras do bigimage.md:**
- **Toda ação executada** gera uma entrada na timeline — não importa o tamanho
- **Toda decisão** (mesmo decisões de NÃO fazer algo) deve ser registrada com justificativa
- **Resultados devem incluir dados** quando disponíveis (números, métricas, feedback)
- **Aprendizados são obrigatórios** — é o que diferencia este arquivo de um log genérico
- **O agente lê o bigimage.md antes de qualquer ação** em cada nova sessão
- **Entradas são anexadas**, nunca apagadas — o histórico completo é o ativo mais valioso
- Se uma ação falhou, registrar **por que falhou** e **o que seria diferente**

**Por que existe:** Cada agente é dedicado a uma empresa. O bigimage.md é a memória institucional — permite que o agente aprenda com acertos e erros ao longo do tempo, sem depender de lembrar de sessões anteriores.

### Regras de escrita

Cada fase só escreve em suas seções. Lê tudo, escreve só no seu território.

| Seção | Escreve | Lê |
|---|---|---|
| `perfil` | Fase 0 (cria) / Captação atualiza | Todas |
| `pré-requisitos` | Fase 0 | Todas |
| `benchmark` | Fase 0 | Todas |
| `canais` | Fase 0 | Todas |
| `preview-monetização` | Fase 0 | Todas |
| `estrategia-captacao` | Captação B2C | Todas |
| `nutricao` | Captação B2C | Todas |
| `leads` | Captação B2C (registra/move) / Comercialização (atualiza status) | Todas |
| `parceiros` | Captação B2B | Todas |
| `estrategia-comercializacao` | Comercialização | Todas |
| `relacionamento` | Relacionamento | Todas |

### Template do scenario.md

Ver `assets/scenario-template.md` para a estrutura completa.

## Workflow geral

1. **Identificar o comando** → determinar a fase
2. **Ler bigimage.md** → entender histórico de ações e aprendizados anteriores
3. **Verificar se scenario.md existe** para este produto
   - Se não existe e é Fase 0 → criar scenario.md com o template
   - Se não existe e não é Fase 0 → informar que precisa rodar Fase 0 primeiro
   - Se existe → ler o estado atual
4. **Verificar pré-requisitos** (Fase 0 completa) antes de executar Captação
   - Se ICP ou baseline faltam → avisar que Fase 0 está incompleta e pedir permissão para continuar
5. **Executar a fase** seguindo o workflow específico (ver seções abaixo)
6. **Atualizar o scenario.md** nas seções de responsabilidade daquela fase
7. **Registrar no bigimage.md** — toda ação, decisão e resultado vai pra timeline
8. **Entregar output consolidado** ao usuário

---

## FASE 0: PRÉ-REQUISITOS

**Objetivo:** Garantir que tudo que a captação precisa já está definido antes de qualquer ação.

**Esta fase é obrigatória antes da Captação.** Sem ICP, baseline e benchmark, toda ação posterior é chute.

### Condição de entrada
- Qualquer produto novo ou produto existente sem scenario.md
- OU scenario.md existe mas seções de pré-requisitos estão vazias

### Responsabilidades
```
PRÉ-REQUISITOS
├── ICP e Personas — definir quem é o cliente ideal (obrigatório)
├── Baseline de métricas — coletar dados atuais antes de definir metas (obrigatório)
├── Benchmark competitivo — analisar concorrentes diretos com tabela formal (obrigatório)
├── Naming de módulos — nomear todos os sistemas/módulos do produto (se aplicável)
├── Análise de canais — mapear canais relevantes para o ICP (obrigatório)
└── Preview de monetização — modelos de receita com worst-case scenario
```

### Workflow da Fase 0
1. Coletar informações sobre o produto (report, descrição, conversa)
2. **Definir ICP** — pelo menos 3-4 personas com: nome, perfil, dores, canais preferidos, valor comercial
3. **Coletar baseline de métricas** — tráfego, receita, engagement, base de contatos, posições atuais
   - Se o usuário não tem os dados: listar exatamente quais métricas faltam e como obter
   - Nunca definir metas sem baseline
4. **Benchmark competitivo formal** (web_search obrigatório)
   - Identificar 3-5 concorrentes diretos
   - Gerar tabela comparativa com critérios relevantes
   - Destacar gaps e oportunidades
5. **Naming de módulos** (se produto tem múltiplos sistemas)
   - Nomear cada módulo/sistema com identidade própria
   - Validar com o usuário
6. **Análise de canais obrigatória**
   - Para cada persona, mapear relevância de: WhatsApp, YouTube, Instagram, Facebook, X, LinkedIn, TikTok, Email, SEO
   - Classificar: Primário / Secundário / Terciário / Não relevante
   - Justificar cada classificação
7. **Preview de monetização com worst-case scenario**
   - Listar modelos de monetização viáveis para o produto
   - Estimar receita potencial por modelo (otimista, realista, pessimista)
   - Identificar qual modelo tem melhor ratio esforço/retorno
   - **Worst-case scenario:** se a captação capturar metade do esperado, qual modelo ainda sustenta a operação?
8. Escrever tudo no scenario.md (seções de perfil, pré-requisitos, benchmark, canais)
9. Entregar output consolidado

### Output da Fase 0
```
## Pré-requisitos: [Produto]

### ICP e Personas
| Persona | Perfil | Dores principais | Canais preferidos | Valor comercial |
|---|---|---|---|---|
| [nome] | [descrição] | [dores] | [canais] | $[faixa] |

### Baseline de Métricas
| Métrica | Valor atual | Fonte |
|---|---|---|
| [métrica] | [valor] | [GA/Facebook/etc] |

**Métricas pendentes (sem acesso):** [lista com instruções de como obter]

### Benchmark Competitivo
| Critério | [Produto] | [Concorrente 1] | [Concorrente 2] | [Concorrente 3] |
|---|---|---|---|---|
| Fundação | [ano] | [ano] | [ano] | [ano] |
| Foco | [área] | [área] | [área] | [área] |
| Canais ativos | [lista] | [lista] | [lista] | [lista] |
| Diferencial | [o que] | [o que] | [o que] | [o que] |
| Pontos fracos | [lista] | [lista] | [lista] | [lista] |

**Oportunidades identificadas:** [gaps nos concorrentes que o produto pode explorar]

### Naming de Módulos (se aplicável)
| Módulo | Nome | Descrição |
|---|---|---|
| [conceito] | [nome] | [descrição] |

### Análise de Canais por Persona
| Canal | Persona 1 | Persona 2 | Persona 3 | Justificativa |
|---|---|---|---|---|
| WhatsApp | Primário/Secundário/Terciário/— | ... | ... | [por quê] |
| YouTube | ... | ... | ... | ... |
| Instagram | ... | ... | ... | ... |
| Facebook | ... | ... | ... | ... |
| X (Twitter) | ... | ... | ... | ... |
| LinkedIn | ... | ... | ... | ... |
| TikTok | ... | ... | ... | ... |
| Email | ... | ... | ... | ... |
| SEO/Google | ... | ... | ... | ... |

### Preview de Monetização
| Modelo | Receita (otimista) | Receita (realista) | Receita (pessimista) | Esforço | Quando |
|---|---|---|---|---|---|
| [modelo] | $[valor] | $[valor] | $[valor] | [baixo/médio/alto] | [fase] |

**Worst-case scenario:**
- Se captação capturar 50% do esperado: [qual modelo sustenta? qual não?]
- Modelo recomendado como âncora: [modelo + justificativa]
- Modelos complementares: [lista]

### Próximo passo
Pré-requisitos definidos. Pode executar a Captação (Track B2C e/ou Track B2B).
```

---

## FASE 1: CAPTAÇÃO — TRACK B2C

**Referência:** `references/framework-captacao.md`

### Responsabilidades
```
CAPTAÇÃO
├── Descoberta — levar desconhecidos ao primeiro contato
├── Atenção — fazer parar e olhar
└── Registro — transformar atenção em contato rastreável

NUTRIÇÃO
├── Acompanhar leads frios até ficarem quentes
├── Manter contato contínuo via canais de captação
└── Detectar quando o lead manifesta intenção de compra
```

### Input
- Report completo de marketing com indicações de estratégias
- OU descrição do produto + contexto mínimo

Se insuficiente, perguntar:
1. O que é o produto/serviço? (físico, digital, SaaS, serviço, mídia)
2. Quem é o cliente ideal? (B2B, B2C, nicho, faixa de preço)
3. Qual o estágio? (novo, existente, escalando)
4. Qual o mercado/geografia?
5. Orçamento/resources disponíveis?

### Definição de lead quente
**Lead quente = pelo menos uma interação positiva direta do prospect com um dos canais de captação.**

Exemplos:
- Respondeu email ou mensagem
- Preencheu formulário de contato
- Clicou em CTA e navegou na página de oferta
- Iniciou conversa no chat
- Ligou ou pediu retorno
- Agendou reunião/call
- Comentou ou interagiu diretamente em conteúdo

### Workflow da captação B2C
1. **Verificar Fase 0 completa** — ICP, baseline e benchmark devem existir no scenario.md
2. Extrair e estruturar o report (se fornecido)
3. Classificar o produto pela matriz de referência
4. Pesquisar mercado atual (web_search obrigatório)
5. **Analisar canais do ICP** — usar mapa de canais da Fase 0 para definir ações por canal (WhatsApp, YouTube, Instagram, Facebook, X, LinkedIn, TikTok, Email, SEO)
6. Traduzir estratégias em ações concretas por canal
7. Definir plano de nutrição (frios → quentes)
8. Identificar gaps (abordagens não consideradas pelo report)
9. **Incluir preview de monetização** — baseado no pior cenário, quais modelos de monetização sustentam a captação?
10. Rankear por viabilidade, custo, velocidade, escala
11. Criar/atualizar scenario.md (perfil, captação, nutrição, leads)
12. Entregar output ao usuário

### Output da captação B2C
```
## Captação B2C: [Produto]

### Perfil
- Tipo: [classificação]
- Cliente ideal: [ICP com personas da Fase 0]
- Mercado: [geografia + nicho]
- Estágio: [novo/crescendo/escala]

### Análise do Report
- Estratégias identificadas: [resumo]
- Pontos fortes: [o que faz sentido]
- Pontos fracos/lacunas: [o que falta]

### Análise de Canais por Persona
| Canal | Relevância | Persona principal | Ação recomendada |
|---|---|---|---|
| WhatsApp | Primário/Sec/Terc/— | [persona] | [ação] |
| YouTube | ... | ... | ... |
| Instagram | ... | ... | ... |
| Facebook | ... | ... | ... |
| X (Twitter) | ... | ... | ... |
| LinkedIn | ... | ... | ... |
| TikTok | ... | ... | ... |
| Email | ... | ... | ... |
| SEO/Google | ... | ... | ... |

### Ações Concretas

#### Descoberta
| # | Ação | Canal | Ferramenta | Prazo | Custo |
|---|---|---|---|---|---|
| 1 | [ação] | [canal] | [ferramenta] | [prazo] | $[valor] |

#### Atenção
| # | Ação | Padrão | Exemplo de Hook | Prazo | Custo |
|---|---|---|---|---|---|
| 1 | [ação] | [padrão] | [exemplo] | [prazo] | $[valor] |

#### Registro
| # | Ação | Modelo | Isca/Conversão | Ferramenta | Prazo |
|---|---|---|---|---|---|
| 1 | [ação] | [modelo] | [isca] | [ferramenta] | [prazo] |

### Plano de Nutrição (frios → quentes)
| # | Ação de nutrição | Canal | Frequência | Gatilho de quente |
|---|---|---|---|---|
| 1 | [ação] | [canal] | [frequência] | [gatilho] |

### Preview de Monetização (worst-case)
**Cenário pessimista (50% da captação esperada):**
- Receita estimada por modelo: [valores]
- Modelo âncora que sustenta a operação: [modelo]
- Modelos complementares: [lista]
- Break-even: [quando]

### Possibilidades Não Consideradas
[abordagens do framework que o report não menciona]

### Análise de Mercado Complementar
[concorrentes, tendências, oportunidades]

### Plano de Ação (30 dias)
[semana a semana]

### Métricas
| Fase | Métrica | Baseline (Fase 0) | Meta |
|---|---|---|---|
| Descoberta | Alcance/impressões | [baseline] | [meta] |
| Atenção | CTR / engajamento | [baseline] | [meta] |
| Registro | CPL | [baseline] | [meta] |
| Nutrição | Taxa frios → quentes | [baseline] | [meta] |

### Investimento estimado
[faixa de custo mensal]

### Próximo passo
Quando houver leads quentes no scenario.md, executar a fase de Comercialização.
```

---

## FASE 1B: CAPTAÇÃO — TRACK B2B (Parceiros e Afiliados)

**Este track pode ser executado por um agente diferente do Track B2C.**

### Responsabilidades
```
CAPTAÇÃO B2B
├── Mapeamento — identificar parceiros/afiliados ideais por vertical
├── Abordagem — outreach e negociação com parceiros
├── Onboarding — integrar parceiro na plataforma/programa
└── Ativação — garantir que o parceiro gere valor desde o dia 1
```

### Input
- ICP B2C definido na Fase 0 (quem são os usuários)
- Preview de monetização da Fase 0 (modelos viáveis)
- Report de marketing (se disponível)
- Lista de serviços/produtos que o ICP já consome

### Workflow da captação B2B
1. **Verificar Fase 0 completa** — ICP e preview de monetização devem existir
2. **Mapear serviços que o ICP precisa** — por vertical (ex: remessas, imigração, seguros, educação, e-commerce)
3. **Identificar parceiros potenciais** para cada categoria
   - web_search obrigatório para encontrar players de cada vertical
   - Priorizar parceiros que já servem o mesmo público
4. **Classificar modelos de parceria**
   - **Afiliado (CPA)** — comissão por transação (remessas, e-commerce)
   - **Lead gen (CPL)** — valor por lead qualificado (imigração, imóveis, seguros)
   - **Sponsored content** — patrocínio de conteúdo (empresas querendo alcance)
   - **Revenue share** — divisão de receita (marketplace, serviços)
   - **Listing pago** — assinatura para presença no diretório
5. **Abordar parceiros** — criar script de outreach por tipo de parceiro
6. **Definir estrutura de onboarding** — como o parceiro entra na plataforma
7. **Rankear por velocidade de ativação e valor potencial**
8. **Incluir worst-case scenario** — se 50% dos parceiros não converterem, quais models sustentam?
9. Escrever no scenario.md (seção parceiros)
10. Entregar output ao usuário

### Output da captação B2B
```
## Captação B2B: [Produto] — Parceiros e Afiliados

### Mapa de Serviços por Vertical
| Vertical | Serviços que o ICP precisa | Parceiros potenciais |
|---|---|---|
| [vertical] | [lista] | [empresas] |

### Pipeline de Parceiros
| # | Parceiro | Vertical | Modelo | Valor potencial | Status | Prazo |
|---|---|---|---|---|---|---|
| 1 | [empresa] | [vertical] | CPA/CPL/sponsored/etc | $[faixa/mês] | [mapeado/abordado/negociando/fechado] | [prazo] |

### Scripts de Outreach
#### Modelo: [tipo de parceria]
- **Subject/Hook:** [texto]
- **Proposta:** [texto]
- **CTA:** [texto]

### Estrutura de Onboarding
1. [Passo 1]
2. [Passo 2]
3. [Passo 3]

### Worst-Case Scenario
- Se 50% dos parceiros não ativar: [impacto na receita]
- Modelos mais resilientes: [lista]
- Parceiros-âncora (alta probabilidade): [lista]

### Modelo de Cobrança Recomendado
| Vertical | Modelo | Preço | Justificativa |
|---|---|---|---|
| [vertical] | [CPA/CPL/etc] | $[valor] | [por quê] |

### Plano de Ação (30 dias)
| Semana | Ação | Meta |
|---|---|---|
| 1 | [ação] | [meta] |

### Métricas
| Métrica | Meta |
|---|---|
| Parceiros abordados | [número] |
| Parceiros fechados | [número] |
| Taxa de conversão B2B | [%] |
| Receita estimada (mês 1) | $[valor] |

### Próximo passo
[Ação seguinte baseada no status dos parceiros]
```

---

## FASE 2: COMERCIALIZAÇÃO

**Referência:** `references/framework-comercializacao.md`

### Condição de entrada
- Scenario.md existe
- Tem leads na seção "Quentes"
- Se não: orientar a continuar captação/nutrição

### Input
- Leads quentes do scenario.md (perfil, canal, interação positiva)
- Estratégia de captação que gerou o lead (contexto)
- Report de marketing original (se disponível)

### Responsabilidades
```
COMERCIALIZAÇÃO
├── Qualificação — confirmar que o lead quente é comprador real
├── Educação — construir convicção baseada no interesse manifestado
├── Oferta — formalizar proposta comercial
└── Fechamento — converter "quero" em "comprei"
```

### Workflow da comercialização
1. Ler scenario.md completo
2. Analisar leads quentes (perfil, canal, interação)
3. Classificar produto pela matriz de referência
4. Pesquisar mercado atual (web_search obrigatório)
5. Traçar estratégia de qualificação
6. Traçar estratégia de educação (partindo do interesse manifestado)
7. Traçar estratégia de oferta
8. Traçar estratégia de fechamento
9. Identificar possibilidades não consideradas
10. Rankear por viabilidade, custo, velocidade, impacto
11. Escrever no scenario.md (seção comercialização + status dos leads)
12. Entregar output ao usuário

### Output da comercialização
```
## Comercialização: [Produto]

### Leads Quentes em Pipeline
- Volume: [quantidade]
- Canal de origem: [canal predominante]
- Interação positiva: [tipo(s)]
- Perfil predominante: [ICP]

### Qualificação
| # | Ação | Método | Ferramenta | Prazo | Custo |
|---|---|---|---|---|---|
| 1 | [ação] | [método] | [ferramenta] | [prazo] | $[valor] |

**Critérios de desqualificação:** [lista]

### Educação
| # | Ação | Método | Material | Prazo | Custo |
|---|---|---|---|---|---|
| 1 | [ação] | [método] | [material] | [prazo] | $[valor] |

**Sequência recomendada:**
1. [Toque 1]
2. [Toque 2]
3. [Toque 3]
4. [Toque 4]

### Oferta
| # | Ação | Tipo | Estrutura | Prazo |
|---|---|---|---|---|
| 1 | [ação] | [tipo] | [detalhes] | [prazo] |

**Elementos:** O que / Quanto / Risco / Urgência

### Fechamento
| # | Ação | Método | Ferramenta | Prazo | Custo |
|---|---|---|---|---|---|
| 1 | [ação] | [método] | [ferramenta] | [prazo] | $[valor] |

**Objeções prováveis:**
| Objeção | Resposta |
|---|---|
| [objeção] | [resposta] |

### Possibilidades Não Consideradas
[abordagens alternativas por sub-fase]

### Análise de Mercado Complementar
[concorrentes, tendências, oportunidades]

### Plano de Ação (30 dias)
[semana a semana]

### Métricas
| Fase | Métrica | Meta |
|---|---|---|
| Qualificação | Taxa de qualificação | [%] |
| Educação | Engajamento | [%] |
| Oferta | Proposta aceita | [%] |
| Fechamento | Conversão final | [%] |
| Geral | CAC | $[valor] |
| Geral | Tempo médio fechamento | [dias] |

### Investimento Estimado
[faixa de custo mensal]

### Próximo passo
Após fechamento, executar a fase de Relacionamento.
```

---

## FASE 3: RELACIONAMENTO

**Referência:** `references/framework-relacionamento.md`

### Condição de entrada
- Scenario.md existe
- Tem leads com status "fechado" (convertidos em clientes)
- Se não: orientar a continuar comercialização

### Input
- Clientes fechados do scenario.md
- Estratégia de comercialização que converteu (contexto)
- Dados do produto (perfil do scenario.md)
- Report de marketing original (se disponível)

### Responsabilidades
```
RELACIONAMENTO
├── Entrega e satisfação — experiência pós-compra
│   ├── Momento 1: primeira impressão (0-7 dias)
│   └── Momento 2: confirmação (7-30 dias)
├── Fidelização — criar razão para continuar
│   ├── Hábito — produto vira rotina
│   ├── Valor crescente — quanto mais usa, mais vale
│   └── Comunidade — pertencimento
└── Advocacia — transformar cliente em vendedor
    ├── Incentivada — programa de referral
    ├── Orgânica — recomendação espontânea
    └── Estratégica — parceiro de negócio / co-marketing
```

### Definição de cliente ativo
**Cliente ativo = quem comprou e teve a experiência de entrega completada (TTV atingido).**

### Workflow do relacionamento
1. Ler scenario.md completo
2. Identificar clientes com status "fechado"
3. Classificar produto pela matriz de referência
4. Pesquisar mercado atual — estratégias de retenção do setor (web_search obrigatório)
5. **Traçar estratégia de entrega** — como garantir que o cliente perceba valor no menor tempo possível (TTV)
6. **Traçar estratégia de fidelização** — qual mecanismo faz mais sentido (hábito, valor crescente, comunidade)
7. **Traçar estratégia de advocacy** — como transformar clientes satisfeitos em promotores
8. Identificar possibilidades não consideradas
9. Rankear por viabilidade, custo, velocidade, impacto
10. Escrever no scenario.md (seção relacionamento + status dos clientes)
11. Entregar output consolidado ao usuário

### Output do relacionamento
```
## Relacionamento: [Produto]

### Clientes Ativos
- Volume: [número]
- Ticket médio: [faixa]
- TTV atual: [estimativa]

### Entrega e Satisfação
| # | Ação | Modelo | Ferramenta | Prazo | Custo |
|---|---|---|---|---|---|
| 1 | [ação concreta de entrega] | [self/acomp/premium] | [ferramenta] | [prazo] | $[valor] |

**Momento 1 — Primeira impressão (0-7 dias):**
- [Ação concreta para garantir boa primeira experiência]

**Momento 2 — Confirmação (7-30 dias):**
- [Ação concreta para re-engajar e confirmar valor]

**TTV alvo:** [tempo] — como reduzir

### Fidelização
| # | Ação | Mecanismo | Ferramenta | Prazo | Custo |
|---|---|---|---|---|---|
| 1 | [ação concreta de retenção] | [hábito/valor/comunidade] | [ferramenta] | [prazo] | $[valor] |

**Mecanismo primário:** [hábito/valor crescente/comunidade] — [justificativa]
**Mecanismo secundário:** [mecanismo] — [justificativa]

### Advocacia
| # | Ação | Tipo | Mecanismo | Prazo | Custo |
|---|---|---|---|---|---|
| 1 | [ação concreta de advocacy] | [incentivada/orgânica/estratégica] | [detalhes] | [prazo] | $[valor] |

**Programa de referral (incentivada):**
- [Estrutura do programa — recompensa, regras, comunicação]

**Ações para advocacy orgânica:**
- [Surpresa e delícia, atendimento excepcional, etc.]

**Parcerias estratégicas:**
- [Co-marketing, case studies, co-criação de conteúdo]

### Possibilidades Não Consideradas
#### Entrega
- [Abordagem alternativa] — Por que faz sentido: [justificativa]
#### Fidelização
- [Abordagem alternativa] — Por que faz sentido: [justificativa]
#### Advocacia
- [Abordagem alternativa] — Por que faz sentido: [justificativa]

### Análise de Mercado Complementar
[estratégias de retenção dos concorrentes, tendências do setor]

### Plano de Ação (30 dias)
[semana a semana com ações concretas]

### Métricas
| Fase | Métrica | Meta |
|---|---|---|
| Entrega | TTV (Time to Value) | [tempo] |
| Entrega | Taxa de onboarding completo | [%] |
| Fidelização | Churn mensal | [%] |
| Fidelização | LTV (Lifetime Value) | $[valor] |
| Fidelização | NPS | [valor] |
| Advocacia | Taxa de referral | [%] |
| Advocacia | Receita por indicação | $[valor] |

### Investimento Estimado
[faixa de custo mensal]
```

---

## Diretriz de Presença Digital FBR

**TODAS as empresas do grupo FBR Inc devem ser motivadas a ter:**

| Presença | Obrigatório | Detalhe |
|---|---|---|
| **Canal YouTube** | ✅ | Vídeos longos + Shorts. SEO perene, autoridade, descoberta. |
| **TikTok** | ✅ | Vídeos curtos virais. Alcance orgânico massivo. |
| **Facebook Page** | ✅ | Posts, carrosséis, vídeos nativos, grupos. |
| **Instagram** | ✅ | Reels, Stories, Posts, Carrosséis. Descoberta + relacionamento. |
| **WhatsApp Business** | ✅ | Canal direto de vendas e suporte. |
| **Google Business Profile** | ✅ | SEO local, reviews, credibilidade. |
| **Pinterest** | Recomendado | Tráfego SEO passivo para produtos visuais. |
| **LinkedIn** | Condicional | Se B2B ou SaaS. |
| **X (Twitter)** | Condicional | Se mídia/notícias. |

**Princípio:** Vídeo é o canal #1 de crescimento orgânico. Imagem é para portfólio e educação visual. Texto é para autoridade e SEO. Os três formatos devem estar presentes em todas as estratégias.

### Conteúdo separado e quantificado

Em TODAS as análises, separar e quantificar claramente:
- **Posts** (imagem estática) — Facebook e Instagram
- **Carrosséis** (3–7 slides) — Facebook e Instagram
- **Vídeos curtos** (Reels, Shorts, TikTok, 15–60s) — Instagram, YouTube, TikTok, Facebook
- **Vídeos longos** (5–15 min) — YouTube
- **Stories** (5–15s) — Instagram

Cada tipo deve ter meta semanal clara por canal.

### Vídeo como pilar central

- **YouTube longo:** Autoridade, SEO, conteúdo perene. Mínimo 2–4 vídeos/mês por empresa.
- **YouTube Shorts:** Descoberta, alcance. Mínimo 4–6 Shorts/mês.
- **Instagram Reels:** Descoberta, engajamento. Mínimo 4/semana.
- **TikTok:** Viralização, descoberta. Mínimo 4–5/semana.
- **Instagram Stories:** Relacionamento, conversão. Mínimo 7–10/semana.
- **Facebook Vídeo:** Alcance orgânico. Mínimo 2/semana.

**Regra de cross-posting:** Cada gravação deve render 4+ publicações em canais diferentes. Gravar 1x, publicar 4x.

### Orgânico primeiro, pago como acelerador

**Prioridade em todas as análises:**
1. Estratégias orgânicas (zero custo) — SEMPRE primeiro
2. Estratégias de baixo custo (<$50/mês) — complemento
3. Tráfego pago — apenas para acelerar canais validados, de forma pontual e assertiva

**Tráfego pago deve ser:**
- Investimento pontual (campanhas de teste, sazonalidade, validação)
- Assertivo (público validado, criativo testado, métrica clara)
- Nunca substituto de presença orgânica
- Sempre precedido de pelo menos 2 semanas de conteúdo orgânico ativo

### Scraping e identificação de prospects

**Em TODAS as análises de captação, incluir:**
- Identificação de grupos de Facebook e WhatsApp relevantes ao ICP
- Estratégia de scraping manual de prospects nesses grupos
- Monitoramento de keywords e sinais de intenção de compra
- Planilha de tracking de prospects identificados
- Scripts de abordagem após nutrição no grupo
- Metas semanais de prospects identificados e DMs enviadas

O scraping é a fonte #1 de leads orgânicos B2B. Deve estar presente em toda análise de captação.

### Atração sutil e inteligente

O conteúdo de todas as empresas FBR deve atrair prospects de forma sutil e inteligente — não venda direta. Princípios:
- **Educacional:** Ensinar algo útil que demonstre expertise
- **Entretenimento:** Humor, bastidores, storytelling
- **Prova social:** Before/after, depoimentos, cases
- **Identificação:** Falar das dores do público-alvo
- **Nunca:** Postar "compre nosso produto" sem contexto

---

## Regras gerais

- **bigimage.md é sagrado.** Ler no início de cada sessão. Registrar toda ação, decisão e resultado.
- **Fase 0 é obrigatória.** Nunca executar Captação sem ICP definido e baseline coletado.
- **O report é a base, não o limite.** Sempre expandir com o que falta.
- **web_search obrigatório** em todas as fases — analisar mercado real.
- **Análise de canais é obrigatória** — sempre mapear WhatsApp, YouTube, Instagram, Facebook, X, LinkedIn, TikTok para cada persona.
- **Presença digital é obrigatória** — toda empresa FBR deve ter YouTube, TikTok, Facebook, Instagram, WhatsApp. Incluir setup na Fase 0.
- **Vídeo em todas as fases** — captação, comercialização e relacionamento devem incluir ações de vídeo.
- **Conteúdo quantificado e separado** — sempre separar Posts, Carrosséis, Vídeos (Reels/Shorts/TikTok), Stories com metas semanais.
- **Scraping em todas as captações** — sempre incluir identificação de prospects em grupos FB e WA.
- **Orgânico primeiro** — sempre priorizar estratégias gratuitas antes de sugerir investimento pago.
- **Benchmark competitivo formal** — sempre gerar tabela comparativa com 3-5 concorrentes.
- **Preview de monetização com worst-case** — sempre incluir cenário pessimista na captação.
- **scenario.md é a fonte de verdade estratégica.** Sempre ler antes, sempre atualizar depois.
- **Nunca pular fases.** Pré-requisitos → Captação → Comercialização → Relacionamento.
- **Sempre rankear por viabilidade prática.** Não recomendar o que não dá pra executar.
- **Incluir pelo menos 1 abordagem de baixo custo** em cada sub-fase.
- **Métricas sempre incluem baseline.** Nunca definir meta sem saber onde está.
- Se produto da FBR Inc, considerar ativos de mídia como vantagem competitiva.
- Responder em português brasileiro.

## Publicação de Relatórios

Ao final de cada fase, o agente DEVE gerar um relatório HTML e publicá-lo para compartilhamento com stakeholders.

### Regras do relatório

1. **Todo relatório é HTML** — dark theme profissional, tipografia moderna (Inter, JetBrains Mono), animações suaves
2. **Cada seção DEVE ter um parágrafo explicativo** — o stakeholder que recebe o link não é técnico. Explicar o que é, por que importa, o que significa para o negócio.
3. **Usar menu fixo no topo** — navegação sticky para o usuário pular entre seções rapidamente
4. **Seções compactas acima do fold** — hero section com métricas-chave + scroll indicator para mostrar que há mais conteúdo
5. **Design responsivo** — funcionar em desktop e mobile
6. **Self-contained** — único arquivo HTML, sem dependências externas exceto Google Fonts CDN

### Fluxo de publicação

```
1. Gerar HTML do relatório
2. curl -X POST https://upload.pipeline.fbr.news/upload \
   -H "Authorization: Bearer [TOKEN]" \
   -H "X-Filename: [produto]-[fase].html" \
   --data-binary @relatorio.html
3. Retornar URL: https://pipeline.fbr.news/[produto]-[fase].html
```

### Parâmetros do upload (por ambiente)

| Parâmetro | Valor |
|---|---|
| Endpoint | `https://upload.pipeline.fbr.news/upload` |
| Método | `POST` |
| Auth | `Authorization: Bearer [token]` |
| Filename | `X-Filename: arquivo.html` |
| Body | Binário do HTML |
| Resposta | `{ "success": true, "url": "https://pipeline.fbr.news/arquivo.html" }` |

**O token está em** `/data/upload-service/token.txt` no servidor.

### Estrutura obrigatória do relatório

```
- Hero section (título + métricas-chave)
- Pipeline visual (fases)
- ICP & Personas (cards)
- Mercado (números)
- Benchmark competitivo (tabela)
- Canais por persona (tabela)
- Monetização (cards + worst-case)
- Base semente (contadores)
- Plano de ação (timeline)
- Dados do report original (se aplicável)
- Footer
```
