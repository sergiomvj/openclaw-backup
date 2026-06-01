#!/bin/bash
# ============================================================
# FBR — Migração Ubuntu Server: Script de Restauração
# ============================================================
# Rodar APÓS instalar Ubuntu Server 24.04 LTS
# 
# Uso:
#   chmod +x restore-fbr.sh
#   sudo ./restore-fbr.sh
#
# Pré-requisitos:
#   - Ubuntu Server 24.04 LTS instalado
#   - Pendrive com backup-openclaw-2026-06-01.tar.gz conectado
#   - Acesso à internet
# ============================================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }
info() { echo -e "${BLUE}[→]${NC} $1"; }

# ============================================================
# CONFIGURAÇÃO
# ============================================================
OPENCLAW_USER="sergio"
OPENCLAW_HOME="/home/${OPENCLAW_USER}"
BACKUP_FILE="backup-openclaw-2026-06-01.tar.gz"
NODE_MAJOR=22
SWAP_SIZE="8G"

echo ""
echo "============================================================"
echo "  FBR Inc — Restauração Ubuntu Server"
echo "  Executado em: $(date)"
echo "============================================================"
echo ""

# ============================================================
# 1. VERIFICAR ROOT
# ============================================================
info "Verificando permissões..."
if [[ $EUID -ne 0 ]]; then
  err "Rode com sudo: sudo ./restore-fbr.sh"
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
  lsof rsync jq
log "Dependências instaladas"

# ============================================================
# 4. CONFIGURAR FIREWALL
# ============================================================
info "Configurando firewall..."
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 18790/tcp
ufw --force enable
ufw status
log "Firewall configurado"

# ============================================================
# 5. CONFIGURAR SWAP (se não existir)
# ============================================================
info "Verificando swap..."
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
# 6. INSTALAR DOCKER
# ============================================================
info "Instalando Docker..."
if ! command -v docker &> /dev/null; then
  curl -fsSL https://get.docker.com | bash
  usermod -aG docker ${OPENCLAW_USER}
  systemctl enable docker
  systemctl start docker
  log "Docker instalado"
else
  log "Docker já instalado"
fi

# ============================================================
# 7. INSTALAR NODE.JS 22
# ============================================================
info "Instalando Node.js ${NODE_MAJOR}..."
if ! command -v node &> /dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash -
  apt install -y nodejs
  log "Node.js $(node -v) instalado"
else
  log "Node.js $(node -v) já instalado"
fi

# ============================================================
# 8. INSTALAR OPENCLAW
# ============================================================
info "Instalando OpenClaw..."
if ! command -v openclaw &> /dev/null; then
  npm install -g openclaw
  log "OpenClaw $(openclaw --version) instalado"
else
  log "OpenClaw $(openclaw --version) já instalado"
fi

# ============================================================
# 9. MONTAR PENDRIVE E RESTAURAR BACKUP
# ============================================================
info "Procurando backup no pendrive..."
mkdir -p /mnt/usb

# Tentar montar automaticamente
USB_FOUND=false
for dev in /dev/sdb1 /dev/sdc1 /dev/sdd1 /dev/sde1; do
  if [[ -b ${dev} ]]; then
    mount ${dev} /mnt/usb 2>/dev/null || true
    
    if [[ -f /mnt/usb/${BACKUP_FILE} ]]; then
      USB_FOUND=true
      log "Backup encontrado em ${dev}"
      break
    fi
    
    # Procurar em subpastas
    FOUND=$(find /mnt/usb -name "${BACKUP_FILE}" -type f 2>/dev/null | head -1)
    if [[ -n ${FOUND} ]]; then
      BACKUP_PATH=${FOUND}
      USB_FOUND=true
      log "Backup encontrado: ${FOUND}"
      break
    fi
    
    umount /mnt/usb 2>/dev/null || true
  fi
done

