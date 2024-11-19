//
//  SearchAds.swift
//  sam
//
//  Created by Evgeny Cherpak on 01/03/2023.
//


#warning("!!! Add updatable feilds of campaign / ad group / keyword to their hasbale / equabtable !!!")
import Foundation

/*
 {
   "access_token": "eyJhbGciOiJkaXIiLCJlbmMiOiJBMjU2R0NNIiwia2lkIjpudWxsfQ  ..lXm332TFi0u2E9YZ.bVVBvsjcavoQbBnQVeDiqEzmUIlaH9zLKY6rl36A_TD8wvgvWxp  yBXMQuhs-qWG_dxQ5nfuJEIxOp8bIndfLE_4a3AiYtW0BsppO3vkWxMe0HWnzglkFbKUHU  3PaJbLHpimmnLvQr44wUAeNcv1LmUPaSWT4pfaBzv3dMe3PNHJJCLVLfzNlWTmPxViIivQ  t3xyiQ9laBO6qIQiKs9zX7KE3holGpJ-Wvo39U6ZmGs7uK9BoNBPaFtd_q914mb9ChHAKc  QaxF3Gadtu_Z5rYFg.vD0iQuRwHGYVnDy27qexCw",
   "token_type": "Bearer",
   "expires_in": 3600,
   "scope": "searchadsorg"
 }
*/

enum SearchAdsError: Error {
    case noClientId
    case noClientSecret
    case noOrgId
    case invalidClient
    case noToken
    case serverError
    
    case invalidURL
    case noData
}

struct TokenResponse: Codable {
    var access_token: String?
    var token_type: String?
    var expires_in: Int?
    var error: String?
}

enum MessageCode: String, RawRepresentable, Codable {
    case invalid_client = "invalid_client"
    case unauthorized = "UNAUTHORIZED"
    case default_bid_amount_exceeds_daily_cap = "DEFAULT_BID_AMOUNT_EXCEEDS_DAILY_CAP"
    case forbidden = "FORBIDDEN"
}

struct ErrorMessage: Codable {
    var messageCode: MessageCode
    var message: String?
    var field: String?
}

struct Errors: Codable {
    var errors: [ErrorMessage]
}

struct ResponseWrapper<T:Codable>: Codable {
    var data: T?
    var error: Errors?
    // pagination?
}

struct Empty: Codable {
    
}

/*
 {
   "data": [
     {
       "orgName": "d314127481",
       "orgId": 5610,
       "currency": "USD",
       "timeZone": "Asia/Jerusalem",
       "paymentModel": "PAYG",
       "roleNames": [
         "API Campaign Manager"
       ],
       "parentOrgId": null,
       "displayName": "Evgeny Cherpak"
     }
   ],
   "pagination": null,
   "error": null
 }
 */
struct ACLS: Codable {
    var orgName: String
    var orgId: Int64
    var currency: String
    var timeZone: String
    var parentOrgId: Int64?
    var displayName: String
}

extension ACLS: Equatable, Hashable {
    
}

struct Money: Codable, Equatable, Hashable {
    var amount: String
    var currency: String
}

enum Status: String, RawRepresentable, Codable {
    case enabled = "ENABLED"
    case paused = "PAUSED"
    case active = "ACTIVE"
}

struct Campaign: Codable {
    var adamId: Int64
    var adChannelType: String
    var billingEvent: String // IMPRESSIONS, TAPS
    var budgetAmount: Money?
    var countriesOrRegions: [String]
    var dailyBudgetAmount: Money?
    var deleted: Bool
    var displayStatus: String // DELETED, ON_HOLD, PAUSED, RUNNING
    var id: Int64
    var name: String
    var orgId: Int64
    var paymentModel: String // LOC, PAYG
    var servingStatus: String // RUNNING, NOT_RUNNING
    var status: Status
}

extension Campaign: Hashable, Equatable {
    static func == (lhs: Campaign, rhs: Campaign) -> Bool {
        lhs.id == rhs.id &&
        lhs.status == rhs.status &&
        lhs.name == rhs.name &&
        lhs.budgetAmount == rhs.budgetAmount
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        hasher.combine(self.status)
        hasher.combine(self.name)
    }
}

