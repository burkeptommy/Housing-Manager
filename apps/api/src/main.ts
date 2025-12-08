import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';

import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Enable CORS
  app.enableCors({
    origin: process.env.CORS_ORIGIN || 'http://localhost:3000',
    credentials: true,
  });

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // API prefix
  app.setGlobalPrefix('api');

  const port = process.env.PORT || 4000;
  await app.listen(port);

  console.log(`🏠 Haven API is running on: http://localhost:${port}/api`);
  console.log(`📖 Endpoints:`);
  console.log(`   - POST /api/auth/register - Register a new user`);
  console.log(`   - POST /api/auth/login    - Login with email/password`);
  console.log(`   - POST /api/auth/refresh  - Refresh access token`);
  console.log(`   - GET  /api/auth/me       - Get current user info`);
  console.log(`   - GET  /api/users/:id     - Get user by ID (admin only)`);
  console.log(`   - GET  /api/health        - Health check`);
}

void bootstrap();
