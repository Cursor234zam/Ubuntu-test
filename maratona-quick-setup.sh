#!/bin/bash
set -euo pipefail

# ==========================================
# MARATONA QUICK SETUP
# Script rápido para convertir Ubuntu actual
# en sistema tipo Maratona Linux
# ==========================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +%H:%M:%S)]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
info() { echo -e "${BLUE}[INFO]${NC} $*"; }

# ==========================================
# INSTALACIÓN RÁPIDA EN SISTEMA ACTUAL
# ==========================================

echo
echo "╔════════════════════════════════════════╗"
echo "║   MARATONA LINUX - INSTALACIÓN RÁPIDA  ║"
echo "╚════════════════════════════════════════╝"
echo

info "Este script instalará herramientas de programación competitiva"
info "en tu sistema Ubuntu actual (NO crea una ISO)"
echo

read -p "¿Deseas continuar? (s/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    exit 1
fi

# Verificar Ubuntu
if ! grep -q "Ubuntu" /etc/os-release; then
    warning "Este script está optimizado para Ubuntu"
    read -p "¿Continuar de todos modos? (s/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 1
    fi
fi

log "Actualizando sistema..."
sudo apt-get update

log "Instalando repositorio oficial de Maratona Linux..."
sudo add-apt-repository -y ppa:icpc-latam/maratona-linux || {
    warning "No se pudo agregar el PPA oficial, instalando manualmente..."
}

sudo apt-get update

# Intentar instalar el metapaquete oficial
log "Intentando instalar maratona-desktop..."
sudo apt-get install -y maratona-desktop 2>/dev/null || {
    warning "No se pudo instalar maratona-desktop, instalando paquetes manualmente..."
    
    log "Instalando compiladores y herramientas base..."
    sudo apt-get install -y \
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
        tree \
        time \
        bc
    
    log "Instalando lenguajes de programación..."
    
    # C/C++
    sudo apt-get install -y \
        gcc-multilib \
        g++-multilib \
        libstdc++-11-dev
    
    # Java
    sudo apt-get install -y \
        default-jdk \
        default-jre \
        maven
    
    # Python
    sudo apt-get install -y \
        python3 \
        python3-pip \
        python3-dev \
        python3-venv \
        python3-numpy \
        python3-scipy \
        ipython3
    
    # Node.js
    sudo apt-get install -y \
        nodejs \
        npm
    
    # Go
    sudo apt-get install -y golang
    
    log "Instalando IDEs y editores..."
    
    # VS Code
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
    sudo install -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/trusted.gpg.d/
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    sudo apt-get update
    sudo apt-get install -y code
    
    # Otros editores
    sudo apt-get install -y \
        geany \
        codeblocks \
        gedit
    
    log "Instalando bibliotecas de algoritmos..."
    sudo apt-get install -y \
        libboost-all-dev \
        libeigen3-dev \
        libgmp-dev
}

# Instalar Rust
if ! command -v rustc &> /dev/null; then
    log "Instalando Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
fi

# Instalar Kotlin
if ! command -v kotlinc &> /dev/null; then
    log "Instalando Kotlin..."
    cd /tmp
    wget -q https://github.com/JetBrains/kotlin/releases/download/v1.9.0/kotlin-compiler-1.9.0.zip
    unzip -q kotlin-compiler-1.9.0.zip
    sudo mv kotlinc /opt/
    sudo ln -sf /opt/kotlinc/bin/kotlin /usr/local/bin/kotlin
    sudo ln -sf /opt/kotlinc/bin/kotlinc /usr/local/bin/kotlinc
    rm kotlin-compiler-1.9.0.zip
fi

# Crear directorio de templates
log "Creando templates de código..."
mkdir -p ~/maratona-templates

# Template C++
cat > ~/maratona-templates/template.cpp << 'EOF'
#include <bits/stdc++.h>
using namespace std;

typedef long long ll;
typedef pair<int, int> pii;
typedef vector<int> vi;