struct AdGroup: Codable {
    var automatedKeywordsOptIn: Bool
    var campaignId: Int64
    var cpaGoal: Money?
    var defaultBidAmount: Money
    var deleted: Bool?
    var displayStatus: String?
    var id: Int64?
    var name: String
    var orgId: Int64
    var paymentModel: String?
    var pricingModel: String
    var servingStateReasons: [String]?
    var servingStatus: String?
    var status: Status
    var startTime: String?
    var endTime: String?
}

extension AdGroup: Hashable, Equatable {
    static func == (lhs: AdGroup, rhs: AdGroup) -> Bool {
        lhs.id == rhs.id &&
        lhs.status == rhs.status &&
        lhs.name == rhs.name &&
        lhs.cpaGoal == rhs.cpaGoal &&
        lhs.defaultBidAmount == rhs.defaultBidAmount
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        hasher.combine(self.status)
        hasher.combine(self.name)
    }
}

enum MatchType: String, RawRepresentable, Codable {
    case broad = "BROAD"
    case exact = "EXACT"
}

struct Keyword: Codable {
    var adGroupId: Int64
    var bidAmount: Money
    var deleted: Bool?
    var id: Int64?
    var matchType: MatchType // BROAD, EXACT
    var status: Status?
    var text: String
}

extension Keyword: Equatable, Hashable {
    static func == (lhs: Keyword, rhs: Keyword) -> Bool {
        lhs.id == rhs.id &&
        lhs.status == rhs.status &&
        lhs.bidAmount == rhs.bidAmount
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        hasher.combine(self.status)
    }
}

struct CampaignUpdate: Codable {
    var budgetAmount: Money?
    var budgetOrders: Int64?
    var countriesOrRegions: [String]?
    var dailyBudgetAmount: Money?
    var name: String?
    var status: Status? // ENABLED, PAUSED
}

struct UpdateCampaignRequest: Codable {
    var campaign: CampaignUpdate
    var clearGeoTargetingOnCountryOrRegionChange: Bool
}

struct CountryOrRegion: Codable, Equatable {
    var countryOrRegion: String
}

extension CountryOrRegion: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(countryOrRegion)
    }
}

extension CountryOrRegion {
    func displayName() -> String {
        return (Locale.current as NSLocale).localizedString(forCountryCode: self.countryOrRegion) ?? "Unknown"
    }
}

enum ReportGranularity: String, RawRepresentable, Codable {
    case hourly = "HOURLY"
    case daily = "DAILY"
    case weekly = "WEEKLY"
    case monthly = "MONTHLY"
}

enum ReportGroupBy: String, RawRepresentable, Codable {
    case adminArea, ageRange, countryCode, countryOrRegion, deviceClass, gender, locality
}

enum ReportTimeZone: String, RawRepresentable, Codable {
    case ortz = "ORTZ"
    case utc = "UTC"
}

struct ReportingRequest: Codable {
    var startTime: String // YYYY-MM-DD
    var endTime: String // YYYY-MM-DD
    var selector: ReportSelector
    var granularity: ReportGranularity?
    var groupBy: [ReportGroupBy]?
    var returnGrandTotals: Bool?
    var returnRecordsWithNoMetrics: Bool?
    var returnRowTotals: Bool?
    var timeZone: ReportTimeZone?
}

struct Pagination: Codable {
    var offset: Int
    var limit: Int
}

enum Fields: String, Codable {
    case id = "id"
    case deleted = "deleted"
    case campaignId = "campaignId"
    case adGroupId = "adGroupId"
    case keywordId = "keywordId"
    case countryOrRegion = "countryOrRegion"
    case deviceClass = "deviceClass"
}

enum SortOrder: String, Codable {
    case ascending = "ASCENDING"
    case descending = "DESCENDING"
}

struct OrderBy: Codable {
    var field: Fields
    var sortOrder: SortOrder
}

struct ReportSelector: Codable {
    var conditions: [Condition]
    var orderBy: [OrderBy]
    var pagination: Pagination
}

enum Operator: String, RawRepresentable, Codable {
    case between = "BETWEEN"
    case contains = "CONTAINS"
    case contains_all = "CONTAINS_ALL"
    case contains_any = "CONTAINS_ANY"
    case endswith = "ENDSWITH"
    case equals = "EQUALS"
    case greater_than = "GREATER_THAN"
    case inRange = "IN"
    case less_than = "LESS_THAN"
    case like = "LIKE"
    case startswith = "STARTSWITH"
}

struct Condition: Codable {
    var field: Fields
    var op: Operator
    var values: [String]
    private enum CodingKeys : String, CodingKey {
        case field, op = "operator", values
    }
}

