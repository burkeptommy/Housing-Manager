import SwiftUI

@MainActor
final class AvatarPhotoService {
    static let shared = AvatarPhotoService()

    private let bucketName = "avatars"

    /// Upload a photo for a family member. Returns the signed URL string.
    func uploadAvatar(image: UIImage, memberId: UUID, householdId: UUID) async throws -> String {
        // Resize to max 400x400 to keep storage lean
        let resized = image.resizedToFit(maxDimension: 400)
        guard let data = resized.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "AvatarPhoto", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        let path = "\(householdId.uuidString.lowercased())/\(memberId.uuidString.lowercased())/avatar.jpg"

        // Upload to Supabase Storage (upsert to overwrite existing)
        try await HavenSupabase.storage
            .from(bucketName)
            .upload(path, data: data, options: .init(contentType: "image/jpeg", upsert: true))

        // Get a signed URL (1 year expiry)
        let url = try await HavenSupabase.storage
            .from(bucketName)
            .createSignedURL(path: path, expiresIn: 60 * 60 * 24 * 365)

        // Save URL to family_members row
        try await HavenSupabase.from("family_members")
            .update(["avatar_url": url.absoluteString])
            .eq("id", value: memberId.uuidString)
            .execute()

        return url.absoluteString
    }

    /// Delete the avatar photo for a member
    func deleteAvatar(memberId: UUID, householdId: UUID) async throws {
        let path = "\(householdId.uuidString.lowercased())/\(memberId.uuidString.lowercased())/avatar.jpg"
        try await HavenSupabase.storage
            .from(bucketName)
            .remove(paths: [path])

        try await HavenSupabase.from("family_members")
            .update(["avatar_url": nil] as [String: String?])
            .eq("id", value: memberId.uuidString)
            .execute()
    }

    /// Phase 95 — vehicle photo upload. Reuses the same `avatars` bucket
    /// + 1-year signed URL strategy as family member avatars; the path
    /// scheme is distinct (`{household}/vehicles/{vehicleId}.jpg`) so the
    /// two flows can't collide. Writes the URL back to `vehicles.photo_url`.
    func uploadVehiclePhoto(image: UIImage, vehicleId: UUID, householdId: UUID) async throws -> String {
        let resized = image.resizedToFit(maxDimension: 1200)
        guard let data = resized.jpegData(compressionQuality: 0.85) else {
            throw NSError(domain: "VehiclePhoto", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        let path = "\(householdId.uuidString.lowercased())/vehicles/\(vehicleId.uuidString.lowercased()).jpg"

        try await HavenSupabase.storage
            .from(bucketName)
            .upload(path, data: data, options: .init(contentType: "image/jpeg", upsert: true))

        let url = try await HavenSupabase.storage
            .from(bucketName)
            .createSignedURL(path: path, expiresIn: 60 * 60 * 24 * 365)

        try await HavenSupabase.from("vehicles")
            .update(["photo_url": url.absoluteString])
            .eq("id", value: vehicleId.uuidString)
            .execute()

        return url.absoluteString
    }

    /// Delete the vehicle photo and clear the URL on `vehicles`.
    func deleteVehiclePhoto(vehicleId: UUID, householdId: UUID) async throws {
        let path = "\(householdId.uuidString.lowercased())/vehicles/\(vehicleId.uuidString.lowercased()).jpg"
        try await HavenSupabase.storage
            .from(bucketName)
            .remove(paths: [path])

        try await HavenSupabase.from("vehicles")
            .update(["photo_url": nil] as [String: String?])
            .eq("id", value: vehicleId.uuidString)
            .execute()
    }
}

// MARK: - UIImage Resize Helper

extension UIImage {
    func resizedToFit(maxDimension: CGFloat) -> UIImage {
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        if ratio >= 1 { return self }
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
