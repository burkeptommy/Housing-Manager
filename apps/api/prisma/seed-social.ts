import { PrismaClient, PostVisibility, CostDisplay, FriendshipStatus, VendorCategory, PropertyType } from '@prisma/client';
import * as h3 from 'h3-js';

const prisma = new PrismaClient();

// Demo coordinates around San Francisco Bay Area
const SF_LOCATIONS = [
  { name: 'Pacific Heights', lat: 37.7925, lng: -122.4382, address: '2850 Pacific Ave' },
  { name: 'Marina District', lat: 37.8015, lng: -122.4368, address: '3200 Scott St' },
  { name: 'Nob Hill', lat: 37.7930, lng: -122.4161, address: '1000 Mason St' },
  { name: 'Russian Hill', lat: 37.8011, lng: -122.4194, address: '1055 Green St' },
  { name: 'Castro', lat: 37.7609, lng: -122.4350, address: '480 Castro St' },
  { name: 'Mission', lat: 37.7599, lng: -122.4148, address: '3180 24th St' },
  { name: 'SOMA', lat: 37.7785, lng: -122.3950, address: '888 Brannan St' },
  { name: 'Hayes Valley', lat: 37.7759, lng: -122.4245, address: '555 Hayes St' },
  { name: 'Potrero Hill', lat: 37.7562, lng: -122.4007, address: '1200 18th St' },
  { name: 'Bernal Heights', lat: 37.7388, lng: -122.4150, address: '450 Cortland Ave' },
  { name: 'Noe Valley', lat: 37.7502, lng: -122.4337, address: '3861 24th St' },
  { name: 'Cole Valley', lat: 37.7654, lng: -122.4505, address: '930 Cole St' },
];

// Demo project types with realistic data - mapped to VendorCategory enums
const PROJECT_TYPES = [
  {
    category: 'Kitchen Renovation',
    vendorCategory: VendorCategory.HANDYMAN,
    titles: [
      'Complete Kitchen Remodel',
      'Kitchen Cabinet Refinishing',
      'New Countertops Installation',
      'Kitchen Backsplash Project',
      'Kitchen Island Addition',
    ],
    costRange: [8000, 75000],
    durationRange: [14, 60],
  },
  {
    category: 'Bathroom Renovation',
    vendorCategory: VendorCategory.HANDYMAN,
    titles: [
      'Master Bath Renovation',
      'Guest Bathroom Update',
      'Bathroom Tile Replacement',
      'Walk-in Shower Installation',
      'Double Vanity Upgrade',
    ],
    costRange: [5000, 35000],
    durationRange: [7, 30],
  },
  {
    category: 'Roofing',
    vendorCategory: VendorCategory.GUTTER_CLEANING,
    titles: [
      'Complete Roof Replacement',
      'Roof Repair and Patching',
      'Gutter Installation',
      'Solar Panel Roof Integration',
      'Skylight Installation',
    ],
    costRange: [8000, 25000],
    durationRange: [3, 14],
  },
  {
    category: 'Plumbing',
    vendorCategory: VendorCategory.WATER_SEWER,
    titles: [
      'Water Heater Replacement',
      'Whole House Repiping',
      'Sewer Line Repair',
      'Bathroom Plumbing Upgrade',
      'Kitchen Sink and Disposal',
    ],
    costRange: [500, 15000],
    durationRange: [1, 7],
  },
  {
    category: 'HVAC',
    vendorCategory: VendorCategory.HVAC_SERVICE,
    titles: [
      'New HVAC System Installation',
      'AC Unit Replacement',
      'Furnace Upgrade',
      'Ductwork Cleaning & Repair',
      'Smart Thermostat Setup',
    ],
    costRange: [3000, 18000],
    durationRange: [1, 5],
  },
  {
    category: 'Landscaping',
    vendorCategory: VendorCategory.LANDSCAPING,
    titles: [
      'Backyard Patio Installation',
      'Front Yard Makeover',
      'Drought-Resistant Garden',
      'Outdoor Kitchen Build',
      'Fence and Gate Installation',
    ],
    costRange: [2000, 40000],
    durationRange: [3, 21],
  },
  {
    category: 'Painting',
    vendorCategory: VendorCategory.HANDYMAN,
    titles: [
      'Whole House Interior Paint',
      'Exterior House Painting',
      'Accent Wall Feature',
      'Cabinet Painting Project',
      'Deck Staining and Sealing',
    ],
    costRange: [1500, 12000],
    durationRange: [2, 10],
  },
  {
    category: 'Flooring',
    vendorCategory: VendorCategory.HANDYMAN,
    titles: [
      'Hardwood Floor Installation',
      'Tile Flooring Throughout',
      'Carpet to Hardwood Conversion',
      'Luxury Vinyl Plank Install',
      'Refinished Original Hardwood',
    ],
    costRange: [3000, 20000],
    durationRange: [3, 14],
  },
  {
    category: 'Electrical',
    vendorCategory: VendorCategory.ELECTRIC,
    titles: [
      'Electrical Panel Upgrade',
      'Whole House Rewiring',
      'EV Charger Installation',
      'Recessed Lighting Project',
      'Smart Home Wiring',
    ],
    costRange: [1000, 15000],
    durationRange: [1, 7],
  },
  {
    category: 'Windows & Doors',
    vendorCategory: VendorCategory.HANDYMAN,
    titles: [
      'Window Replacement Project',
      'Front Door Upgrade',
      'Sliding Glass Door Install',
      'Storm Windows Addition',
      'French Door Installation',
    ],
    costRange: [2000, 25000],
    durationRange: [1, 7],
  },
];

