//
//  ViewController.swift
//  DetectChanges
//
//  Created by Yuriy Gudimov on 10.03.2023.
//

import UIKit
import Combine

class ViewController: UIViewController, ModalVCDelegate {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    var timer: Timer?
    var modalVC: ModalVC?
    var modalVCIsPresented: Bool
    @Published var options: Options
    @Published var currentApartments: [Apartment]
    var apartmentsDataSource: [Apartment]
    var immomioLinkFetcher: ImmomioLinkFetcher
    var landlordsManager: LandlordsManager?
    var notificationsManager: NotificationsManager
    var isSecondRunPlus: Bool
    var loadingView: LoadingView?
    var modalVCView: ModalView?
    var backgroundAudioPlayer: BackgroundAudioPlayer?
    var bgAudioPlayerIsInterrupted: Bool
    
    private var cancellables: Set<AnyCancellable> = []
    
    required init?(coder aDecoder: NSCoder) {
        self.options = Options()
        self.immomioLinkFetcher = ImmomioLinkFetcher(networkManager: NetworkManager())
        self.currentApartments = [Apartment]()
        self.apartmentsDataSource = [Apartment]()
        self.notificationsManager = NotificationsManager()
        self.modalVCIsPresented = false
        self.isSecondRunPlus = false
        self.bgAudioPlayerIsInterrupted = false
        super.init(coder: aDecoder)
    }
    
    //MARK: - VC Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colour.brandDark.setColor
        notificationsManager.requestNotificationAuthorization()
        
        backgroundAudioPlayer = BackgroundAudioPlayer(for: self)
        backgroundAudioPlayer?.start()
        
        tableView.layer.cornerRadius = 10
        tableView.register(ApartmentCell.nib, forCellReuseIdentifier: ApartmentCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        
        setupModalVC()
        startEngine()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let modalVC = modalVC, !modalVCIsPresented {
            present(modalVC, animated: true)
            setPublishersToUpdateOptions(from: modalVC.modalView)
            setPublisherToUpdateApartmentsDataSource()
            modalVCIsPresented = true
        }
    }
    
    private func setupModalVC() {
        modalVC = ModalVC(smallDetentSize: calcModalVCDetentSizeSmall())
        modalVC?.presentationController?.delegate = self
        modalVC?.delegate = self
        modalVCView = modalVC?.view as? ModalView
    }
    
    //MARK: - ModalVCDelegate
    
    func startEngine() {
        landlordsManager = landlordsManager ?? LandlordsManager(immomioLinkFetcher: immomioLinkFetcher)
        guard let modalVCView = modalVCView else { fatalError("Unable to get modalVCView in startEngine") }
        modalVCView.containerView?.isHidden = true
        loadingView = LoadingView(frame: tableView.bounds)
        tableView.addSubview(loadingView!)
        
        timer = Timer.scheduledTimer(withTimeInterval: options.updateTime, repeats: true) {[unowned self] timer in
            landlordsManager?.start { [weak self] apartments in
                guard let self = self else { return }
                if !self.isSecondRunPlus {
                    self.currentApartments = apartments
                    self.isSecondRunPlus = true
                } else {
                    if !apartments.isEmpty {
                        let newApartments = apartments.map {
                            Apartment(time: $0.time, title: $0.title, internalLink: $0.internalLink, street: $0.street, rooms: $0.rooms, area: $0.area, rent: $0.rent, externalLink: $0.externalLink, company: $0.company, isNew: true)
                        }
                        self.currentApartments.insert(contentsOf: newApartments, at: 0)
                        
                        if newApartments.contains(where: { self.apartmentSatisfyCurrentFilter($0) }) {
                            self.notificationsManager.pushNotification(for: newApartments.count)
                        }
                    }
                }
                self.loadingView?.removeFromSuperview()
                self.statusLabel.text = "Last update: \(TimeManager.shared.getCurrentTime())"
                self.statusLabel.flash(numberOfFlashes: 1)
                modalVCView.containerView?.isHidden = false
                self.enableStopButton(false)
            }
        }
        timer?.fire()
    }
    
