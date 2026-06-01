---
name: sales-leads
description: "Recebe leads quentes do capta-leads e traça estratégia de comercialização com ações concretas e possibilidades não consideradas."
---

# Sales Leads

Segunda skill do pipeline comercial. Lê o **scenario.md** gerado pelo capta-leads, identifica os leads quentes, e traça a **estratégia de comercialização**: qualificação → educação → oferta → fechamento.

## Posição no pipeline

```
capta-leads                        sales-leads                        (próxima)
    │                                   │                              relacionamento
    ├── Captação                        ├── Qualificação
    ├── Nutrição (frios → quentes)      ├── Educação
    │                                   ├── Oferta
    │   scenario.md                     └── Fechamento
    │   (fonte de verdade)                       │
    └─────────────── compartilhado ──────────────┘
```

## Arquivo de estado: scenario.md

Todas as skills do pipeline compartilham o mesmo `scenario.md`.

**Responsabilidades do sales-leads no scenario.md:**
- **Lê** as seções: `perfil`, `estratégia-captacao`, `leads` (seção quentes), `nutricao`
- **Escreve** na seção: `estrategia-comercializacao`
- **Atualiza** o status dos leads na seção `leads` (ex: "em qualificação", "proposta enviada", "fechado")
- **Nunca escreve** nas seções de captação ou nutrição

### Quando sales-leads entra em ação

Sales-leads é invocada quando:
1. O scenario.md tem **leads na seção "Quentes"**
2. O usuário pede explicitamente estratégia de comercialização
3. O agente detecta leads quentes que ainda não têm estratégia de comercialização

### Quando sales-leads NÃO deve agir

- Não há leads quentes no scenario.md → orientar a continuar capta-leads
- O usuário pede estratégia de captação → encaminhar para capta-leads

## Input esperado

O input são **leads quentes** registrados no scenario.md, contendo:
- Perfil do lead (dados de contato, empresa, segmento)
- Canal de origem (por onde veio)
- Interação positiva registrada (o que fez, quando, em qual canal)
- Contexto da manifestação de interesse
- Dados do produto/serviço (seção perfil do scenario.md)
- Estratégia de captação que gerou o lead (seção estratégia-captacao do scenario.md)

Se o scenario.md não existir ou não tiver leads quentes:
- Informar o usuário que é necessário executar capta-leads primeiro
- Não inventar dados

## Workflow

1. **Ler o scenario.md** do produto
   - Se não existe: informar que capta-leads precisa rodar primeiro
   - Se existe sem leads quentes: informar e sugerir continuar nutrição
2. **Analisar os leads quentes** — perfil, canal de origem, tipo de interação positiva
3. **Classificar o produto** usando a matriz de referência (ver `references/framework-comercializacao.md`)
4. **Pesquisar mercado atual** — buscar táticas de vendas do setor, concorrentes, tendências (usar web_search)
5. **Traçar estratégia de qualificação** — como confirmar que o lead é comprador real
6. **Traçar estratégia de educação** — como construir convicção baseado no que o lead já demonstrou interesse
7. **Traçar estratégia de oferta** — como formalizar a proposta considerando ticket médio e ciclo de vendas
8. **Traçar estratégia de fechamento** — como remover obstáculos finais considerando tipo de decisão
9. **Identificar possibilidades não consideradas** — abordagens alternativas que podem aumentar conversão
10. **Rankear tudo** — pontuar por: viabilidade, custo, velocidade, impacto
11. **Escrever no scenario.md** — preencher a seção `estrategia-comercializacao` e atualizar status dos leads
12. **Gerar output consolidado** para o usuário

## O que sales-leads escreve no scenario.md

```markdown
## Estratégia de Comercialização
**Gerado em:** [data]
**Leads quentes na data:** [número]

### Qualificação
- Método: [autoprovação/comportamental/humana]
- Ações: [lista de ações concretas]
- Critérios de desqualificação: [lista]

### Educação
- Método: [sequência/sob demanda/conversa]
- Sequência de toques: [lista]
- Materiais necessários: [lista]

### Oferta
- Tipo: [direta/condicionada/proposta]
- Estrutura: [detalhes]
- Urgência/gatilho: [detalhes]

### Fechamento
- Método: [automático/semi-automático/humano]
- Ações: [lista]
- Objeções prováveis e respostas: [tabela]

### Métricas
| Fase | Métrica | Meta |
|---|---|---|
| ... | ... | ... |
```

## Output para o usuário

Além de atualizar o scenario.md, entregar ao usuário:

```
## Estratégia de Comercialização: [Nome do Produto/Empresa]

### Leads Quentes em Pipeline
- Volume: [quantidade]
- Canal de origem predominante: [canal]
- Interação positiva registrada: [tipo(s)]
- Perfil predominante: [resumo ICP]

### Qualificação
| # | Ação | Método | Ferramenta | Prazo | Custo |
|---|---|---|---|---|---|
| 1 | [ação concreta] | [método] | [ferramenta] | [prazo] | $[valor] |

**Critérios de desqualificação:**
- [Sem budget / sem autoridade / sem necessidade / timing]

### Educação
| # | Ação | Método | Material | Prazo | Custo |
|---|---|---|---|---|---|
| 1 | [ação concreta] | [método] | [material] | [prazo] | $[valor] |

**Sequência recomendada:**
1. [Toque 1]
2. [Toque 2]
3. [Toque 3]
4. [Toque 4]

### Oferta
| # | Ação | Tipo | Estrutura | Prazo |
|---|---|---|---|---|
| 1 | [ação concreta] | [tipo] | [detalhes] | [prazo] |

**Elementos da oferta:**
- O que: [produto + bônus]
- Quanto: [preço + condições]
- Risco: [garantia/trial]
- Urgência: [gatilho]

### Fechamento
| # | Ação | Método | Ferramenta | Prazo | Custo |
|---|---|---|---|---|---|
| 1 | [ação concreta] | [método] | [ferramenta] | [prazo] | $[valor] |

**Objeções prováveis:**
| Objeção | Resposta |
|---|---|
| [objeção 1] | [resposta] |

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
Após fechamento, invocar a skill de **relacionamento** (a ser criada) para maximização do LTV.
```

## Regras

- **O scenario.md é a fonte de verdade.** Tudo que sales-leads precisa está lá.
- Se scenario.md não existe → **não prosseguir**, orientar a rodar capta-leads primeiro.
- Se não há leads quentes → **não prosseguir**, orientar a continuar nutrição.
- **Considerar o contexto da interação positiva** — a educação parte do que o lead já demonstrou.
- Sempre pesquisar mercado real antes de recomendar (web_search obrigatório)
- Rankear por **viabilidade prática**
- Adaptar ao ticket médio e ciclo de vendas
- **Sempre escrever no scenario.md** — a seção de comercialização e o status dos leads
- **Nunca escrever** nas seções de captação ou nutrição
- Se o produto for da FBR Inc, considerar os ativos de mídia como vantagem competitiva
- Responder em português brasileiro
