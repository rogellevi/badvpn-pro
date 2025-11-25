#!/bin/bash
# BADVPN PRO MAX – Instalador, gestor, optimizador y modo turbo

SERVICE_DIR="/etc/systemd/system"
BIN="/usr/bin/badvpn-udpgw"
LOG="/var/log/badvpn.log"

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
    if [[ -x "$BIN" ]]; then
        return 0
    else
        return 1
    fi
}

function install_badvpn() {
    banner
    echo -e "${AMARILLO}Instalando dependencias...${RESET}"
    log "Instalando dependencias"
    apt update -y && apt install -y build-essential cmake git >> $LOG 2>&1

    echo -e "${AMARILLO}Descargando BadVPN...${RESET}"
    log "Descargando BadVPN"

    cd /opt
    if [[ ! -d "/opt/badvpn" ]]; then
        git clone https://github.com/ambrop72/badvpn.git >> $LOG 2>&1
    fi

    cd badvpn
    echo -e "${AMARILLO}Compilando BadVPN (puede tardar)...${RESET}"
    log "Compilando BadVPN"

    cmake . -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 >> $LOG 2>&1
    make >> $LOG 2>&1

    cp udpgw/badvpn-udpgw $BIN
    chmod +x $BIN

    echo -e "${VERDE}✔ BadVPN instalado correctamente${RESET}"
    log "BadVPN instalado exitosamente"
}

function add_port() {
    banner
    read -p "Puerto a agregar: " port

    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        echo -e "${ROJO}Puerto inválido${RESET}"
        return
    fi

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

    systemctl enable badvpn-${port}.service >> $LOG 2>&1
    systemctl start badvpn-${port}.service >> $LOG 2>&1

    echo -e "${VERDE}✔ Puerto ${port} agregado y ejecutándose${RESET}"
    log "Puerto ${port} agregado"
}

function remove_port() {
    banner
    read -p "Puerto a eliminar: " port

    systemctl disable --now badvpn-${port}.service >> $LOG 2>&1
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

function optimize_udp() {
    banner
    echo -e "${AMARILLO}Optimizando sistema para tráfico UDP...${RESET}"
    log "Aplicando optimización UDP"

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

function modo_turbo_badvpn() {
    banner
    echo -e "${ROJO}🔥 ACTIVANDO MODO TURBO 🔥${RESET}"
    log "Modo turbo activado"

    read -p "Puerto Turbo (recomendado: 7200–7300): " turbo_port

    echo -e "${AMARILLO}Aplicando nivel TURBO al kernel...${RESET}"

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
ExecStart=/usr/bin/chrt -f 50 $BIN --listen-addr 127.0.0.1:${turbo_port} \
--max-clients 500 --client-socket-buffer 1048576 --worker-threads 8
Nice=-15
CPUAffinity=0 1 2 3
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable badvpn-turbo-${turbo_port}.service >> $LOG 2>&1
    systemctl start badvpn-turbo-${turbo_port}.service >> $LOG 2>&1

    echo -e "${VERDE}✔ MODO TURBO activo en puerto ${turbo_port}${RESET}"
    echo -e "${VERDE}✔ 8 hilos de procesamiento${RESET}"
    echo -e "${VERDE}✔ Afinidad CPU (Core 0–3)${RESET}"
    echo -e "${VERDE}✔ Prioridad alta del kernel${RESET}"
}

function menu() {
    banner
    echo -e "${AMARILLO}1)${RESET} Instalar BadVPN"
    echo -e "${AMARILLO}2)${RESET} Agregar puerto"
    echo -e "${AMARILLO}3)${RESET} Eliminar puerto"
    echo -e "${AMARILLO}4)${RESET} Listar puertos"
    echo -e "${AMARILLO}5)${RESET} Estado de un puerto"
    echo -e "${AMARILLO}6)${RESET} Ver log"
    echo -e "${AMARILLO}7)${RESET} Optimizar rendimiento UDP"
    echo -e "${AMARILLO}8)${RESET} Activar Modo TURBO ${ROJO}(Ultra Boost)${RESET}"
    echo -e "${AMARILLO}9)${RESET} Salir"
    echo ""
    read -p "Opción: " op

    case $op in
        1) install_badvpn ;;
        2) if check_installed; then add_port; else echo -e "${ROJO}Primero instala BadVPN${RESET}"; fi ;;
        3) remove_port ;;
        4) list_ports ;;
        5) status_port ;;
        6) less $LOG ;;
        7) optimize_udp ;;
        8) modo_turbo_badvpn ;;
        9) exit ;;
        *) echo -e "${ROJO}Opción inválida${RESET}" ;;
    esac

    read -p "Presiona ENTER para continuar..."
    menu
}

check_root
menu
