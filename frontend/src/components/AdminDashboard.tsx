import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { surveyApi } from '@/services/api';
import { useToast } from '@/hooks/use-toast';
import { Download, Eye, FileText, Users, TrendingUp } from 'lucide-react';

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
                        
                        <div className="flex space-x-2">
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => {
                              // Aquí se podría implementar la vista detallada
                              toast({
                                title: "Función en desarrollo",
                                description: "Vista detallada próximamente"
                              });
                            }}
                          >
                            <Eye className="h-4 w-4 mr-1" />
                            Ver
                          </Button>
                          
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => {
                              // Aquí se podría implementar la descarga
                              toast({
                                title: "Función en desarrollo",
                                description: "Descarga próximamente"
                              });
                            }}
                          >
                            <Download className="h-4 w-4 mr-1" />
                            Descargar
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
    </div>
  );
};