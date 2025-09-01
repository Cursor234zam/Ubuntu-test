#!/bin/bash
set -euo pipefail

# ==========================================
# MARATONA UBUNTU BUILDER
# Sistema similar a Maratona Linux
# Crea una imagen Ubuntu personalizada con
# software preinstalado para programación
# ==========================================

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
WORK_DIR="/srv/maratona"
ROOTFS="$WORK_DIR/rootfs"
SQUASHFS="$WORK_DIR/filesystem.squashfs"
ISO_DIR="$WORK_DIR/iso"
OUTPUT_ISO="$WORK_DIR/maratona-ubuntu.iso"
PACKAGES_LIST="$WORK_DIR/packages.list"
SCRIPTS_DIR="./maratona-scripts"

# Función de logging
log() {
    echo -e "${GREEN}[$(date +%H:%M:%S)]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

# ==========================================
# PASO 1: VERIFICAR PRERREQUISITOS
# ==========================================
check_prerequisites() {
    log "Verificando prerrequisitos..."
    
    local missing_tools=()
    local required_tools=(
        "debootstrap"
        "squashfs-tools"
        "xorriso"
        "isolinux"
        "syslinux-utils"
        "genisoimage"
        "rsync"
        "wget"
        "curl"
    )
    
    for tool in "${required_tools[@]}"; do
        if ! dpkg -l | grep -q "^ii.*$tool"; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log "Instalando herramientas faltantes..."
        sudo apt-get update
        sudo apt-get install -y "${missing_tools[@]}"
    fi
    
    # Verificar espacio en disco (mínimo 10GB)
    available_space=$(df /srv 2>/dev/null | awk 'NR==2 {print $4}' || df / | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt 10485760 ]; then
        error "Espacio insuficiente. Se requieren al menos 10GB libres"
    fi
    
    log "Prerrequisitos verificados ✓"
}

# ==========================================
# PASO 2: CREAR ESTRUCTURA DE DIRECTORIOS
# ==========================================
setup_directories() {
    log "Creando estructura de directorios..."
    
    sudo mkdir -p "$WORK_DIR"
    sudo mkdir -p "$ROOTFS"
    sudo mkdir -p "$ISO_DIR"/{casper,isolinux,install}
    sudo mkdir -p "$SCRIPTS_DIR"
    
    log "Directorios creados ✓"
}

# ==========================================
# PASO 3: CREAR LISTA DE PAQUETES ESTILO MARATONA
# ==========================================
create_packages_list() {
    log "Creando lista de paquetes para instalación..."
    
    cat > "$PACKAGES_LIST" << 'EOF'
# ==========================================
# PAQUETES BASE DEL SISTEMA
# ==========================================
ubuntu-minimal
ubuntu-standard
linux-generic
grub-pc
network-manager
ssh
curl
wget
git
vim
nano
htop
tree
zip
unzip
tar
gzip
bzip2
xz-utils

# ==========================================
# ENTORNO DE ESCRITORIO (LIGERO)
# ==========================================
xfce4
xfce4-terminal
lightdm
firefox
gedit
mousepad

# ==========================================
# COMPILADORES Y LENGUAJES
# ==========================================
build-essential
gcc
g++
gdb
valgrind
make
cmake
automake
autoconf

# C/C++
gcc-multilib
g++-multilib
libstdc++-dev

# Java
default-jdk
default-jre
maven
gradle

# Python
python3
python3-pip
python3-dev
python3-venv
python3-numpy
python3-scipy
python3-matplotlib
python3-pandas
ipython3
jupyter-notebook

# Kotlin
# Se instalará via script

# JavaScript/Node
nodejs
npm

# Go
golang

# Rust
# Se instalará via script

# ==========================================
# IDES Y EDITORES
# ==========================================
code
codeblocks
geany
emacs
sublime-text

# ==========================================
# HERRAMIENTAS DE DESARROLLO
# ==========================================
git-flow
docker.io
docker-compose
postgresql
mysql-server
mongodb
redis-server

# ==========================================
# BIBLIOTECAS DE ALGORITMOS
# ==========================================
libboost-all-dev
libeigen3-dev
libgmp-dev
libgsl-dev

# ==========================================
# HERRAMIENTAS DE COMPETENCIA
# ==========================================
time
bc
dc
gnuplot
graphviz

# ==========================================
# DOCUMENTACIÓN
# ==========================================
manpages-dev
manpages-posix-dev
cpp-doc
gcc-doc
glibc-doc
python3-doc
openjdk-17-doc

# ==========================================
# UTILIDADES ADICIONALES
# ==========================================
screen
tmux
ncdu
iotop
strace
ltrace
tcpdump
wireshark
nmap
netcat
EOF
    
    log "Lista de paquetes creada ✓"
}

# ==========================================
# PASO 4: CREAR SISTEMA BASE UBUNTU
# ==========================================
create_base_system() {
    log "Creando sistema base Ubuntu 22.04..."
    
    if [ ! -f "$ROOTFS/etc/os-release" ]; then
        sudo debootstrap \
            --arch=amd64 \
            --variant=minbase \
            --include=systemd,systemd-sysv,ubuntu-minimal,ubuntu-standard,network-manager,linux-generic \
            jammy \
            "$ROOTFS" \
            http://archive.ubuntu.com/ubuntu/ || error "Fallo en debootstrap"
    else
        warning "Sistema base ya existe, saltando debootstrap"
    fi
    
    log "Sistema base creado ✓"
}

# ==========================================
# PASO 5: CONFIGURAR SISTEMA BASE
# ==========================================
configure_base_system() {
    log "Configurando sistema base..."
    
    # Configurar sources.list
    cat << EOF | sudo tee "$ROOTFS/etc/apt/sources.list" > /dev/null
deb http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-backports main restricted universe multiverse
EOF
    
    # Configurar hostname
    echo "maratona-ubuntu" | sudo tee "$ROOTFS/etc/hostname" > /dev/null
    
    # Configurar hosts
    cat << EOF | sudo tee "$ROOTFS/etc/hosts" > /dev/null
127.0.0.1   localhost
127.0.1.1   maratona-ubuntu
EOF
    
    # Configurar fstab
    cat << EOF | sudo tee "$ROOTFS/etc/fstab" > /dev/null
# /etc/fstab: static file system information.
proc            /proc           proc    defaults        0       0
sysfs           /sys            sysfs   defaults        0       0
devpts          /dev/pts        devpts  defaults        0       0
tmpfs           /run            tmpfs   defaults        0       0
EOF
    
    # Configurar resolv.conf
    echo "nameserver 8.8.8.8" | sudo tee "$ROOTFS/etc/resolv.conf" > /dev/null
    
    log "Sistema base configurado ✓"
}

# ==========================================
# PASO 6: INSTALAR PAQUETES EN CHROOT
# ==========================================
install_packages() {
    log "Instalando paquetes en el sistema..."
    
    # Crear script de instalación
    cat << 'INSTALL_SCRIPT' | sudo tee "$ROOTFS/tmp/install-packages.sh" > /dev/null
#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
export LANG=C.UTF-8

# Actualizar sistema
apt-get update
apt-get upgrade -y

# Instalar paquetes básicos primero
apt-get install -y --no-install-recommends \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    locales \
    sudo

# Configurar locales
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8

# Agregar repositorios necesarios
# VSCode
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list

# Sublime Text
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor > /usr/share/keyrings/sublimehq-archive.gpg
echo "deb [signed-by=/usr/share/keyrings/sublimehq-archive.gpg] https://download.sublimetext.com/ apt/stable/" > /etc/apt/sources.list.d/sublime-text.list

# Actualizar con nuevos repos
apt-get update

# Instalar entorno de escritorio
apt-get install -y --no-install-recommends \
    xfce4 \
    xfce4-terminal \
    lightdm \
    lightdm-gtk-greeter \
    xfce4-power-manager \
    xfce4-screenshooter \
    thunar-volman \
    network-manager-gnome

# Instalar herramientas de desarrollo
apt-get install -y \
    build-essential \
    gcc \
    g++ \
    gdb \
    valgrind \
    make \
    cmake \
    git \
    vim \
    nano \
    emacs \
    wget \
    curl \
    htop \
    tree

# Instalar lenguajes de programación
apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    python3-venv \
    default-jdk \
    nodejs \
    npm \
    golang

# Instalar IDEs
apt-get install -y \
    code \
    codeblocks \
    geany \
    sublime-text || true

# Instalar bibliotecas de desarrollo
apt-get install -y \
    libboost-all-dev \
    libeigen3-dev \
    libgmp-dev \
    libgsl-dev

# Instalar navegador
apt-get install -y firefox

# Limpiar cache
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Instalación de paquetes completada"
INSTALL_SCRIPT
    
    sudo chmod +x "$ROOTFS/tmp/install-packages.sh"
    
    # Montar sistemas necesarios para chroot
    log "Montando sistemas de archivos para chroot..."
    sudo mount --bind /dev "$ROOTFS/dev"
    sudo mount --bind /dev/pts "$ROOTFS/dev/pts"
    sudo mount --bind /proc "$ROOTFS/proc"
    sudo mount --bind /sys "$ROOTFS/sys"
    
    # Ejecutar instalación en chroot
    log "Ejecutando instalación de paquetes (esto puede tomar varios minutos)..."
    sudo chroot "$ROOTFS" /tmp/install-packages.sh || warning "Algunos paquetes pueden haber fallado"
    
    # Desmontar sistemas
    log "Desmontando sistemas de archivos..."
    sudo umount "$ROOTFS/dev/pts" || true
    sudo umount "$ROOTFS/dev" || true
    sudo umount "$ROOTFS/proc" || true
    sudo umount "$ROOTFS/sys" || true
    
    log "Paquetes instalados ✓"
}

# ==========================================
# PASO 7: CONFIGURAR USUARIO MARATONA
# ==========================================
configure_user() {
    log "Configurando usuario maratona..."
    
    cat << 'USER_SCRIPT' | sudo tee "$ROOTFS/tmp/configure-user.sh" > /dev/null
#!/bin/bash
set -e

# Crear usuario maratona
useradd -m -s /bin/bash -G sudo,adm,cdrom,audio,video,plugdev maratona || true

# Establecer contraseña (maratona)
echo "maratona:maratona" | chpasswd

# Configurar sudo sin contraseña para el usuario
echo "maratona ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/maratona

# Crear directorios de trabajo
mkdir -p /home/maratona/{Desktop,Documents,Downloads,workspace,competencia}
chown -R maratona:maratona /home/maratona

# Configurar autologin en LightDM
cat > /etc/lightdm/lightdm.conf << EOF
[Seat:*]
autologin-user=maratona
autologin-user-timeout=0
user-session=xfce
EOF

# Crear plantillas de código
mkdir -p /home/maratona/templates

# Template C++
cat > /home/maratona/templates/template.cpp << 'CPP'
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    // Tu código aquí
    
    return 0;
}
CPP

# Template Python
cat > /home/maratona/templates/template.py << 'PY'
#!/usr/bin/env python3
import sys
input = sys.stdin.readline

def solve():
    # Tu código aquí
    pass

if __name__ == "__main__":
    solve()
PY

# Template Java
cat > /home/maratona/templates/Main.java << 'JAVA'
import java.util.*;
import java.io.*;

public class Main {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        
        // Tu código aquí
        
        sc.close();
    }
}
JAVA

