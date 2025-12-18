'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@/contexts/auth-context';
import { getApiClient } from '@/lib/api';
import type { FeedItem, FeedSource, FeedResponse } from '@haven/core';

type TabType = 'all' | 'neighbors' | 'friends' | 'following';

// Format relative time
function formatRelativeTime(dateString: string): string {
  const date = new Date(dateString);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMins < 1) return 'Just now';
  if (diffMins < 60) return `${diffMins}m ago`;
  if (diffHours < 24) return `${diffHours}h ago`;
  if (diffDays < 7) return `${diffDays}d ago`;
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

// Format cost display
function formatCost(post: FeedItem['post']): string | null {
  if (post.costDisplay === 'HIDDEN') return null;
  if (post.costDisplay === 'EXACT' && post.actualCost) {
    return `$${post.actualCost.toLocaleString()}`;
  }
  if (post.costDisplay === 'RANGE' && post.costRangeMin != null && post.costRangeMax != null) {
    return `$${post.costRangeMin.toLocaleString()} - $${post.costRangeMax.toLocaleString()}`;
  }
  return null;
}

// Source badge component
function SourceBadge({ source }: { source: FeedSource }) {
  const badges = {
    neighbor: {
      bg: 'bg-green-100 dark:bg-green-900/30',
      text: 'text-green-700 dark:text-green-400',
      icon: '📍',
      label: 'Neighbor',
    },
    friend: {
      bg: 'bg-emerald-100 dark:bg-emerald-900/30',
      text: 'text-emerald-700 dark:text-emerald-400',
      icon: '👤',
      label: 'Friend',
    },
    following: {
      bg: 'bg-purple-100 dark:bg-purple-900/30',
      text: 'text-purple-700 dark:text-purple-400',
      icon: '⭐',
      label: 'Following',
    },
  };

  const badge = badges[source];

  return (
    <span className={`text-xs px-2 py-0.5 rounded-full ${badge.bg} ${badge.text} flex items-center gap-1`}>
      <span>{badge.icon}</span>
      {badge.label}
    </span>
  );
}

