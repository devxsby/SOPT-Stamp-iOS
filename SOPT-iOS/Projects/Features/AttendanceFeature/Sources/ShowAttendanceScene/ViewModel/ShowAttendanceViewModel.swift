//
//  ShowAttendanceViewModel.swift
//  AttendanceFeature
//
//  Created by devxsby on 2023/04/11.
//  Copyright © 2023 SOPT-iOS. All rights reserved.
//

import Combine

import Core
import Domain
import Foundation

struct AttendanceButtonInfo {
    let title: String
    let isEnalbed: Bool
}

public final class ShowAttendanceViewModel: ViewModelType {

    // MARK: - Properties
    
    private let useCase: ShowAttendanceUseCase
    private var cancelBag = CancelBag()
    public var sceneType: AttendanceScheduleType?
    public var lectureRound: AttendanceRoundModel = .EMPTY
    
    // MARK: - Inputs
    
    public struct Input {
        let viewWillAppear: Driver<Void>
        let refreshStarted: Driver<Void>
    }
    
    // MARK: - Outputs
    
    public class Output {
        @Published var scheduleModel: AttendanceScheduleModel?
        @Published var scoreModel: AttendanceScoreModel?
        @Published var todayAttendances: [AttendanceStepModel]?
        @Published var takenAttendanceType: TakenAttendanceType?
        var attendanceButtonInfo = PassthroughSubject<AttendanceButtonInfo, Never>()
        var isLoading = PassthroughSubject<Bool, Never>()
    }
    
    // MARK: - init
  
    public init(useCase: ShowAttendanceUseCase) {
        self.useCase = useCase
    }
}

extension ShowAttendanceViewModel {
    
    public func transform(from input: Input, cancelBag: CancelBag) -> Output {
        let output = Output()
        
        self.bindOutput(output: output, cancelBag: cancelBag)
        
        input.viewWillAppear
            .withUnretained(self)
            .sink { owner, _ in
                output.isLoading.send(true)
                owner.useCase.fetchAttendanceSchedule()
                owner.useCase.fetchAttendanceScore()
            }
            .store(in: cancelBag)
        
        input.refreshStarted
            .withUnretained(self)
            .sink { owner, _ in
                owner.useCase.fetchAttendanceSchedule()
                owner.useCase.fetchAttendanceScore()
            }
        .store(in: self.cancelBag)
        
        return output
    }
  
    private func bindOutput(output: Output, cancelBag: CancelBag) {
        let fetchedSchedule = self.useCase.attendanceScheduleFetched
        let fetchedScore = self.useCase.attendanceScoreFetched
        let todayAttendances = self.useCase.todayAttendances
        let takenAttendanceType = self.useCase.takenAttendanceType
        let lectureRound = self.useCase.lectureRound
        let lectureRoundErrorTitle = self.useCase.lectureRoundErrorTitle
        
        fetchedSchedule.asDriver()
            .sink(receiveValue: { model in
                if model.type != SessionType.noSession.rawValue {
                    self.sceneType = .scheduledDay
                    
                    let convertedStartDate = self.convertDateString(model.startDate)
                    let convertedEndDate = self.convertDateString(model.endDate)

                    let newModel = AttendanceScheduleModel(type: model.type,
                                                           id: model.id,
                                                           location: model.location,
                                                           name: model.name,
                                                           startDate: convertedStartDate,
                                                           endDate: convertedEndDate,
                                                           message: model.message,
                                                           attendances: model.attendances)
                    output.scheduleModel = newModel
                } else {
                    self.sceneType = .unscheduledDay
                    output.scheduleModel = model
                    output.isLoading.send(false)
                }
            })
            .store(in: cancelBag)
        
        fetchedScore.asDriver()
            .sink(receiveValue: { model in
                output.scoreModel = model
            })
            .store(in: cancelBag)
        
        todayAttendances
            .sink { attendances in
                output.todayAttendances = attendances
            }
            .store(in: self.cancelBag)
        
        takenAttendanceType
            .sink { attendanceType in
                output.takenAttendanceType = attendanceType
            }
            .store(in: self.cancelBag)
        
        lectureRound
            .compactMap { $0 }
            .withUnretained(self)
            .sink { owner, lectureRound in
                if lectureRound == .EMPTY {
                    output.isLoading.send(false)
                    let buttonInfo = AttendanceButtonInfo(title: I18N.Attendance.takeNthAttendance(2), isEnalbed: false)
                    output.attendanceButtonInfo.send(buttonInfo)
                    return
                }
                owner.lectureRound = lectureRound
                let buttonInfo = AttendanceButtonInfo(title: I18N.Attendance.takeNthAttendance(lectureRound.round), isEnalbed: true)
                output.attendanceButtonInfo.send(buttonInfo)
                output.isLoading.send(false)
            }
            .store(in: self.cancelBag)
        
        lectureRoundErrorTitle
            .withUnretained(self)
            .sink { owner, title in
                let buttonInfo = AttendanceButtonInfo(title: title, isEnalbed: false)
                output.attendanceButtonInfo.send(buttonInfo)
                output.isLoading.send(false)
            }
            .store(in: self.cancelBag)
    }
    
    private func convertDateString(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        
        guard let date = dateFormatter.date(from: dateString) else { return "" }
        
        dateFormatter.dateFormat = "M월 d일 EEEE H:mm"
        return dateFormatter.string(from: date)
    }
    
    func formatTimeInterval(startDate: String, endDate: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M월 d일 EEEE HH:mm"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
    
        guard let startDateObject = dateFormatter.date(from: startDate),
              let endDateObject = dateFormatter.date(from: endDate) else { return "" }
        
        let formattedStartDate = dateFormatter.string(from: startDateObject)
        
        dateFormatter.dateFormat = "HH:mm"
        let formattedEndDate = dateFormatter.string(from: endDateObject)
        
        return "\(formattedStartDate) ~ \(formattedEndDate)"
    }
}
