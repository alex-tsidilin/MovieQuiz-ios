import UIKit

final class MovieQuizViewController: UIViewController, MovieQuizViewControllerProtocol {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.layer.cornerRadius = 20  // закругляю картинку
        alertPresenter = AlertPresenter(viewController: self)
        presenter = MovieQuizPresenter(viewController: self)
        showLoadingIndicator()
    }
    
    private var alertPresenter: AlertPresenter?
    private var presenter: MovieQuizPresenter!
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) { presenter.yesButtonClicked() }
    @IBAction private func noButtonClicked(_ sender: UIButton) { presenter.noButtonClicked() }
    
    func show(quiz step: QuizStepViewModel) {
        // здесь мы заполняем нашу картинку, текст и счётчик данными
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    func show(quiz result: QuizResultsViewModel) {
        let alertModel = AlertModel(
            title: result.title,
            message: result.text,
            buttonText: result.buttonText)
        { [weak self] _ in
            guard let self = self else { return }
            self.presenter.restartGame()
        }
        alertPresenter?.showAlert(quiz: alertModel)
    }
    
    func highlightImageBorder(isCorrectAnswer: Bool) {
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrectAnswer ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
    }
    
    func extinguishImageBorder() { imageView.layer.borderWidth = 0 }

    func showLoadingIndicator() {
        activityIndicator.isHidden = false // говорим, что индикатор загрузки не скрыт
        activityIndicator.startAnimating() // включаем анимацию
    }
    
    func hideLoadingIndicator() {
        activityIndicator.isHidden = true // говорим, что индикатор загрузки не скрыт
    }
    
    func showNetworkError(message: String) {
        hideLoadingIndicator() // скрываем индикатор загрузки
        let networkError = AlertModel(
            title: "Ошибка",
            message: message,
            buttonText: "Попробовать ещё раз")
        {   [weak self] _ in
            guard let self = self else { return }
            self.presenter.reloadGame()
            self.showLoadingIndicator()
        }
        alertPresenter?.showAlert(quiz: networkError)
    }
}
