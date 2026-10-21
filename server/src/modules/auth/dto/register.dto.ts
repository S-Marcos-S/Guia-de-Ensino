import { IsEmail, IsString, MinLength } from 'class-validator';

export class RegisterDto {
  @IsEmail({}, { message: 'Formato de e-mail inválido.' })
  email!: string;

  @IsString({ message: 'A senha deve ser uma cadeia de caracteres válida.' })
  @MinLength(8, { message: 'A senha deve conter no mínimo 8 caracteres.' })
  password!: string;
}