struct FindSelector: Codable {
    var conditions: [Condition]
    var fields: [Fields]
    var orderBy: [OrderBy]
    var pagination: Pagination
}

struct SpendRow: Codable {
//    var avgCPA: Money
    var avgCPT: Money
    var avgCPM: Money?
    var localSpend: Money
    var impressions: Int
    var totalInstalls: Int
//    var latOffInstalls: Int
//    var latOnInstalls: Int
    var totalNewDownloads: Int
//    var redownloads: Int
    var taps: Int
//    var conversionRate: Float
    var ttr: Float
}

struct GrandTotalsRow: Codable {
    var other: Bool
    var total: SpendRow
}

struct ReportingDataResponse: Codable {
    var reportingDataResponse: ReportResponse
}

struct RowMetadata: Codable {
    var campaignId: Int64?
    var campaignName: String?
    var campaignStatus: Status?
    var countriesOrRegions: [String]?
    var dailyBudget: Money?
    
    var adGroupId: Int64?
    var adGroupName: String?
    var adGroupStatus: Status?
    var defaultBidAmount: Money?
//    var cpaGoal: Money?
    
    var keywordId: Int64?
    var keyword: String?
    var keywordStatus: Status?
    var bidAmount: Money?
    var avgCPT: Money?
    var matchType: MatchType?
}

struct ReportRow: Codable {
    var other: Bool
    var total: SpendRow
    var metadata: RowMetadata
}

struct ReportResponse: Codable {
    var row: [ReportRow]
    var grandTotals: GrandTotalsRow?
}

extension ReportRow: Equatable {
    
}

extension RowMetadata: Equatable {
    
}

extension ReportResponse: Equatable {
    static func == (lhs: ReportResponse, rhs: ReportResponse) -> Bool {
        lhs.row == rhs.row && lhs.grandTotals == rhs.grandTotals
    }
}

extension GrandTotalsRow: Equatable {
    static func == (lhs: GrandTotalsRow, rhs: GrandTotalsRow) -> Bool {
        lhs.total == rhs.total
    }
}

extension SpendRow: Equatable {
    
}

struct AdGroupUpdate: Codable {
    var automatedKeywordsOptIn: Bool?
    @NullEncodable var cpaGoal: Money?
    var defaultBidAmount: Money?
    var name: String?
    var status: Status? // ENABLED, PAUSED
}

struct KeywordUpdateObject {
    var keyword: Keyword
    var update: KeywordUpdate
}

struct KeywordUpdate: Codable {
    var id: Int64
    var bidAmount: Money?
    var status: Status? // ACTIVE, PAUSED
}

class SearchAds: ObservableObject {
    
    static let instance = SearchAds()
    
    init() {
        clientId = UserDefaults.standard.clientId
        clientSecret = UserDefaults.standard.clientSecret
    }
    
    var onError: ((ErrorMessage) -> Void)? = nil
    var onResponse: (() -> Void)? = nil
    
    var clientId: String? = nil
    var clientSecret: String? = nil
    
    @Published var token: String? = nil
    
