import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Button } from '@/components/ui/button';
import { FileUpload } from '@/components/FileUpload';
import { Question, QuestionResponse } from '@/types/survey';

interface QuestionCardProps {
  question: Question;
  response: QuestionResponse | undefined;
  onResponseChange: (response: QuestionResponse) => void;
}

export const QuestionCard: React.FC<QuestionCardProps> = ({
  question,
  response,
  onResponseChange
}) => {
  const [answer, setAnswer] = useState(response?.answer || '');
  const [filePath, setFilePath] = useState(response?.file_path || '');

  const handleAnswerChange = (newAnswer: string) => {
    setAnswer(newAnswer);
    
    // Calcular puntuación basada en la respuesta
    let score = 0;
    if (question.requires_file) {
      // Para preguntas que requieren archivo, la puntuación se otorga si hay archivo y respuesta
      score = (newAnswer.trim() !== '' && filePath !== '') ? question.score : 0;
    } else {
      // Para preguntas de sí/no o texto, la puntuación se otorga si la respuesta es "Sí" o hay texto
      score = (newAnswer.toLowerCase().includes('sí') || newAnswer.toLowerCase().includes('si') || 
               (newAnswer.trim() !== '' && !['no', 'No', 'NO'].includes(newAnswer.trim()))) ? question.score : 0;
    }

    onResponseChange({
      question_id: question.id,
      answer: newAnswer,
      score,
      file_path: filePath || undefined
    });
  };

  const handleFileUploaded = (path: string, fileName: string) => {
    setFilePath(path);
    
    // Recalcular puntuación cuando se sube un archivo
    let score = 0;
    if (question.requires_file) {
      score = (answer.trim() !== '' && path !== '') ? question.score : 0;
    } else {
      score = (answer.toLowerCase().includes('sí') || answer.toLowerCase().includes('si') || 
               (answer.trim() !== '' && !['no', 'No', 'NO'].includes(answer.trim()))) ? question.score : 0;
    }

    onResponseChange({
      question_id: question.id,
      answer,
      score,
      file_path: path || undefined
    });
  };

  const isYesNoQuestion = question.file_description.includes('solo si/no') || 
                         question.file_description.includes('Solo sí/no');

  const isContactQuestion = question.file_description.includes('escriba el contacto') ||
                           question.file_description.includes('solo datos');

  return (
    <Card className="w-full">
      <CardHeader>
        <CardTitle className="text-lg flex items-start justify-between">
          <span className="flex-1">{question.id}. {question.text}</span>
          <span className="text-sm font-normal bg-primary text-primary-foreground px-2 py-1 rounded">
            {question.score} pts
          </span>
        </CardTitle>
      </CardHeader>
      
      <CardContent className="space-y-4">
        {/* Campo de respuesta */}
        <div className="space-y-2">
          <Label htmlFor={`answer-${question.id}`}>
            Respuesta {question.requires_file && !isYesNoQuestion && !isContactQuestion && '*'}
          </Label>
          
          {isYesNoQuestion ? (
            <div className="flex space-x-4">
              <Button
                type="button"
                variant={answer === 'Sí' ? 'default' : 'outline'}
                onClick={() => handleAnswerChange('Sí')}
                className="w-20"
              >
                Sí
              </Button>
              <Button
                type="button"
                variant={answer === 'No' ? 'default' : 'outline'}
                onClick={() => handleAnswerChange('No')}
                className="w-20"
              >
                No
              </Button>
            </div>
          ) : isContactQuestion ? (
            <Textarea
              id={`answer-${question.id}`}
              placeholder="Proporcione los datos solicitados (nombre, cargo, contacto, etc.)"
              value={answer}
              onChange={(e) => handleAnswerChange(e.target.value)}
              className="min-h-[100px]"
            />
          ) : (
            <Input
              id={`answer-${question.id}`}
              placeholder="Ingrese su respuesta"
              value={answer}
              onChange={(e) => handleAnswerChange(e.target.value)}
            />
          )}
        </div>

        {/* Subida de archivo si es requerido */}
        {question.requires_file && (
          <div className="space-y-2">
            <Label>
              Archivo adjunto {question.requires_file ? '*' : ''}
            </Label>
            <FileUpload
              onFileUploaded={handleFileUploaded}
              description={question.file_description}
              required={question.requires_file}
            />
          </div>
        )}

        {/* Mostrar puntuación actual */}
        <div className="text-sm text-muted-foreground">
          Puntuación actual: {response?.score || 0} / {question.score}
        </div>
      </CardContent>
    </Card>
  );
};