// Demo user profiles
const DEMO_USERS = [
  { firstName: 'Sarah', lastName: 'Chen', bio: 'DIY enthusiast and home renovation blogger. Love sharing my projects!', isPublic: true, isInfluencer: true },
  { firstName: 'Mike', lastName: 'Johnson', bio: 'First-time homeowner learning as I go. Happy to share what works!', isPublic: true, isInfluencer: false },
  { firstName: 'Emily', lastName: 'Rodriguez', bio: 'Interior designer by day, home improver by weekend.', isPublic: true, isInfluencer: true },
  { firstName: 'David', lastName: 'Kim', bio: 'Tech worker who discovered a love for home projects.', isPublic: true, isInfluencer: false },
  { firstName: 'Jessica', lastName: 'Thompson', bio: 'Sharing our Victorian restoration journey.', isPublic: true, isInfluencer: true },
  { firstName: 'Chris', lastName: 'Martinez', bio: 'Contractor turned homeowner. Ask me anything!', isPublic: true, isInfluencer: false },
  { firstName: 'Amanda', lastName: 'Lee', bio: 'Sustainable home improvements advocate.', isPublic: true, isInfluencer: false },
  { firstName: 'Ryan', lastName: 'Wilson', bio: 'Weekend warrior tackling one project at a time.', isPublic: false, isInfluencer: false },
  { firstName: 'Nicole', lastName: 'Brown', bio: 'Budget-friendly renovations that look expensive.', isPublic: true, isInfluencer: true },
  { firstName: 'James', lastName: 'Taylor', bio: 'Old house, new tricks. Restoring a 1920s bungalow.', isPublic: true, isInfluencer: false },
  { firstName: 'Lisa', lastName: 'Anderson', bio: 'Making our mid-century modern shine again.', isPublic: true, isInfluencer: false },
  { firstName: 'Kevin', lastName: 'Garcia', bio: 'Smart home enthusiast and DIYer.', isPublic: true, isInfluencer: false },
];

// Demo vendor companies with proper VendorCategory enum values
const DEMO_VENDORS = [
  { name: 'Bay Area Plumbing Pros', category: VendorCategory.WATER_SEWER, rating: 4.8 },
  { name: 'Golden Gate Roofing', category: VendorCategory.GUTTER_CLEANING, rating: 4.9 },
  { name: 'SF Kitchen & Bath', category: VendorCategory.HANDYMAN, rating: 4.7 },
  { name: 'Pacific Electric Services', category: VendorCategory.ELECTRIC, rating: 4.6 },
  { name: 'Sunset Painting Co.', category: VendorCategory.HANDYMAN, rating: 4.8 },
  { name: 'NorCal HVAC Solutions', category: VendorCategory.HVAC_SERVICE, rating: 4.5 },
  { name: 'Bay Flooring Experts', category: VendorCategory.HANDYMAN, rating: 4.7 },
  { name: 'Green Thumb Landscaping', category: VendorCategory.LANDSCAPING, rating: 4.9 },
  { name: 'Vista Windows & Doors', category: VendorCategory.HANDYMAN, rating: 4.6 },
  { name: 'Elite Bath Remodeling', category: VendorCategory.HANDYMAN, rating: 4.8 },
];

