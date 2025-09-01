#!/bin/bash
set -euo pipefail

# ==========================================
# CONFIGURACIÓN
# ==========================================
ROOTFS=/srv/lab/rootfs
INITRAMFS=/srv/lab/initramfs
SQUASH=$ROOTFS.squashfs
ZIPFILE=./scripts.zip   # <-- ruta a tu archivo .zip en el host

# ==========================================
# 1) PRERREQUISITOS
# ==========================================
echo "[*] Instalando prerrequisitos..."
sudo apt-get update
sudo apt-get install -y debootstrap squashfs-tools busybox-static \
  initramfs-tools kmod curl wget aria2 iproute2 ca-certificates \
  rsync coreutils util-linux unzip

# ==========================================
# 2) CREAR ROOTFS BASE (Ubuntu 24.04 - noble)
# ==========================================
if [ ! -d "$ROOTFS" ]; then
  echo "[*] Creando rootfs base en $ROOTFS ..."
  sudo mkdir -p "$ROOTFS"
  sudo debootstrap --arch=amd64 noble "$ROOTFS" http://archive.ubuntu.com/ubuntu/
fi

# ==========================================
# 3) GENERAR FILESYSTEM.SQUASHFS
# ==========================================
echo "[*] Generando $SQUASH ..."
sudo mksquashfs "$ROOTFS" "$SQUASH" -comp xz -b 1M -noappend

# ==========================================
# 4) CREAR INITRAMFS SIMULADO
# ==========================================
echo "[*] Preparando initramfs simulado en $INITRAMFS ..."
sudo rm -rf "$INITRAMFS"
sudo mkdir -p "$INITRAMFS"/{bin,sbin,usr/bin,usr/sbin,proc,sys,dev,run,tmp,work,upper,newroot,var/log,lib,lib64}

# Copiar filesystem.squashfs
sudo cp "$SQUASH" "$INITRAMFS/filesystem.squashfs"

# Copiar scripts.zip al initramfs
if [ -f "$ZIPFILE" ]; then
  echo "[*] Copiando $ZIPFILE dentro del initramfs..."
  sudo cp "$ZIPFILE" "$INITRAMFS/scripts.zip"
else
  echo "[!] Advertencia: no encontré $ZIPFILE en el host"
fi

# Copiar binarios necesarios y sus dependencias
echo "[*] Copiando binarios y dependencias..."
sudo cp /bin/busybox "$INITRAMFS/bin/" 2>/dev/null || sudo cp /usr/bin/busybox "$INITRAMFS/bin/"
sudo cp /bin/bash "$INITRAMFS/bin/" 2>/dev/null || sudo cp /usr/bin/bash "$INITRAMFS/bin/"
sudo cp /usr/bin/unzip "$INITRAMFS/usr/bin/"
sudo cp /usr/bin/tee "$INITRAMFS/usr/bin/"

# Copiar utilidades adicionales necesarias
for util in awk md5sum sha256sum; do
  if [ -f "/usr/bin/$util" ]; then
    sudo cp "/usr/bin/$util" "$INITRAMFS/usr/bin/"
  elif [ -f "/bin/$util" ]; then
    sudo cp "/bin/$util" "$INITRAMFS/bin/"
  fi
done

# Crear enlaces simbólicos necesarios
sudo ln -sf /bin/busybox "$INITRAMFS/bin/sh"
sudo ln -sf /bin/busybox "$INITRAMFS/bin/mount"
sudo ln -sf /bin/busybox "$INITRAMFS/bin/mkdir"
sudo ln -sf /bin/busybox "$INITRAMFS/bin/cat"
sudo ln -sf /bin/busybox "$INITRAMFS/bin/echo"
sudo ln -sf /bin/busybox "$INITRAMFS/bin/cp"
sudo ln -sf /bin/busybox "$INITRAMFS/bin/ln"
sudo ln -sf /bin/busybox "$INITRAMFS/bin/sed"

