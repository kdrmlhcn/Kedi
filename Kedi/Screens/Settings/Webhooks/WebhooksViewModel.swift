//
//  WebhooksViewModel.swift
//  Kedi
//
//  Created by Saffet Emin Reisoğlu on 3/31/24.
//

import Foundation

final class WebhooksViewModel: ObservableObject {
    
    private let apiService = APIService.shared
    private let meManager = MeManager.shared
    
    @Published var webhooks = [WebhookItem]()
    @Published var errorAlert: Error?
    
    var id: String {
        meManager.id ?? ""
    }
    
    private var projects: [Project] {
        meManager.projects ?? []
    }
    
    init() {
        webhooks = projects.map { .init(state: .loading, project: $0) }
        Task {
            await fetchWebhooks()
        }
    }
    
    @MainActor
    private func fetchWebhooks() async {
        let states = await withTaskGroup(of: (String, WebhookState?).self) { group in
            projects.forEach { project in
                group.addTask { [weak self] in
                    (project.id, await self?.fetchWebhook(projectId: project.id))
                }
            }
            
            var states = [String: WebhookState]()
            for await (projectId, state) in group {
                states[projectId] = state
            }
            return states
        }
        
        webhooks = webhooks.compactMap { webhook in
            guard let state = states[webhook.project.id] else {
                return nil
            }
            return .init(state: state, project: webhook.project)
        }
        
        updateProjects()
    }
    
    private func fetchWebhook(projectId: String) async -> WebhookState {
        do {
            let webhooks = try await apiService.request(
                .webhooks(projectId: projectId)
            ) as RCWebhooksResponse
            
            if let webhookId = webhooks.first(where: { $0.url == "https://api.kediapp.com/webhook?id=\(id)" })?.id {
                return .active(webhookId: webhookId)
            } else {
                return .inactive
            }
        } catch {
            return .error(error)
        }
    }
    
    private func createWebhook(projectId: String) async -> WebhookState {
        do {
            let webhook = try await apiService.request(
                .createWebhook(
                    projectId: projectId,
                    request: .init(
                        name: "Kedi / \(DeviceUtility.modelId) / \(DeviceUtility.id)",
                        url: "https://api.kediapp.com/webhook?id=\(id)",
                        environment: "production"
                    )
                )
            ) as RCCreateWebhookResponse
            return .active(webhookId: webhook.id ?? "")
        } catch {
            return .error(error)
        }
    }
    
    private func updateWebhook(projectId: String, webhookId: String) async -> WebhookState {
        do {
            let _ = try await apiService.request(
                .updateWebhook(
                    projectId: projectId,
                    webhookId: webhookId,
                    request: .init(
                        name: "Kedi / \(DeviceUtility.modelId) / \(DeviceUtility.id)",
                        url: "https://api.kediapp.com/webhook?id=\(id)",
                        environment: "production"
                    )
                )
            ) as RCCreateWebhookResponse
            return .active(webhookId: webhookId)
        } catch {
            return .error(error)
        }
    }
    
    private func deleteWebhook(projectId: String, webhookId: String) async -> WebhookState {
        do {
            let _ = try await apiService.request(
                .deleteWebhook(projectId: projectId, webhookId: webhookId)
            ) as RCDeleteWebhookResponse
            return .inactive
        } catch {
            return .error(error)
        }
    }
    
    private func updateProjects() {
        var newProjects = projects
        webhooks.forEach { webhook in
            if let index = newProjects.firstIndex(where: { $0.id == webhook.project.id }) {
                switch webhook.state {
                case .active(let webhookId):
                    newProjects[index].webhookId = webhookId
                case .inactive:
                    newProjects[index].webhookId = nil
                case .loading,
                        .error:
                    break
                }
            }
        }
        meManager.set(projects: newProjects)
    }
    
    @MainActor
    func toggleWebhook(projectId: String) {
        guard let index = webhooks.firstIndex(where: { $0.project.id == projectId }),
              let webhook = webhooks[safe: index] else {
            return
        }
        
        switch webhook.state {
        case .active(let webhookId):
            Task {
                webhooks[index].state = .loading
                webhooks[index].state = await deleteWebhook(projectId: projectId, webhookId: webhookId)
            }
            
        case .inactive:
            Task {
                webhooks[index].state = .loading
                webhooks[index].state = await createWebhook(projectId: projectId)
            }
            
        case .loading,
                .error:
            return
        }
        
        updateProjects()
    }
    
    @MainActor
    func sendTestNotification(projectId: String, webhookId: String) async {
        do {
            let _ = try await apiService.request(
                .testWebhook(projectId: projectId, webhookId: webhookId)
            ) as RCTestWebhookResponse
        } catch {
            errorAlert = error
        }
    }
    
    @MainActor
    func resetWebhooks() async {
        meManager.generateId()
        
        let tempWebhooks = webhooks
        
        webhooks = webhooks.compactMap { webhook in
            guard case .active = webhook.state else {
                return nil
            }
            return .init(state: .loading, project: webhook.project)
        }
        
        let states = await withTaskGroup(of: (String, WebhookState?).self) { group in
            tempWebhooks.forEach { webhook in
                if case .active(let webhookId) = webhook.state {
                    group.addTask { [weak self] in
                        (webhook.project.id, await self?.updateWebhook(projectId: webhook.project.id, webhookId: webhookId))
                    }
                }
            }
            
            var states = [String: WebhookState]()
            for await (projectId, state) in group {
                states[projectId] = state
            }
            return states
        }
        
        webhooks = webhooks.compactMap { webhook in
            guard let state = states[webhook.project.id] else {
                return nil
            }
            return .init(state: state, project: webhook.project)
        }
        
        updateProjects()
    }
    
    @MainActor
    func refresh() async {
        webhooks = projects.map { .init(state: .loading, project: $0) }
        await fetchWebhooks()
    }
}
