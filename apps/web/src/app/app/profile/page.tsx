'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import { getApiClient } from '@/lib/api';
import type { SocialProfile, ProjectPost, ProfileStats } from '@haven/core';

// Format currency
function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

// Post Grid Card
function PostGridCard({ post }: { post: ProjectPost }) {
  const image = post.afterImages?.[0] || post.beforeImages?.[0];

  return (
    <Link
      href={`/app/community/post/${post.id}`}
      className="group relative aspect-square bg-slate-100 dark:bg-slate-700 rounded-lg overflow-hidden"
    >
      {image ? (
        <img src={image} alt={post.title} className="w-full h-full object-cover" />
      ) : (
        <div className="w-full h-full flex items-center justify-center text-4xl text-slate-400 dark:text-slate-500">
          🏠
        </div>
      )}
      {/* Hover overlay */}
      <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-4 text-white">
        <div className="flex items-center gap-1">
          <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
            <path d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
          </svg>
          <span>{post.likesCount || 0}</span>
        </div>
        <div className="flex items-center gap-1">
          <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
            <path d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z" />
          </svg>
          <span>{post.savesCount || 0}</span>
        </div>
      </div>
      {/* Verified badge */}
      {post.isVerified && (
        <div className="absolute top-2 right-2 bg-green-500 text-white text-xs px-2 py-0.5 rounded-full flex items-center gap-1">
          <svg className="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
            <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
          </svg>
        </div>
      )}
    </Link>
  );
}

// Stats Card
function StatCard({ label, value, icon }: { label: string; value: string | number; icon: string }) {
  return (
    <div className="bg-white dark:bg-slate-800 rounded-xl p-4 text-center border border-slate-200 dark:border-slate-700">
      <div className="text-2xl mb-1">{icon}</div>
      <div className="text-2xl font-bold text-slate-900 dark:text-white">{value}</div>
      <div className="text-sm text-slate-500 dark:text-slate-400">{label}</div>
    </div>
  );
}