// Feed Card Component
function FeedCard({
  item,
  onLike,
  onSave,
}: {
  item: FeedItem;
  onLike: (postId: string, isLiked: boolean) => void;
  onSave: (postId: string, isSaved: boolean) => void;
}) {
  const { post, source, author, isAnonymized } = item;
  const [imageIndex, setImageIndex] = useState(0);
  const allImages = [...(post.beforeImages || []), ...(post.afterImages || [])];
  const hasImages = allImages.length > 0;
  const costDisplay = formatCost(post);

  return (
    <div className="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-slate-200 dark:border-slate-700 overflow-hidden">
      {/* Header */}
      <div className="flex items-center gap-3 p-4">
        <div className="w-10 h-10 rounded-full bg-slate-200 dark:bg-slate-700 flex items-center justify-center overflow-hidden">
          {author.avatarUrl ? (
            <img src={author.avatarUrl} alt="" className="w-full h-full object-cover" />
          ) : (
            <span className="text-slate-500 dark:text-slate-400 text-lg">
              {isAnonymized ? '🏠' : (author.displayName?.[0] || '?')}
            </span>
          )}
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <span className="font-medium text-slate-900 dark:text-white truncate">
              {author.displayName || 'Anonymous'}
            </span>
            {author.isInfluencer && (
              <span className="text-xs bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-400 px-1.5 py-0.5 rounded">
                ⭐ Influencer
              </span>
            )}
          </div>
          <div className="flex items-center gap-2 text-sm text-slate-500 dark:text-slate-400">
            <span>{formatRelativeTime(post.createdAt)}</span>
            <span>•</span>
            <SourceBadge source={source} />
          </div>
        </div>
        {post.isVerified && (
          <span className="text-xs bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400 px-2 py-1 rounded-full flex items-center gap-1">
            <svg className="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
            </svg>
            Verified
          </span>
        )}
      </div>

      {/* Title & Description */}
      <div className="px-4 pb-3">
        <h3 className="font-semibold text-lg text-slate-900 dark:text-white">
          {post.title}
        </h3>
        {post.description && (
          <p className="text-slate-600 dark:text-slate-300 mt-1 line-clamp-2">
            {post.description}
          </p>
        )}
      </div>

      {/* Image Carousel */}
      {hasImages && (
        <div className="relative aspect-video bg-slate-100 dark:bg-slate-700">
          <img
            src={allImages[imageIndex]}
            alt={`Project image ${imageIndex + 1}`}
            className="w-full h-full object-cover"
          />
          {allImages.length > 1 && (
            <>
              <button
                onClick={() => setImageIndex((i) => (i - 1 + allImages.length) % allImages.length)}
                className="absolute left-2 top-1/2 -translate-y-1/2 w-8 h-8 bg-black/50 text-white rounded-full flex items-center justify-center hover:bg-black/70"
              >
                ‹
              </button>
              <button
                onClick={() => setImageIndex((i) => (i + 1) % allImages.length)}
                className="absolute right-2 top-1/2 -translate-y-1/2 w-8 h-8 bg-black/50 text-white rounded-full flex items-center justify-center hover:bg-black/70"
              >
                ›
              </button>
              <div className="absolute bottom-2 left-1/2 -translate-x-1/2 flex gap-1">
                {allImages.map((_, i) => (
                  <span
                    key={i}
                    className={`w-2 h-2 rounded-full ${i === imageIndex ? 'bg-white' : 'bg-white/50'}`}
                  />
                ))}
              </div>
              {/* Before/After label */}
              {post.beforeImages?.length && post.afterImages?.length && (
                <div className="absolute top-2 left-2">
                  <span className="text-xs bg-black/60 text-white px-2 py-1 rounded">
                    {imageIndex < post.beforeImages.length ? 'Before' : 'After'}
                  </span>
                </div>
              )}
            </>
          )}
        </div>
      )}

      {/* Vendor & Cost Info */}
      {(post.vendor || costDisplay || post.durationDays) && (
        <div className="px-4 py-3 border-t border-slate-100 dark:border-slate-700 flex items-center flex-wrap gap-x-4 gap-y-2 text-sm">
          {post.vendor && (
            <div className="flex items-center gap-1 text-slate-600 dark:text-slate-300">
              <span className="font-medium">{post.vendor.displayName}</span>
              {post.vendor.rating && (
                <span className="text-amber-500">★ {post.vendor.rating.toFixed(1)}</span>
              )}
            </div>
          )}
          {costDisplay && (
            <span className="text-green-600 dark:text-green-400 font-medium">
              {costDisplay}
            </span>
          )}
          {post.durationDays && (
            <span className="text-slate-500 dark:text-slate-400">
              {post.durationDays} day{post.durationDays !== 1 ? 's' : ''}
            </span>
          )}
        </div>
      )}

      {/* Actions */}
      <div className="px-4 py-3 border-t border-slate-100 dark:border-slate-700 flex items-center gap-4">
        <button
          onClick={() => onLike(post.id, !!post.isLiked)}
          className={`flex items-center gap-1.5 text-sm ${
            post.isLiked
              ? 'text-red-500'
              : 'text-slate-500 dark:text-slate-400 hover:text-red-500'
          }`}
        >
          <svg
            className="w-5 h-5"
            fill={post.isLiked ? 'currentColor' : 'none'}
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
            />
          </svg>
          <span>{post.likesCount || 0}</span>
        </button>
        <button
          onClick={() => onSave(post.id, !!post.isSaved)}
          className={`flex items-center gap-1.5 text-sm ${
            post.isSaved
              ? 'text-emerald-500'
              : 'text-slate-500 dark:text-slate-400 hover:text-emerald-500'
          }`}
        >
          <svg
            className="w-5 h-5"
            fill={post.isSaved ? 'currentColor' : 'none'}
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z"
            />
          </svg>
          <span>{post.savesCount || 0}</span>
        </button>
        <button className="flex items-center gap-1.5 text-sm text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-200">
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
            />
          </svg>
          <span>{post.commentsCount || 0}</span>
        </button>
        {post.vendor && (
          <button className="ml-auto text-sm text-emerald-600 dark:text-emerald-400 hover:underline">
            Contact Vendor
          </button>
        )}
      </div>
    </div>
  );
}

// Empty state component
function EmptyState({ tab }: { tab: TabType }) {
  const messages = {
    all: {
      icon: '🏡',
      title: 'No projects in your feed',
      subtitle: 'Follow friends or neighbors to see their home projects.',
    },
    neighbors: {
      icon: '📍',
      title: 'No neighbor projects yet',
      subtitle: 'Projects from neighbors in your area will appear here.',
    },
    friends: {
      icon: '👥',
      title: 'No friend projects yet',
      subtitle: 'Add friends to see their shared projects.',
    },
    following: {
      icon: '⭐',
      title: 'No following activity',
      subtitle: 'Follow home improvement influencers to get inspired.',
    },
  };

  const msg = messages[tab];

  return (
    <div className="flex flex-col items-center justify-center py-16 text-center">
      <div className="text-6xl mb-4">{msg.icon}</div>
      <h3 className="text-lg font-medium text-slate-900 dark:text-white">{msg.title}</h3>
      <p className="text-slate-500 dark:text-slate-400 mt-1">{msg.subtitle}</p>
    </div>
  );
}

