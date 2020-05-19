
import UIKit
import ExposureNotification

class KeysViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let cellReuseIdentifier = "keyCell"
    private lazy var dataSource = makeDataSource()

    private let networkingHelper = NetworkingHelper()

    enum Section : CaseIterable {
      case keys
    }

    init() {
        super.init(nibName: nil, bundle: nil)
        title = "Keys"
        tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: "keyboard"), tag: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = tableView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self,forCellReuseIdentifier: cellReuseIdentifier)
        tableView.dataSource = dataSource
        tableView.delegate = self

        networkingHelper.getDebugKeys(day: Date().addingTimeInterval(60*60*24)) { [weak self] result in
            var snapshot = NSDiffableDataSourceSnapshot<KeysViewController.Section, NetworkingHelper.DebugZips>()
            snapshot.appendSections([.keys])
            snapshot.appendItems(result)
            self?.dataSource.apply(snapshot, animatingDifferences: true)
        }
        
    }

    func makeDataSource() -> UITableViewDiffableDataSource<KeysViewController.Section, NetworkingHelper.DebugZips> {
            let reuseIdentifier = cellReuseIdentifier

            return UITableViewDiffableDataSource(
                tableView: tableView,
                cellProvider: {  tableView, indexPath, zip in
                    let cell = tableView.dequeueReusableCell(
                        withIdentifier: reuseIdentifier,
                        for: indexPath)

                    cell.textLabel?.text = zip.name
                    return cell
                }
            )
        }
}


extension KeysViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let key = dataSource.itemIdentifier(for: indexPath) else { return }
        let manager = ENManager()
        manager.activate { (error) in
            manager.detectExposures(configuration: .dummyConfiguration, diagnosisKeyURLs: [key.localUrl]) { (summary, error) in
                let alertController = UIAlertController(title: "Summary", message: summary?.description ?? error?.localizedDescription ?? "nil", preferredStyle: .alert)
                let actionOk = UIAlertAction(title: "OK",
                    style: .default,
                    handler: nil)
                alertController.addAction(actionOk)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
}

@available(iOS 13.5, *)
extension ENExposureConfiguration {
    static var dummyConfiguration: ENExposureConfiguration = {
        let configuration = ENExposureConfiguration()
        configuration.minimumRiskScore = 0
        configuration.attenuationLevelValues = [1, 2, 3, 4, 5, 6, 7, 8]
        configuration.attenuationWeight = 50
        configuration.daysSinceLastExposureLevelValues = [1, 2, 3, 4, 5, 6, 7, 8]
        configuration.daysSinceLastExposureWeight = 50
        configuration.durationLevelValues = [1, 2, 3, 4, 5, 6, 7, 8]
        configuration.durationWeight = 50
        configuration.transmissionRiskLevelValues = [1, 2, 3, 4, 5, 6, 7, 8]
        configuration.transmissionRiskWeight = 50
        return configuration
    }()
}