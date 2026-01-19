# Haven Mobile - Fix Profile & Family Editing + Social Auth Name Capture

## OVERVIEW

Fix critical bugs preventing users from editing their profile and family member information. Also ensure Apple/Google sign-in properly captures first and last name.

---

## PROBLEM 1: "Failed to update profile" Error

### Current Behavior
When user tries to update their profile information, they get "Failed to update profile" error.

### Investigation Steps

1. **Check the Profile screen API call:**
```
apps/mobile/app/(tabs)/profile/index.tsx
# or
apps/mobile/app/(tabs)/more/profile.tsx
```

2. **Check the API endpoint:**
```
apps/api/src/users/users.controller.ts
apps/api/src/users/users.service.ts
```

3. **Common issues to check:**
   - Is the API endpoint expecting the right payload format?
   - Is the auth token being sent correctly?
   - Is there a validation error not being surfaced?
   - Is the Prisma update failing silently?

### Likely Fix

**Mobile side - ensure correct API call:**
```typescript
// In profile update handler
const updateProfile = async (data: {
  firstName: string;
  lastName: string;
  phone?: string;
  avatarUrl?: string;
}) => {
  try {
    const token = await getIdToken();
    const response = await fetch(`${API_BASE_URL}/users/me`, {
      method: 'PATCH',  // or PUT depending on API
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
      body: JSON.stringify(data),
    });

    if (!response.ok) {
      const error = await response.json();
      console.error('Profile update error:', error);
      throw new Error(error.message || 'Failed to update profile');
    }

    return await response.json();
  } catch (err) {
    console.error('Profile update failed:', err);
    throw err;
  }
};
```

**API side - ensure endpoint exists and works:**
```typescript
// users.controller.ts
@Patch('me')
@UseGuards(JwtAuthGuard)
async updateMe(
  @CurrentUser() user: User,
  @Body() updateDto: UpdateUserDto,
) {
  return this.usersService.update(user.id, updateDto);
}

// users.service.ts
async update(id: string, data: UpdateUserDto) {
  return this.prisma.user.update({
    where: { id },
    data: {
      firstName: data.firstName,
      lastName: data.lastName,
      phone: data.phone,
      avatarUrl: data.avatarUrl,
    },
  });
}
```

### Verification
- [ ] User can update first name
- [ ] User can update last name
- [ ] User can update phone number
- [ ] Changes persist after app restart
- [ ] Error messages are clear if validation fails

---

## PROBLEM 2: Apple/Google Sign-In Not Capturing Name

### Current Behavior
When user signs in with Apple, only the email is captured. First name and last name are empty.

### Root Cause
Apple only provides the user's name on the **first sign-in ever**. If you miss capturing it then, it's gone. Google always provides the name.

### Fix in Auth Context

**File:** `apps/mobile/src/contexts/auth-context.tsx`

When handling Apple sign-in result, capture the name:

```typescript
// In the Apple sign-in handler
const handleAppleSignIn = async () => {
  const result = await signInWithApple();
  
  if (result.success && result.user) {
    // Apple provides fullName only on first sign-in
    const displayName = result.user.displayName;
    
    if (displayName) {
      // Parse first and last name
      const nameParts = displayName.trim().split(' ');
      const firstName = nameParts[0] || '';
      const lastName = nameParts.slice(1).join(' ') || '';
      
      // Update the user record in our database
      await updateUserProfile({
        firstName,
        lastName,
      });
    }
  }
};
```

**File:** `apps/mobile/src/lib/apple-auth.ts`

Ensure we're capturing the full name from Apple's credential:

```typescript
export async function signInWithApple(): Promise<AppleAuthResult> {
  try {
    const credential = await AppleAuthentication.signInAsync({
      requestedScopes: [
        AppleAuthentication.AppleAuthenticationScope.FULL_NAME,
        AppleAuthentication.AppleAuthenticationScope.EMAIL,
      ],
      nonce: hashedNonce,
    });

    // IMPORTANT: Capture the name from Apple's credential
    let displayName = null;
    if (credential.fullName) {
      const { givenName, familyName } = credential.fullName;
      if (givenName || familyName) {
        displayName = [givenName, familyName].filter(Boolean).join(' ');
      }
    }

    // ... rest of Firebase sign-in ...

    return {
      success: true,
      user: {
        uid: user.uid,
        email: user.email,
        displayName,  // Pass this along!
        firstName: credential.fullName?.givenName || null,
        lastName: credential.fullName?.familyName || null,
      },
    };
  } catch (error) {
    // ...
  }
}
```