# Copiar bibliotecas necesarias
echo "[*] Copiando bibliotecas necesarias..."
for binary in "$INITRAMFS"/bin/* "$INITRAMFS"/usr/bin/*; do
  if [ -f "$binary" ] && [ ! -L "$binary" ]; then
    ldd "$binary" 2>/dev/null | grep -oE '/[^ ]+' | while read lib; do
      if [ -f "$lib" ]; then
        libdir=$(dirname "$lib")
        sudo mkdir -p "$INITRAMFS$libdir"
        sudo cp -n "$lib" "$INITRAMFS$lib" 2>/dev/null || true
      fi
    done
  fi
done

# Copiar ld-linux si existe
if [ -f /lib64/ld-linux-x86-64.so.2 ]; then
  sudo mkdir -p "$INITRAMFS/lib64"
  sudo cp /lib64/ld-linux-x86-64.so.2 "$INITRAMFS/lib64/"
fi

# ==========================================
# 5) CREAR SCRIPT /init CON LOGGING Y /dev/fd
# ==========================================
cat <<'EOF' | sudo tee "$INITRAMFS/init" >/dev/null
#!/bin/sh
set -x

# Función de logging simple
log() {
    echo "[INIT $(date +%H:%M:%S)] $*"
}

# Función para manejar errores
panic() {
    echo "[PANIC] $*"
    echo "[PANIC] Iniciando shell de emergencia..."
    exec /bin/sh
}

# Verificar que estamos en el initramfs
log "Iniciando sistema desde initramfs..."

# Crear directorios esenciales
log "Creando directorios esenciales..."
mkdir -p /proc /sys /dev /run /tmp /newroot

# Montar sistemas de archivos esenciales
log "Montando sistemas de archivos esenciales..."
mount -t proc proc /proc || panic "No se pudo montar /proc"
mount -t sysfs sysfs /sys || panic "No se pudo montar /sys"
mount -t devtmpfs devtmpfs /dev || {
    log "devtmpfs falló, intentando tmpfs..."
    mount -t tmpfs tmpfs /dev
    # Crear dispositivos mínimos manualmente
    mknod -m 666 /dev/null c 1 3
    mknod -m 666 /dev/zero c 1 5
    mknod -m 666 /dev/random c 1 8
    mknod -m 666 /dev/urandom c 1 9
    mknod -m 666 /dev/tty c 5 0
    mknod -m 666 /dev/console c 5 1
}

# Crear enlaces simbólicos para fd
log "Creando enlaces simbólicos para /dev/fd..."
ln -sf /proc/self/fd /dev/fd
ln -sf /proc/self/fd/0 /dev/stdin
ln -sf /proc/self/fd/1 /dev/stdout
ln -sf /proc/self/fd/2 /dev/stderr

# Configurar logging
LOG=/run/initramfs-boot.log
exec > >(tee -a "$LOG") 2>&1

log "Sistema de logging configurado en $LOG"

# Cargar módulos del kernel si están disponibles
log "Intentando cargar módulos del kernel..."
if [ -f /bin/modprobe ]; then
    modprobe squashfs 2>/dev/null || log "No se pudo cargar módulo squashfs"
    modprobe overlay 2>/dev/null || log "No se pudo cargar módulo overlay"
else
    log "modprobe no disponible, saltando carga de módulos"
fi

# Leer parámetros del kernel
CMDLINE_ENV="${CMDLINE:-}"
CMDLINE_PROC="$(cat /proc/cmdline 2>/dev/null || true)"
CMDLINE="${CMDLINE_ENV:-$CMDLINE_PROC}"
log "CMDLINE: $CMDLINE"

# Extraer parámetros
URL="$(echo "$CMDLINE" | sed -n 's/.*url=\([^ ]*\).*/\1/p')"
VERIFY="$(echo "$CMDLINE" | sed -n 's/.*verify=\([^ ]*\).*/\1/p')"

# Preparar directorios para overlay
log "Preparando directorios para overlay..."
mkdir -p /run/src /run/ro /run/rw /run/rw/upper /run/rw/work

# Obtener o copiar filesystem.squashfs
if [ -n "$URL" ]; then
    log "Descargando squashfs desde: $URL"
    if [ -f /usr/bin/aria2c ]; then
        aria2c -o /run/src/rootfs.squashfs "$URL" || panic "Fallo al descargar con aria2c"
    elif [ -f /usr/bin/curl ]; then
        curl -L "$URL" -o /run/src/rootfs.squashfs || panic "Fallo al descargar con curl"
    elif [ -f /usr/bin/wget ]; then
        wget -O /run/src/rootfs.squashfs "$URL" || panic "Fallo al descargar con wget"
    else
        panic "No hay herramientas de descarga disponibles"
    fi
else
    log "Usando filesystem.squashfs local"
    if [ -f /filesystem.squashfs ]; then
        cp /filesystem.squashfs /run/src/rootfs.squashfs || panic "No se pudo copiar filesystem.squashfs"
    else
        panic "No se encontró /filesystem.squashfs"
    fi
