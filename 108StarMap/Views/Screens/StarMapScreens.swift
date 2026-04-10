import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: StarMapViewModel
    @State private var showAddObservation = false
    @State private var showAddConstellation = false
    @State private var showAddStar = false
    @State private var showAddEvent = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tonight's Sky")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        Text("Track stars, save observations, and plan your next night session.")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [Color.starCard, Color.starAccent.opacity(0.35)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            StatCard(title: "Constellations", value: "\(viewModel.constellations.count)", icon: "star.circle.fill", color: .starAccent, cardColor: .starCard)
                            StatCard(title: "Stars", value: "\(viewModel.totalStars)", icon: "star.fill", color: .starAccent, cardColor: .starCard)
                            StatCard(title: "Observations", value: "\(viewModel.observations.count)", icon: "binoculars.fill", color: .starAccent, cardColor: .starCard)
                            StatCard(title: "Visible now", value: viewModel.visibleNowCount, icon: "moon.stars", color: .starAccent, cardColor: .starCard)
                        }
                        .padding(.horizontal)
                    }

                    Text("Quick actions")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        quickAction(title: "Add constellation", icon: "star.circle.fill") { showAddConstellation = true }
                        quickAction(title: "Add star", icon: "star.fill") { showAddStar = true }
                        quickAction(title: "Add observation", icon: "binoculars.fill") { showAddObservation = true }
                        quickAction(title: "Add event", icon: "calendar") { showAddEvent = true }
                    }
                    .padding(.horizontal)

                    Text("Visible now")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal)
                    if viewModel.seasonalConstellations.isEmpty {
                        emptyHint("No constellations for current season yet.")
                            .padding(.horizontal)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.seasonalConstellations) { constellation in
                                    NavigationLink(destination: ConstellationDetailView(constellation: constellation, viewModel: viewModel)) {
                                        ConstellationCard(constellation: constellation)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    Text("Favorite stars")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal)
                    let favorites = viewModel.constellations.flatMap(\.stars).filter(\.isFavorite)
                    if favorites.isEmpty {
                        emptyHint("Mark stars as favorite to see them here.")
                            .padding(.horizontal)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(favorites) { star in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(star.name)
                                            .foregroundStyle(.white)
                                            .font(.headline)
                                        Text(star.constellationName)
                                            .foregroundStyle(.gray)
                                            .font(.caption)
                                    }
                                    .padding()
                                    .frame(width: 170, alignment: .leading)
                                    .starCardStyle(cornerRadius: 12)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    Text("Recent observations")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal)

                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.recentObservations) { observation in
                            ObservationRow(observation: observation)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        viewModel.deleteObservation(observation)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)

                    Text("Upcoming events")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal)

                    let upcoming = viewModel.events.sorted { $0.date < $1.date }.prefix(3)
                    if upcoming.isEmpty {
                        emptyHint("No events added yet.")
                            .padding(.horizontal)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(Array(upcoming)) { event in
                                EventCard(event: event)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .starScreenBackground()
            .sheet(isPresented: $showAddObservation) {
                AddObservationView(viewModel: viewModel)
            }
            .sheet(isPresented: $showAddConstellation) {
                AddConstellationView(viewModel: viewModel)
            }
            .sheet(isPresented: $showAddStar) {
                AddStarFromStarsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showAddEvent) {
                AddEventView(viewModel: viewModel)
            }
        }
    }

    private func quickAction(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.starAccent)
                Text(title)
                    .foregroundStyle(.white)
                    .font(.subheadline)
                Spacer()
            }
            .padding()
            .starCardStyle(cornerRadius: 12)
        }
    }

    private func emptyHint(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.gray)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .starCardStyle(cornerRadius: 10)
    }
}

struct ConstellationsView: View {
    @ObservedObject var viewModel: StarMapViewModel
    @State private var showAdd = false
    @State private var query = ""
    @State private var selectedHemisphere: Hemisphere?