#define FOR(i, a, b) for(int i = (a); i < (b); i++)
#define REP(i, n) FOR(i, 0, n)
#define RFOR(i, a, b) for(int i = (b) - 1; i >= (a); i--)
#define RREP(i, n) RFOR(i, 0, n)
#define all(v) v.begin(), v.end()
#define pb push_back
#define mp make_pair
#define fi first
#define se second

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    // Tu código aquí
    
    return 0;
}
EOF

# Template Python
cat > ~/maratona-templates/template.py << 'EOF'
#!/usr/bin/env python3
import sys
from collections import defaultdict, deque, Counter
from heapq import heappush, heappop, heapify
from bisect import bisect_left, bisect_right
from math import gcd, lcm, sqrt, ceil, floor

input = sys.stdin.readline

def solve():
    # Tu código aquí
    pass

if __name__ == "__main__":
    # t = int(input())
    # for _ in range(t):
    #     solve()
    solve()
EOF

# Template Java
cat > ~/maratona-templates/Main.java << 'EOF'
import java.util.*;
import java.io.*;

public class Main {
    static class FastReader {
        BufferedReader br;
        StringTokenizer st;
        
        public FastReader() {
            br = new BufferedReader(new InputStreamReader(System.in));
        }
        
        String next() {
            while (st == null || !st.hasMoreElements()) {
                try {
                    st = new StringTokenizer(br.readLine());
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
            return st.nextToken();
        }
        
        int nextInt() { return Integer.parseInt(next()); }
        long nextLong() { return Long.parseLong(next()); }
        double nextDouble() { return Double.parseDouble(next()); }
        
        String nextLine() {
            String str = "";
            try {
                str = br.readLine();
            } catch (IOException e) {
                e.printStackTrace();
            }
            return str;
        }
    }
    
    public static void main(String[] args) {
        FastReader sc = new FastReader();
        
        // Tu código aquí
        
    }
}
EOF

# Crear scripts útiles
log "Creando scripts de utilidad..."

# Script para compilar y ejecutar
sudo tee /usr/local/bin/run > /dev/null << 'EOF'
#!/bin/bash
# Compilar y ejecutar código rápidamente

if [ $# -eq 0 ]; then
    echo "Uso: run archivo.[cpp|py|java|go|rs|kt]"
    exit 1
fi

file="$1"
filename="${file%.*}"
extension="${file##*.}"

case "$extension" in
    cpp|cc|cxx)
        echo "Compilando C++..."
        g++ -std=c++17 -O2 -Wall -Wextra -pedantic -Wshadow -Wformat=2 -Wfloat-equal -Wconversion -Wlogical-op -Wshift-overflow=2 -Wduplicated-cond -Wcast-qual -Wcast-align -D_GLIBCXX_DEBUG -D_GLIBCXX_DEBUG_PEDANTIC -D_FORTIFY_SOURCE=2 -fsanitize=address -fsanitize=undefined -fno-sanitize-recover -fstack-protector "$file" -o "$filename"
        if [ $? -eq 0 ]; then
            echo "Ejecutando..."
            echo "---OUTPUT---"
            time "./$filename"
        fi
        ;;
    c)
        echo "Compilando C..."
        gcc -O2 -Wall -Wextra -pedantic "$file" -o "$filename" -lm
        if [ $? -eq 0 ]; then
            echo "Ejecutando..."
            echo "---OUTPUT---"
            time "./$filename"
        fi
        ;;
    py)
        echo "Ejecutando Python..."
        echo "---OUTPUT---"
        time python3 "$file"
        ;;
    java)
        echo "Compilando Java..."
        javac "$file"
        if [ $? -eq 0 ]; then
            echo "Ejecutando..."
            echo "---OUTPUT---"
            time java "$filename"
        fi
        ;;
    kt)
        echo "Compilando Kotlin..."
        kotlinc "$file" -include-runtime -d "$filename.jar"
        if [ $? -eq 0 ]; then
            echo "Ejecutando..."
            echo "---OUTPUT---"
            time java -jar "$filename.jar"
        fi
        ;;
    go)
        echo "Ejecutando Go..."
        echo "---OUTPUT---"
        time go run "$file"
        ;;
    rs)
        echo "Compilando Rust..."
        rustc -O "$file"
        if [ $? -eq 0 ]; then
            echo "Ejecutando..."
            echo "---OUTPUT---"
            time "./$filename"
        fi
        ;;
    js)
        echo "Ejecutando JavaScript..."
        echo "---OUTPUT---"
        time node "$file"
        ;;
    *)
        echo "Extensión no soportada: $extension"
        echo "Extensiones soportadas: cpp, c, py, java, kt, go, rs, js"
        exit 1
        ;;
