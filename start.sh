#!/bin/bash

echo "🚀 Iniciando Cuestionario de Gestión de Riesgos..."
echo "======================================================"

# Verificar si Python está instalado
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 no está instalado. Por favor, instale Python 3.8 o superior."
    exit 1
fi

# Verificar si Node.js está instalado
if ! command -v node &> /dev/null; then
    echo "❌ Node.js no está instalado. Por favor, instale Node.js 16 o superior."
    exit 1
fi

# Función para verificar si un puerto está en uso
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null ; then
        echo "⚠️  Puerto $1 está en uso. Cerrando proceso..."
        lsof -ti:$1 | xargs kill -9 2>/dev/null || true
        sleep 2
    fi
}

# Verificar y liberar puertos
check_port 8000
check_port 3000

echo "🔧 Configurando entorno..."

# Configurar backend si no existe el entorno virtual
if [ ! -d "backend/venv" ]; then
    echo "📦 Instalando dependencias del backend..."
    cd backend
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    pip install reportlab jinja2  # Dependencias para PDF y templates
    cd ..
fi

# Configurar frontend si no existen node_modules
if [ ! -d "frontend/node_modules" ]; then
    echo "📦 Instalando dependencias del frontend..."
    cd frontend
    npm install
    cd ..
fi

echo "✅ Configuración completada!"
echo ""

# Iniciar backend en segundo plano
echo "🚀 Iniciando backend en puerto 8000..."
cd backend
source venv/bin/activate
python main.py &
BACKEND_PID=$!
cd ..

# Esperar a que el backend esté listo
echo "⏳ Esperando que el backend esté listo..."
sleep 5

# Verificar si el backend está corriendo
if ! curl -s http://localhost:8000/ > /dev/null; then
    echo "❌ Error: El backend no se pudo iniciar correctamente."
    kill $BACKEND_PID 2>/dev/null
    exit 1
fi

echo "✅ Backend iniciado correctamente en http://localhost:8000"

# Iniciar frontend
echo "🚀 Iniciando frontend en puerto 3000..."
cd frontend
npm run dev &
FRONTEND_PID=$!
cd ..

echo ""
echo "🎉 ¡Aplicación iniciada exitosamente!"
echo "======================================================"
echo "📱 Frontend: http://localhost:3000"
echo "🔧 Backend API: http://localhost:8000"
echo "📚 Documentación API: http://localhost:8000/docs"
echo ""
echo "Para detener la aplicación, presione Ctrl+C"
echo ""

# Función para limpiar procesos al salir
cleanup() {
    echo ""
    echo "🛑 Deteniendo aplicación..."
    kill $BACKEND_PID 2>/dev/null
    kill $FRONTEND_PID 2>/dev/null
    echo "✅ Aplicación detenida."
    exit 0
}

# Capturar señal de interrupción
trap cleanup SIGINT SIGTERM

# Mantener el script corriendo
wait