    private var filtered: [Constellation] {
        var result = viewModel.constellations
        if let selectedHemisphere {
            result = result.filter { $0.hemisphere == selectedHemisphere }
        }
        if !query.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(query) ||
                $0.latinName.localizedCaseInsensitiveContains(query)
            }
        }
        return result.sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.starAccent)
                    TextField("Search constellations", text: $query)
                        .foregroundStyle(.white)
                }
                .padding()
                .starCardStyle(cornerRadius: 10)
                .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        FilterChip(title: "All", isSelected: selectedHemisphere == nil, color: .starAccent)
                            .onTapGesture { selectedHemisphere = nil }
                        ForEach(Hemisphere.allCases, id: \.self) { hemisphere in
                            FilterChip(title: hemisphere.rawValue, isSelected: selectedHemisphere == hemisphere, color: .starAccent)
                                .onTapGesture { selectedHemisphere = hemisphere }
                        }
                    }
                    .padding(.horizontal)
                }

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(filtered) { constellation in
                            NavigationLink(destination: ConstellationDetailView(constellation: constellation, viewModel: viewModel)) {
                                ConstellationDetailCard(constellation: constellation)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button {
                                    viewModel.toggleFavoriteConstellation(constellation)
                                } label: {
                                    Label("Favorite", systemImage: "star")
                                }
                                Button(role: .destructive) {
                                    viewModel.deleteConstellation(constellation)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .starScreenBackground()
            .navigationTitle("Constellations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.starAccent)
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddConstellationView(viewModel: viewModel)
            }
        }
    }
}

struct ConstellationDetailCard: View {
    let constellation: Constellation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(constellation.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                if constellation.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.starAccent)
                }
            }
            Text(constellation.latinName)
                .font(.caption)
                .foregroundColor(.starAccent)
            Text(constellation.description)
                .font(.caption)
                .foregroundStyle(.gray)
                .lineLimit(2)
            HStack {
                Image(systemName: constellation.hemisphere.icon)
                    .foregroundColor(.starAccent)
                Text(constellation.hemisphere.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.gray)
                Spacer()
                Text("\(constellation.stars.count) stars")
                    .font(.caption2)
                    .foregroundColor(.starAccent)
            }
        }
        .padding()
        .starCardStyle(cornerRadius: 12)
    }
}

struct ConstellationDetailView: View {
    let constellation: Constellation
    @ObservedObject var viewModel: StarMapViewModel
    @State private var showAddStar = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(constellation.name)
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                        Spacer()
                        if constellation.isFavorite {
                            Image(systemName: "star.fill")
                                .foregroundColor(.starAccent)
                        }
                    }
                    Text(constellation.latinName)
                        .font(.title3)
                        .foregroundColor(.starAccent)
                    Text(constellation.abbreviation)
                        .font(.headline)
                        .foregroundStyle(.gray)
                }
                .padding()

                Group {
                    Text("Description")
                        .font(.headline)
                        .foregroundColor(.starAccent)
                    Text(constellation.description)
                        .foregroundStyle(.white)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .starCardStyle(cornerRadius: 8)
                }
                .padding(.horizontal)

                if let mythology = constellation.mythology, !mythology.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Mythology")
                            .font(.headline)
                            .foregroundColor(.starAccent)
                        Text(mythology)
                            .foregroundStyle(.white)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .starCardStyle(cornerRadius: 8)
                    }
                    .padding(.horizontal)
                }

                VStack(alignment: .leading) {
                    Text("Stars")
                        .font(.headline)
                        .foregroundColor(.starAccent)
                        .padding(.horizontal)
                    ForEach(currentConstellation.stars) { star in
                        StarRow(star: star)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .starScreenBackground()
        .navigationTitle("Details")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddStar = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.starAccent)
                }
            }
        }
        .sheet(isPresented: $showAddStar) {
            AddStarView(viewModel: viewModel, constellation: currentConstellation)
        }
    }

    private var currentConstellation: Constellation {
        viewModel.constellations.first(where: { $0.id == constellation.id }) ?? constellation
    }
}

struct StarsView: View {
    @ObservedObject var viewModel: StarMapViewModel
    @State private var selectedBrightness: StarBrightness?
    @State private var query = ""
    @State private var showAddStar = false