chown -R maratona:maratona /home/maratona/templates

echo "Usuario maratona configurado"
USER_SCRIPT
    
    sudo chmod +x "$ROOTFS/tmp/configure-user.sh"
    sudo chroot "$ROOTFS" /tmp/configure-user.sh
    
    log "Usuario configurado ✓"
}

# ==========================================
# PASO 8: INSTALAR HERRAMIENTAS ADICIONALES
# ==========================================
install_additional_tools() {
    log "Instalando herramientas adicionales..."
    
    cat << 'TOOLS_SCRIPT' | sudo tee "$ROOTFS/tmp/install-tools.sh" > /dev/null
#!/bin/bash
set -e

# Instalar Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || true

# Instalar Kotlin
cd /tmp
wget https://github.com/JetBrains/kotlin/releases/download/v1.9.0/kotlin-compiler-1.9.0.zip
unzip kotlin-compiler-1.9.0.zip
mv kotlinc /opt/
ln -s /opt/kotlinc/bin/kotlin /usr/local/bin/kotlin
ln -s /opt/kotlinc/bin/kotlinc /usr/local/bin/kotlinc
rm kotlin-compiler-1.9.0.zip

# Instalar herramientas de debugging
apt-get install -y strace ltrace tcpdump

# Configurar VS Code para competencias
mkdir -p /home/maratona/.config/Code/User
cat > /home/maratona/.config/Code/User/settings.json << 'VSCODE'
{
    "editor.fontSize": 14,
    "editor.fontFamily": "'Courier New', monospace",
    "editor.tabSize": 4,
    "editor.insertSpaces": true,
    "files.autoSave": "afterDelay",
    "terminal.integrated.fontSize": 14,
    "cpp.default.compilerPath": "/usr/bin/g++",
    "code-runner.executorMap": {
        "cpp": "cd $dir && g++ -std=c++17 -O2 -Wall $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt",
        "python": "python3",
        "java": "cd $dir && javac $fileName && java $fileNameWithoutExt"
    }
}
VSCODE

chown -R maratona:maratona /home/maratona/.config

echo "Herramientas adicionales instaladas"
TOOLS_SCRIPT
    
    sudo chmod +x "$ROOTFS/tmp/install-tools.sh"
    sudo chroot "$ROOTFS" /tmp/install-tools.sh || warning "Algunas herramientas adicionales pueden haber fallado"
    
    log "Herramientas adicionales instaladas ✓"
}

