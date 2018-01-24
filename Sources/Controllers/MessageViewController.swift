import UIKit

public enum MessageStyle {
  case initial
  case loading
  case error
}

public final class MessageViewController: UIViewController {
  // Blur effect view.
  private lazy var blurView: UIVisualEffectView = .init(effect: UIBlurEffect(style: .extraLight))
  /// Text label.
  public private(set) lazy var textLabel: UILabel = .init()
  /// Info image view.
  public private(set) lazy var imageView: UIImageView = .init()
  /// Border view.
  public private(set) lazy var borderView: UIView = .init()

  private lazy var collapsedConstraints: [NSLayoutConstraint] = self.makeCollapsedConstraints()
  private lazy var expandedConstraints: [NSLayoutConstraint] = self.makeExpandedConstraints()

  var state: State = .scanning {
    didSet {
      handleStateUpdate()
    }
  }

  // MARK: - View lifecycle

  public override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(blurView)
    blurView.contentView.addSubviews(textLabel, imageView, borderView)
    setupSubviews()
    handleStateUpdate()
  }

  public override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    blurView.frame = view.bounds
  }

  // MARK: - Subviews

  private func setupSubviews() {
    textLabel.translatesAutoresizingMaskIntoConstraints = false
    textLabel.textColor = .black
    textLabel.numberOfLines = 3

    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.image = imageNamed("info").withRenderingMode(.alwaysTemplate)
    imageView.tintColor = .black

    borderView.translatesAutoresizingMaskIntoConstraints = false
    borderView.backgroundColor = .clear
    borderView.layer.borderWidth = 2
    borderView.layer.cornerRadius = 10
    borderView.layer.borderColor = UIColor.black.cgColor
  }

  private func handleStateUpdate() {
    borderView.isHidden = true
    borderView.layer.removeAllAnimations()

    switch state {
    case .scanning, .unauthorized:
      textLabel.text = state == .scanning ? Info.text : Info.settingsText
      textLabel.textColor = .black
      textLabel.font = UIFont.boldSystemFont(ofSize: 14)
      textLabel.numberOfLines = 3
      textLabel.textAlignment = .left
      imageView.tintColor = .black
    case .processing:
      textLabel.text = Info.loadingText
      textLabel.textColor = .black
      textLabel.font = UIFont.boldSystemFont(ofSize: 16)
      textLabel.numberOfLines = 10
      textLabel.textAlignment = .center
      borderView.isHidden = false
      imageView.tintColor = .black
    case .notFound:
      textLabel.text = Info.notFoundText
      textLabel.textColor = .black
      textLabel.font = UIFont.boldSystemFont(ofSize: 16)
      textLabel.numberOfLines = 10
      textLabel.textAlignment = .center
      imageView.tintColor = .red
    }

    if state == .scanning || state == .unauthorized {
      expandedConstraints.forEach({ $0.isActive = false })
      collapsedConstraints.forEach({ $0.isActive = true })
    } else {
      collapsedConstraints.forEach({ $0.isActive = false })
      expandedConstraints.forEach({ $0.isActive = true })
    }
  }

  // MARK: - Animations

  /**
   Animates blur and border view.
   */
  func animateLoading() {
    animate(blurStyle: .light)
    animate(borderViewAngle: CGFloat(Double.pi/2))
  }

  /**
   Animates blur to make pulsating effect.

   - Parameter style: The current blur style.
   */
  private func animate(blurStyle: UIBlurEffectStyle) {
    guard state == .processing else { return }

    UIView.animate(
      withDuration: 2.0,
      delay: 0.5,
      options: [.beginFromCurrentState],
      animations: ({ [weak self] in
        self?.blurView.effect = UIBlurEffect(style: blurStyle)
      }),
      completion: ({ [weak self] _ in
        self?.animate(blurStyle: blurStyle == .light ? .extraLight : .light)
      }))
  }

  /**
   Animates border view with a given angle.

   - Parameter angle: Rotation angle.
   */
  private func animate(borderViewAngle: CGFloat) {
    guard state == .processing else {
      borderView.transform = .identity
      return
    }

    UIView.animate(
      withDuration: 0.8,
      delay: 0.5,
      usingSpringWithDamping: 0.6,
      initialSpringVelocity: 1.0,
      options: [.beginFromCurrentState],
      animations: ({ [weak self] in
        self?.borderView.transform = CGAffineTransform(rotationAngle: borderViewAngle)
      }),
      completion: ({ [weak self] _ in
        self?.animate(borderViewAngle: borderViewAngle + CGFloat(Double.pi / 2))
      }))
  }
}

extension MessageViewController {
  private func makeExpandedConstraints() -> [NSLayoutConstraint] {
    let padding: CGFloat = 10
    let borderSize: CGFloat = 51

    return [
      imageView.centerYAnchor.constraint(equalTo: blurView.centerYAnchor, constant: -60),
      imageView.centerXAnchor.constraint(equalTo: blurView.centerXAnchor),
      imageView.widthAnchor.constraint(equalToConstant: 30),
      imageView.heightAnchor.constraint(equalToConstant: 27),

      textLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 14),
      textLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
      textLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

      borderView.topAnchor.constraint(equalTo: imageView.topAnchor, constant: -12),
      borderView.centerXAnchor.constraint(equalTo: blurView.centerXAnchor),
      borderView.widthAnchor.constraint(equalToConstant: borderSize),
      borderView.heightAnchor.constraint(equalToConstant: borderSize)
    ]
  }

  private func makeCollapsedConstraints() -> [NSLayoutConstraint] {
    let padding: CGFloat = 10
    var constraints = [
      imageView.topAnchor.constraint(equalTo: blurView.topAnchor, constant: 18),
      imageView.widthAnchor.constraint(equalToConstant: 30),
      imageView.heightAnchor.constraint(equalToConstant: 27),

      textLabel.topAnchor.constraint(equalTo: imageView.topAnchor, constant: -3),
      textLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10)
    ]

    if #available(iOS 11.0, *) {
      constraints += [
        imageView.leadingAnchor.constraint(
          equalTo: view.safeAreaLayoutGuide.leadingAnchor,
          constant: padding
        ),
        textLabel.trailingAnchor.constraint(
          equalTo: view.safeAreaLayoutGuide.trailingAnchor,
          constant: -padding
        )
      ]
    } else {
      constraints += [
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
        textLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding)
      ]
    }

    return constraints
  }
}