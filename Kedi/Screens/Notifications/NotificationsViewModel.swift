//
//  NotificationsViewModel.swift
//  Kedi
//
//  Created by Saffet Emin Reisoğlu on 3/24/24.
//

import Foundation

final class NotificationsViewModel: ObservableObject {
    
    private let apiService = APIService.shared
    private let meManager = MeManager.shared
    
    private var projects: [Project] {
        meManager.projects ?? []
    }
    
    @Published private(set) var state: ViewState = .loading
    
    @Published private(set) var notificationSections: [NotificationSection] = .stub
    
    init() {
        Task {
            await fetchAllEvents()
        }
    }
    
    @MainActor
    private func fetchAllEvents() async {
        var notifications = await withTaskGroup(of: [NotificationItem].self) { group in
            projects.forEach { project in
                group.addTask { [weak self] in
                    await self?.fetchEvents(project: project) ?? []
                }
            }
            
            var allNotifications = [NotificationItem]()
            for await notifications in group {
                allNotifications.append(contentsOf: notifications)
            }
            return allNotifications
        }
        
        notifications.sort(by: { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) })
        
        let groupedNotifications = Dictionary(grouping: notifications) { notification in
            notification.date?.withoutTime
        }
        
        notificationSections = groupedNotifications
            .compactMap { date, notifications in
                guard let date else {
                    return nil
                }
                return .init(date: date, notifications: notifications)
            }
            .sorted(by: { $0.date > $1.date })
        
        state = notifications.isEmpty ? .empty : .data
    }
    
    private func fetchEvents(project: Project) async -> [NotificationItem]? {
        guard let webhookId = project.webhookId else {
            return nil
        }
        do {
            let data = try await apiService.request(
                .latestEvents(projectId: project.id, webhookId: webhookId)
            ) as RCLatestEventsResponse
            return data.events?.map { .init(data: $0, project: project) } ?? []
        } catch {
            return nil
        }
    }
    
    func refresh() async {
        await fetchAllEvents()
    }
}
