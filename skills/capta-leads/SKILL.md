---
name: capta-leads
description: "Analisa produto ou empresa e entrega as melhores estratégias de captação, comercialização e relacionamento com análise de mercado consolidada."
---

# Capta Leads

Primeira skill do pipeline comercial. Responsável por **captação e nutrição de leads** — da descoberta até o momento em que o prospect manifesta intenção clara de compra.

Quando o lead atinge o estágio "quente" (interação positiva direta), a skill orienta o agente a invocar **sales-leads** para traçar a estratégia de comercialização.

## Quando usar

Quando o usuário pedir análise de estratégia de captação, plano de prospecção, ou quiser saber como atrair e nutrir leads para um produto ou serviço.

## Arquivo de estado: scenario.md

Todas as skills do pipeline compartilham um único arquivo de estado: `[produto]/scenario.md`

**Responsabilidades do capta-leads no scenario.md:**
- **Cria** o arquivo na primeira execução
- **Escreve** nas seções: `perfil`, `estrategia-captacao`, `leads`, `nutricao`
- **Atualiza** `leads` conforme leads são captados e nutridos
- **Move** leads da seção `frios` para `quentes` quando há interação positiva
- **Lê** as seções escritas por sales-leads (`estrategia-comercializacao`) para contexto

**Nunca escreve** nas seções de responsabilidade do sales-leads.

### Estrutura do scenario.md

O capta-leads cria o scenario.md com a estrutura abaixo na primeira execução:

```
# Scenario: [Nome do Produto/Empresa]

## Perfil
- Tipo: [físico/digital/SaaS/serviço/mídia]
- Cliente ideal: [resumo ICP]
- Mercado: [geografia + nicho]
- Estágio: [novo/crescendo/escala]
- Ticket médio: [faixa]
- Data de criação: [data]

## Estratégia de Captação
[Gerado por capta-leads — detalhado abaixo]

## Nutrição
[Gerado por capta-leads — detalhado abaixo]

## Leads
### Quentes (interação positiva registrada)
| Lead | Canal | Interação positiva | Data | Status |
|---|---|---|---|---|
| [a preencher conforme execução] |

### Frios (captados, sem interação positiva)
| Lead | Canal | Ação de captação | Data | Última nutrição |
|---|---|---|---|---|
| [a preencher conforme execução] |

## Estratégia de Comercialização
[Gerado por sales-leads — não editar com capta-leads]

## Relacionamento
[Gerado pela skill de relacionamento — não editar com capta-leads]
```

## Input esperado

O input principal é um **report completo de marketing** com indicações de estratégias, contendo:
- Descrição do produto/serviço
- Estratégias recomendadas pelo report
- Dados de mercado, concorrentes, público-alvo
- Orçamento e recursos disponíveis

Se o input for insuficiente, perguntar:

1. O que é o produto/serviço? (físico, digital, SaaS, serviço, mídia)
2. Quem é o cliente ideal? (B2B, B2C, nicho, faixa de preço)
3. Qual o estágio? (novo, existente com clientes, escalando)
4. Qual o mercado/geografia? (local, nacional, internacional)
5. Orçamento/resources disponíveis? (equipe, verba, tempo)

## Responsabilidades desta skill

```
CAPTAÇÃO (responsabilidade direta)
├── Descoberta — levar desconhecidos ao primeiro contato
├── Atenção — fazer parar e olhar
└── Registro — transformar atenção em contato rastreável

NUTRIÇÃO (responsabilidade direta)
├── Acompanhar leads frios até ficarem quentes
├── Manter contato contínuo via canais de captação
└── Detectar quando o lead manifesta intenção de compra
```

## Definição de lead quente

**Lead quente = prospect com pelo menos uma interação positiva direta com um dos canais de captação.**

Exemplos de interação positiva:
- Respondeu um email ou mensagem
- Preencheu formulário de contato
- Clicou em CTA e navegou na página de oferta
- Iniciou conversa no chat
- Ligou ou pediu retorno
- Agendou uma reunião/call
- Comentou ou interagiu diretamente em conteúdo

**Apenas leads quentes acionam sales-leads.**

## Workflow

1. **Verificar se scenario.md já existe** para este produto
   - Se não existe: criar com a estrutura completa
   - Se existe: ler o estado atual antes de prosseguir
2. **Extrair e estruturar** o report — identificar produto, estratégias sugeridas, dados de mercado
3. **Classificar o produto** usando a matriz de referência (ver `references/framework.md`)
4. **Pesquisar mercado atual** — buscar concorrentes, tendências, canais ativos para o nicho (usar web_search)
5. **Traduzir estratégias em ações concretas** — para cada estratégia do report, definir o que fazer, como fazer, com que ferramenta, em quanto tempo, com que custo
6. **Definir plano de nutrição** — como acompanhar leads que não manifestaram interesse (frios) até que interajam positivamente
7. **Identificar gaps** — cruzar o framework completo com o report e apontar abordagens que não foram consideradas
8. **Rankear tudo** — pontuar por: viabilidade, custo, velocidade, escala, impacto
9. **Escrever no scenario.md** — atualizar seções de perfil, estratégia de captação, nutrição e critérios de lead quente
10. **Gerar output consolidado** para o usuário seguindo o template de saída

## Output para o usuário

Além de atualizar o scenario.md, entregar ao usuário:

```
## Análise de Captação: [Nome do Produto/Empresa]

### Perfil
[resumo do perfil classificado]

### Análise do Report
- Estratégias identificadas: [resumo]
- Pontos fortes: [o que faz sentido]
- Pontos fracos/lacunas: [o que falta]

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
| 1 | [sequência/email/conteúdo] | [canal] | [frequência] | [o que qualifica como quente] |

### Possibilidades Não Consideradas
[abordagens do framework que o report não menciona]

### Análise de Mercado Complementar
[concorrentes, tendências, oportunidades]

### Plano de Ação (30 dias)
[semana a semana]

### Métricas
| Fase | Métrica | Meta |
|---|---|---|
| Descoberta | Alcance/impressões | [número] |
| Atenção | CTR / engajamento | [%] |
| Registro | CPL | $[valor] |
| Nutrição | Taxa frios → quentes | [%] |

### Investimento estimado
[faixa de custo mensal]

### Próximo passo
Quando leads quentes aparecerem no scenario.md, invocar **sales-leads** para traçar a estratégia de comercialização.
```

## Regras

- **O report é a base, não o limite.** Traduzir estratégias em ações executáveis E expandir com o que falta.
- Sempre pesquisar mercado real antes de recomendar (web_search obrigatório)
- Rankear por **viabilidade prática**
- Incluir pelo menos 1 abordagem de baixo custo / bootstrap em cada fase
- **Sempre criar ou atualizar o scenario.md** — é a fonte de verdade do pipeline
- **Nunca escrever** nas seções de comercialização ou relacionamento do scenario.md
- Definir claramente os gatilhos que transformam lead frio em quente **para aquele produto específico**
- Se o produto for da FBR Inc (revistas, blogs, SaaS), considerar os ativos de mídia como vantagem competitiva
- Responder em português brasileiro
