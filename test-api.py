#!/usr/bin/env python3
"""
Script de prueba para verificar que la API del backend funcione correctamente.
"""

import requests
import json

def test_api():
    base_url = "http://localhost:8000"
    
    print("🧪 Probando API del backend...")
    print("=" * 50)
    
    try:
        # Probar endpoint raíz
        print("1. Probando endpoint raíz...")
        response = requests.get(f"{base_url}/")
        if response.status_code == 200:
            print("   ✅ Endpoint raíz funcionando")
            print(f"   📝 Respuesta: {response.json()}")
        else:
            print(f"   ❌ Error en endpoint raíz: {response.status_code}")
            return False
        
        # Probar endpoint de preguntas
        print("\n2. Probando endpoint de preguntas...")
        response = requests.get(f"{base_url}/questions")
        if response.status_code == 200:
            data = response.json()
            print("   ✅ Endpoint de preguntas funcionando")
            print(f"   📊 Total de preguntas: {len(data['questions'])}")
        else:
            print(f"   ❌ Error en endpoint de preguntas: {response.status_code}")
            return False
        
        # Probar endpoint de estadísticas
        print("\n3. Probando endpoint de estadísticas...")
        response = requests.get(f"{base_url}/stats")
        if response.status_code == 200:
            print("   ✅ Endpoint de estadísticas funcionando")
            print(f"   📈 Estadísticas: {response.json()}")
        else:
            print(f"   ❌ Error en endpoint de estadísticas: {response.status_code}")
            return False
            
        print("\n🎉 ¡Todos los tests pasaron exitosamente!")
        print("🚀 La API está lista para usar")
        return True
        
    except requests.exceptions.ConnectionError:
        print("❌ No se pudo conectar al backend. Asegúrese de que esté ejecutándose en puerto 8000")
        return False
    except Exception as e:
        print(f"❌ Error inesperado: {e}")
        return False

if __name__ == "__main__":
    test_api()