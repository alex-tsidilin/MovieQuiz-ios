
import Foundation

class QuestionFactory: QuestionFactoryProtocol {
    
    private let moviesLoader: MoviesLoading
    private var movies: [MostPopularMovie] = []
    weak var delegate: QuestionFactoryDelegate?
    
    func loadData() {
        moviesLoader.loadMovies { [weak self]  result in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                switch result {
                case .success(let mostPopularMovies):
                    self.movies = mostPopularMovies.items
                    self.delegate?.didLoadDataFromServer()
                case .failure(let error):
                    self.delegate?.didFailToLoadData(with: error)
                }
            }
        }
    }
    
    func requestNextQuestion() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let index = (0..<self.movies.count).randomElement() ?? 0
            
            guard let movie = self.movies[safe: index] else { return }
            
            var imageData = Data()
            
            do {
                imageData = try Data(contentsOf: movie.resizedImageURL)
            } catch {
                print("Failed to load image")
            }
            
            let rating = Float(movie.rating) ?? 0
            
            // question generation
            let ratingInDoubleDigits = Int(rating*10)
            let range = 5
            let randomNumberAroundRatingInDoubleDigits = min((ratingInDoubleDigits-range...ratingInDoubleDigits+range).randomElement() ?? 0, 99)
            let ratingInQuestionFloat = Float(randomNumberAroundRatingInDoubleDigits)/10
            let text = "Рейтинг этого фильма больше чем \(ratingInQuestionFloat)?"
            let correctAnswer = rating > ratingInQuestionFloat
            
            let question = QuizQuestion(image: imageData,
                                        text: text,
                                        correctAnswer: correctAnswer)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.didReceiveNextQuestion(question: question)
            }
        }
    }
    
    init(delegate: QuestionFactoryDelegate?, moviesLoader: MoviesLoading) {
         self.delegate = delegate
         self.moviesLoader = moviesLoader
     }
    
}
