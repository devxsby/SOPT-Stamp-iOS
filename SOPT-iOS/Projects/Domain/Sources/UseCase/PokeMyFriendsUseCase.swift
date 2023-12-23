//
//  PokeMyFriendsUseCase.swift
//  Domain
//
//  Created by sejin on 12/21/23.
//  Copyright © 2023 SOPT-iOS. All rights reserved.
//

import Combine

import Core

public protocol PokeMyFriendsUseCase {
    var myFriends: PassthroughSubject<PokeMyFriendsModel, Never> { get }
    var myFriendsList: PassthroughSubject<PokeMyFriendsListModel, Never> { get }
    var pokedResponse: PassthroughSubject<PokeUserModel, Never> { get }
    
    func getFriends()
    func getFriends(relation: String, page: Int)
    func poke(userId: Int, message: PokeMessageModel)
}

public class DefaultPokeMyFriendsUseCase {
    public var repository: PokeMyFriendsRepositoryInterface
    public let cancelBag = CancelBag()

    public let myFriends = PassthroughSubject<PokeMyFriendsModel, Never>()
    public let myFriendsList = PassthroughSubject<PokeMyFriendsListModel, Never>()
    public let pokedResponse = PassthroughSubject<PokeUserModel, Never>()
    
    public init(repository: PokeMyFriendsRepositoryInterface) {
        self.repository = repository
    }
}

extension DefaultPokeMyFriendsUseCase: PokeMyFriendsUseCase {
    public func getFriends() {
        repository.getFriends()
            .sink { event in
                print("GetFriendsList State: \(event)")
            } receiveValue: { [weak self] friends in
                self?.myFriends.send(friends)
            }.store(in: cancelBag)
    }
    
    public func getFriends(relation: String, page: Int) {
        repository.getFriends(relation: relation, page: page)
            .sink { event in
                print("GetFriendsListWithRelation State: \(event)")
            } receiveValue: { [weak self] friends in
                self?.myFriendsList.send(friends)
            }.store(in: cancelBag)
    }
    
    public func poke(userId: Int, message: PokeMessageModel) {
        self.repository
            .poke(userId: userId, message: message.content)
            .sink { event in
                print("Poke State: \(event)")
            } receiveValue: { [weak self] user in
                self?.pokedResponse.send(user)
            }.store(in: self.cancelBag)
    }
}
