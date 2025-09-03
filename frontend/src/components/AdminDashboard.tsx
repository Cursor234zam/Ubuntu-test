import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { surveyApi } from '@/services/api';
import { useToast } from '@/hooks/use-toast';
import { Download, Eye, FileText, Users, TrendingUp, FileDown, Archive, Package } from 'lucide-react';

interface Submission {
  id: string;
  personal_info: {
    nombre_completo: string;
    cargo: string;
    entidad: string;
    email: string;
  };
  total_score: number;
  max_score: number;
  percentage: number;
  submission_date: string;
}

export const AdminDashboard: React.FC = () => {
  const [submissions, setSubmissions] = useState<Submission[]>([]);
  const [loading, setLoading] = useState(true);
  const [downloadingPdf, setDownloadingPdf] = useState<string | null>(null);
  const [downloadingZip, setDownloadingZip] = useState<string | null>(null);
  const [downloadingComplete, setDownloadingComplete] = useState<string | null>(null);
  const [selectedSubmission, setSelectedSubmission] = useState<Submission | null>(null);
  const { toast } = useToast();

  useEffect(() => {
    loadSubmissions();
  }, []);

  const loadSubmissions = async () => {
    try {
      const data = await surveyApi.getSubmissions();
      setSubmissions(data.submissions);
    } catch (error) {
      toast({
        title: "Error",
        description: "No se pudieron cargar las submisiones",
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  };

  const getScoreColor = (percentage: number) => {
    if (percentage >= 80) return "bg-green-100 text-green-800";
    if (percentage >= 60) return "bg-yellow-100 text-yellow-800";
    return "bg-red-100 text-red-800";
  };

  const calculateStats = () => {
    if (submissions.length === 0) return { average: 0, highest: 0, lowest: 0 };
    
    const percentages = submissions.map(s => s.percentage);
    return {
      average: Math.round(percentages.reduce((a, b) => a + b, 0) / percentages.length),
      highest: Math.max(...percentages),
      lowest: Math.min(...percentages)
    };
  };

  const stats = calculateStats();

  const downloadFile = (blob: Blob, filename: string) => {
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.style.display = 'none';
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    window.URL.revokeObjectURL(url);
    document.body.removeChild(a);
  };

  const handleDownloadPDF = async (submissionId: string, personName: string) => {
    setDownloadingPdf(submissionId);
    try {
      const blob = await surveyApi.downloadPDF(submissionId);
      const filename = `cuestionario_${personName.replace(/\s+/g, '_')}_${submissionId.substring(0, 8)}.pdf`;
      downloadFile(blob, filename);
      
      toast({
        title: "Descarga exitosa",
        description: "PDF descargado correctamente"
      });
    } catch (error: any) {
      toast({
        title: "Error",
        description: error.response?.data?.detail || "Error al descargar PDF",
        variant: "destructive"
      });
    } finally {
      setDownloadingPdf(null);
    }
  };

  const handleDownloadZIP = async (submissionId: string, personName: string) => {
    setDownloadingZip(submissionId);
    try {
      const blob = await surveyApi.downloadZIP(submissionId);
      const filename = `archivos_${personName.replace(/\s+/g, '_')}_${submissionId.substring(0, 8)}.zip`;
      downloadFile(blob, filename);
      
      toast({
        title: "Descarga exitosa",
        description: "Archivos ZIP descargados correctamente"
      });
    } catch (error: any) {
      toast({
        title: "Error",
        description: error.response?.data?.detail || "Error al descargar archivos",
        variant: "destructive"
      });
    } finally {
      setDownloadingZip(null);
    }
  };

  const handleDownloadComplete = async (submissionId: string, personName: string) => {
    setDownloadingComplete(submissionId);
    try {
      const blob = await surveyApi.downloadComplete(submissionId);
      const filename = `paquete_completo_${personName.replace(/\s+/g, '_')}_${submissionId.substring(0, 8)}.zip`;
      downloadFile(blob, filename);
      
      toast({
        title: "Descarga exitosa",
        description: "Paquete completo descargado correctamente"
      });
    } catch (error: any) {
      toast({
        title: "Error",
        description: error.response?.data?.detail || "Error al descargar paquete completo",
        variant: "destructive"
      });
    } finally {
      setDownloadingComplete(null);
    }
  };

  const handleViewDetails = async (submissionId: string) => {
    try {
      const submission = await surveyApi.getSubmission(submissionId);
      setSelectedSubmission(submission);
    } catch (error) {
      toast({
        title: "Error",
        description: "No se pudo cargar la información detallada",
        variant: "destructive"
      });
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center min-h-screen">
        <div className="text-center">
          <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-primary"></div>
          <p className="mt-4 text-muted-foreground">Cargando dashboard...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8 max-w-6xl">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-primary mb-2">
          Dashboard Administrativo
        </h1>
        <p className="text-muted-foreground">
          Gestión y análisis de cuestionarios de gestión de riesgos
        </p>
      </div>

      {/* Estadísticas generales */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-2">
              <Users className="h-8 w-8 text-primary" />
              <div>
                <p className="text-2xl font-bold">{submissions.length}</p>
                <p className="text-sm text-muted-foreground">Total Submisiones</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-2">
              <TrendingUp className="h-8 w-8 text-green-600" />
              <div>
                <p className="text-2xl font-bold">{stats.average}%</p>
                <p className="text-sm text-muted-foreground">Promedio</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-2">
              <TrendingUp className="h-8 w-8 text-blue-600" />
              <div>
                <p className="text-2xl font-bold">{stats.highest}%</p>
                <p className="text-sm text-muted-foreground">Puntuación Más Alta</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-2">
              <TrendingUp className="h-8 w-8 text-red-600" />
              <div>
                <p className="text-2xl font-bold">{stats.lowest}%</p>
                <p className="text-sm text-muted-foreground">Puntuación Más Baja</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Lista de submisiones */}
      <Card>
        <CardHeader>
          <CardTitle>Submisiones Recientes</CardTitle>
        </CardHeader>
        <CardContent>
          {submissions.length === 0 ? (
            <div className="text-center py-8">
              <FileText className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
              <p className="text-muted-foreground">No hay submisiones disponibles</p>
            </div>
          ) : (
            <div className="space-y-4">
              {submissions.map((submission) => (
                <Card key={submission.id} className="border-l-4 border-l-primary">
                  <CardContent className="p-4">
                    <div className="flex flex-col md:flex-row md:items-center md:justify-between space-y-2 md:space-y-0">
                      <div className="space-y-1">
                        <h3 className="font-semibold">{submission.personal_info.nombre_completo}</h3>
                        <p className="text-sm text-muted-foreground">
                          {submission.personal_info.cargo} - {submission.personal_info.entidad}
                        </p>
                        <p className="text-xs text-muted-foreground">
                          {new Date(submission.submission_date).toLocaleString('es-ES')}
                        </p>
                      </div>
                      
                      <div className="flex items-center space-x-4">
                        <div className="text-center">
                          <p className="text-lg font-bold">{submission.total_score}/{submission.max_score}</p>
                          <Badge className={getScoreColor(submission.percentage)}>
                            {submission.percentage}%
                          </Badge>
                        </div>
                        
                        <div className="flex flex-wrap gap-2">
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => handleViewDetails(submission.id)}
                          >
                            <Eye className="h-4 w-4 mr-1" />
                            Ver
                          </Button>
                          
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => handleDownloadPDF(submission.id, submission.personal_info.nombre_completo)}
                            disabled={downloadingPdf === submission.id}
                          >
                            {downloadingPdf === submission.id ? (
                              <div className="animate-spin rounded-full h-3 w-3 border-b-2 border-current mr-1"></div>
                            ) : (
                              <FileDown className="h-4 w-4 mr-1" />
                            )}
                            PDF
                          </Button>
                          
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => handleDownloadZIP(submission.id, submission.personal_info.nombre_completo)}
                            disabled={downloadingZip === submission.id}
                          >
                            {downloadingZip === submission.id ? (
                              <div className="animate-spin rounded-full h-3 w-3 border-b-2 border-current mr-1"></div>
                            ) : (
                              <Archive className="h-4 w-4 mr-1" />
                            )}
                            ZIP
                          </Button>
                          
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => handleDownloadComplete(submission.id, submission.personal_info.nombre_completo)}
                            disabled={downloadingComplete === submission.id}
                          >
                            {downloadingComplete === submission.id ? (
                              <div className="animate-spin rounded-full h-3 w-3 border-b-2 border-current mr-1"></div>
                            ) : (
                              <Package className="h-4 w-4 mr-1" />
                            )}
                            Completo
                          </Button>
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Modal de detalles */}
      {selectedSubmission && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <Card className="max-w-4xl max-h-[90vh] overflow-y-auto w-full">
            <CardHeader>
              <div className="flex justify-between items-start">
                <CardTitle>Detalles de la Submisión</CardTitle>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => setSelectedSubmission(null)}
                >
                  ✕
                </Button>
              </div>
            </CardHeader>
            
            <CardContent className="space-y-6">
              {/* Información personal */}
              <div>
                <h3 className="text-lg font-semibold mb-3">Información Personal</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                  <div><strong>Nombre:</strong> {selectedSubmission.personal_info.nombre_completo}</div>
                  <div><strong>Cargo:</strong> {selectedSubmission.personal_info.cargo}</div>
                  <div><strong>Entidad:</strong> {selectedSubmission.personal_info.entidad}</div>
                  <div><strong>Email:</strong> {selectedSubmission.personal_info.email}</div>
                  <div><strong>Fecha:</strong> {new Date(selectedSubmission.submission_date).toLocaleString('es-ES')}</div>
                </div>
              </div>

              {/* Puntuación */}
              <div>
                <h3 className="text-lg font-semibold mb-3">Puntuación</h3>
                <div className="grid grid-cols-3 gap-4 text-center">
                  <div className="bg-muted p-3 rounded">
                    <p className="text-2xl font-bold text-primary">{selectedSubmission.total_score}</p>
                    <p className="text-sm text-muted-foreground">Puntos Obtenidos</p>
                  </div>
                  <div className="bg-muted p-3 rounded">
                    <p className="text-2xl font-bold text-primary">{selectedSubmission.max_score}</p>
                    <p className="text-sm text-muted-foreground">Puntos Máximos</p>
                  </div>
                  <div className="bg-muted p-3 rounded">
                    <p className="text-2xl font-bold text-primary">{selectedSubmission.percentage}%</p>
                    <p className="text-sm text-muted-foreground">Porcentaje</p>
                  </div>
                </div>
              </div>

              {/* Respuestas */}
              <div>
                <h3 className="text-lg font-semibold mb-3">Respuestas</h3>
                <div className="space-y-3 max-h-96 overflow-y-auto">
                  {selectedSubmission.responses?.map((response: any) => (
                    <Card key={response.question_id} className="p-3">
                      <div className="flex justify-between items-start mb-2">
                        <h4 className="font-medium">Pregunta {response.question_id}</h4>
                        <Badge variant={response.score > 0 ? "default" : "secondary"}>
                          {response.score} pts
                        </Badge>
                      </div>
                      <p className="text-sm text-muted-foreground mb-2">
                        <strong>Respuesta:</strong> {response.answer}
                      </p>
                      {response.file_path && (
                        <p className="text-sm text-blue-600">
                          <strong>Archivo:</strong> {response.file_path.split('/').pop()}
                        </p>
                      )}
                    </Card>
                  ))}
                </div>
              </div>

              {/* Botones de descarga */}
              <div className="flex flex-wrap gap-3 pt-4 border-t">
                <Button
                  onClick={() => handleDownloadPDF(selectedSubmission.id, selectedSubmission.personal_info.nombre_completo)}
                  disabled={downloadingPdf === selectedSubmission.id}
                  className="flex-1 min-w-[150px]"
                >
                  {downloadingPdf === selectedSubmission.id ? (
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-current mr-2"></div>
                  ) : (
                    <FileDown className="h-4 w-4 mr-2" />
                  )}
                  Descargar PDF
                </Button>
                
                <Button
                  variant="outline"
                  onClick={() => handleDownloadZIP(selectedSubmission.id, selectedSubmission.personal_info.nombre_completo)}
                  disabled={downloadingZip === selectedSubmission.id}
                  className="flex-1 min-w-[150px]"
                >
                  {downloadingZip === selectedSubmission.id ? (
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-current mr-2"></div>
                  ) : (
                    <Archive className="h-4 w-4 mr-2" />
                  )}
                  Descargar Archivos
                </Button>
                
                <Button
                  variant="secondary"
                  onClick={() => handleDownloadComplete(selectedSubmission.id, selectedSubmission.personal_info.nombre_completo)}
                  disabled={downloadingComplete === selectedSubmission.id}
                  className="flex-1 min-w-[150px]"
                >
                  {downloadingComplete === selectedSubmission.id ? (
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-current mr-2"></div>
                  ) : (
                    <Package className="h-4 w-4 mr-2" />
                  )}
                  Paquete Completo
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  );
};