# ==========================================
# PASO 9: CREAR SCRIPTS DE COMPETENCIA
# ==========================================
create_competition_scripts() {
    log "Creando scripts de competencia..."
    
    # Script para compilar y ejecutar
    cat << 'RUNNER' | sudo tee "$ROOTFS/usr/local/bin/run" > /dev/null
#!/bin/bash
# Script para compilar y ejecutar código rápidamente

if [ $# -eq 0 ]; then
    echo "Uso: run archivo.[cpp|py|java]"
    exit 1
fi

file="$1"
filename="${file%.*}"
extension="${file##*.}"

case "$extension" in
    cpp|cc|cxx)
        echo "Compilando C++..."
        g++ -std=c++17 -O2 -Wall "$file" -o "$filename"
        if [ $? -eq 0 ]; then
            echo "Ejecutando..."
            time "./$filename"
        fi
        ;;
    c)
        echo "Compilando C..."
        gcc -O2 -Wall "$file" -o "$filename"
        if [ $? -eq 0 ]; then
            echo "Ejecutando..."
            time "./$filename"
        fi
        ;;
    py)
        echo "Ejecutando Python..."
        time python3 "$file"
        ;;
    java)
        echo "Compilando Java..."
        javac "$file"
        if [ $? -eq 0 ]; then
            echo "Ejecutando..."
            time java "$filename"
        fi
        ;;
    kt)
        echo "Compilando Kotlin..."
        kotlinc "$file" -include-runtime -d "$filename.jar"
        if [ $? -eq 0 ]; then
            echo "Ejecutando..."
            time java -jar "$filename.jar"
        fi
        ;;
    go)
        echo "Ejecutando Go..."
        time go run "$file"
        ;;
    rs)
        echo "Compilando Rust..."
        rustc -O "$file"
        if [ $? -eq 0 ]; then
            echo "Ejecutando..."
            time "./$filename"
        fi
        ;;
    *)
        echo "Extensión no soportada: $extension"
        exit 1
        ;;
