# Guia de Instalação Ubuntu Server — Hostel

> **Hardware:** i7 3ª gen | 16GB RAM | SSD 512GB | RJ45 nativa + USB-RJ45
> **Objetivo:** MikroTik CHR + FreePBX + AdGuard DNS para gerenciamento de rede do hostel
> **Data:** 1 de junho de 2026
> **Substitui:** `proxmox-hostel-install.md` — ProxMox removido por decisão de padronizar tudo em Ubuntu

---

## Por que Ubuntu em vez de ProxMox

- **Padrão FBR:** Todas as máquinas rodam Ubuntu Server — mesma base de conhecimento, mesma manutenção
- **Simplicidade:** ProxMox adiciona complexidade (hypervisor, clusters, storage pools) desnecessária pra 3 serviços
- **Docker é suficiente:** MikroTik CHR, FreePBX e AdGuard rodam perfeitamente em containers
- **Menos overhead:** Sem camada de hypervisor, mais RAM disponível pros serviços
- **Manutenção unificada:** Mesmo sistema operacional = mesmos comandos, mesmos scripts

---

## FASE 1 — Preparação

### 1.1 — O que baixar

- **Ubuntu Server 24.04 LTS ISO:** https://ubuntu.com/download/server
- **Rufus** para criar pendrive bootável: https://rufus.ie

### 1.2 — Pendrive bootável

1. Abra Rufus
2. Selecione a ISO do Ubuntu Server
3. Device → seu pendrive (mínimo 4GB)
4. Partition scheme → **GPT**
5. Clique em **Start**

### 1.3 — Verificar BIOS

Antes de instalar, entre na BIOS (DEL ou F2 no boot):

1. **Virtualização (VT-x):** **Enabled** — obrigatório pra Docker
2. **VT-d (IOMMU):** **Enabled** se disponível
3. **Secure Boot:** **Disabled**
4. **Boot Order:** Pendrive em primeiro
5. Salve e saia (F10)

---

## FASE 2 — Instalação do Ubuntu Server

### 2.1 — Boot pelo pendrive

1. Ligue o PC com pendrive inserido
2. Boot pelo pendrive (F12 para boot menu se necessário)

### 2.2 — Instalação

| Etapa | Escolha |
|-------|---------|
| Language | English |
| Keyboard | Portuguese (Brazil) ou English US |
| Network | DHCP (automático) |
| Storage | Use an entire disk → SSD 512GB |
| Profile | Name: `sergio`, Username: `sergio`, senha forte |
| SSH | **SIM** ✅ — Install OpenSSH server |
| Snaps | Nenhum |

### 2.3 — Pós-instalação

```bash
# Logar via SSH do seu computador
ssh sergio@<ip-da-maquina>

# Atualizar
sudo apt update && sudo apt upgrade -y
```

---

## FASE 3 — Stack Base

### 3.1 — Script de instalação

```bash
# Copiar script do pendrive e rodar
sudo ./install-hostel.sh
```

Ou instalar manualmente:

```bash
# Dependências
sudo apt install -y curl git wget nano ufw htop tmux lsof jq

# Docker
curl -fsSL https://get.docker.com | sudo bash
sudo usermod -aG docker sergio

# Firewall
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 5060:5061/udp   # SIP
sudo ufw allow 10000:20000/udp # RTP (voz)
sudo ufw --force enable
```

---

## FASE 4 — MikroTik CHR (Docker)

### 4.1 — Criar container MikroTik

```bash
sudo docker run -d \
  --name mikrotik-chr \
  --restart unless-stopped \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  --device=/dev/net/tun \
  -p 8080:80 \
  -p 8291:8291 \
  -p 21:21 \
  -p 22:22 \
  -p 23:23 \
  -p 5060:5060 \
  -p 5061:5061 \
  -p 4500:4500/udp \
  -p 500:500/udp \
  -p 1194:1194 \
  --network=host \
  -v mikrotik_data:/var/lib/mikrotik \
  igorondaro/mikrotik-routeros:latest
```

> **Nota:** Imagem Docker do RouterOS. Verifique a imagem mais recente no Docker Hub.

### 4.2 — Acessar MikroTik

```bash
# Console direto
docker exec -it mikrotik-chr /bin/bash

# Ou via Winbox (do seu computador)
# IP do servidor, porta 8291
# Login: admin / senha vazia (primeiro acesso)
```

### 4.3 — Configuração básica

Pelo console do container ou Winbox:

