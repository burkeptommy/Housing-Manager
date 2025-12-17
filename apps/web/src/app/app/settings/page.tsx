'use client';

import { useState } from 'react';
import { useAuth } from '@/contexts/auth-context';

export default function SettingsPage() {
  const { user, currentHousehold, signOut } = useAuth();
  const [activeTab, setActiveTab] = useState<'profile' | 'notifications' | 'security' | 'preferences'>('profile');
  const [notificationSettings, setNotificationSettings] = useState({
    emailBillReminders: true,
    emailMaintenanceReminders: true,
    emailWorkOrderUpdates: true,
    pushBillReminders: true,
    pushMaintenanceReminders: true,
    pushWorkOrderUpdates: false,
    smsUrgentAlerts: true,
    weeklyDigest: true,
  });
  const [preferences, setPreferences] = useState({
    reminderDays: '3',
    theme: 'system',
    language: 'en',
    timezone: 'America/New_York',
  });
  const [isSaving, setIsSaving] = useState(false);
  const [successMessage, setSuccessMessage] = useState('');

  const handleSave = async () => {
    setIsSaving(true);
    // Simulate save
    await new Promise((resolve) => setTimeout(resolve, 500));
    setIsSaving(false);
    setSuccessMessage('Settings saved successfully');
    setTimeout(() => setSuccessMessage(''), 3000);
  };

  const tabs = [
    { id: 'profile', label: 'Profile', icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
      </svg>
    )},
    { id: 'notifications', label: 'Notifications', icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
      </svg>
    )},
    { id: 'security', label: 'Security', icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
      </svg>
    )},
    { id: 'preferences', label: 'Preferences', icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4" />
      </svg>
    )},
  ];

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div>
        <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Settings</h1>
        <p className="text-slate-600 dark:text-slate-400 mt-1">
          Manage your account preferences and notification settings.
        </p>
      </div>

      {/* Success Message */}
      {successMessage && (
        <div className="p-4 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800">
          <div className="flex items-center gap-2">
            <svg className="w-5 h-5 text-green-600 dark:text-green-400" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
            </svg>
            <p className="text-sm text-green-600 dark:text-green-400">{successMessage}</p>
          </div>
        </div>
      )}

      <div className="flex flex-col lg:flex-row gap-6">
        {/* Tab Navigation */}
        <div className="lg:w-64">
          <nav className="space-y-1">
            {tabs.map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as typeof activeTab)}
                className={`w-full flex items-center gap-3 px-4 py-3 rounded-lg text-sm font-medium transition-colors ${
                  activeTab === tab.id
                    ? 'bg-blue-50 text-blue-600 dark:bg-blue-900/20 dark:text-blue-400'
                    : 'text-slate-600 hover:bg-slate-100 dark:text-slate-400 dark:hover:bg-slate-700/50'
                }`}
              >
                {tab.icon}
                {tab.label}
              </button>
            ))}
          </nav>
        </div>

        {/* Content */}
        <div className="flex-1">
          {/* Profile Tab */}
          {activeTab === 'profile' && (
            <div className="card space-y-6">
              <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Profile Information</h2>

              <div className="flex items-center gap-4">
                <div className="w-20 h-20 rounded-full bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
                  <span className="text-2xl font-semibold text-blue-600 dark:text-blue-400">
                    {user?.firstName?.[0] || user?.email?.[0]?.toUpperCase() || 'U'}
                  </span>
                </div>
                <div>
                  <button className="btn btn-secondary text-sm">Change Photo</button>
                  <p className="text-xs text-slate-500 mt-1">JPG, PNG or GIF. Max 2MB</p>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="label block mb-1.5">First Name</label>
                  <input
                    type="text"
                    className="input"
                    defaultValue={user?.firstName || ''}
                    placeholder="Enter first name"
                  />
                </div>
                <div>
                  <label className="label block mb-1.5">Last Name</label>
                  <input
                    type="text"
                    className="input"
                    defaultValue={user?.lastName || ''}
                    placeholder="Enter last name"
                  />
                </div>
                <div className="md:col-span-2">
                  <label className="label block mb-1.5">Email</label>
                  <input
                    type="email"
                    className="input bg-slate-50 dark:bg-slate-700"
                    value={user?.email || ''}
                    disabled
                  />
                  <p className="text-xs text-slate-500 mt-1">Contact support to change your email</p>
                </div>
                <div>
                  <label className="label block mb-1.5">Phone Number</label>
                  <input
                    type="tel"
                    className="input"
                    defaultValue={user?.phone || ''}
                    placeholder="(555) 123-4567"
                  />
                </div>
              </div>

              <div className="pt-4 border-t border-slate-200 dark:border-slate-700">
                <h3 className="font-medium text-slate-900 dark:text-white mb-3">Current Household</h3>
                <div className="p-4 rounded-lg bg-slate-50 dark:bg-slate-700/50">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="font-medium text-slate-900 dark:text-white">{currentHousehold?.name || 'No household selected'}</p>
                      <p className="text-sm text-slate-500">{currentHousehold?.address?.city}, {currentHousehold?.address?.state}</p>
                    </div>
                    <span className="badge badge-green">Active</span>
                  </div>
                </div>
              </div>

              <button onClick={handleSave} disabled={isSaving} className="btn btn-primary">
                {isSaving ? 'Saving...' : 'Save Changes'}
              </button>
            </div>
          )}

          {/* Notifications Tab */}
          {activeTab === 'notifications' && (
            <div className="card space-y-6">
              <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Notification Preferences</h2>

              <div className="space-y-6">
                <div>
                  <h3 className="font-medium text-slate-900 dark:text-white mb-4">Email Notifications</h3>
                  <div className="space-y-3">
                    {[
                      { key: 'emailBillReminders', label: 'Bill payment reminders', desc: 'Get reminded before bills are due' },
                      { key: 'emailMaintenanceReminders', label: 'Maintenance task reminders', desc: 'Never miss scheduled maintenance' },
                      { key: 'emailWorkOrderUpdates', label: 'Work order updates', desc: 'Status changes and vendor communications' },
                      { key: 'weeklyDigest', label: 'Weekly digest', desc: 'Summary of upcoming tasks and bills' },
                    ].map((item) => (
                      <label key={item.key} className="flex items-start gap-3 p-3 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-700/50 cursor-pointer">
                        <input
                          type="checkbox"
                          checked={notificationSettings[item.key as keyof typeof notificationSettings] as boolean}
                          onChange={(e) => setNotificationSettings({...notificationSettings, [item.key]: e.target.checked})}
                          className="mt-1 w-4 h-4 text-blue-600 rounded"
                        />
                        <div>
                          <p className="font-medium text-slate-900 dark:text-white">{item.label}</p>
                          <p className="text-sm text-slate-500">{item.desc}</p>
                        </div>
                      </label>
                    ))}
                  </div>
                </div>

                <div>
                  <h3 className="font-medium text-slate-900 dark:text-white mb-4">Push Notifications</h3>
                  <div className="space-y-3">
                    {[
                      { key: 'pushBillReminders', label: 'Bill reminders', desc: 'Push notifications for upcoming bills' },
                      { key: 'pushMaintenanceReminders', label: 'Maintenance reminders', desc: 'Push notifications for tasks' },
                      { key: 'pushWorkOrderUpdates', label: 'Work order updates', desc: 'Real-time status updates' },
                    ].map((item) => (
                      <label key={item.key} className="flex items-start gap-3 p-3 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-700/50 cursor-pointer">
                        <input
                          type="checkbox"
                          checked={notificationSettings[item.key as keyof typeof notificationSettings] as boolean}
                          onChange={(e) => setNotificationSettings({...notificationSettings, [item.key]: e.target.checked})}
                          className="mt-1 w-4 h-4 text-blue-600 rounded"
                        />
                        <div>
                          <p className="font-medium text-slate-900 dark:text-white">{item.label}</p>
                          <p className="text-sm text-slate-500">{item.desc}</p>
                        </div>
                      </label>
                    ))}
                  </div>
                </div>

                <div>
                  <h3 className="font-medium text-slate-900 dark:text-white mb-4">SMS Notifications</h3>
                  <label className="flex items-start gap-3 p-3 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-700/50 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={notificationSettings.smsUrgentAlerts}
                      onChange={(e) => setNotificationSettings({...notificationSettings, smsUrgentAlerts: e.target.checked})}
                      className="mt-1 w-4 h-4 text-blue-600 rounded"
                    />
                    <div>
                      <p className="font-medium text-slate-900 dark:text-white">Urgent alerts only</p>
                      <p className="text-sm text-slate-500">Emergency notifications and critical updates</p>
                    </div>
                  </label>
                </div>
              </div>

              <button onClick={handleSave} disabled={isSaving} className="btn btn-primary">
                {isSaving ? 'Saving...' : 'Save Preferences'}
              </button>
            </div>
          )}

          {/* Security Tab */}
          {activeTab === 'security' && (
            <div className="space-y-6">
              <div className="card">
                <h2 className="text-lg font-semibold text-slate-900 dark:text-white mb-6">Security Settings</h2>

                <div className="space-y-6">
                  <div>
                    <h3 className="font-medium text-slate-900 dark:text-white mb-2">Password</h3>
                    <p className="text-sm text-slate-500 mb-3">Last changed: Never</p>
                    <button className="btn btn-secondary">Change Password</button>
                  </div>

                  <div className="pt-6 border-t border-slate-200 dark:border-slate-700">
                    <h3 className="font-medium text-slate-900 dark:text-white mb-2">Two-Factor Authentication</h3>
                    <p className="text-sm text-slate-500 mb-3">Add an extra layer of security to your account</p>
                    <div className="flex items-center justify-between p-4 rounded-lg bg-slate-50 dark:bg-slate-700/50">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-lg bg-green-100 dark:bg-green-900/30 flex items-center justify-center">
                          <svg className="w-5 h-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                          </svg>
                        </div>
                        <div>
                          <p className="font-medium text-slate-900 dark:text-white">Authenticator App</p>
                          <p className="text-sm text-slate-500">Not enabled</p>
                        </div>
                      </div>
                      <button className="btn btn-secondary text-sm">Enable</button>
                    </div>
                  </div>

                  <div className="pt-6 border-t border-slate-200 dark:border-slate-700">
                    <h3 className="font-medium text-slate-900 dark:text-white mb-2">Active Sessions</h3>
                    <p className="text-sm text-slate-500 mb-3">Manage your active login sessions</p>
                    <div className="p-4 rounded-lg bg-slate-50 dark:bg-slate-700/50">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-3">
                          <svg className="w-8 h-8 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                          </svg>
                          <div>
                            <p className="font-medium text-slate-900 dark:text-white">Current Session</p>
                            <p className="text-sm text-slate-500">Chrome on macOS</p>
                          </div>
                        </div>
                        <span className="badge badge-green">Active</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <div className="card border-red-200 dark:border-red-800">
                <h2 className="text-lg font-semibold text-red-600 dark:text-red-400 mb-4">Danger Zone</h2>
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="font-medium text-slate-900 dark:text-white">Sign out everywhere</p>
                      <p className="text-sm text-slate-500">Sign out of all sessions except this one</p>
                    </div>
                    <button className="btn btn-secondary text-sm">Sign Out All</button>
                  </div>
                  <div className="flex items-center justify-between pt-4 border-t border-slate-200 dark:border-slate-700">
                    <div>
                      <p className="font-medium text-slate-900 dark:text-white">Delete Account</p>
                      <p className="text-sm text-slate-500">Permanently delete your account and all data</p>
                    </div>
                    <button className="btn bg-red-600 hover:bg-red-700 text-white text-sm">Delete Account</button>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Preferences Tab */}
          {activeTab === 'preferences' && (
            <div className="card space-y-6">
              <h2 className="text-lg font-semibold text-slate-900 dark:text-white">App Preferences</h2>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label className="label block mb-1.5">Reminder Lead Time</label>
                  <select
                    className="input"
                    value={preferences.reminderDays}
                    onChange={(e) => setPreferences({...preferences, reminderDays: e.target.value})}
                  >
                    <option value="1">1 day before</option>
                    <option value="3">3 days before</option>
                    <option value="5">5 days before</option>
                    <option value="7">1 week before</option>
                  </select>
                  <p className="text-xs text-slate-500 mt-1">When to send reminders for bills and tasks</p>
                </div>

                <div>
                  <label className="label block mb-1.5">Theme</label>
                  <select
                    className="input"
                    value={preferences.theme}
                    onChange={(e) => setPreferences({...preferences, theme: e.target.value})}
                  >
                    <option value="system">System Default</option>
                    <option value="light">Light</option>
                    <option value="dark">Dark</option>
                  </select>
                </div>

                <div>
                  <label className="label block mb-1.5">Language</label>
                  <select
                    className="input"
                    value={preferences.language}
                    onChange={(e) => setPreferences({...preferences, language: e.target.value})}
                  >
                    <option value="en">English</option>
                    <option value="es">Spanish</option>
                    <option value="fr">French</option>
                  </select>
                </div>

                <div>
                  <label className="label block mb-1.5">Timezone</label>
                  <select
                    className="input"
                    value={preferences.timezone}
                    onChange={(e) => setPreferences({...preferences, timezone: e.target.value})}
                  >
                    <option value="America/New_York">Eastern Time (ET)</option>
                    <option value="America/Chicago">Central Time (CT)</option>
                    <option value="America/Denver">Mountain Time (MT)</option>
                    <option value="America/Los_Angeles">Pacific Time (PT)</option>
                  </select>
                </div>
              </div>

              <div className="pt-6 border-t border-slate-200 dark:border-slate-700">
                <h3 className="font-medium text-slate-900 dark:text-white mb-4">Dashboard Widgets</h3>
                <div className="space-y-3">
                  {[
                    { label: 'Upcoming Bills', desc: 'Show bills due in the next 30 days' },
                    { label: 'Maintenance Tasks', desc: 'Show upcoming maintenance reminders' },
                    { label: 'Recent Activity', desc: 'Show recent work orders and requests' },
                    { label: 'Weather Widget', desc: 'Show local weather forecast' },
                  ].map((widget, i) => (
                    <label key={i} className="flex items-start gap-3 p-3 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-700/50 cursor-pointer">
                      <input
                        type="checkbox"
                        defaultChecked={i < 3}
                        className="mt-1 w-4 h-4 text-blue-600 rounded"
                      />
                      <div>
                        <p className="font-medium text-slate-900 dark:text-white">{widget.label}</p>
                        <p className="text-sm text-slate-500">{widget.desc}</p>
                      </div>
                    </label>
                  ))}
                </div>
              </div>

              <button onClick={handleSave} disabled={isSaving} className="btn btn-primary">
                {isSaving ? 'Saving...' : 'Save Preferences'}
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Sign Out Button */}
      <div className="pt-4">
        <button
          onClick={() => signOut()}
          className="flex items-center gap-2 text-red-600 hover:text-red-700 dark:text-red-400 dark:hover:text-red-300 font-medium"
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
          </svg>
          Sign Out
        </button>
      </div>
    </div>
  );
}
