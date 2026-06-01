# Big Picture: FBR.NEWS (Transformação Facebrasil)

## Timeline de Ações

### 2026-05-31 — Análise de captação do report de transformação Facebrasil
- **Fase:** Captação B2C
- **Ação:** Análise completa do report de transformação da Facebrasil usando o pipeline-fbr v1 (sem Fase 0)
- **Input:** Report de marketing da Transformação Facebrasil (enviado como imagem pelo Sergio)
- **Decisão tomada:** Executar captação diretamente sem Fase 0 (skill ainda não tinha Fase 0). Pesquisou mercado, gerou ações concretas, identificou 8 lacunas no report.
- **Resultado:**
  - Scenario.md criado em `/data/.openclaw/workspace/FBR.NEWS/scenario.md`
  - Perfil definido: mídia + plataforma digital, ICP brasileiros nos EUA 25-50 anos
  - Mercado: 700K-2.2M pessoas, US$ 132 bi gasto anual
  - Ações de descoberta, atenção e registro mapeadas
  - 8 lacunas críticas identificadas no report original
- **Aprendizado:** A execução real revelou 8 falhas estruturais na skill v1. A mais grave: sem ICP definido (Target Audience "TBD"), toda análise fica genérica. Segunda mais grave: ignorar WhatsApp para comunidade brasileira é erro fatal.
- **Próximo passo definido:** Discutir lacunas com o Sergio e atualizar a skill
- **Status:** concluído

---

### 2026-05-31 — Discussão das 8 lacunas + parcerias de monetização
- **Fase:** Transversal (meta: melhoria da skill)
- **Ação:** Discussão detalhada com o Sergio sobre cada lacuna identificada e sobre a ausência de ações B2B
- **Input:** As 8 lacunas + pergunta do Sergio sobre parcerias de afiliados
- **Decisão tomada:** Sergio confirmou todas as 8 correções e pediu melhorias estruturais na skill:
  1. Fase 0 obrigatória (ICP, baseline, benchmark, naming, canais, monetização)
  2. Track B2B separado com agente diferente
  3. Análise de canais obrigatória (WhatsApp, YouTube, IG, FB, X, LinkedIn)
  4. Preview de monetização com worst-case scenario
  5. Benchmark competitivo formal com tabela
- **Resultado:** Decisões alinhadas. Skill seria atualizada com todas as mudanças.
- **Aprendizado:** O Sergio pensa em agentes dedicados por empresa — isso muda a arquitetura da skill. A separação B2B/B2C permite escalar agentes especializados. O WhatsApp é.canal estratégico, não opcional, para produtos que servem a comunidade brasileira.
- **Próximo passo definido:** Atualizar a skill pipeline-fbr com todas as mudanças
- **Status:** concluído

---

### 2026-05-31 — Atualização da skill pipeline-fbr (v1 → v2)
- **Fase:** Transversal (melhoria de ferramenta)
- **Ação:** Reescrita da SKILL.md e scenario-template.md com todas as melhorias decididas
- **Input:** Decisões da discussão anterior
- **Decisão tomada:** Adicionar Fase 0 completa, Track B2B separado, análise de canais, preview de monetização, benchmark formal, baseline obrigatório
- **Resultado:**
  - SKILL.md atualizado com:
    - Fase 0 (Pré-requisitos): ICP, baseline, benchmark, naming, canais, preview monetização
    - Fase 1 renomeada para "Captação B2C" com análise de canais e worst-case
    - Fase 1B criada: Track B2B (parceiros e afiliados) com workflow próprio
    - Comandos de entrada expandidos (Fase 0 + B2B)
    - Workflow geral atualizado com leitura do bigimage.md
    - Regras gerais expandidas
  - scenario-template.md atualizado para v2.0 com novas seções
- **Aprendizado:** A skill evoluiu de 3 fases para 4+1 (Fase 0 + 3 fases + track B2B paralelo). A estrutura ficou mais complexa mas cada parte é executável independentemente por agentes diferentes.
- **Próximo passo definido:** Criar bigimage.md da Facebrasil e re-testar a skill com Fase 0
- **Status:** concluído

---

### 2026-05-31 — Criação do bigimage.md + decisão de aprendizado contínuo
- **Fase:** Transversal (infraestrutura do agente)
- **Ação:** Adicionar bigimage.md como arquivo obrigatório na skill, criar o bigimage da Facebrasil
- **Input:** Decisão do Sergio de que cada agente precisa aprender com cada situação
- **Decisão tomada:** bigimage.md é lido no início de cada sessão, toda ação é registrada com aprendizado obrigatório, entradas são acumulativas
- **Resultado:**
  - SKILL.md atualizado com seção "Arquivos de estado" incluindo bigimage.md
  - Workflow geral atualizado: passo 2 = ler bigimage.md
  - Regra geral #1: "bigimage.md é sagrado"
  - Este arquivo criado com histórico completo da sessão
- **Aprendizado:** A memória institucional é o ativo mais valioso de um agente dedicado. Sem ela, cada sessão é do zero. Com ela, o agente evolui. O campo "aprendizado" é o diferencial — transforma log em sabedoria.
- **Próximo passo definido:** Re-testar a skill com a Fase 0 completa para a Facebrasil
- **Status:** concluído

---