esac
EOF

sudo chmod +x /usr/local/bin/run

# Script para generar archivo desde template
sudo tee /usr/local/bin/new-solution > /dev/null << 'EOF'
#!/bin/bash
# Crear nueva solución desde template

if [ $# -eq 0 ]; then
    echo "Uso: new-solution nombre.[cpp|py|java]"
    exit 1
fi

file="$1"
extension="${file##*.}"
template_dir="$HOME/maratona-templates"

case "$extension" in
    cpp|cc|cxx)
        cp "$template_dir/template.cpp" "$file"
        echo "Creado: $file (C++)"
        ;;
    py)
        cp "$template_dir/template.py" "$file"
        chmod +x "$file"
        echo "Creado: $file (Python)"
        ;;
    java)
        # Extraer nombre de clase del archivo
        classname="${file%.*}"
        cp "$template_dir/Main.java" "$file"
        # Si el nombre no es Main, cambiar el nombre de la clase
        if [ "$classname" != "Main" ]; then
            sed -i "s/public class Main/public class $classname/g" "$file"
        fi
        echo "Creado: $file (Java)"
        ;;
    *)
        echo "Extensión no soportada: $extension"
        echo "Extensiones soportadas: cpp, py, java"
        exit 1
        ;;
esac

# Abrir en el editor preferido si está configurado
if [ -n "$EDITOR" ]; then
    $EDITOR "$file"
elif command -v code &> /dev/null; then
    code "$file"
elif command -v gedit &> /dev/null; then
    gedit "$file" &
fi
EOF

sudo chmod +x /usr/local/bin/new-solution

# Script para probar con entrada/salida
sudo tee /usr/local/bin/test-io > /dev/null << 'EOF'
#!/bin/bash
# Probar programa con archivos de entrada/salida

if [ $# -lt 2 ]; then
    echo "Uso: test-io programa input.txt [output_esperado.txt]"
    exit 1
fi

program="$1"
input="$2"
expected="${3:-}"

if [ ! -f "$program" ]; then
    echo "Error: No se encuentra el archivo $program"
    exit 1
fi

if [ ! -f "$input" ]; then
    echo "Error: No se encuentra el archivo $input"
    exit 1
fi

# Compilar si es necesario
extension="${program##*.}"
executable="${program%.*}"

case "$extension" in
    cpp|cc|cxx)
        g++ -std=c++17 -O2 -Wall "$program" -o "$executable" || exit 1
        runner="./$executable"
        ;;
    c)
        gcc -O2 -Wall "$program" -o "$executable" -lm || exit 1
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
echo "=== ENTRADA ==="
cat "$input"
echo
echo "=== SALIDA ==="
output=$($runner < "$input" 2>&1)
echo "$output"

# Comparar con output esperado si se proporciona
if [ -n "$expected" ] && [ -f "$expected" ]; then
    echo
    echo "=== VERIFICACIÓN ==="
    expected_output=$(cat "$expected")
    if [ "$output" = "$expected_output" ]; then
        echo "✅ CORRECTO - La salida coincide"
    else
        echo "❌ INCORRECTO - La salida no coincide"
        echo
        echo "=== SALIDA ESPERADA ==="
        cat "$expected"
        echo
        echo "=== DIFERENCIAS ==="
        diff -u <(echo "$expected_output") <(echo "$output") || true
    fi
