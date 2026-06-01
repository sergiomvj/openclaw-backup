#!/bin/bash
# ============================================================
# Hostel — Script de Instalação
# ============================================================
# Rodar APÓS instalar Ubuntu Server 24.04 LTS
#
# Hardware: i7 3ª gen | 16GB RAM | SSD 512GB | RJ45 + USB-RJ45
# Stack: Docker + MikroTik CHR + FreePBX + AdGuard + Cockpit + Netdata
#
# Uso:
#   chmod +x install-hostel.sh
#   sudo ./install-hostel.sh
# ============================================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }
info() { echo -e "${BLUE}[→]${NC} $1"; }

HOSTEL_USER="sergio"
HOSTEL_HOME="/home/${HOSTEL_USER}"
SWAP_SIZE="4G"

echo ""
echo "============================================================"
echo "  Hostel — Instalação Ubuntu Server"
echo "  MikroTik CHR + FreePBX + AdGuard DNS"
echo "  Executado em: $(date)"
echo "============================================================"
echo ""

# ============================================================
# 1. VERIFICAR ROOT
# ============================================================
if [[ $EUID -ne 0 ]]; then
  err "Rode com sudo: sudo ./install-hostel.sh"
fi
log "Root OK"

# ============================================================
# 2. ATUALIZAR SISTEMA
# ============================================================
info "Atualizando sistema..."
apt update -y && apt upgrade -y
log "Sistema atualizado"

# ============================================================
# 3. INSTALAR DEPENDÊNCIAS
# ============================================================
info "Instalando dependências..."
apt install -y \
  curl git wget nano ufw htop tmux \
  build-essential python3 \
  ca-certificates gnupg \
  lsof rsync jq \
  cockpit
log "Dependências + Cockpit instalados"

# ============================================================
# 4. FIREWALL
# ============================================================
info "Configurando firewall..."
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 9090/tcp   # Cockpit
ufw allow 19999/tcp  # Netdata
ufw allow 8291/tcp   # Winbox → MikroTik
ufw allow 5060:5061/udp   # SIP
ufw allow 10000:20000/udp # RTP (voz)
ufw --force enable
log "Firewall configurado"

# ============================================================
# 5. SWAP
# ============================================================
info "Configurando swap..."
if [[ $(swapon --show | wc -l) -lt 2 ]]; then
  fallocate -l ${SWAP_SIZE} /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
  sysctl vm.swappiness=10
  echo 'vm.swappiness=10' >> /etc/sysctl.conf
  log "Swap ${SWAP_SIZE} criado"
else
  log "Swap já existe"
fi

# ============================================================
# 6. DOCKER
# ============================================================
info "Instalando Docker..."
if ! command -v docker &> /dev/null; then
  curl -fsSL https://get.docker.com | bash
  usermod -aG docker ${HOSTEL_USER}
  systemctl enable docker
  systemctl start docker
  log "Docker instalado"
else
  log "Docker já instalado"
fi

# ============================================================
# 7. COCKPIT
# ============================================================
info "Configurando Cockpit..."
systemctl enable --now cockpit.socket
log "Cockpit ativo em https://$(hostname -I | awk '{print $1}'):9090"

# ============================================================
# 8. NETDATA
# ============================================================
info "Instalando Netdata..."
if ! command -v netdata &> /dev/null; then
  curl -fsSL https://get.netdata.cloud/kickstart.sh | sh -
  systemctl enable netdata
  log "Netdata ativo em http://$(hostname -I | awk '{print $1}'):19999"
else
  log "Netdata já instalado"
fi

# ============================================================
# 9. MIKROTIK CHR (Docker)
# ============================================================
info "Instalando MikroTik CHR..."
if ! docker ps -a | grep -q mikrotik-chr; then
  docker run -d \
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
    --network=host \
    -v mikrotik_data:/var/lib/mikrotik \
    igorondaro/mikrotik-routeros:latest
  
  log "MikroTik CHR container criado"
else
  log "MikroTik CHR já existe"
fi

# ============================================================
# 10. FREEPBX (Docker)
# ============================================================
info "Instalando FreePBX..."
if ! docker ps -a | grep -q freepbx; then
  docker run -d \
    --name freepbx \
    --restart unless-stopped \
    --cap-add=NET_ADMIN \
    --cap-add=NET_RAW \
    --device=/dev/net/tun \
    --network=host \
    -v freepbx_data:/var/lib/freepbx \
    -v freepbx_asterisk:/etc/asterisk \
    -t \
    flaviostutz/freepbx:latest

  log "FreePBX container criado"
else
  log "FreePBX já existe"
fi

# ============================================================
# 11. ADGUARD HOME
# ============================================================
info "Instalando AdGuard Home..."
if ! command -v AdGuardHome &> /dev/null && ! systemctl is-active AdGuardHome &> /dev/null; then
  curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -v
  log "AdGuard Home instalado"