fi

# Verificación opcional del archivo
if [ -n "$VERIFY" ]; then
    log "Verificando integridad del archivo..."
    case "$VERIFY" in
        md5:*)
            want="${VERIFY#md5:}"
            if [ -f /usr/bin/md5sum ] || [ -f /bin/md5sum ]; then
                have="$(md5sum /run/src/rootfs.squashfs | awk '{print $1}')"
                if [ "$want" != "$have" ]; then
                    panic "MD5 no coincide: esperado=$want, obtenido=$have"
                fi
                log "MD5 verificado correctamente"
            else
                log "md5sum no disponible, saltando verificación"
            fi
            ;;
        sha256:*)
            want="${VERIFY#sha256:}"
            if [ -f /usr/bin/sha256sum ] || [ -f /bin/sha256sum ]; then
                have="$(sha256sum /run/src/rootfs.squashfs | awk '{print $1}')"
                if [ "$want" != "$have" ]; then
                    panic "SHA256 no coincide: esperado=$want, obtenido=$have"
                fi
                log "SHA256 verificado correctamente"
            else
                log "sha256sum no disponible, saltando verificación"
            fi
            ;;
    esac
fi

# Montar squashfs
log "Montando filesystem squashfs..."
mount -t squashfs -o ro /run/src/rootfs.squashfs /run/ro || panic "No se pudo montar squashfs"

# Montar tmpfs para capa de escritura
log "Montando tmpfs para capa de escritura..."
mount -t tmpfs tmpfs /run/rw || panic "No se pudo montar tmpfs"

# Asegurar que los directorios de trabajo existen
mkdir -p /run/rw/upper /run/rw/work

