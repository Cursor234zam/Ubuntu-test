#!/bin/bash
set -euo pipefail

# ==========================================
# FIX PARA EL ERROR DE BOOT
# ==========================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +%H:%M:%S)]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
info() { echo -e "${BLUE}[INFO]${NC} $*"; }

# Configuración
ROOTFS=/srv/lab/rootfs
INITRAMFS=/srv/lab/initramfs
SQUASH=$ROOTFS.squashfs
ZIPFILE=./scripts.zip

echo "╔════════════════════════════════════════╗"
echo "║     SOLUCIONANDO PROBLEMAS DE BOOT     ║"
echo "╚════════════════════════════════════════╝"
echo

# ==========================================
# PASO 1: VERIFICAR PRERREQUISITOS
# ==========================================
log "Verificando prerrequisitos..."

if [ ! -d "$INITRAMFS" ]; then
    error "No existe $INITRAMFS. Ejecuta primero el script de creación."
fi

if [ ! -f "$SQUASH" ]; then
    warning "No existe $SQUASH, creándolo..."
    if [ ! -d "$ROOTFS" ]; then
        error "No existe $ROOTFS. Necesitas crear el sistema base primero."
    fi
    sudo mksquashfs "$ROOTFS" "$SQUASH" -comp xz -b 1M -noappend
fi

# ==========================================
# PASO 2: LIMPIAR Y RECREAR ESTRUCTURA
# ==========================================
log "Recreando estructura de directorios..."

sudo rm -rf "$INITRAMFS"
sudo mkdir -p "$INITRAMFS"/{bin,sbin,usr/bin,usr/sbin,lib,lib64,lib/x86_64-linux-gnu}
sudo mkdir -p "$INITRAMFS"/{proc,sys,dev,run,tmp,work,upper,newroot,var/log}
sudo mkdir -p "$INITRAMFS"/mnt

# ==========================================
# PASO 3: INSTALAR BUSYBOX ESTÁTICO
# ==========================================
log "Instalando busybox estático..."

# Verificar si busybox-static está instalado
if ! dpkg -l | grep -q busybox-static; then
    sudo apt-get update
    sudo apt-get install -y busybox-static
fi

# Copiar busybox estático (no necesita bibliotecas)
sudo cp /bin/busybox "$INITRAMFS/bin/busybox"

# Crear TODOS los enlaces simbólicos de busybox
log "Creando enlaces de busybox..."
for cmd in $(sudo chroot "$INITRAMFS" /bin/busybox --list); do
    sudo ln -sf /bin/busybox "$INITRAMFS/bin/$cmd" 2>/dev/null || true
    sudo ln -sf /bin/busybox "$INITRAMFS/sbin/$cmd" 2>/dev/null || true
done

# ==========================================
# PASO 4: COPIAR BINARIOS ADICIONALES Y DEPENDENCIAS
# ==========================================
log "Copiando binarios adicionales con sus dependencias..."

# Función para copiar un binario con todas sus dependencias
copy_binary_with_deps() {
    local binary="$1"
    local dest_dir="$2"
    
    if [ ! -f "$binary" ]; then
        warning "No se encuentra $binary"
        return 1
    fi
    
    # Copiar el binario
    sudo cp "$binary" "$dest_dir/" 2>/dev/null || return 1
    
    # Copiar las dependencias
    ldd "$binary" 2>/dev/null | grep -oE '/[^ ]+' | while read lib; do
        if [ -f "$lib" ]; then
            local libdir=$(dirname "$lib")
            sudo mkdir -p "$INITRAMFS$libdir"
            sudo cp -n "$lib" "$INITRAMFS$lib" 2>/dev/null || true
        fi
    done
}

# Copiar bash (importante para scripts más complejos)
if [ -f /bin/bash ]; then
    copy_binary_with_deps /bin/bash "$INITRAMFS/bin"
elif [ -f /usr/bin/bash ]; then
    copy_binary_with_deps /usr/bin/bash "$INITRAMFS/bin"
fi

