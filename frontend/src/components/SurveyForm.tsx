import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Progress } from '@/components/ui/progress';
import { PersonalInfoForm } from '@/components/PersonalInfoForm';
import { QuestionCard } from '@/components/QuestionCard';
import { ProgressSummary } from '@/components/ProgressSummary';
import { useToast } from '@/hooks/use-toast';
import { surveyApi } from '@/services/api';
import { PersonalInfo, Question, QuestionResponse, SurveySubmission } from '@/types/survey';
import { CheckCircle, AlertCircle, Send } from 'lucide-react';

export const SurveyForm: React.FC = () => {
  const [questions, setQuestions] = useState<Question[]>([]);
  const [personalInfo, setPersonalInfo] = useState<PersonalInfo>({
    nombre_completo: '',
    cargo: '',
    entidad: '',
    celular: '',
    email: ''
  });
  const [responses, setResponses] = useState<Map<number, QuestionResponse>>(new Map());
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [submissionResult, setSubmissionResult] = useState<any>(null);
  const { toast } = useToast();

  useEffect(() => {
    loadQuestions();
  }, []);

  const loadQuestions = async () => {
    try {
      const data = await surveyApi.getQuestions();
      setQuestions(data.questions);
    } catch (error) {
      toast({
        title: "Error",
        description: "No se pudieron cargar las preguntas",
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  };

  const handleResponseChange = (response: QuestionResponse) => {
    setResponses(prev => new Map(prev.set(response.question_id, response)));
  };

  const validateForm = (): boolean => {
    // Validar información personal
    const requiredPersonalFields = ['nombre_completo', 'cargo', 'entidad', 'celular', 'email'];
    for (const field of requiredPersonalFields) {
      if (!personalInfo[field as keyof PersonalInfo]?.trim()) {
        toast({
          title: "Error de validación",
          description: `El campo ${field.replace('_', ' ')} es requerido`,
          variant: "destructive"
        });
        return false;
      }
    }

    // Validar email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(personalInfo.email)) {
      toast({
        title: "Error de validación",
        description: "El correo electrónico no es válido",
        variant: "destructive"
      });
      return false;
    }

    // Validar que todas las preguntas estén respondidas
    for (const question of questions) {
      const response = responses.get(question.id);
      if (!response || !response.answer.trim()) {
        toast({
          title: "Error de validación",
          description: `La pregunta ${question.id} debe ser respondida`,
          variant: "destructive"
        });
        return false;
      }

      // Validar archivos requeridos
      if (question.requires_file && (!response.file_path || response.file_path.trim() === '')) {
        toast({
          title: "Error de validación",
          description: `La pregunta ${question.id} requiere un archivo adjunto`,
          variant: "destructive"
        });
        return false;
      }
    }

    return true;
  };

  const handleSubmit = async () => {
    if (!validateForm()) return;

    setSubmitting(true);
    try {
      const responsesArray = Array.from(responses.values());
      const totalScore = responsesArray.reduce((sum, r) => sum + r.score, 0);

      const submission: SurveySubmission = {
        personal_info: personalInfo,
        responses: responsesArray,
        total_score: totalScore,
        submission_date: new Date()
      };

      const result = await surveyApi.submitSurvey(submission);
      setSubmissionResult(result);
      setSubmitted(true);
      
      toast({
        title: "¡Éxito!",
        description: "Cuestionario enviado correctamente",
      });
    } catch (error: any) {
      toast({
        title: "Error",
        description: error.response?.data?.detail || "Error al enviar el cuestionario",
        variant: "destructive"
      });
    } finally {
      setSubmitting(false);
    }
  };

  const calculateProgress = (): number => {
    const totalQuestions = questions.length + 1; // +1 para información personal
    const completedPersonalInfo = Object.values(personalInfo).every(value => value.trim() !== '') ? 1 : 0;
    const completedQuestions = Array.from(responses.values()).filter(r => 
      r.answer.trim() !== '' && (!questions.find(q => q.id === r.question_id)?.requires_file || r.file_path)
    ).length;
    
    return ((completedPersonalInfo + completedQuestions) / totalQuestions) * 100;
  };

  const calculateTotalScore = (): { current: number; max: number } => {
    const current = Array.from(responses.values()).reduce((sum, r) => sum + r.score, 0);
    const max = questions.reduce((sum, q) => sum + q.score, 0);
    return { current, max };
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center min-h-screen">
        <div className="text-center">
          <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-primary"></div>
          <p className="mt-4 text-muted-foreground">Cargando cuestionario...</p>
        </div>
      </div>
    );
  }

  if (submitted && submissionResult) {
    return (
      <div className="container mx-auto px-4 py-8 max-w-4xl">
        <Card className="border-green-200 bg-green-50">
          <CardHeader className="text-center">
            <div className="flex justify-center mb-4">
              <CheckCircle className="h-16 w-16 text-green-600" />
            </div>
            <CardTitle className="text-2xl text-green-800">
              ¡Cuestionario Enviado Exitosamente!
            </CardTitle>
          </CardHeader>
          
          <CardContent className="text-center space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-center">
              <div className="bg-white p-4 rounded-lg">
                <p className="text-2xl font-bold text-primary">{submissionResult.total_score}</p>
                <p className="text-sm text-muted-foreground">Puntuación Total</p>
              </div>
              <div className="bg-white p-4 rounded-lg">
                <p className="text-2xl font-bold text-primary">{submissionResult.max_score}</p>
                <p className="text-sm text-muted-foreground">Puntuación Máxima</p>
              </div>
              <div className="bg-white p-4 rounded-lg">
                <p className="text-2xl font-bold text-primary">{submissionResult.percentage}%</p>
                <p className="text-sm text-muted-foreground">Porcentaje</p>
              </div>
            </div>
            
            <p className="text-muted-foreground">
              ID de Submisión: <code className="bg-white px-2 py-1 rounded">{submissionResult.submission_id}</code>
            </p>
            
            <Button 
              onClick={() => window.location.reload()} 
              variant="outline"
              className="mt-4"
            >
              Realizar Nuevo Cuestionario
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  const progress = calculateProgress();
  const { current: currentScore, max: maxScore } = calculateTotalScore();

  return (
    <div className="container mx-auto px-4 py-8 max-w-4xl">
      {/* Header */}
      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold text-primary mb-2">
          Cuestionario de Gestión de Riesgos en Salud
        </h1>
        <p className="text-muted-foreground">
          Complete todas las preguntas y adjunte los documentos requeridos
        </p>
      </div>

      {/* Progress Bar */}
      <Card className="mb-6">
        <CardContent className="pt-6">
          <div className="space-y-2">
            <div className="flex justify-between text-sm">
              <span>Progreso del cuestionario</span>
              <span>{Math.round(progress)}% completado</span>
            </div>
            <Progress value={progress} className="w-full" />
            <div className="flex justify-between text-sm text-muted-foreground">
              <span>Puntuación: {currentScore} / {maxScore}</span>
              <span>{maxScore > 0 ? Math.round((currentScore / maxScore) * 100) : 0}%</span>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Progress Summary */}
      <div className="mb-6">
        <ProgressSummary
          personalInfo={personalInfo}
          questions={questions}
          responses={responses}
        />
      </div>

      {/* Personal Information */}
      <div className="mb-6">
        <PersonalInfoForm
          personalInfo={personalInfo}
          onPersonalInfoChange={setPersonalInfo}
        />
      </div>

      {/* Questions */}
      <div className="space-y-6">
        {questions.map((question) => (
          <QuestionCard
            key={question.id}
            question={question}
            response={responses.get(question.id)}
            onResponseChange={handleResponseChange}
          />
        ))}
      </div>

      {/* Submit Button */}
      <div className="mt-8 text-center">
        <Card className="bg-muted/50">
          <CardContent className="pt-6">
            <div className="space-y-4">
              <div className="flex items-center justify-center space-x-2">
                {progress === 100 ? (
                  <CheckCircle className="h-5 w-5 text-green-600" />
                ) : (
                  <AlertCircle className="h-5 w-5 text-yellow-600" />
                )}
                <span className="text-sm">
                  {progress === 100 
                    ? "Formulario completo - Listo para enviar" 
                    : `Complete el formulario para continuar (${Math.round(progress)}%)`
                  }
                </span>
              </div>
              
              <Button
                onClick={handleSubmit}
                disabled={progress < 100 || submitting}
                size="lg"
                className="w-full md:w-auto"
              >
                {submitting ? (
                  <>
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                    Enviando...
                  </>
                ) : (
                  <>
                    <Send className="h-4 w-4 mr-2" />
                    Enviar Cuestionario
                  </>
                )}
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};