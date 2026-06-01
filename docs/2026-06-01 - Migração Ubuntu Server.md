# Migração FBR: Umbrel → Ubuntu Server

**Data:** 1 de junho de 2026  
**Autor:** David + Sergio  
**Status:** Plano pronto para execução  
**Princípio:** Tudo que fizermos precisa virar um método replicável e registrado.

---

## 1. Visão Geral

Migração do OpenClaw do ambiente Umbrel (containerizado, acesso limitado) para Ubuntu Server 24.04 LTS nativo (controle total, performance máxima).

### Antes (Umbrel)
```
Umbrel OS
└── Docker container
    └── OpenClaw (acesso limitado, sem systemd, sem restart)
```

### Depois (Ubuntu Server)
```
Ubuntu Server 24.04 LTS
├── OpenClaw (nativo, systemd, controle total)
├── Easypanel v2 (mesmo que VPS atual)
│   ├── Traefik (reverse proxy)
│   └── Serviços auxiliares
└── Docker Swarm
```

---

## 2. Hardware

| Componente | Spec | Função |
|-----------|------|--------|
| CPU | Intel i7 3ª geração | Suficiente — chamadas vão pra API |
| RAM | 32 GB | Excelente — múltiplos agentes + indexação |
| VRAM | 1 GB | Modelos locais não, mas 100% via API |
| Storage | 2x SSD 512GB | Ver seção de discos abaixo |
| Rede | LAN (IP local) | Acesso via SSH + Traefik |

### Decisão dos discos

| Opção | Setup | Recomendação |
|-------|-------|-------------|
| **RAID 1** (recomendado) | Espelhados, 512GB úteis | Redundância total — se um SSD morre, nada se perde |
| Separação | SSD1 = OS, SSD2 = dados | Mais espaço, sem redundância |

**Recomendação: RAID 1.** 512GB é muito pra operar. Memória da FBR merece redundância.

---

## 3. Preparação do Pendrive USB

O mesmo pendrive vai servir pra:
1. Instalar o Ubuntu Server
2. Guardar o backup do OpenClaw

### Passo a passo

#### 3.1. Baixar Ubuntu Server

```bash
# No seu computador Windows
# Baixar de: https://ubuntu.com/download/server
# Versão: Ubuntu Server 24.04 LTS
```

#### 3.2. Criar pendrive bootável