# Copiar unzip
if [ -f /usr/bin/unzip ]; then
    copy_binary_with_deps /usr/bin/unzip "$INITRAMFS/usr/bin"
fi

# Copiar tee
if [ -f /usr/bin/tee ]; then
    copy_binary_with_deps /usr/bin/tee "$INITRAMFS/usr/bin"
fi

# Copiar herramientas de red (pueden ser útiles)
for tool in wget curl aria2c; do
    if which $tool >/dev/null 2>&1; then
        copy_binary_with_deps "$(which $tool)" "$INITRAMFS/usr/bin"
    fi
done

# Copiar el intérprete de enlaces dinámicos
if [ -f /lib64/ld-linux-x86-64.so.2 ]; then
    sudo mkdir -p "$INITRAMFS/lib64"
    sudo cp /lib64/ld-linux-x86-64.so.2 "$INITRAMFS/lib64/"
fi

# Copiar bibliotecas básicas que casi siempre se necesitan
for lib in /lib/x86_64-linux-gnu/lib{c,m,dl,pthread,rt,util}.so.*; do
    if [ -f "$lib" ]; then
        sudo cp -n "$lib" "$INITRAMFS/lib/x86_64-linux-gnu/" 2>/dev/null || true
    fi
done

# ==========================================
# PASO 5: COPIAR ARCHIVOS NECESARIOS
# ==========================================
log "Copiando archivos necesarios..."

# Copiar squashfs
sudo cp "$SQUASH" "$INITRAMFS/filesystem.squashfs"

# Copiar scripts.zip si existe
if [ -f "$ZIPFILE" ]; then
    log "Copiando $ZIPFILE..."
    sudo cp "$ZIPFILE" "$INITRAMFS/scripts.zip"
else
    warning "No se encontró $ZIPFILE"
fi

# ==========================================
# PASO 6: CREAR INIT SCRIPT MEJORADO
# ==========================================
log "Creando script init robusto..."

cat <<'INIT_SCRIPT' | sudo tee "$INITRAMFS/init" >/dev/null
#!/bin/busybox sh
# Script init usando busybox sh para máxima compatibilidad

# Función de logging
log() {
    echo "[INIT] $*"
}

# Función para panic
panic() {
    echo "[PANIC] $*"
    echo "[PANIC] Iniciando shell de emergencia..."
    echo "[PANIC] Escribe 'exit' para reintentar el boot"
    /bin/busybox sh
    # Si el usuario sale del shell, reintentar
    exec /init
}

# Decirle a busybox que instale todos sus applets
/bin/busybox --install -s

# Verificar que tenemos las herramientas básicas
log "Verificando herramientas básicas..."
for tool in mount mkdir cat ln; do
    if ! which $tool >/dev/null 2>&1; then
        panic "Herramienta crítica no encontrada: $tool"
    fi
done

log "Iniciando sistema..."

# Crear directorios esenciales
log "Creando directorios..."
mkdir -p /proc /sys /dev /run /tmp /newroot 2>/dev/null || true

# Montar sistemas de archivos esenciales
log "Montando /proc..."
mount -t proc none /proc || panic "No se pudo montar /proc"

log "Montando /sys..."
mount -t sysfs none /sys || panic "No se pudo montar /sys"

log "Montando /dev..."
mount -t devtmpfs none /dev || {
    log "devtmpfs falló, usando tmpfs..."
    mount -t tmpfs none /dev || panic "No se pudo montar /dev"
    
    # Crear dispositivos mínimos
    log "Creando dispositivos básicos..."
    mknod -m 666 /dev/null c 1 3
    mknod -m 666 /dev/zero c 1 5
    mknod -m 666 /dev/random c 1 8
    mknod -m 666 /dev/urandom c 1 9
    mknod -m 666 /dev/tty c 5 0
    mknod -m 666 /dev/console c 5 1
    mknod -m 666 /dev/tty0 c 4 0
}

