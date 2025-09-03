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
import shutil
import zipfile
from pdf_generator import PDFGenerator
from file_manager import FileManager

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
os.makedirs("temp", exist_ok=True)

# Servir archivos estáticos
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# Inicializar generadores
pdf_generator = PDFGenerator()
file_manager = FileManager()

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

@app.get("/download-pdf/{submission_id}")
async def download_submission_pdf(submission_id: str):
    """Descargar PDF con las respuestas de una submisión"""
    submission = next((s for s in submissions_db if s["id"] == submission_id), None)
    if not submission:
        raise HTTPException(status_code=404, detail="Submisión no encontrada")
    
    try:
        # Generar PDF
        personal_info = submission['personal_info']
        safe_name = file_manager.sanitize_filename(personal_info['nombre_completo'])
        pdf_filename = f"cuestionario_{safe_name}_{submission_id[:8]}.pdf"
        pdf_path = os.path.join("temp", pdf_filename)
        
        pdf_generator.generate_survey_pdf(submission, pdf_path)
        
        if not os.path.exists(pdf_path):
            raise HTTPException(status_code=500, detail="Error al generar PDF")
        
        return FileResponse(
            path=pdf_path,
            media_type='application/pdf',
            filename=pdf_filename,
            headers={"Content-Disposition": f"attachment; filename={pdf_filename}"}
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al generar PDF: {str(e)}")

@app.get("/download-zip/{submission_id}")
async def download_submission_zip(submission_id: str):
    """Descargar ZIP con archivos adjuntos de una submisión"""
    submission = next((s for s in submissions_db if s["id"] == submission_id), None)
    if not submission:
        raise HTTPException(status_code=404, detail="Submisión no encontrada")
    
    try:
        # Crear ZIP con archivos adjuntos
        zip_path = file_manager.create_submission_zip(submission)
        
        if not zip_path or not os.path.exists(zip_path):
            raise HTTPException(status_code=404, detail="No hay archivos adjuntos para descargar")
        
        zip_filename = os.path.basename(zip_path)
        
        return FileResponse(
            path=zip_path,
            media_type='application/zip',
            filename=zip_filename,
            headers={"Content-Disposition": f"attachment; filename={zip_filename}"}
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al crear ZIP: {str(e)}")

@app.get("/download-complete/{submission_id}")
async def download_complete_package(submission_id: str):
    """Descargar paquete completo: PDF + ZIP de archivos"""
    submission = next((s for s in submissions_db if s["id"] == submission_id), None)
    if not submission:
        raise HTTPException(status_code=404, detail="Submisión no encontrada")
    
    try:
        personal_info = submission['personal_info']
        safe_name = file_manager.sanitize_filename(personal_info['nombre_completo'])
        
        # Crear directorio temporal para el paquete completo
        package_dir = os.path.join("temp", f"paquete_{submission_id[:8]}")
        os.makedirs(package_dir, exist_ok=True)
        
        # Generar PDF
        pdf_filename = f"cuestionario_{safe_name}.pdf"
        pdf_path = os.path.join(package_dir, pdf_filename)
        pdf_generator.generate_survey_pdf(submission, pdf_path)
        
        # Crear subdirectorio para archivos adjuntos
        attachments_dir = os.path.join(package_dir, "archivos_adjuntos")
        os.makedirs(attachments_dir, exist_ok=True)
        
        # Copiar archivos adjuntos
        file_count = 0
        for response in submission['responses']:
            if response.get('file_path') and os.path.exists(response['file_path']):
                question_id = response['question_id']
                original_path = response['file_path']
                original_name = os.path.basename(original_path)
                _, ext = os.path.splitext(original_name)
                
                new_name = f"pregunta_{question_id:02d}_{file_manager.get_question_short_name(question_id)}{ext}"
                new_path = os.path.join(attachments_dir, new_name)
                
                shutil.copy2(original_path, new_path)
                file_count += 1
        
        # Crear archivo ZIP del paquete completo
        complete_zip_filename = f"paquete_completo_{safe_name}_{submission_id[:8]}.zip"
        complete_zip_path = os.path.join("temp", complete_zip_filename)
        
        with zipfile.ZipFile(complete_zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
            # Agregar PDF
            zipf.write(pdf_path, pdf_filename)
            
            # Agregar archivos adjuntos
            if file_count > 0:
                for root, dirs, files in os.walk(attachments_dir):
                    for file in files:
                        file_path = os.path.join(root, file)
                        arc_name = os.path.join("archivos_adjuntos", file)
                        zipf.write(file_path, arc_name)
        
        # Limpiar directorio temporal
        shutil.rmtree(package_dir)
        
        return FileResponse(
            path=complete_zip_path,
            media_type='application/zip',
            filename=complete_zip_filename,
            headers={"Content-Disposition": f"attachment; filename={complete_zip_filename}"}
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al crear paquete completo: {str(e)}")

@app.delete("/cleanup-temp")
async def cleanup_temp_files():
    """Limpiar archivos temporales (endpoint administrativo)"""
    try:
        file_manager.cleanup_temp_files()
        return {"message": "Archivos temporales limpiados exitosamente"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al limpiar archivos: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)