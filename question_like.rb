require_relative "questions_db"
require_relative "model_superclass"
require_relative "user"
require_relative "question"

class QuestionLike < ModelSuperclass

    def self.find_by_question_id(question_id)
        results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
        SELECT 
            * 
        FROM 
            question_likes
        WHERE
            question_id = ?
        SQL
        results.map { |result| QuestionLike.new(result)}
    end

    def self.liked_questions_for_liker_id(liker_id)
        results = QuestionsDatabase.instance.execute(<<-SQL, liker_id)
        SELECT
            *
        FROM
            questions
        JOIN    
            (SELECT 
                question_id
            FROM 
                question_likes
            WHERE
                liker_id = ?
            ) liked_questions
        ON questions.id = liked_questions.question_id

        SQL
        results.map { |result| Question.new(result)}
    end

    def self.likers_for_question_id(question_id)
        results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
        SELECT
            *
        FROM
            users
        JOIN
            question_likes
        ON users.id = liker_id
        WHERE
            question_likes.question_id = ?
        SQL
        results.map { |result| User.new(result)}
    end

    def self.num_likes_for_question_id(question_id)
        results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
        SELECT 
            COUNT(question_likes.liker_id)
        FROM 
            question_likes
        WHERE
            question_id = ?
        SQL
        results[0]["COUNT(question_likes.liker_id)"]
    end

    def self.most_liked_questions(n)
        results = QuestionsDatabase.instance.execute(<<-SQL, n)
        SELECT
            *
        FROM
            questions
        JOIN
            (SELECT 
                questions.id, COUNT(question_likes.liker_id) AS count
            FROM 
                questions
            JOIN
                question_likes 
                ON question_likes.question_id = questions.id
            GROUP BY questions.id

            ) liker_count
        ON questions.id = liker_count.id
        ORDER BY 
            liker_count.count DESC
        LIMIT ?
        SQL
        results.map { |result| Question.new(result)}
    end

    attr_accessor :id, :question_id, :liker_id

    def initialize(hash)
        @question_id = hash['question_id']
        @liker_id = hash['liker_id']
    end

end