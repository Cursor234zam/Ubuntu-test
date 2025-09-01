#!/bin/bash
set -euo pipefail

# ==========================================
# CONFIGURACIÓN
# ==========================================
LAB_DIR=/srv/lab
ROOTFS=$LAB_DIR/rootfs
INITRAMFS=$LAB_DIR/initramfs
SQUASH=$ROOTFS.squashfs
ZIPFILE=./scripts.zip

# ==========================================
# 0) CREAR DIRECTORIOS BASE
# ==========================================
echo "[*] Creando directorios base..."
sudo mkdir -p "$LAB_DIR"

# ==========================================
# 1) PRERREQUISITOS
# ==========================================
echo "[*] Instalando prerrequisitos..."
sudo apt-get update
sudo apt-get install -y debootstrap squashfs-tools busybox-static \
  initramfs-tools kmod curl wget aria2 iproute2 ca-certificates \
  rsync coreutils util-linux unzip ldd

# ==========================================
# 2) CREAR ROOTFS BASE (Ubuntu 24.04 - noble)
# ==========================================
if [ ! -d "$ROOTFS" ]; then
  echo "[*] Creando rootfs base en $ROOTFS ..."
  sudo mkdir -p "$ROOTFS"
  sudo debootstrap --arch=amd64 --include=bash,coreutils,util-linux noble "$ROOTFS" http://archive.ubuntu.com/ubuntu/
  
  # Verificar que debootstrap funcionó
  if [ ! -f "$ROOTFS/bin/bash" ]; then
    echo "[ERROR] debootstrap falló - no se encontró /bin/bash"
    exit 1
  fi
fi

# ==========================================
# 3) GENERAR FILESYSTEM.SQUASHFS
# ==========================================
echo "[*] Generando $SQUASH ..."
sudo mksquashfs "$ROOTFS" "$SQUASH" -comp xz -b 1M -noappend

# ==========================================
# 4) CREAR INITRAMFS MEJORADO
# ==========================================
echo "[*] Preparando initramfs mejorado en $INITRAMFS ..."
sudo rm -rf "$INITRAMFS"
sudo mkdir -p "$INITRAMFS"/{bin,sbin,usr/bin,usr/sbin,lib,lib64,proc,sys,dev,run,tmp,newroot,var/log}

sudo cp "$SQUASH" "$INITRAMFS/filesystem.squashfs"

# Copiar scripts.zip al initramfs
if [ -f "$ZIPFILE" ]; then
  echo "[*] Copiando $ZIPFILE dentro del initramfs..."
  sudo cp "$ZIPFILE" "$INITRAMFS/scripts.zip"
else
  echo "[!] Advertencia: no encontré $ZIPFILE en el host"
fi

# Función para copiar binario con dependencias
copy_binary_with_deps() {
  local binary="$1"
  local dest_dir="$2"
  
  if [ -f "$binary" ]; then
    echo "[*] Copiando $binary con dependencias..."
    sudo cp "$binary" "$dest_dir/"
    
    # Copiar librerías dependientes
    ldd "$binary" 2>/dev/null | grep -o '/lib[^ ]*' | while read lib; do
      if [ -f "$lib" ]; then
        sudo mkdir -p "$INITRAMFS/$(dirname "$lib")"
        sudo cp "$lib" "$INITRAMFS/$lib" 2>/dev/null || true
      fi
    done
  fi
}

# Copiar binarios necesarios con sus dependencias
copy_binary_with_deps "/bin/busybox" "$INITRAMFS/bin"
copy_binary_with_deps "/bin/bash" "$INITRAMFS/bin"
copy_binary_with_deps "/usr/bin/unzip" "$INITRAMFS/usr/bin"

# Crear enlaces simbólicos de busybox
sudo chroot "$INITRAMFS" /bin/busybox --install -s /bin/ 2>/dev/null || true
sudo ln -sf busybox "$INITRAMFS/bin/sh"

# ==========================================
# 5) CREAR SCRIPT /init MEJORADO
# ==========================================
cat <<'EOF' | sudo tee "$INITRAMFS/init" >/dev/null
#!/bin/sh
set -e

# Función de logging simple
log() {
    echo "[INIT] $*" | tee -a /run/boot.log 2>/dev/null || echo "[INIT] $*"
}

# Crear directorios básicos
mkdir -p /run /tmp /newroot /dev /proc /sys