### Backend: Store Name on User Creation

**File:** `apps/api/src/auth/auth.service.ts` (or wherever user creation happens)

When creating a user from Firebase auth, accept and store the name:

```typescript
async createOrUpdateUser(firebaseUser: DecodedIdToken, additionalData?: {
  firstName?: string;
  lastName?: string;
}) {
  const existingUser = await this.prisma.user.findUnique({
    where: { firebaseUid: firebaseUser.uid },
  });

  if (existingUser) {
    // Update if we have new name data and existing is empty
    if (additionalData?.firstName && !existingUser.firstName) {
      await this.prisma.user.update({
        where: { id: existingUser.id },
        data: {
          firstName: additionalData.firstName,
          lastName: additionalData.lastName,
        },
      });
    }
    return existingUser;
  }

  // Create new user with name
  return this.prisma.user.create({
    data: {
      firebaseUid: firebaseUser.uid,
      email: firebaseUser.email,
      firstName: additionalData?.firstName || firebaseUser.name?.split(' ')[0] || null,
      lastName: additionalData?.lastName || firebaseUser.name?.split(' ').slice(1).join(' ') || null,
      // ...
    },
  });
}
```

### If Name Is Missing: Prompt User

If a user's name is empty after sign-in, prompt them to enter it:

```typescript
// In the auth flow or on first app load
useEffect(() => {
  if (user && (!user.firstName || !user.lastName)) {
    // Show a modal or navigate to a "Complete Your Profile" screen
    setShowNamePrompt(true);
  }
}, [user]);
```

Create a simple name prompt modal:

```typescript
function NamePromptModal({ visible, onComplete }) {
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');

  const handleSave = async () => {
    await updateProfile({ firstName, lastName });
    onComplete();
  };

  return (
    <Modal visible={visible} animationType="slide">
      <SafeAreaView style={styles.container}>
        <Text style={styles.title}>What's your name?</Text>
        <Text style={styles.subtitle}>
          We couldn't get your name from Apple. Please enter it below.
        </Text>
        <TextInput
          placeholder="First Name"
          value={firstName}
          onChangeText={setFirstName}
        />
        <TextInput
          placeholder="Last Name"
          value={lastName}
          onChangeText={setLastName}
        />
        <Button title="Continue" onPress={handleSave} />
      </SafeAreaView>
    </Modal>
  );
}
```

---

## PROBLEM 3: Cannot Edit Family Members

### Current Behavior
Account owner cannot edit other family members' information.

### Required Functionality
- Account owner (head of household) can edit ANY family member
- Regular members can only edit their own profile
- Editable fields: firstName, lastName, phone, email, birthday, photo

### Implementation

**Mobile - Family Member Detail Screen:**
```
apps/mobile/app/(tabs)/family/[memberId].tsx
# or similar
```

Add edit functionality:

