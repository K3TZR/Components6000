//
//  Authentication.swift
//  TestSmartlink/Wan
//
//  Created by Douglas Adams on 12/5/21.
//

import Foundation
import SwiftUI

import JWTDecode
import Shared

final class Authentication {
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _previousIdToken: IdToken?
  private let _tokenStore: TokenStore
  private var _smartlinkEmail: String?
  private var _smartlinkImage: Image?
  
  private let kDomain             = "https://frtest.auth0.com/"
  private let kClientId           = "4Y9fEIIsVYyQo5u6jr7yBWc4lV5ugC2m"
  private let kServiceName        = ".oauth-token"
  
  private let kApplicationJson    = "application/json"
  private let kAuth0Authenticate  = "https://frtest.auth0.com/oauth/ro"
  private let kAuth0Delegation    = "https://frtest.auth0.com/delegation"
  private let kClaimEmail         = "email"
  private let kClaimPicture       = "picture"
  private let kGrantType          = "password"
  private let kGrantTypeRefresh   = "urn:ietf:params:oauth:grant-type:jwt-bearer"
  private let kHttpHeaderField    = "content-type"
  private let kHttpPost           = "POST"
  private let kConnection         = "Username-Password-Authentication"
  private let kDevice             = "any"
  private let kScope              = "openid offline_access email picture"
  
  private let kKeyClientId        = "client_id"       // dictionary keys
  private let kKeyConnection      = "connection"
  private let kKeyDevice          = "device"
  private let kKeyGrantType       = "grant_type"
  private let kKeyIdToken         = "id_token"
  private let kKeyPassword        = "password"
  private let kKeyRefreshToken    = "refresh_token"
  private let kKeyScope           = "scope"
  private let kKeyTarget          = "target"
  private let kKeyUserName        = "username"
  