esac
RUNNER
    
    sudo chmod +x "$ROOTFS/usr/local/bin/run"
    
    # Script para testing con casos de prueba
    cat << 'TESTER' | sudo tee "$ROOTFS/usr/local/bin/test-solution" > /dev/null
#!/bin/bash
# Script para probar soluciones con casos de prueba

if [ $# -lt 2 ]; then
    echo "Uso: test-solution programa input.txt [output_esperado.txt]"
    exit 1
fi

program="$1"
input="$2"
expected="${3:-}"

# Compilar si es necesario
extension="${program##*.}"
executable="${program%.*}"

case "$extension" in
    cpp|cc|cxx)
        g++ -std=c++17 -O2 -Wall "$program" -o "$executable" || exit 1
        runner="./$executable"
        ;;
    c)
        gcc -O2 -Wall "$program" -o "$executable" || exit 1
        runner="./$executable"
        ;;
    py)
        runner="python3 $program"
        ;;
    java)
        javac "$program" || exit 1
        runner="java ${executable##*/}"
        ;;
    *)
        echo "Tipo de archivo no soportado"
        exit 1
        ;;
esac

# Ejecutar con input
echo "=== EJECUTANDO ==="
output=$($runner < "$input" 2>&1)
echo "$output"

# Comparar con output esperado si se proporciona
if [ -n "$expected" ] && [ -f "$expected" ]; then
    echo ""
    echo "=== COMPARANDO ==="
    expected_output=$(cat "$expected")
    if [ "$output" = "$expected_output" ]; then
        echo "✓ CORRECTO"
    else
        echo "✗ INCORRECTO"
        echo "Esperado:"
        cat "$expected"
    fi
