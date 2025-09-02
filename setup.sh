#!/bin/bash

echo "🚀 Configurando la aplicación de Cuestionario de Gestión de Riesgos..."

# Crear entorno virtual de Python
echo "📦 Configurando backend Python..."
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cd ..

# Instalar dependencias de Node.js
echo "📦 Configurando frontend React..."
cd frontend
npm install
cd ..

echo "✅ Configuración completada!"
echo ""
echo "Para ejecutar la aplicación:"
echo "1. Backend: cd backend && source venv/bin/activate && python main.py"
echo "2. Frontend: cd frontend && npm run dev"
echo ""
echo "La aplicación estará disponible en:"
echo "- Frontend: http://localhost:3000"
echo "- Backend API: http://localhost:8000"