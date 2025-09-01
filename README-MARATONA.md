# 🏆 Maratona Ubuntu - Sistema para Competencias de Programación

Sistema similar a **Maratona Linux** - Una distribución Ubuntu personalizada con todas las herramientas necesarias para competencias de programación (ICPC, ACM, OBI, etc.).

## 📋 ¿Qué es Maratona Ubuntu?

Es un sistema operativo basado en Ubuntu que incluye:
- **Compiladores**: GCC, G++, Java, Python, Go, Rust, Kotlin
- **IDEs**: VS Code, Code::Blocks, Geany, Emacs, Vim
- **Bibliotecas**: Boost, Eigen, GMP, STL
- **Herramientas**: Git, Docker, debugging tools
- **Templates**: Plantillas pre-configuradas para C++, Python y Java
- **Scripts**: Utilidades para compilar y probar código rápidamente

## 🚀 Opciones de Instalación

### Opción 1: Instalación Rápida (Recomendada)
Convierte tu Ubuntu actual en un sistema tipo Maratona Linux:

```bash
chmod +x maratona-quick-setup.sh
./maratona-quick-setup.sh
```

**Ventajas:**
- ✅ Rápido (15-30 minutos)
- ✅ No requiere reiniciar
- ✅ Mantiene tus archivos actuales
- ✅ Ideal para uso personal

### Opción 2: Crear ISO Personalizada
Crea una imagen ISO completa de Ubuntu con todo preinstalado:

```bash
chmod +x maratona-ubuntu-builder.sh
./maratona-ubuntu-builder.sh
```

**Ventajas:**
- ✅ ISO portable para múltiples computadoras
- ✅ Sistema limpio y optimizado
- ✅ Ideal para laboratorios y competencias
- ✅ Booteable desde USB

**Requisitos:**
- 10 GB de espacio libre
- Ubuntu/Debian como sistema host
- Conexión a internet
- Tiempo: 1-2 horas

### Opción 3: Script de Arranque Personalizado
Usa el script mejorado que analizamos:

```bash
chmod +x fixed-boot-script.sh
sudo ./fixed-boot-script.sh
```

## 📦 Software Incluido

### Lenguajes de Programación
| Lenguaje | Compilador/Intérprete | Versión |
|----------|------------------------|---------|
| C/C++ | GCC/G++ | 11+ con C++17 |
| Java | OpenJDK | 17 LTS |
| Python | Python3 | 3.10+ |
| Go | golang | 1.18+ |
| Rust | rustc | latest |
| Kotlin | kotlinc | 1.9.0 |
| JavaScript | Node.js | 16+ |

### IDEs y Editores
- **Visual Studio Code** - Con extensiones para competencias
- **Code::Blocks** - IDE clásico para C/C++
- **Geany** - Editor ligero y rápido
- **Vim/Emacs** - Para usuarios avanzados
- **Sublime Text** - Editor moderno

### Bibliotecas Importantes
- **Boost** - Biblioteca C++ completa
- **Eigen** - Álgebra lineal
- **GMP** - Aritmética de precisión arbitraria
- **NumPy/SciPy** - Computación científica en Python

## 🛠️ Comandos Útiles

### Compilar y Ejecutar
```bash
# Compilar y ejecutar cualquier archivo
run solution.cpp
run solution.py
run Main.java

# Crear nuevo archivo desde template
new-solution problema.cpp
new-solution problema.py

# Probar con entrada/salida
test-io solution.cpp input.txt output.txt
```

### Templates Disponibles

#### C++ Template
```cpp
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    // Tu código aquí
    
    return 0;
}
```

#### Python Template
```python
#!/usr/bin/env python3
import sys
input = sys.stdin.readline

def solve():
    # Tu código aquí
    pass

if __name__ == "__main__":
    solve()
```

## 📁 Estructura de Directorios

```
~/
├── maratona-templates/     # Templates de código
│   ├── template.cpp
│   ├── template.py
│   └── Main.java
├── maratona-workspace/     # Área de trabajo
│   └── (tus soluciones)
└── .config/Code/User/      # Configuración VS Code
    └── settings.json
```

## 🔧 Configuración VS Code

El sistema configura automáticamente VS Code con:
- Compilación con un click
- Sintaxis highlighting mejorada
- Snippets para competencias
- Terminal integrada
- Auto-save activado

## 🐛 Solución de Problemas

### El script falla al instalar paquetes
```bash
# Actualizar repositorios
sudo apt update
sudo apt --fix-broken install
```

### No encuentra comandos después de instalar
```bash
# Recargar bashrc
source ~/.bashrc
# O reiniciar terminal
```

### Problemas con VS Code
```bash
# Reinstalar VS Code
sudo apt remove code
sudo apt install code
```

### Falta espacio en disco
```bash
# Limpiar cache de apt
sudo apt clean
sudo apt autoremove
```

## 📊 Comparación con Maratona Linux Original

| Característica | Maratona Linux | Nuestro Sistema |
|---------------|----------------|-----------------|
| Base | Ubuntu LTS | Ubuntu 22.04 |
| Instalación | PPA oficial | Script automatizado |
| Personalización | Limitada | Total |
| Tamaño ISO | ~3 GB | ~2.5 GB |
| Tiempo instalación | Variable | 15-30 min (quick) |
| Actualizaciones | Via PPA | Manual |

## 🎯 Casos de Uso

### Para Estudiantes
- Practicar para competencias
- Aprender múltiples lenguajes
- Resolver problemas de jueces online

### Para Profesores
- Preparar laboratorios
- Enseñar algoritmos
- Organizar competencias locales

### Para Competencias
- ICPC/ACM
- OBI (Olimpíada Brasileira de Informática)
- Codeforces, AtCoder, TopCoder
- Competencias universitarias

## 🔐 Seguridad

### Usuario por defecto (ISO)
- Usuario: `maratona`
- Contraseña: `maratona`
- Sudo sin contraseña configurado

**⚠️ Importante**: Cambiar contraseña en producción

## 📝 Licencia y Créditos

Este proyecto está inspirado en:
- [Maratona Linux](https://github.com/maratona-linux) - ICPC LATAM
- Ubuntu y su comunidad
- Herramientas open source

## 🤝 Contribuir

Para mejorar el sistema:
1. Reporta bugs o sugiere mejoras
2. Agrega más templates
3. Mejora la documentación
4. Comparte con la comunidad

## 📞 Soporte

Si encuentras problemas:
1. Revisa los logs en `/var/log/`
2. Ejecuta los scripts en modo debug: `bash -x script.sh`
3. Verifica los requisitos del sistema

## ⚡ Tips para Competencias

1. **Practica los templates** - Memoriza las estructuras básicas
2. **Conoce tus herramientas** - Domina el IDE y debugger
3. **Prepara snippets** - Ten código común listo
4. **Optimiza tu entorno** - Configura shortcuts
5. **Prueba localmente** - Siempre test con casos extremos

---

**¡Buena suerte en tus competencias! 🏆**