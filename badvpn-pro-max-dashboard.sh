#!/bin/bash
# BADVPN PRO MAX + DASHBOARD
# Todo en uno: instalación, gestión, Turbo, optimización UDP y Dashboard

SERVICE_DIR="/etc/systemd/system"
BIN="/usr/bin/badvpn-udpgw"
LOG="/var/log/badvpn.log"
DASHBOARD="/opt/badvpn-dashboard.py"

# Colores
ROJO="\e[31m"
VERDE="\e[32m"
AMARILLO="\e[33m"
AZUL="\e[34m"
MORADO="\e[35m"
RESET="\e[0m"

function log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG
}

function banner() {
    clear
    echo -e "${MORADO}==============================================${RESET}"
    echo -e "${VERDE}         BADVPN PRO MAX – MENU ${RESET}"
    echo -e "${MORADO}==============================================${RESET}"
}

function check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${ROJO}Debes ejecutar este script como root${RESET}"
        exit 1
    fi
}

function check_installed() {
    [[ -x "$BIN" ]]
}

# ==================== INSTALACIÓN BADVPN ====================
function install_badvpn() {
    banner
    echo -e "${AMARILLO}Instalando dependencias...${RESET}"
    log "Instalando dependencias"
    apt update -y && apt install -y build-essential cmake git python3 python3-pip net-tools lsof >/dev/null 2>&1
    pip3 install flask psutil >/dev/null 2>&1

    echo -e "${AMARILLO}Descargando BadVPN...${RESET}"
    cd /opt
    [[ ! -d "/opt/badvpn" ]] && git clone https://github.com/ambrop72/badvpn.git >/dev/null 2>&1
    cd badvpn
    echo -e "${AMARILLO}Compilando BadVPN...${RESET}"
    cmake . -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 >/dev/null 2>&1
    make >/dev/null 2>&1
    cp udpgw/badvpn-udpgw $BIN
    chmod +x $BIN

    echo -e "${VERDE}✔ BadVPN instalado${RESET}"
    log "BadVPN instalado"
}

# ==================== GESTIÓN PUERTOS ====================
function add_port() {
    banner
    read -p "Puerto a agregar: " port
    [[ ! "$port" =~ ^[0-9]+$ ]] && { echo -e "${ROJO}Puerto inválido${RESET}"; return; }
cat > ${SERVICE_DIR}/badvpn-${port}.service <<EOF
[Unit]
Description=BadVPN UDPGW en puerto ${port}
After=network.target
[Service]
ExecStart=${BIN} --listen-addr 127.0.0.1:${port}
Restart=always
[Install]
WantedBy=multi-user.target
EOF
    systemctl enable badvpn-${port}.service >/dev/null 2>&1
    systemctl start badvpn-${port}.service >/dev/null 2>&1
    echo -e "${VERDE}✔ Puerto ${port} agregado${RESET}"
    log "Puerto ${port} agregado"
}

function remove_port() {
    banner
    read -p "Puerto a eliminar: " port
    systemctl disable --now badvpn-${port}.service >/dev/null 2>&1
    rm -f ${SERVICE_DIR}/badvpn-${port}.service
    systemctl daemon-reload
    echo -e "${VERDE}✔ Puerto ${port} eliminado${RESET}"
    log "Puerto eliminado"
}

function list_ports() {
    banner
    echo -e "${AZUL}Puertos activos:${RESET}"
    ls ${SERVICE_DIR} | grep badvpn | sed 's/.service//g'
}

function status_port() {
    banner
    read -p "Puerto: " port
    systemctl status badvpn-${port}.service
}

