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
sudo mkdir -p "$INITRAMFS"/{bin,sbin,usr/bin,usr/sbin,proc,sys,dev,run,tmp,work,upper,newroot,var/log}

sudo cp "$SQUASH" "$INITRAMFS/filesystem.squashfs"

# Copiar scripts.zip al initramfs
if [ -f "$ZIPFILE" ]; then
  echo "[*] Copiando $ZIPFILE dentro del initramfs..."
  sudo cp "$ZIPFILE" "$INITRAMFS/scripts.zip"
else
  echo "[!] Advertencia: no encontré $ZIPFILE en el host"
fi

# Copiar binarios necesarios
sudo cp /bin/busybox "$INITRAMFS/bin/"
sudo cp /bin/bash "$INITRAMFS/bin/"
sudo cp /usr/bin/unzip "$INITRAMFS/usr/bin/"
sudo cp /usr/bin/tee "$INITRAMFS/usr/bin/"
sudo ln -sf /bin/busybox "$INITRAMFS/bin/sh"

# ==========================================
# 5) CREAR SCRIPT /init CON LOGGING Y /dev/fd
# ==========================================
cat <<'EOF' | sudo tee "$INITRAMFS/init" >/dev/null
#!/bin/sh
set -euxo pipefail

# Crear directorios y montar proc/sys/dev antes de redirecciones
mkdir -p /run /tmp /newroot /dev
mount -t proc proc /proc
mount -t sysfs sysfs /sys
[ -e /dev/null ] || mount -t devtmpfs devtmpfs /dev || true

# Crear enlaces /dev/fd y /dev/std*
mkdir -p /dev/fd
ln -sf /proc/self/fd /dev/fd
ln -sf /proc/self/fd/1 /dev/stdout
ln -sf /proc/self/fd/2 /dev/stderr
ln -sf /proc/self/fd/0 /dev/stdin

# Logging
LOG=/run/initramfs-boot.log
exec > >(tee -i "$LOG") 2>&1
trap 'echo "[PANIC] Error en línea ${LINENO}"; exec sh' ERR
log(){ echo "[INIT] $*"; }

# Cargar módulos
modprobe squashfs || true
modprobe overlay || true

# Leer CMDLINE
CMDLINE_ENV="${CMDLINE:-}"
CMDLINE_PROC="$(cat /proc/cmdline 2>/dev/null || true)"
CMDLINE="${CMDLINE_ENV:-$CMDLINE_PROC}"
log "CMDLINE=$CMDLINE"

URL="$(echo "$CMDLINE" | sed -n 's/.*url=\([^ ]*\).*/\1/p')"
VERIFY="$(echo "$CMDLINE" | sed -n 's/.*verify=\([^ ]*\).*/\1/p')"

# Preparar overlay
mkdir -p /run/src /run/ro /run/rw/upper /run/rw/work

if [ -n "$URL" ]; then
  log "Descargando squashfs de $URL"
  aria2c -o /run/src/rootfs.squashfs "$URL" || curl -L "$URL" -o /run/src/rootfs.squashfs
else
  cp /filesystem.squashfs /run/src/rootfs.squashfs
fi

# Verificación opcional
if [ -n "$VERIFY" ]; then
  case "$VERIFY" in
    md5:*)
      want="${VERIFY#md5:}"
      have="$(md5sum /run/src/rootfs.squashfs | awk '{print $1}')"
      [ "$want" = "$have" ] || { echo "MD5 no coincide"; exit 1; }
      ;;
    sha256:*)
      want="${VERIFY#sha256:}"
      have="$(sha256sum /run/src/rootfs.squashfs | awk '{print $1}')"
      [ "$want" = "$have" ] || { echo "SHA256 no coincide"; exit 1; }
      ;;
  esac
fi

# Montar overlayfs
mount -t squashfs -o ro /run/src/rootfs.squashfs /run/ro
mount -t tmpfs tmpfs /run/rw
mkdir -p /run/rw/upper /run/rw/work
mount -t overlay overlay -o lowerdir=/run/ro,upperdir=/run/rw/upper,workdir=/run/rw/work /newroot

log "Preparando cambio de root"
mkdir -p /newroot/{proc,sys,dev,run}

mount --move /proc /newroot/proc
mount --move /sys  /newroot/sys
mount --move /dev  /newroot/dev || true
mount --move /run  /newroot/run || true

# ==========================================
# EJECUTAR SCRIPTS DESDE ZIP
# ==========================================
if [ -f /scripts.zip ]; then
  log "Descomprimiendo /scripts.zip en /newroot/root/scripts..."
  cp /scripts.zip /newroot/root/scripts.zip
  chroot /newroot /bin/bash -c "
    cd /root && unzip -o scripts.zip -d /root/scripts &&
    chmod +x /root/scripts/install.sh &&
    /bin/bash /root/scripts/install.sh
  "
  log "Ejecución de scripts finalizada."
else
  log "No se encontró /scripts.zip en initramfs"
fi

cd /newroot
exec chroot /newroot /sbin/init || exec chroot /newroot /bin/sh
EOF

sudo chmod +x "$INITRAMFS/init"

# ==========================================
# 6) CREAR HARNESS PARA ARRANQUE FALSO
# ==========================================
HARNESS=/tmp/run-fake-boot.sh
cat <<EOF > "$HARNESS"
#!/bin/bash
set -euo pipefail
LAB=$INITRAMFS

echo "[*] Iniciando arranque simulado..."
sudo unshare -m --propagation private bash -c "
  mount --bind /dev \$LAB/dev
  export CMDLINE='url= verify='
  chroot \$LAB /init
"
EOF
chmod +x "$HARNESS"

echo
echo "================================================="
echo "[*] Todo listo."
echo "Ejecuta el arranque falso con:"
echo "  $HARNESS"
echo
echo "Si falla, revisa /run/initramfs-boot.log dentro del entorno."
echo "================================================="