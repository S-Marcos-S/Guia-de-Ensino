import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser, AuthenticatedUser } from '../../common/decorators/current-user.decorator';
import { SyncService } from './sync.service';
import { PushRequestDto } from './dto/push-request.dto';
import { PushResponseDto } from './dto/push-response.dto';
import { PullQueryDto } from './dto/pull-query.dto';
import { PullResponseDto } from './dto/pull-response.dto';

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

  @Get('pull')
  @HttpCode(HttpStatus.OK)
  async pull(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: PullQueryDto,
  ): Promise<PullResponseDto> {
    return this.syncService.processPull(user.userId, query);
  }
}
