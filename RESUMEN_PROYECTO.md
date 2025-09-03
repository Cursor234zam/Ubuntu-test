# 📋 Cuestionario de Gestión de Riesgos en Salud

## ✅ Proyecto Completado

He creado una aplicación web completa para el cuestionario de gestión de riesgos en salud con todas las funcionalidades solicitadas.

## 🏗️ Arquitectura del Proyecto

### Backend (FastAPI + Python)
- **Framework**: FastAPI para API REST
- **Funcionalidades**:
  - ✅ Manejo de 23 preguntas con puntuación automática
  - ✅ Sistema de subida de archivos (PDFs, imágenes, documentos)
  - ✅ Validación completa de datos
  - ✅ Almacenamiento en memoria (expandible a BD)
  - ✅ API RESTful documentada automáticamente
  - ✅ CORS configurado para desarrollo

### Frontend (React + TypeScript + Tailwind + shadcn/ui)
- **Framework**: React 18 con TypeScript
- **UI**: Tailwind CSS + shadcn/ui para componentes modernos
- **Funcionalidades**:
  - ✅ Formulario reactivo con validación en tiempo real
  - ✅ Subida de archivos con drag & drop
  - ✅ Barra de progreso y resumen visual
  - ✅ Sistema de puntuación en vivo
  - ✅ Dashboard administrativo
  - ✅ Diseño responsivo para móviles y desktop

## 📊 Características del Cuestionario

### Información Personal Requerida
1. ✅ Nombre completo
2. ✅ Cargo
3. ✅ Entidad perteneciente
4. ✅ Número de celular
5. ✅ Correo electrónico

### 23 Preguntas Implementadas
Todas las preguntas están implementadas con su puntuación correspondiente:

| Pregunta | Puntos | Tipo | Archivo Requerido |
|----------|--------|------|-------------------|
| 1. Plan de Contingencia | 8 | Archivo | ✅ Plan |
| 2. Plan Aprobado | 8 | Archivo | ✅ Sellos/Acta |
| 3. Sala de Situación | 4 | Archivo | ✅ Fotografía |
| 4. Equipo Respuesta Rápida | 8 | Archivo | ✅ Memorándums |
| 5. Vehículos de Socorro | 4 | Archivo | ✅ Foto motorizado |
| 6. Formulario Enfermedades | 4 | Archivo | ✅ Formulario |
| 7. Formulario Albergues | 4 | Archivo | ✅ Formulario |
| 8. Manejo EDAN Salud | 4 | Sí/No | ❌ Solo respuesta |
| 9. Estadístico/Informático | 4 | Archivo | ✅ Memorándum |
| 10. Guía/Protocolo | 4 | Sí/No | ❌ Solo respuesta |
| 11. Epidemiólogo | 4 | Archivo | ✅ Memorándum |
| 12. Contacto SENAMHI | 4 | Texto | ❌ Datos contacto |
| 13. Contacto VIDECI | 4 | Texto | ❌ Datos contacto |
| 14. Contacto MSyD | 4 | Texto | ❌ Datos contacto |
| 15. Conoce COEM | 4 | Sí/No | ❌ Solo respuesta |
| 16. Conoce SCI | 4 | Sí/No | ❌ Solo respuesta |
| 17. Ley 602 | 4 | Sí/No | ❌ Solo respuesta |
| 18. Declaratoria Emergencias | 4 | Sí/No | ❌ Solo respuesta |
| 19. Instructivo G.R. SEDES | 4 | Archivo | ✅ Documento/Foto |
| 20. Stock Medicamentos | 4 | Archivo | ✅ Lista |
| 21. Ferias Prevención | 4 | Archivo | ✅ Fotografía |
| 22. Centro Coordinador | 4 | Texto | ❌ Datos contacto |
| 23. Colaboradores | 0 | Texto | ❌ Solo datos |

**Total**: 100 puntos

## 🎯 Funcionalidades Implementadas

### ✅ Formulario Completo
- Información personal con validación
- 23 preguntas con tipos de respuesta específicos
- Sistema de puntuación automática
- Validación en tiempo real

### ✅ Sistema de Archivos
- Subida de múltiples tipos: PDF, PNG, JPG, JPEG, DOC, DOCX, TXT
- Validación de tamaño (máx. 10MB)
- Almacenamiento seguro con nombres únicos
- Preview de archivos subidos

### ✅ Experiencia de Usuario
- Diseño moderno y responsivo
- Barra de progreso visual
- Resumen de progreso con pendientes
- Notificaciones toast para feedback
- Estados de carga y validación

### ✅ Dashboard Administrativo
- Lista de todas las submisiones
- Estadísticas generales (promedio, máximo, mínimo)
- Vista detallada de cada submisión
- Filtrado y búsqueda (base implementada)

### ✅ API REST Completa
- Documentación automática en `/docs`
- Endpoints para todas las operaciones
- Validación robusta con Pydantic
- Manejo de errores estructurado

## 🚀 Cómo Ejecutar

### Opción 1: Script Automático
```bash
./start.sh
```

### Opción 2: Manual
```bash
# Terminal 1 - Backend
cd backend
source venv/bin/activate
python main.py

# Terminal 2 - Frontend  
cd frontend
npm run dev
```

### Verificar Funcionamiento
```bash
# Probar API
python3 test-api.py

# Acceder a la aplicación
# http://localhost:3000
```

## 📱 Capturas de Funcionalidad

La aplicación incluye:
1. **Página principal** con navegación entre cuestionario y dashboard
2. **Formulario de información personal** con validación
3. **Preguntas individuales** con diferentes tipos de respuesta
4. **Sistema de subida de archivos** con drag & drop
5. **Barra de progreso** y resumen visual
6. **Página de confirmación** con puntuación final
7. **Dashboard administrativo** con estadísticas

## 🔧 Tecnologías Utilizadas

### Frontend
- React 18 + TypeScript
- Tailwind CSS para estilos
- shadcn/ui para componentes
- React Hook Form para formularios
- Axios para API calls
- Lucide React para iconos

### Backend
- FastAPI (Python)
- Pydantic para validación
- Uvicorn como servidor ASGI
- Aiofiles para archivos asíncronos
- Sistema de archivos local

## 🎉 Estado del Proyecto

**✅ COMPLETADO** - La aplicación está lista para usar y cumple con todos los requisitos:

- ✅ Frontend React con Tailwind y shadcn/ui
- ✅ Backend Python con FastAPI
- ✅ Sistema completo de subida de archivos
- ✅ Formulario con 23 preguntas y puntuación
- ✅ Validación completa frontend y backend
- ✅ Información personal requerida
- ✅ Dashboard administrativo
- ✅ Diseño moderno y responsivo
- ✅ Buenas prácticas de programación
- ✅ Documentación completa

La aplicación está lista para usar siguiendo las instrucciones de ejecución.