# ==================== OPTIMIZACIÓN UDP ====================
function optimize_udp() {
    banner
    echo -e "${AMARILLO}Aplicando optimización UDP...${RESET}"
    sysctl -w net.core.rmem_max=26214400
    sysctl -w net.core.wmem_max=26214400
    sysctl -w net.core.rmem_default=6291456
    sysctl -w net.core.wmem_default=6291456
    sysctl -w net.core.netdev_max_backlog=50000
    sysctl -w net.ipv4.udp_rmem_min=16384
    sysctl -w net.ipv4.udp_wmem_min=16384
    sysctl -w net.ipv4.udp_mem="2097152 4194304 8388608"
    sysctl -w net.ipv4.tcp_fastopen=3
    sysctl -w net.ipv4.ip_forward=1
cat > /etc/sysctl.d/99-badvpn-udp.conf <<EOF
net.core.rmem_max=26214400
net.core.wmem_max=26214400
net.core.rmem_default=6291456
net.core.wmem_default=6291456
net.core.netdev_max_backlog=50000
net.ipv4.udp_rmem_min=16384
net.ipv4.udp_wmem_min=16384
net.ipv4.udp_mem=2097152 4194304 8388608
net.ipv4.tcp_fastopen=3
net.ipv4.ip_forward=1
EOF
    sysctl --system >/dev/null 2>&1
    echo -e "${VERDE}✔ Optimización UDP aplicada${RESET}"
    log "Optimización UDP aplicada"
}

# ==================== MODO TURBO ====================
function modo_turbo_badvpn() {
    banner
    echo -e "${ROJO}🔥 ACTIVANDO MODO TURBO 🔥${RESET}"
    read -p "Puerto Turbo (7200-7300 recomendado): " turbo_port
    sysctl -w net.core.rmem_max=67108864
    sysctl -w net.core.wmem_max=67108864
    sysctl -w net.core.netdev_max_backlog=200000
    sysctl -w net.ipv4.udp_rmem_min=32768
    sysctl -w net.ipv4.udp_wmem_min=32768
    sysctl -w net.ipv4.udp_mem="4194304 8388608 16777216"
    sysctl -w net.core.optmem_max=65536
cat > /etc/sysctl.d/99-badvpn-turbo.conf <<EOF
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.core.netdev_max_backlog=200000
net.ipv4.udp_rmem_min=32768
net.ipv4.udp_wmem_min=32768
net.ipv4.udp_mem=4194304 8388608 16777216
net.core.optmem_max=65536
EOF
    sysctl --system >/dev/null 2>&1
cat > ${SERVICE_DIR}/badvpn-turbo-${turbo_port}.service <<EOF
[Unit]
Description=BadVPN TURBO en puerto ${turbo_port}
After=network.target
[Service]
ExecStart=/usr/bin/chrt -f 50 $BIN --listen-addr 127.0.0.1:${turbo_port} --max-clients 500 --client-socket-buffer 1048576 --worker-threads 8
Nice=-15
CPUAffinity=0 1 2 3
Restart=always
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable badvpn-turbo-${turbo_port}.service >/dev/null 2>&1
    systemctl start badvpn-turbo-${turbo_port}.service >/dev/null 2>&1
    echo -e "${VERDE}✔ MODO TURBO activo en puerto ${turbo_port}${RESET}"
}

