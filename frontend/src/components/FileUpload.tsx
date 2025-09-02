import React, { useState } from 'react';
import { Upload, File, X, CheckCircle } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { useToast } from '@/hooks/use-toast';
import { surveyApi } from '@/services/api';

interface FileUploadProps {
  onFileUploaded: (filePath: string, fileName: string) => void;
  acceptedTypes?: string;
  description?: string;
  required?: boolean;
}

export const FileUpload: React.FC<FileUploadProps> = ({
  onFileUploaded,
  acceptedTypes = ".pdf,.png,.jpg,.jpeg,.doc,.docx,.txt",
  description = "Suba el archivo requerido",
  required = false
}) => {
  const [uploading, setUploading] = useState(false);
  const [uploadedFile, setUploadedFile] = useState<{ name: string; path: string } | null>(null);
  const { toast } = useToast();

  const handleFileChange = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    // Validar tamaño del archivo (max 10MB)
    if (file.size > 10 * 1024 * 1024) {
      toast({
        title: "Error",
        description: "El archivo es demasiado grande. Máximo 10MB.",
        variant: "destructive"
      });
      return;
    }

    setUploading(true);
    
    try {
      const response = await surveyApi.uploadFile(file);
      setUploadedFile({ name: response.filename, path: response.file_path });
      onFileUploaded(response.file_path, response.filename);
      
      toast({
        title: "Éxito",
        description: "Archivo subido correctamente",
      });
    } catch (error: any) {
      toast({
        title: "Error",
        description: error.response?.data?.detail || "Error al subir el archivo",
        variant: "destructive"
      });
    } finally {
      setUploading(false);
    }
  };

  const removeFile = () => {
    setUploadedFile(null);
    onFileUploaded('', '');
  };

  return (
    <div className="space-y-2">
      <p className="text-sm text-muted-foreground">{description}</p>
      
      {!uploadedFile ? (
        <Card className="border-dashed border-2 hover:border-primary/50 transition-colors">
          <CardContent className="flex flex-col items-center justify-center p-6">
            <Upload className="h-8 w-8 text-muted-foreground mb-2" />
            <div className="text-center">
              <Button 
                variant="ghost" 
                className="relative"
                disabled={uploading}
              >
                <input
                  type="file"
                  className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                  accept={acceptedTypes}
                  onChange={handleFileChange}
                  disabled={uploading}
                />
                {uploading ? "Subiendo..." : "Seleccionar archivo"}
              </Button>
              <p className="text-xs text-muted-foreground mt-1">
                PDF, imágenes, documentos (máx. 10MB)
              </p>
            </div>
          </CardContent>
        </Card>
      ) : (
        <Card className="border-green-200 bg-green-50">
          <CardContent className="flex items-center justify-between p-4">
            <div className="flex items-center space-x-2">
              <CheckCircle className="h-4 w-4 text-green-600" />
              <File className="h-4 w-4 text-muted-foreground" />
              <span className="text-sm truncate">{uploadedFile.name}</span>
            </div>
            <Button
              variant="ghost"
              size="sm"
              onClick={removeFile}
              className="text-red-600 hover:text-red-700"
            >
              <X className="h-4 w-4" />
            </Button>
          </CardContent>
        </Card>
      )}
    </div>
  );
};