import { Body, Controller, HttpCode, HttpStatus, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser, AuthenticatedUser } from '../../common/decorators/current-user.decorator';
import { SyncService } from './sync.service';
import { PushRequestDto } from './dto/push-request.dto';
import { PushResponseDto } from './dto/push-response.dto';

@Controller(['api/sync', 'sync'])
@UseGuards(JwtAuthGuard)
export class SyncController {
  constructor(private readonly syncService: SyncService) {}

  @Post('push')
  @HttpCode(HttpStatus.OK)
  async push(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: PushRequestDto,
  ): Promise<PushResponseDto> {
    return this.syncService.processPush(user.userId, dto);
  }
}
