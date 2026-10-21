import { IsEmail, IsString } from 'class-validator';

export class LoginDto {
  @IsEmail({}, { message: 'Formato de e-mail inválido.' })
  email!: string;

  @IsString({ message: 'A senha é obrigatória.' })
  password!: string;
}
