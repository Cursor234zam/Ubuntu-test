# Cuestionario de Gestión de Riesgos en Salud

Una aplicación web completa para evaluar la preparación de entidades de salud ante eventos adversos, desarrollada con React + TypeScript en el frontend y FastAPI + Python en el backend.

## 🌟 Características

- **Frontend moderno**: React 18 + TypeScript + Tailwind CSS + shadcn/ui
- **Backend robusto**: FastAPI + Python con validación automática
- **Subida de archivos**: Soporte para PDFs, imágenes y documentos
- **Puntuación automática**: Sistema de scoring en tiempo real
- **Validación completa**: Validación tanto en frontend como backend
- **UI responsiva**: Diseño adaptable para móviles y desktop
- **Progreso visual**: Barra de progreso y indicadores de completitud

## 📋 Funcionalidades del Cuestionario

### Información Personal Requerida
- Nombre completo
- Cargo
- Entidad perteneciente
- Número de celular
- Correo electrónico

### 23 Preguntas de Evaluación
El cuestionario incluye preguntas sobre:
- Planes de contingencia y emergencia
- Equipos de respuesta rápida
- Recursos y vehículos de emergencia
- Protocolos y procedimientos
- Contactos institucionales
- Conocimientos normativos
- Stocks de medicamentos e insumos

### Sistema de Puntuación
- **Total máximo**: 100 puntos
- **Preguntas de 8 puntos**: Planes críticos y equipos
- **Preguntas de 4 puntos**: Recursos, conocimientos y contactos
- **Pregunta de 0 puntos**: Información de colaboradores

## 🛠️ Tecnologías Utilizadas

### Frontend
- **React 18** con TypeScript
- **Tailwind CSS** para estilos
- **shadcn/ui** para componentes
- **React Hook Form** para manejo de formularios
- **Axios** para comunicación con API
- **Lucide React** para iconos

### Backend
- **FastAPI** framework web
- **Pydantic** para validación de datos
- **Uvicorn** servidor ASGI
- **Aiofiles** para manejo asíncrono de archivos
- **Python-multipart** para subida de archivos

## 🚀 Instalación y Ejecución

### Prerequisitos
- Python 3.8+
- Node.js 16+
- npm o yarn

### Instalación Automática
```bash
chmod +x setup.sh
./setup.sh
```

### Instalación Manual

#### Backend
```bash
cd backend
python3 -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate
pip install -r requirements.txt
```

#### Frontend
```bash
cd frontend
npm install
```

### Ejecución

#### Opción 1: Scripts automáticos
```bash
# Terminal 1 - Backend
chmod +x run-backend.sh
./run-backend.sh

# Terminal 2 - Frontend
chmod +x run-frontend.sh
./run-frontend.sh
```

#### Opción 2: Manual
```bash
# Terminal 1 - Backend
cd backend
source venv/bin/activate
python main.py

# Terminal 2 - Frontend
cd frontend
npm run dev
```

### URLs de Acceso
- **Aplicación web**: http://localhost:3000
- **API Backend**: http://localhost:8000
- **Documentación API**: http://localhost:8000/docs

## 📁 Estructura del Proyecto

```
/
├── backend/
│   ├── main.py              # Aplicación FastAPI principal
│   ├── requirements.txt     # Dependencias Python
│   └── uploads/            # Archivos subidos (se crea automáticamente)
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── ui/         # Componentes shadcn/ui
│   │   │   ├── SurveyForm.tsx
│   │   │   ├── PersonalInfoForm.tsx
│   │   │   ├── QuestionCard.tsx
│   │   │   └── FileUpload.tsx
│   │   ├── services/
│   │   │   └── api.ts      # Cliente API
│   │   ├── types/
│   │   │   └── survey.ts   # Tipos TypeScript
│   │   ├── hooks/
│   │   │   └── use-toast.ts
│   │   ├── lib/
│   │   │   └── utils.ts
│   │   ├── App.tsx
│   │   └── main.tsx
│   ├── package.json
│   ├── tailwind.config.js
│   ├── tsconfig.json
│   └── vite.config.ts
├── setup.sh               # Script de instalación
├── run-backend.sh         # Script para ejecutar backend
├── run-frontend.sh        # Script para ejecutar frontend
└── README.md
```

## 🔧 API Endpoints

### Principales Endpoints
- `GET /questions` - Obtener preguntas del cuestionario
- `POST /upload-file` - Subir archivo
- `POST /submit-survey` - Enviar cuestionario completo
- `GET /submissions` - Ver todas las submisiones
- `GET /submissions/{id}` - Ver submisión específica

### Tipos de Archivo Soportados
- **Documentos**: PDF, DOC, DOCX, TXT
- **Imágenes**: PNG, JPG, JPEG
- **Tamaño máximo**: 10MB por archivo

## 💡 Características Técnicas

### Validaciones
- **Frontend**: Validación en tiempo real con feedback visual
- **Backend**: Validación robusta con Pydantic
- **Archivos**: Validación de tipo y tamaño
- **Email**: Validación de formato de correo electrónico

### Seguridad
- **CORS** configurado para desarrollo
- **Validación de tipos de archivo**
- **Límites de tamaño de archivo**
- **Sanitización de nombres de archivo**

### UX/UI
- **Diseño responsivo** para móviles y desktop
- **Indicadores de progreso** visuales
- **Feedback inmediato** en acciones del usuario
- **Estados de carga** para mejor experiencia
- **Notificaciones toast** para confirmaciones y errores

## 🎯 Uso de la Aplicación

1. **Completar información personal** (todos los campos son obligatorios)
2. **Responder las 23 preguntas** del cuestionario
3. **Subir archivos requeridos** para preguntas específicas
4. **Monitorear el progreso** con la barra de progreso
5. **Enviar el cuestionario** una vez completado al 100%
6. **Recibir confirmación** con puntuación total y porcentaje

## 🔄 Próximas Mejoras

- Base de datos persistente (PostgreSQL/MySQL)
- Autenticación y autorización
- Dashboard administrativo
- Exportación de reportes
- Notificaciones por email
- Backup automático de archivos

## 📞 Soporte

Para soporte técnico o consultas sobre el cuestionario, contacte al administrador del sistema.