if [[ ${USB_FOUND} == false ]]; then
  # Tentar encontrar em partições já montadas
  FOUND=$(find /media -name "${BACKUP_FILE}" -type f 2>/dev/null | head -1)
  if [[ -n ${FOUND} ]]; then
    BACKUP_PATH=${FOUND}
    USB_FOUND=true
    log "Backup encontrado: ${FOUND}"
  fi
fi

if [[ ${USB_FOUND} == false ]]; then
  echo ""
  warn "Backup não encontrado automaticamente."
  echo "  Opções:"
  echo "  1. Conecte o pendrive e reexecute este script"
  echo "  2. Baixe do GitHub:"
  echo "     su - ${OPENCLAW_USER}"
  echo "     git clone https://github.com/sergiomvj/openclaw-backup.git /tmp/openclaw-restore"
  echo "     cp /tmp/openclaw-restore/${BACKUP_FILE} /tmp/"
  echo ""
  echo "  Depois rode a restauração manual:"
  echo "     cd /home/${OPENCLAW_USER}/.openclaw"
  echo "     tar xzf /tmp/${BACKUP_FILE}"
  echo "     openclaw memory index --force"
  echo ""
  err "Pendrive com backup não encontrado"
fi

# ============================================================
# 10. RESTAURAR BACKUP
# ============================================================
info "Restaurando backup..."
mkdir -p ${OPENCLAW_HOME}/.openclaw

# Se BACKUP_PATH não foi setado, usar o do pendrive
if [[ -z ${BACKUP_PATH} ]]; then
  BACKUP_PATH="/mnt/usb/${BACKUP_FILE}"
fi

# Copiar pro tmp (mais rápido que ler direto do USB)
cp "${BACKUP_PATH}" /tmp/${BACKUP_FILE}

# Extrair
cd ${OPENCLAW_HOME}/.openclaw
tar xzf /tmp/${BACKUP_FILE}

# Ajustar permissões
chown -R ${OPENCLAW_USER}:${OPENCLAW_USER} ${OPENCLAW_HOME}/.openclaw

# Limpar
rm /tmp/${BACKUP_FILE}
umount /mnt/usb 2>/dev/null || true

log "Backup restaurado"

# ============================================================
# 11. COPIAR SKILLS E DOCS DO GITHUB (complementar)
# ============================================================
info "Clonando repo do GitHub..."
if command -v git &> /dev/null; then
  su - ${OPENCLAW_USER} -c "
    if [[ ! -d ${OPENCLAW_HOME}/openclaw-backup ]]; then
      git clone https://github.com/sergiomvj/openclaw-backup.git ${OPENCLAW_HOME}/openclaw-backup 2>/dev/null || true
    fi
  "
  log "Repo GitHub clonado"
else
  warn "Git não disponível, repo não clonado"
fi

# ============================================================
# 12. RECONSTRUIR ÍNDICE DE MEMÓRIA
# ============================================================
info "Reconstruindo índice de memória..."
su - ${OPENCLAW_USER} -c "openclaw memory index --force" 2>/dev/null || warn "Índice será reconstruído no primeiro start do gateway"
log "Índice de memória processado"

# ============================================================
# 13. INSTALAR GATEWAY COMO SERVIÇO SYSTEMD
# ============================================================
info "Configurando OpenClaw como serviço systemd..."
su - ${OPENCLAW_USER} -c "openclaw gateway install" 2>/dev/null || {
  # Criar service manualmente se o comando não existir
  mkdir -p /home/${OPENCLAW_USER}/.config/systemd/user
  cat > /home/${OPENCLAW_USER}/.config/systemd/user/openclaw-gateway.service << 'SERVICE'
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/openclaw gateway --foreground
Restart=on-failure
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=default.target
SERVICE
  chown -R ${OPENCLAW_USER}:${OPENCLAW_USER} /home/${OPENCLAW_USER}/.config
  log "Service file criado manualmente"
}

# Habilitar lingering (serviço roda mesmo sem login)
loginctl enable-linger ${OPENCLAW_USER} 2>/dev/null || true

log "Serviço systemd configurado"

