import zipfile
import os
import shutil
from typing import List, Dict
import uuid

class FileManager:
    def __init__(self, upload_directory: str = "uploads"):
        self.upload_directory = upload_directory
        self.temp_directory = "temp"
        os.makedirs(self.temp_directory, exist_ok=True)
    
    def create_submission_zip(self, submission_data: Dict) -> str:
        """Crear archivo ZIP con todos los archivos adjuntos de una submisión"""
        submission_id = submission_data['id']
        personal_info = submission_data['personal_info']
        
        # Crear nombre del archivo ZIP
        safe_name = self.sanitize_filename(personal_info['nombre_completo'])
        zip_filename = f"cuestionario_{safe_name}_{submission_id[:8]}.zip"
        zip_path = os.path.join(self.temp_directory, zip_filename)
        
        # Recopilar archivos adjuntos
        attached_files = []
        for response in submission_data['responses']:
            if response.get('file_path'):
                file_path = response['file_path']
                if os.path.exists(file_path):
                    attached_files.append({
                        'path': file_path,
                        'question_id': response['question_id'],
                        'original_name': os.path.basename(file_path)
                    })
        
        if not attached_files:
            return None  # No hay archivos para comprimir
        
        # Crear archivo ZIP
        with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
            # Agregar archivo de información
            info_content = self.create_submission_info(submission_data)
            zipf.writestr("informacion_submision.txt", info_content)
            
            # Agregar archivos adjuntos organizados por pregunta
            for file_info in attached_files:
                # Crear nombre descriptivo para el archivo en el ZIP
                question_id = file_info['question_id']
                original_name = file_info['original_name']
                _, ext = os.path.splitext(original_name)
                
                zip_filename = f"pregunta_{question_id:02d}_{self.get_question_short_name(question_id)}{ext}"
                
                zipf.write(file_info['path'], zip_filename)
        
        return zip_path
    
    def create_submission_info(self, submission_data: Dict) -> str:
        """Crear archivo de texto con información de la submisión"""
        personal_info = submission_data['personal_info']
        
        info = f"""INFORMACIÓN DE LA SUBMISIÓN
{'='*50}

DATOS PERSONALES:
- Nombre: {personal_info['nombre_completo']}
- Cargo: {personal_info['cargo']}
- Entidad: {personal_info['entidad']}
- Celular: {personal_info['celular']}
- Email: {personal_info['email']}

RESUMEN DE EVALUACIÓN:
- ID de Submisión: {submission_data['id']}
- Fecha: {datetime.fromisoformat(submission_data['submission_date']).strftime('%d/%m/%Y %H:%M:%S')}
- Puntuación: {submission_data['total_score']} / {submission_data['max_score']} ({submission_data['percentage']}%)

ARCHIVOS ADJUNTOS:
"""
        
        # Listar archivos por pregunta
        file_count = 0
        for response in submission_data['responses']:
            if response.get('file_path'):
                file_count += 1
                question_id = response['question_id']
                filename = os.path.basename(response['file_path'])
                info += f"- Pregunta {question_id}: {filename}\n"
        
        if file_count == 0:
            info += "- No se adjuntaron archivos\n"
        
        info += f"\nTotal de archivos adjuntos: {file_count}\n"
        
        return info
    
    def get_question_short_name(self, question_id: int) -> str:
        """Obtener nombre corto para organizar archivos por pregunta"""
        question_names = {
            1: "plan_contingencia",
            2: "plan_aprobado", 
            3: "sala_situacion",
            4: "equipo_respuesta",
            5: "vehiculos",
            6: "form_enfermedades",
            7: "form_albergues",
            9: "estadistico",
            11: "epidemiologo",
            19: "instructivo_gr",
            20: "stock_medicamentos",
            21: "ferias_prevencion"
        }
        return question_names.get(question_id, f"pregunta_{question_id}")
    
    def sanitize_filename(self, filename: str) -> str:
        """Limpiar nombre de archivo para uso seguro"""
        # Remover caracteres especiales y espacios
        safe_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-"
        sanitized = "".join(c if c in safe_chars else "_" for c in filename)
        return sanitized[:50]  # Limitar longitud
    
    def cleanup_temp_files(self, max_age_hours: int = 24):
        """Limpiar archivos temporales antiguos"""
        import time
        
        if not os.path.exists(self.temp_directory):
            return
        
        current_time = time.time()
        max_age_seconds = max_age_hours * 3600
        
        for filename in os.listdir(self.temp_directory):
            file_path = os.path.join(self.temp_directory, filename)
            if os.path.isfile(file_path):
                file_age = current_time - os.path.getmtime(file_path)
                if file_age > max_age_seconds:
                    try:
                        os.remove(file_path)
                        print(f"Archivo temporal eliminado: {filename}")
                    except Exception as e:
                        print(f"Error al eliminar {filename}: {e}")