// Main Community Page
export default function CommunityPage() {
  const { isAuthenticated } = useAuth();
  const [activeTab, setActiveTab] = useState<TabType>('all');
  const [feedData, setFeedData] = useState<FeedResponse | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Fetch feed data
  const fetchFeed = async (tab: TabType) => {
    if (!isAuthenticated) return;

    setIsLoading(true);
    setError(null);

    try {
      const api = getApiClient();
      let response: FeedResponse;

      switch (tab) {
        case 'neighbors':
          response = await api.getNeighborFeed();
          break;
        case 'friends':
          response = await api.getFriendFeed();
          break;
        case 'following':
          response = await api.getFollowingFeed();
          break;
        default:
          response = await api.getSocialFeed();
      }

      setFeedData(response);
    } catch (err: any) {
      console.error('Failed to fetch feed:', err);
      setError(err.message || 'Failed to load feed');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchFeed(activeTab);
  }, [activeTab, isAuthenticated]);

  // Handle like action
  const handleLike = async (postId: string, isLiked: boolean) => {
    try {
      const api = getApiClient();
      if (isLiked) {
        await api.unlikePost(postId);
      } else {
        await api.likePost(postId);
      }
      // Optimistic update
      setFeedData((prev) => {
        if (!prev) return prev;
        return {
          ...prev,
          items: prev.items.map((item) =>
            item.post.id === postId
              ? {
                  ...item,
                  post: {
                    ...item.post,
                    isLiked: !isLiked,
                    likesCount: item.post.likesCount + (isLiked ? -1 : 1),
                  },
                }
              : item
          ),
        };
      });
    } catch (err) {
      console.error('Failed to like/unlike post:', err);
    }
  };

  // Handle save action
  const handleSave = async (postId: string, isSaved: boolean) => {
    try {
      const api = getApiClient();
      if (isSaved) {
        await api.unsavePostBookmark(postId);
      } else {
        await api.savePostBookmark(postId);
      }
      // Optimistic update
      setFeedData((prev) => {
        if (!prev) return prev;
        return {
          ...prev,
          items: prev.items.map((item) =>
            item.post.id === postId
              ? {
                  ...item,
                  post: {
                    ...item.post,
                    isSaved: !isSaved,
                    savesCount: item.post.savesCount + (isSaved ? -1 : 1),
                  },
                }
              : item
          ),
        };
      });
    } catch (err) {
      console.error('Failed to save/unsave post:', err);
    }
  };

  const tabs: { key: TabType; label: string; icon: string }[] = [
    { key: 'all', label: 'All', icon: '🏡' },
    { key: 'neighbors', label: 'Neighbors', icon: '📍' },
    { key: 'friends', label: 'Friends', icon: '👥' },
    { key: 'following', label: 'Following', icon: '⭐' },
  ];

  return (
    <div className="max-w-2xl mx-auto">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Community</h1>
        <p className="text-slate-500 dark:text-slate-400">
          See what your neighbors and friends are working on
        </p>
      </div>

      {/* Tab Navigation */}
      <div className="flex gap-2 mb-6 overflow-x-auto pb-2">
        {tabs.map((tab) => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key)}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg font-medium text-sm whitespace-nowrap transition-colors ${
              activeTab === tab.key
                ? 'bg-emerald-600 text-white'
                : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700'
            }`}
          >
            <span>{tab.icon}</span>
            {tab.label}
          </button>
        ))}
      </div>

      {/* Feed Content */}
      {isLoading ? (
        <div className="flex items-center justify-center py-16">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600"></div>
        </div>
      ) : error ? (
        <div className="bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 p-4 rounded-lg text-center">
          {error}
          <button
            onClick={() => fetchFeed(activeTab)}
            className="block mx-auto mt-2 text-sm underline"
          >
            Try again
          </button>
        </div>
      ) : feedData?.items.length === 0 ? (
        <EmptyState tab={activeTab} />
      ) : (
        <div className="space-y-4">
          {feedData?.items.map((item) => (
            <FeedCard
              key={item.post.id}
              item={item}
              onLike={handleLike}
              onSave={handleSave}
            />
          ))}
          {feedData?.hasMore && (
            <button
              onClick={() => {
                // TODO: Load more with cursor pagination
              }}
              className="w-full py-3 text-center text-emerald-600 dark:text-emerald-400 hover:underline"
            >
              Load more
            </button>
          )}
        </div>
      )}
    </div>
  );
}
