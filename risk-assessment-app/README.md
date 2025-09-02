# Sistema de Evaluación de Gestión de Riesgos en Salud

## Descripción
Aplicación web completa para evaluar la preparación y gestión de riesgos en entidades de salud. Permite completar un cuestionario de 23 preguntas con sistema de puntuación y carga de documentos de respaldo.

## Características Principales

### Frontend (React + Tailwind + shadcn/ui)
- ✅ Formulario de información personal
- ✅ 23 preguntas con diferentes tipos de respuesta
- ✅ Carga de archivos (PDF, imágenes, documentos)
- ✅ Sistema de puntuación automático
- ✅ Navegación paso a paso
- ✅ Vista de resultados y recomendaciones
- ✅ Descarga de reporte
- ✅ Diseño moderno y responsivo

### Backend (FastAPI + Python)
- ✅ API RESTful completa
- ✅ Manejo de archivos y documentos
- ✅ Almacenamiento de respuestas
- ✅ Cálculo automático de puntuación
- ✅ CORS configurado

## Requisitos Previos
- Node.js 16+ y npm
- Python 3.8+
- pip

## Instalación y Configuración

### Backend

1. Navegar al directorio del backend:
```bash
cd backend
```

2. Instalar dependencias:
```bash
pip install -r requirements.txt
```

3. Iniciar el servidor:
```bash
python main.py
# o
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

El backend estará disponible en: `http://localhost:8000`

### Frontend

1. Navegar al directorio del frontend:
```bash
cd frontend
```

2. Instalar dependencias:
```bash
npm install
```

3. Iniciar la aplicación:
```bash
npm run dev
```

La aplicación estará disponible en: `http://localhost:5173`

## Estructura del Proyecto

```
risk-assessment-app/
├── backend/
│   ├── main.py              # API principal con FastAPI
│   ├── requirements.txt     # Dependencias de Python
│   ├── uploads/             # Directorio para archivos subidos
│   └── submissions.json     # Almacenamiento de respuestas
│
└── frontend/
    ├── src/
    │   ├── components/
    │   │   ├── ui/          # Componentes de shadcn/ui
    │   │   ├── PersonalInfoForm.jsx
    │   │   ├── QuestionCard.jsx
    │   │   └── ResultsSummary.jsx
    │   ├── lib/
    │   │   └── utils.js     # Utilidades
    │   ├── App.jsx          # Componente principal
    │   ├── App.css          # Estilos personalizados
    │   └── index.css        # Estilos de Tailwind
    └── package.json
```

## Uso de la Aplicación

1. **Información Personal**: Complete todos los campos requeridos
2. **Cuestionario**: Responda las 23 preguntas, subiendo los documentos solicitados
3. **Revisión**: Verifique sus respuestas antes de enviar
4. **Resultados**: Visualice su puntuación y recomendaciones
5. **Reporte**: Descargue el reporte de evaluación

## Sistema de Puntuación

- **Puntuación máxima**: 100 puntos
- **Niveles de evaluación**:
  - 80-100%: Excelente nivel de preparación
  - 60-79%: Buen nivel con áreas de mejora
  - 40-59%: Nivel medio - Requiere mejoras significativas
  - 0-39%: Nivel bajo - Requiere atención urgente

## Tipos de Preguntas

1. **Con archivo adjunto**: Requieren subir documentación de respaldo
2. **Sí/No**: Preguntas de respuesta binaria
3. **Texto libre**: Para información de contactos y datos adicionales

## API Endpoints

- `GET /api/questions` - Obtener todas las preguntas
- `POST /api/upload` - Subir archivo para una pregunta
- `POST /api/submit` - Enviar formulario completo
- `GET /api/submissions` - Obtener todas las evaluaciones
- `GET /api/submissions/{id}` - Obtener evaluación específica

## Formatos de Archivo Soportados

- PDF (.pdf)
- Imágenes (.jpg, .jpeg, .png)
- Documentos (.doc, .docx)

## Buenas Prácticas Implementadas

- ✅ Separación de responsabilidades (Frontend/Backend)
- ✅ Componentes reutilizables
- ✅ Validación de datos en cliente y servidor
- ✅ Manejo de errores
- ✅ Diseño responsivo
- ✅ Código limpio y documentado
- ✅ API RESTful
- ✅ CORS configurado
- ✅ Almacenamiento seguro de archivos

## Notas de Desarrollo

- Los datos se almacenan en formato JSON para simplicidad (en producción usar base de datos)
- Los archivos se guardan localmente (en producción usar servicio de almacenamiento en la nube)
- No incluye autenticación (puede agregarse según necesidades)

## Licencia
Este proyecto fue desarrollado como herramienta de evaluación para gestión de riesgos en salud.