import { HttpException, HttpStatus } from '@nestjs/common';

export class InvalidCursorException extends HttpException {
  constructor(message: string, details?: Record<string, unknown>) {
    super(
      {
        statusCode: HttpStatus.BAD_REQUEST,
        error: 'Bad Request',
        message,
        code: 'INVALID_CURSOR',
        ...details,
      },
      HttpStatus.BAD_REQUEST,
    );
  }
}
