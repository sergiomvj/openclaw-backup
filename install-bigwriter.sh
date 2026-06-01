#!/bin/bash
# ============================================================
# BigWriter — Script de Instalação
# ============================================================
# Rodar APÓS instalar Ubuntu Server 24.04 LTS
#
# Hardware: MiniPC i7 8ª gen | 20GB RAM | SSD 512GB + HD 512GB
# Stack: Ollama + Redis + Celery + FastAPI + Streamlit
#
# Uso:
#   chmod +x install-bigwriter.sh
#   sudo ./install-bigwriter.sh
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

BW_USER="sergio"
BW_HOME="/home/${BW_USER}"
BW_DIR="${BW_HOME}/bigwriter"
SWAP_SIZE="8G"

echo ""
echo "============================================================"
echo "  BigWriter — Instalação"
echo "  Sistema de produção automatizada de conteúdo FBR"
echo "  Executado em: $(date)"
echo "============================================================"
echo ""

# ============================================================
# 1. VERIFICAR ROOT
# ============================================================
if [[ $EUID -ne 0 ]]; then
  err "Rode com sudo: sudo ./install-bigwriter.sh"
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
  build-essential python3 python3-pip python3-venv \
  ca-certificates gnupg \
  lsof rsync jq sqlite3 \
  nginx
log "Dependências instaladas"

# ============================================================
# 4. FIREWALL
# ============================================================
info "Configurando firewall..."
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8000/tcp   # FastAPI
ufw allow 3000/tcp   # Streamlit dashboard
ufw allow 11434/tcp  # Ollama API (interno, pode restringir depois)
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
  usermod -aG docker ${BW_USER}
  systemctl enable docker
  systemctl start docker
  log "Docker instalado"
else
  log "Docker já instalado"
fi

# ============================================================
# 7. NODE.JS (para ferramentas auxiliares)
# ============================================================
info "Instalando Node.js 22..."
if ! command -v node &> /dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  apt install -y nodejs
  log "Node.js $(node -v) instalado"
else
  log "Node.js $(node -v) já instalado"
fi

# ============================================================
# 8. PYTHON + VIRTUAL ENV
# ============================================================
info "Configurando Python..."
python3 -m venv ${BW_HOME}/.venvs/bigwriter 2>/dev/null || python3 -m venv ${BW_HOME}/.venvs/bigwriter
chown -R ${BW_USER}:${BW_USER} ${BW_HOME}/.venvs
log "Virtual environment criado"

# ============================================================
# 9. REDIS (via Docker)
# ============================================================
info "Instalando Redis..."
if ! docker ps | grep -q bigwriter-redis; then
  docker run -d \
    --name bigwriter-redis \
    --restart unless-stopped \
    -p 127.0.0.1:6379:6379 \
    -v bigwriter_redis_data:/data \
    redis:7-alpine redis-server --appendonly yes
  log "Redis rodando na porta 6379"
else
  log "Redis já rodando"
fi

# ============================================================
# 10. OLLAMA
# ============================================================
info "Instalando Ollama..."
if ! command -v ollama &> /dev/null; then
  curl -fsSL https://ollama.com/install.sh | sh
  systemctl enable ollama
  systemctl start ollama
  log "Ollama instalado"
else
  log "Ollama já instalado"
fi

# ============================================================
# 11. BAIXAR MODELOS LLM
# ============================================================
info "Baixando modelos LLM (isso pode demorar bastante)..."
echo ""
echo "  Modelos a instalar:"
echo "  1. gemma4:26b-a4b-q8  (Produtor — ~14 GB)"
echo "  2. qwen2.5:7b         (Revisor  — ~6 GB)"
echo ""
read -p "Baixar os modelos agora? (s/n): " DOWNLOAD_MODELS

if [[ "${DOWNLOAD_MODELS}" == "s" || "${DOWNLOAD_MODELS}" == "S" ]]; then
  info "Baixando Gemma 4 26B A4B Q8 (~14 GB)..."
  su - ${BW_USER} -c "ollama pull gemma4:26b-a4b-q8" || warn "Modelo gemma4 não encontrado com esse nome. Verifique disponível em: ollama list"
  
  info "Baixando Qwen 2.5 7B (~6 GB)..."
  su - ${BW_USER} -c "ollama pull qwen2.5:7b" || warn "Modelo qwen2.5 não encontrado. Verifique disponível em: ollama list"
  
  log "Modelos instalados"
  su - ${BW_USER} -c "ollama list"