    private var filtered: [Star] {
        var result = viewModel.constellations.flatMap(\.stars)
        if let selectedBrightness {
            result = result.filter { $0.brightness == selectedBrightness }
        }
        if !query.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(query) || $0.designation.localizedCaseInsensitiveContains(query) }
        }
        return result.sorted { $0.brightness.rawValue < $1.brightness.rawValue }
    }

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.starAccent)
                    TextField("Search stars", text: $query)
                        .foregroundStyle(.white)
                }
                .padding()
                .starCardStyle(cornerRadius: 10)
                .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        FilterChip(title: "All", isSelected: selectedBrightness == nil, color: .starAccent)
                            .onTapGesture { selectedBrightness = nil }
                        ForEach(StarBrightness.allCases, id: \.self) { brightness in
                            FilterChip(title: brightness.description, isSelected: selectedBrightness == brightness, color: .starAccent)
                                .onTapGesture { selectedBrightness = brightness }
                        }
                    }
                    .padding(.horizontal)
                }

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filtered) { star in
                            NavigationLink(destination: StarDetailView(star: star, viewModel: viewModel)) {
                                StarDetailRow(star: star)
                            }
                            .buttonStyle(.plain)
                                .contextMenu {
                                    Button {
                                        viewModel.toggleFavoriteStar(star)
                                    } label: {
                                        Label("Favorite", systemImage: "star")
                                    }
                                    Button(role: .destructive) {
                                        viewModel.deleteStar(star)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding()
                }
            }
            .starScreenBackground()
            .navigationTitle("Stars")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddStar = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.starAccent)
                    }
                }
            }
            .sheet(isPresented: $showAddStar) {
                AddStarFromStarsView(viewModel: viewModel)
            }
        }
    }
}

struct StarDetailRow: View {
    let star: Star

    var body: some View {
        HStack {
            Image(systemName: star.brightness.icon)
                .foregroundColor(.starAccent)
                .font(.title2)
            VStack(alignment: .leading) {
                HStack {
                    Text(star.name)
                        .foregroundStyle(.white)
                    if star.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.starAccent)
                            .font(.caption)
                    }
                }
                Text("\(star.constellationName) • \(star.brightness.description)")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            Spacer()
            if let color = star.color, !color.isEmpty {
                Text(color)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.starCard.opacity(0.6))
                    .foregroundColor(.starAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.starAccent.opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .padding()
        .starCardStyle(cornerRadius: 8)
    }
}

struct ObservationsView: View {
    @ObservedObject var viewModel: StarMapViewModel
    @State private var showAdd = false
    @State private var editingObservation: Observation?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.observations.sorted { $0.date > $1.date }) { observation in
                        ObservationCard(observation: observation)
                            .contextMenu {
                                Button {
                                    editingObservation = observation
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    viewModel.deleteObservation(observation)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding()
            }
            .starScreenBackground()
            .navigationTitle("Observations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.starAccent)
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddObservationView(viewModel: viewModel)
            }
            .sheet(item: $editingObservation) { observation in
                EditObservationView(viewModel: viewModel, observation: observation)
            }
        }
    }
}

struct ObservationCard: View {
    let observation: Observation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "binoculars.fill")
                    .foregroundColor(.starAccent)
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text(observation.starName)
                        .foregroundStyle(.white)
                        .font(.headline)
                    Text(observation.constellationName)
                        .font(.caption)
                        .foregroundColor(.starAccent)
                }
                Spacer()
                Text(formattedDate(observation.date))
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            if let location = observation.location, !location.isEmpty {
                Text(location)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            if let notes = observation.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .lineLimit(2)
            }
        }
        .padding()
        .starCardStyle(cornerRadius: 12)
    }
}

