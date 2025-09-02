# 🚀 Instrucciones de Uso - Cuestionario de Gestión de Riesgos

## ⚡ Inicio Rápido

### Opción 1: Script Automático (Recomendado)
```bash
./start.sh
```
Este script configura e inicia automáticamente tanto el backend como el frontend.

### Opción 2: Inicio Manual

#### 1. Iniciar Backend
```bash
cd backend
source venv/bin/activate
python main.py
```

#### 2. Iniciar Frontend (en otra terminal)
```bash
cd frontend
npm run dev
```

## 🌐 URLs de Acceso

- **Aplicación Web**: http://localhost:3000
- **API Backend**: http://localhost:8000
- **Documentación API**: http://localhost:8000/docs

## 📋 Cómo Usar la Aplicación

### 1. Completar Información Personal
- Nombre completo
- Cargo
- Entidad perteneciente
- Número de celular
- Correo electrónico

### 2. Responder las 23 Preguntas
Cada pregunta tiene diferentes tipos de respuesta:

#### Preguntas de Sí/No (8, 10, 15, 16, 17, 18)
- Simplemente seleccione "Sí" o "No"
- Puntuación automática: 4 puntos por "Sí"

#### Preguntas con Archivos Requeridos (1, 2, 3, 4, 5, 6, 7, 9, 11, 19, 20, 21)
- Responda la pregunta Y suba el archivo solicitado
- Tipos de archivo aceptados: PDF, PNG, JPG, JPEG, DOC, DOCX, TXT
- Tamaño máximo: 10MB por archivo

#### Preguntas de Contacto/Datos (12, 13, 14, 22, 23)
- Proporcione la información detallada solicitada
- Use el área de texto para incluir todos los datos

### 3. Monitorear Progreso
- La barra de progreso muestra el avance en tiempo real
- El resumen de progreso indica qué falta por completar
- La puntuación se calcula automáticamente

### 4. Enviar Cuestionario
- El botón de envío se habilita cuando el formulario está 100% completo
- Recibirá una confirmación con su puntuación total

## 📊 Sistema de Puntuación

- **Puntuación máxima**: 100 puntos
- **Preguntas críticas** (8 puntos): Planes de contingencia, equipos de respuesta
- **Preguntas importantes** (4 puntos): Recursos, conocimientos, contactos
- **Pregunta informativa** (0 puntos): Colaboradores

### Rangos de Evaluación
- **Excelente**: 80-100 puntos (80-100%)
- **Bueno**: 60-79 puntos (60-79%)
- **Regular**: 40-59 puntos (40-59%)
- **Deficiente**: 0-39 puntos (0-39%)

## 🔧 Dashboard Administrativo

Acceda al dashboard desde la navegación superior para:
- Ver todas las submisiones
- Analizar estadísticas generales
- Descargar reportes (próximamente)

## 🆘 Solución de Problemas

### Backend no inicia
```bash
cd backend
source venv/bin/activate
pip install -r requirements.txt
python main.py
```

### Frontend no inicia
```bash
cd frontend
npm install
npm run dev
```

### Puertos ocupados
```bash
# Liberar puerto 8000 (backend)
sudo lsof -t -i:8000 | xargs sudo kill -9

# Liberar puerto 3000 (frontend)
sudo lsof -t -i:3000 | xargs sudo kill -9
```

### Probar API
```bash
python3 test-api.py
```

## 📁 Archivos Importantes

- `backend/main.py` - Servidor FastAPI principal
- `frontend/src/App.tsx` - Aplicación React principal
- `frontend/src/components/SurveyForm.tsx` - Formulario del cuestionario
- `backend/uploads/` - Directorio de archivos subidos

## 🔐 Consideraciones de Seguridad

- Los archivos se almacenan localmente en `backend/uploads/`
- Validación de tipos de archivo en frontend y backend
- Límite de tamaño de archivo: 10MB
- CORS configurado para desarrollo local

## 📈 Próximas Mejoras

- [ ] Base de datos persistente (PostgreSQL)
- [ ] Autenticación de usuarios
- [ ] Exportación de reportes PDF/Excel
- [ ] Notificaciones por email
- [ ] Backup automático de archivos
- [ ] Panel de administración avanzado

## 📞 Soporte

Para soporte técnico, revise los logs en:
- Backend: Terminal donde ejecuta `python main.py`
- Frontend: Terminal donde ejecuta `npm run dev`
- Navegador: Consola de desarrollador (F12)