Usar **Rufus** (https://rufus.ie):
1. Abrir Rufus
2. Selecionar o pendrive USB
3. Selecionar a ISO do Ubuntu Server 24.04
4. **IMPORTANTE:** Partição GPT se a máquina suportar UEFI, MBR se for BIOS legacy
5. Criar o pendrive bootável

#### 3.3. Copiar o backup pro pendrive

Depois de criar o bootável, o pendrive ainda tem espaço. Copiar:

```powershell
# No Windows, copiar o arquivo de backup
# O backup está no GitHub: sergiomvj/openclaw-backup
# Baixar o backup-openclaw-2026-06-01.tar.gz do repo
```

Ou, se o pendrive já está conectado na máquina Umbrel e o backup foi feito lá, copiar direto.

#### 3.4. Anotar o que está no pendrive

```
pendrive USB/
├── [Ubuntu Server 24.04 LTS bootável]
└── backup-openclaw-2026-06-01.tar.gz   ← cérebro do David
```

---

## 4. Instalação do Ubuntu Server

### 4.1. Boot pelo pendrive

1. Conectar o pendrive na máquina
2. Ligar e entrar na BIOS (geralmente F2, DEL ou F12)
3. Configurar boot pelo USB
4. Bootar pelo Ubuntu Server

### 4.2. Instalação — opções importantes

| Etapa | Escolha |
|-------|---------|
| Idioma | English (mais fácil pra troubleshooting) |
| Keyboard | English (US) ou Portuguese (Brazil) |
| Network | DHCP (depois configuramos IP estático se necessário) |
| Storage | Ver seção 4.3 abaixo |
| Profile | Name: `sergio`, username: `sergio`, senha forte |
| SSH | **SIM** — instalar OpenSSH server |
| Snaps | Não instalar nenhum por enquanto |

### 4.3. Configuração de storage (RAID 1)

Se for RAID 1 (recomendado):

Na tela de storage:
1. Escolher "Manual" ou "Custom storage layout"
2. Criar RAID 1 com os dois SSDs:
   - Marcar ambos como physical volumes pra RAID
   - Criar RAID 1 device
   - Particionar: EFI (~512MB), swap (~8GB), root (restante)
3. Formatar root como ext4
4. Montar em `/`

Se NÃO for RAID:
- SSD1: OS (partição única ext4, montar em `/`)
- SSD2: dados (montar em `/data`)

### 4.4. Pós-instalação

```bash
# Logar via SSH do seu computador
ssh sergio@<ip-da-maquina>

# Atualizar tudo
sudo apt update && sudo apt upgrade -y

# Instalar dependências básicas
sudo apt install -y curl git wget nano ufw
```

---

## 5. Configuração do Servidor

### 5.1. Firewall

```bash
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 18790/tcp  # OpenClaw gateway (se quiser acesso externo)
sudo ufw enable
sudo ufw status
```

### 5.2. Docker + Docker Compose

```bash
# Instalar Docker
curl -fsSL https://get.docker.com | sudo bash

# Adicionar sergio ao grupo docker
sudo usermod -aG docker sergio

# Verificar
docker --version
docker compose version
```

### 5.3. Easypanel

```bash
# Instalar Easypanel v2
curl -fsSL https://get.easypanel.io | sudo bash

# Acessar: http://<ip-da-maquina>:80
# Configurar com mesmo setup da VPS atual
```

### 5.4. Traefik + Cloudflare

Configurar dentro do Easypanel (mesmo processo da VPS):
- Traefik como reverse proxy
- Cloudflare DNS apontando pra máquina
- SSL automático via Let's Encrypt

---

## 6. Instalação do OpenClaw

### 6.1. Instalar

```bash
# Instalar Node.js 22 (LTS)
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs

# Instalar OpenClaw
sudo npm install -g openclaw

# Verificar
openclaw --version
```

### 6.2. Restaurar backup

```bash
# Copiar backup do pendrive
sudo mkdir -p /mnt/usb
sudo mount /dev/sdb1 /mnt/usb
cp /mnt/usb/backup-openclaw-2026-06-01.tar.gz /tmp/

# Restaurar
mkdir -p ~/.openclaw
cd ~/.openclaw
tar xzf /tmp/backup-openclaw-2026-06-01.tar.gz

# Reconstruir índice de memória
openclaw memory index --force

# Desmontar pendrive
sudo umount /mnt/usb
```

### 6.3. Verificar restauração

```bash
# Memória
openclaw memory status --deep

# Skills
openclaw skills list

# Gateway
openclaw gateway status
```

### 6.4. Iniciar gateway

```bash
# Primeira vez
openclaw gateway

# Ou instalar como serviço systemd (recomendado)
openclaw gateway install
systemctl --user start openclaw-gateway
systemctl --user enable openclaw-gateway
```

### 6.5. Validar que tudo funciona

Depois de iniciar, abrir chat com o David e pedir:

```
O que você lembra sobre a FBR? E sobre o pipeline-fbr?
```

Se o David responder com contexto correto — migração bem sucedida.

---

## 7. Serviços Auxiliares

### 7.1. Upload service (upload.pipeline.fbr.news)

Restaurar via Easypanel como Docker service (mesmo setup da VPS atual).

### 7.2. Nginx para relatórios (pipeline.fbr.news)

Restaurar via Easypanel como Docker service.

---

## 8. Pós-Migração

### 8.1. Testar cada camada do OpenClaw Learn

```bash
# Active Memory
/verbose on
# Mandar mensagem e verificar se recall aparece

# Skill Workshop
# Dizer algo como "next time sempre faça X" e verificar se propõe skill

# Cron de reflexão
openclaw cron list
# Verificar se daily-reflection está ativo

# Memory
openclaw memory status --deep
```

### 8.2. GitHub integration

Mover script de auth para local permanente:

```bash
mkdir -p ~/.openclaw/scripts
cp /tmp/github-app-auth.js ~/.openclaw/scripts/
```

### 8.3. Configurar IP estático (opcional)

```bash
# Editar netplan
sudo nano /etc/netplan/00-installer-config.yaml
```

```yaml
network:
  ethernets:
    eth0:
      addresses:
        - 192.168.60.xxx/24
      routes:
        - to: default
          via: 192.168.60.1
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
  version: 2
```

```bash
sudo netplan apply
```

---

## 9. Checklist de Migração

### Preparação
- [ ] Ubuntu Server 24.04 ISO baixado
- [ ] Pendrive bootável criado (Rufus)
- [ ] Backup `backup-openclaw-2026-06-01.tar.gz` copiado pro pendrive
- [ ] Hardware verificado (i7 3ª gen, 32GB RAM, 2x SSD 512GB)

### Instalação
- [ ] Boot pelo pendrive
- [ ] Ubuntu Server instalado (RAID 1 se escolhido)
- [ ] SSH habilitado
- [ ] Sistema atualizado (`apt update && apt upgrade`)

### Stack base
- [ ] Docker + Docker Compose instalados
- [ ] Easypanel v2 instalado
- [ ] Firewall configurado (UFW)
- [ ] Traefik configurado no Easypanel
- [ ] Cloudflare DNS apontando pro novo servidor

### OpenClaw
- [ ] Node.js 22 instalado
- [ ] OpenClaw instalado via npm
- [ ] Backup restaurado (`tar xzf`)
- [ ] Índice de memória reconstruído (`openclaw memory index --force`)
- [ ] Gateway iniciado (`openclaw gateway`)
- [ ] Gateway instalado como serviço systemd

### Validação
- [ ] `openclaw memory status --deep` — tudo ok
- [ ] `openclaw skills list` — pipeline-fbr, capta-leads, sales-leads
- [ ] Chat com David — pergunta sobre FBR e pipeline
- [ ] Active Memory funcionando (`/verbose on`)
- [ ] Cron `daily-reflection` ativo
- [ ] GitHub auth funcionando

### Serviços
- [ ] Upload service restaurado
- [ ] Nginx de relatórios restaurado
- [ ] Script GitHub App em local permanente

---

## 10. Rollback

Se algo der errado, o Umbrel continua intacto — não foi alterado. A máquina pode voltar ao estado anterior com:

1. Reconectar os discos originais do Umbrel (se trocou os discos)
2. Ou reinstalar Umbrel OS

O backup no GitHub (`sergiomvj/openclaw-backup`) é a rede de segurança — sempre acessível.

---

## 11. Endereços e Referências

| Recurso | URL/comando |
|---------|-------------|
| Ubuntu Server ISO | https://ubuntu.com/download/server |
| Rufus | https://rufus.ie |
| Easypanel | https://easypanel.io |
| OpenClaw docs | https://docs.openclaw.ai |
| Repo backup | https://github.com/sergiomvj/openclaw-backup (privado) |
| OpenClaw Learn | `docs/2026-06-01 - OpenClaw Learn.md` |

---

*Método criado em 1 de junho de 2026. Documentado como parte do princípio FBR: tudo que fizermos precisa virar um método replicável e registrado.*