struct EventsView: View {
    @ObservedObject var viewModel: StarMapViewModel
    @State private var showAddEventSheet = false
    @State private var editingEvent: AstronomicalEvent?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.events.sorted { $0.date < $1.date }) { event in
                        EventCard(event: event)
                            .contextMenu {
                                Button {
                                    editingEvent = event
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                Button {
                                    viewModel.toggleNotification(event)
                                } label: {
                                    Label(event.isNotified ? "Disable reminder" : "Remind me", systemImage: "bell")
                                }
                                Button(role: .destructive) {
                                    viewModel.deleteEvent(event)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                    Button("Add Event") {
                        showAddEventSheet = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .starPrimaryButtonStyle(cornerRadius: 12)
                }
                .padding()
            }
            .starScreenBackground()
            .navigationTitle("Astronomical Events")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAddEventSheet) {
                AddEventView(viewModel: viewModel)
            }
            .sheet(item: $editingEvent) { event in
                EditEventView(viewModel: viewModel, event: event)
            }
        }
    }
}

struct EventCard: View {
    let event: AstronomicalEvent

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(event.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(formattedDate(event.date))
                    .font(.caption)
                    .foregroundColor(.starAccent)
                Text(event.description)
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .lineLimit(2)
            }
            Spacer()
            if event.isNotified {
                Image(systemName: "bell.fill")
                    .foregroundColor(.starAccent)
            }
        }
        .padding()
        .starCardStyle(cornerRadius: 12)
    }
}

struct AddConstellationView: View {
    @ObservedObject var viewModel: StarMapViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var latinName = ""
    @State private var abbreviation = ""
    @State private var hemisphere: Hemisphere = .northern
    @State private var visibility: Visibility = .allYear
    @State private var details = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Latin name", text: $latinName)
                TextField("Abbreviation", text: $abbreviation)
                Picker("Hemisphere", selection: $hemisphere) {
                    ForEach(Hemisphere.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                Picker("Visibility", selection: $visibility) {
                    ForEach(Visibility.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                TextField("Description", text: $details, axis: .vertical)
            }
            .navigationTitle("Add Constellation")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let item = Constellation(id: UUID(), name: name, latinName: latinName, abbreviation: abbreviation, hemisphere: hemisphere, visibility: visibility, description: details, mythology: nil, brightestStar: nil, area: nil, stars: [], isFavorite: false, createdAt: Date())
                        viewModel.addConstellation(item)
                        dismiss()
                    }
                    .disabled(name.isEmpty || latinName.isEmpty)
                }
            }
        }
    }
}

struct AddStarView: View {
    @ObservedObject var viewModel: StarMapViewModel
    let constellation: Constellation
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var designation = ""
    @State private var brightness: StarBrightness = .magnitude3
    @State private var color = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Designation", text: $designation)
                Picker("Brightness", selection: $brightness) {
                    ForEach(StarBrightness.allCases, id: \.self) { Text($0.description).tag($0) }
                }
                TextField("Color", text: $color)
            }
            .navigationTitle("Add Star")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let star = Star(
                            id: UUID(),
                            name: name,
                            designation: designation,
                            brightness: brightness,
                            constellationId: constellation.id,
                            constellationName: constellation.name,
                            rightAscension: nil,
                            declination: nil,
                            distance: nil,
                            temperature: nil,
                            color: color.isEmpty ? nil : color,
                            description: nil,
                            isFavorite: false
                        )
                        viewModel.addStar(star, to: constellation.id)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct AddObservationView: View {
    @ObservedObject var viewModel: StarMapViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()
    @State private var starName = ""
    @State private var constellationName = ""
    @State private var location = ""
    @State private var notes = ""
    @State private var rating = 3

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date)
                TextField("Star name", text: $starName)
                TextField("Constellation name", text: $constellationName)
                TextField("Location", text: $location)
                TextField("Notes", text: $notes, axis: .vertical)
                Stepper("Rating: \(rating)", value: $rating, in: 1...5)
            }
            .navigationTitle("Add Observation")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let matchingConstellation = viewModel.constellations.first { $0.name.caseInsensitiveCompare(constellationName) == .orderedSame }
                        let observation = Observation(
                            id: UUID(),
                            date: date,
                            starId: nil,
                            starName: starName,
                            constellationId: matchingConstellation?.id ?? UUID(),
                            constellationName: constellationName,
                            location: location.isEmpty ? nil : location,
                            equipment: nil,
                            conditions: nil,
                            notes: notes.isEmpty ? nil : notes,
                            rating: rating,
                            isFavorite: false
                        )
                        viewModel.addObservation(observation)
                        dismiss()
                    }
                    .disabled(starName.isEmpty || constellationName.isEmpty)
                }
            }
        }
    }
}

