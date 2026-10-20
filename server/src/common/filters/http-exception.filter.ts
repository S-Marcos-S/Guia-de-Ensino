import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Response } from 'express';
import { QueryFailedError } from 'typeorm';

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message: string | object = 'Ocorreu um erro interno no servidor.';
    let errorType = 'InternalServerError';

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const res = exception.getResponse();
      message =
        typeof res === 'object' && res !== null
          ? ((res as Record<string, unknown>).message ?? res)
          : res;
      errorType = exception.name;
    } else if (exception instanceof QueryFailedError) {
      status = HttpStatus.BAD_REQUEST;
      errorType = 'DatabaseQueryError';

      // Tratamento específico de códigos de erro PostgreSQL
      const driverError = exception.driverError as { code?: string; detail?: string } | undefined;
      const pgCode = driverError?.code;

      if (pgCode === '23505') {
        // Unique violation
        message = 'Conflito de unicidade: o registro ou identificador informado já existe.';
        status = HttpStatus.CONFLICT;
      } else if (pgCode === '23503') {
        // Foreign key violation
        message =
          'Violação de integridade referencial: a entidade referenciada não existe ou pertence a outro usuário.';
        status = HttpStatus.UNPROCESSABLE_ENTITY;
      } else {
        message = 'A operação no banco de dados falhou devido a uma inconsistência de dados.';
      }

      this.logger.error(`[Database Error] Code: ${pgCode} - ${exception.message}`);
    } else if (exception instanceof Error) {
      this.logger.error(`[Unhandled Error] ${exception.message}`, exception.stack);
    }

    response.status(status).json({
      statusCode: status,
      error: errorType,
      message,
      timestamp: new Date().toISOString(),
    });
  }
}
