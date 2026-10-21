import { HttpException, HttpStatus } from '@nestjs/common';

export class IdempotencyConflictException extends HttpException {
  constructor(clientOpId: string) {
    super(
      `Conflito de idempotência: a operação '${clientOpId}' já foi registrada anteriormente com payload diferente.`,
      HttpStatus.CONFLICT,
    );
  }
}