// Post descriptions
const DESCRIPTIONS = [
  'Super happy with how this turned out! The team was professional and finished ahead of schedule.',
  'Took a while to find the right contractor but so worth the wait. Quality work!',
  'DIY project that pushed my skills. Learned a ton and saved money!',
  'Before and after speaks for itself. Best home investment we\'ve made.',
  'Finally pulled the trigger on this project. Should have done it years ago!',
  'Our contractor recommended some changes that made it even better than planned.',
  'Budget was tight but we made it work. Prioritized the must-haves.',
  'The transformation is incredible. Friends can\'t believe it\'s the same house!',
  'Second project with this vendor. Consistently excellent work.',
  'Neighbors keep stopping by to ask who did the work. Highly recommend!',
  'Permit process was a headache but the result is worth it.',
  'Went over budget but the upgraded materials were worth every penny.',
];

function randomFromArray<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

function randomInRange(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function generatePlaceholderImageUrl(width: number, height: number, label: string): string {
  // Using placeholder URLs that indicate where real images would go
  return `https://placehold.co/${width}x${height}/e2e8f0/64748b?text=${encodeURIComponent(label)}`;
}

async function main() {
  console.log('🌱 Seeding social demo data...\n');

  // Get or create service categories for project types
  const serviceCategories = await Promise.all(
    [...new Set(PROJECT_TYPES.map(p => p.category))].map(async (name) => {
      return prisma.serviceCategory.upsert({
        where: { name },
        update: {},
        create: {
          name,
          description: `${name} services`,
          isActive: true,
        },
      });
    })
  );
  console.log(`✅ Created ${serviceCategories.length} service categories`);

  // Create demo vendors with proper IDs for upsert
  const vendors = await Promise.all(
    DEMO_VENDORS.map(async (v, index) => {
      const vendorId = `demo-vendor-${index + 1}`;
      return prisma.vendor.upsert({
        where: { id: vendorId },
        update: {
          displayName: v.name,
          category: v.category,
          rating: v.rating,
        },
        create: {
          id: vendorId,
          displayName: v.name,
          email: `contact@${v.name.toLowerCase().replace(/\s+/g, '').replace(/&/g, 'and')}.com`,
          phone: `415-555-${1000 + index}`,
          category: v.category,
          rating: v.rating,
          reviewCount: randomInRange(20, 150),
          isActive: true,
          isVerified: true,
          city: 'San Francisco',
          state: 'CA',
          serviceAreas: ['San Francisco', 'Oakland', 'Berkeley'],
        },
      });
    })
  );
  console.log(`✅ Created ${vendors.length} demo vendors`);

  // Create demo users
  const users = await Promise.all(
    DEMO_USERS.map(async (u, index) => {
      const email = `${u.firstName.toLowerCase()}.${u.lastName.toLowerCase()}@demo.haven.app`;
      return prisma.user.upsert({
        where: { email },
        update: {
          bio: u.bio,
          isPublicProfile: u.isPublic,
          influencerBadges: u.isInfluencer ? ['HomeExpert', 'Verified'] : [],
        },
        create: {
          id: `demo-user-${index + 1}`,
          email,
          firebaseUid: `demo-firebase-${index + 1}`,
          firstName: u.firstName,
          lastName: u.lastName,
          displayName: `${u.firstName} ${u.lastName}`,
          bio: u.bio,
          isPublicProfile: u.isPublic,
          influencerBadges: u.isInfluencer ? ['HomeExpert', 'Verified'] : [],
          role: 'HOMEOWNER',
        },
      });
    })
  );
  console.log(`✅ Created ${users.length} demo users`);

  // Create households for each user with H3 indices
  const households = await Promise.all(
    users.map(async (user, index) => {
      const location = SF_LOCATIONS[index % SF_LOCATIONS.length];
      const h3Index = h3.latLngToCell(location.lat, location.lng, 8);
      const householdId = `demo-household-${index + 1}`;

      // Create or update household (without address fields - those go in HomeProfile)
      const household = await prisma.household.upsert({
        where: { id: householdId },
        update: { h3Index },
        create: {
          id: householdId,
          name: `${user.firstName}'s Home`,
          ownerId: user.id,
          h3Index,
        },
      });

      // Create HomeProfile with address info
      const postalCode = `94${110 + index}`;
      await prisma.homeProfile.upsert({
        where: { householdId: household.id },
        update: {},
        create: {
          householdId: household.id,
          propertyType: randomFromArray([
            PropertyType.SINGLE_FAMILY,
            PropertyType.CONDO,
            PropertyType.TOWNHOUSE,
          ]),
          addressLine1: location.address,
          city: 'San Francisco',
          state: 'CA',
          postalCode,
          country: 'US',
          squareFeet: randomInRange(1200, 3500),
          yearBuilt: randomInRange(1920, 2020),
          bedrooms: randomInRange(2, 5),
          bathrooms: randomInRange(1, 3.5),
        },
      });

      // Create household membership
      await prisma.householdMember.upsert({
        where: {
          householdId_userId: {
            householdId: household.id,
            userId: user.id,
          },
        },
        update: {},
        create: {
          householdId: household.id,
          userId: user.id,
          role: 'OWNER',
          status: 'ACTIVE',
        },
      });

      return household;
    })
  );
  console.log(`✅ Created ${households.length} demo households with H3 indices and home profiles`);

  // Create friendships between users
  const friendshipPairs = [
    [0, 1], [0, 2], [0, 3], [1, 2], [1, 4], [2, 3], [2, 5],
    [3, 4], [4, 5], [5, 6], [6, 7], [7, 8], [8, 9], [9, 10],
    [10, 11], [0, 11], [1, 6], [2, 8], [3, 9], [4, 10],
  ];

  for (const [i, j] of friendshipPairs) {
    if (users[i] && users[j]) {
      await prisma.friendship.upsert({
        where: {
          requesterId_addresseeId: {
            requesterId: users[i].id,
            addresseeId: users[j].id,
          },
        },
        update: {},
        create: {
          requesterId: users[i].id,
          addresseeId: users[j].id,
          status: FriendshipStatus.ACCEPTED,
          acceptedAt: new Date(),
        },
      });
    }
  }
  console.log(`✅ Created ${friendshipPairs.length} friendships`);

  // Create follows (influencers get more followers)
  const influencerIndices = DEMO_USERS.map((u, i) => u.isInfluencer ? i : -1).filter(i => i >= 0);
  let followCount = 0;

  for (const influencerIdx of influencerIndices) {
    for (let i = 0; i < users.length; i++) {
      if (i !== influencerIdx && Math.random() > 0.3) {
        await prisma.follow.upsert({
          where: {
            followerId_followingId: {
              followerId: users[i].id,
              followingId: users[influencerIdx].id,
            },
          },
          update: {},
          create: {
            followerId: users[i].id,
            followingId: users[influencerIdx].id,
          },
        });
        followCount++;
      }
    }
  }
  console.log(`✅ Created ${followCount} follow relationships`);

  // Create project posts
  const posts = [];
  const visibilities = [
    PostVisibility.PUBLIC,
    PostVisibility.PUBLIC,
    PostVisibility.FRIENDS_ONLY,
    PostVisibility.NEIGHBORS_ONLY,
  ];

  const costDisplays = [
    CostDisplay.EXACT,
    CostDisplay.EXACT,
    CostDisplay.RANGE,
    CostDisplay.HIDDEN,
  ];

  for (let i = 0; i < 50; i++) {
    const userIndex = i % users.length;
    const user = users[userIndex];
    const household = households[userIndex];
    const projectType = randomFromArray(PROJECT_TYPES);
    const title = randomFromArray(projectType.titles);
    // Find vendor by matching VendorCategory enum
    const vendor = vendors.find(v => v.category === projectType.vendorCategory) || randomFromArray(vendors);
    const cost = randomInRange(projectType.costRange[0], projectType.costRange[1]);
    const duration = randomInRange(projectType.durationRange[0], projectType.durationRange[1]);
    const visibility = randomFromArray(visibilities);
    const costDisplay = randomFromArray(costDisplays);

    // Generate placeholder image URLs
    const beforeImages = [
      generatePlaceholderImageUrl(800, 600, `Before+1`),
      generatePlaceholderImageUrl(800, 600, `Before+2`),
    ];
    const afterImages = [
      generatePlaceholderImageUrl(800, 600, `After+1`),
      generatePlaceholderImageUrl(800, 600, `After+2`),
    ];

    const daysAgo = randomInRange(1, 180);
    const createdAt = new Date(Date.now() - daysAgo * 24 * 60 * 60 * 1000);

    const post = await prisma.projectPost.create({
      data: {
        authorId: user.id,
        householdId: household.id,
        vendorId: vendor.id,
        title,
        description: randomFromArray(DESCRIPTIONS),
        beforeImages,
        afterImages,
        visibility,
        costDisplay,
        actualCost: costDisplay === CostDisplay.EXACT ? cost : null,
        costRangeMin: costDisplay === CostDisplay.RANGE ? Math.floor(cost * 0.8) : null,
        costRangeMax: costDisplay === CostDisplay.RANGE ? Math.floor(cost * 1.2) : null,
        durationDays: duration,
        completedAt: createdAt,
        isVerified: Math.random() > 0.3,
        likesCount: randomInRange(0, 50),
        savesCount: randomInRange(0, 20),
        commentsCount: randomInRange(0, 15),
        createdAt,
      },
    });
    posts.push(post);
  }
  console.log(`✅ Created ${posts.length} project posts`);

  // Create some likes
  let likeCount = 0;
  for (const post of posts.slice(0, 30)) {
    const numLikes = randomInRange(1, 8);
    const likers = users.sort(() => Math.random() - 0.5).slice(0, numLikes);

    for (const liker of likers) {
      if (liker.id !== post.authorId) {
        try {
          await prisma.projectLike.create({
            data: {
              userId: liker.id,
              postId: post.id,
            },
          });
          likeCount++;
        } catch {
          // Ignore duplicate likes
        }
      }
    }
  }
  console.log(`✅ Created ${likeCount} likes`);

  // Create some saves
  let saveCount = 0;
  for (const post of posts.slice(0, 20)) {
    const numSaves = randomInRange(1, 4);
    const savers = users.sort(() => Math.random() - 0.5).slice(0, numSaves);

    for (const saver of savers) {
      if (saver.id !== post.authorId) {
        try {
          await prisma.savedPost.create({
            data: {
              userId: saver.id,
              postId: post.id,
            },
          });
          saveCount++;
        } catch {
          // Ignore duplicates
        }
      }
    }
  }
  console.log(`✅ Created ${saveCount} saved posts`);

  // Create some comments
  const commentTexts = [
    'Looks amazing! Great work!',
    'How long did this take?',
    'Love the color choice!',
    'We\'re thinking of doing something similar. Any tips?',
    'What was the most challenging part?',
    'This is exactly what I needed to see. Thanks for sharing!',
    'Did you do any of this yourself or all contractor?',
    'The before and after is incredible!',
    'Adding this vendor to my list!',
    'Budget goals! This is inspiring.',
    'How did you find this contractor?',
    'The details are perfect.',
    'This gives me hope for my own project!',
    'Saving this for reference.',
    'What materials did you use?',
  ];

  let commentCount = 0;
  for (const post of posts.slice(0, 25)) {
    const numComments = randomInRange(1, 5);
    const commenters = users.sort(() => Math.random() - 0.5).slice(0, numComments);

    for (const commenter of commenters) {
      await prisma.postComment.create({
        data: {
          postId: post.id,
          authorId: commenter.id,
          content: randomFromArray(commentTexts),
          createdAt: new Date(post.createdAt.getTime() + randomInRange(1, 48) * 60 * 60 * 1000),
        },
      });
      commentCount++;
    }
  }
  console.log(`✅ Created ${commentCount} comments`);

  // Update post counts to match actual data
  for (const post of posts) {
    const [likesCount, savesCount, commentsCount] = await Promise.all([
      prisma.projectLike.count({ where: { postId: post.id } }),
      prisma.savedPost.count({ where: { postId: post.id } }),
      prisma.postComment.count({ where: { postId: post.id } }),
    ]);

    await prisma.projectPost.update({
      where: { id: post.id },
      data: { likesCount, savesCount, commentsCount },
    });
  }
  console.log(`✅ Updated engagement counts`);

  console.log('\n🎉 Social demo data seeding complete!\n');
  console.log('Summary:');
  console.log(`  - ${users.length} users with profiles`);
  console.log(`  - ${households.length} households with H3 indices`);
  console.log(`  - ${vendors.length} vendors`);
  console.log(`  - ${friendshipPairs.length} friendships`);
  console.log(`  - ${followCount} follows`);
  console.log(`  - ${posts.length} project posts`);
  console.log(`  - ${likeCount} likes`);
  console.log(`  - ${saveCount} saves`);
  console.log(`  - ${commentCount} comments`);
}

main()
  .catch((e) => {
    console.error('Error seeding social data:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