fi
TESTER
    
    sudo chmod +x "$ROOTFS/usr/local/bin/test-solution"
    
    log "Scripts de competencia creados ✓"
}

# ==========================================
# PASO 10: LIMPIAR Y OPTIMIZAR
# ==========================================
cleanup_system() {
    log "Limpiando y optimizando sistema..."
    
    # Limpiar archivos temporales
    sudo rm -rf "$ROOTFS/tmp/*"
    sudo rm -rf "$ROOTFS/var/cache/apt/archives/*.deb"
    sudo rm -rf "$ROOTFS/var/lib/apt/lists/*"
    sudo rm -rf "$ROOTFS/root/.bash_history"
    
    # Actualizar initramfs
    sudo chroot "$ROOTFS" update-initramfs -u -k all 2>/dev/null || true
    
    log "Sistema limpiado ✓"
}

# ==========================================
# PASO 11: CREAR SQUASHFS
# ==========================================
create_squashfs() {
    log "Creando filesystem.squashfs..."
    
    # Eliminar squashfs anterior si existe
    sudo rm -f "$SQUASHFS"
    
    # Crear nuevo squashfs
    sudo mksquashfs "$ROOTFS" "$SQUASHFS" \
        -comp xz \
        -b 1M \
        -noappend \
        -quiet
    
    # Obtener tamaño
    size=$(du -h "$SQUASHFS" | cut -f1)
    log "Squashfs creado: $size ✓"
}

