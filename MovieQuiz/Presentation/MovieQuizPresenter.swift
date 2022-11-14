
import UIKit

final class MovieQuizPresenter: QuestionFactoryDelegate {
 
    // MARK: - QuestionFactoryDelegate
    
    func didLoadDataFromServer() {
        viewController?.hideLoadingIndicator()
        questionFactory?.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: Error) {
        let message = error.localizedDescription
        viewController?.showNetworkError(message: message)
    }
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.show(quiz: viewModel)
        }
    }
    
    // MARK: - Lifecycle
    
    private let questionsAmount: Int = 10
    private var currentQuestionIndex: Int = 0
    private var currentQuestion: QuizQuestion?
    weak var viewController: MovieQuizViewControllerProtocol?
    private var numberOfCorrectAnswers: Int = 0
    var questionFactory: QuestionFactoryProtocol?
    private let statisticService: StatisticService!
    
    init(viewController: MovieQuizViewControllerProtocol) {
        self.viewController = viewController
        
        statisticService = StatisticServiceImplementation()
        
        questionFactory = QuestionFactory(delegate: self, moviesLoader: MoviesLoader())
        questionFactory?.loadData()
        viewController.showLoadingIndicator()
    }
    
    func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(), // распаковываем картинку
            question: model.text, // берём текст вопроса
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")// высчитываем номер вопроса
    }
    
    func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }
    
    func resetQuestionIndex() {
        currentQuestionIndex = 0
    }
    
    func switchToNextQuestion() {
        currentQuestionIndex += 1
    }
    
    func yesButtonClicked() {
        didAnswer(isYes: true)
    }
    
    func noButtonClicked() {
        didAnswer(isYes: false)
    }
    
    func didAnswer(isCorrectAnswer: Bool) {
        if (isCorrectAnswer) { numberOfCorrectAnswers += 1 }
    }
    
    private func didAnswer(isYes: Bool) {
        guard let currentQuestion = currentQuestion else { return }
        let givenAnswer = isYes
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    func showNextQuestionOrResults() {
        if isLastQuestion() {
            statisticService?.store(correct: numberOfCorrectAnswers, total: questionsAmount)
            let text = """
                    Ваш результат: \(numberOfCorrectAnswers) из \(questionsAmount)
                    Количество сыгранных квизов: \(statisticService.gamesCount)
                    Рекорд: \(statisticService.bestGame.correct)/\(statisticService.bestGame.total) (\(statisticService.bestGame.date))
                    Средняя точность: \(Int(statisticService.totalAccuracy))%
                    """
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: text,
                buttonText: "Сыграть ещё раз")
            viewController?.show(quiz: viewModel)// показать результат квиза
            
        } else {
            self.switchToNextQuestion()
            questionFactory?.requestNextQuestion()
        }
    }
    
    func restartGame() {
        resetQuestionIndex()
        numberOfCorrectAnswers = 0
        questionFactory?.requestNextQuestion()
    }
    
    func showAnswerResult(isCorrect: Bool) {
        didAnswer(isCorrectAnswer: isCorrect)
        
        viewController?.highlightImageBorder(isCorrectAnswer: isCorrect)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.showNextQuestionOrResults()
            self.viewController?.extinguishImageBorder()
        }
    }
    
}
