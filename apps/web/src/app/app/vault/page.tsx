'use client';

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/contexts/auth-context';
import { getIdToken } from '@/lib/firebase';
import {
  FileText,
  Upload,
  Search,
  File,
  Calendar,
  AlertTriangle,
  Download,
  Trash2,
  Plus,
  X,
  Loader2,
  Home,
  Shield,
  Receipt,
  BookOpen,
  FileCheck,
  FolderOpen,
} from 'lucide-react';

interface Document {
  id: string;
  fileName: string;
  originalName: string;
  mimeType: string;
  fileSize: number;
  category: string;
  title: string;
  description: string;
  tags: string[];
  expiresAt: string | null;
  createdAt: string;
  downloadUrl?: string;
  uploadedBy: { id: string; displayName: string; firstName: string };
}

interface DocumentSummary {
  total: number;
  byCategory: Record<string, number>;
  expiringSoon: number;
  expired: number;
}

const categoryConfig: Record<
  string,
  { icon: React.ElementType; label: string; color: string }
> = {
  PROPERTY: {
    icon: Home,
    label: 'Property',
    color: 'bg-blue-100 text-blue-700',
  },
  INSURANCE: {
    icon: Shield,
    label: 'Insurance',
    color: 'bg-green-100 text-green-700',
  },
  WARRANTY: {
    icon: FileCheck,
    label: 'Warranty',
    color: 'bg-purple-100 text-purple-700',
  },
  MANUAL: {
    icon: BookOpen,
    label: 'Manual',
    color: 'bg-orange-100 text-orange-700',
  },
  TAX: { icon: Receipt, label: 'Tax', color: 'bg-red-100 text-red-700' },
  CONTRACT: {
    icon: FileText,
    label: 'Contract',
    color: 'bg-indigo-100 text-indigo-700',
  },
  RECEIPT: {
    icon: Receipt,
    label: 'Receipt',
    color: 'bg-yellow-100 text-yellow-700',
  },
  PERMIT: {
    icon: FileCheck,
    label: 'Permit',
    color: 'bg-cyan-100 text-cyan-700',
  },
  OTHER: { icon: File, label: 'Other', color: 'bg-gray-100 text-gray-700' },
};

