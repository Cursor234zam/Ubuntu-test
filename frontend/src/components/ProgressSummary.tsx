import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';
import { CheckCircle, AlertCircle, FileText, User } from 'lucide-react';
import { PersonalInfo, Question, QuestionResponse } from '@/types/survey';

interface ProgressSummaryProps {
  personalInfo: PersonalInfo;
  questions: Question[];
  responses: Map<number, QuestionResponse>;
}

export const ProgressSummary: React.FC<ProgressSummaryProps> = ({
  personalInfo,
  questions,
  responses
}) => {
  const isPersonalInfoComplete = Object.values(personalInfo).every(value => value.trim() !== '');
  
  const completedQuestions = questions.filter(q => {
    const response = responses.get(q.id);
    if (!response || !response.answer.trim()) return false;
    if (q.requires_file && (!response.file_path || response.file_path.trim() === '')) return false;
    return true;
  });

  const questionsWithFiles = questions.filter(q => q.requires_file);
  const questionsWithUploadedFiles = questionsWithFiles.filter(q => {
    const response = responses.get(q.id);
    return response?.file_path && response.file_path.trim() !== '';
  });

  const totalScore = Array.from(responses.values()).reduce((sum, r) => sum + r.score, 0);
  const maxScore = questions.reduce((sum, q) => sum + q.score, 0);

  const progress = ((isPersonalInfoComplete ? 1 : 0) + completedQuestions.length) / (questions.length + 1) * 100;

  return (
    <Card className="bg-muted/30">
      <CardHeader>
        <CardTitle className="flex items-center space-x-2">
          <FileText className="h-5 w-5" />
          <span>Resumen del Progreso</span>
        </CardTitle>
      </CardHeader>
      
      <CardContent className="space-y-4">
        {/* Progreso general */}
        <div className="space-y-2">
          <div className="flex justify-between text-sm">
            <span>Progreso total</span>
            <span>{Math.round(progress)}%</span>
          </div>
          <Progress value={progress} className="w-full" />
        </div>

        {/* Estadísticas */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
          <div className="space-y-1">
            <div className="flex items-center justify-center">
              {isPersonalInfoComplete ? (
                <CheckCircle className="h-5 w-5 text-green-600" />
              ) : (
                <AlertCircle className="h-5 w-5 text-yellow-600" />
              )}
            </div>
            <p className="text-sm font-medium">Info Personal</p>
            <p className="text-xs text-muted-foreground">
              {isPersonalInfoComplete ? 'Completa' : 'Pendiente'}
            </p>
          </div>

          <div className="space-y-1">
            <div className="text-lg font-bold text-primary">
              {completedQuestions.length}/{questions.length}
            </div>
            <p className="text-sm font-medium">Preguntas</p>
            <p className="text-xs text-muted-foreground">Respondidas</p>
          </div>

          <div className="space-y-1">
            <div className="text-lg font-bold text-primary">
              {questionsWithUploadedFiles.length}/{questionsWithFiles.length}
            </div>
            <p className="text-sm font-medium">Archivos</p>
            <p className="text-xs text-muted-foreground">Subidos</p>
          </div>

          <div className="space-y-1">
            <div className="text-lg font-bold text-primary">
              {totalScore}/{maxScore}
            </div>
            <p className="text-sm font-medium">Puntuación</p>
            <p className="text-xs text-muted-foreground">
              {maxScore > 0 ? Math.round((totalScore / maxScore) * 100) : 0}%
            </p>
          </div>
        </div>

        {/* Lista de pendientes */}
        {progress < 100 && (
          <div className="space-y-2">
            <h4 className="text-sm font-medium text-muted-foreground">Pendientes:</h4>
            <div className="space-y-1 text-xs">
              {!isPersonalInfoComplete && (
                <div className="flex items-center space-x-2 text-yellow-700">
                  <User className="h-3 w-3" />
                  <span>Completar información personal</span>
                </div>
              )}
              
              {questions.map(q => {
                const response = responses.get(q.id);
                const isComplete = response?.answer.trim() && 
                  (!q.requires_file || (response.file_path && response.file_path.trim() !== ''));
                
                if (!isComplete) {
                  return (
                    <div key={q.id} className="flex items-center space-x-2 text-yellow-700">
                      <AlertCircle className="h-3 w-3" />
                      <span>Pregunta {q.id}: {!response?.answer.trim() ? 'Responder' : 'Subir archivo'}</span>
                    </div>
                  );
                }
                return null;
              })}
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
};