struct AddEventView: View {
    @ObservedObject var viewModel: StarMapViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var date = Date()
    @State private var details = ""
    @State private var notify = true

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                DatePicker("Date", selection: $date)
                TextField("Description", text: $details, axis: .vertical)
                Toggle("Enable reminder", isOn: $notify)
            }
            .navigationTitle("Add Event")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let item = AstronomicalEvent(id: UUID(), name: name, date: date, description: details, visibility: nil, isNotified: notify)
                        viewModel.addEvent(item)
                        dismiss()
                    }
                    .disabled(name.isEmpty || details.isEmpty)
                }
            }
        }
    }
}

struct AddStarFromStarsView: View {
    @ObservedObject var viewModel: StarMapViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var designation = ""
    @State private var brightness: StarBrightness = .magnitude3
    @State private var color = ""
    @State private var selectedConstellationId: UUID?

    var body: some View {
        NavigationStack {
            Form {
                if viewModel.constellations.isEmpty {
                    Text("Add a constellation first.")
                        .foregroundColor(.gray)
                } else {
                    Picker("Constellation", selection: $selectedConstellationId) {
                        ForEach(viewModel.constellations) { constellation in
                            Text(constellation.name).tag(Optional(constellation.id))
                        }
                    }
                }

                TextField("Name", text: $name)
                TextField("Designation", text: $designation)
                Picker("Brightness", selection: $brightness) {
                    ForEach(StarBrightness.allCases, id: \.self) { Text($0.description).tag($0) }
                }
                TextField("Color", text: $color)
            }
            .navigationTitle("Add Star")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        guard
                            let constellationId = selectedConstellationId,
                            let constellation = viewModel.constellations.first(where: { $0.id == constellationId })
                        else { return }

                        let star = Star(
                            id: UUID(),
                            name: name,
                            designation: designation,
                            brightness: brightness,
                            constellationId: constellation.id,
                            constellationName: constellation.name,
                            rightAscension: nil,
                            declination: nil,
                            distance: nil,
                            temperature: nil,
                            color: color.isEmpty ? nil : color,
                            description: nil,
                            isFavorite: false
                        )
                        viewModel.addStar(star, to: constellation.id)
                        dismiss()
                    }
                    .disabled(
                        viewModel.constellations.isEmpty ||
                        selectedConstellationId == nil ||
                        name.isEmpty
                    )
                }
            }
            .onAppear {
                if selectedConstellationId == nil {
                    selectedConstellationId = viewModel.constellations.first?.id
                }
            }
        }
    }
}

struct StarDetailView: View {
    let star: Star
    @ObservedObject var viewModel: StarMapViewModel
    @State private var showEdit = false

    var body: some View {
        let currentStar = latestStar
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(currentStar.name)
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                    Text(currentStar.constellationName)
                        .font(.title3)
                        .foregroundColor(.starAccent)
                    Text(currentStar.brightness.description)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                .padding()

                detailBlock(title: "Designation", value: currentStar.designation)
                detailBlock(title: "Color", value: currentStar.color ?? "Unknown")
                detailBlock(title: "Right ascension", value: currentStar.rightAscension ?? "Not set")
                detailBlock(title: "Declination", value: currentStar.declination ?? "Not set")
                detailBlock(title: "Distance (ly)", value: currentStar.distance.map { String(Int($0)) } ?? "Not set")
            }
            .padding(.bottom)
        }
        .starScreenBackground()
        .navigationTitle("Star")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showEdit = true
                }
                .foregroundColor(.starAccent)
            }
        }
        .sheet(isPresented: $showEdit) {
            EditStarView(viewModel: viewModel, star: latestStar)
        }
    }

    private var latestStar: Star {
        viewModel.constellations.flatMap(\.stars).first(where: { $0.id == star.id }) ?? star
    }

    @ViewBuilder
    private func detailBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.starAccent)
            Text(value)
                .foregroundStyle(.white)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .starCardStyle(cornerRadius: 10)
        .padding(.horizontal)
    }
}