```typescript
export default function FamilyMemberDetailScreen() {
  const { id } = useLocalSearchParams();
  const { user, householdInfo } = useAuth();
  const [member, setMember] = useState<FamilyMember | null>(null);
  const [isEditing, setIsEditing] = useState(false);
  const [editData, setEditData] = useState({});

  // Check if current user can edit this member
  const canEdit = useMemo(() => {
    // Account owner can edit anyone
    if (householdInfo?.role === 'owner' || householdInfo?.role === 'admin') {
      return true;
    }
    // Users can edit themselves
    return member?.userId === user?.id;
  }, [householdInfo, member, user]);

  const handleSave = async () => {
    try {
      const token = await getIdToken();
      const response = await fetch(
        `${API_BASE_URL}/households/${householdInfo.id}/members/${id}`,
        {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`,
          },
          body: JSON.stringify(editData),
        }
      );

      if (!response.ok) throw new Error('Failed to update');
      
      // Refresh member data
      await fetchMember();
      setIsEditing(false);
      Alert.alert('Success', 'Member updated successfully');
    } catch (err) {
      Alert.alert('Error', 'Failed to update member');
    }
  };

  return (
    <ScreenContainer
      title={`${member?.firstName} ${member?.lastName}`}
      showBack
      rightAction={canEdit ? (
        <TouchableOpacity onPress={() => setIsEditing(!isEditing)}>
          <Text style={styles.editButton}>
            {isEditing ? 'Cancel' : 'Edit'}
          </Text>
        </TouchableOpacity>
      ) : null}
    >
      {isEditing ? (
        <EditMemberForm
          member={member}
          onChange={setEditData}
          onSave={handleSave}
        />
      ) : (
        <MemberDetails member={member} />
      )}
    </ScreenContainer>
  );
}
```

**API - Household Members Endpoint:**

```typescript
// households.controller.ts
@Patch(':householdId/members/:memberId')
@UseGuards(JwtAuthGuard, HouseholdMemberGuard)
async updateMember(
  @Param('householdId') householdId: string,
  @Param('memberId') memberId: string,
  @CurrentUser() user: User,
  @Body() updateDto: UpdateMemberDto,
) {
  // Check if user has permission to edit this member
  const membership = await this.householdsService.getMembership(
    householdId,
    user.id
  );
  
  // Only owners/admins can edit others
  if (membership.role !== 'owner' && membership.role !== 'admin') {
    // Check if editing self
    const targetMember = await this.householdsService.getMember(
      householdId,
      memberId
    );
    if (targetMember.userId !== user.id) {
      throw new ForbiddenException('Cannot edit other members');
    }
  }

  return this.householdsService.updateMember(householdId, memberId, updateDto);
}
```

---

## PROBLEM 4: Two Places to Edit Name (Profile & Family)

### Requirement
User should be able to edit their name from:
1. **Profile page** - Personal settings
2. **Family page** - When viewing themselves as a family member

Both should work and update the same underlying data.

### Implementation

Both screens should call the same API endpoint. The key is:

1. **Profile page** updates the `User` record directly
2. **Family page** updates the `HouseholdMember` record, which should also update the linked `User` if applicable

**Ensure data consistency:**

```typescript
// When updating a household member who is also a user
async updateMember(householdId: string, memberId: string, data: UpdateMemberDto) {
  const member = await this.prisma.householdMember.findUnique({
    where: { id: memberId },
    include: { user: true },
  });

  // Update the member record
  const updated = await this.prisma.householdMember.update({
    where: { id: memberId },
    data: {
      firstName: data.firstName,
      lastName: data.lastName,
      phone: data.phone,
      // ... other fields
    },
  });

  // If member is linked to a user, update user record too
  if (member.userId) {
    await this.prisma.user.update({
      where: { id: member.userId },
      data: {
        firstName: data.firstName,
        lastName: data.lastName,
        phone: data.phone,
      },
    });
  }

  return updated;
}
```

---

## VERIFICATION CHECKLIST

### Profile Editing
- [ ] Can update first name from Profile page
- [ ] Can update last name from Profile page
- [ ] Can update phone number
- [ ] Changes save successfully (no error)
- [ ] Changes persist after app restart

### Social Auth Name Capture
- [ ] New Apple sign-in captures first and last name
- [ ] New Google sign-in captures first and last name
- [ ] If name is missing, user is prompted to enter it
- [ ] Name shows correctly throughout app

### Family Member Editing
- [ ] Account owner can edit any family member
- [ ] Regular member can edit their own info
- [ ] Edit button appears based on permissions
- [ ] Changes save successfully
- [ ] Both Profile and Family edits update the same data

---

## TEST

```bash
# Start the API
cd /Users/tomburke/Projects/Housing-Manager/apps/api
pnpm dev

# Start mobile app
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
npx expo start --clear
```

Test scenarios:
1. Go to Profile → Edit name → Save → Should succeed
2. Go to Family → Tap yourself → Edit → Save → Should succeed
3. Sign out → Sign in with Apple → Name should be captured
4. As owner, edit another family member → Should succeed