### 2026-05-31 — Performance lenta do servidor
- **Fase:** N/A (infraestrutura)
- **Ação:** Sergio reportou interações lentas e gargalos de postagem. Possível problema no servidor.
- **Input:** Observação direta do Sergio
- **Decisão tomada:** Anotado para investigar quando Sergio tiver acesso ao PC principal
- **Resultado:** Pendente. Precisa de acesso ao servidor para diagnosticar.
- **Aprendizado:** Problemas de infraestrutura afetam a experiência do usuário e a percepção de qualidade do agente. Investigar cedo.
- **Próximo passo definido:** Diagnosticar quando Sergio ligar o PC principal
- **Status:** bloqueado — aguardando acesso ao servidor

---

### 2026-05-31 — Fase 0 completa: Pré-requisitos FBR.NEWS
- **Fase:** Fase 0 — Pré-requisitos
- **Ação:** Execução completa da Fase 0 com a skill v2 (primeiro teste real)
- **Input:** Report de transformação + pesquisa de mercado (6 web_search executados)
- **Decisão tomada:** Definir 4 personas, mapear 9 canais por persona, benchmark com 6 concorrentes, naming de 11 módulos, preview de monetização com 11 modelos e 3 cenários
- **Resultado:**
  - **4 personas definidas:** Recém-Chegado, Estabilizado, Empreendedor, Investidor
  - **Baseline:** Quase tudo PENDENTE — Sergio não tinha acesso ao GA/redes sociais. Único dado disponível: ~80K readers (print+digital, dado antigo do advertising kit)
  - **Benchmark (6 concorrentes):** Brazilian Times, Portal Brazil USA, BrazilD, Samba, Portal do Imigrante, Ruvo
    - Oportunidade principal: nenhum concorrente tem IA + conteúdo + serviços + marketplace
    - Nenhum usa WhatsApp estrategicamente
    - Samba é o mais inovador mas é só marketplace
  - **Naming (11 módulos):** FBR.News, FBR.Imigra, FBR.Work, FBR.Edu, FBR.Health, FBR.Community, FBR.Assistant, FBR.Market, FBR.Tools, Semana FBR, FBR.Partners
  - **Canais:** WhatsApp primário para Recém-Chegado, Instagram primário para Estabilizado, LinkedIn primário para Empreendedor e Investidor
  - **Monetização:** 11 modelos mapeados. Worst-case: $1.500/mês mínimo (afiliados remessas + lead gen imigração + AdSense). Break-even realista: mês 3-4
  - **Pipeline B2B:** 8 parceiros mapeados (Wise, Remitly, escritórios imigração, Amazon, corretores imóveis, seguradoras, Inter&Co, Ruvo)
- **Aprendizado:**
  1. A Fase 0 funcionou — a skill v2 é significativamente melhor que v1. Output é muito mais completo.
  2. Sem baseline de métricas reais, todas as metas são estimativas. **Coletar baseline é prioridade #1.**
  3. WhatsApp como canal é confirmado por dados: 98% open rate, 45-60% conversão, 96% dos brasileiros usam. Nenhum concorrente usa.
  4. O mercado de remessas (US$ 8.1 bi/ano) é a maior oportunidade de monetização via afiliados.
  5. Lead gen (CPL) é o modelo-âncora mais resiliente no worst-case.
  6. Samba pode ser parceiro em vez de concorrente (marketplace + conteúdo = complementares).
- **Próximo passo definido:** Coletar baseline de métricas (GA + redes sociais). Depois executar Captação B2C e/ou B2B.
- **Status:** concluído

---

### 2026-05-31 — Relatório HTML + Link compartilhável + Scraping no topo
- **Fase:** Transversal (entregável + infraestrutura)
- **Ação:** Criar relatório HTML elegante com animações para stakeholders + plano de scraping como ação #1
- **Input:** Sergio pediu: (1) scraping no topo das ações, (2) relatório HTML elegante com animações e tipografia moderna, (3) link compartilhável para stakeholders, (4) plano de infra para visualização
- **Decisão tomada:**
  1. Usar Canvas do OpenClaw para servir o HTML
  2. Gateway está em loopback — precisa mudar para `auto` ou LAN para link ser acessível externamente
  3. Relatório criado em `~/.openclaw/canvas/fbr-news-pipeline.html`
  4. Scraping movido para Semana 1 como prioridade absoluta
- **Resultado:**
  - HTML criado: tipografia Inter + JetBrains Mono, animações suaves (fadeUp, reveal on scroll), dark theme profissional
  - Seções: Visão, Personas, Mercado, Benchmark, Canais, Monetização, Base, Ações, Módulos
  - URL local: `http://localhost:18789/__openclaw__/canvas/fbr-news-pipeline.html`
  - **Bloqueio:** gateway.bind = loopback. Precisa mudar para `auto` para stakeholders acessarem externamente
- **Aprendizado:**
  1. Canvas do OpenClaw é a forma mais simples de servir HTML compartilhável
  2. Gateway.bind precisa ser `auto` ou LAN/Tailscale para acesso externo — em loopback só funciona local
  3. Relatórios para stakeholders devem ser auto-contidos (sem deps externas exceto Google Fonts CDN)
  4. Scraping é fundação — sem base limpa, nada funciona. Deve ser semana 1 inegociável.
- **Próximo passo definido:** Configurar gateway.bind=auto para habilitar link externo. Apresentar ao Sergio.
- **Status:** concluído
