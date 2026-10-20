import { HttpException, HttpStatus } from '@nestjs/common';

export class SnapshotExpiredException extends HttpException {
  constructor(
    message = 'O token do snapshot expirou (TTL de 15 minutos). É necessário solicitar um novo snapshot.',
  ) {
    super(
      {
        statusCode: HttpStatus.GONE,
        error: 'Gone',
        message,
        code: 'SNAPSHOT_EXPIRED',
      },
      HttpStatus.GONE,
    );
  }
}
