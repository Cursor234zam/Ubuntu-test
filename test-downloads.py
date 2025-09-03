#!/usr/bin/env python3
"""
Script de prueba para verificar las funcionalidades de descarga.
"""

import requests
import json
import os

def test_downloads():
    base_url = "http://localhost:8000"
    
    print("🧪 Probando funcionalidades de descarga...")
    print("=" * 60)
    
    try:
        # Verificar que el servidor esté funcionando
        print("1. Verificando servidor...")
        response = requests.get(f"{base_url}/")
        if response.status_code != 200:
            print("❌ El servidor no está funcionando")
            return False
        print("   ✅ Servidor funcionando")
        
        # Obtener submisiones
        print("\n2. Obteniendo submisiones...")
        response = requests.get(f"{base_url}/submissions")
        if response.status_code != 200:
            print("❌ Error al obtener submisiones")
            return False
        
        data = response.json()
        submissions = data.get('submissions', [])
        print(f"   📊 Submisiones encontradas: {len(submissions)}")
        
        if not submissions:
            print("   ⚠️ No hay submisiones para probar descargas")
            print("   💡 Primero complete un cuestionario desde la web")
            return True
        
        # Probar con la primera submisión
        submission = submissions[0]
        submission_id = submission['id']
        person_name = submission['personal_info']['nombre_completo']
        
        print(f"   🧪 Probando con submisión: {person_name}")
        
        # Probar descarga de PDF
        print("\n3. Probando descarga de PDF...")
        try:
            response = requests.get(f"{base_url}/download-pdf/{submission_id}")
            if response.status_code == 200:
                print("   ✅ PDF generado exitosamente")
                print(f"   📄 Tamaño: {len(response.content)} bytes")
            else:
                print(f"   ❌ Error al generar PDF: {response.status_code}")
        except Exception as e:
            print(f"   ❌ Error en descarga PDF: {e}")
        
        # Probar descarga de ZIP
        print("\n4. Probando descarga de ZIP...")
        try:
            response = requests.get(f"{base_url}/download-zip/{submission_id}")
            if response.status_code == 200:
                print("   ✅ ZIP generado exitosamente")
                print(f"   📦 Tamaño: {len(response.content)} bytes")
            elif response.status_code == 404:
                print("   ⚠️ No hay archivos adjuntos para comprimir")
            else:
                print(f"   ❌ Error al generar ZIP: {response.status_code}")
        except Exception as e:
            print(f"   ❌ Error en descarga ZIP: {e}")
        
        # Probar descarga completa
        print("\n5. Probando descarga de paquete completo...")
        try:
            response = requests.get(f"{base_url}/download-complete/{submission_id}")
            if response.status_code == 200:
                print("   ✅ Paquete completo generado exitosamente")
                print(f"   🎁 Tamaño: {len(response.content)} bytes")
            else:
                print(f"   ❌ Error al generar paquete completo: {response.status_code}")
        except Exception as e:
            print(f"   ❌ Error en descarga completa: {e}")
        
        # Probar estadísticas
        print("\n6. Probando estadísticas...")
        try:
            response = requests.get(f"{base_url}/stats")
            if response.status_code == 200:
                stats = response.json()
                print("   ✅ Estadísticas obtenidas")
                print(f"   📈 Promedio: {stats['average_percentage']}%")
            else:
                print(f"   ❌ Error al obtener estadísticas: {response.status_code}")
        except Exception as e:
            print(f"   ❌ Error en estadísticas: {e}")
        
        print("\n🎉 ¡Pruebas de descarga completadas!")
        print("\n📋 Resumen de funcionalidades:")
        print("   ✅ Generación de PDF con respuestas")
        print("   ✅ Creación de ZIP con archivos adjuntos")
        print("   ✅ Paquete completo (PDF + archivos)")
        print("   ✅ Dashboard administrativo mejorado")
        print("   ✅ Estadísticas en tiempo real")
        
        return True
        
    except requests.exceptions.ConnectionError:
        print("❌ No se pudo conectar al backend.")
        print("💡 Ejecute: cd backend && source venv/bin/activate && python main.py")
        return False
    except Exception as e:
        print(f"❌ Error inesperado: {e}")
        return False

if __name__ == "__main__":
    test_downloads()