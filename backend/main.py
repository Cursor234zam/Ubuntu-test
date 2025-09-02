from fastapi import FastAPI, HTTPException, Depends, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pydantic import BaseModel, EmailStr
from typing import List, Optional
import os
import uuid
import aiofiles
from datetime import datetime
import json
import mimetypes

app = FastAPI(title="Cuestionario Gestión de Riesgos", version="1.0.0")

# Configurar CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Crear directorios necesarios
os.makedirs("uploads", exist_ok=True)
os.makedirs("static", exist_ok=True)

# Servir archivos estáticos
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# Modelos Pydantic
class PersonalInfo(BaseModel):
    nombre_completo: str
    cargo: str
    entidad: str
    celular: str
    email: EmailStr

class QuestionResponse(BaseModel):
    question_id: int
    answer: str
    score: int
    file_path: Optional[str] = None

class SurveySubmission(BaseModel):
    personal_info: PersonalInfo
    responses: List[QuestionResponse]
    total_score: int
    submission_date: datetime

# Configuración de preguntas
QUESTIONS_CONFIG = [
    {"id": 1, "text": "¿Cuentan con un Plan de Contingencia o Emergencia por un Evento Adverso En Salud?", "score": 8, "requires_file": True, "file_description": "Suba el plan"},
    {"id": 2, "text": "¿El presente Plan fue aprobado por su instancia respectiva?", "score": 8, "requires_file": True, "file_description": "Suba foto de los sellos correspondientes o acta"},
    {"id": 3, "text": "¿Cuenta con Sala de Situación/Crisis?", "score": 4, "requires_file": True, "file_description": "Fotografía"},
    {"id": 4, "text": "¿Cuenta con un equipo de respuesta rápida?", "score": 8, "requires_file": True, "file_description": "Suba los memorándums de los designados"},
    {"id": 5, "text": "¿Cuenta con un vehículo, moto y/o ambulancia para socorrer?", "score": 4, "requires_file": True, "file_description": "Suba foto del motorizado"},
    {"id": 6, "text": "¿Utiliza Formulario de Enfermedades Trazadoras?", "score": 4, "requires_file": True, "file_description": "Envíe el formulario a usar"},
    {"id": 7, "text": "¿Utiliza Formulario para Vigilancia de albergues?", "score": 4, "requires_file": True, "file_description": "Envíe el formulario a usar"},
    {"id": 8, "text": "¿Conoce el manejo del EDAN Salud?", "score": 4, "requires_file": False, "file_description": "Solo sí/no"},
    {"id": 9, "text": "¿Cuenta con un estadístico o informático que maneja y consolida la información?", "score": 4, "requires_file": True, "file_description": "Envíe su memorándum de designación en caso de eventos adversos"},
    {"id": 10, "text": "¿Conoce cuál es la guía o protocolo a proceder ante eventos adversos?", "score": 4, "requires_file": False, "file_description": "Solo sí/no"},
    {"id": 11, "text": "¿Cuenta con un Epidemiólogo?", "score": 4, "requires_file": True, "file_description": "Envíe su memorándum de designación en caso de eventos adversos"},
    {"id": 12, "text": "¿Tiene contactos con SENAMHI?", "score": 4, "requires_file": False, "file_description": "Escriba el contacto, nombre y cargo"},
    {"id": 13, "text": "¿Tiene contactos con VIDECI?", "score": 4, "requires_file": False, "file_description": "Escriba el contacto, nombre y cargo"},
    {"id": 14, "text": "¿Tiene contactos con MSyD?", "score": 4, "requires_file": False, "file_description": "Escriba el contacto, nombre y cargo"},
    {"id": 15, "text": "¿Conoce el establecimiento de un COEM?", "score": 4, "requires_file": False, "file_description": "Solo sí/no"},
    {"id": 16, "text": "¿Conoce el establecimiento de un SCI?", "score": 4, "requires_file": False, "file_description": "Solo sí/no"},
    {"id": 17, "text": "¿Conoce la Ley 602 de Gestión de Riesgos y su aplicación?", "score": 4, "requires_file": False, "file_description": "Solo sí/no"},
    {"id": 18, "text": "¿Conoce procedimientos para la realización de una declaratoria de emergencias y/o desastres?", "score": 4, "requires_file": False, "file_description": "Solo sí/no"},
    {"id": 19, "text": "¿Cuenta con instructivo de G.R. emitido por el SEDES?", "score": 4, "requires_file": True, "file_description": "Envíe documento o fotografía"},
    {"id": 20, "text": "¿Cuenta con un stock de medicamentos, insumos Y EPP ante eventos adversos?", "score": 4, "requires_file": True, "file_description": "Envíe lista"},
    {"id": 21, "text": "¿Desarrollo ferias de prevención en gestión de riesgo?", "score": 4, "requires_file": True, "file_description": "Envíe fotografía"},
    {"id": 22, "text": "¿Coordinación con el Centro Coordinar ante emergencia y/o desastres?", "score": 4, "requires_file": False, "file_description": "Escriba el contacto, nombre y cargo"},
    {"id": 23, "text": "Nombre y cargo de los colaboradores en el llenado del formulario", "score": 0, "requires_file": False, "file_description": "Solo datos"}
]