else
  warn "Modelos não instalados. Instale depois com:"
  echo "  ollama pull gemma4:26b-a4b-q8"
  echo "  ollama pull qwen2.5:7b"
fi

# ============================================================
# 12. CRIAR ESTRUTURA DO PROJETO
# ============================================================
info "Criando estrutura do projeto..."
mkdir -p ${BW_DIR}
mkdir -p ${BW_DIR}/{bigwriter/{models,pipeline,llm,workers,api/routes,cms,dashboard/components},data/{briefings,artigos,templates},tests,scripts,logs}

# Criar pyproject.toml
cat > ${BW_DIR}/pyproject.toml << 'PYPROJECT'
[project]
name = "bigwriter"
version = "0.1.0"
description = "Sistema de produção automatizada de conteúdo — FBR Inc"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.110.0",
    "uvicorn>=0.29.0",
    "celery>=5.3.0",
    "redis>=5.0.0",
    "httpx>=0.27.0",
    "pydantic>=2.6.0",
    "sqlalchemy>=2.0.0",
    "aiosqlite>=0.19.0",
    "streamlit>=1.32.0",
    "python-dotenv>=1.0.0",
    "markdown>=3.5.0",
    "wordcloud>=1.9.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0.0",
    "pytest-asyncio>=0.23.0",
    "black>=24.0.0",
    "ruff>=0.3.0",
]
PYPROJECT

# Criar .env.example
cat > ${BW_DIR}/.env.example << 'ENVFILE'
# Ollama
OLLAMA_BASE_URL=http://localhost:11434
PRODUCER_MODEL=gemma4:26b-a4b-q8
REVIEWER_MODEL=qwen2.5:7b

# Redis
REDIS_URL=redis://localhost:6379/0

# Database
DATABASE_URL=sqlite+aiosqlite:///./data/bigwriter.db

# API
API_HOST=0.0.0.0
API_PORT=8000

# Dashboard
DASHBOARD_PORT=3000

# Batch
MAX_RETRIES=3
MIN_SCORE_APPROVE=8.0
MIN_SCORE_REWORK=7.0

# Logging
LOG_LEVEL=INFO
ENVFILE

# Criar .env (cópia do example)
cp ${BW_DIR}/.env.example ${BW_DIR}/.env

# Criar config.py
cat > ${BW_DIR}/bigwriter/config.py << 'CONFIG'
import os
from dotenv import load_dotenv

load_dotenv()

# Ollama
OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
PRODUCER_MODEL = os.getenv("PRODUCER_MODEL", "gemma4:26b-a4b-q8")
REVIEWER_MODEL = os.getenv("REVIEWER_MODEL", "qwen2.5:7b")

# Redis
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")

# Database
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite+aiosqlite:///./data/bigwriter.db")

# API
API_HOST = os.getenv("API_HOST", "0.0.0.0")
API_PORT = int(os.getenv("API_PORT", "8000"))

# Batch
MAX_RETRIES = int(os.getenv("MAX_RETRIES", "3"))
MIN_SCORE_APPROVE = float(os.getenv("MIN_SCORE_APPROVE", "8.0"))
MIN_SCORE_REWORK = float(os.getenv("MIN_SCORE_REWORK", "7.0"))

# Paths
DATA_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "data")
BRIEFINGS_DIR = os.path.join(DATA_DIR, "briefings")
ARTIGOS_DIR = os.path.join(DATA_DIR, "artigos")
TEMPLATES_DIR = os.path.join(DATA_DIR, "templates")
CONFIG

# Criar __init__.py em todos os pacotes
find ${BW_DIR}/bigwriter -type d -exec touch {}/__init__.py \;

# Ajustar permissões
chown -R ${BW_USER}:${BW_USER} ${BW_DIR}

log "Estrutura do projeto criada em ${BW_DIR}"

# ============================================================
# 13. INSTALAR DEPENDÊNCIAS PYTHON
# ============================================================
info "Instalando dependências Python..."
su - ${BW_USER} -c "source ${BW_HOME}/.venvs/bigwriter/bin/activate && pip install --upgrade pip && cd ${BW_DIR} && pip install -e ."
log "Dependências Python instaladas"