```routeros
# Nomear interfaces
/interface print
/interface ethernet set ether1 name="WAN"
/interface ethernet set ether2 name="LAN"

# WAN — DHCP client (recebe IP do modem)
/ip dhcp-client add interface=WAN disabled=no

# LAN
/ip address add address=10.0.0.1/24 interface=LAN

# DHCP Server para rede do hostel
/ip pool add name=dhcp_pool ranges=10.0.0.50-10.0.0.200
/ip dhcp-server add name=dhcp1 interface=LAN address-pool=dhcp_pool disabled=no
/ip dhcp-server network add address=10.0.0.0/24 gateway=10.0.0.1 dns-server=10.0.0.1

# DNS
/ip dns set allow-remote-requests=yes
/ip dns static add name=hostel.local address=10.0.0.1

# NAT (masquerade)
/ip firewall nat add chain=srcnat out-interface=WAN action=masquerade

# Firewall básico
/ip firewall filter add chain=input action=accept protocol=icmp
/ip firewall filter add chain=input action=accept connection-state=established,related
/ip firewall filter add chain=input action=accept in-interface=LAN
/ip firewall filter add chain=input action=drop
```

---

## FASE 5 — FreePBX (Docker)

### 5.1 — Criar container FreePBX

```bash
sudo docker run -d \
  --name freepbx \
  --restart unless-stopped \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  --device=/dev/net/tun \
  --network=host \
  -v freepbx_data:/var/lib/freepbx \
  -v freepbx_asterisk:/etc/asterisk \
  -t \
  fl.zabbix.com/freepbx/freepbx:latest
```

> **Nota:** Verifique a imagem mais adequada no Docker Hub. Alternativas: `trafex/freepbx`, `flaviostutz/freepbx`.

### 5.2 — Acessar FreePBX

1. No navegador: **http://<ip-do-servidor>**
2. Siga o wizard inicial (criar admin user)
3. Configure ramais

### 5.3 — Criar ramais

No painel do FreePBX:

1. **Applications** → **Extensions**
2. **Add Extension** → **Add SIP [chan_pjsip] Extension**
3. Para cada ramal:

| Ramal | Nome | Uso |
|-------|------|-----|
| 100 | Recepção | Recepção principal |
| 101 | Portaria | Portaria / segurança |
| 102 | Manutenção | Equipe de manutenção |
| 103 | Gerência | Gerência do hostel |

4. Submit → **Apply Config**

---

## FASE 6 — Grandstream HT814

### 6.1 — Conectar

1. Ligue o HT814 na energia
2. Conecte a porta **LAN** no switch TP-Link
3. O HT814 recebe IP via DHCP (ex: 10.0.0.50)

### 6.2 — Registrar no FreePBX

