import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import * as express from 'express';

import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    // Enable raw body for Stripe webhook signature verification
    rawBody: true,
  });

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

  // Swagger/OpenAPI configuration
  const config = new DocumentBuilder()
    .setTitle('Haven Home Manager API')
    .setDescription('API for managing home maintenance, service requests, and household operations')
    .setVersion('1.0')
    .addBearerAuth()
    .addTag('Auth', 'Authentication and authorization endpoints')
    .addTag('Users', 'User management endpoints')
    .addTag('Households', 'Household management endpoints')
    .addTag('Home Profiles', 'Home profile management endpoints')
    .addTag('Service Categories', 'Service category management (Admin only)')
    .addTag('Service Requests', 'Service request management endpoints')
    .addTag('Messages', 'Real-time messaging endpoints')
    .addTag('Billing', 'Subscription and billing endpoints')
    .addTag('Health', 'Health check endpoints')
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document, {
    swaggerOptions: {
      persistAuthorization: true,
    },
  });

  const port = process.env.PORT || 4000;
  await app.listen(port);

  console.log(`🏠 Haven API is running on: http://localhost:${port}/api`);
  console.log(`📖 API Documentation: http://localhost:${port}/api/docs`);
  console.log(`🔌 WebSocket: ws://localhost:${port}/messages`);
  console.log(`📋 Endpoints:`);
  console.log(`   Auth:`);
  console.log(`   - POST /api/auth/register - Register a new user`);
  console.log(`   - POST /api/auth/login    - Login with email/password`);
  console.log(`   - POST /api/auth/refresh  - Refresh access token`);
  console.log(`   - GET  /api/auth/me       - Get current user info`);
  console.log(`   Users:`);
  console.log(`   - GET  /api/users/:id     - Get user by ID (admin only)`);
  console.log(`   Households:`);
  console.log(`   - POST /api/households    - Create household`);
  console.log(`   - GET  /api/households    - List user's households`);
  console.log(`   - GET  /api/households/:id - Get household details`);
  console.log(`   - PATCH /api/households/:id - Update household`);
  console.log(`   Home Profiles:`);
  console.log(`   - PUT  /api/households/:id/profile - Upsert home profile`);
  console.log(`   - GET  /api/households/:id/profile - Get home profile`);
  console.log(`   Service Categories (Admin):`);
  console.log(`   - CRUD /api/service-categories`);
  console.log(`   Service Requests:`);
  console.log(`   - POST /api/requests      - Create request`);
  console.log(`   - GET  /api/requests?householdId=... - List by household`);
  console.log(`   - GET  /api/manager/requests - Manager's assigned requests`);
  console.log(`   - PATCH /api/requests/:id - Update request`);
  console.log(`   Messages:`);
  console.log(`   - GET  /api/channels/:type/:id/messages - Get channel messages`);
  console.log(`   - POST /api/channels/:type/:id/messages - Send message`);
  console.log(`   Billing:`);
  console.log(`   - POST /api/billing/subscribe - Create subscription`);
  console.log(`   - GET  /api/billing/subscription - Get current subscription`);
  console.log(`   - POST /api/billing/webhook - Stripe webhook`);
  console.log(`   Health:`);
  console.log(`   - GET  /api/health        - Health check`);
}

void bootstrap();
