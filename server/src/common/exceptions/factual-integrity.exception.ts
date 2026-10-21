import { HttpException, HttpStatus } from '@nestjs/common';

export class FactualIntegrityException extends HttpException {
  constructor(message: string) {
    super(
      {
        statusCode: HttpStatus.CONFLICT,
        error: 'FactualIntegrityConflict',
        message: `Violação de integridade factual: ${message}`,
      },
      HttpStatus.CONFLICT,
    );
  }
}