struct EditStarView: View {
    @ObservedObject var viewModel: StarMapViewModel
    @Environment(\.dismiss) private var dismiss
    let star: Star

    @State private var name: String
    @State private var designation: String
    @State private var brightness: StarBrightness
    @State private var color: String

    init(viewModel: StarMapViewModel, star: Star) {
        self.viewModel = viewModel
        self.star = star
        _name = State(initialValue: star.name)
        _designation = State(initialValue: star.designation)
        _brightness = State(initialValue: star.brightness)
        _color = State(initialValue: star.color ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Designation", text: $designation)
                Picker("Brightness", selection: $brightness) {
                    ForEach(StarBrightness.allCases, id: \.self) { Text($0.description).tag($0) }
                }
                TextField("Color", text: $color)
            }
            .navigationTitle("Edit Star")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        var updated = star
                        updated.name = name
                        updated.designation = designation
                        updated.brightness = brightness
                        updated.color = color.isEmpty ? nil : color
                        viewModel.updateStar(updated)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EditObservationView: View {
    @ObservedObject var viewModel: StarMapViewModel
    @Environment(\.dismiss) private var dismiss
    let observation: Observation

    @State private var date: Date
    @State private var starName: String
    @State private var constellationName: String
    @State private var location: String
    @State private var notes: String
    @State private var rating: Int

    init(viewModel: StarMapViewModel, observation: Observation) {
        self.viewModel = viewModel
        self.observation = observation
        _date = State(initialValue: observation.date)
        _starName = State(initialValue: observation.starName)
        _constellationName = State(initialValue: observation.constellationName)
        _location = State(initialValue: observation.location ?? "")
        _notes = State(initialValue: observation.notes ?? "")
        _rating = State(initialValue: observation.rating ?? 3)
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date)
                TextField("Star name", text: $starName)
                TextField("Constellation name", text: $constellationName)
                TextField("Location", text: $location)
                TextField("Notes", text: $notes, axis: .vertical)
                Stepper("Rating: \(rating)", value: $rating, in: 1...5)
            }
            .navigationTitle("Edit Observation")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let updated = Observation(
                            id: observation.id,
                            date: date,
                            starId: observation.starId,
                            starName: starName,
                            constellationId: observation.constellationId,
                            constellationName: constellationName,
                            location: location.isEmpty ? nil : location,
                            equipment: observation.equipment,
                            conditions: observation.conditions,
                            notes: notes.isEmpty ? nil : notes,
                            rating: rating,
                            isFavorite: observation.isFavorite
                        )
                        viewModel.updateObservation(updated)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EditEventView: View {
    @ObservedObject var viewModel: StarMapViewModel
    @Environment(\.dismiss) private var dismiss
    let event: AstronomicalEvent

    @State private var name: String
    @State private var date: Date
    @State private var details: String
    @State private var notify: Bool

    init(viewModel: StarMapViewModel, event: AstronomicalEvent) {
        self.viewModel = viewModel
        self.event = event
        _name = State(initialValue: event.name)
        _date = State(initialValue: event.date)
        _details = State(initialValue: event.description)
        _notify = State(initialValue: event.isNotified)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                DatePicker("Date", selection: $date)
                TextField("Description", text: $details, axis: .vertical)
                Toggle("Enable reminder", isOn: $notify)
            }
            .navigationTitle("Edit Event")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        var updated = event
                        updated.name = name
                        updated.date = date
                        updated.description = details
                        updated.isNotified = notify
                        viewModel.updateEvent(updated)
                        dismiss()
                    }
                }
            }
        }
    }
}