# Montar sistemas de archivos básicos
mount -t proc proc /proc 2>/dev/null || true
mount -t sysfs sysfs /sys 2>/dev/null || true
mount -t devtmpfs devtmpfs /dev 2>/dev/null || mdev -s

log "Iniciando sistema de arranque personalizado..."

# Cargar módulos necesarios
modprobe squashfs 2>/dev/null || true
modprobe overlay 2>/dev/null || true

# Preparar directorios para overlay
mkdir -p /run/src /run/ro /run/rw/upper /run/rw/work

# Usar filesystem local
if [ -f /filesystem.squashfs ]; then
    cp /filesystem.squashfs /run/src/rootfs.squashfs
    log "Usando filesystem.squashfs local"
else
    log "ERROR: No se encontró filesystem.squashfs"
    exec /bin/sh
fi

# Montar sistema de archivos con overlay
mount -t squashfs -o ro /run/src/rootfs.squashfs /run/ro 2>/dev/null || {
    log "ERROR: No se pudo montar squashfs"
    exec /bin/sh
}

mount -t tmpfs tmpfs /run/rw 2>/dev/null || {
    log "ERROR: No se pudo montar tmpfs"
    exec /bin/sh
}

mkdir -p /run/rw/upper /run/rw/work

mount -t overlay overlay \
    -o lowerdir=/run/ro,upperdir=/run/rw/upper,workdir=/run/rw/work \
    /newroot 2>/dev/null || {
    log "ERROR: No se pudo montar overlay"
    exec /bin/sh
}

log "Sistema de archivos montado correctamente"

# Preparar el nuevo entorno
mkdir -p /newroot/{proc,sys,dev,run}

# Mover montajes al nuevo root
mount --move /proc /newroot/proc 2>/dev/null || true
mount --move /sys /newroot/sys 2>/dev/null || true
mount --move /dev /newroot/dev 2>/dev/null || true

# ==========================================
# EJECUTAR SCRIPTS DESDE ZIP
# ==========================================
if [ -f /scripts.zip ]; then
    log "Procesando scripts.zip..."
    cp /scripts.zip /newroot/root/scripts.zip
    
    # Ejecutar en el nuevo entorno
    chroot /newroot /bin/bash -c '
        cd /root
        if command -v unzip >/dev/null; then
            unzip -o scripts.zip -d /root/scripts 2>/dev/null || true
            if [ -f /root/scripts/install.sh ]; then
                chmod +x /root/scripts/install.sh
                log() { echo "[SCRIPT] $*"; }
                log "Ejecutando install.sh..."
                /bin/bash /root/scripts/install.sh || true
                log "Scripts ejecutados"
            fi
        else
            echo "[ERROR] unzip no disponible en el sistema base"
        fi
    ' 2>/dev/null || log "Error ejecutando scripts"
else
    log "No se encontró scripts.zip"
fi

# Cambiar al nuevo sistema
log "Cambiando al sistema principal..."
cd /newroot

# Intentar arrancar el sistema
exec chroot /newroot /sbin/init 2>/dev/null || \
exec chroot /newroot /bin/bash 2>/dev/null || \
exec /bin/sh
EOF

sudo chmod +x "$INITRAMFS/init"

# ==========================================
# 6) CREAR HARNESS MEJORADO
# ==========================================
HARNESS=/tmp/run-marathon-ubuntu.sh
cat <<EOF > "$HARNESS"
#!/bin/bash
set -euo pipefail

LAB_DIR="$INITRAMFS"
LOG_FILE="/tmp/marathon-boot.log"

echo "[*] Iniciando Maratón Ubuntu..."
echo "[*] Log disponible en: \$LOG_FILE"

# Limpiar log anterior
> "\$LOG_FILE"

sudo unshare -m --propagation private bash -c "
    # Montar /dev para el entorno
    mount --bind /dev \"\$LAB_DIR/dev\"
    
    # Ejecutar init y capturar log
    chroot \"\$LAB_DIR\" /init 2>&1 | tee \"\$LOG_FILE\"
" || {
    echo "[ERROR] Falló el arranque. Revisa \$LOG_FILE"
    exit 1
}
EOF

chmod +x "$HARNESS"

echo
echo "================================================="
echo "[*] Maratón Ubuntu preparado correctamente."
echo
echo "Ejecuta con:"
echo "  $HARNESS"
echo
echo "Archivos generados:"
echo "  - Rootfs: $ROOTFS"
echo "  - SquashFS: $SQUASH"
echo "  - InitramFS: $INITRAMFS"
echo "  - Script de arranque: $HARNESS"
echo "================================================="