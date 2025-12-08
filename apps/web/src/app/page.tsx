import { Button, Card, CardContent, CardHeader, CardTitle } from '@haven/ui';

export default function Home() {
  return (
    <main className="min-h-screen p-8">
      <div className="max-w-4xl mx-auto">
        <header className="text-center mb-12">
          <h1 className="text-4xl font-bold text-gray-900 mb-4">
            Haven Home Manager
          </h1>
          <p className="text-xl text-gray-600">
            Manage your home with ease
          </p>
        </header>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <Card>
            <CardHeader>
              <CardTitle>Your Homes</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-gray-600 mb-4">
                Add and manage all your properties in one place.
              </p>
              <Button variant="primary">View Homes</Button>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Tasks</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-gray-600 mb-4">
                Keep track of maintenance and home improvement tasks.
              </p>
              <Button variant="outline">View Tasks</Button>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Rooms</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-gray-600 mb-4">
                Organize your home by rooms for better management.
              </p>
              <Button variant="secondary">Manage Rooms</Button>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Settings</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-gray-600 mb-4">
                Configure your account and preferences.
              </p>
              <Button variant="ghost">Open Settings</Button>
            </CardContent>
          </Card>
        </div>
      </div>
    </main>
  );
}