export default function ProfilePage() {
  const { user, isAuthenticated } = useAuth();
  const [profile, setProfile] = useState<SocialProfile | null>(null);
  const [stats, setStats] = useState<ProfileStats | null>(null);
  const [posts, setPosts] = useState<ProjectPost[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<'posts' | 'saved'>('posts');
  const [isEditingBio, setIsEditingBio] = useState(false);
  const [bio, setBio] = useState('');

  useEffect(() => {
    const fetchProfileData = async () => {
      if (!isAuthenticated || !user?.id) return;

      setIsLoading(true);
      setError(null);

      try {
        const api = getApiClient();
        const [profileData, statsData, portfolioData] = await Promise.all([
          api.getSocialProfile(user.id),
          api.getProfileStats(),
          api.getUserPortfolio(user.id),
        ]);

        setProfile(profileData);
        setStats(statsData);
        setPosts(portfolioData.posts);
        setBio(profileData.bio || '');
      } catch (err: any) {
        console.error('Failed to load profile:', err);
        setError(err.message || 'Failed to load profile');
      } finally {
        setIsLoading(false);
      }
    };

    fetchProfileData();
  }, [isAuthenticated, user?.id]);

  const handleSaveBio = async () => {
    try {
      const api = getApiClient();
      const updated = await api.updateSocialProfile({ bio });
      setProfile((prev) => prev ? { ...prev, bio: updated.bio } : prev);
      setIsEditingBio(false);
    } catch (err) {
      console.error('Failed to update bio:', err);
    }
  };

  const handleTogglePublic = async () => {
    try {
      const api = getApiClient();
      await api.updateSocialProfile({ isPublicProfile: !profile?.isPublicProfile });
      setProfile((prev) => prev ? { ...prev, isPublicProfile: !prev.isPublicProfile } : prev);
    } catch (err) {
      console.error('Failed to toggle public profile:', err);
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-[calc(100vh-200px)]">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="text-center py-16">
        <p className="text-red-500">{error}</p>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto">
      {/* Profile Header */}
      <div className="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-slate-200 dark:border-slate-700 overflow-hidden mb-6">
        {/* Cover Image */}
        <div className="h-32 bg-gradient-to-r from-emerald-500 to-purple-500" />

        <div className="px-6 pb-6">
          {/* Avatar */}
          <div className="flex items-end justify-between -mt-12 mb-4">
            <div className="w-24 h-24 rounded-full border-4 border-white dark:border-slate-800 bg-slate-200 dark:bg-slate-700 flex items-center justify-center overflow-hidden">
              {user?.avatarUrl ? (
                <img src={user.avatarUrl} alt="" className="w-full h-full object-cover" />
              ) : (
                <span className="text-4xl text-slate-500 dark:text-slate-400">
                  {user?.firstName?.[0] || '?'}
                </span>
              )}
            </div>
            <div className="flex gap-2">
              <button
                onClick={handleTogglePublic}
                className={`px-4 py-2 rounded-lg text-sm font-medium ${
                  profile?.isPublicProfile
                    ? 'bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400'
                    : 'bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300'
                }`}
              >
                {profile?.isPublicProfile ? '🌍 Public Profile' : '🔒 Private Profile'}
              </button>
            </div>
          </div>

          {/* Name & Bio */}
          <div className="mb-4">
            <h1 className="text-2xl font-bold text-slate-900 dark:text-white flex items-center gap-2">
              {user ? `${user.firstName} ${user.lastName}` : 'Anonymous'}
              {profile?.influencerBadges?.length ? (
                <span className="text-sm bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-400 px-2 py-0.5 rounded">
                  ⭐ Influencer
                </span>
              ) : null}
            </h1>
            {isEditingBio ? (
              <div className="mt-2 flex gap-2">
                <input
                  type="text"
                  value={bio}
                  onChange={(e) => setBio(e.target.value)}
                  className="flex-1 input"
                  placeholder="Tell others about yourself..."
                />
                <button onClick={handleSaveBio} className="btn btn-primary">Save</button>
                <button onClick={() => setIsEditingBio(false)} className="btn btn-secondary">Cancel</button>
              </div>
            ) : (
              <p
                className="text-slate-500 dark:text-slate-400 mt-1 cursor-pointer hover:text-slate-700 dark:hover:text-slate-200"
                onClick={() => setIsEditingBio(true)}
              >
                {profile?.bio || 'Click to add a bio...'}
              </p>
            )}
          </div>

          {/* Follow Stats */}
          <div className="flex gap-6 text-sm">
            <button className="hover:underline">
              <span className="font-bold text-slate-900 dark:text-white">{stats?.followers || 0}</span>{' '}
              <span className="text-slate-500 dark:text-slate-400">followers</span>
            </button>
            <button className="hover:underline">
              <span className="font-bold text-slate-900 dark:text-white">{stats?.following || 0}</span>{' '}
              <span className="text-slate-500 dark:text-slate-400">following</span>
            </button>
          </div>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
        <StatCard label="Projects" value={stats?.totalPosts || 0} icon="📸" />
        <StatCard label="Followers" value={stats?.followers || 0} icon="👥" />
        <StatCard label="Following" value={stats?.following || 0} icon="➡️" />
        <StatCard
          label="Value Added"
          value={stats?.totalValueAdded ? formatCurrency(stats.totalValueAdded) : '$0'}
          icon="💰"
        />
      </div>

      {/* Tab Navigation */}
      <div className="flex border-b border-slate-200 dark:border-slate-700 mb-6">
        <button
          onClick={() => setActiveTab('posts')}
          className={`px-6 py-3 text-sm font-medium border-b-2 transition-colors ${
            activeTab === 'posts'
              ? 'border-emerald-600 text-emerald-600'
              : 'border-transparent text-slate-500 hover:text-slate-700 dark:text-slate-400'
          }`}
        >
          My Projects
        </button>
        <button
          onClick={() => setActiveTab('saved')}
          className={`px-6 py-3 text-sm font-medium border-b-2 transition-colors ${
            activeTab === 'saved'
              ? 'border-emerald-600 text-emerald-600'
              : 'border-transparent text-slate-500 hover:text-slate-700 dark:text-slate-400'
          }`}
        >
          Saved
        </button>
      </div>

      {/* Content */}
      {activeTab === 'posts' && (
        posts.length === 0 ? (
          <div className="text-center py-16">
            <div className="text-6xl mb-4">📸</div>
            <h3 className="text-lg font-medium text-slate-900 dark:text-white">No projects yet</h3>
            <p className="text-slate-500 dark:text-slate-400 mt-1">
              Share your first home project to build your portfolio
            </p>
            <Link href="/app/work-orders" className="btn btn-primary mt-4">
              Create a Project Post
            </Link>
          </div>
        ) : (
          <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
            {posts.map((post) => (
              <PostGridCard key={post.id} post={post} />
            ))}
          </div>
        )
      )}

      {activeTab === 'saved' && (
        <div className="text-center py-16">
          <div className="text-6xl mb-4">🔖</div>
          <h3 className="text-lg font-medium text-slate-900 dark:text-white">Saved posts</h3>
          <p className="text-slate-500 dark:text-slate-400 mt-1">
            Posts you save will appear here for inspiration
          </p>
        </div>
      )}
    </div>
  );
}