export default function VaultPage() {
  const { user } = useAuth();
  const [documents, setDocuments] = useState<Document[]>([]);
  const [summary, setSummary] = useState<DocumentSummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [selectedCategory, setSelectedCategory] = useState<string>('');
  const [searchQuery, setSearchQuery] = useState('');
  const [showUpload, setShowUpload] = useState(false);
  const [uploading, setUploading] = useState(false);

  // Upload form state
  const [uploadFile, setUploadFile] = useState<File | null>(null);
  const [uploadCategory, setUploadCategory] = useState<string>('OTHER');
  const [uploadTitle, setUploadTitle] = useState('');
  const [uploadDescription, setUploadDescription] = useState('');
  const [uploadExpires, setUploadExpires] = useState('');

  const householdId = user?.householdId;

  const loadData = useCallback(async () => {
    if (!householdId) return;
    try {
      const token = await getIdToken();
      const apiUrl =
        process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      const params = new URLSearchParams();
      if (selectedCategory) params.append('category', selectedCategory);
      if (searchQuery) params.append('search', searchQuery);

      const [docsRes, summaryRes] = await Promise.all([
        fetch(`${apiUrl}/documents/household/${householdId}?${params}`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
        fetch(`${apiUrl}/documents/household/${householdId}/summary`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
      ]);

      if (docsRes.ok) setDocuments(await docsRes.json());
      if (summaryRes.ok) setSummary(await summaryRes.json());
    } catch (error) {
      console.error('Failed to load documents:', error);
    } finally {
      setLoading(false);
    }
  }, [householdId, selectedCategory, searchQuery]);

  useEffect(() => {
    if (householdId) {
      loadData();
    }
  }, [householdId, loadData]);

  const handleUpload = async () => {
    if (!uploadFile || !householdId) return;

    try {
      setUploading(true);
      const token = await getIdToken();
      const apiUrl =
        process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      const formData = new FormData();
      formData.append('file', uploadFile);
      formData.append('category', uploadCategory);
      if (uploadTitle) formData.append('title', uploadTitle);
      if (uploadDescription) formData.append('description', uploadDescription);
      if (uploadExpires) formData.append('expiresAt', uploadExpires);

      const response = await fetch(
        `${apiUrl}/documents/household/${householdId}/upload`,
        {
          method: 'POST',
          headers: { Authorization: `Bearer ${token}` },
          body: formData,
        },
      );

      if (response.ok) {
        setShowUpload(false);
        setUploadFile(null);
        setUploadTitle('');
        setUploadDescription('');
        setUploadExpires('');
        loadData();
      }
    } catch (error) {
      console.error('Upload failed:', error);
    } finally {
      setUploading(false);
    }
  };

  const handleDelete = async (documentId: string) => {
    if (!confirm('Are you sure you want to delete this document?')) return;

    try {
      const token = await getIdToken();
      const apiUrl =
        process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      await fetch(
        `${apiUrl}/documents/${documentId}?householdId=${householdId}`,
        {
          method: 'DELETE',
          headers: { Authorization: `Bearer ${token}` },
        },
      );

      loadData();
    } catch (error) {
      console.error('Delete failed:', error);
    }
  };

  const handleDownload = async (doc: Document) => {
    try {
      const token = await getIdToken();
      const apiUrl =
        process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      const response = await fetch(
        `${apiUrl}/documents/${doc.id}?householdId=${householdId}`,
        {
          headers: { Authorization: `Bearer ${token}` },
        },
      );

      if (response.ok) {
        const data = await response.json();
        window.open(data.downloadUrl, '_blank');
      }
    } catch (error) {
      console.error('Download failed:', error);
    }
  };

  const formatFileSize = (bytes: number) => {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    });
  };

  const isExpiringSoon = (expiresAt: string | null) => {
    if (!expiresAt) return false;
    const expires = new Date(expiresAt);
    const thirtyDays = new Date();
    thirtyDays.setDate(thirtyDays.getDate() + 30);
    return expires <= thirtyDays && expires > new Date();
  };

  const isExpired = (expiresAt: string | null) => {
    if (!expiresAt) return false;
    return new Date(expiresAt) < new Date();
  };

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    const file = e.dataTransfer.files[0];
    if (file) {
      setUploadFile(file);
      setUploadTitle(file.name.replace(/\.[^/.]+$/, ''));
      setShowUpload(true);
    }
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-8 h-8 animate-spin text-indigo-600" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Document Vault</h1>
          <p className="text-gray-500">Securely store your home documents</p>
        </div>
        <button
          onClick={() => setShowUpload(true)}
          className="flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700"
        >
          <Plus className="w-4 h-4" />
          Upload
        </button>
      </div>

      {/* Summary Cards */}
      {summary && (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-white rounded-xl border border-gray-200 p-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-indigo-100 rounded-lg flex items-center justify-center">
                <FileText className="w-5 h-5 text-indigo-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">
                  {summary.total}
                </p>
                <p className="text-sm text-gray-500">Total Documents</p>
              </div>
            </div>
          </div>

          {summary.expiringSoon > 0 && (
            <div className="bg-white rounded-xl border border-amber-200 p-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-amber-100 rounded-lg flex items-center justify-center">
                  <Calendar className="w-5 h-5 text-amber-600" />
                </div>
                <div>
                  <p className="text-2xl font-bold text-gray-900">
                    {summary.expiringSoon}
                  </p>
                  <p className="text-sm text-gray-500">Expiring Soon</p>
                </div>
              </div>
            </div>
          )}

          {summary.expired > 0 && (
            <div className="bg-white rounded-xl border border-red-200 p-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-red-100 rounded-lg flex items-center justify-center">
                  <AlertTriangle className="w-5 h-5 text-red-600" />
                </div>
                <div>
                  <p className="text-2xl font-bold text-gray-900">
                    {summary.expired}
                  </p>
                  <p className="text-sm text-gray-500">Expired</p>
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Filters */}
      <div className="flex flex-wrap gap-4">
        <div className="flex-1 min-w-[200px]">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              placeholder="Search documents..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
          </div>
        </div>
        <select
          value={selectedCategory}
          onChange={(e) => setSelectedCategory(e.target.value)}
          className="px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
        >
          <option value="">All Categories</option>
          {Object.entries(categoryConfig).map(([key, config]) => (
            <option key={key} value={key}>
              {config.label}
            </option>
          ))}
        </select>
      </div>

      {/* Drop Zone */}
      <div
        onDrop={handleDrop}
        onDragOver={(e) => e.preventDefault()}
        className="border-2 border-dashed border-gray-300 rounded-xl p-8 text-center hover:border-indigo-400 transition-colors cursor-pointer"
        onClick={() => setShowUpload(true)}
      >
        <Upload className="w-10 h-10 text-gray-400 mx-auto mb-2" />
        <p className="text-gray-600">
          Drag and drop files here, or click to upload
        </p>
        <p className="text-sm text-gray-400 mt-1">
          Supports PDF, images, and documents up to 25MB
        </p>
      </div>

      {/* Document List */}
      {documents.length === 0 ? (
        <div className="text-center py-12 bg-white rounded-xl border border-gray-200">
          <FolderOpen className="w-12 h-12 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900">
            No documents yet
          </h3>
          <p className="text-gray-500">
            Upload your first document to get started
          </p>
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <div className="divide-y divide-gray-100">
            {documents.map((doc) => {
              const config = categoryConfig[doc.category] || categoryConfig.OTHER;
              const Icon = config.icon;
              const expiringSoon = isExpiringSoon(doc.expiresAt);
              const expired = isExpired(doc.expiresAt);

              return (
                <div
                  key={doc.id}
                  className="p-4 hover:bg-gray-50 flex items-center gap-4"
                >
                  <div
                    className={`w-10 h-10 rounded-lg flex items-center justify-center ${config.color}`}
                  >
                    <Icon className="w-5 h-5" />
                  </div>

                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <h3 className="font-medium text-gray-900 truncate">
                        {doc.title}
                      </h3>
                      {expired && (
                        <span className="px-2 py-0.5 bg-red-100 text-red-700 text-xs font-medium rounded">
                          Expired
                        </span>
                      )}
                      {expiringSoon && !expired && (
                        <span className="px-2 py-0.5 bg-amber-100 text-amber-700 text-xs font-medium rounded">
                          Expiring Soon
                        </span>
                      )}
                    </div>
                    <div className="flex items-center gap-3 mt-1 text-sm text-gray-500">
                      <span>{config.label}</span>
                      <span>•</span>
                      <span>{formatFileSize(doc.fileSize)}</span>
                      <span>•</span>
                      <span>{formatDate(doc.createdAt)}</span>
                      {doc.expiresAt && (
                        <>
                          <span>•</span>
                          <span>Expires: {formatDate(doc.expiresAt)}</span>
                        </>
                      )}
                    </div>
                  </div>

                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => handleDownload(doc)}
                      className="p-2 text-gray-400 hover:text-gray-600 rounded-lg hover:bg-gray-100"
                      title="Download"
                    >
                      <Download className="w-5 h-5" />
                    </button>
                    <button
                      onClick={() => handleDelete(doc.id)}
                      className="p-2 text-gray-400 hover:text-red-600 rounded-lg hover:bg-red-50"
                      title="Delete"
                    >
                      <Trash2 className="w-5 h-5" />
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Upload Modal */}
      {showUpload && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl w-full max-w-md">
            <div className="flex items-center justify-between p-4 border-b border-gray-200">
              <h2 className="text-lg font-semibold">Upload Document</h2>
              <button
                onClick={() => setShowUpload(false)}
                className="p-1 hover:bg-gray-100 rounded"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-4 space-y-4">
              {/* File Input */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  File
                </label>
                <input
                  type="file"
                  onChange={(e) => {
                    const file = e.target.files?.[0];
                    if (file) {
                      setUploadFile(file);
                      if (!uploadTitle) {
                        setUploadTitle(file.name.replace(/\.[^/.]+$/, ''));
                      }
                    }
                  }}
                  className="w-full"
                />
                {uploadFile && (
                  <p className="text-sm text-gray-500 mt-1">
                    {uploadFile.name} ({formatFileSize(uploadFile.size)})
                  </p>
                )}
              </div>

              {/* Category */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Category
                </label>
                <select
                  value={uploadCategory}
                  onChange={(e) => setUploadCategory(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-200 rounded-lg"
                >
                  {Object.entries(categoryConfig).map(([key, config]) => (
                    <option key={key} value={key}>
                      {config.label}
                    </option>
                  ))}
                </select>
              </div>

              {/* Title */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Title
                </label>
                <input
                  type="text"
                  value={uploadTitle}
                  onChange={(e) => setUploadTitle(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-200 rounded-lg"
                  placeholder="Document title"
                />
              </div>

              {/* Description */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Description (optional)
                </label>
                <textarea
                  value={uploadDescription}
                  onChange={(e) => setUploadDescription(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-200 rounded-lg"
                  rows={2}
                  placeholder="Brief description"
                />
              </div>

              {/* Expiration */}
              {['WARRANTY', 'INSURANCE', 'CONTRACT', 'PERMIT'].includes(
                uploadCategory,
              ) && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Expiration Date (optional)
                  </label>
                  <input
                    type="date"
                    value={uploadExpires}
                    onChange={(e) => setUploadExpires(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-200 rounded-lg"
                  />
                </div>
              )}
            </div>

            <div className="flex gap-3 p-4 border-t border-gray-200">
              <button
                onClick={() => setShowUpload(false)}
                className="flex-1 px-4 py-2 border border-gray-200 rounded-lg hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={handleUpload}
                disabled={!uploadFile || uploading}
                className="flex-1 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-50"
              >
                {uploading ? 'Uploading...' : 'Upload'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
