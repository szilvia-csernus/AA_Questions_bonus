require_relative "questions_db"
require_relative "model_superclass"
require_relative "question_follow"
require_relative "question_like"
require_relative "reply"
require_relative "user"

class Question < ModelSuperclass

    def self.find_by_author_id(author_id)
        results = QuestionsDatabase.instance.execute(<<-SQL, author_id)
        SELECT 
            * 
        FROM 
            questions
        WHERE
            author_id = ?
        SQL
        results.map { |result| Question.new(result)}
    end

    def self.most_followed(n)
        QuestionFollow.most_followed_questions(n)
    end

    def self.most_liked(n)
        QuestionLike.most_liked_questions(n)
    end

    attr_accessor :id, :title, :body, :author_id

    def initialize(hash = {})
        @id = hash['id']
        @title = hash['title']
        @body = hash['body']
        @author_id = hash['author_id']
    end

    def author
        User.find_by_id(@author_id)
    end

    def replies
        Reply.find_by_question_id(@id)
    end

    def followers
        QuestionFollow.followers_for_question_id(@id)
    end

    def likers
        QuestionLike.likers_for_question_id(@id)
    end

    def num_likes
        QuestionLike.num_likes_for_question_id(@id)
    end

end