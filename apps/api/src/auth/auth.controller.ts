import {
  Controller,
  Post,
  Get,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
  Req,
} from '@nestjs/common';
import { Request } from 'express';

import { AuthService } from './auth.service';
import {
  RegisterDto,
  RegisterSimpleDto,
  LoginDto,
  RefreshTokenDto,
  AuthResponseDto,
  TokenResponseDto,
  MeResponseDto,
} from './dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { CurrentUser } from './decorators/current-user.decorator';
import { JwtPayload } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  async register(
    @Body() dto: RegisterDto,
    @Req() req: Request,
  ): Promise<AuthResponseDto> {
    const userAgent = req.headers['user-agent'];
    const ipAddress = req.ip || req.socket.remoteAddress;

    return this.authService.register(dto, userAgent, ipAddress);
  }

  /**
   * Simplified registration for Alfred-first mobile flow
   * Creates user, household with address, and triggers auto-enrichment
   */
  @Post('register-simple')
  @HttpCode(HttpStatus.CREATED)
  async registerSimple(
    @Body() dto: RegisterSimpleDto,
    @Req() req: Request,
  ) {
    const userAgent = req.headers['user-agent'];
    const ipAddress = req.ip || req.socket.remoteAddress;

    return this.authService.registerSimple(dto, userAgent, ipAddress);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(
    @Body() dto: LoginDto,
    @Req() req: Request,
  ): Promise<AuthResponseDto> {
    const userAgent = req.headers['user-agent'];
    const ipAddress = req.ip || req.socket.remoteAddress;

    return this.authService.login(dto, userAgent, ipAddress);
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  async refresh(
    @Body() dto: RefreshTokenDto,
    @Req() req: Request,
  ): Promise<TokenResponseDto> {
    const userAgent = req.headers['user-agent'];
    const ipAddress = req.ip || req.socket.remoteAddress;

    return this.authService.refresh(dto.refreshToken, userAgent, ipAddress);
  }

  @Post('logout')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.NO_CONTENT)
  async logout(
    @CurrentUser() user: JwtPayload,
    @Body() body: { refreshToken?: string },
  ): Promise<void> {
    await this.authService.logout(user.sub, body.refreshToken);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  async getMe(@CurrentUser() user: JwtPayload): Promise<MeResponseDto> {
    return this.authService.getMe(user.sub);
  }
}
