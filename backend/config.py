import os
from decouple import config

class Settings:
    APP_NAME: str = config("APP_NAME", default="Cuestionario Gestión de Riesgos")
    APP_VERSION: str = config("APP_VERSION", default="1.0.0")
    DEBUG: bool = config("DEBUG", default=True, cast=bool)
    
    # Configuración de archivos
    MAX_FILE_SIZE: int = config("MAX_FILE_SIZE", default=10485760, cast=int)  # 10MB
    UPLOAD_DIRECTORY: str = config("UPLOAD_DIRECTORY", default="uploads")
    
    # Configuración CORS
    ALLOWED_ORIGINS: list = config(
        "ALLOWED_ORIGINS", 
        default="http://localhost:3000,http://localhost:5173",
        cast=lambda v: [s.strip() for s in v.split(',')]
    )
    
    # Base de datos (para futuras implementaciones)
    DATABASE_URL: str = config("DATABASE_URL", default="sqlite:///./survey.db")

settings = Settings()