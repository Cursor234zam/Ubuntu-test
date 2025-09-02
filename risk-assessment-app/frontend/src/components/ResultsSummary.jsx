import React from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Badge } from './ui/badge';
import { Progress } from './ui/progress';
import { CheckCircle, AlertCircle, FileText, Download } from 'lucide-react';
import { Button } from './ui/button';

const ResultsSummary = ({ submission, maxScore }) => {
  const percentage = (submission.total_score / maxScore) * 100;
  
  const getScoreColor = (percentage) => {
    if (percentage >= 80) return 'text-green-600';
    if (percentage >= 60) return 'text-yellow-600';
    if (percentage >= 40) return 'text-orange-600';
    return 'text-red-600';
  };

  const getScoreMessage = (percentage) => {
    if (percentage >= 80) return 'Excelente nivel de preparación';
    if (percentage >= 60) return 'Buen nivel de preparación con áreas de mejora';
    if (percentage >= 40) return 'Nivel medio de preparación - Se requieren mejoras significativas';
    return 'Nivel bajo de preparación - Se requiere atención urgente';
  };

  const downloadReport = () => {
    // Create a simple text report
    const report = `
REPORTE DE EVALUACIÓN DE GESTIÓN DE RIESGOS
==========================================

Fecha de Evaluación: ${new Date(submission.submission_date).toLocaleDateString()}
ID de Evaluación: ${submission.submission_id}

INFORMACIÓN PERSONAL
--------------------
Nombre: ${submission.personal_info.full_name}
Cargo: ${submission.personal_info.position}
Entidad: ${submission.personal_info.entity}
Teléfono: ${submission.personal_info.phone_number}
Email: ${submission.personal_info.email}

RESULTADOS
----------
Puntuación Total: ${submission.total_score} / ${maxScore}
Porcentaje: ${percentage.toFixed(1)}%
Evaluación: ${getScoreMessage(percentage)}

RESPUESTAS POR PREGUNTA
-----------------------
${submission.responses.map(r => `Pregunta ${r.question_id}: ${r.score} puntos`).join('\n')}
    `;

    // Create blob and download
    const blob = new Blob([report], { type: 'text/plain' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `reporte_evaluacion_${submission.submission_id}.txt`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    window.URL.revokeObjectURL(url);
  };

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <CheckCircle className="h-6 w-6 text-green-600" />
            Formulario Enviado Exitosamente
          </CardTitle>
          <CardDescription>
            Su evaluación ha sido registrada correctamente
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Score Summary */}
          <div className="space-y-4">
            <div className="flex justify-between items-center">
              <span className="text-lg font-medium">Puntuación Total</span>
              <span className={`text-2xl font-bold ${getScoreColor(percentage)}`}>
                {submission.total_score} / {maxScore}
              </span>
            </div>
            <Progress value={percentage} className="h-3" />
            <p className={`text-center font-medium ${getScoreColor(percentage)}`}>
              {percentage.toFixed(1)}% - {getScoreMessage(percentage)}
            </p>
          </div>

          {/* Submission Details */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 pt-4 border-t">
            <div>
              <p className="text-sm text-muted-foreground">ID de Evaluación</p>
              <p className="font-mono text-sm">{submission.submission_id}</p>
            </div>
            <div>
              <p className="text-sm text-muted-foreground">Fecha de Envío</p>
              <p className="text-sm">
                {new Date(submission.submission_date).toLocaleString()}
              </p>
            </div>
          </div>

          {/* Personal Info Summary */}
          <div className="space-y-2 pt-4 border-t">
            <h3 className="font-semibold">Información del Evaluado</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-2 text-sm">
              <p><span className="text-muted-foreground">Nombre:</span> {submission.personal_info.full_name}</p>
              <p><span className="text-muted-foreground">Cargo:</span> {submission.personal_info.position}</p>
              <p><span className="text-muted-foreground">Entidad:</span> {submission.personal_info.entity}</p>
              <p><span className="text-muted-foreground">Email:</span> {submission.personal_info.email}</p>
            </div>
          </div>

          {/* Question Results */}
          <div className="space-y-2 pt-4 border-t">
            <h3 className="font-semibold">Detalle por Pregunta</h3>
            <div className="grid grid-cols-1 gap-2">
              {submission.responses.map((response) => (
                <div key={response.question_id} className="flex justify-between items-center p-2 rounded-lg bg-muted/50">
                  <span className="text-sm">Pregunta {response.question_id}</span>
                  <Badge variant={response.score > 0 ? "default" : "secondary"}>
                    {response.score} puntos
                  </Badge>
                </div>
              ))}
            </div>
          </div>

          {/* Actions */}
          <div className="flex gap-4 pt-4 border-t">
            <Button onClick={downloadReport} className="flex-1">
              <Download className="mr-2 h-4 w-4" />
              Descargar Reporte
            </Button>
            <Button variant="outline" onClick={() => window.location.reload()} className="flex-1">
              Nueva Evaluación
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Recommendations */}
      {percentage < 80 && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <AlertCircle className="h-5 w-5 text-yellow-600" />
              Recomendaciones
            </CardTitle>
          </CardHeader>
          <CardContent>
            <ul className="space-y-2">
              {percentage < 40 && (
                <>
                  <li className="flex items-start gap-2">
                    <span className="text-yellow-600 mt-1">•</span>
                    <span className="text-sm">Es urgente desarrollar un Plan de Contingencia completo y aprobado por las instancias correspondientes.</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-yellow-600 mt-1">•</span>
                    <span className="text-sm">Se recomienda establecer un equipo de respuesta rápida con designaciones formales.</span>
                  </li>
                </>
              )}
              {percentage < 60 && (
                <>
                  <li className="flex items-start gap-2">
                    <span className="text-yellow-600 mt-1">•</span>
                    <span className="text-sm">Fortalecer la coordinación con entidades de emergencia (SENAMHI, VIDECI, MSyD).</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-yellow-600 mt-1">•</span>
                    <span className="text-sm">Implementar capacitaciones sobre la Ley 602 de Gestión de Riesgos.</span>
                  </li>
                </>
              )}
              <li className="flex items-start gap-2">
                <span className="text-yellow-600 mt-1">•</span>
                <span className="text-sm">Mantener actualizado el stock de medicamentos, insumos y EPP para eventos adversos.</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-yellow-600 mt-1">•</span>
                <span className="text-sm">Realizar ferias de prevención en gestión de riesgo de manera periódica.</span>
              </li>
            </ul>
          </CardContent>
        </Card>
      )}
    </div>
  );
};

export default ResultsSummary;