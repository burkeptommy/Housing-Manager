import SwiftUI

struct PropertyListView: View {
    @StateObject private var viewModel = PropertyListViewModel()
    @State private var showAddProperty = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.properties.isEmpty {
                    ScrollView {
                        VStack(spacing: HavenTheme.spacing12) {
                            SkeletonCard(lineCount: 2)
                            SkeletonCard(lineCount: 2)
                            SkeletonCard(lineCount: 2)
                        }
                        .padding()
                    }
                    .background(HavenColors.background)
                } else if viewModel.properties.isEmpty {
                    EmptyStateView(
                        title: "No Properties",
                        message: "Add your first property to start tracking home systems and maintenance.",
                        icon: "house.badge.plus",
                        actionTitle: "Add Property",
                        action: { showAddProperty = true }
                    )
                } else {
                    propertyList
                }
            }
            .navigationTitle("Properties")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.light()
                        showAddProperty = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add new property")
                }
            }
            .refreshable {
                Haptics.light()
                await viewModel.loadProperties()
            }
            .task {
                if viewModel.properties.isEmpty {
                    await viewModel.loadProperties()
                }
            }
            .sheet(isPresented: $showAddProperty) {
                AddPropertyView(onComplete: {
                    Haptics.success()
                    Task { await viewModel.loadProperties() }
                })
            }
        }
    }

    private var propertyList: some View {
        ScrollView {
            LazyVStack(spacing: HavenTheme.spacing12) {
                ForEach(viewModel.properties) { property in
                    NavigationLink {
                        PropertyDetailView(propertyID: property.id)
                    } label: {
                        PropertyCardRow(property: property)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, HavenTheme.spacing16)
            .padding(.top, HavenTheme.spacing8)
            .padding(.bottom, HavenTheme.spacing32)
        }
        .background(HavenColors.background)
    }
}

struct PropertyCardRow: View {
    let property: PropertyRow

    private var propertyIcon: String {
        switch property.propertyType.lowercased() {
        case "vacation home": return "sun.max.fill"
        case "rental property": return "building.fill"
        case "commercial": return "building.2.fill"
        case "land": return "leaf.fill"
        default: return "house.fill"
        }
    }

    var body: some View {
        HavenCard {
            HStack(spacing: HavenTheme.spacing16) {
                Image(systemName: propertyIcon)
                    .font(.title2)
                    .foregroundStyle(Color.havenAccent)
                    .frame(width: 48, height: 48)
                    .background(Color.havenAccent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: HavenTheme.spacing4) {
                    Text(property.name)
                        .font(HavenTypography.headline)
                    if let street = property.street {
                        Text(street)
                            .font(HavenTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let city = property.city, let state = property.state {
                        Text("\(city), \(state)")
                            .font(HavenTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(property.name), \(property.propertyType)")
        .accessibilityHint("View property details")
    }
}

#Preview {
    PropertyListView()
}
