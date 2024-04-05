//
//  ShowAttendanceRepository.swift
//  Data
//
//  Created by devxsby on 2023/04/11.
//  Copyright © 2023 SOPT-iOS. All rights reserved.
//

import Combine

import Core

import Domain
import Networks

public class ShowAttendanceRepository {
    
    private let attendanceService: AttendanceService
    private let cancelBag = CancelBag()
    
    public init(service: AttendanceService) {
        self.attendanceService = service
    }
}

extension ShowAttendanceRepository: ShowAttendanceRepositoryInterface {
    public func fetchAttendanceScheduleModel() -> AnyPublisher<AttendanceScheduleModel, Error> {
        return self.attendanceService.fetchAttendanceSchedule()
            .compactMap { $0.data?.toDomain() }
            .eraseToAnyPublisher()
    }
    
    public func fetchAttendanceScoreModel() -> AnyPublisher<Domain.AttendanceScoreModel, Error> {
        return self.attendanceService.fetchAttendanceScore()
            .compactMap{ $0.data?.toDomain() }
            .eraseToAnyPublisher()
    }
    
    public func fetchLectureRound(lectureId: Int) -> AnyPublisher<AttendanceRoundModel?, Error> {
        return self.attendanceService
            .fetchAttendanceRound(lectureId: lectureId)
            .map { $0.data?.toDomain() }
            .eraseToAnyPublisher()
    }
}

// 더미데이터

/*
extension ShowAttendanceRepository: ShowAttendanceRepositoryInterface {
    public func fetchAttendanceScheduleModel() -> AnyPublisher<AttendanceScheduleModel, Error> {
        return Future<AttendanceScheduleModel, Error> { promise in
            promise(.success(AttendanceScheduleModel(type: "HAS_ATTENDANCE", id: 0,
                                                     location: "솝트대학교 IT 창업관",
                                                     name: "3차 세미나",
                                                     startDate: "2023-04-29T14:00:00", endDate: "2023-04-29T18:00:00",
                                                     message: "",
                                                     attendances: [TodayAttendanceModel(status: "ATTENDANCE", attendedAt: "14:00")])))
        }.eraseToAnyPublisher()
    }
    
    public func fetchAttendanceScoreModel() -> AnyPublisher<Domain.AttendanceScoreModel, Error> {
        return Future<AttendanceScoreModel, Error> { promise in
            promise(.success(AttendanceScoreModel.init(part: "iOS",
                                                       generation: 33,
                                                       name: "윤수빈",
                                                       score: 1.0,
                                                       total: TotalScoreModel(attendance: 2, absent: 1, tardy: 1, participate: 1),
                                                       attendances: [AttendanceModel(attribute: "ETC", name: "솝커톤", status: "PARTICIPATE", date: "4월 22일"),
                                                                     AttendanceModel(attribute: "ETC", name: "1차 행사", status: "ATTENDANCE", date: "4월 15일"),
                                                                     AttendanceModel(attribute: "SEMINAR", name: "2차 세미나", status: "ATTENDANCE", date: "4월 08일"),
                                                                     AttendanceModel(attribute: "SEMINAR", name: "1차 세미나", status: "ABSENT", date: "4월 01일"),
                                                                     AttendanceModel(attribute: "ETC", name: "OT", status: "TARDY", date: "3월 25일")])))
        }.eraseToAnyPublisher()
    }
    
    public func fetchLectureRound(lectureId: Int) -> AnyPublisher<AttendanceRoundModel?, Error> {
        return Future<AttendanceRoundModel?, Error> { promise in
            promise(.success(AttendanceRoundModel.init(subLectureId: 0, round: 2)))
        }.eraseToAnyPublisher()
    }
}
*/