# ============================================================
# 14. SYSTEMD SERVICES
# ============================================================
info "Criando serviços systemd..."

# Celery worker
cat > /etc/systemd/system/bigwriter-worker.service << 'SERVICE'
[Unit]
Description=BigWriter Celery Worker
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
User=sergio
WorkingDirectory=/home/sergio/bigwriter
ExecStart=/home/sergio/.venvs/bigwriter/bin/celery -A bigwriter.workers.celery_app worker --loglevel=info --concurrency=2
Restart=on-failure
RestartSec=10
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
SERVICE

# Celery beat (scheduler)
cat > /etc/systemd/system/bigwriter-beat.service << 'SERVICE'
[Unit]
Description=BigWriter Celery Beat (Scheduler)
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
User=sergio
WorkingDirectory=/home/sergio/bigwriter
ExecStart=/home/sergio/.venvs/bigwriter/bin/celery -A bigwriter.workers.celery_app beat --loglevel=info
Restart=on-failure
RestartSec=10
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
SERVICE

# FastAPI
cat > /etc/systemd/system/bigwriter-api.service << 'SERVICE'
[Unit]
Description=BigWriter FastAPI
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
User=sergio
WorkingDirectory=/home/sergio/bigwriter
ExecStart=/home/sergio/.venvs/bigwriter/bin/uvicorn bigwriter.api.main:app --host 0.0.0.0 --port 8000
Restart=on-failure
RestartSec=10
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
log "Serviços systemd criados (não habilitados — habilitar após implementar o código)"

# ============================================================
# 15. NGINX REVERSE PROXY (opcional)
# ============================================================
cat > /etc/nginx/sites-available/bigwriter << 'NGINX'
server {
    listen 80;
    server_name bigwriter.local;

    # Dashboard (Streamlit)
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # API (FastAPI)
    location /api/ {
        proxy_pass http://127.0.0.1:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # Ollama (interno)
    location /ollama/ {
        proxy_pass http://127.0.0.1:11434/;
        proxy_set_header Host $host;
        proxy_read_timeout 300s;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/bigwriter /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t 2>/dev/null && log "Nginx configurado" || warn "Nginx config precisa ajuste"

# ============================================================
# 16. VERIFICAÇÕES
# ============================================================
echo ""
echo "============================================================"
echo "  VERIFICAÇÃO FINAL — BigWriter"
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

check "Python $(python3 --version)" "command -v python3"
check "Docker $(docker --version)" "command -v docker"
check "Ollama" "command -v ollama"
check "Redis rodando" "docker ps | grep -q bigwriter-redis"
check "Nginx" "command -v nginx"
check "Firewall" "ufw status | grep -q active"
check "Projeto criado" "[ -d ${BW_DIR}/bigwriter ]"
check "Config criado" "[ -f ${BW_DIR}/bigwriter/config.py ]"
check "pyproject.toml" "[ -f ${BW_DIR}/pyproject.toml ]"
check ".env" "[ -f ${BW_DIR}/.env ]"

echo ""
echo "============================================================"
echo "  RESULTADO: ${PASS} OK / ${FAIL} FALHAS"
echo "============================================================"
echo ""

info "Próximos passos:"
echo "  1. Verificar modelos Ollama:"
echo "     ollama list"
echo ""
echo "  2. Se os modelos não estão instalados:"
echo "     ollama pull gemma4:26b-a4b-q8"
echo "     ollama pull qwen2.5:7b"
echo ""
echo "  3. Testar Ollama manualmente:"
echo "     ollama run qwen2.5:7b 'Escreva um parágrafo sobre IA'"
echo ""
echo "  4. Implementar o código do pipeline:"
echo "     cd ${BW_DIR}"
echo "     # Seguir o PROJECT.md"
echo ""
echo "  5. Quando pronto, habilitar serviços:"
echo "     sudo systemctl enable bigwriter-api bigwriter-worker bigwriter-beat"
echo "     sudo systemctl start bigwriter-api"
echo ""
echo "  6. Acessar:"
echo "     API:       http://$(hostname -I | awk '{print $1}'):8000"
echo "     Dashboard: http://$(hostname -I | awk '{print $1}'):3000"
echo ""

log "BigWriter setup finalizado em $(date)"