  private let kDefaultPicture     = "person.fill"
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  init() {
    let appName = (Bundle.main.infoDictionary!["CFBundleName"] as! String)
    _tokenStore = TokenStore(service: appName + kServiceName)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  func forceNewLogin(for smartlinkEmail: String) {
    _previousIdToken = nil
    // remove the Refresh Token from the KeyChain
    _ = _tokenStore.delete(account: smartlinkEmail)
  }
  
  /// Obtain an Id Token from previous credentials
  /// - Parameters:
  ///   - smartlinkEmail:       email address
  ///   - previousToken:        a token from an earlier exchange
  /// - Returns:                an Id Token (if any)
  func getValidIdToken(from previousToken: IdToken?, or smartlinkEmail: String?) -> IdToken? {
    // is there a saved Auth0 token which has not expired?
    if let previousToken = previousToken, isValid(previousToken) {
      // YES, use the saved token
      updateClaims(from: previousToken)
      return previousToken
      
    } else if smartlinkEmail != nil, let refreshToken = _tokenStore.get(account: smartlinkEmail) {
      // NO, can we get an ID Token using the Refresh Token?
      if let idToken = requestIdToken(from: refreshToken, smartlinkEmail: smartlinkEmail!), isValid(idToken) {
        // YES
        return idToken
        
      } else {
        // NO, the Keychain entry is no longer valid, delete it
        _ = _tokenStore.delete(account: smartlinkEmail)
      }
    }
    // unable to obtain an ID Token
    return nil
  }
  
  /// Given a UserId / Password, request an ID Token & Refresh Token
  /// - Parameters:
  ///   - user:       User name
  ///   - pwd:        User password
  /// - Returns:      an Id Token (if any)
  func requestTokens(for user: String, pwd: String) -> IdToken? {
    // build the request
    var request = URLRequest(url: URL(string: kAuth0Authenticate)!)
    request.httpMethod = kHttpPost
    request.addValue(kApplicationJson, forHTTPHeaderField: kHttpHeaderField)
    
    // add the body data & perform the request
    if let data = createTokensBodyData(for: user, pwd: pwd) {
      request.httpBody = data
      let result = performRequest(request, for: [kKeyIdToken, kKeyRefreshToken])
      
      // validate the Id Token
      if isValid(result[0]), let refreshToken = result[1] {
        // save the email & picture
        updateClaims(from: result[0])
        // save the Refresh Token
        _ = _tokenStore.set(account: _smartlinkEmail, data: refreshToken)
        // save Id Token
        _previousIdToken = result[0]
        return result[0]
      }
    }
    // invalid Id Token or request failure
    return nil
  }
  
  /// Given a Refresh Token, request an ID Token
  /// - Parameter refreshToken:     a Refresh Token
  /// - Returns:                    an Id Token (if any)
  func requestIdToken(from refreshToken: String, smartlinkEmail: String) -> IdToken? {
    // build the request
    var request = URLRequest(url: URL(string: kAuth0Delegation)!)
    request.httpMethod = kHttpPost
    request.addValue(kApplicationJson, forHTTPHeaderField: kHttpHeaderField)
    
    // add the body data & perform the request
    if let data = createRefreshTokenBodyData(for: refreshToken) {
      request.httpBody = data
      let result = performRequest(request, for: [kKeyIdToken, kKeyRefreshToken])
      
      // validate the Id Token
      if result.count > 0, isValid(result[0]) {
        // save the email & picture
        updateClaims(from: result[0])
        // save the Refresh Token
        _ = _tokenStore.set(account: smartlinkEmail, data: refreshToken)
        // save Id Token
        _previousIdToken = result[0]
        return result[0]
      }
    }
    // invalid Id Token or request failure
    return nil
  }
  
  /// Validate an Id Token
  /// - Parameter idToken:        the Id Token
  /// - Returns:                  true / false
  func isValid(_ idToken: IdToken?) -> Bool {
    if let token = idToken {
      if let jwt = try? decode(jwt: token) {
        let result = IDTokenValidation(issuer: kDomain, audience: kClientId).validate(jwt)
        if result == nil { return true }
      }
    }
    return false
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Perform a URL Request
  /// - Parameter urlRequest:     the Request
  /// - Returns:                  an Id Token (if any)
  private func performRequest(_ request: URLRequest, for keys: [String]) -> [String?] {
    // retrieve the data
    let (responseData, error) = URLSession.shared.synchronousDataTask(with: request)
    
    // guard that the data isn't empty and that no error occurred
    guard let data = responseData, error == nil else { return [String]() }
    
    return parseJson(data, for: keys)
  }
  
  /// Create the Body Data for obtaining an Id Token give a Refresh Token
  /// - Returns:                    the Data (if created)
  private func createRefreshTokenBodyData(for refreshToken: String) -> Data? {
    var dict = [String : String]()
    
    dict[kKeyClientId]      = kClientId
    dict[kKeyGrantType]     = kGrantTypeRefresh
    dict[kKeyRefreshToken]  = refreshToken
    dict[kKeyTarget]        = kClientId
    dict[kKeyScope]         = kScope
    
    return serialize(dict)
  }
  
  /// Create the Body Data for obtaining an Id Token given a User Id / Password
  /// - Returns:                    the Data (if created)
  private func createTokensBodyData(for user: String, pwd: String) -> Data? {
    var dict = [String : String]()
    
    dict[kKeyClientId]      = kClientId
    dict[kKeyConnection]    = kConnection
    dict[kKeyDevice]        = kDevice
    dict[kKeyGrantType]     = kGrantType
    dict[kKeyPassword]      = pwd
    dict[kKeyScope]         = kScope
    dict[kKeyUserName]      = user
    
    return serialize(dict)
  }
  
  /// Convert a Data to a JSON dictionary and return the values of the specified keys
  /// - Parameters:
  ///   - data:       the Data
  ///   - keys:       an array of keys
  /// - Returns:      an array of values (some may be nil)
  private func parseJson(_ data: Data, for keys: [String]) -> [String?] {
    var values = [String?]()
    
    // convert data to a dict
    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
      // get the value for each key (some may be nil)
      for key in keys {
        values.append(json[key] as? String)
      }
    }
    return values
  }
  
  /// Convert a JSON dictionary to a Data
  /// - Parameter dict:   the dictionary
  /// - Returns:          a Data
  private func serialize(_ dict: Dictionary<String,String>) -> Data? {
    // try to serialize the data
    return try? JSONSerialization.data(withJSONObject: dict)
  }
  
  /// Update the Smartlink picture and email
  /// - Parameter idToken:    the Id Token
  private func updateClaims(from idToken: IdToken?) {
    if let idToken = idToken, let jwt = try? decode(jwt: idToken) {
      _smartlinkImage = getImage(jwt.claim(name: kClaimPicture).string)
      _smartlinkEmail = jwt.claim(name: kClaimEmail).string ?? ""
    }
  }
  
  /// Given a claim, retrieve the gravatar image
  /// - Parameter claimString:    a "picture" claim string
  /// - Returns:                  the image
  private func getImage(_ claimString: String?) -> Image {
    if let urlString = claimString, let url = URL(string: urlString) {
      if let data = try? Data(contentsOf: url), let theImage = NSImage(data: data) {
        return Image(nsImage: theImage)
      }
    }
    return Image( systemName: kDefaultPicture)
  }
}

// ----------------------------------------------------------------------------

extension URLSession {
  func synchronousDataTask(with urlRequest: URLRequest, timeout: DispatchTimeInterval = .seconds(10)) -> (Data?, Error?) {
    var data: Data?
    var error: Error?
    
    let semaphore = DispatchSemaphore(value: 0)
    
    let dataTask = self.dataTask(with: urlRequest) {
      data = $0
      error = $2
      semaphore.signal()
    }
    dataTask.resume()
    // timeout the request
    _ = semaphore.wait(timeout: .now() + timeout)
    return (data, error)
  }
}
