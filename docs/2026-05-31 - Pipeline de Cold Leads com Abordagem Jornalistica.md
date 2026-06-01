# Pipeline de Cold Leads com Abordagem Jornalística

**Data:** 31 de maio de 2026  
**Participantes:** Sergio, David  
**Status:** Em projeto — aguardando dados dos ativos da FBR e definição do nicho piloto

---

## 1. Contexto

A FBR Inc é uma empresa americana que detém dezenas de ativos digitais — revistas, blogs e sistemas SaaS. Sergio quer construir um pipeline de geração de cold leads usando agentes autônomos para qualquer um dos negócios da empresa.

## 2. Pesquisa de mercado

### Ferramentas e plataformas avaliadas

| Plataforma | Tipo | Ponto forte | Preço aprox. |
|---|---|---|---|
| **Clay** | Tudo-em-um | Claygent AI agents pesquisam prospects em profundidade | ~$149/mês |
| **Apollo.io** | Tudo-em-um | Banco de dados grande + scoring + sequências | ~$50-100/mês |
| **Smartlead** | Cold email | Agentes pesquisam, personalizam, atualizam CRM | ~$30-100/mês |
| **Apify** | Scraping + agents | Actors prontos, integração com LangGraph/CrewAI via MCP | Pay-per-use |
| **n8n** | Orquestração | Open-source, self-host, workflows visuais | Grátis (self-host) |
| **Instantly** | Cold email | Alto volume, warmup, deliverability | ~$30-100/mês |

### Custo estimado por lead (abordagem Apify)
- **$0.03–$0.17 por lead** com pipeline próprio
- Significativamente mais barato que plataformas SaaS ($0.50–$2.00/lead)

## 3. Abordagem escolhida: Outreach Jornalístico

### Por que essa abordagem
A FBR possui **revistas e blogs reais** — isso é um diferencial competitivo massivo:
- Email enviado de `@revistaX.com` — não de domínio genérico
- A abordagem é legítima — a matéria pode realmente ser publicada
- Quem aceita ser featured já está aquecido para conversa comercial
- Taxa de resposta estimada: **15-30%** (vs 1-5% de cold pitch comum)

### A jornada do lead
```
1. Apify scrape negócios por nicho/região
2. LLM enriquece e scored contra o ICP
3. Template jornalístico gerado:
   "Olá, sou da [revista X], vimos sua empresa
    e gostaríamos de featured vocês numa matéria..."
4. Email enviado do domínio da própria revista
5. Quem responde → CRM (relação comercial)
6. Quem não responde em 30 dias → purga
```

## 4. Arquitetura do pipeline

```
┌─────────────────────┐
│   APIFY SCRAPERS    │
│  Google Maps, dirs  │
│  LinkedIn (via      │
│  proxies)           │
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│   PROXY LAYER       │
│  BrightData/Oxylabs │
│  IPs residenciais   │
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│   ENRIQUECIMENTO    │
│  LLM scoring +      │
│  verificação email  │
│  (Hunter, NeverB.)  │
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│   FILTRO LEGAL      │
│  - Remove EU quando │
│    necessário       │
│  - Data minimizada  │
│  - Tag compliance   │
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│   COLD EMAIL        │
│  Domínios das       │
│  revistas da FBR    │
│  Warmup separado    │
│  Unsubscribe auto   │
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│   CONVERSÃO         │
│  Respostas → CRM    │
│  Não-abriu → delete │
│  em 30-90 dias      │
└─────────────────────┘
```

### Componentes
- **Scraping:** Apify (actors: Google Maps Scraper, Lead Gen AI Agent, LinkedIn via proxies)
- **Proxies:** BrightData ou Oxylabs (IPs residenciais rotativas)
- **Orquestração:** n8n (self-hosted no servidor da FBR)
- **Enriquecimento:** LLM (OpenAI/Claude) + Hunter.io (verificação de email)
- **Envio:** Domínios das revistas da FBR + infra dedicada com warmup
- **CRM:** A definir (HubSpot, ou algo mais simples como Google Sheets)