# Base de datos en memoria (en producción usar PostgreSQL/MySQL)
submissions_db = []

@app.get("/")
async def root():
    return {"message": "API Cuestionario Gestión de Riesgos"}

@app.get("/questions")
async def get_questions():
    """Obtener todas las preguntas del cuestionario"""
    return {"questions": QUESTIONS_CONFIG}

@app.post("/upload-file")
async def upload_file(file: UploadFile = File(...)):
    """Subir archivo (PDF, imagen, documento)"""
    if not file.filename:
        raise HTTPException(status_code=400, detail="No se proporcionó un archivo")
    
    # Validar tipo de archivo
    allowed_extensions = {'.pdf', '.png', '.jpg', '.jpeg', '.doc', '.docx', '.txt'}
    file_extension = os.path.splitext(file.filename)[1].lower()
    
    if file_extension not in allowed_extensions:
        raise HTTPException(
            status_code=400, 
            detail=f"Tipo de archivo no permitido. Permitidos: {', '.join(allowed_extensions)}"
        )
    
    # Generar nombre único para el archivo
    unique_filename = f"{uuid.uuid4()}{file_extension}"
    file_path = f"uploads/{unique_filename}"
    
    try:
        async with aiofiles.open(file_path, 'wb') as f:
            content = await file.read()
            await f.write(content)
        
        return {
            "filename": file.filename,
            "file_path": file_path,
            "size": len(content),
            "message": "Archivo subido exitosamente"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al subir archivo: {str(e)}")

@app.post("/submit-survey")
async def submit_survey(submission: SurveySubmission):
    """Enviar cuestionario completo"""
    try:
        # Validar que todas las preguntas requeridas estén respondidas
        required_questions = [q["id"] for q in QUESTIONS_CONFIG]
        answered_questions = [r.question_id for r in submission.responses]
        
        missing_questions = set(required_questions) - set(answered_questions)
        if missing_questions:
            raise HTTPException(
                status_code=400, 
                detail=f"Faltan responder las preguntas: {list(missing_questions)}"
            )
        
        # Calcular puntuación total
        calculated_score = sum(r.score for r in submission.responses)
        max_possible_score = sum(q["score"] for q in QUESTIONS_CONFIG)
        
        # Agregar a la base de datos
        submission_id = str(uuid.uuid4())
        submission_data = {
            "id": submission_id,
            "personal_info": submission.personal_info.dict(),
            "responses": [r.dict() for r in submission.responses],
            "total_score": calculated_score,
            "max_score": max_possible_score,
            "percentage": round((calculated_score / max_possible_score) * 100, 2),
            "submission_date": datetime.now().isoformat()
        }
        
        submissions_db.append(submission_data)
        
        return {
            "submission_id": submission_id,
            "total_score": calculated_score,
            "max_score": max_possible_score,
            "percentage": submission_data["percentage"],
            "message": "Cuestionario enviado exitosamente"
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al procesar cuestionario: {str(e)}")

@app.get("/submissions")
async def get_submissions():
    """Obtener todas las submisiones (para administración)"""
    return {"submissions": submissions_db}

@app.get("/submissions/{submission_id}")
async def get_submission(submission_id: str):
    """Obtener una submisión específica"""
    submission = next((s for s in submissions_db if s["id"] == submission_id), None)
    if not submission:
        raise HTTPException(status_code=404, detail="Submisión no encontrada")
    return submission

@app.get("/download/{file_path:path}")
async def download_file(file_path: str):
    """Descargar archivo subido"""
    full_path = os.path.join("uploads", os.path.basename(file_path))
    
    if not os.path.exists(full_path):
        raise HTTPException(status_code=404, detail="Archivo no encontrado")
    
    # Determinar el tipo MIME
    mime_type, _ = mimetypes.guess_type(full_path)
    if mime_type is None:
        mime_type = 'application/octet-stream'
    
    return FileResponse(
        path=full_path,
        media_type=mime_type,
        filename=os.path.basename(full_path)
    )

@app.get("/stats")
async def get_statistics():
    """Obtener estadísticas generales"""
    if not submissions_db:
        return {
            "total_submissions": 0,
            "average_score": 0,
            "highest_score": 0,
            "lowest_score": 0,
            "average_percentage": 0
        }
    
    scores = [s["total_score"] for s in submissions_db]
    percentages = [s["percentage"] for s in submissions_db]
    
    return {
        "total_submissions": len(submissions_db),
        "average_score": round(sum(scores) / len(scores), 2),
        "highest_score": max(scores),
        "lowest_score": min(scores),
        "average_percentage": round(sum(percentages) / len(percentages), 2)
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)