No **HT814** (http://10.0.0.50):
- Login: admin / admin

**FXS Ports → Port 1:**

| Campo | Valor |
|-------|-------|
| SIP Server | 10.0.0.10 (IP do FreePBX) |
| SIP UserID | 100 |
| Authenticate ID | 100 |
| Authenticate Password | (senha do ramal no FreePBX) |

Repetir para portas 2, 3, 4 → **Save and Apply**

### 6.3 — Testar

1. Ligue telefone analógico na porta FXS 1
2. Tire fone do gancho — deve ouvir tom de discar
3. Ligue do ramal 100 pro 101 — deve tocar

---

## FASE 7 — AdGuard Home (DNS)

### 7.1 — Instalar

```bash
curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sudo sh -s -- -v
```

### 7.2 — Configurar

1. Acesse: **http://<ip-do-servidor>:3000**
2. Wizard:
   - Web interface port: **80** (ou 8080 se 80 estiver ocupado)
   - DNS server port: **53**
3. Crie usuário admin

### 7.3 — Apontar MikroTik para o AdGuard

No MikroTik (Winbox ou terminal):

```routeros
/ip dns set servers=10.0.0.1 allow-remote-requests=yes
/ip dhcp-server network set 0 dns-server=10.0.0.1
```

---

## FASE 8 — Monitoramento

### 8.1 — Cockpit (gestão do servidor)

```bash
sudo apt install -y cockpit
sudo systemctl enable --now cockpit.socket
# Acessa: https://<ip>:9090
```

### 8.2 — Netdata (monitoramento visual)

```bash
curl -fsSL https://get.netdata.cloud/kickstart.sh | sh
# Acessa: http://<ip>:19999
```

---

## FASE 9 — Diagrama da Rede

```
┌──────────────────────────────────────────────────┐
│                  INTERNET                        │
│              (1 ou 2 links)                      │
└──────────────────┬───────────────────────────────┘
                   │
          ┌────────▼────────┐
          │  USB-RJ45 (WAN) │
          └────────┬────────┘
                   │
    ┌──────────────▼──────────────────────────────┐
    │    Ubuntu Server 24.04 LTS (Hostel)          │
    │    i7 3ª gen / 16GB / SSD 512GB             │
    │                                              │
    │  ┌────────────────────────────────────────┐  │
    │  │  Docker                                 │  │
    │  │                                         │  │
    │  │  ┌─────────────┐  ┌──────────────────┐ │  │
    │  │  │ MikroTik CHR │  │    FreePBX       │ │  │
    │  │  │ WAN + LAN    │  │    PBX / Ramais  │ │  │
    │  │  │ NAT          │  │    URA / Gravação│ │  │
    │  │  │ Firewall     │  │                  │ │  │
    │  │  └─────────────┘  └──────────────────┘ │  │
    │  │                                         │  │
    │  │  ┌─────────────────────────────────────┐│  │
    │  │  │ AdGuard Home (nativo)               ││  │
    │  │  │ DNS / Bloqueio ads / Filtro         ││  │
    │  │  └─────────────────────────────────────┘│  │
    │  └────────────────────────────────────────┘  │
    │                                              │
    │  ┌────────────────┐  ┌───────────────────┐  │
    │  │ Cockpit :9090  │  │ Netdata :19999    │  │
    │  │ Gestão         │  │ Monitoramento     │  │
    │  └────────────────┘  └───────────────────┘  │
    └──────────────┬───────────────────────────────┘
                   │
          ┌────────▼────────┐
          │ RJ45 nativa LAN │
          └────────┬────────┘
                   │
          ┌────────▼────────┐
          │ Switch TP-Link  │
          │   SG108E        │
          └──┬──┬──┬──┬──┬──┘
             │  │  │  │  │
     ┌───────┘  │  │  │  └───────┐
     ▼          ▼  ▼  ▼          ▼
  HT814    Routers  Routers   Outros
  (FXS)    (bridge) (bridge)  dispositivos
     │
  Telefones
  analógicos
```

---

## FASE 10 — Checklist

### Instalação
- [ ] Ubuntu Server 24.04 instalado
- [ ] SSH habilitado
- [ ] Sistema atualizado
- [ ] Docker instalado

### Serviços
- [ ] MikroTik CHR rodando (Docker)
- [ ] WAN com internet
- [ ] LAN distribuindo DHCP
- [ ] Firewall MikroTik ativo
- [ ] FreePBX rodando (Docker)
- [ ] Ramais criados (100-103)
- [ ] AdGuard Home rodando
- [ ] DNS resolvendo e bloqueando ads

### Hardware
- [ ] HT814 registrado no FreePBX
- [ ] Tom de discar nos telefones analógicos
- [ ] Teste de chamada entre ramais

### Monitoramento
- [ ] Cockpit acessível (:9090)
- [ ] Netdata acessível (:19999)

### Segurança
- [ ] Senhas documentadas em local seguro
- [ ] Firewall UFW ativo
- [ ] Winbox instalado no seu computador

---

## Comandos Úteis

```bash
# Status dos containers
docker ps

# Logs de um container
docker logs -f mikrotik-chr
docker logs -f freepbx

# Reiniciar container
docker restart mikrotik-chr
docker restart freepbx

# Console do MikroTik
docker exec -it mikrotik-chr /bin/bash

# Backup dos containers
docker export mikrotik-chr | gzip > mikrotik-backup-$(date +%Y%m%d).tar.gz
docker export freepbx | gzip > freepbx-backup-$(date +%Y%m%d).tar.gz

# Recursos do sistema
htop
df -h
free -h
```

---

## Comparação: Ubuntu vs ProxMox

| Critério | ProxMox (antes) | Ubuntu Server (agora) |
|----------|-----------------|----------------------|
| **Complexidade** | Hypervisor + VMs + LXC | Docker + serviços nativos |
| **RAM overhead** | ~2GB (hypervisor) | ~200MB (Docker daemon) |
| **Manutenção** | Específica ProxMox | Mesma de todas as máquinas FBR |
| **Backup** | vzdump (formato proprietário) | Docker export + rsync |
| **Rede** | vmbr0, vmbr1, bridges | Docker networks + host networking |
| **Monitoramento** | Painel ProxMox | Cockpit + Netdata |
| **Escala** | VMs completas | Containers leves |
| **Padrão FBR** | ❌ Único diferente | ✅ Mesmo de todas as máquinas |

---

*Guia criado por David ⚡ — 01/06/2026*
*Projeto: Infraestrutura de rede do Hostel*
*Padrão FBR: tudo que fizermos precisa virar um método replicável e registrado.*