    func pauseEngine() {
        timer?.invalidate()
        timer = nil
        enableStopButton(true)
    }
    
    func stopEngine() {
        let numberOfRows = tableView.numberOfRows(inSection: 0)
        guard numberOfRows > 0 else {
            return
        }
        apartmentsDataSource.removeAll()
        
        var indexPaths = [IndexPath]()
        for row in 0..<numberOfRows {
            indexPaths.append(IndexPath(row: row, section: 0))
        }
        tableView.deleteRows(at: indexPaths, with: .automatic)
        isSecondRunPlus = false
        landlordsManager = nil
    }
    
    func setNotificationManagerAlertType(with state: Bool) {
        guard let modalView = modalVCView else { return }
        notificationsManager.setAlertType(to: modalView.optionsView.soundSwitch.isOn ? .custom : .standart)
    }
    
    //MARK: - Support functions
    private func enableStopButton(_ status: Bool) {
        if status {
            modalVCView?.stopButton.isEnabled = true
            modalVCView?.stopButton.alpha = 1.0
        } else {
            modalVCView?.stopButton.isEnabled = false
            modalVCView?.stopButton.alpha = 0.5
        }
    }
    
    private func setPublishersToUpdateOptions(from modalView: ModalView) {
        modalView.optionsView.roomsTextField.publisher(for: \.text)
            .map { Int(extractFrom: $0, defaultValue: Constants.defaultOptions.rooms) }
            .sink { [weak self] in
                guard let self = self else { return }
                self.options.rooms = $0
            }
            .store(in: &cancellables)
        
        modalView.optionsView.areaTextField.publisher(for: \.text)
            .map { Int(extractFrom: $0, defaultValue: Constants.defaultOptions.area) }
            .sink { [weak self] in
                guard let self = self else { return }
                self.options.area = $0
            }
            .store(in: &cancellables)
        
        modalView.optionsView.rentTextField.publisher(for: \.text)
            .map { Int(extractFrom: $0, defaultValue: Constants.defaultOptions.rent) }
            .sink { [weak self] in
                guard let self = self else { return }
                self.options.rent = $0
            }
            .store(in: &cancellables)
        
        modalView.optionsView.timerUpdateTextField.publisher(for: \.text)
            .map { Double(extractFrom: $0, defaultValue: Constants.defaultOptions.updateTimer) }
            .sink { [weak self] in
                guard let self = self else { return }
                self.options.updateTime = $0
            }
            .store(in: &cancellables)
    }
    
    private func setPublisherToUpdateApartmentsDataSource() {
        Publishers.CombineLatest($currentApartments, $options)
            .map { apartments, options in
                apartments.filter { apartment in
                    apartment.rooms >= options.rooms && apartment.area >= options.area && apartment.rent <= options.rent
                }
            }
            .sink { [unowned self] filteredApartments in
                apartmentsDataSource = filteredApartments
                tableView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    private func apartmentSatisfyCurrentFilter(_ apartment: Apartment) -> Bool {
        return apartment.rooms >= options.rooms && apartment.area >= options.area && apartment.rent <= options.rent
    }
}

// MARK: - DetectDetent Protocol

extension ViewController: DetectDetent {
    func detentChanged(detent: UISheetPresentationController.Detent.Identifier) {
        switchModalVCCurrentDetent(to: detent)
    }
    
    private func switchModalVCCurrentDetent(to detent: UISheetPresentationController.Detent.Identifier) {
        modalVC?.currentDetent = detent
    }
    
    private func calcModalVCDetentSizeSmall() -> CGFloat {
        self.view.frame.height * 0.1
    }
    
}

//MARK: - UISheetPresentationControllerDelegate

extension ViewController: UISheetPresentationControllerDelegate {
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
        if let currentDetent = sheetPresentationController.selectedDetentIdentifier {
            detentChanged(detent: currentDetent)
        }
    }
}
