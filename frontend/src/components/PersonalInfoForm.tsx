import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { PersonalInfo } from '@/types/survey';

interface PersonalInfoFormProps {
  personalInfo: PersonalInfo;
  onPersonalInfoChange: (info: PersonalInfo) => void;
}

export const PersonalInfoForm: React.FC<PersonalInfoFormProps> = ({
  personalInfo,
  onPersonalInfoChange
}) => {
  const handleChange = (field: keyof PersonalInfo, value: string) => {
    onPersonalInfoChange({
      ...personalInfo,
      [field]: value
    });
  };

  return (
    <Card className="w-full">
      <CardHeader>
        <CardTitle className="text-xl text-center">
          Información Personal
        </CardTitle>
      </CardHeader>
      
      <CardContent className="space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="space-y-2">
            <Label htmlFor="nombre_completo">Nombre Completo *</Label>
            <Input
              id="nombre_completo"
              placeholder="Ingrese su nombre completo"
              value={personalInfo.nombre_completo}
              onChange={(e) => handleChange('nombre_completo', e.target.value)}
              required
            />
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="cargo">Cargo *</Label>
            <Input
              id="cargo"
              placeholder="Ingrese su cargo"
              value={personalInfo.cargo}
              onChange={(e) => handleChange('cargo', e.target.value)}
              required
            />
          </div>
        </div>

        <div className="space-y-2">
          <Label htmlFor="entidad">Entidad Perteneciente *</Label>
          <Input
            id="entidad"
            placeholder="Ingrese la entidad a la que pertenece"
            value={personalInfo.entidad}
            onChange={(e) => handleChange('entidad', e.target.value)}
            required
          />
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="space-y-2">
            <Label htmlFor="celular">Número de Celular *</Label>
            <Input
              id="celular"
              type="tel"
              placeholder="Ej: +591 70123456"
              value={personalInfo.celular}
              onChange={(e) => handleChange('celular', e.target.value)}
              required
            />
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="email">Correo Electrónico *</Label>
            <Input
              id="email"
              type="email"
              placeholder="ejemplo@correo.com"
              value={personalInfo.email}
              onChange={(e) => handleChange('email', e.target.value)}
              required
            />
          </div>
        </div>
      </CardContent>
    </Card>
  );
};