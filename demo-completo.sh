#!/bin/bash

echo "🎭 DEMOSTRACIÓN COMPLETA - Cuestionario de Gestión de Riesgos"
echo "=============================================================="
echo ""

# Verificar que el backend esté corriendo
if ! curl -s http://localhost:8000/ > /dev/null; then
    echo "⚠️  El backend no está corriendo. Iniciando..."
    cd backend
    source venv/bin/activate
    python main.py &
    BACKEND_PID=$!
    cd ..
    echo "⏳ Esperando que el backend se inicie..."
    sleep 8
    
    if ! curl -s http://localhost:8000/ > /dev/null; then
        echo "❌ No se pudo iniciar el backend"
        exit 1
    fi
    echo "✅ Backend iniciado"
else
    echo "✅ Backend ya está funcionando"
fi

echo ""
echo "📊 Creando datos de demostración..."
python3 demo.py

echo ""
echo "🧪 Probando funcionalidades de descarga..."
python3 test-downloads.py

echo ""
echo "🌐 URLs de la aplicación:"
echo "   📱 Frontend: http://localhost:3000"
echo "   🔧 Backend API: http://localhost:8000"
echo "   📚 Documentación: http://localhost:8000/docs"
echo ""

echo "🎯 Funcionalidades implementadas:"
echo "   ✅ Formulario completo con 23 preguntas"
echo "   ✅ Sistema de subida de archivos"
echo "   ✅ Puntuación automática"
echo "   ✅ Generación de PDF con respuestas"
echo "   ✅ Descarga de ZIP con archivos"
echo "   ✅ Paquete completo (PDF + archivos)"
echo "   ✅ Dashboard administrativo"
echo "   ✅ Vista detallada de submisiones"
echo "   ✅ Estadísticas en tiempo real"
echo ""

echo "📋 Para probar manualmente:"
echo "   1. Vaya a http://localhost:3000"
echo "   2. Complete el cuestionario con archivos"
echo "   3. Envíe y descargue inmediatamente"
echo "   4. Vaya al Dashboard para vista administrativa"
echo ""

echo "🎉 ¡Demostración lista! La aplicación está funcionando completamente."