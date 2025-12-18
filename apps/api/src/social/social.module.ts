import { Module } from '@nestjs/common';
import { SocialController } from './social.controller';
import { H3Service } from './services/h3.service';
import { GeocodingService } from './services/geocoding.service';
import { FriendshipService } from './services/friendship.service';
import { FollowService } from './services/follow.service';
import { ProjectPostService } from './services/project-post.service';
import { FeedService } from './services/feed.service';
import { SocialVendorService } from './services/social-vendor.service';
import { PrismaModule } from '../prisma';

@Module({
  imports: [PrismaModule],
  controllers: [SocialController],
  providers: [
    H3Service,
    GeocodingService,
    FriendshipService,
    FollowService,
    ProjectPostService,
    FeedService,
    SocialVendorService,
  ],
  exports: [
    H3Service,
    GeocodingService,
    FriendshipService,
    FollowService,
    ProjectPostService,
    FeedService,
    SocialVendorService,
  ],
})
export class SocialModule {}