# Crear enlaces para stdin/stdout/stderr
log "Creando enlaces de E/S estándar..."
ln -sf /proc/self/fd /dev/fd 2>/dev/null || true
ln -sf /proc/self/fd/0 /dev/stdin 2>/dev/null || true
ln -sf /proc/self/fd/1 /dev/stdout 2>/dev/null || true
ln -sf /proc/self/fd/2 /dev/stderr 2>/dev/null || true

# Configurar PATH
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

# Intentar cargar módulos (si modprobe existe)
if which modprobe >/dev/null 2>&1; then
    log "Cargando módulos del kernel..."
    modprobe squashfs 2>/dev/null || log "No se pudo cargar módulo squashfs"
    modprobe overlay 2>/dev/null || log "No se pudo cargar módulo overlay"
else
    log "modprobe no disponible, continuando sin cargar módulos"
fi

# Leer parámetros del kernel
CMDLINE="${CMDLINE:-}"
if [ -z "$CMDLINE" ] && [ -f /proc/cmdline ]; then
    CMDLINE=$(cat /proc/cmdline)
fi
log "CMDLINE: $CMDLINE"

# Preparar directorios para montaje
log "Preparando directorios de montaje..."
mkdir -p /run/src /run/ro /run/rw /run/rw/upper /run/rw/work

# Verificar y copiar filesystem.squashfs
if [ -f /filesystem.squashfs ]; then
    log "Usando filesystem.squashfs local"
    cp /filesystem.squashfs /run/src/rootfs.squashfs
else
    panic "No se encontró /filesystem.squashfs"
fi

# Verificar que el archivo se copió correctamente
if [ ! -f /run/src/rootfs.squashfs ]; then
    panic "Error al copiar filesystem.squashfs"
fi

# Obtener tamaño del squashfs para verificación
SQUASH_SIZE=$(stat -c %s /run/src/rootfs.squashfs 2>/dev/null || echo "0")
log "Tamaño de squashfs: $SQUASH_SIZE bytes"

if [ "$SQUASH_SIZE" -eq "0" ]; then
    panic "El archivo squashfs está vacío o corrupto"
fi

# Montar squashfs
log "Montando filesystem squashfs..."
mount -t squashfs -o ro,loop /run/src/rootfs.squashfs /run/ro || {
    log "Error al montar squashfs, intentando con diferentes opciones..."
    mount -t squashfs /run/src/rootfs.squashfs /run/ro || \
    mount -o loop /run/src/rootfs.squashfs /run/ro || \
    panic "No se pudo montar squashfs de ninguna forma"
}

# Verificar que el montaje fue exitoso
if [ ! -d /run/ro/bin ] && [ ! -d /run/ro/usr ]; then
    panic "El squashfs montado no parece contener un sistema válido"
fi

log "Squashfs montado correctamente"

# Montar tmpfs para capa de escritura
log "Montando capa de escritura..."
mount -t tmpfs tmpfs /run/rw || panic "No se pudo montar tmpfs"

# Crear directorios de trabajo
mkdir -p /run/rw/upper /run/rw/work