## 5. Mitigação de riscos e compliance

### Estratégias de contingenciamento

| Risco | Estratégia |
|---|---|
| **GDPR (UE)** | Geo-fencing pra excluir contatos EU; hosting em servidores EUA; base legal "interesse legítimo"; data minimization; retenção curta (30-90 dias) |
| **LinkedIn ToS** | Contas sock puppet; rate limiting (50-100/dia); rotação de contas; proxies residenciais; browsers antidetect (GoLogin, Multilogin) |
| **CAN-SPAM (EUA)** | Assunto não-engabioso; endereço físico; unsubscribe funcional; honrar opt-out em 10 dias |
| **Reputação de domínio** | Domínios dedicados (nunca o principal); warmup progressivo (30 dias); SPF/DKIM/DMARC/rDNS; volume controlado (50-200/dia) |
| **Exposição legal da FBR** | LLC separada para operações de outbound; email enviado como "parceiro/editor" de revista; respaldo jurídico do precedente hiQ vs LinkedIn |

### Proteção empresarial
- **LLC separada** para operações de outbound — isola a FBR Inc
- **Terms of Service** nos próprios ativos que permitem scraping de dados públicos
- **A/B testing** de abordagem editorial vs comercial
- **Responder e deletar** — quem responde entra no CRM, quem não responde é purgado

## 6. Plano de implementação

### Fase 1 — Teste com Apify (semana 1-2)
- Criar conta Apify
- Testar 2-3 Actors prontos (Google Maps, Lead Gen AI Agent)
- Validar qualidade dos dados e custo real por lead

### Fase 2 — Pipeline com n8n (semana 3-4)
- Self-host n8n no servidor
- Montar: Apify → LLM scoring → verificação de email → Google Sheets/CRM
- Definir ICP por negócio

### Fase 3 — Personalização e outreach (semana 5+)
- Conectar com infra de email
- Templates personalizados por segmento (abordagem jornalística)
- Domínios das revistas com warmup

### Fase 4 — Scale e automação (contínuo)
- Expandir para múltiplos ativos de mídia
- Pipeline rodando 24/7
- Métricas de conversão e otimização contínua

## 7. Decisões pendentes

- [ ] Quais são os ativos de mídia da FBR (nomes, nichos, URLs)
- [ ] Qual nicho/vertical atacar primeiro no piloto
- [ ] ICP detalhado por tipo de negócio
- [ ] Configurar secret manager (quando Sergio ligar o PC principal)
- [ ] Configurar skill de Apify no OpenClaw
- [ ] Escolher provedor de proxies (BrightData vs Oxylabs)
- [ ] Definir CRM de destino
- [ ] Configurar infra de email (domínios, warmup, SPF/DKIM/DMARC)

## 8. Recursos e referências

- [Apify AI Lead Generation Playbook 2026](https://use-apify.com/blog/ai-lead-generation-playbook-2026)
- [Apify AI Agents](https://apify.com/ai-agents)
- [Local Lead Generation Agent](https://apify.com/apify/local-lead-generation-agent)
- [AI Cold Outreach Personalization](https://apify.com/happitap/ai-cold-outreach-personalization)
- [n8n Workflow: B2B Lead Gen + Cold Email](https://n8n.io/workflows/9816-automated-b2b-lead-generation-and-cold-emails-with-openai-apify-gmail-and-telegram/)
- [Clay AI Lead Generation](https://www.clay.com/blog/ai-lead-generation)
- [Caso hiQ vs LinkedIn (2019)](https://en.wikipedia.org/wiki/HiQ_Labs_v._LinkedIn) — precedente legal para scraping de dados públicos nos EUA

---

*Documento criado por David. Última atualização: 31 de maio de 2026.*
