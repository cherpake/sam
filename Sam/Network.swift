//
//  Network.swift
//  sam
//
//  Created by Evgeny Cherpak on 03/08/2020.
//

import Foundation
import Security

extension Notification.Name {
    static let backgroundRefreshTodayData = Notification.Name("SAM.backgroundRefreshTodayData")
}

class Network: NSObject {
    
    static let instance = Network()
    
    var connectionIdentity: SecIdentity?
    
    private var session: URLSession?
    private var dataEncoder = JSONEncoder()
    private var dataDecoder = JSONDecoder()
    
    typealias FieldId = String
    
    enum RoleNamesData: String, Codable {
        case Admin = "Admin"
        case ReadOnly = "Account Read Only"
    }
    
    struct ACLSResponseData: Codable {
        var orgName: String
        var orgId: Int
        var currency: String
        var timeZone: String
        var paymentModel: String
        var roleNames: [RoleNamesData]
        var pagination: PaginationResponseData?
    }
    
    enum FieldsData: String, Codable {
        case countryOrRegion = "countryOrRegion"
        case deviceClass = "deviceClass"
    }
    
    enum TimeZoneData: String, Codable {
        case UTC = "UTC"
        case ORTZ = "ORTZ"
    }
    
    enum SortOrderData: String, Codable {
        case ascending = "ASCENDING"
    }
    
    struct PaginationData: Codable {
        var offset: Int = 0
        var limit: Int = 1000
    }
    
    struct OrderByData: Codable {
        var field: FieldsData
        var sortOrder: SortOrderData
    }
    
    struct SelectorData: Codable {
        var orderBy: [OrderByData]
        var pagination: PaginationData
    }
    
    struct CampaignsReportRequestData: Codable {
        var startTime: String
        var endTime: String
        var selector: SelectorData
        var groupBy: [FieldsData] // fields
        var timeZone: TimeZoneData
        var returnRecordsWithNoMetrics: Bool
        var returnRowTotals: Bool
        var returnGrandTotals: Bool
    }
    
    struct PaginationResponseData: Codable {
        var totalResults: Int
        var startIndex: Int
        var itemsPerPage: Int
    }
    
    struct ResponseDataWrapper<T: Codable>: Codable {
        var data: T
        var pagination: PaginationResponseData?
    }
    
    struct AmountData: Codable {
        var amount: String
        var currency: String
    }
    
    struct TotalDataResponse: Codable {
        var avgCPA: AmountData
        var avgCPT: AmountData
        var localSpend: AmountData
        var impressions: Int
        var installs: Int
        var latOffInstalls: Int
        var latOnInstalls: Int
        var newDownloads: Int
        var redownloads: Int
        var taps: Int
        var conversionRate: Float
        var ttr: Float
    }
        
    struct TotalsData: Codable {
        var other: Bool
        var total: TotalDataResponse
    }

    struct ReportingDataResponseWrapper: Codable {
        var reportingDataResponse: ReportingDataResponse
    }
    
    struct ReportingDataResponse: Codable {
        var grandTotals: TotalsData
        
        var toJSONRepresentation: Data? {
            return try? Network.instance.dataEncoder.encode(self)
        }
        
        static func fromJSONRepresentation(json data: Data) -> ReportingDataResponse? {
            return try? Network.instance.dataDecoder.decode(ReportingDataResponse.self, from: data)
        }
    }
    
    // MARK: -
    
//    #if DEBUG
//    public var orgId: Int? = 5610
//    #else
    public var orgId: Int?
//    #endif
    
    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true
        session = URLSession(configuration: URLSessionConfiguration.default,
                             delegate: self,
                             delegateQueue: OperationQueue.main)
    }
     
    func request(method: String, path: String, body: Data? = nil, completionHandler: @escaping (Data?, Error?) -> Void) {
        let url = URL(string: path)!
        var r = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30.0)
        r.httpMethod = method
        r.httpBody = body
        r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let orgId = self.orgId {
            r.setValue("orgId=\(orgId)", forHTTPHeaderField: "Authorization")
        }
        debugPrint("Request", String(data: r.httpBody ?? Data(), encoding: .utf8)! as Any)
        debugPrint("Request: \(String(describing: r.allHTTPHeaderFields))")
        session?.dataTask(with: r, completionHandler: { (data, response, error) in
            guard let data = data else { return }
            debugPrint(String(data: data, encoding: .utf8)! as Any)
            completionHandler(data, error)
        }).resume()
    }
    
    func getACLS(completionHandler: @escaping ([ACLSResponseData], Error?) -> Void) {
        request(method: "GET", path: "https://api.searchads.apple.com/api/v3/acls") { (data, error) in
            var acls = [ACLSResponseData]()
            defer {
                completionHandler(acls, error)
            }
            guard let data = data else { return }
            guard let response = try? self.dataDecoder.decode(ResponseDataWrapper<[ACLSResponseData]>.self, from: data) else { return }
            acls = response.data
        }
    }
    
    func getCampaignsReport(start: Date = Date(),
                            end: Date = Date(),
                            timeZone: TimeZoneData = .ORTZ,
                            completionHandler: @escaping (ReportingDataResponse?, Error?) -> Void) {
        guard let _ = self.orgId else {
            #warning("Return error")
            debugPrint("Unable to fetch - missing orgId")
            completionHandler(nil, nil)
            return
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let crd = CampaignsReportRequestData(startTime: formatter.string(from: start),
                                             endTime: formatter.string(from: end),
                                             selector: SelectorData(orderBy: [OrderByData(field: .deviceClass, sortOrder: .ascending)],
                                                                    pagination: PaginationData(offset: 0, limit: 1000)),
                                             groupBy: [.deviceClass],
                                             timeZone: timeZone,
                                             returnRecordsWithNoMetrics: true,
                                             returnRowTotals: true,
                                             returnGrandTotals: true)
        do {
            let data = try dataEncoder.encode(crd)
            request(method: "POST", path: "https://api.searchads.apple.com/api/v3/reports/campaigns", body: data) { (data, error) in
                var report: ReportingDataResponse? = nil
                defer {
                    completionHandler(report, error)
                }
                guard let data = data else { return }
                guard let response = try? self.dataDecoder.decode(ResponseDataWrapper<ReportingDataResponseWrapper>.self, from: data) else { return }
                report = response.data.reportingDataResponse
            }
        } catch let error {
            completionHandler(nil, error)
        }
    }
    
}

extension Network: URLSessionDelegate {
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        switch (challenge.protectionSpace.authenticationMethod, challenge.protectionSpace.host) {
        case (NSURLAuthenticationMethodClientCertificate, "api.searchads.apple.com"):
            self.didReceive(clientIdentityChallenge: challenge, completionHandler: completionHandler)
        default:
            completionHandler(.performDefaultHandling, nil)
        }
    }
        
    func didReceive(clientIdentityChallenge challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let identity = self.connectionIdentity else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        completionHandler(.useCredential, URLCredential(identity: identity, certificates: nil, persistence: .forSession))
    }
    
}