# Montar overlayfs
log "Montando overlayfs..."
mount -t overlay overlay -o lowerdir=/run/ro,upperdir=/run/rw/upper,workdir=/run/rw/work /newroot || {
    log "Overlay falló, intentando union directa..."
    # Fallback: copiar todo el contenido (más lento pero funciona)
    cp -a /run/ro/* /newroot/ 2>/dev/null || panic "No se pudo preparar newroot"
}

# Verificar que newroot tiene contenido
if [ ! -f /newroot/bin/bash ] && [ ! -f /newroot/usr/bin/bash ]; then
    panic "newroot no parece tener un sistema válido"
fi

log "Sistema root preparado correctamente"

# Preparar puntos de montaje en newroot
log "Preparando puntos de montaje en newroot..."
mkdir -p /newroot/{proc,sys,dev,run,tmp}

# ==========================================
# EJECUTAR SCRIPTS DESDE ZIP
# ==========================================
if [ -f /scripts.zip ]; then
    log "Encontrado /scripts.zip, procesando..."
    
    # Copiar scripts.zip a newroot
    cp /scripts.zip /newroot/root/scripts.zip || log "Error al copiar scripts.zip"
    
    # Verificar que bash y unzip existen en newroot
    if [ -f /newroot/bin/bash ] || [ -f /newroot/usr/bin/bash ]; then
        if [ -f /newroot/usr/bin/unzip ] || [ -f /newroot/bin/unzip ]; then
            log "Ejecutando scripts de instalación..."
            
            # Montar proc, sys, dev temporalmente en newroot para el chroot
            mount -t proc proc /newroot/proc
            mount -t sysfs sysfs /newroot/sys
            mount --bind /dev /newroot/dev
            
            # Ejecutar scripts
            chroot /newroot /bin/bash -c "
                cd /root
                unzip -o scripts.zip -d /root/scripts 2>/dev/null || unzip -o scripts.zip
                if [ -f /root/scripts/install.sh ]; then
                    chmod +x /root/scripts/install.sh
                    /bin/bash /root/scripts/install.sh
                elif [ -f /root/install.sh ]; then
                    chmod +x /root/install.sh
                    /bin/bash /root/install.sh
                fi
            " || log "Error al ejecutar scripts de instalación"
            
            # Desmontar temporales
            umount /newroot/proc 2>/dev/null || true
            umount /newroot/sys 2>/dev/null || true
            umount /newroot/dev 2>/dev/null || true
            
            log "Ejecución de scripts finalizada"
        else
            log "unzip no encontrado en newroot, saltando instalación de scripts"
        fi
    else
        log "bash no encontrado en newroot, saltando instalación de scripts"
    fi
else
    log "No se encontró /scripts.zip en initramfs"
fi

# Mover sistemas de archivos montados
log "Moviendo sistemas de archivos a newroot..."
mount --move /proc /newroot/proc || mount -t proc proc /newroot/proc
mount --move /sys /newroot/sys || mount -t sysfs sysfs /newroot/sys
mount --move /dev /newroot/dev || mount --bind /dev /newroot/dev
mount --move /run /newroot/run || {
    mount -t tmpfs tmpfs /newroot/run
    cp -a /run/* /newroot/run/ 2>/dev/null || true
}

# Cambiar al nuevo root
log "Cambiando a nuevo sistema root..."
cd /newroot

# Intentar ejecutar init del sistema
if [ -f /newroot/sbin/init ]; then
    log "Ejecutando /sbin/init..."
    exec chroot /newroot /sbin/init
elif [ -f /newroot/usr/sbin/init ]; then
    log "Ejecutando /usr/sbin/init..."
    exec chroot /newroot /usr/sbin/init
elif [ -f /newroot/bin/systemd ]; then
    log "Ejecutando systemd..."
    exec chroot /newroot /bin/systemd
elif [ -f /newroot/bin/bash ]; then
    log "Init no encontrado, ejecutando bash..."
    exec chroot /newroot /bin/bash
else
    panic "No se encontró ningún programa init o shell válido"
fi
EOF

sudo chmod +x "$INITRAMFS/init"

# ==========================================
# 6) CREAR HARNESS MEJORADO PARA ARRANQUE FALSO
# ==========================================
HARNESS=/tmp/run-fake-boot.sh
cat <<'EOF' > "$HARNESS"
#!/bin/bash
set -euo pipefail

LAB=/srv/lab/initramfs

echo "[*] Verificando entorno..."
if [ ! -d "$LAB" ]; then
    echo "[ERROR] No existe el directorio $LAB"
    echo "Ejecuta primero el script de preparación"
    exit 1
fi

if [ ! -f "$LAB/init" ]; then
    echo "[ERROR] No existe $LAB/init"
    exit 1
fi

if [ ! -f "$LAB/filesystem.squashfs" ]; then
    echo "[ERROR] No existe $LAB/filesystem.squashfs"
    exit 1
fi

echo "[*] Iniciando arranque simulado..."
echo "[*] Esto puede tomar varios minutos..."
echo

# Usar unshare para crear un namespace aislado
sudo unshare -m --propagation private bash -c "
    # Preparar el entorno
    mount --bind /dev $LAB/dev 2>/dev/null || true
    
    # Configurar variable de entorno para cmdline
    export CMDLINE='url= verify='
    
    # Ejecutar init en chroot
    echo '[*] Ejecutando init...'
    chroot $LAB /init || {
        echo
        echo '[ERROR] El init falló. Revisa los logs:'
        echo '  - /srv/lab/initramfs/run/initramfs-boot.log'
        echo
        echo 'Iniciando shell de depuración...'
        chroot $LAB /bin/sh
    }
"

echo
echo "[*] Arranque simulado completado"
EOF

chmod +x "$HARNESS"

# ==========================================
# 7) CREAR SCRIPT DE DEPURACIÓN
# ==========================================
DEBUG_SCRIPT=/tmp/debug-boot.sh
cat <<'EOF' > "$DEBUG_SCRIPT"
#!/bin/bash
set -euo pipefail

LAB=/srv/lab/initramfs

echo "[DEBUG] Entrando en modo depuración del initramfs..."
echo

sudo unshare -m --propagation private bash -c "
    mount --bind /dev $LAB/dev 2>/dev/null || true
    echo '[DEBUG] Shell interactivo en initramfs'
    echo '[DEBUG] Puedes ejecutar /init manualmente o explorar el sistema'
    echo
    chroot $LAB /bin/sh
"
EOF

chmod +x "$DEBUG_SCRIPT"

echo
echo "================================================="
echo "[*] Script preparado y mejorado."
echo
echo "PARA EJECUTAR:"
echo "  1. Arranque normal:    $HARNESS"
echo "  2. Modo depuración:    $DEBUG_SCRIPT"
echo
echo "ARCHIVOS IMPORTANTES:"
echo "  - Log de arranque: /srv/lab/initramfs/run/initramfs-boot.log"
echo "  - Script init:     /srv/lab/initramfs/init"
echo "  - Scripts.zip:     ./scripts.zip (debe existir)"
echo
echo "NOTA: Asegúrate de que scripts.zip existe en el directorio actual"
echo "      y contiene install.sh en su raíz o en una carpeta scripts/"
echo "================================================="