#!/usr/bin/env python3
"""
Script de demostración que crea datos de prueba para mostrar las funcionalidades de descarga.
"""

import requests
import json
import os
from datetime import datetime

def create_demo_data():
    base_url = "http://localhost:8000"
    
    print("🎭 Creando datos de demostración...")
    print("=" * 50)
    
    # Datos de prueba
    demo_submission = {
        "personal_info": {
            "nombre_completo": "Dr. Juan Carlos Pérez",
            "cargo": "Director Médico",
            "entidad": "Hospital Central de La Paz",
            "celular": "+591 70123456",
            "email": "juan.perez@hospital.gob.bo"
        },
        "responses": [
            {"question_id": 1, "answer": "Sí, contamos con plan actualizado", "score": 8},
            {"question_id": 2, "answer": "Sí, aprobado por dirección", "score": 8},
            {"question_id": 3, "answer": "Sí, en el segundo piso", "score": 4},
            {"question_id": 4, "answer": "Sí, equipo de 8 personas", "score": 8},
            {"question_id": 5, "answer": "Sí, 2 ambulancias y 1 moto", "score": 4},
            {"question_id": 6, "answer": "Sí, utilizamos formulario estándar", "score": 4},
            {"question_id": 7, "answer": "Sí, tenemos formulario específico", "score": 4},
            {"question_id": 8, "answer": "Sí", "score": 4},
            {"question_id": 9, "answer": "Sí, Lic. María González", "score": 4},
            {"question_id": 10, "answer": "Sí", "score": 4},
            {"question_id": 11, "answer": "Sí, Dr. Carlos Mamani", "score": 4},
            {"question_id": 12, "answer": "Ing. Pedro López - Meteorólogo - Tel: 2234567", "score": 4},
            {"question_id": 13, "answer": "Lic. Ana García - Coordinadora - Tel: 2345678", "score": 4},
            {"question_id": 14, "answer": "Dr. Luis Mendoza - Director - Tel: 2456789", "score": 4},
            {"question_id": 15, "answer": "Sí", "score": 4},
            {"question_id": 16, "answer": "Sí", "score": 4},
            {"question_id": 17, "answer": "Sí", "score": 4},
            {"question_id": 18, "answer": "Sí", "score": 4},
            {"question_id": 19, "answer": "Sí, tenemos instructivo actualizado", "score": 4},
            {"question_id": 20, "answer": "Sí, stock para 30 días", "score": 4},
            {"question_id": 21, "answer": "Sí, 2 ferias anuales", "score": 4},
            {"question_id": 22, "answer": "Cap. Roberto Silva - Coordinador - Tel: 2567890", "score": 4},
            {"question_id": 23, "answer": "Dra. Sandra Quispe - Subdirectora, Lic. Mario Conde - Estadístico", "score": 0}
        ],
        "total_score": 96,
        "submission_date": datetime.now().isoformat()
    }
    
    try:
        # Enviar submisión de prueba
        print("📤 Enviando submisión de prueba...")
        response = requests.post(f"{base_url}/submit-survey", json=demo_submission)
        
        if response.status_code == 200:
            result = response.json()
            submission_id = result['submission_id']
            print(f"   ✅ Submisión creada: {submission_id}")
            print(f"   📊 Puntuación: {result['total_score']}/{result['max_score']} ({result['percentage']}%)")
            
            # Probar descargas
            print(f"\n📥 Probando descargas para submisión {submission_id[:8]}...")
            
            # Probar PDF
            print("   📄 Probando generación de PDF...")
            pdf_response = requests.get(f"{base_url}/download-pdf/{submission_id}")
            if pdf_response.status_code == 200:
                print(f"      ✅ PDF generado ({len(pdf_response.content)} bytes)")
            else:
                print(f"      ❌ Error en PDF: {pdf_response.status_code}")
            
            # Probar ZIP (puede fallar si no hay archivos)
            print("   📦 Probando generación de ZIP...")
            zip_response = requests.get(f"{base_url}/download-zip/{submission_id}")
            if zip_response.status_code == 200:
                print(f"      ✅ ZIP generado ({len(zip_response.content)} bytes)")
            elif zip_response.status_code == 404:
                print("      ⚠️ No hay archivos adjuntos (normal en demo)")
            else:
                print(f"      ❌ Error en ZIP: {zip_response.status_code}")
            
            # Probar paquete completo
            print("   🎁 Probando paquete completo...")
            complete_response = requests.get(f"{base_url}/download-complete/{submission_id}")
            if complete_response.status_code == 200:
                print(f"      ✅ Paquete completo generado ({len(complete_response.content)} bytes)")
            else:
                print(f"      ❌ Error en paquete completo: {complete_response.status_code}")
            
            print(f"\n🎉 ¡Datos de demostración creados exitosamente!")
            print(f"🌐 Visite http://localhost:3000 para ver la aplicación")
            print(f"👨‍💼 Use el Dashboard para ver la submisión y probar descargas")
            
            return True
            
        else:
            print(f"❌ Error al crear submisión: {response.status_code}")
            print(f"   📝 Detalle: {response.text}")
            return False
            
    except requests.exceptions.ConnectionError:
        print("❌ No se pudo conectar al backend.")
        print("💡 Ejecute primero: cd backend && source venv/bin/activate && python main.py")
        return False
    except Exception as e:
        print(f"❌ Error inesperado: {e}")
        return False

if __name__ == "__main__":
    create_demo_data()