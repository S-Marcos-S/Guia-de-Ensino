import { ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AuthenticatedUser } from '../decorators/current-user.decorator';

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  canActivate(context: ExecutionContext) {
    return super.canActivate(context);
  }

  handleRequest<TUser = AuthenticatedUser>(err: Error | null, user: TUser | null): TUser {
    if (err || !user) {
      throw (
        err || new UnauthorizedException('Autenticação necessária ou token JWT expirado/inválido.')
      );
    }
    return user;
  }
}