# ==================== DASHBOARD WEB ====================
function setup_dashboard() {
    banner
    echo -e "${AMARILLO}Configurando Dashboard web...${RESET}"
mkdir -p /opt
cat > $DASHBOARD <<'EOF'
#!/usr/bin/env python3
from flask import Flask, render_template_string
import subprocess, psutil

app = Flask(__name__)
TEMPLATE = """
<html><head><title>BadVPN Dashboard</title><meta http-equiv="refresh" content="5">
<style>body{background:#1e1e1e;color:#f0f0f0;font-family:Arial;}table{border-collapse:collapse;width:80%;margin:auto;}
th,td{border:1px solid #555;padding:8px;text-align:center;}th{background:#333;}tr:nth-child(even){background:#222;}
</style></head><body>
<h1>BadVPN Dashboard</h1>
<h2>Servicios BadVPN</h2><table><tr><th>Servicio</th><th>Estado</th><th>PID</th><th>CPU%</th><th>Mem%</th></tr>
{% for s in services %}<tr><td>{{s.name}}</td><td>{{s.status}}</td><td>{{s.pid}}</td><td>{{s.cpu}}</td><td>{{s.mem}}</td></tr>{% endfor %}
</table>
<h2>Puertos UDP</h2><table><tr><th>Puerto</th><th>PID</th><th>Proceso</th></tr>{% for p in udp_ports %}<tr><td>{{p.port}}</td><td>{{p.pid}}</td><td>{{p.proc}}</td></tr>{% endfor %}</table>
</body></html>
"""
def get_services():
    result=[]
    output=subprocess.getoutput("systemctl list-units --type=service --no-pager | grep badvpn")
    for line in output.splitlines():
        parts=line.split()
        name=parts[0]
        status=parts[3] if len(parts)>3 else "unknown"
        pid,cpu,mem="-","-","-"
        try:
            pid_cmd=int(subprocess.getoutput(f"systemctl show -p MainPID {name} | cut -d'=' -f2"))
            if pid_cmd>0:
                p=psutil.Process(pid_cmd)
                pid=pid_cmd
                cpu=round(p.cpu_percent(interval=0.1),1)
                mem=round(p.memory_percent(),1)
        except: pass
        result.append({"name":name,"status":status,"pid":pid,"cpu":cpu,"mem":mem})
    return result
def get_udp_ports():
    result=[]
    output=subprocess.getoutput("netstat -anu | grep 127.0.0.1")
    for line in output.splitlines():
        parts=line.split()
        if len(parts)>=4:
            addr=parts[3]
            port=addr.split(":")[-1]
            pid,proc="-","-"
            try:
                lsof_out=subprocess.getoutput(f"lsof -i UDP:{port} -t")
                if lsof_out: pid=int(lsof_out.strip()); proc=psutil.Process(pid).name()
            except: pass
            result.append({"port":port,"pid":pid,"proc":proc})
    return result
@app.route("/")
def index():
    return render_template_string(TEMPLATE, services=get_services(), udp_ports=get_udp_ports())
if __name__=="__main__":
    app.run(host="0.0.0.0", port=8080)
EOF
    chmod +x $DASHBOARD
    echo -e "${VERDE}✔ Dashboard listo en /opt/badvpn-dashboard.py (http://<IP>:8080)${RESET}"
}

function launch_dashboard() {
    banner
    echo -e "${AMARILLO}Iniciando Dashboard en segundo plano...${RESET}"
    nohup python3 $DASHBOARD >/dev/null 2>&1 &
    echo -e "${VERDE}✔ Dashboard ejecutándose en http://<IP>:8080${RESET}"
}

# ==================== MENÚ ====================
function menu() {
    banner
    echo -e "${AMARILLO}1)${RESET} Instalar BadVPN"
    echo -e "${AMARILLO}2)${RESET} Agregar puerto"
    echo -e "${AMARILLO}3)${RESET} Eliminar puerto"
    echo -e "${AMARILLO}4)${RESET} Listar puertos"
    echo -e "${AMARILLO}5)${RESET} Estado de un puerto"
    echo -e "${AMARILLO}6)${RESET} Ver log"
    echo -e "${AMARILLO}7)${RESET} Optimizar rendimiento UDP"
    echo -e "${AMARILLO}8)${RESET} Activar Modo TURBO"
    echo -e "${AMARILLO}9)${RESET} Configurar Dashboard"
    echo -e "${AMARILLO}10)${RESET} Lanzar Dashboard"
    echo -e "${AMARILLO}11)${RESET} Salir"
    echo ""
    read -p "Opción: " op
    case $op in
        1) install_badvpn ;;
        2) check_installed && add_port || echo -e "${ROJO}Primero instala BadVPN${RESET}" ;;
        3) remove_port ;;
        4) list_ports ;;
        5) status_port ;;
        6) less $LOG ;;
        7) optimize_udp ;;
        8) modo_turbo_badvpn ;;
        9) setup_dashboard ;;
        10) launch_dashboard ;;
        11) exit ;;
        *) echo -e "${ROJO}Opción inválida${RESET}" ;;
    esac
    read -p "ENTER para continuar..." 
    menu
}

check_root
menu