fi

echo
echo "=== ESTADÍSTICAS ==="
/usr/bin/time -v $runner < "$input" 2>&1 | grep -E "(User time|Maximum resident set size)" || true
EOF

sudo chmod +x /usr/local/bin/test-io

# Configurar VS Code
log "Configurando VS Code para competencias..."
mkdir -p ~/.config/Code/User

cat > ~/.config/Code/User/settings.json << 'EOF'
{
    "editor.fontSize": 14,
    "editor.fontFamily": "'Courier New', 'Consolas', 'Monaco', monospace",
    "editor.tabSize": 4,
    "editor.insertSpaces": true,
    "editor.wordWrap": "on",
    "editor.minimap.enabled": false,
    "editor.suggestSelection": "first",
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 1000,
    "terminal.integrated.fontSize": 14,
    "terminal.integrated.shell.linux": "/bin/bash",
    "workbench.colorTheme": "Default Dark+",
    "cpp.default.compilerPath": "/usr/bin/g++",
    "code-runner.runInTerminal": true,
    "code-runner.saveFileBeforeRun": true,
    "code-runner.clearPreviousOutput": true,
    "code-runner.executorMap": {
        "cpp": "cd $dir && g++ -std=c++17 -O2 -Wall $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt",
        "c": "cd $dir && gcc -O2 -Wall $fileName -o $fileNameWithoutExt -lm && $dir$fileNameWithoutExt",
        "python": "python3",
        "java": "cd $dir && javac $fileName && java $fileNameWithoutExt",
        "javascript": "node",
        "go": "go run",
        "rust": "cd $dir && rustc $fileName && $dir$fileNameWithoutExt"
    },
    "extensions.ignoreRecommendations": true,
    "files.associations": {
        "*.cpp": "cpp",
        "*.cc": "cpp",
        "*.cxx": "cpp",
        "*.h": "cpp",
        "*.hpp": "cpp"
    },
    "C_Cpp.default.cppStandard": "c++17",
    "C_Cpp.default.cStandard": "c11",
    "python.defaultInterpreterPath": "/usr/bin/python3"
}
EOF

# Instalar extensiones de VS Code útiles
if command -v code &> /dev/null; then
    log "Instalando extensiones de VS Code..."
    code --install-extension ms-vscode.cpptools
    code --install-extension ms-python.python
    code --install-extension vscjava.vscode-java-pack
    code --install-extension golang.go
    code --install-extension rust-lang.rust
    code --install-extension formulahendry.code-runner
fi

# Crear alias útiles
log "Configurando alias..."
cat >> ~/.bashrc << 'EOF'

# Alias para Maratona
alias compile='run'
alias newcpp='new-solution'
alias testio='test-io'
alias maratona='cd ~/maratona-workspace'

# Crear workspace si no existe
[ ! -d ~/maratona-workspace ] && mkdir -p ~/maratona-workspace
EOF

mkdir -p ~/maratona-workspace

# Resumen final
echo
echo "╔════════════════════════════════════════╗"
echo "║      ¡INSTALACIÓN COMPLETADA! 🎉       ║"
echo "╚════════════════════════════════════════╝"
echo
info "Herramientas instaladas:"
echo "  ✓ Compiladores: gcc, g++, java, python3, go, rust, kotlin"
echo "  ✓ IDEs: VS Code, Geany, Code::Blocks"
echo "  ✓ Bibliotecas: Boost, Eigen, GMP"
echo
info "Comandos disponibles:"
echo "  run <archivo>           - Compilar y ejecutar"
echo "  new-solution <archivo>  - Crear desde template"
echo "  test-io <prog> <in>     - Probar con entrada/salida"
echo
info "Templates en: ~/maratona-templates/"
info "Workspace en: ~/maratona-workspace/"
echo
log "Reinicia tu terminal para aplicar todos los cambios"
echo
echo "¡Buena suerte en las competencias! 🏆"