    private func requestToken() async throws -> Result<String, Error> {
        guard let clientId else { return .failure(SearchAdsError.noClientId) }
        guard let clientSecret else { return .failure(SearchAdsError.noClientSecret) }
        if let token {
            return .success(token)
        }
        var builder = URLComponents()
        builder.scheme = "https"
        builder.host = "appleid.apple.com"
        builder.path = "/auth/oauth2/token"
        builder.queryItems = [
            .init(name: "grant_type", value: "client_credentials"),
            .init(name: "scope", value: "searchadsorg"),
            .init(name: "client_id", value: clientId),
            .init(name: "client_secret", value: clientSecret)
        ]
        guard let url = builder.url else {
            return .failure(SearchAdsError.invalidURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("appleid.apple.com", forHTTPHeaderField: "Host")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        debugPrint(" DATA for \(request) \(request.allHTTPHeaderFields?.debugDescription): \(String(data: data, encoding: .utf8)!)")
        
        do {
            let tr = try JSONDecoder().decode(TokenResponse.self, from: data)
            if let error = tr.error {
                var result: Error? = nil
                switch error {
                case "invalid_client": result = SearchAdsError.invalidClient
                default:
                    break
                }
                onError?(ErrorMessage(messageCode: MessageCode(rawValue: error)!))
                return .failure(result ?? SearchAdsError.serverError)
            } else if let token = tr.access_token {
                self.token = token
                return .success(token)
            }
        }
        catch let error {
            debugPrint(error)
        }
        return .failure(SearchAdsError.serverError)
    }
    
    private func request<T: Codable>(
        method: String = "GET",
        host: String = "api.searchads.apple.com",
        version: String = "v5",
        api: String,
        orgId: Int64? = nil,
        limit: Int32? = nil,
        offset: Int32? = nil,
        body: Codable? = nil,
        type: T.Type
    ) async throws -> Result<T?, Error> {
        if orgId == nil && api != "acls" {
            return .failure(SearchAdsError.noOrgId)
        }
        return try await request(method: method, host: host, path: "/api/\(version)/\(api)", orgId: orgId, limit: limit, offset: offset, body: body, type: type)
    }
    
    private func request<T: Codable>(
        method: String = "GET",
        host: String = "api.searchads.apple.com",
        path: String,
        orgId: Int64? = nil,
        limit: Int32? = nil,
        offset: Int32? = nil,
        body: Codable? = nil,
        type: T.Type
    ) async throws -> Result<T?, Error> {
        let _ = try await requestToken()
        guard let token else { return .failure(SearchAdsError.noToken) }
        var builder = URLComponents()
        builder.scheme = "https"
        builder.host = host
        builder.path = path
        var queryItems = [URLQueryItem]()
        if let limit {
            queryItems.append(.init(name: "limit", value: "\(limit)"))
        }
        if let offset {
            queryItems.append(.init(name: "offset", value: "\(offset)"))
        }
        if queryItems.count > 0 {
            builder.queryItems = queryItems
        }
        guard let url = builder.url else {
            return .failure(SearchAdsError.invalidURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let orgId {
            request.setValue("orgId=\(orgId)", forHTTPHeaderField: "X-AP-Context")
        }
        if let body {
            request.httpBody = try? JSONEncoder().encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        debugPrint(" REQUEST: \(request)")
        if let body {
            debugPrint("   >>>> BODY: \(body)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            guard httpResponse.statusCode == 200 else {
                debugPrint("Failure with \(httpResponse.statusCode)")
                if httpResponse.statusCode == 401 {
                    self.token = nil
                    let result = try await self.request(
                        method: method,
                        path: path,
                        orgId: orgId,
                        limit: limit,
                        offset: offset,
                        body: body,
                        type: type
                    )
                    return result
                } else {
                    return .failure(SearchAdsError.serverError)
                }
            }
        }
        
        debugPrint(" DATA for \(request) \(request.allHTTPHeaderFields?.debugDescription): \(String(data: data, encoding: .utf8)!)")
        
        do {
            let obj = try JSONDecoder().decode(ResponseWrapper<T>.self, from: data)
            // check if we got an error
            // and try again if our token expired
            if let e = obj.error?.errors.first {
                if e.messageCode == .unauthorized /*, let _ = self.token*/ {
                    self.token = nil
                    debugPrint(" TOKEN: \(e.message ?? "")")
                    let result = try await self.request(
                        method: method,
                        path: path,
                        orgId: orgId,
                        limit: limit,
                        offset: offset,
                        body: body,
                        type: type
                    )
                    return result
                } else {
                    onError?(e)
                    return .failure(SearchAdsError.serverError)
                }
            } else {
                onResponse?()
                return .success(obj.data)
            }
        } catch let error {
            debugPrint(" PARSE ERROR: \(error) of \(String(data: data, encoding: .utf8))")
            return .failure(error)
        }
    }
    
    // MARK: -
    
    // GET https://api.searchads.apple.com/api/v4/acls
    func getACLS() async throws -> [ACLS]? {
        let response = try await request(api: "acls", type: [ACLS].self)
        let obj = try response.get()
        return obj
    }
    
    // GET https://api.searchads.apple.com/api/v4/campaigns
    func getCampaigns(orgId: Int64? = UserDefaults.standard.orgId) async throws -> [Campaign]? {
        let response = try await request(api: "campaigns",
                                         orgId: orgId,
                                         limit: 1000,
                                         offset: 0,
                                         type: [Campaign].self)
        let obj = try response.get()
        return obj
    }
    
    // GET https://api.searchads.apple.com/api/v4/campaigns/{campaignId}/adgroups
    func getAdGroups(
        campaign: Campaign
    ) async throws -> [AdGroup]? {
        let response = try await request(api: "campaigns/\(campaign.id)/adgroups",
                                         orgId: campaign.orgId,
                                         limit: 1000,
                                         offset: 0,
                                         type: [AdGroup].self)
        let obj = try response.get()
        return obj
    }
    
    // GET https://api.searchads.apple.com/api/v4/campaigns/{campaignId}/adgroups/{adgroupId}/targetingkeywords
    func getKeywords(
        adGroup: AdGroup
    ) async throws -> [Keyword]? {
        guard let id = adGroup.id else { return nil }
        let response = try await request(api: "campaigns/\(adGroup.campaignId)/adgroups/\(id)/targetingkeywords",
                                         orgId: adGroup.orgId,
                                         limit: 1000,
                                         offset: 0,
                                         type: [Keyword].self)
        let obj = try response.get()
        return obj
    }
    
    func getKeywords(
        campaign: Campaign
    ) async throws -> [Keyword]? {
        let response = try await request(
            method: "POST",
            api: "campaigns/\(campaign.id)/adgroups/targetingkeywords/find",
            orgId: campaign.orgId,
            body: FindSelector(
                conditions: [
                    Condition(
                        field: .deleted,
                        op: .equals,
                        values: ["false"]
                    )
                ],
                fields: [],
                orderBy: [OrderBy(field: .id, sortOrder: .ascending)],
                pagination: Pagination(offset: 0, limit: 1000)),
            type: [Keyword].self)
        let obj = try response.get()
        return obj
    }
    
    // PUT https://api.searchads.apple.com/api/v4/campaigns/{campaignId}
    func updateCampaign(
        campaign: Campaign,
        update: UpdateCampaignRequest
    ) async throws -> Campaign? {
        return try await updateCampaign(campaignId: campaign.id, update: update)
    }
    
    func updateCampaign(
        campaignId: Int64,
        update: UpdateCampaignRequest,
        orgId: Int64? = UserDefaults.standard.orgId
    ) async throws -> Campaign? {
        let response = try await request(
            method: "PUT",
            api: "campaigns/\(campaignId)",
            orgId: orgId,
            body: update,
            type: Campaign.self)
        let obj = try response.get()
        return obj
    }
    
    // DELETE https://api.searchads.apple.com/api/v4/campaigns/{campaignId}
    func deleteCampaign(
        campaign: Campaign
    ) async throws {
        let _ = try await request(
            method: "DELETE",
            api: "campaigns/\(campaign.id)",
            orgId: campaign.orgId,
            type: Empty.self)
    }
    
    // GET https://api.searchads.apple.com/api/v4/countries-or-regions
    func getSupportedCountries() async throws -> [CountryOrRegion]? {
        let response = try await request(
            method: "GET",
            api: "countries-or-regions",
            orgId: UserDefaults.standard.orgId,
            type: [CountryOrRegion].self)
        let obj = try response.get()
        return obj
    }
    
    // POST https://api.searchads.apple.com/api/v4/reports/campaigns
    func getCampaignReport(
        report: ReportingRequest,
        orgId: Int64? = UserDefaults.standard.orgId
    ) async throws -> ReportingDataResponse? {
        let response = try await request(
            method: "POST",
            api: "reports/campaigns",
            orgId: orgId,
            body: report,
            type: ReportingDataResponse.self)
        let obj = try response.get()
        return obj
    }
    
    // POST https://api.searchads.apple.com/api/v4/reports/campaigns/{campaignId}/adgroups
    func getAdGroupReport(
        campaign: Campaign,
        report: ReportingRequest,
        orgId: Int64? = UserDefaults.standard.orgId
    ) async throws -> ReportingDataResponse? {
        return try await getAdGroupReport(campaignId: campaign.id, report: report)
    }
    
    func getAdGroupReport(
        campaignId: Int64,
        report: ReportingRequest,
        orgId: Int64? = UserDefaults.standard.orgId
    ) async throws -> ReportingDataResponse? {
        let response = try await request(
            method: "POST",
            api: "reports/campaigns/\(campaignId)/adgroups",
            orgId: orgId,
            body: report,
            type: ReportingDataResponse.self)
        let obj = try response.get()
        return obj
    }
    
    // PUT https://api.searchads.apple.com/api/v4/campaigns/{campaignId}/adgroups/{adgroupId}
    func updateAdGroup(
        adGroup: AdGroup,
        update: AdGroupUpdate
    ) async throws -> AdGroup? {
        guard let id = adGroup.id else { return nil }
        return try await updateAdGroup(campaignId: adGroup.campaignId, adGroupId: id, update: update)
    }
    
    func updateAdGroup(
        campaignId: Int64,
        adGroupId: Int64,
        update: AdGroupUpdate,
        orgId: Int64? = UserDefaults.standard.orgId
    ) async throws -> AdGroup? {
        let response = try await request(
            method: "PUT",
            api: "campaigns/\(campaignId)/adgroups/\(adGroupId)",
            orgId: orgId,
            body: update,
            type: AdGroup.self)
        let obj = try response.get()
        return obj
    }
    
    // DELETE https://api.searchads.apple.com/api/v4/campaigns/{campaignId}/adgroups/{adgroupId}
    func deleteAdGroup(
        adGroup: AdGroup
    ) async throws {
        guard let id = adGroup.id else { return }
        let _ = try await request(
            method: "DELETE",
            api: "campaigns/\(adGroup.campaignId)/adgroups/\(id)",
            orgId: adGroup.orgId,
            type: Empty.self)
    }

    // POST https://api.searchads.apple.com/api/v4/reports/campaigns/{campaignId}/adgroups/{adgroupId}/keywords
    func getKeywordsReport(
        adGroup: AdGroup,
        report: ReportingRequest
    ) async throws -> ReportingDataResponse? {
        guard let id = adGroup.id else { return nil }
        return try await getKeywordsReport(campaignId: adGroup.campaignId, adGroupId: id, report: report)
    }
    
    func getKeywordsReport(
        campaignId: Int64,
        adGroupId: Int64? = nil,
        report: ReportingRequest,
        orgId: Int64? = UserDefaults.standard.orgId
    ) async throws -> ReportingDataResponse? {
        var path: String? = nil
        if let adGroupId {
            path = "reports/campaigns/\(campaignId)/adgroups/\(adGroupId)/keywords"
        } else {
            path = "reports/campaigns/\(campaignId)/keywords"
        }
        guard let path else { return nil }
        let response = try await request(
            method: "POST",
            api: path,
            orgId: orgId,
            body: report,
            type: ReportingDataResponse.self)
        let obj = try response.get()
        return obj
    }
    
    // POST https://api.searchads.apple.com/api/v4/reports/campaigns/{campaignId}/keywords
    func getKeywordsReport(
        campaign: Campaign,
        report: ReportingRequest
    ) async throws -> ReportingDataResponse? {
        let response = try await request(
            method: "POST",
            api: "reports/campaigns/\(campaign.id)/keywords",
            orgId: campaign.orgId,
            body: report,
            type: ReportingDataResponse.self)
        let obj = try response.get()
        return obj
    }
    
    // PUT https://api.searchads.apple.com/api/v4/campaigns/{campaignId}/adgroups/{adgroupId}/targetingkeywords/bulk
    func updateKeywords(
        adGroup: AdGroup,
        updates: [KeywordUpdate]
    ) async throws -> [Keyword]? {
        guard let id = adGroup.id else { return nil }
        return try await updateKeywords(campaignId: adGroup.campaignId, adGroupId: id, updates: updates)
    }
    
    func updateKeywords(
        campaignId: Int64,
        adGroupId: Int64,
        updates: [KeywordUpdate],
        orgId: Int64? = UserDefaults.standard.orgId
    ) async throws -> [Keyword]? {
        let response = try await request(
            method: "PUT",
            api: "campaigns/\(campaignId)/adgroups/\(adGroupId)/targetingkeywords/bulk",
            orgId: orgId,
            body: updates,
            type: [Keyword].self)
        let obj = try response.get()
        return obj ?? [Keyword]()
    }
    
    func updateKeywords(
        orgId: Int64,
        adGroups: [AdGroup],
        updates: [KeywordUpdateObject]
    ) async throws -> [Keyword]? {
        var result = [Keyword]()
        
        let adGroupIds = Set(updates.compactMap { $0.keyword.adGroupId })
        for adGroupId in adGroupIds {
            if let adGroup = adGroups.filter({ $0.id == adGroupId }).first {
                let adGroupUpdates = updates.filter({ $0.keyword.adGroupId == adGroupId }).compactMap({ $0.update })
                guard let id = adGroup.id else { return nil }
                let response = try await request(
                    method: "PUT",
                    api: "campaigns/\(adGroup.campaignId)/adgroups/\(id)/targetingkeywords/bulk",
                    orgId: adGroup.orgId,
                    body: adGroupUpdates,
                    type: [Keyword].self)
                if let obj = try response.get() {
                    result.append(contentsOf: obj)
                }
            }
        }
        
        return result
    }
    
    /*
     KeywordUpdateRequest
     Targeting keyword parameters to use in requests and responses.
     Search Ads 2.0.9+
     Properties
     adGroupId
     int64
     The unique identifier for the ad group that the targeting keyword belongs to.
     bidAmount
     Money
     The maximum cost-per-tap/impression bid amount. This is the offer price for a keyword in a bidding auction. If the bidAmount field is null, the bidAmount uses the defaultBidAmount of the corresponding ad group.
     If you set automatedKeywordsOptIn=true in Update an Ad Group, the bid uses optimized keywords with the defaultBidAmount.
     deleted
     boolean
     (Read only) An indicator of whether the keyword is soft-deleted.
     Default: false
     id
     int64
     (Read only) A unique identifier for the targeting keyword in the payload to update keyword bids or statuses. This keywordId is specific to a particular ad group and match type that you use to update bid amounts.
     matchType
     string
     (Required) An automated keyword and bidding strategy. Match type can be either Broad or Exact. See Ad Groups for Search Match use cases.
     Value    Description
     Broad    Use this value to ensure your ads don’t run on relevant, close variants of a keyword, such as singulars, plurals, misspellings, synonyms, related searches, and phrases that include that term (fully or partially).
     Exact    Use this value for the most control over searches your ad may appear in. You can target a specific term and its close variants, such as common misspellings and plurals. Your ad may receive fewer impressions as a result, but your tap-through rates (TTRs) and conversions on those impressions may be higher because you’re reaching users most interested in your app.
     Default: BROAD
     Possible values: BROAD, EXACT
     modificationTime
     date-time
     (Read only) The date and time of the most recent modification of the object.
     status
     string
     The user-controlled status to enable or pause the keyword.
     Possible values: ACTIVE, PAUSED
     text
     string
     (Required) The word or phrase to match in App Store user searches to show your ad.

     */
    
    
    // POST https://api.searchads.apple.com/api/v4/campaigns/{campaignId}/adgroups/{adgroupId}/targetingkeywords/delete/bulk
    func deleteKeywords(
        adGroups: [AdGroup],
        keywords: [Keyword]
    ) async throws {
        for adGroup in adGroups {
            let adGroupKeywords = keywords.filter { $0.adGroupId == adGroup.id }
            if adGroupKeywords.count > 0 {
                guard let id = adGroup.id else { return }
                let _ = try await request(
                    method: "POST",
                    api: "campaigns/\(adGroup.campaignId)/adgroups/\(id)/targetingkeywords/delete/bulk",
                    orgId: adGroup.orgId,
                    body: adGroupKeywords.compactMap({ $0.id }),
                    type: Empty.self)
            }
        }
    }
    
    // POST https://api.searchads.apple.com/api/v4/campaigns/{campaignId}/adgroups/{adgroupId}/targetingkeywords/bulk
    func addKeywords(
        adGroup: AdGroup,
        keywords: [Keyword]
    ) async throws -> [Keyword]? {
        guard let id = adGroup.id else { return nil }
        return try await request(
            method: "POST",
            api: "campaigns/\(adGroup.campaignId)/adgroups/\(id)/targetingkeywords/bulk",
            orgId: adGroup.orgId,
            body: keywords,
            type: [Keyword].self).get()
    }
    
    // POST https://api.searchads.apple.com/api/v4/campaigns/{campaignId}/adgroups
    func createAdGroup(
        campaign: Campaign,
        adGroup: AdGroup
    ) async throws -> AdGroup? {
        return try await createAdGroup(campaignId: campaign.id, adGroup: adGroup)
        
    }
    
    func createAdGroup(
        campaignId: Int64,
        adGroup: AdGroup,
        orgId: Int64? = UserDefaults.standard.orgId
    ) async throws -> AdGroup? {
        return try await request(
            method: "POST",
            api: "campaigns/\(campaignId)/adgroups",
            orgId: orgId,
            body: adGroup,
            type: AdGroup.self).get()
    }
    
}