# Intentar montar overlay
log "Montando overlayfs..."
mount -t overlay overlay -o lowerdir=/run/ro,upperdir=/run/rw/upper,workdir=/run/rw/work /newroot 2>/dev/null || {
    log "Overlay no disponible, copiando sistema (esto tomará tiempo)..."
    # Fallback: copiar todo el contenido
    cp -a /run/ro/* /newroot/ || panic "No se pudo copiar el sistema a newroot"
}

# Verificar que newroot tiene contenido
if [ ! -f /newroot/bin/sh ] && [ ! -f /newroot/usr/bin/sh ]; then
    log "Contenido de /newroot:"
    ls -la /newroot/ 2>/dev/null || true
    panic "newroot no contiene un sistema válido"
fi

log "Sistema root preparado correctamente"

# ==========================================
# EJECUTAR SCRIPTS DESDE ZIP (SI EXISTE)
# ==========================================
if [ -f /scripts.zip ] && [ -f /usr/bin/unzip ]; then
    log "Procesando scripts.zip..."
    
    # Copiar a newroot
    cp /scripts.zip /newroot/tmp/scripts.zip
    
    # Montar proc, sys, dev en newroot para el chroot
    mount -t proc none /newroot/proc 2>/dev/null || true
    mount -t sysfs none /newroot/sys 2>/dev/null || true
    mount --bind /dev /newroot/dev 2>/dev/null || true
    
    # Intentar ejecutar scripts
    if [ -f /newroot/bin/bash ]; then
        log "Ejecutando scripts de instalación..."
        chroot /newroot /bin/bash -c "
            cd /tmp
            unzip -o scripts.zip
            if [ -f install.sh ]; then
                chmod +x install.sh
                ./install.sh
            elif [ -f scripts/install.sh ]; then
                chmod +x scripts/install.sh
                ./scripts/install.sh
            fi
        " || log "Error ejecutando scripts"
    else
        log "bash no disponible en newroot, saltando scripts"
    fi
    
    # Desmontar
    umount /newroot/proc 2>/dev/null || true
    umount /newroot/sys 2>/dev/null || true
    umount /newroot/dev 2>/dev/null || true
    
    log "Procesamiento de scripts completado"
elif [ -f /scripts.zip ]; then
    log "scripts.zip encontrado pero unzip no disponible"
else
    log "No se encontró scripts.zip"
fi

# Preparar para switch_root
log "Preparando cambio de root..."
mkdir -p /newroot/{proc,sys,dev,run,tmp}

# Mover montajes
mount --move /proc /newroot/proc || mount -t proc none /newroot/proc
mount --move /sys /newroot/sys || mount -t sysfs none /newroot/sys
mount --move /dev /newroot/dev || mount --bind /dev /newroot/dev

# Si existe /run con contenido, intentar moverlo
if [ -d /run ] && [ "$(ls -A /run 2>/dev/null)" ]; then
    mount --move /run /newroot/run 2>/dev/null || {
        mount -t tmpfs tmpfs /newroot/run
        cp -a /run/* /newroot/run/ 2>/dev/null || true
    }
else
    mount -t tmpfs tmpfs /newroot/run
fi

# Cambiar al nuevo root
log "Ejecutando switch_root..."
exec switch_root /newroot /sbin/init || \
exec switch_root /newroot /usr/sbin/init || \
exec switch_root /newroot /bin/init || \
exec switch_root /newroot /bin/sh || \
panic "No se pudo ejecutar switch_root ni encontrar init"
INIT_SCRIPT

sudo chmod +x "$INITRAMFS/init"

# ==========================================
# PASO 7: VERIFICAR INTEGRIDAD
# ==========================================
log "Verificando integridad del initramfs..."

# Verificar que los binarios críticos existen y son ejecutables
for binary in busybox sh mount mkdir; do
    if [ ! -x "$INITRAMFS/bin/$binary" ]; then
        error "Binario crítico no encontrado o no ejecutable: $binary"
    fi
done

# Verificar que el squashfs existe
if [ ! -f "$INITRAMFS/filesystem.squashfs" ]; then
    error "filesystem.squashfs no está en initramfs"
fi

log "Verificación completada ✓"

# ==========================================
# PASO 8: CREAR SCRIPT DE ARRANQUE MEJORADO
# ==========================================
log "Creando script de arranque mejorado..."

HARNESS=/tmp/run-fake-boot-fixed.sh
cat <<'HARNESS_SCRIPT' > "$HARNESS"
#!/bin/bash
set -euo pipefail

LAB=/srv/lab/initramfs

echo "╔════════════════════════════════════════╗"
echo "║      ARRANQUE SIMULADO - MEJORADO      ║"
echo "╚════════════════════════════════════════╝"
echo

# Verificaciones previas
echo "[*] Verificando sistema..."

if [ ! -d "$LAB" ]; then
    echo "[ERROR] No existe $LAB"
    exit 1
fi

if [ ! -f "$LAB/init" ]; then
    echo "[ERROR] No existe $LAB/init"
    exit 1
fi

if [ ! -x "$LAB/bin/busybox" ]; then
    echo "[ERROR] busybox no es ejecutable"
    exit 1
fi

if [ ! -f "$LAB/filesystem.squashfs" ]; then
    echo "[ERROR] No existe filesystem.squashfs"
    exit 1
fi

echo "[✓] Verificaciones completadas"
echo

echo "[*] Contenido del initramfs:"
echo "    - Binarios en /bin: $(ls $LAB/bin 2>/dev/null | wc -l)"
echo "    - Bibliotecas en /lib: $(find $LAB/lib -name "*.so*" 2>/dev/null | wc -l)"
echo "    - Tamaño squashfs: $(du -h $LAB/filesystem.squashfs | cut -f1)"
echo

echo "[*] Iniciando arranque simulado..."
echo "[*] Esto puede tomar unos minutos..."
echo

# Crear un namespace aislado y ejecutar
sudo unshare --mount --pid --fork bash -c "
    # Montar /dev en el initramfs si no está montado
    if ! mountpoint -q $LAB/dev 2>/dev/null; then
        mount --bind /dev $LAB/dev 2>/dev/null || true
    fi
    
    # Configurar variable de entorno
    export CMDLINE='quiet'
    export PATH=/bin:/sbin:/usr/bin:/usr/sbin
    
    # Ejecutar init
    echo '[*] Ejecutando init...'
    echo '----------------------------------------'
    exec chroot $LAB /init
" || {
    echo
    echo "[ERROR] El arranque falló"
    echo
    echo "Opciones de depuración:"
    echo "1. Revisar el init script: less $LAB/init"
    echo "2. Ejecutar shell de depuración: sudo chroot $LAB /bin/sh"
    echo "3. Verificar binarios: ldd $LAB/bin/busybox"
    echo
    exit 1
}

echo
echo "[*] Arranque completado"
HARNESS_SCRIPT

chmod +x "$HARNESS"

# ==========================================
# PASO 9: CREAR SCRIPT DE DEBUG
# ==========================================
DEBUG=/tmp/debug-initramfs.sh
cat <<'DEBUG_SCRIPT' > "$DEBUG"
#!/bin/bash

LAB=/srv/lab/initramfs

echo "╔════════════════════════════════════════╗"
echo "║         MODO DEBUG - INITRAMFS         ║"
echo "╚════════════════════════════════════════╝"
echo

echo "Comandos útiles:"
echo "  /bin/busybox         - Ver todos los comandos disponibles"
echo "  mount                 - Ver sistemas montados"
echo "  ls /                  - Ver contenido del root"
echo "  cat /init             - Ver script de init"
echo "  /init                 - Ejecutar init manualmente"
echo "  exit                  - Salir"
echo

sudo unshare --mount --pid --fork bash -c "
    mount --bind /dev $LAB/dev 2>/dev/null || true
    export PATH=/bin:/sbin:/usr/bin:/usr/sbin
    echo
    echo 'Shell de depuración en initramfs:'
    chroot $LAB /bin/sh
"
DEBUG_SCRIPT

chmod +x "$DEBUG"

# ==========================================
# RESUMEN FINAL
# ==========================================
echo
echo "╔════════════════════════════════════════╗"
echo "║      ¡PROBLEMAS SOLUCIONADOS! ✓        ║"
echo "╚════════════════════════════════════════╝"
echo
info "Cambios realizados:"
echo "  ✓ Instalado busybox estático (no necesita bibliotecas)"
echo "  ✓ Creados todos los enlaces simbólicos de comandos"
echo "  ✓ Copiadas bibliotecas necesarias para binarios adicionales"
echo "  ✓ Script init reescrito para máxima compatibilidad"
echo "  ✓ Mejor manejo de errores y fallbacks"
echo
info "Para ejecutar:"
echo "  Arranque normal:  $HARNESS"
echo "  Modo debug:       $DEBUG"
echo
info "Si aún hay problemas, usa el modo debug para investigar"
echo
log "¡Listo! Ahora el comando 'mount' y otros deberían funcionar correctamente 🎉"