else
  log "AdGuard Home já instalado"
fi

# ============================================================
# 12. NETWORK — USB-RJ45
# ============================================================
info "Verificando interfaces de rede..."
echo ""
echo "Interfaces disponíveis:"
ip -br link show
echo ""

USB_IFACE=$(ip -br link show | grep -i "enx" | awk '{print $1}' | head -1)
if [[ -n ${USB_IFACE} ]]; then
  log "Adaptador USB-RJ45 detectado: ${USB_IFACE}"
  info "Configure a interface ${USB_IFACE} como WAN no MikroTik"
else
  warn "Adaptador USB-RJ45 não detectado. Conecte e verifique com: ip link show"
fi

# ============================================================
# 13. DIRETÓRIO DE BACKUP
# ============================================================
info "Criando diretório de backups..."
mkdir -p ${HOSTEL_HOME}/backups
chown ${HOSTEL_USER}:${HOSTEL_USER} ${HOSTEL_HOME}/backups

# Script de backup automático
cat > ${HOSTEL_HOME}/backups/backup-hostel.sh << 'BACKUP'
#!/bin/bash
# Backup diário do Hostel
BACKUP_DIR="/home/sergio/backups"
DATE=$(date +%Y-%m-%d)

# Docker containers
docker export mikrotik-chr | gzip > ${BACKUP_DIR}/mikrotik-${DATE}.tar.gz
docker export freepbx | gzip > ${BACKUP_DIR}/freepbx-${DATE}.tar.gz

# AdGuard config
cp -r /opt/AdGuardHome/AdGuardHome.yaml ${BACKUP_DIR}/adguard-config-${DATE}.yaml 2>/dev/null || true

# Limpar backups antigos (manter 7 dias)
find ${BACKUP_DIR} -name "*.tar.gz" -mtime +7 -delete
find ${BACKUP_DIR} -name "*.yaml" -mtime +7 -delete

echo "Backup ${DATE} concluído"
BACKUP

chmod +x ${HOSTEL_HOME}/backups/backup-hostel.sh
chown ${HOSTEL_USER}:${HOSTEL_USER} ${HOSTEL_HOME}/backups/backup-hostel.sh

# Cron job de backup diário (2h da manhã)
(crontab -l 2>/dev/null; echo "0 2 * * * /home/sergio/backups/backup-hostel.sh >> /home/sergio/backups/backup.log 2>&1") | crontab -

log "Backup automático configurado (diário às 02:00)"

# ============================================================
# 14. VERIFICAÇÕES
# ============================================================
echo ""
echo "============================================================"
echo "  VERIFICAÇÃO FINAL — Hostel"
echo "============================================================"

PASS=0
FAIL=0

check() {
  if eval "$2" &> /dev/null; then
    log "$1"
    ((PASS++))
  else
    warn "$1 — FALHOU"
    ((FAIL++))
  fi
}

check "Docker $(docker --version)" "command -v docker"
check "Cockpit (:9090)" "systemctl is-active cockpit.socket"
check "Netdata (:19999)" "systemctl is-active netdata"
check "MikroTik CHR container" "docker ps -a | grep -q mikrotik-chr"
check "FreePBX container" "docker ps -a | grep -q freepbx"
check "Firewall UFW" "ufw status | grep -q active"
check "Backup script" "[ -f ${HOSTEL_HOME}/backups/backup-hostel.sh ]"
check "Cron de backup" "crontab -l | grep -q backup-hostel"

echo ""
echo "============================================================"
echo "  RESULTADO: ${PASS} OK / ${FAIL} FALHAS"
echo "============================================================"
echo ""

info "Próximos passos:"
echo ""
echo "  1. Configurar MikroTik CHR:"
echo "     docker exec -it mikrotik-chr /bin/bash"
echo "     (ou Winbox → IP do servidor :8291)"
echo "     → Ver guia: ubuntu-hostel-install.md FASE 4"
echo ""
echo "  2. Configurar FreePBX:"
echo "     http://$(hostname -I | awk '{print $1}')"
echo "     → Criar ramais 100-103"
echo "     → Ver guia: ubuntu-hostel-install.md FASE 5"
echo ""
echo "  3. Configurar AdGuard Home:"
echo "     http://$(hostname -I | awk '{print $1}'):3000"
echo "     → Ver guia: ubuntu-hostel-install.md FASE 7"
echo ""
echo "  4. Conectar HT814 no switch e registrar ramais"
echo "     → Ver guia: ubuntu-hostel-install.md FASE 6"
echo ""
echo "  5. Monitoramento:"
echo "     Cockpit:  https://$(hostname -I | awk '{print $1}'):9090"
echo "     Netdata:  http://$(hostname -I | awk '{print $1}'):19999"
echo ""

log "Hostel setup finalizado em $(date)"