# ==========================================
# PASO 12: CREAR ISO BOOTEABLE
# ==========================================
create_iso() {
    log "Creando ISO booteable..."
    
    # Copiar squashfs a casper
    sudo cp "$SQUASHFS" "$ISO_DIR/casper/filesystem.squashfs"
    
    # Copiar kernel e initrd
    sudo cp "$ROOTFS/boot/vmlinuz"* "$ISO_DIR/casper/vmlinuz" 2>/dev/null || \
        sudo cp "$ROOTFS/boot/vmlinuz" "$ISO_DIR/casper/vmlinuz"
    
    sudo cp "$ROOTFS/boot/initrd"* "$ISO_DIR/casper/initrd" 2>/dev/null || \
        sudo cp "$ROOTFS/boot/initrd.img" "$ISO_DIR/casper/initrd"
    
    # Crear configuración de ISOLINUX
    cat << 'ISOLINUX' | sudo tee "$ISO_DIR/isolinux/isolinux.cfg" > /dev/null
DEFAULT live
LABEL live
  menu label ^Start Maratona Ubuntu
  kernel /casper/vmlinuz
  append initrd=/casper/initrd boot=casper quiet splash ---
LABEL check
  menu label ^Check disc for defects
  kernel /casper/vmlinuz
  append initrd=/casper/initrd boot=casper integrity-check quiet splash ---
LABEL memtest
  menu label Test ^memory
  kernel /install/memtest
LABEL hd
  menu label ^Boot from first hard disk
  localboot 0x80
ISOLINUX
    
    # Copiar archivos de isolinux
    sudo cp /usr/lib/ISOLINUX/isolinux.bin "$ISO_DIR/isolinux/" || \
        sudo cp /usr/lib/syslinux/modules/bios/isolinux.bin "$ISO_DIR/isolinux/"
    
    sudo cp /usr/lib/syslinux/modules/bios/*.c32 "$ISO_DIR/isolinux/" 2>/dev/null || true
    
    # Crear ISO
    sudo xorriso -as mkisofs \
        -r -V "Maratona Ubuntu" \
        -cache-inodes -J -l \
        -b isolinux/isolinux.bin \
        -c isolinux/boot.cat \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        -o "$OUTPUT_ISO" \
        "$ISO_DIR" 2>/dev/null || \
    sudo genisoimage \
        -r -V "Maratona Ubuntu" \
        -cache-inodes -J -l \
        -b isolinux/isolinux.bin \
        -c isolinux/boot.cat \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        -o "$OUTPUT_ISO" \
        "$ISO_DIR"
    
    # Hacer ISO booteable con UEFI
    sudo isohybrid "$OUTPUT_ISO" 2>/dev/null || true
    
    size=$(du -h "$OUTPUT_ISO" | cut -f1)
    log "ISO creada: $OUTPUT_ISO ($size) ✓"
}

# ==========================================
# PASO 13: CREAR SCRIPT DE TESTING
# ==========================================
create_test_script() {
    log "Creando script de testing..."
    
    cat << 'TEST_SCRIPT' > "$WORK_DIR/test-maratona.sh"
#!/bin/bash
# Script para probar Maratona Ubuntu en QEMU/KVM

ISO="$1"
if [ -z "$ISO" ]; then
    ISO="/srv/maratona/maratona-ubuntu.iso"
fi

if [ ! -f "$ISO" ]; then
    echo "Error: No se encuentra el ISO en $ISO"
    exit 1
fi

echo "Iniciando Maratona Ubuntu en máquina virtual..."
echo "Usuario: maratona"
echo "Contraseña: maratona"
echo

# Verificar si KVM está disponible
if [ -e /dev/kvm ]; then
    ACCEL="-enable-kvm"
    echo "Usando aceleración KVM"
else
    ACCEL=""
    echo "KVM no disponible, usando emulación (será más lento)"
fi

# Iniciar VM
qemu-system-x86_64 \
    $ACCEL \
    -m 2048 \
    -cdrom "$ISO" \
    -boot d \
    -vga std \
    -display gtk \
    || qemu-system-x86_64 \
    $ACCEL \
    -m 2048 \
    -cdrom "$ISO" \
    -boot d
TEST_SCRIPT
    
    chmod +x "$WORK_DIR/test-maratona.sh"
    
    log "Script de testing creado ✓"
}

# ==========================================
# FUNCIÓN PRINCIPAL
# ==========================================
main() {
    echo
    echo "╔════════════════════════════════════════╗"
    echo "║     MARATONA UBUNTU BUILDER v1.0       ║"
    echo "║  Sistema Ubuntu para Competencias      ║"
    echo "╚════════════════════════════════════════╝"
    echo
    
    info "Este proceso creará una imagen Ubuntu personalizada"
    info "similar a Maratona Linux con herramientas de programación"
    echo
    
    # Verificar si se ejecuta como root
    if [ "$EUID" -eq 0 ]; then
        error "No ejecutes este script como root. Se pedirá sudo cuando sea necesario."
    fi
    
    # Ejecutar pasos
    check_prerequisites
    setup_directories
    create_packages_list
    create_base_system
    configure_base_system
    install_packages
    configure_user
    install_additional_tools
    create_competition_scripts
    cleanup_system
    create_squashfs
    create_iso
    create_test_script
    
    echo
    echo "╔════════════════════════════════════════╗"
    echo "║         ¡CONSTRUCCIÓN EXITOSA!         ║"
    echo "╚════════════════════════════════════════╝"
    echo
    info "ISO creada en: $OUTPUT_ISO"
    info "Tamaño: $(du -h "$OUTPUT_ISO" | cut -f1)"
    echo
    info "Para probar en máquina virtual:"
    echo "  $WORK_DIR/test-maratona.sh"
    echo
    info "Para grabar en USB (reemplaza /dev/sdX con tu dispositivo):"
    echo "  sudo dd if=$OUTPUT_ISO of=/dev/sdX bs=4M status=progress"
    echo
    info "Credenciales por defecto:"
    echo "  Usuario: maratona"
    echo "  Contraseña: maratona"
    echo
    log "¡Todo listo! 🎉"
}

# Ejecutar
main "$@"