# ============================================================
# 14. INSTALAR EASYPANEL
# ============================================================
info "Instalando Easypanel..."
read -p "Instalar Easypanel agora? (s/n): " INSTALL_EASYPANEL
if [[ "${INSTALL_EASYPANEL}" == "s" || "${INSTALL_EASYPANEL}" == "S" ]]; then
  curl -fsSL https://get.easypanel.io | bash
  log "Easypanel instalado — acesse http://$(hostname -I | awk '{print $1}')"
else
  warn "Easypanel pulado. Instale depois com: curl -fsSL https://get.easypanel.io | bash"
fi

# ============================================================
# 15. VERIFICAÇÕES FINAIS
# ============================================================
echo ""
echo "============================================================"
echo "  VERIFICAÇÃO FINAL"
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

check "Node.js $(node -v)" "command -v node"
check "Docker $(docker --version)" "command -v docker"
check "Git $(git --version)" "command -v git"
check "OpenClaw" "command -v openclaw"
check "Firewall UFW" "ufw status | grep -q active"
check "MEMORY.md" "[ -f ${OPENCLAW_HOME}/.openclaw/workspace/MEMORY.md ]"
check "Skills (pipeline-fbr)" "[ -f ${OPENCLAW_HOME}/.openclaw/workspace/skills/pipeline-fbr/SKILL.md ]"
check "Skills (capta-leads)" "[ -f ${OPENCLAW_HOME}/.openclaw/workspace/skills/capta-leads/SKILL.md ]"
check "Skills (sales-leads)" "[ -f ${OPENCLAW_HOME}/.openclaw/workspace/skills/sales-leads/SKILL.md ]"
check "Docs (OpenClaw Learn)" "[ -f '${OPENCLAW_HOME}/.openclaw/workspace/docs/2026-06-01 - OpenClaw Learn.md' ]"
check "Docs (Migração)" "[ -f '${OPENCLAW_HOME}/.openclaw/workspace/docs/2026-06-01 - Migração Ubuntu Server.md' ]"
check "openclaw.json" "[ -f ${OPENCLAW_HOME}/.openclaw/openclaw.json ]"
check "Índice de memória" "[ -f ${OPENCLAW_HOME}/.openclaw/memory/main.sqlite ]"
check "Chave GitHub" "[ -f ${OPENCLAW_HOME}/.openclaw/secrets/github-app.pem ]"
check "Backup GitHub" "[ -d ${OPENCLAW_HOME}/openclaw-backup ]"

echo ""
echo "============================================================"
echo "  RESULTADO: ${PASS} OK / ${FAIL} FALHAS"
echo "============================================================"
echo ""

if [[ ${FAIL} -eq 0 ]]; then
  log "TUDO OK — Migração completa!"
  echo ""
  info "Próximos passos:"
  echo "  1. Iniciar gateway:"
  echo "     su - ${OPENCLAW_USER}"
  echo "     systemctl --user start openclaw-gateway"
  echo "     systemctl --user enable openclaw-gateway"
  echo ""
  echo "  2. Acessar dashboard:"
  echo "     http://$(hostname -I | awk '{print $1}'):18790"
  echo ""
  echo "  3. Conversar com o David e validar:"
  echo "     'O que você lembra sobre a FBR?'"
  echo ""
  echo "  4. Configurar Easypanel (se não instalou):"
  echo "     curl -fsSL https://get.easypanel.io | bash"
  echo ""
  echo "  5. Configurar DNS Cloudflare apontando pra este servidor"
else
  warn "${FAIL} verificações falharam. Revise acima."
  echo ""
  info "Para restauração manual do backup:"
  echo "  cd ${OPENCLAW_HOME}/.openclaw"
  echo "  tar xzf /tmp/${BACKUP_FILE}"
  echo "  openclaw memory index --force"
fi

echo ""
echo "Documento completo: ${OPENCLAW_HOME}/.openclaw/workspace/docs/2026-06-01 - Migração Ubuntu Server.md"
echo "Backup no GitHub: https://github.com/sergiomvj/openclaw-backup (privado)"
echo ""
log "Script finalizado em $(date)"
