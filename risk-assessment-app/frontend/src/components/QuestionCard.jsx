import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Textarea } from './ui/textarea';
import { RadioGroup, RadioGroupItem } from './ui/radio-group';
import { Badge } from './ui/badge';
import { Upload, FileText, Check, X } from 'lucide-react';

const QuestionCard = ({ question, questionNumber, onAnswerChange, answer }) => {
  const [file, setFile] = useState(null);
  const [textAnswer, setTextAnswer] = useState(answer?.text || '');
  const [yesNoAnswer, setYesNoAnswer] = useState(answer?.yesNo || '');
  const [uploading, setUploading] = useState(false);

  const handleFileChange = async (e) => {
    const selectedFile = e.target.files[0];
    if (selectedFile) {
      setFile(selectedFile);
      setUploading(true);
      
      // Create FormData
      const formData = new FormData();
      formData.append('file', selectedFile);
      formData.append('question_id', questionNumber);
      
      try {
        const response = await fetch('http://localhost:8000/api/upload', {
          method: 'POST',
          body: formData
        });
        
        if (response.ok) {
          const data = await response.json();
          onAnswerChange(questionNumber, {
            file: data.filename,
            filePath: data.file_path,
            score: question.score
          });
        }
      } catch (error) {
        console.error('Error uploading file:', error);
      } finally {
        setUploading(false);
      }
    }
  };

  const handleTextChange = (value) => {
    setTextAnswer(value);
    onAnswerChange(questionNumber, {
      text: value,
      score: value ? question.score : 0
    });
  };

  const handleYesNoChange = (value) => {
    setYesNoAnswer(value);
    onAnswerChange(questionNumber, {
      yesNo: value,
      score: value === 'yes' ? question.score : 0
    });
  };

  const removeFile = () => {
    setFile(null);
    onAnswerChange(questionNumber, {
      file: null,
      filePath: null,
      score: 0
    });
  };

  return (
    <Card className="w-full">
      <CardHeader>
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <CardTitle className="text-lg">
              {questionNumber}. {question.text}
            </CardTitle>
          </div>
          <Badge variant="secondary" className="ml-4">
            {question.score} puntos
          </Badge>
        </div>
      </CardHeader>
      <CardContent>
        {/* File upload section */}
        {question.requires_file && (
          <div className="space-y-2">
            <Label>{question.file_description}</Label>
            <div className="flex items-center gap-4">
              <div className="flex-1">
                <Input
                  type="file"
                  onChange={handleFileChange}
                  accept=".pdf,.jpg,.jpeg,.png,.doc,.docx"
                  disabled={uploading}
                  className="file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-primary file:text-primary-foreground hover:file:bg-primary/90"
                />
              </div>
              {file && (
                <div className="flex items-center gap-2">
                  <FileText className="h-4 w-4" />
                  <span className="text-sm">{file.name}</span>
                  <Button
                    size="sm"
                    variant="ghost"
                    onClick={removeFile}
                  >
                    <X className="h-4 w-4" />
                  </Button>
                </div>
              )}
            </div>
            {uploading && (
              <p className="text-sm text-muted-foreground">Subiendo archivo...</p>
            )}
          </div>
        )}

        {/* Yes/No answer section */}
        {question.answer_type === 'yes_no' && (
          <RadioGroup
            value={yesNoAnswer}
            onValueChange={handleYesNoChange}
            className="space-y-2"
          >
            <RadioGroupItem value="yes" id={`q${questionNumber}_yes`}>
              Sí
            </RadioGroupItem>
            <RadioGroupItem value="no" id={`q${questionNumber}_no`}>
              No
            </RadioGroupItem>
          </RadioGroup>
        )}

        {/* Text answer section */}
        {question.answer_type === 'text' && (
          <div className="space-y-2">
            <Label>{question.text_description}</Label>
            <Textarea
              value={textAnswer}
              onChange={(e) => handleTextChange(e.target.value)}
              placeholder="Ingrese su respuesta aquí..."
              rows={3}
            />
          </div>
        )}
      </CardContent>
    </Card>
  );
};

export default QuestionCard;