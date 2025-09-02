from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List, Dict, Any
import os
import shutil
from datetime import datetime
import json
from pathlib import Path

app = FastAPI(title="Risk Assessment API", version="1.0.0")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create uploads directory
UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)

# Data storage (in production, use a database)
SUBMISSIONS_FILE = Path("submissions.json")
if not SUBMISSIONS_FILE.exists():
    SUBMISSIONS_FILE.write_text("[]")

class PersonalInfo(BaseModel):
    full_name: str = Field(..., min_length=1, max_length=200)
    position: str = Field(..., min_length=1, max_length=100)
    entity: str = Field(..., min_length=1, max_length=200)
    phone_number: str = Field(..., pattern="^[0-9+\\-\\s]+$")
    email: EmailStr

class QuestionResponse(BaseModel):
    question_id: int
    answer: Optional[str] = None
    file_path: Optional[str] = None
    score: int = 0

class FormSubmission(BaseModel):
    personal_info: PersonalInfo
    responses: List[QuestionResponse]
    total_score: int = 0
    submission_date: datetime = Field(default_factory=datetime.now)
    submission_id: Optional[str] = None

# Question definitions with scores
QUESTIONS = {
    1: {"text": "¿Cuentan con un Plan de Contingencia o Emergencia por un Evento Adverso En Salud?", "score": 8, "requires_file": True, "file_description": "Suba el plan"},
    2: {"text": "¿El presente Plan fue aprobado por su instancia respectiva?", "score": 8, "requires_file": True, "file_description": "Suba foto de los sellos correspondientes o acta"},
    3: {"text": "¿Cuenta con Sala de Situación/Crisis?", "score": 4, "requires_file": True, "file_description": "Fotografía"},
    4: {"text": "¿Cuenta con un equipo de respuesta rápida?", "score": 8, "requires_file": True, "file_description": "Suba los memorándums de los designados"},
    5: {"text": "¿Cuenta con un vehículo, moto y/o ambulancia para socorrer?", "score": 4, "requires_file": True, "file_description": "Suba foto del motorizado"},
    6: {"text": "¿Utiliza Formulario de Enfermedades Trazadoras?", "score": 4, "requires_file": True, "file_description": "Envíe el formulario a usar"},
    7: {"text": "¿Utiliza Formulario para Vigilancia de albergues?", "score": 4, "requires_file": True, "file_description": "Envíe el formulario a usar"},
    8: {"text": "¿Conoce el manejo del EDAN Salud?", "score": 4, "requires_file": False, "answer_type": "yes_no"},
    9: {"text": "¿Cuenta con un estadístico o informático que maneja y consolida la información?", "score": 4, "requires_file": True, "file_description": "Envíe su memorándum de designación en caso de eventos adversos"},
    10: {"text": "¿Conoce cuál es la guía o protocolo a proceder ante eventos adversos?", "score": 4, "requires_file": False, "answer_type": "yes_no"},
    11: {"text": "¿Cuenta con un Epidemiólogo?", "score": 4, "requires_file": True, "file_description": "Envíe su memorándum de designación en caso de eventos adversos"},
    12: {"text": "¿Tiene contactos con SENAMHI?", "score": 4, "requires_file": False, "answer_type": "text", "text_description": "Escriba el contacto, nombre y cargo"},
    13: {"text": "¿Tiene contactos con VIDECI?", "score": 4, "requires_file": False, "answer_type": "text", "text_description": "Escriba el contacto, nombre y cargo"},
    14: {"text": "¿Tiene contactos con MSyD?", "score": 4, "requires_file": False, "answer_type": "text", "text_description": "Escriba el contacto, nombre y cargo"},
    15: {"text": "¿Conoce el establecimiento de un COEM?", "score": 4, "requires_file": False, "answer_type": "yes_no"},
    16: {"text": "¿Conoce el establecimiento de un SCI?", "score": 4, "requires_file": False, "answer_type": "yes_no"},
    17: {"text": "¿Conoce la Ley 602 de Gestión de Riesgos y su aplicación?", "score": 4, "requires_file": False, "answer_type": "yes_no"},
    18: {"text": "¿Conoce procedimientos para la realización de una declaratoria de emergencias y/o desastres?", "score": 4, "requires_file": False, "answer_type": "yes_no"},
    19: {"text": "¿Cuenta con instructivo de G.R. emitido por el SEDES?", "score": 4, "requires_file": True, "file_description": "Envíe documento o fotografía"},
    20: {"text": "¿Cuenta con un stock de medicamentos, insumos Y EPP ante eventos adversos?", "score": 4, "requires_file": True, "file_description": "Envíe lista"},
    21: {"text": "¿Desarrollo ferias de prevención en gestión de riesgo?", "score": 4, "requires_file": True, "file_description": "Envíe fotografía"},
    22: {"text": "¿Coordinación con el Centro Coordinar ante emergencia y/o desastres?", "score": 4, "requires_file": False, "answer_type": "text", "text_description": "Escriba el contacto, nombre y cargo"},
    23: {"text": "Nombre y cargo de los colaboradores en el llenado del formulario", "score": 0, "requires_file": False, "answer_type": "text", "text_description": "Solo datos"}
}

@app.get("/")
async def root():
    return {"message": "Risk Assessment API", "version": "1.0.0"}

@app.get("/api/questions")
async def get_questions():
    """Get all questions with their metadata"""
    return {"questions": QUESTIONS}

@app.post("/api/upload")
async def upload_file(
    file: UploadFile = File(...),
    question_id: int = Form(...)
):
    """Upload a file for a specific question"""
    try:
        # Validate file type
        allowed_extensions = ['.pdf', '.jpg', '.jpeg', '.png', '.doc', '.docx']
        file_extension = Path(file.filename).suffix.lower()
        
        if file_extension not in allowed_extensions:
            raise HTTPException(status_code=400, detail="File type not allowed")
        
        # Create unique filename
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"q{question_id}_{timestamp}_{file.filename}"
        file_path = UPLOAD_DIR / filename
        
        # Save file
        with file_path.open("wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        return {
            "filename": filename,
            "file_path": str(file_path),
            "question_id": question_id
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/submit")
async def submit_form(submission: FormSubmission):
    """Submit the complete form"""
    try:
        # Generate submission ID
        submission.submission_id = datetime.now().strftime("%Y%m%d%H%M%S")
        
        # Calculate total score
        total_score = sum(response.score for response in submission.responses)
        submission.total_score = total_score
        
        # Load existing submissions
        submissions = json.loads(SUBMISSIONS_FILE.read_text())
        
        # Add new submission
        submission_dict = submission.dict()
        submission_dict['submission_date'] = submission.submission_date.isoformat()
        submissions.append(submission_dict)
        
        # Save submissions
        SUBMISSIONS_FILE.write_text(json.dumps(submissions, indent=2, ensure_ascii=False))
        
        return {
            "message": "Form submitted successfully",
            "submission_id": submission.submission_id,
            "total_score": total_score,
            "max_score": sum(q["score"] for q in QUESTIONS.values())
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/submissions")
async def get_submissions():
    """Get all submissions"""
    try:
        submissions = json.loads(SUBMISSIONS_FILE.read_text())
        return {"submissions": submissions, "total": len(submissions)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/submissions/{submission_id}")
async def get_submission(submission_id: str):
    """Get a specific submission"""
    try:
        submissions = json.loads(SUBMISSIONS_FILE.read_text())
        for submission in submissions:
            if submission.get('submission_id') == submission_id:
                return submission
        raise HTTPException(status_code=404, detail="Submission not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)