import { HttpException, HttpStatus } from '@nestjs/common';

export class SyncEpochMismatchException extends HttpException {
  constructor(clientEpoch: string, serverEpoch: string) {
    super(
      {
        statusCode: HttpStatus.GONE,
        error: 'Gone',
        message: `Época de sincronização divergente (cliente: '${clientEpoch}', servidor: '${serverEpoch}'). Full Resync obrigatório.`,
        code: 'RESYNC_REQUIRED',
        serverEpoch,
      },
      HttpStatus.GONE,
    );
  }
}
